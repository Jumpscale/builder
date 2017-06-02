#!/bin/bash
set -e

if [ -z ${JSENV+x} ]; then
    echo "[-] JSENV is not set, your environment is not loaded correctly."
    exit 1
fi

logfile="/tmp/install.log"

# Loading developer functions
. $CODEDIR/github/jumpscale/developer/jsenv-functions.sh

container() {
    ssh -A root@localhost -p 2222 "$1" > ${logfile} 2>&1
}

usage() {
   cat <<EOF
Usage: js9_build [-l] [-p] [-h]
   -l: means install the jumpscale libs, ays & prefab
   -p: means install the jumpscale portal
   -h: help

   example to do all: 'js9_build -lp' which will install jumpscale & libs & pip deps

EOF
   exit 0
}

while getopts ":lph" opt; do
   case $opt in
   l )  echo "[+] will install: js9 libs" ; install_libs=1 ;;
   p )  echo "[+] will install: js9 portal" ; install_portal=1 ;;
   h )  usage ; exit 0 ;;
   \?)  usage ; exit 1 ;;
   esac
done

shift $(($OPTIND - 1))

# echo "the remaining arguments are: $1 $2 $3"

export bname="js9_base0"
export iname="js9_base"

if ! docker images | grep -q "jumpscale/$bname"; then
    bash js_builder_base9_step1.sh
fi

echo "[+] cleaning previous system"
docker inspect $iname   > /dev/null 2>&1 && docker rm -f $iname > /dev/null
docker inspect js9devel > /dev/null 2>&1 && docker rm -f js9deve > /dev/null
docker inspect js9      > /dev/null 2>&1 && docker rm -f js9 > /dev/null

# make sure we always install jumpscale if any of the libs are asked for
if [ -n "$install_libs" ]; then
    install_js=1
    initenv=1
fi

if [ -n "$install_portal" ]; then
    install_js=1
    install_libs=1
    initenv=1
fi

echo "[+] starting docker container"
docker run \
    --name $iname \
    --hostname $iname \
    -d -p 2222:22 \
    --device=/dev/net/tun \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    -v ${GIGDIR}/:/root/gig/ \
    -v ${GIGDIR}/code/:/opt/code/ \
    jumpscale/$bname > ${logfile} 2>&1

ssh_authorize $iname

# Removing previous known_hosts for this target
# and allowing the new one
sed -i.bak /localhost.:2222/d ~/.ssh/known_hosts
rm -f ~/.ssh/known_hosts.bak

# Waiting for ssh to allow connections
while ! ssh-keyscan -p 2222 localhost 2>&1 | grep -q "OpenSSH"; do
    sleep 0.2
done

# Allowing this host
ssh-keyscan -p 2222 localhost 2>&1 | grep -v '^#' >> ~/.ssh/known_hosts

# Adding github known_host
container "ssh-keyscan github.com >> ~/.ssh/known_hosts"

echo "[+] loading or updating jumpscale source code"
getcode core9 > ${logfile} 2>&1
getcode developer > ${logfile} 2>&1

if [ -n "$install_libs" ]; then
    echo "[+] installing python devlopment environment (needed for certain python packages to install)"
    container "apt-get update -y"
    container "apt-get upgrade -y"
    container "apt-get install -y build-essential libssl-dev libffi-dev python3-dev"

    echo "[+] installing jumpscale 9 libraries"
    container "js9_getcode_libs_prefab_ays noinit"
fi

if [ -n "$install_portal" ]; then
    echo "[+] installing jumpscale 9 portal"
    container "js9_getcode_portal noinit"
fi

if [ -n "$initenv" ]; then
    echo "[+] initializing js9 environment"
    container "js9_init"
fi

docker commit $iname jumpscale/$iname > ${logfile} 2>&1

echo "[+] build successful"
