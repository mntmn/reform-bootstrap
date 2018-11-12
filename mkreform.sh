#!/bin/bash

set -x
set -e

./mkdeps.sh
./mkkernel.sh
./mkuboot.sh

mkdir -p target
mkdir -p target-userland

# DEPS: parted multistrap udisksctl g++-arm-linux-gnueabihf

# change 4000 below to the number of megabytes your image file should have
if [ ! -f reform-system.img ]; then
  dd if=/dev/zero of=reform-system.img bs=1M count=8000
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

# format the partition
echo "About to format ${LOOPDISK}p1!"
read -p "Are you sure? " -n 1 -r

if [[ $REPLY =~ ^[Yy]$ ]]
then
  sudo /sbin/mkfs.ext4 -q ${LOOPDISK}p1
else
  exit 1
fi

# print the finished partition table
/sbin/parted -s reform-system.img print

sudo mount -t ext4 ${LOOPDISK}p1 target

# create debian userland
sudo /usr/sbin/multistrap -d target-userland -f multistrap.conf
sudo cp target-userland/usr/share/base-passwd/group.master target-userland/etc/group
sudo cp etc-templates/passwd target-userland/etc/passwd
sudo cp etc-templates/inittab target-userland/etc
sudo cp etc-templates/shadow target-userland/etc
sudo cp etc-templates/fstab target-userland/etc
sudo cp etc-templates/hosts target-userland/etc
sudo cp etc-templates/resolv.conf target-userland/etc
sudo mkdir -p target-userland/etc/dhcp
sudo cp etc-templates/dhclient.conf target-userland/etc/dhcp
sudo cp etc-templates/network-interfaces target-userland/etc/network/interfaces
sudo cp etc-templates/motd target-userland/etc
sudo cp etc-templates/hostname target-userland/etc
sudo cp etc-templates/common-* target-userland/etc/pam.d
sudo chown root:root -R target-userland/bin target-userland/usr target-userland/sbin target-userland/lib target-userland/sys target-userland/etc target-userland/var target-userland/root
sudo chown root:shadow target-userland/etc/shadow
sudo cp target-scripts/* target-userland/root/
sudo cp target-scripts/.bash_profile target-userland/root/
sudo cp target-scripts/.xinitrc target-userland/root/
# Reform sources
sudo cp -Rv reform target-userland/root/
# inception!
sudo mkdir -p target-userland/root/sources
sudo cp -Rv reform-bootstrap target-userland/root/sources/
sudo cp -Rv reform-linux target-userland/root/sources/
sudo cp -Rv linux target-userland/root/sources/
sudo cp -Rv u-boot target-userland/root/sources/

sudo mv target-userland/root/reformd-init-script.sh target-userland/etc/init.d/reformd
sudo cp etc-templates/xorg.conf target-userland/etc/X11
sudo mkdir -p target-userland/var/local/log

# extract /usr/local tree
sudo tar --directory ./target-userland -xf reform-usrlocal.tar.gz -v -z

# install debian userland in image
sudo cp -av target-userland/* target/

# install custom kernel
# mkkernel.sh needs to run before. this creates zImage and imx6qp-mntreform.dtb.

sudo cp linux/arch/arm/boot/zImage target
sudo cp linux/arch/arm/boot/dts/imx6qp-mntreform.dtb target
sudo cp mnt-blk-icon.bmp target

# install custom u-boot
# mkuboot.sh needs to run before. this creates u-boot.imx.

sudo umount target

# install u-boot
sudo dd if=./u-boot/u-boot.imx of=$LOOPDISK bs=1k seek=1

# detach the image
sudo udisksctl loop-delete -b $LOOPDISK

echo Reform system image created: reform-system.img
