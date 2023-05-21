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

### [ファイル構成](https://github.com/office-itou/Linux/tree/master/installer-usbstick/document/USB-stick_tree_map.txt)

## 設定ファイル

### [無人インストール関連ファイル](https://github.com/office-itou/Linux/tree/master/installer/source/cfg)

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

