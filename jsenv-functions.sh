#!/bin/bash

# ------
# Functions definitions: here are useful functions we use
# ------
branchExists() {
    local repository="$1"
    local branch="$2"

    echo "* Checking if ${repository}/${branch} exists"
    httpcode=$(curl -o /dev/null -I -s --write-out '%{http_code}\n' https://github.com/${repository}/tree/${branch})

    if [ "$httpcode" = "200" ]; then
        return 0
    else
        return 1
    fi
}


dockerremove(){
    echo "[+] remove docker $1"
    docker rm  -f "$1" > /dev/null 2>&1 || true
    # docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1
}

dockerremoveimage(){
    echo "[+] remove docker image $1"
    docker rmi  -f "jumpscale9/$1"  > ${logfile} 2>&1 || true
}


dockerrun() {
    bname="$1"
    iname="$2"
    port="${3:-2222}"
    start="$4"
    local addarg="${5:-}"

    #addarg: -p 10700-10800:10700-10800

    echo "[+] start docker $bname -> $iname (port:$port)"

    existing="$(docker ps -aq -f name=^/${iname}$)"
    mounted_volumes="\
        -v ${GIGDIR}/:/root/gig/ \
        -v ${GIGDIR}/code/:/opt/code/ \
        -v ${GIGDIR}/private/:/optvar/private \
    "
    # mount optvar/data to all platforms except for windows to avoid fsync mongodb error
    # related: https://docs.mongodb.com/manual/administration/production-notes/#fsync-on-directories
    if [ -e /proc/version ] &&  ! grep -q Microsoft /proc/version; then
        mounted_volumes="$mounted_volumes \
            -v ${GIGDIR}/data/:/optvar/data \
        "
    fi

    if [[ ! -z "$existing" ]]; then
      if [ ! -z "$start" ]; then
        docker start $iname  > ${logfile} 2>&1 || die "docker could not start, please check ${logfile}"
        return
      else
        dockerremove $iname
      fi
    fi
    docker run --name $iname \
        --hostname $iname \
        -d \
        -p ${port}:22 ${addarg} \
        --device=/dev/net/tun \
        --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
        --cap-add=DAC_OVERRIDE --cap-add=DAC_READ_SEARCH \
        ${mounted_volumes} \
        $bname > ${logfile} 2>&1 || die "docker could not start, please check ${logfile}"

    sleep 1

    ssh_authorize "${iname}"


}

getcode() {
    echo "* get code"
    pushd $CODEDIR/github/jumpscale

    if ! grep -q ^github.com ~/.ssh/known_hosts 2> /dev/null; then
        ssh-keyscan github.com >> ~/.ssh/known_hosts 2>&1
    fi

    if [ ! -e $CODEDIR/github/jumpscale/$1 ]; then
        repository="Jumpscale/$1"
        branch=${2:-${GIGBRANCH}}

        # fallback to master if branch doesn't exists
        if ! branchExists ${repository} ${branch}; then
            branch="master"
        fi

        echo "* Cloning github.com/${repository} [${branch}]"
        (git clone -b ${branch} git@github.com:${repository}.git || git clone -b ${branch} https://github.com/${repository}.git) || return 1

    else
        pushd $CODEDIR/github/jumpscale/$1
        git pull || return 1
        popd
    fi
    popd

}

die() {
    echo "[-] something went wrong: $1"
    cat $logfile
    exit 1
}

# die and get docker log back to host
# $1 = docker container name, $2 = logfile name, $3 = optional message
dockerdie() {
    if [ "$3" != "" ]; then
        echo "[-] something went wrong in docker $1: $3"
        exit 1
    fi

    echo "[-] something went wrong in docker: $1"
    docker exec -t $iname cat "$2"

    exit 1
}

dockercommit() {
    echo "[+] Commit docker: $1"
    docker commit $1 jumpscale/$2 > ${logfile} 2>&1 || return 1
    if [ "$3" != "" ]; then
        dockerremove $1
    fi
}

ssh_authorize() {
    if [ "$1" = "" ]; then
        echo "[-] ssh_authorize: missing container target"
        return
    fi

    echo "[+] authorizing local ssh keys on docker: $1"
    SSHKEYS=$(ssh-add -L)
    if [ -e /proc/version ] && grep -q Microsoft /proc/version; then
        # Windows Sub Linux doesn't support escaping quote so ssh-add -L should have only one key
        docker exec -t "$1" /bin/sh -c "echo ${SSHKEYS} >> /root/.ssh/authorized_keys"
    else
        docker exec -t "$1" /bin/sh -c "echo \"${SSHKEYS}\" >> /root/.ssh/authorized_keys"
    fi
}

#
# Warning: this is bash specific
#
catcherror_handler() {
    if [ "${logfile}" != "" ]; then
        echo "[-] line $1: script error, backlog from ${logfile}:"
        cat ${logfile}
        exit 1
    fi

    echo "[-] line $1: script error, no logging file defined"
    exit 1
}

catcherror() {
    trap 'catcherror_handler $LINENO' ERR
}

container() {
    catcherror
    ssh -A root@localhost -p ${port} "$@" > ${logfile} 2>&1
}

# alias docker for docker.exe for windows subsystem(WSL) linux because docker isn't supported natively on WSL
if [ -e /proc/version ] &&  grep -q Microsoft /proc/version; then
    docker() {
        docker.exe "$@"
    }
fi
