#!/bin/sh

set -xe

TARGET=$1
RUNS_ON=$2
ROOTDIR=$3
BUILD_VERSION=$4

if [ -z "$(which sudo)" ]; then
  export SUDO="" ;
else
  export SUDO="sudo" ;
fi

${SUDO} apk update
${SUDO} apk add gcc g++ curl curl-dev make curl git gtk+3.0-dev glu-dev bash perl-utils gspell-dev libsecret-dev mesa-dev mesa-gl

git clone --branch "v${BUILD_VERSION}" https://github.com/wxWidgets/wxWidgets.git "${ROOTDIR}/wxWidgets"
cd "${ROOTDIR}/wxWidgets"
git submodule update --init --recursive
