#!/bin/sh

git clone https://github.com/mntmn/u-boot

cd u-boot

git checkout mntreform

cp mntreform-config .config

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
make -j4

