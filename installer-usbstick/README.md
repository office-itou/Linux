# mkinstallusbstick.sh (make installer USB stick)

複数のインストールメディアに対応したUSBメモリーの作成 (exFAT対応)

## 起動方法

sudo ./mkinstallusbstick.sh

## 準備

### OS

Debian 12 (bookworm)  

### 必須パッケージ

curl lz4 lzma lzop dosfstools exfatprogs grub-pc-bin

## 作業環境

### 作業用ストレージ構成

``` bash: lsblk
master@sv-server:~/mkusb$ lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL
NAME          FSTYPE      FSVER    LABEL  SIZE MOUNTPOINTS VENDOR   MODEL
sda                                       240G             VMware,  VMware Virtual S
+-sda1        LVM2_member LVM2 001        240G
  +-vg01-home ext4        1.0             240G /home
sr0                                      1024M             NECVMWar VMware Virtual IDE CDROM Drive
nvme0n1                                    20G                      VMware Virtual NVMe Disk
+-nvme0n1p1   vfat        FAT32           487M /boot/efi
+-nvme0n1p2   ext3        1.0             488M /boot
+-nvme0n1p3   LVM2_member LVM2 001         19G
  +-vg00-root ext4        1.0              19G /
```

### 使用容量

約44GiB

### ディレクトリー構成

・ カレントディレクトリーに作成されるディレクトリー

| ディレクトリー名 | 用途 | 使用容量 |
| :---: | --- | ---: |
| arc | compressed file | 588KiB |
| bld | boot loader files | 1.9GiB |
| cfg | setting files (preseed.cfg/cloud-init/initrd/vmlinuz/...) | 776MiB |
| deb | deb files | 860MiB |
| img | copy files image | 1.1GiB |
| ird | custom initramfs files | 1.1GiB |
| iso | iso files | 27GiB |
| lnx | linux-image unpacked files | 52KiB |
| mnt | iso file mount point | 4.0KiB |
| opt | optional files | 78MiB |
| pac | deb unpacked files | 5.1GiB |
| ram | initramfs unpacked files | 3.1GiB |
| usb | USB stick mount point |  |
| wrk | work directory | 3.2GiB |

## USBメモリー

### パーティション構成

・ 128GiBのUSBメモリーの例

``` bash: lsblk
master@sv-server:~/mkusb$ lsblk -f -o NAME,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
NAME   FSTYPE FSVER LABEL     SIZE MOUNTPOINTS VENDOR   MODEL
sdb                         112.6G             JetFlash Transcend 128GB
+-sdb1                       1007K
+-sdb2 vfat   FAT32           256M
+-sdb3 exfat  1.0   ISOFILE 112.4G
```

| /dev/ | 用途 | フォーマット | 設定容量 | 使用容量 |
| :---: | :---: | :---: | ---: | ---: |
| sdX1 | MBR | 無し | 1GiB | 1GiB |
| sdX2 | EFI | vFAT | 256MiB | 18MiB |
| sdX3 | DATA | exFAT | 113GiB | 28GiB |

・sdXは各自の環境に合わせて読み替えの事  
・当方の作業は **/dev/sdb** を前提  

### ファイル構成

