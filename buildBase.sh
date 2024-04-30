#!/bin/bash


TAG=""
JDK_DIR=""
CRIU_ARCHIVE=""
TOMCAT_ARCHIVE=""
SHOULD_FAIL=""
SCRIPT_DIR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

function displayHelp() {
  echo "Build a base semeru-esque container based on ubi 9 with a custom JDK."
  echo "Note: CRIU requires linux kernel that supports \"setcap cap_checkpoint_restore\""
  echo "Note: This build script requires that ./extra/criu.tar.gz and ./extra/tomcat.tar.gz both exist (relative to the script directory, which is currently $SCRIPT_DIR)"
  echo ""
  echo "Parameters:"
  echo -n $'\t'; echo "--tag=<TAG>"
  echo -n $'\t'; echo "    Tag to use for the built container image"
  echo -n $'\t'; echo "    Required."
  echo -n $'\t'; echo "    Example: --tag=a-tag:some-version"
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
    --tag=*)
      TAG="${i#*=}"
      shift # past argument=value
      ;;
    --jdk-dir=*)
      JDK_DIR="${i#*=}"
      shift # past argument=value
      ;;
    --criu-archive=*)
      CRIU_ARCHIVE="${i#*=}"
      shift # past argument=value
      ;;
    --tomcat-archive=*)
      TOMCAT_ARCHIVE="${i#*=}"
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

if [[ $# -gt 0 ]] ; then
  failWith "This script does not take positional arguments and one was provided"
fi

if [ -z ${TAG} ]; then
  echo "Missing parameter --tag=<TAG>"
  SHOULD_FAIL="YES"
fi
if [ -z ${JDK_DIR} ]; then
  echo "Missing parameter --jdk-dir=<TAG>"
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
  failWith "Error(s) when checking build setup. See previous message(s)."  
fi

echo "Building image."
echo "tag=${TAG}"
echo "jdk-dir=${JDK_DIR}"

set -Eeo pipefail

SCRATCH_DIR=$(mktemp -d "/tmp/liberty-base-script-dir-XXX")
trap 'rm -rf -- "$SCRATCH_DIR"' EXIT

# Tar up the JDK image and move it into the build directory
echo "Creating jdk.tar.gz"
if [ ! -d "$JDK_DIR" ]; then
 failWith "JDK image directory \"${JDK_DIR}\" does not exist"
fi
tar -czvf "${SCRATCH_DIR}/jdk.tar.gz" -C "${JDK_DIR}" .

# Hardlink cached CRIU, tomcat, and our docker file
ln "${SCRIPT_DIR}/extras/tomcat.tar.gz" "${SCRATCH_DIR}/tomcat.tar.gz"
ln "${SCRIPT_DIR}/extras/criu.tar.gz" "${SCRATCH_DIR}/criu.tar.gz"
ln "${SCRIPT_DIR}/base-container/ubi9-custom/Dockerfile_base" "${SCRATCH_DIR}/Dockerfile_base"

cd "${SCRATCH_DIR}"
echo "Building the docker image"
docker build -f Dockerfile_base -t $TAG .
