#!/bin/bash

set -xe

TARGET=$1
RUNS_ON=$2

export DEBIAN_FRONTEND=noninteractive

case $RUNS_ON in
  ubuntu*20.04)
    sudo apt-get update
    sudo apt-get install -y libgtk-3-dev libwebkit2gtk-4.0-dev liblzma-dev libcurl4-openssl-dev libnotify-dev \
      libsecret-1-dev libgspell-1-dev libgl1-mesa-dev libglu1-mesa-dev
    ;;
  *)
    echo "Unknown platform: $RUNS_ON"
    exit 1
    ;;
esac