``` bash: ファイル構成
\
+---sdX1
+---sdX2
|   +---.disk
|   |       info
|   +---EFI
|   |   +---BOOT
|   |           BOOTX64.CSV
|   |           BOOTX64.EFI
|   |           grub.cfg
|   |           grubx64.efi
|   |           mmx64.efi
|   +---boot
|       +---grub
|           |   grub.cfg
|           |   grubenv
|           +---fonts
|           |       unicode.pf2
|           +---i386-pc
|           |       …
|           +---locale
|           |       …
|           +---x86_64-efi
|                   …
+---sdX3
    |   menu.cfg
    +---casper
    |   +---ubuntu.focal.server
    |   |       initrd.img
    |   |       vmlinuz.img
    |   +---ubuntu.jammy.server
    |   |       …
    |   +---ubuntu.kinetic.server
    |   |       …
    |   +---ubuntu.lunar.desktop
    |   |       …
    |   +---ubuntu.lunar.server
    |           …
    +---images
    |       AlmaLinux-9-latest-x86_64-boot.iso
    |       CentOS-Stream-9-latest-x86_64-boot.iso
    |       Fedora-Server-netinst-x86_64-38-1.6.iso
    |       MIRACLELINUX-9.0-rtm-minimal-x86_64.iso
    |       Rocky-9-latest-x86_64-boot.iso
    |       debian-10.13.0-amd64-netinst.iso
    |       debian-11.7.0-amd64-netinst.iso
    |       debian-bookworm-DI-rc3-amd64-netinst.iso
    |       debian-live-bkworm-DI-rc3-amd64-lxde.iso
    |       debian-live-testing-amd64-lxde.iso
    |       debian-testing-amd64-netinst.iso
    |       openSUSE-Leap-15.4-NET-x86_64-Media.iso
    |       ubuntu-18.04.6-server-amd64.iso
    |       ubuntu-20.04.6-live-server-amd64.iso
    |       ubuntu-22.04.2-live-server-amd64.iso
    |       ubuntu-22.10-live-server-amd64.iso
    |       ubuntu-23.04-desktop-amd64.iso
    |       ubuntu-23.04-live-server-amd64.iso
    +---install.amd
    |   +---debian.bookworm.live
    |   |       initrd.img
    |   |       vmlinuz.img
    |   +---debian.bookworm.netinst
    |   |       …
    |   +---debian.bullseye.netinst
    |   |       …
    |   +---debian.buster.netinst
    |   |       …
    |   +---debian.testing.live
    |   |       …
    |   +---debian.testing.netinst
    |   |       …
    |   +---ubuntu.bionic.server
    |           …
    +---kickstart
    |       ks_almalinux.cfg
    |       ks_centos.cfg
    |       ks_fedora.cfg
    |       ks_miraclelinux.cfg
    |       ks_rocky.cfg
    +---live
    |   +---debian.bookworm.live
    |   |       initrd.img
    |   |       vmlinuz.img
    |   +---debian.testing.live
    |           …
    +---nocloud
    |   +---ubuntu.desktop
    |           meta-data
    |           network-config
    |           user-data
    |           vendor-data
    |   +---ubuntu.server
    |           …
    +---preseed
        +---debian
        |       preseed.cfg
        |       preseed_old.cfg
        |       preseed_old_server.cfg
        |       preseed_server.cfg
        |       sub_late_command.sh
        +---ubuntu
                preseed.cfg
                preseed_old.cfg
                preseed_old_server.cfg
                preseed_server.cfg
                sub_late_command.sh
                sub_success_command.sh
```

## 設定ファイル

### 無人インストール関連ファイル

``` bash: unattended installation configuration file
https://github.com/office-itou/Linux/tree/master/installer/source/cfg
+---autoyast
|       autoinst.xml
|       autoinst_Tumbleweed.xml
+---debian
|       preseed.cfg
|       sub_late_command.sh
+---kickstart
|       ks_almalinux.cfg
|       ks_centos.cfg
|       ks_centos8.cfg
|       ks_fedora.cfg
|       ks_miraclelinux.cfg
|       ks_miraclelinux8.cfg
|       ks_rocky.cfg
|       ks_rocky8.cfg
+---ubuntu.desktop
|       preseed.cfg
|       sub_late_command.sh
|       sub_success_command.sh
\---ubuntu.server
        meta-data
        network-config
        user-data
        vendor-data
```

### grub.cfg関連ファイル

・ [grub.cfg](https://github.com/office-itou/Linux/tree/master/installer-usbstick/exsample/grub.cfg)  
・ [menu.cfg](https://github.com/office-itou/Linux/tree/master/installer-usbstick/exsample/menu.cfg)  

