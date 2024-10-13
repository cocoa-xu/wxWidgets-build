#!/bin/bash

set -xe

PLATFORM=$1
IMAGE=$2
ROOTDIR=$3
BUILD_VERSION=$4
LIBRARY_TYPE=$5
TARGET=$6
JOBS=$7

ls -lah "$(pwd)"

sudo docker run --privileged --network=host --rm --platform="${PLATFORM}" -v "$(pwd)":/work "${IMAGE}" \
    sh -c "chmod a+x /work/install-deps.sh && /work/install-deps.sh ${TARGET} ${IMAGE} /work && chmod a+x /work/do-build.sh && /work/do-build.sh /work ${BUILD_VERSION} ${LIBRARY_TYPE} ${TARGET} ${JOBS}"
