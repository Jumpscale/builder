# Development environment

Use this development environment to play & develop with JumpScale.
It uses Docker and the goal is to get it to work on Ubuntu, Windows & Mac OS X.

## JumpScale 9

### Install a specific branch
By default, master branch is installed, if you want to install from a specific branch, first set the `GIGBRANCH` environment variable:

```bash
export GIGBRANCH=anotherbranch
```

### Protect host bash_profile
If you don't want the JumpScale install script to mess with your `bash_profile`, set the `GIGSAFE` environment variable:

```bash
export GIGSAFE=1
```

### Choose your JumpScale base directory
By default all the code will be installed in `~/gig`, if you want to use another location, export the `GIGDIR` environment variable:

```bash
export GIGDIR=/home/user/development/otherdir/gig
```

### Initialize the host
First execute `jsinit.sh` in order to prepare the installation:

```bash
export GIGBRANCH="9.0.0"
curl https://raw.githubusercontent.com/Jumpscale/developer/master/jsinit.sh?$RANDOM > /tmp/jsinit.sh; bash /tmp/jsinit.sh
```

### Build the Docker image

Before executing any `js9_*` command please use `source ~/.jsenv.sh` first.

Then in order to build the Docker image execute `js9_build`:

```bash
#-l installs extra libs
#-p installs portal
js9_build -l
```

To see all options do ```js9_build -h```.

To see interactive output do the following in a separate console:

```bash
tail -f /tmp/install.log
```

### Start the Docker container
Start the development environment build in the Docker container:
```shell
js9_start
```

Then SSH into it:
```shell
ssh root@localhost -p 2222
```

## JumpScale 8.2

```bash
curl -sL https://raw.githubusercontent.com/Jumpscale/developer/master/scripts/js_builder_js82_zerotier.sh | bash -s <your-ZeroTier-network-ID>
```

To see interactive output do the following in a separate console:
```bash
tail -f /tmp/lastcommandoutput.txt
```

For more details about using `js_builder_js82_zerotier.sh` see [here](docs/installjs8_details.md).


### Add a Zero-OS Orchestrator to your JumpScale 8.2 development environment

This script is based on the JumpScale 8.2 development environment above:

```bash
curl -sL https://raw.githubusercontent.com/Jumpscale/developer/master/scripts/g8os_grid_installer82.sh | bash -s <Branch> <your-ZeroTier-network-ID> <your-ZeroTier-Token>
```

Again, to see interactive output do the following in separate console:

```
tail -f /tmp/lastcommandoutput.txt
```


Login into the development machine

```
ssh root@zerotier-IP-address
#or
docker exec -it js82 bash
```

## Start with the JumpScale interactive shell

```bash
js
```

 > This will change, is just to get started

## Recommended tools

- All JumpScale code is checked out under `/opt/code` in the development environment or in `~/gig/code/...`
- Use an IDE like Atom for development, SourceTree is a good tool for Git manipulation
- Over SSH you can play with the code in the Docker container
- To push changes to a remote host (remote development) use `j.tools.develop...`

## Other scripts (js8)

In `/scripts`:

- `prepare.sh`: execute this to make sure that your local environment is up to date
- `js_builder.sh`: build JumpScale 8 on branch 8.2.0 inside the Docker container with name js


## Cleanup

```
#remove all old dockers
docker rm $(docker ps -a -q)
```

## Init tools (js8)

```
#sets the initial config
python3 -c "from js9 import j;j.do.initEnv()"
#generates the init list
python3 -c "from JumpScale9 import j;j.tools.jsloader.generate()"
#get a shell now with autogenerated init
python3 -c "from JumpScale.init import j;from IPython import embed;embed()"
```

## Removing Homebrew and /opt on Mac OS X

```
curl https://raw.githubusercontent.com/Jumpscale/developer/master/scripts/osx_reset_all.sh?$RANDOM > $TMPDIR/resetall.sh;bash $TMPDIR/resetall.sh
```
