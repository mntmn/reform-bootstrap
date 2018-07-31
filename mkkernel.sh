#!/bin/sh

git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
git clone https://github.com/mntmn/reform-linux

cp ./reform-linux/imx6qp-mntreform.dts ./linux/arch/arm/boot/dts/
cp ./reform-linux/imx6qdl-mntreform.dtsi ./linux/arch/arm/boot/dts/

cp ./reform-linux/kernel-config ./linux/.config

export ARCH=arm
export LOADADDR=0x10008000
export CROSS_COMPILE=arm-linux-gnueabihf-

cd linux
patch -p1 < ../reform-linux/drm-flip-done-timeout-workaround.patch
make -j4 zImage imx6qp-mntreform.dtb

cd ..

