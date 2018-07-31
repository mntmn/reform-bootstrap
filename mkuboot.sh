#!/bin/sh

#git clone --depth 1 https://github.com/mntmn/u-boot -b mntreform

cd u-boot

cp mntreform-config .config

export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-
make -j4

