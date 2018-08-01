#!/bin/sh

set -x
set -e

if [ ! -f linux/Makefile ]; then
  git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

if [ ! -f reform-linux/kernel-config ]; then
  git clone https://github.com/mntmn/reform-linux
fi

if [ ! -f ./linux/arch/arm/boot/dts/imx6qp-mntreform.dts ]; then  
  cp ./reform-linux/imx6qp-mntreform.dts ./linux/arch/arm/boot/dts/
  cp ./reform-linux/imx6qdl-mntreform.dtsi ./linux/arch/arm/boot/dts/
  cp ./reform-linux/kernel-config ./linux/.config
fi

if [ ! -f u-boot/Makefile ]; then
  git clone --depth 1 https://github.com/mntmn/u-boot -b mntreform
fi

