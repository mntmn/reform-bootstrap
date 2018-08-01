#!/bin/sh

set -x
set -e

./mkdeps.sh
./mkkernel.sh
./mkuboot.sh

mkdir -p target
mkdir -p target-userland

# DEPS: parted multistrap udisksctl g++-arm-linux-gnueabihf

if [ ! -f reform-system.img ]; then
  dd if=/dev/zero of=reform-system.img bs=1M count=2000
else
  echo "reform-system.img already exists. Delete it if you want to change the image size."
fi

# can/should we use non-mbr? GPT?
/sbin/parted -s reform-system.img "mklabel msdos"
/sbin/parted -s reform-system.img "mkpart primary ext4 1 -1"
/sbin/parted -s reform-system.img print

LOOPDISK=$(udisksctl loop-setup -f ./reform-system.img)

LOOPDISK=$(echo $LOOPDISK | cut -f 5 -d " " | tr -d .)
echo LOOPDISK: $LOOPDISK

# TODO: check that LOOPDISK is safe for formatting, then replace below instances with it

# format the partition
sudo /sbin/mkfs.ext4 -q /dev/loop0p1

# print the finished partition table
/sbin/parted -s reform-system.img print

sudo mount -t ext4 /dev/loop0p1 target

# create debian userland
sudo /usr/sbin/multistrap -d target-userland -f multistrap.conf
sudo cp target-userland/usr/share/base-passwd/group.master target-userland/etc/group
sudo cp etc-templates/passwd target-userland/etc/passwd
sudo cp etc-templates/inittab target-userland/etc
sudo cp etc-templates/shadow target-userland/etc
sudo cp etc-templates/gshadow target-userland/etc
sudo cp etc-templates/fstab target-userland/etc
sudo cp etc-templates/hosts target-userland/etc
sudo cp etc-templates/resolv.conf target-userland/etc
sudo cp etc-templates/network-interfaces target-userland/etc/network/interfaces
sudo cp etc-templates/motd target-userland/etc
sudo cp etc-templates/common-* target-userland/etc/pam.d
sudo chown root:root -R target-userland/bin target-userland/usr target-userland/sbin target-userland/lib target-userland/sys target-userland/etc target-userland/var target-userland/root
sudo chown root:shadow target-userland/etc/shadow
sudo chown root:shadow target-userland/etc/gshadow
sudo cp target-scripts/* target-userland/root/

# install debian userland in image
sudo cp -av target-userland/* target/

# install custom kernel
# mkkernel.sh needs to run before. this creates zImage and imx6qp-mntreform.dtb.

sudo cp linux/arch/arm/boot/zImage target
sudo cp linux/arch/arm/boot/dts/imx6qp-mntreform.dtb target

# install custom u-boot
# mkuboot.sh needs to run before. this creates u-boot.imx.

sudo umount target

# install u-boot
sudo dd if=./u-boot/u-boot.imx of=/dev/loop0 bs=1k seek=1

# detach the image
sudo udisksctl loop-delete -b /dev/loop0

echo Reform system image created: reform-system.img
