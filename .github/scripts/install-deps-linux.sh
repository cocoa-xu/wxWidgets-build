#!/bin/bash

set -xe

TARGET=$1

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y libgtk-3-dev libwebkit2gtk-4.1-dev liblzma-dev libcurl4-openssl-dev libnotify-dev \
  libsecret-1-dev libgspell-1-dev libgl1-mesa-dev libglu1-mesa-dev
