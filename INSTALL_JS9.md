# Development environment

** ONLY USE THIS FOR OLDER VERSIONS OF JUMPSCALE **

For versions 9.1.3, 9.2.x and 9.3.x use the JumpScale bash utilities: https://github.com/Jumpscale/bash

## JumpScale 9


1 - Install the latest version of [`docker`](https://docs.docker.com/engine/installation/linux/ubuntu/#install-docker)

2 - switch to root
```bash
sudo -i
```

3 - Make sure that you have at least one SSH key for root and it should be located under /root then (optionally) export it:
```bash
export SSHKEYNAME=<YOUR SSH KEY NAME (i.e. id_rsa)>
```

4 - Link sh with bash (prob not needed)
```bash
ln -fs /bin/bash /bin/sh
```

5  Start the installation
```bash
export TMPDIR=/tmp
curl https://raw.githubusercontent.com/Jumpscale/developer/master/jsinit.sh?$RANDOM > $TMPDIR/jsinit.sh;bash $TMPDIR/jsinit.sh
```

6 - Start installing JumpScale9 Libraries:
```bash
js9_build # if you only want to install the base
js9_build -l # install JumpScale9 Libraries without portal
js9_build -p # install JumpScale9 Libraries with portal
```

To see all options do ```js9_build -h```


To see interactive output do the following in a separate console:

```bash
tail -f /tmp/lastcommandoutput.txt
```

7 - Start the docker container for js9
```bash
export HOMEDIR=~ # Make sure that the HOMEDIR variable is exported
js9_start
```

8 - Connect to js9 Container through ssh
```bash
ssh -tA root@localhost -p2222
```
