#!/bin/bash
set -e

if [ -z ${JSENV+x} ]; then
    echo "[-] JSENV is not set, your environment is not loaded correctly."
    exit 1
fi

logfile="/tmp/install.log"
. $CODEDIR/github/jumpscale/developer/jsenv-functions.sh

export bname=js9_base
export iname=js9

usage() {
   cat <<EOF
Usage: js9_start [-n $name] [-p $port]
   -n $name: name of container
   -p $port: port on which to install
   -b: build the docker, don't download from docker
   -h: help

   example to do all: 'js9_start -n mymachine -p 2223' which will start a container with name myachine on port 2223 and download
   also works with specifying nothing

EOF
   exit 0
}

port=2222

while getopts ":npbh" opt; do
   case $opt in
   n )  iname=$OPTARG ;;
   p )  port=$OPTARG ;;
   b )  build=1 ;;
   h )  usage ; exit 0 ;;
   \?)  usage ; exit 1 ;;
   esac
done
shift $(($OPTIND - 1))

docker inspect $bname >  /dev/null 2>&1 &&  docker rm  -f $bname > /dev/null 2>&1
docker inspect $iname >  /dev/null 2>&1 &&  docker rm  -f "$iname" > /dev/null 2>&1

if ! docker images | grep -q "jumpscale/$bname"; then
    if [ -n "${build}" ]; then
        bash js_builder_base9.sh -l
    fi
fi
echo "[+] starting jumpscale9 development environment"

# -v ${GIGDIR}/data/:/optvar/data
docker run --name $iname \
    --hostname $iname \
    -d \
    -p ${port}:22 -p 8000-8100:8000-8100 \
    --device=/dev/net/tun \
    --cap-add=NET_ADMIN --cap-add=SYS_ADMIN \
    --cap-add=DAC_OVERRIDE --cap-add=DAC_READ_SEARCH \
    -v ${GIGDIR}/:/root/gig/ \
    -v ${GIGDIR}/code/:/opt/code/ \
    jumpscale/$bname > ${logfile} 2>&1 || die "docker could not start, please check ${logfile}"

# initssh
# copyfiles
# linkcmds

# echo "* update jumpscale code (js9_code update -a jumpscale -f )"
# ssh -A root@localhost -p 2222 'export LC_ALL=C.UTF-8;export LANG=C.UTF-8;js9_code update -a jumpscale -f'
# echo "* init js9 environment (js9_init)"
# ssh -A root@localhost -p 2222 'js9_init' > /tmp/lastcommandoutput.txt 2>&1


# configzerotiernetwork
#
# autostart


echo "[+] docker started"
echo "[+] please access over ssh using:"
echo "[+]    ssh -tA root@localhost -p ${port})"
echo "[+] or using  js  or  jshell"
