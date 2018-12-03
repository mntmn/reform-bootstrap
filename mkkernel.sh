#!/bin/sh

set -x
set -e

export ARCH=arm
export LOADADDR=0x10008000
export CROSS_COMPILE=arm-linux-gnueabihf-

cp ./reform-linux/imx6qp-mntreform.dts ./linux/arch/arm/boot/dts/
cp ./reform-linux/imx6qdl-mntreform.dtsi ./linux/arch/arm/boot/dts/
cp ./reform-linux/kernel-config ./linux/.config

cd linux

#PATCHFILE=../reform-linux/drm-flip-done-timeout-workaround.patch
#if ! patch -Rsfp1 --dry-run <$PATCHFILE; then
#  patch -p1 <$PATCHFILE
#else
#  echo "Kernel already patched ($PATCHFILE)."
#fi

PATCHFILE=../reform-linux/0017-pci-fix-suspend-on-i.MX6.patch
if ! patch -Rsfp1 --dry-run <$PATCHFILE; then
  patch -p1 <$PATCHFILE
else
  echo "Kernel already patched ($PATCHFILE)."
fi

make -j4 zImage imx6qp-mntreform.dtb

cd ..

