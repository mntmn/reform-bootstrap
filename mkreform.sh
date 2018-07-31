#!/bin/sh

set -x
set -e

mkdir -p target

# DEPS: parted multistrap udisksctl g++-arm-linux-gnueabihf

# dd if=/dev/zero of=reform-system.img bs=1M count=8000

# can/should we use non-mbr? GPT?
/sbin/parted -s reform-system.img mklabel gpt
/sbin/parted -s reform-system.img mkpart primary ext4 1 8000
/sbin/parted -s reform-system.img name 1 "reform-boot"
/sbin/parted -s reform-system.img print

LOOPDISK=$(udisksctl loop-setup -f ./reform-system.img)

LOOPDISK=$(echo $LOOPDISK | cut -f 5 -d " " | tr -d .)
echo LOOPDISK: $LOOPDISK

# TODO: check that LOOPDISK is safe for formatting 

# format the partition
sudo /sbin/mkfs.ext4 /dev/loop0p1

# print the finished partition table
/sbin/parted -s reform-system.img print

sudo mount -t ext4 /dev/loop0p1 target

# install debian into the image
/usr/sbin/multistrap -d target -f multistrap.conf

# install custom kernel
# mkkernel.sh needs to run before. this creates zImage and imx6qp-mntreform.dtb.

cp linux/arch/arm/boot/zImage target
cp linux/arch/arm/boot/dts/imx6qp-mntreform.dtb target

# install custom u-boot
# mkuboot.sh needs to run before. this creates u-boot.imx.

sudo umount target

dd if=./u-boot/u-boot.imx of=/dev/loop0 bs=1k seek=1

# detach the image
sudo udisksctl loop-delete -b /dev/loop0

