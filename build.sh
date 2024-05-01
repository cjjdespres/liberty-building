#!/bin/bash

# Arguments
JDK_TAG=""
LIBERTY_TAG=""
JDK_DIR=""

# Other useful parameters
SHOULD_FAIL=""
SCRIPT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

function displayHelp() {
  echo "Build a container image with open liberty and a custom JDK."
  echo "Note: CRIU requires linux kernel that supports \"setcap cap_checkpoint_restore\""
  echo "Note: This build script requires that ./extra/criu.tar.gz and ./extra/tomcat.tar.gz both exist (relative to the script directory, which is currently $SCRIPT_DIR)"
  echo ""
  echo "Parameters:"
  echo -n $'\t'; echo "--jdk-tag=<TAG>"
  echo -n $'\t'; echo "    Tag to use for the base JDK container image"
  echo -n $'\t'; echo "    Required."
  echo -n $'\t'; echo "    Example: --jdk-tag=my-base:some-version"
  echo -n $'\t'; echo "--liberty-tag=<TAG>"
  echo -n $'\t'; echo "    Tag to use for the liberty container image"
  echo -n $'\t'; echo "    Required."
  echo -n $'\t'; echo "    Example: --liberty-tag=my-liberty:another-version"
  echo -n $'\t'; echo "--jdk-dir=<PATH>"
  echo -n $'\t'; echo "    Path to the local directory of the JDK image to use when building the container image"
  echo -n $'\t'; echo "    Required."
  echo -n $'\t'; echo "    Example: --jdk-dir=/home/user/openj9-openjdk-jdk17/build/linux-x86_64-server-release/images/jdk/"
}

function failWith() {
  echo "Build failed: $1"
  exit 1
}

if [[ $# -eq 0 ]]; then
  displayHelp
  exit 0
fi

for i in "$@"; do
  case $i in
    --jdk-tag=*)
      JDK_TAG="${i#*=}"
      shift # past argument=value
      ;;
    --jdk-dir=*)
      JDK_DIR="${i#*=}"
      shift # past argument=value
      ;;
    --liberty-tag=*)
      LIBERTY_TAG="${i#*=}"
      shift # past argument=value
      ;;
    -h|--help)
      displayHelp
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

# Basic parameter verification. If something goes wrong, we set SHOULD_FAIL and
# failWith just before we start running things.
if [[ $# -gt 0 ]] ; then
  echo "This script does not take positional arguments and one was provided"
  SHOULD_FAIL="YES"
fi

if [ -z ${JDK_TAG} ]; then
  echo "Missing parameter --jdk-tag=<TAG>"
  SHOULD_FAIL="YES"
fi

if [ -z ${JDK_DIR} ]; then
  echo "Missing parameter --jdk-dir=<PATH>"
  SHOULD_FAIL="YES"
elif [ ! -d "${JDK_DIR}" ]; then
  echo "JDK directory specified by --jdk-dir=${JDK_DIR} does not exist"
  SHOULD_FAIL="YES"
fi

if [ -z ${LIBERTY_TAG} ]; then
  echo "Missing parameter --liberty-tag=<TAG>"
  SHOULD_FAIL="YES"
fi

if [ ! -f "${SCRIPT_DIR}/extras/tomcat.tar.gz" ]; then
  echo "Missing file extras/tomcat.tar.gz"
  SHOULD_FAIL="YES"
fi

if [ ! -f "${SCRIPT_DIR}/extras/criu.tar.gz" ]; then
  echo "Missing file extras/criu.tar.gz"
  SHOULD_FAIL="YES"
fi

if [ -n "${SHOULD_FAIL}" ]; then
  failWith "Error(s) when checking build setup. See previous message(s) for details. Run this script without parameters for help."
fi

set -Eeox pipefail

# Create a temporary script build directory and have it be cleaned up on EXIT
SCRATCH_DIR=$(mktemp -d "/tmp/liberty-script-build-dir-XXX")
trap 'rm -rf -- "$SCRATCH_DIR"' EXIT

echo "Building liberty image. Parameters:"

export JDK_TAG="${JDK_TAG}"
export JDK_DIR="${JDK_DIR}"
export LIBERTY_TAG="${LIBERTY_TAG}"
export SCRIPT_DIR="${SCRIPT_DIR}"
export SCRATCH_DIR="${SCRATCH_DIR}"

echo "Building base JDK image"
./buildBase.sh

echo "Building liberty image"
./buildLiberty.sh
