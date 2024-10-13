#!/bin/bash

set -xe

PLATFORM=$1
IMAGE=$2
ROOTDIR=$3
BUILD_VERSION=$4
LIBRARY_TYPE=$5
TARGET=$6
JOBS=$7

sudo docker run --privileged --network=host --rm --platform="${PLATFORM}" -v $(pwd):/work "${IMAGE}" \
    sh -c "cd /work && chmod a+x ./install-deps.sh && ./install-deps.sh ${TARGET} ${IMAGE} && chmod a+x ./do-build.sh && ./do-build.sh /work ${BUILD_VERSION} ${LIBRARY_TYPE} ${TARGET} ${JOBS}"
