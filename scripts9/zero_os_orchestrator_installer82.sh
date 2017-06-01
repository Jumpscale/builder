#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

function valid () {
  if [ $? -ne 0 ]; then
      cat /tmp/lastcommandoutput.txt
      if [ -z $1 ]; then
        echo "Error in last step"
      else
        echo $1
      fi
      exit $?
  fi
}

if [ -z $1 ] || [ -z $2 ] || [ -s $3 ]; then
  echo "Usage: ays_orchestrator_installer82.sh <BRANCH> <ZEROTIERNWID> <ZEROTIERTOKEN>"
  echo
  echo "  BRANCH: 0-orchestrator development branch."
  echo "  ZEROTIERNWID: Zerotier network id."
  echo "  ZEROTIERTOKEN: Zerotier api token."
  echo
  exit 1
fi
BRANCH=$1
ZEROTIERNWID=$2
ZEROTIERTOKEN=$3

if (( `docker ps -a | grep js9 | wc -l` < 1 )); then
  echo "js9 docker container is not running"
  exit 1
fi

if [ -e /proc/version ] && grep -q Microsoft /proc/version; then
  # Windows subsystem 4 linux
  WINDOWSUSERNAME=`ls -ail /mnt/c/Users/ | grep drwxrwxrwx | grep -v Public | grep -v Default | grep -v '\.\.'`
  WINDOWSUSERNAME=${WINDOWSUSERNAME##* }
  GIGHOME=${GIGPATH:-/mnt/c/Users/${WINDOWSUSERNAME}/gig}
else
  # Native Linux or MacOSX
  GIGHOME=${GIGPATH:-~/gig}
fi

echo "Installing orchestrator dependencies"
# docker exec -t js9 bash -c "pip3 install git+https://github.com/zero-os/0-core.git@${BRANCH}#subdirectory=client/py-client -U" > /tmp/lastcommandoutput.txt 2>&1
# valid
# docker exec -t js9 bash -c "pip3 install git+https://github.com/zero-os/0-orchestrator.git@${BRANCH}#subdirectory=pyclient -U" > /tmp/lastcommandoutput.txt 2>&1
# valid
# docker exec -t js9 bash -c "pip3 install zerotier -U" > /tmp/lastcommandoutput.txt 2>&1
# valid
# docker exec -t js9 python3 -c "from js9 import j; j.tools.prefab.local.development.golang.install()" > /tmp/lastcommandoutput.txt 2>&1
# valid
# docker exec -t js9 mkdir -p /usr/local/go > /tmp/lastcommandoutput.txt 2>&1
# valid

echo "Updating AYS orchestrator server"
pushd ${GIGHOME}/code/github/ > /tmp/lastcommandoutput.txt 2>&1
valid
mkdir -p zero-os > /tmp/lastcommandoutput.txt 2>&1
valid
pushd zero-os > /tmp/lastcommandoutput.txt 2>&1
valid
if [ ! -d "0-orchestrator" ]; then
  git clone https://github.com/zero-os/0-orchestrator.git > /tmp/lastcommandoutput.txt 2>&1
  valid
fi
pushd 0-orchestrator > /tmp/lastcommandoutput.txt 2>&1
valid
git pull
valid
git checkout ${BRANCH} > /tmp/lastcommandoutput.txt 2>&1
valid

if ! docker exec -t js9 cat /root/init-include.sh | grep -q "ays start"; then
  docker exec -t js9 bash -c "echo ays start >> /root/init-include.sh" > /tmp/lastcommandoutput.txt 2>&1
  valid
fi

echo "Building orchestrator api server"
docker exec -t js9 bash -c "mkdir -p /opt/go/proj/src/github.com" > /tmp/lastcommandoutput.txt 2>&1
valid
docker exec -t js9 bash -c "if [ ! -d /opt/go/proj/src/github.com/zero-os ]; then ln -sf /opt/code/github/zero-os /opt/go/proj/src/github.com/zero-os; fi" > /tmp/lastcommandoutput.txt 2>&1
valid
docker exec -t js9 bash -c "cd /opt/go/proj/src/github.com/zero-os/0-orchestrator/api; GOPATH=/opt/go/proj GOROOT=/opt/go/root/ /opt/go/root/bin/go get -d ./...; GOPATH=/opt/go/proj GOROOT=/opt/go/root/ /opt/go/root/bin/go build -o /root/orchestratorapiserver" > /tmp/lastcommandoutput.txt 2>&1
valid
docker exec -t js9 bash -c "if [ ! -d /optvar/cockpit_repos/ ]; then ays repo create -n orchestrator-server -g js9; fi" > /tmp/lastcommandoutput.txt 2>&1
valid

echo "Starting orchestrator api server"
ZEROTIERIP=`docker exec -t js9 bash -c "ip -4 addr show zt0 | grep -oP 'inet\s\d+(\.\d+){3}' | sed 's/inet //' | tr -d '\n\r'"`
if ! docker exec -t js9 cat /root/init-include.sh | grep -q "/root/orchestratorapiserver"; then
  docker exec -t js9 bash -c 'echo "nohup /root/orchestratorapiserver --bind '"${ZEROTIERIP}"':8080 --ays-url http://127.0.0.1:5000 --ays-repo orchestrator-server > /var/log/orchestratorapiserver.log 2>&1 &"  >> /root/init-include.sh' > /tmp/lastcommandoutput.txt 2>&1
  valid
fi
# docker stop js9 > /tmp/lastcommandoutput.txt 2>&1
# valid
# docker start js9  > /tmp/lastcommandoutput.txt 2>&1
# valid

# echo "Waiting for api server to be ready"
# docker exec -t js9 bash -c "while true; do if [ -d /optvar/cockpit_repos/orchestrator-server ]; then break; fi; sleep 1; done"
echo "Deploying bootstrap service"
docker exec -t js9 bash -c 'echo -e "bootstrap.g8os__grid1:\n  zerotierNetID: '"${ZEROTIERNWID}"'\n  zerotierToken: '"${ZEROTIERTOKEN}"'\n\nactions:\n  - action: install\n" > /optvar/cockpit_repos/orchestrator-server/blueprints/bootstrap.bp'
docker exec -t js9 bash -c 'cd /optvar/cockpit_repos/orchestrator-server; ays blueprint' > /tmp/lastcommandoutput.txt 2>&1
valid
docker exec -t js9 bash -c 'cd /optvar/cockpit_repos/orchestrator-server; ays run create --follow -y' > /tmp/lastcommandoutput.txt 2>&1
valid

echo
echo "Your ays server is ready to bootstrap nodes into your zerotier network."
echo "Download your ipxe boot iso image https://bootstrap.gig.tech/iso/${BRANCH}/${ZEROTIERNWID} and boot up your nodes!"
echo "Enjoy your orchestrator api server: http://${ZEROTIERIP}:8080/"
