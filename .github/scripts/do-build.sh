#!/bin/bash

set -xe

ROOTDIR=$1
BUILD_VERSION_V=$2
LIBRARY_TYPE=$3
TARGET=$4
JOBS=$5

export BUILD_VERSION="${BUILD_VERSION_V#v}"
export DESTDIR="${ROOTDIR}/wxWidgets-${LIBRARY_TYPE}-${BUILD_VERSION_V}"
export FILENAME="wxWidgets-${LIBRARY_TYPE}-${TARGET}.tar.gz"

cd "${ROOTDIR}/wxWidgets"

rm -rf "${DESTDIR}"
mkdir -p "${DESTDIR}"
rm -rf "${ROOTDIR}/build"
mkdir -p "${ROOTDIR}/build"

if [ "${LIBRARY_TYPE}" = "static" ]; then
  ./configure --disable-sys-libs --disable-tests --disable-shared \
    --enable-cxx11 --enable-stl --enable-webview --enable-monolithic \
    --with-liblzma --with-libcurl --without-subdirs
else
  ./configure --disable-sys-libs --disable-tests \
    --enable-cxx11 --enable-stl --enable-webview --enable-monolithic \
    --with-liblzma --with-libcurl --without-subdirs
fi

make -j"${JOBS}"

make DESTDIR="${DESTDIR}" install
cd "${DESTDIR}"
tar -czf "${ROOTDIR}/build/${FILENAME}" .

cd "${ROOTDIR}/build"
shasum -a 256 "${FILENAME}" | tee "${FILENAME}.sha256"
