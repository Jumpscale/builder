#!/bin/bash
set -e

if [ -z ${JSENV+x} ]; then
    echo "[-] JSENV is not set, your environment is not loaded correctly."
    exit 1
fi

# source ~/.jsenv.sh
# source $CODEDIR/github/jumpscale/core9/cmds/js9_base

logfile="/dev/null"

export iname=js9_base0

docker inspect $iname   > /dev/null 2>&1 && docker rm -f $iname > /dev/null
docker inspect js9devel > /dev/null 2>&1 && docker rm -f js9deve > /dev/null
docker inspect js9      > /dev/null 2>&1 && docker rm -f js9 > /dev/null

echo "[+] building ubuntu docker base image"

docker run \
    --name "${iname}" \
    --hostname "${iname}" \
    -d --device=/dev/net/tun \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    --cap-add=DAC_OVERRIDE --cap-add=DAC_READ_SEARCH \
    -v ${GIGDIR}/:/root/gig/ \
    -v ${GIGDIR}/code/:/opt/code/ \
    phusion/baseimage > ${logfile}

docker exec -t $iname bash /opt/code/github/jumpscale/developer/scripts9/js_builder_base9_step1-docker.sh

echo "[+] commiting changes"
docker commit $iname jumpscale/$iname > ${logfile} 2>&1
docker rm -f $iname > ${logfile} 2>&1

echo "[+] build successful (use js9_start to start an env)"
