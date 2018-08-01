#!/bin/sh

set -x
set -e

export ARCH=arm
export LOADADDR=0x10008000
export CROSS_COMPILE=arm-linux-gnueabihf-

PATCHFILE=../reform-linux/drm-flip-done-timeout-workaround.patch

cd linux
if ! patch -Rsfp1 --dry-run <$PATCHFILE; then
  patch -p1 <$PATCHFILE
else
  echo "Kernel already patched."
fi

make -j4 zImage imx6qp-mntreform.dtb

cd ..

