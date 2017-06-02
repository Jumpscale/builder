#!/bin/bash

# ------
# Functions definitions: here are useful functions we use
# ------
getcode() {
    echo "[+] downloading code: ${CODEDIR}/github/jumpscale/$1"

    if [ -e "${CODEDIR}/github/jumpscale/$1" ]; then
        cd "${CODEDIR}/github/jumpscale/$1"
        git pull
        cd -

    else
        mkdir -p "${CODEDIR}/github/jumpscale"
        cd "${CODEDIR}/github/jumpscale"

        git clone git@github.com:Jumpscale/$1.git || git clone https://github.com/Jumpscale/$1.git
    fi
}

die() {
    echo "[-] something went wrong: $1"
    exit 1
}

ssh_authorize() {
    if [ "$1" = "" ]; then
        echo "[-] ssh_authorize: missing container target"
        return
    fi

    echo "[+] authorizing local ssh keys on docker: $1"
    SSHKEYS=$(ssh-add -L)
    docker exec -t "$1" /bin/sh -c "echo \"${SSHKEYS}\" > /root/.ssh/authorized_keys"
}
