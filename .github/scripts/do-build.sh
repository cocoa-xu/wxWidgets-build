#!/bin/bash

set -xe

ROOTDIR=$1
BUILD_VERSION=$2
LIBRARY_TYPE=$3
TARGET=$4
JOBS=$5

export DESTDIR="${ROOTDIR}/wxWidgets-${LIBRARY_TYPE}-${BUILD_VERSION}"
export FILENAME="wxWidgets-${LIBRARY_TYPE}-${TARGET}.tar.gz"

cd "${ROOTDIR}/wxWidgets"

rm -rf "${DESTDIR}"
mkdir -p "${DESTDIR}"
rm -rf "${ROOTDIR}/build"
mkdir -p "${ROOTDIR}/build"

if [ "$(uname -s)" = "Darwin" ]; then
  export wxwidgets_flags="--with-cocoa --with-macosx-version-min=11.0"
fi

if [ "${LIBRARY_TYPE}" = "static" ]; then
  ./configure --disable-sys-libs --disable-shared ${wxwidgets_flags}
else
  ./configure --disable-sys-libs ${wxwidgets_flags}
fi

make -j"${JOBS}"

make DESTDIR="${DESTDIR}" install
cd "${DESTDIR}"
tar -czf "${ROOTDIR}/build/${FILENAME}" .

cd "${ROOTDIR}/build"
shasum -a 256 "${FILENAME}" | tee "${FILENAME}.sha256"
