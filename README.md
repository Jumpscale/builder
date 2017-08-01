# Development environment
Use this development environment to play & develop with JumpScale.

It uses Docker and the goal is to get it to work on Ubuntu, Windows & Mac OS X.

## JumpScale 9
Make sure to have your chosen SSH key loaded into SSH agent before starting.
You can do that by:
```bash
eval $(ssh-agent)
ssh-add <path-to-sshkey>
```

### Install a specific branch (optional)
By default, master branch is installed, if you want to install from a specific branch, first set the `GIGBRANCH` and/or `GIGDEVELOPERBRANCH` environment variable:

```bash
export GIGBRANCH=master
export GIGDEVELOPERBRANCH=master
```

- GIGDEVELOPERBRANCH: the branch of this (jumpscale/developer) repository to use
- GIGBRANCH: the branch which will be used for all other JumpScale repositories
  - If the specified branch does not exist then it will fallback to master
  - If the repository was already cloned, then it will just do a pull of the branch (without losing local changes, will fail if there are changes).

### Protect host bash_profile (optional)

THIS IS NOT RECOMMENDED TO DO, only use this when you don't want any change in your system

If you don't want the JumpScale install script change your `bash_profile`, set the `GIGSAFE` environment variable:
```bash
export GIGSAFE=1
```


#### Note for Windows Subsystem for Linux (WSL)
Since Docker containers aren't supported on WSL (for now), you will need to do the following:
1. Install [Docker on Windows](https://docs.docker.com/docker-for-windows/install/)
2. Allow sharing the `C:` drive from the Docker Shared Drives settings
3. Run the following commands on WSL Bash:
   ```bash
   sudo mkdir /c
   sudo mount --bind /mnt/c /c
   ```
4. Add the following lines to the WSL `~/.bashrc` file (to link WSL with host Docker bin)
   ```bash
   export PATH="$PATH:/mnt/c/Program\ Files/Docker/Docker/resources/bin/"
   ```

### Initialize the host
First execute `jsinit.sh` in order to prepare the installation:
```bash
export GIGDEVELOPERBRANCH="master"
curl "https://raw.githubusercontent.com/Jumpscale/developer/${GIGDEVELOPERBRANCH}/jsinit.sh?$RANDOM" > /tmp/jsinit.sh
bash /tmp/jsinit.sh
```

### Build the Docker image
Before executing any `js9_*` command please use `source ~/.jsenv.sh` first.

Then in order to build the Docker image execute `js9_build`:

```bash
#-l installs extra libs, AYS and prefab
#-p installs portal
#-r will rebuild the base Docker, use this when you want to redo all
js9_build #without options will install the basic docker with basic JumpScale9 support
```

To see all options do `js9_build -h`.

To see detailed output while the script is running do the following in a separate console:

```bash
tail -f /tmp/install.log
```

As a result a new Docker image with the name `js9_base` will be build and a container with the same name will be started. The script will check whether your private SSH key is loaded. If that is the case it will add your public key to `authorized_keys`. If no key is loaded, it will ask for the name of your private key.


To troubleshoot you can always enter the Docker as follows:
```bash
docker exec -ti js9 /bin/bash
```


### Start the Docker container

As a result of the previous step a container with the name `js9` got started.

With `js9_start` the running container will be stopped and removed, and a new one will be started:

```shell
js9_start
```

`js9_start` allows you to control the name of the container with the `-n` option (default name is `js9`), and the SSH port with the `-p` option (default port is 2222).

`js9_start` will start a new container based on the local image if there isn't a js9 container on the system. If there is, the user will be prompted to choose between using the existing container or removing the container and a new one would be created. To bypass the prompt you can choose the `-r` option to reset the installation or `-c` option to continue using the existing container.

`js9_start` will start a new container based on the local image. If it doesn't find any local image, it downloads one from Docker Hub. With the `-b` option you instruct `js9_start` to first build a new image, which then always includes AYS, prefab and some extra libraries, but excluding the portal framework. If you want to rebuild the image that includes the portal framework, you need to you `js9_build` with the `-p` option.


### SSH into the container

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


## Start with the JumpScale interactive shell

```bash
js9
```

## Recommended tools

- All JumpScale code is checked out under `/opt/code` in the development environment or in `~/gig/code/...`
- Use an IDE like Atom for development, SourceTree is a good tool for Git manipulation
- Over SSH you can play with the code in the Docker container
- To push changes to a remote host (remote development) use `j.tools.develop...`


## Cleanup

```
#remove all old dockers
docker rm $(docker ps -a -q)
```

## Removing Homebrew and /opt on Mac OS X

```
curl https://raw.githubusercontent.com/Jumpscale/developer/master/scripts/osx_reset_all.sh?$RANDOM > $TMPDIR/resetall.sh;bash $TMPDIR/resetall.sh
```
