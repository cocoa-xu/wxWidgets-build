#!/bin/bash

set -xe

PLATFORM=$1
IMAGE=$2
ROOTDIR=$3
BUILD_VERSION_V=$4
LIBRARY_TYPE=$5
TARGET=$6
JOBS=$7

sudo docker run --privileged --network=host --rm --platform="${PLATFORM}" -v $(pwd):/work "${IMAGE}" \
    sh -c "chmod a+x /work/install-deps.sh && ./install-deps.sh ${TARGET} ${IMAGE} && chmod a+x /work/do-build.sh && /work/do-build.sh /work ${BUILD_VERSION_V} ${LIBRARY_TYPE} ${TARGET} ${JOBS}"
