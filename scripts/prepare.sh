#!/usr/bin/env bash
set -ex

export STARTDIR=$PWD

if [ -d "/tmp" ]; then
    export TMPDIR="/tmp"
fi


cd $TMPDIR
function clean_system {
    set +ex
    sed -i.bak /AYS_/d $HOME/.bashrc
    sed -i.bak /JSDOCKER_/d $HOME/.bashrc
    sed -i.bak /'            '/d $HOME/.bashrc
    set -ex
}

function osx_install {
    # set +ex
    # brew unlink curl
    # brew unlink python3
    # brew unlink git
    # set -ex
    # brew install python3
    # brew link --overwrite python3
    # brew install git
    # brew link --overwrite git
    # brew install curl
    # brew link --overwrite curl
    # brew install snappy
    sudo mkdir -p /optvar
    sudo chown -R $USER /optvar
    sudo mkdir -p /opt
    sudo chown -R $USER /opt
}



if [ "$(uname)" == "Darwin" ]; then
    # Do something under Mac OS X platform
    # echo 'install brew'
    export LANG=C; export LC_ALL=C
    osx_install

elif [ -e /etc/alpine-release ]; then
    alpine_install

elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # export LC_ALL='C.UTF-8'
    locale-gen en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
    if [ "$dist" == "Ubuntu" ]; then
        echo "found ubuntu"
        apt-get install git
        apt-get install mc curl git ssh python3.5 -y
        apt-get install python3-pip -y
    fi

elif [ "$(expr substr $(uname -s) 1 9)" == "CYGWIN_NT" ]; then
    # Do something under Windows NT platform
    export LANG=C; export LC_ALL=C
    lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
    install apt-cyg /bin
    apt-cyg install curl
    # apt-cyg install python3-dev
    # apt-cyg install build-essential
    # apt-cyg install openssl-devel
    # apt-cyg install libffi-dev
    # apt-cyg install python3
    # apt-cyg install make
    apt-cyg install unzip
    apt-cyg install git

    # ln -sf /usr/bin/python3 /usr/bin/python

fi

clean_system

# pip_install

set -ex


cd $STARTDIR