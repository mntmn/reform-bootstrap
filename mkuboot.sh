#!/bin/sh

set -x
set -e

cd u-boot
cp mntreform-config .config

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
make -j4

cd ..

