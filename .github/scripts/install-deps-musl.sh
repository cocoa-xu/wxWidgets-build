#!/bin/bash

set -xe

if [ -z "$(which sudo)" ]; then
  export SUDO="" ;
else
  export SUDO="sudo" ;
fi

${SUDO} apk update
${SUDO} apk add gcc g++ curl curl-dev make curl git gtk+3.0-dev glu-dev
