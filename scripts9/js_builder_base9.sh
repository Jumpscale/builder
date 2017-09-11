#!/bin/bash
set -e

export port=2222

if [ -z ${JSENV+x} ]; then
    echo "[-] JSENV is not set, your environment is not loaded correctly."
    exit 1
fi

logfile="/tmp/install.log"
rm -f $logfile

# Loading developer functions
. $CODEDIR/github/jumpscale/developer/jsenv-functions.sh
catcherror

usage() {
   cat <<EOF
Usage: js9_build [-l] [-p] [-h]
   -l: means install the jumpscale libs, ays & prefab
   -p: means install the jumpscale portal
   -r: rebuild the base image (ubuntu1604)
   -h: help

   example to do all: 'js9_build -lp' which will install jumpscale & libs & pip deps

EOF
   exit 0
}

reset=0

while getopts ":lprh" opt; do
   case $opt in
   l )  echo "[+] will install: js9 libs" ; install_libs=1 ;;
   p )  echo "[+] will install: js9 portal" ; install_portal=1 ;;
   r )  reset=1 ;;
   h )  usage ; exit 0 ;;
   \?)  usage ; exit 1 ;;
   esac
done

shift $(($OPTIND - 1))

base_deps() {

    echo "[+]   updating ubuntu repositories"
    container apt-get update

    echo "[+]   updating system"
    container apt-get upgrade -y

    echo "[+]   installing python"
    container apt-get install -y python3

    echo "[+]   installing basic dependencies"
    container apt-get install -y curl mc openssh-server git net-tools iproute2 tmux localehelper psmisc python3-cryptography python3-paramiko python3-psutil telnet

    echo "[+]   setting up default environment"
    container 'echo "" > /etc/motd'
    container touch /root/.iscontainer
    container mkdir /host
    echo "[+]   base deps done"

}

update_code() {
    echo "[+] loading or updating jumpscale source code"
    getcode core9 > ${logfile} 2>&1
    getcode lib9 > ${logfile} 2>&1
    getcode prefab9 > ${logfile} 2>&1
    getcode builder_bootstrap > ${logfile} 2>&1
    getcode developer > ${logfile} 2>&1
    echo "[+] update code done"
}

enable_ssh() {
    # /opt/code is hardcoded, it runs inside the docker
    dockerscript="/opt/code/github/jumpscale/developer/scripts9/ubuntu_enablessh.sh"
    docker exec -t $iname bash ${dockerscript} || dockerdie ${iname} ${logfile}

    echo "[+]   Waiting for ssh to allow connections"
    while ! ssh-keyscan -p 2222 localhost 2>&1 | grep -q "OpenSSH"; do
        sleep 0.2
    done

    # Removing previous known_hosts for this target
    # and allowing the new one
    echo "[+]   push local ssh keys"
    sed -i.bak /localhost.:2222/d ~/.ssh/known_hosts
    rm -f ~/.ssh/known_hosts.bak

    # Allowing this host
    echo "[+]   allow this host"
    ssh-keyscan -p 2222 localhost 2>&1 | grep -v '^#' >> ~/.ssh/known_hosts
}

getpip_python() {
    echo "[+]   installing pip system"
    container "curl -sk https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py"
    container python3 /tmp/get-pip.py
    echo "[+]   installing some pip dependencies"
    container pip3 install --upgrade pip
    container pip3 install tmuxp
    container pip3 install gitpython
    # echo "[+]   installing some pip dependencies (paramiko...)"
    # container pip3 install paramiko --no-deps --upgrade-strategy only-if-needed --upgrade
    # container pip3 install cryptography --no-deps --upgrade-strategy only-if-needed
    # container pip3 install bcrypt --upgrade-strategy only-if-needed --upgrade
    # container pip3 install paramiko --upgrade-strategy only-if-needed --upgrade
}

installjs9() {
    container "ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts"
    echo "[+]   synchronizing developer files"
    container rsync -rv /opt/code/github/jumpscale/developer/files_guest/ /

    echo "[+]   installing jumpscale core9"
    container "cd /opt/code/github/jumpscale/core9;bash install.sh"

    echo "[+]   installing binaries files"
    container 'find  /opt/code/github/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \;'
    container 'find  /opt/code/github/jumpscale/developer/cmds_guest -exec ln -s {} "/usr/local/bin/" \;'

    container rm -rf /usr/local/bin/cmds
    container rm -rf /usr/local/bin/cmds_guest

    echo "[+]   initializing jumpscale part3"
    container 'python3 -c "from JumpScale9 import j; j.tools.jsloader.generate()"'

}

installzerotier() {
    container "apt-get install gpgv2 -y"
    container "curl -s 'https://pgp.mit.edu/pks/lookup?op=get&search=0x1657198823E52A61' | gpg --import"
    container "curl -s https://install.zerotier.com/ | bash || true"
}

cleanup() {
    echo "[+]   cleanup"
    container rm -rf "/tmp/*" "/var/tmp/*"
    container rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
    #container rm -rf /root/.cache
    #container mkdir /root/.cache
    container apt-get clean
    # container rm -f "/etc/ssh/ssh_host_*"
}

if [ $reset -eq 1 ]; then
    dockerremoveimage jumpscale/base0
    dockerremoveimage jumpscale/base1
    dockerremoveimage jumpscale/base2
    dockerremoveimage jumpscale/base3
fi

dockerrun "phusion/baseimage" "base0" 2222
enable_ssh
dockercommit "base0" "base0" "stop"

dockerrun "jumpscale/base0" "base1" 2222
base_deps
dockercommit "base1" "base1" "stop"

dockerrun "jumpscale/base1" "base2" 2222
getpip_python
dockercommit "base2" "base2" "stop"

dockerrun "jumpscale/base2" "base3" 2222
installjs9
installzerotier
cleanup

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

if [ -n "$install_libs" ]; then
    echo "[+] installing python development environment (needed for certain python packages to install)"
    container "apt-get update -y"
    container "apt-get upgrade -y"
    container "apt-get install -y build-essential libssl-dev libffi-dev python3-dev"

    echo "[+] installing jumpscale 9 libraries"
    container "js9_getcode_libs_prefab_ays ${GIGBRANCH} noinit"
fi

if [ -n "$install_portal" ]; then
    echo "[+] installing jumpscale 9 portal"
    container "js9_getcode_portal ${GIGBRANCH} noinit"
fi

if [ -n "$initenv" ]; then
    echo "[+] initializing js9 environment"
    container "js9_init"
fi

dockercommit "base3" "base3" "stop"

echo "[+] build successful"
