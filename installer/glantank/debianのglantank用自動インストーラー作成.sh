#!/bin/bash
# =============================================================================
  rm -rf ./glantank
  mkdir -p ./glantank/install
  pushd ./glantank
# -----------------------------------------------------------------------------
# wget -O preseed.cfg "https://raw.githubusercontent.com/office-itou/lab/master/Linux/installer/glantank/preseed.cfg.standard.glantank.raid1"
# wget -O preseed.cfg "https://raw.githubusercontent.com/office-itou/lab/master/Linux/installer/glantank/preseed.cfg.standard.glantank.raid5"
# wget                "http://ftp.riken.jp/Linux/debian/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/preseed.cfg"
  wget                "http://ftp.riken.jp/Linux/debian/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/initrd.gz"
  wget                "http://ftp.riken.jp/Linux/debian/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/zImage"
# -----------------------------------------------------------------------------
  pushd install
  zcat ../initrd.gz | cpio -if -
  cp -p ../../preseed.cfg .
  find | cpio --quiet -o -H newc | gzip -9 > ../initrd
  popd
# -----------------------------------------------------------------------------
  ls -al
  popd
# -----------------------------------------------------------------------------
  exit 0
# = eof =======================================================================
