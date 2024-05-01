#!/bin/bash

# Build a liberty image using a custom base JDK image. Assumes that:
# - JDK container image has already been built
#
# Required environment variables:
#   JDK_TAG: tag for the base JDK container image to use for building
#   LIBERTY_TAG: tag for resulting liberty container image
#   SCRIPT_DIR: directory the script is contained in
#   SCRATCH_DIR: directory that can be used for scratch work

set -Eeo pipefail

SCRIPT_DOCKER_DIR="${SCRIPT_DIR}/ci.docker/releases/24.0.0.3/kernel-slim/"
SCRATCH_DOCKER_DIR="${SCRATCH_DIR}/kernel-slim/"

if [ ! -d "${SCRIPT_DOCKER_DIR}" ]; then
  echo "Script docker file ${SCRIPT_DOCKER_DIR} does not exist - do you need to clone submodules?"
  exit 1
fi

# Check the custom base image actually exists
if [ -z "$(docker images -q ${JDK_TAG} 2> /dev/null)" ]; then
  echo "Custom base image ${JDK_TAG} does not exist"
  exit 1
fi

# Move over local resources
cp -r "${SCRIPT_DOCKER_DIR}" "${SCRATCH_DIR}"

cd "${SCRATCH_DOCKER_DIR}"

# Replace FROM ... with FROM ${JDK_TAG} 
sed -i -r "s/^FROM [^[:space:]]*(.*)$/FROM ${JDK_TAG}\1/" Dockerfile.ubi.openjdk21

# Actually build
docker build --no-cache -f Dockerfile.ubi.openjdk21 -t "${LIBERTY_TAG}" .

