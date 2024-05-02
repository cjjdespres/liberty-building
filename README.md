# Building liberty containers from scratch

This repo contains some scripts/docker files to build liberty containers from scratch using a custom JDK based on ubi-9. Two images are built:

1. A base JDK image, containing a system SCC populated with tomcat.
2. A Liberty image using the built JDK image, whose SCC has an extra layer populated iwth

## Installation

Use `git clone --recurse-submodules https://github.com/cjjdespres/liberty-container` to get this repo itself. After that, make sure that a `tomcat.tar.gz` and a `criu.tar.gz` file are present in the `extras` folder in the root of this project - they are used in the building of the base JDK image and should contain a tomcat and a criu build, respectively. Finally, this build requires you to be running with a Linux kernel that supports `setcap cap_checkpoint_restore`, which should be available in version `5.9` and later.

## Usage

Build the image itself with `build.sh`. It takes the following required parameters:

1. `--jdk-tag=<TAG>` - the tag to apply to the JDK container image that will be built
2. `--jdk-dir=<PATH>` - the path to the local JDK image directory that will be used to build the JDK container image
3. `--liberty-tag=<TAG>` - the tag to apply to the Liberty container image that will be built

## Known issues

- The build seems to start tomcat when building the JDK image and the SCC seems
  to be populated, but the build is unable to stop tomcat. I think this might be
  a docker networking issue during build?
- There are a bunch of "file is a socket - skipping" messages emitted during the
  CRIU section of the base JDK image build. I think this is just an issue with
  the particular `criu.tar.gz` I'm using.
