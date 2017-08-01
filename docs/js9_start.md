## Usage

After finishing the building step, this command will actually start the container containing the js9 installation. To be able to use this command you need to source '.jsenv.sh' file and have your `GIGDIR` environment variable exported to the location specified in the installation.

By default the created container will be called 'js9' and will use port 2222. It is possible to specify the name and the port by using the various options available to this command specified below.

If a js9 container already exists the user will be prompted to choose between starting the existing container or creating a new one and deleting the old container.

## Command options

The available options are:

```
-n name of container
-p port on which to install
-b build the docker, don't download from docker
-r reset docker, destroy first if already on host
-c continue using existing js9 docker
-h help
```
- `-n` specifies name of container. Default is 'js9'.
- `-p` specifies the port used.
- The `-b` option will remove the existing image and will rebuild a new image(which includes ays, prefab and additional libraries).
- The `-r` option will remove the existing js9 docker and create a new container with same specified name and port.
- The `-c` option will start the js9 container that is already in the system.
