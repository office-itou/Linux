# **Mkosi example**

## **Ubuntu 25.10 questing**

### **Create in the image directory**

``` bash:
sudo rm -rf $PWD/.workdirs/ubuntu-25.10/
sudo mkosi \
--force \
--wipe-build-dir \
--architecture=x86-64 \
--root-password=r00t \
--bootable=yes \
--bootloader=systemd-boot \
--format=directory \
--output=rootfs \
--output-directory=$PWD/.workdirs/ubuntu-25.10/ \
--cache-directory=/srv/user/share/cache/ubuntu-25.10/ \
--distribution=ubuntu \
--release=questing \
--repositories=main,restricted,universe,multiverse \
--package=ubuntu-minimal,ubuntu-standard,systemd-boot-efi,linux-image-generic,linux-firmware
```

### **Execution in the image directory**

``` bash:
sudo mkosi \
--format=directory \
--output=rootfs \
--directory=$PWD/.workdirs/ubuntu-25.10/ \
qemu
```

## **reference**

* https://wiki.archlinux.org/title/Mkosi
