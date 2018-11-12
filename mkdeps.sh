#!/bin/sh

set -x
set -e

if [ ! -f linux/Makefile ]; then
  git clone --depth 1 git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
fi

if [ ! -f reform-linux/kernel-config ]; then
  git clone https://github.com/mntmn/reform-linux
fi

if [ ! -f u-boot/Makefile ]; then
  git clone --depth 1 https://github.com/mntmn/u-boot -b mntreform
fi

if [ ! -f reform/README.md ]; then
  git clone https://github.com/mntmn/reform
fi

# TODO secure distribution
if [ ! -f reform-usrlocal.tar.gz ]; then
  wget -O reform-usrlocal.tar.gz http://dump.mntmn.com/reform-usrlocal-20181110.tar.gz
fi
