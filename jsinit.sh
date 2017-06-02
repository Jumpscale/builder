#!/bin/sh
set -e

if ! which curl > /dev/null; then
    echo "[-] curl not found, this is required to bootstrap jsinit"
    exit 1
fi

osx_install() {
    if ! which brew > /dev/null; then
        sudo echo "* Install Brew"
        yes '' | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    sudo echo "* Unlink curl/python/git"
    errortrapoff
    brew unlink curl   > /tmp/lastcommandoutput.txt 2>&1
    brew unlink python3  > /tmp/lastcommandoutput.txt 2>&1
    brew unlink git  > /tmp/lastcommandoutput.txt 2>&1
    sudo echo "* Install Python"
    brew install --overwrite python3  > /tmp/lastcommandoutput.txt 2>&1
    brew link --overwrite python3  > /tmp/lastcommandoutput.txt 2>&1
    sudo echo "* Install Git"
    brew install git  > /tmp/lastcommandoutput.txt 2>&1
    brew link --overwrite git  > /tmp/lastcommandoutput.txt 2>&1
    sudo echo "* Install Curl"
    brew install curl  > /tmp/lastcommandoutput.txt 2>&1
    brew link --overwrite curl  > /tmp/lastcommandoutput.txt 2>&1

    # brew install snappy
    # sudo mkdir -p /optvar
    # sudo chown -R $USER /optvar
    # sudo mkdir -p /opt
    # sudo chown -R $USER /opt
}

alpine_install() {
    apk add git  > /tmp/lastcommandoutput.txt 2>&1
    apk add curl  > /tmp/lastcommandoutput.txt 2>&1
    apk add python3  > /tmp/lastcommandoutput.txt 2>&1
    apk add tmux  > /tmp/lastcommandoutput.txt 2>&1
    # apk add wget
    # apk add python3-dev
    # apk add gcc
    # apk add make
    # apk add alpine-sdk
    # apk add snappy-dev
    # apk add py3-cffi
    # apk add libffi
    # apk add libffi-dev
    # apk add openssl-dev
    # apk add libexecinfo-dev
    # apk add linux-headers
    # apk add redis
}

ubuntu_install() {
    locale-gen en_US.UTF-8
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    apt-get install curl git ssh python3 -y
    # apt-get install python3-pip -y
    # apt-get install libssl-dev -y
    # apt-get install python3-dev -y
    # apt-get install build-essential -y
    # apt-get install libffi-dev -y
    # apt-get install libsnappy-dev libsnappy1v5 -y
    # rm -f /usr/bin/python
    # rm -f /usr/bin/python3
    # ln -s /usr/bin/python3.5 /usr/bin/python
    # ln -s /usr/bin/python3.5 /usr/bin/python3
}

archlinux_install() {
    sudo pacman -S --needed git curl openssh python3 --noconfirm
}

fedora_install() {
   dnf install -y git curl openssh python3
   export PATH=$PATH:/usr/local/bin
}

cygwin_install() {
    # Do something under Windows NT platform
    export LANG=C; export LC_ALL=C
    lynx -source rawgit.com/transcode-open/apt-cyg/master/apt-cyg > apt-cyg
    install apt-cyg /bin
    apt-cyg install curl
    # apt-cyg install python3-dev
    # apt-cyg install build-essential
    # apt-cyg install openssl-devel
    # apt-cyg install libffi-dev
    apt-cyg install python3
    # apt-cyg install make
    # apt-cyg install unzip
    apt-cyg install git
    ln -sf /usr/bin/python3 /usr/bin/python
}

branchExists() {
    repository="$1"
    branch="$2"

    echo "* Checking if ${repository}/${branch} exists"
    httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' https://github.com/${repository}/tree/${branch})

    if [ "$httpcode" = "200" ]; then
        return 0
    else
        return 1
    fi
}

getcode() {
    echo "* get code"
    cd $CODEDIR/github/jumpscale

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1
    fi

    if [ ! -e $CODEDIR/github/jumpscale/developer ]; then
        repository="Jumpscale/developer"
        branch=$GIGBRANCH

        # fallback to master if branch doesn't exists
        if ! branchExists ${repository} ${branch}; then
            branch="master"
        fi

        echo "* Cloning github.com/${repository} [${branch}]"
        git clone git@github.com:${repository} || git clone https://github.com/${repository}

    else
        cd $CODEDIR/github/jumpscale/developer
        git pull > /tmp/lastcommandoutput.txt 2>&1
    fi

    cd $CODEDIR/github/jumpscale
    if [ ! -e $CODEDIR/github/jumpscale/core9 ]; then
        repository="Jumpscale/core9"
        branch=$GIGBRANCH

        # fallback to master if branch doesn't exists
        if ! branchExists ${repository} ${branch}; then
            branch="master"
        fi

        echo "* Cloning github.com/${repository} [${branch}]"
        git clone -b "${branch}" git@github.com:${repository} || git clone -b "${branch}" https://github.com/${repository}

    else
        cd $CODEDIR/github/jumpscale/core9
        git pull > /tmp/lastcommandoutput.txt 2>&1
    fi
}

