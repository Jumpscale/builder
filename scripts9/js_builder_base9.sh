#!/bin/bash

if [ -z ${JSENV+x} ]; then
    echo "[-] JSENV is not set, your environment is not loaded correctly."
    exit 1
fi
# progname=$0
#see http://floppsie.comp.glam.ac.uk/Glamorgan/gaius/scripting/4.html

source ~/.jsenv.sh
source $CODEDIR/github/jumpscale/core9/cmds/js9_base

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
   l )  echo "* Will install js9 libs." ; install_libs=1 ;;
   p )  echo "* Will install js9 portal." ; install_portal=1 ;;
   h )  usage ; exit 0 ;;
   \?)  usage ; exit 1 ;;
   esac
done

shift $(($OPTIND - 1))

# echo "the remaining arguments are: $1 $2 $3"

export bname=js9_base0
export iname=js9_base

if ! docker images | grep -q "jumpscale/$bname"; then
    sh js_builder_base9_step1.sh
fi

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

docker run --name $iname -h $iname -d -p 2222:22 --device=/dev/net/tun --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v ${GIGDIR}/:/root/gig/ -v ${GIGDIR}/code/:/opt/code/ jumpscale/$bname sleep 365d  > /tmp/lastcommandoutput.txt 2>&1

initssh


trap - ERR
set +e
echo "* autoaccept github key"
ssh -A root@localhost -p 2222 'ssh  -oStrictHostKeyChecking=no -T git@github.com -y'  > /tmp/lastcommandoutput.txt 2>&1
set -e
trap valid ERR

echo "* get/update jumpscale code"
getcode core9 > /tmp/lastcommandoutput.txt 2>&1
getcode developer > /tmp/lastcommandoutput.txt 2>&1


if [ -n "$install_libs" ]; then
    echo "* install python dev environment (needed for certain python packages to install)"
    ssh -A root@localhost -p 2222 'apt-get update -y;apt-get upgrade -y;apt-get install build-essential libssl-dev libffi-dev python3-dev -y' > /tmp/lastcommandoutput.txt 2>&1
    echo "* install jumpscale 9 lib"
    ssh -A root@localhost -p 2222 'js9_getcode_libs_prefab_ays noinit' > /tmp/lastcommandoutput.txt 2>&1
fi

if [ -n "$install_portal" ]; then
    echo "* install jumpscale 9 portal"
    ssh -A root@localhost -p 2222 'js9_getcode_portal noinit' > /tmp/lastcommandoutput.txt 2>&1
fi

if [ -n "$initenv" ]; then
    echo "* init js9 environment"
    ssh -A root@localhost -p 2222 'js9_init' > /tmp/lastcommandoutput.txt 2>&1
fi

cleanup

commitdocker


echo "* BUILD SUCCESSFUL"
