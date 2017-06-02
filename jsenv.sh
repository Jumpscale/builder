#!/bin/bash

# ==================================================
# Main Jumpscale Developer environment file
# ==================================================
#
# This file should be sourced (or equivalant) before using any
# jumpscale developer script (exception for setup scripts)
#
# Please note that, by default, this script is sourced on user
# bashrc (added during setup), unless you runs the setup with
# this exclusion.
#
# Moreover, this is only used when bash, if you use another shell
# (eg: zsh), this file will not be sourced automaticaly at all.
#
# If you don't use the default behaviour, please source it manually before using any scripts
#
# What does this script does ?
#
# - sets GIGDIR
# - check for ssh keys
# - improve me please.
#

# Settings JSENV to some version number
# This version is not relevant, don't trust on it
# This is mainly to set the variable to enable JSENV settings
export JSENV="1.0"

#
# OS Detection
#
if [ "$(uname)" = "Darwin" ]; then
    export LANG=C
    export LC_ALL=C
    export HOMEDIR=~

elif grep -q Microsoft /proc/version; then
    # Windows subsystem 4 linux
    WINDOWSUSERNAME=$(ls -ail /mnt/c/Users/ | grep drwxrwxrwx | grep -v Public | grep -v Default | grep -v '\.\.')
    WINDOWSUSERNAME=${WINDOWSUSERNAME##* }
    GIGDIR=/mnt/c/Users/${WINDOWSUSERNAME}/gig

else
    # Native Linux or MacOSX
    export GIGDIR=${GIGDIR:-~/gig}
    HOMEDIR=~
fi

# ------
# Here you can override some explicit variables used
# ------
# export TMPDIR=/tmp
# export HOMEDIR=~


#
# SSH Subsystem
#
# If ssh-agent is already running, let assume that your keys
# are properly already loaded
#
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval `ssh-agent`

    # echo "KEYNAME:$SSHKEYNAME"
    if [ -z $SSHKEYNAME ]; then
        SSHKEYNAME=SOMETHINGWHICHWILLNOTMATCH
    else
        #trim the sshkeyname
        export SSHKEYNAME=`echo $SSHKEYNAME | xargs`
    fi

    while [ ! -e "$HOMEDIR/.ssh/$SSHKEYNAME" ] || [ "$SSHKEYNAME" = "" ]
    do
        echo "please give name of ssh key to load, if not generate one."
        read -p 'SSHKEYNAME: ' SSHKEYNAME
        echo "check keypath '$HOMEDIR/.ssh/$SSHKEYNAME' exists"
    done

    if ! ssh-add -l | grep -q $SSHKEYNAME; then
        echo "will now try to load sshkey: $HOMEDIR/.ssh/$SSHKEYNAME"
        ssh-add $HOMEDIR/.ssh/$SSHKEYNAME
        echo "ssh key $SSHKEYNAME loaded"
    fi
fi


# FIXME: why is this redeclared ?
export GIGDIR="${GIGDIR}"
export CODEDIR="${GIGDIR}/code"

# export GIGGROUP="getent group gig | cut -d: -f3"

if [[ "$PS1" != *"gig"* ]]; then
    export PS1="(gig) $PS1"
fi

if [[ "$PATH" != *"cmds_host"* ]]; then
    export PATH="${PATH}:$CODEDIR/github/jumpscale/developer/cmds_host"
fi

# set +ex
