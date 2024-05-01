#!/bin/bash

# Build a base JDK container image using a custom JDK. Assumes that:
# - JDK image directory exists
# - extras/tomcat.tar.gz exists
# - extras/criu.tar.gz exists
#
# Required environment variables:
#   JDK_TAG: tag for the semeru-esque container image we're going to build
#   JDK_DIR: directory containing the JDK image to be used to build our container image
#   SCRIPT_DIR: directory the script is contained in
#   SCRATCH_DIR: directory that can be used for scratch work

SUB_DIR="${SCRATCH_DIR}/base-image"
mkdir -p "${SUB_DIR}"

# Tar up the JDK image and move it into the build directory
echo "Creating jdk.tar.gz"
tar -czvf "${SUB_DIR}/jdk.tar.gz" -C "${JDK_DIR}" .

# Hardlink our docker file, and hardlink cached CRIU and tomcat
ln "${SCRIPT_DIR}/extras/tomcat.tar.gz" "${SUB_DIR}/tomcat.tar.gz"
ln "${SCRIPT_DIR}/extras/criu.tar.gz" "${SUB_DIR}/criu.tar.gz"
ln "${SCRIPT_DIR}/base-container/ubi9-custom/Dockerfile_base" "${SUB_DIR}/Dockerfile_base"

cd "${SUB_DIR}"
docker build --no-cache -f Dockerfile_base -t $JDK_TAG .
