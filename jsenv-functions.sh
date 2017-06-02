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