main() {
    echo "=========================="
    echo "== jsinit bootstrapping =="
    echo "=========================="
    echo ""

    echo "[+] fetching our cutie mascot"
    curl -s https://raw.githubusercontent.com/Jumpscale/developer/master/mascot?$RANDOM > ~/.mascot.txt
    clear
    cat ~/.mascot.txt
    echo

    export GIGBRANCH=${GIGBRANCH:-"master"}

    if [ "$(uname)" = "Darwin" ]; then
        echo "[+] apple plateform detected"

        # Do something under Mac OS X platform
        echo "* INSTALL homebrew, curl, python, git"
        export LANG=C; export LC_ALL=C
        osx_install

    elif [ -e /etc/alpine-release ]; then
        echo "[+] alpine plateform detected"
        alpine_install

    elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
        echo "[+] linux plateform detected"

        dist=`grep DISTRIB_ID /etc/*-release | awk -F '=' '{print $2}'`
        if [ "$dist" = "Ubuntu" ]; then
            echo "[+] ubuntu distribution found"
            ubuntu_install

        elif which pacman > /dev/null 2>&1; then
            echo "[+] archlinux distribution found"
            archlinux_install

        elif which dnf > /dev/null 2>&1; then
            echo "[+] fedora based distribution found"
            fedora_install

        else
            echo "[-] sorry, your distribution is not supported"
            exit 1
        fi

    elif [ "$(expr substr $(uname -s) 1 9)" = "CYGWIN_NT" ]; then
        echo "[+] cygwin based system found"
        cygwin_install
    fi

    echo "[+] downloading generic environment file"
    curl -s https://raw.githubusercontent.com/Jumpscale/developer/$GIGBRANCH/jsenv.sh?$RANDOM > ~/.jsenv.sh


    echo "[+] loading gig environment file"
    . ~/.jsenv.sh

    # You can avoid .bash_profile smashing by setting
    # GIGSAFE environment variable
    if [ ! -z ${GIGSAFE+x} ]; then
        # check profile file exists, if yes modify
        if [ ! -e $HOMEDIR/.bash_profile ] ; then
            touch $HOMEDIR/.bash_profile
        else
            #make a 1-time backup
            if [ ! -e "$HOMEDIR/.bash_profile.bak" ]; then
                cp $HOMEDIR/.bash_profile  $HOMEDIR/.bash_profile.bak
            fi
        fi

        sed -i.bak '/export SSHKEYNAME/d' $HOMEDIR/.bash_profile
        sed -i.bak '/jsenv.sh/d' $HOMEDIR/.bash_profile

        echo "" >> $HOMEDIR/.bash_profile
        echo "# Added by jsinit script" >> $HOMEDIR/.bash_profile
        echo "export SSHKEYNAME=$SSHKEYNAME" >> $HOMEDIR/.bash_profile
        echo "source ~/.jsenv.sh" >> $HOMEDIR/.bash_profile
    fi


    echo "[+] creating local environment directories"
    mkdir -p ${CODEDIR}/github/jumpscale

    echo "[+] installing code for development scripts and jumpscale core"
    getcode

    echo "[+] ensure local commands are callable"
    chmod +x ${CODEDIR}/github/jumpscale/developer/cmds_host/*

    echo "[+] cleaning garbage"
    rm -f /usr/local/bin/js9* > /dev/null 2>&1 || true
    rm -rf /usr/local/bin/cmds* > /dev/null 2>&1 || true

    # create private dir
    mkdir -p "${GIGDIR}/private"
    if [ ! -e "$GIGDIR/private/me.toml" ]; then
        echo "* copy templates private files."
        cp $CODEDIR/github/jumpscale/developer/templates/private/me.toml $GIGDIR/private/
    fi

    echo "[+] copy chosen sshpub key"
    mkdir -p $GIGDIR/private/pubsshkeys
    SSHKEYS=$(ssh-add -L) > $GIGDIR/private/pubsshkeys/id_rsa.pub

    echo "[+] please edit templates in ${GIGDIR}/private/"
    echo "[+]    if you don't then installer will ask for it."
    echo "[+]"
    echo "[+] to get started with jumpscale do 'js9_start -b'"
    echo "[+]     docker needs to be installed locally"
}

main "$@"
