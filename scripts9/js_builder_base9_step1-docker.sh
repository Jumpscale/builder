#!/bin/bash
set -e

logfile="/tmp/install.log"
# logfile="/dev/stdout"

if [ "$1" != "" ]; then
    logfile="$1"
fi

# There is one indentation level on echo to make
# a difference from host output, this is run on docker

echo "export LC_ALL=C.UTF-8" >> /root/.profile
echo "export LANG=C.UTF-8" >> /root/.profile

echo "[+]   configuring services"
mkdir -p /var/run/sshd
rm -f /etc/service/sshd/down
/etc/my_init.d/00_regen_ssh_host_keys.sh > ${logfile} 2>&1

echo "[+]   updating repositories"
apt-get update > ${logfile} 2>&1

echo "[+]   updating system"
apt-get upgrade -y > ${logfile} 2>&1

echo "[+]   installing python"
apt-get install -y python3 python3-dev > ${logfile} 2>&1

echo "[+]   installing dependencies"
apt-get install -y curl mc openssh-server git make net-tools iproute2 g++ vim tmux localehelper psmisc pkg-config libssl-dev > ${logfile} 2>&1

echo "[+]   setting up default environment"
echo "" > /etc/motd
touch /root/.iscontainer

echo "[+]   authorizing users"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
for user in $(curl -s https://raw.githubusercontent.com/Jumpscale/developer/master/scripts/devs); do
    echo "[+]      authorizing $user" > ${logfile}
    curl -s https://github.com/${user}.keys >> /root/.ssh/authorized_keys
done

echo "[+]   downloading zerotier source code"
cd /tmp
git clone --depth=1 https://github.com/zerotier/ZeroTierOne.git > ${logfile} 2>&1
cd ZeroTierOne/

echo "[+]   compiling zerotier"
make -j 4 > ${logfile} 2>&1
make install > ${logfile} 2>&1

echo "[+]   installing pip system"
cd /tmp
curl -sk https://bootstrap.pypa.io/get-pip.py > get-pip.py
python3 get-pip.py > ${logfile} 2>&1

pip3 install --upgrade pip > ${logfile} 2>&1
pip3 install tmuxp > ${logfile} 2>&1
pip3 install gitpython > ${logfile} 2>&1

echo "[+]   installing jumpscale core9"
pip3 install -e /opt/code/github/jumpscale/core9 --upgrade > ${logfile} 2>&1

echo "[+]   syncronizing developer files"
rsync -rv /opt/code/github/jumpscale/developer/files_guest/ / > ${logfile} 2>&1

echo "[+]   installing binaries files"
# source /root/.jsenv.sh

find  /opt/code/github/jumpscale/core9/cmds -exec ln -s {} "/usr/local/bin/" \; 2> ${logfile}
find  /opt/code/github/jumpscale/developer/cmds_guest -exec ln -s {} "/usr/local/bin/" \; 2> ${logfile}

rm -rf /usr/local/bin/cmds
rm -rf /usr/local/bin/cmds_guest

echo "[+]   initializing jumpscale"
python3 -c "from JumpScale9 import j; j.do.initEnv()" > ${logfile} 2>&1
python3 -c "from JumpScale9 import j; j.tools.jsloader.generate()" > ${logfile} 2>&1

echo "[+]   cleanup"
rm -rf /tmp/* /var/tmp/*
rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup
rm -f /etc/ssh/ssh_host_*
apt-get clean
