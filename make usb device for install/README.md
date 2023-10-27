# mk_usb4inst.sh (make usb device for install)  
  
複数のインストールISOファイルに対応したUSBデバイスの作成 (exFAT対応)  
(当作業では128GBのUSBメモリーの利用を想定)  
  
## 起動方法  
  
sudo ./mk_usb4inst.sh -d sdX [ -s sdX ] [ -f ntfs ]  
  
| オプション | 機能 |  
| --- | --- |  
| -d or --device sdX  | 本作業で作成するUSBデバイス名 [sda～sdz] |  
| -s or --source sdX  | インストール作業時のUSBデバイス名 [sda～sdz] (未指定時 sda) |  
| -f or --format ntfs | フォーマットの種類 [ntfs] (未指定時 exFAT) |  
| -n or --noformat    | フォーマット作業のスキップ (作成済みメディアに対する作業用) |  
  
> [!NOTE]  
> **openSUSE** のDVD版は **NTFS** でのみ利用可能  
> （ **exFAT** でメディア検索ができない）  
  
## 作業環境  
  
### OS  
  
| OS名 |  
| --- |  
| Debian 12 (bookworm) |  
  
### 必須パッケージ  
  
| パッケージ名 |  
| --- |  
| fdisk |  
| coreutils |  
| curl |  
| exfatprogs |  
| ntfs-3g |  
| dosfstools |  
| grub2-common |  
| grub-pc-bin |  
| initramfs-tools-core |  
| cpio |  
| gzip |  
| bzip2 |  
| lz4 |  
| lzma |  
| lzop |  
| xz-utils |  
| zstd |  
| po-debconf |  
  
## USBメモリーの構成  
  
### パーティション構成
  
| NAME | TYPE | TRAN | FSTYPE | FSVER | LABEL   | SIZE   | VENDOR   | MODEL           |  
| ---  | ---  | ---  | ---    | ---   | ---     | ---:   | ---      | ---             |  
| sdX  | disk | usb  |        |       |         | 112.6G | JetFlash | Transcend 128GB |  
| sdX1 | part |      |        |       |         | 1007K  |          |                 |  
| sdX2 | part |      | vfat   | FAT32 |         | 256M   |          |                 |  
| sdX3 | part |      | ntfs   |       | ISOFILE | 112.4G |          |                 |  
  
(lsblk -o NAME,TYPE,TRAN,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdX)  
  
### ディレクトリー/ファイル構成
  
``` text:  
sdX3: \  
|   menu.cfg  
|  
+---autoyast  
|       autoinst_leap_15.5_dvd.xml  
|       autoinst_leap_15.5_net.xml  
|       autoinst_leap_15.6_dvd.xml  
|       autoinst_leap_15.6_net.xml  
|       autoinst_tumbleweed_dvd.xml  
|       autoinst_tumbleweed_net.xml  
|  
+---casper  
|   +---ubuntu.focal.server  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.jammy.server  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.lunar.desktop  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.lunar.legacy  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.lunar.server  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.mantic.desktop  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   +---ubuntu.mantic.legacy  
|   |       initrd.gz  
|   |       vmlinuz  
|   |  
|   \---ubuntu.mantic.server  
|           initrd.gz  
|           vmlinuz  
|  
+---images  
|       AlmaLinux-9-latest-x86_64-boot.iso  
|       AlmaLinux-9-latest-x86_64-dvd.iso  
|       CentOS-Stream-9-latest-x86_64-boot.iso  
|       CentOS-Stream-9-latest-x86_64-dvd1.iso  
|       debian-10.13.0-amd64-netinst.iso  
|       debian-11.8.0-amd64-netinst.iso  
|       debian-12.2.0-amd64-DVD-1.iso  
|       debian-12.2.0-amd64-netinst.iso  
|       debian-live-12.2.0-amd64-lxde.iso  
|       debian-live-testing-amd64-lxde.iso  
|       debian-testing-amd64-DVD-1.iso  
|       debian-testing-amd64-netinst.iso  
|       Fedora-Server-dvd-x86_64-38-1.6.iso  
|       Fedora-Server-netinst-x86_64-37-1.7.iso  
|       Fedora-Server-netinst-x86_64-38-1.6.iso  
|       MIRACLELINUX-9.2-rtm-minimal-x86_64.iso  
|       MIRACLELINUX-9.2-rtm-x86_64.iso  
|       openSUSE-Leap-15.5-DVD-x86_64-Media.iso  
|       openSUSE-Leap-15.5-NET-x86_64-Media.iso  
|       openSUSE-Leap-15.6-DVD-x86_64-Media.iso  
|       openSUSE-Leap-15.6-NET-x86_64-Media.iso  
|       openSUSE-Tumbleweed-DVD-x86_64-Current.iso  
|       openSUSE-Tumbleweed-NET-x86_64-Current.iso  
|       Rocky-9-latest-x86_64-boot.iso  
|       Rocky-9-latest-x86_64-dvd.iso  
|       ubuntu-20.04.6-live-server-amd64.iso  
|       ubuntu-22.04.3-live-server-amd64.iso  
|       ubuntu-23.04-desktop-amd64.iso  
|       ubuntu-23.04-desktop-legacy-amd64.iso  
|       ubuntu-23.04-live-server-amd64.iso  
|       ubuntu-23.10-desktop-legacy-amd64.iso  
|       ubuntu-23.10-live-server-amd64.iso  
|       ubuntu-23.10.1-desktop-amd64.iso  
|  
+---install.amd  
|   +---debian.bookworm.dvd  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   +---gtk  
|   |   |       initrd.gz  
|   |   |       vmlinuz  
|   |   |  
|   |   \---xen  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.bookworm.live  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   \---gtk  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.bookworm.netinst  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   +---gtk  
|   |   |       initrd.gz  
|   |   |       vmlinuz  
|   |   |  
|   |   \---xen  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.bullseye.netinst  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   +---gtk  
|   |   |       initrd.gz  
|   |   |       vmlinuz  
|   |   |  
|   |   \---xen  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.buster.netinst  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   +---gtk  
|   |   |       initrd.gz  
|   |   |       vmlinuz  
|   |   |  
|   |   \---xen  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.testing.dvd  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   +---gtk  
|   |   |       initrd.gz  
|   |   |       vmlinuz  
|   |   |  
|   |   \---xen  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   +---debian.testing.live  
|   |   |   initrd.gz  
|   |   |   vmlinuz  
|   |   |  
|   |   \---gtk  
|   |           initrd.gz  
|   |           vmlinuz  
|   |  
|   \---debian.testing.netinst  
|       |   initrd.gz  
|       |   vmlinuz  
|       |  
|       +---gtk  
|       |       initrd.gz  
|       |       vmlinuz  
|       |  
|       \---xen  
|               initrd.gz  
|               vmlinuz  
|  
+---kickstart  
|       ks_almalinux-9_dvd.cfg  
|       ks_almalinux-9_net.cfg  
|       ks_centos-9_dvd.cfg  
|       ks_centos-9_net.cfg  
|       ks_fedora-37_net.cfg  
|       ks_fedora-38_dvd.cfg  
|       ks_fedora-38_net.cfg  
|       ks_miraclelinux-9_dvd.cfg  
|       ks_miraclelinux-9_net.cfg  
|       ks_rockylinux-9_dvd.cfg  
|       ks_rockylinux-9_net.cfg  
|  
+---live  
|   +---debian.bookworm.live  
|   |       initrd.gz  
|   |       initrd.gz-6.1.0-13-amd64  
|   |       vmlinuz  
|   |       vmlinuz-6.1.0-13-amd64  
|   |  
|   \---debian.testing.live  
|           initrd.gz  
|           initrd.gz-6.5.0-2-amd64  
|           vmlinuz  
|           vmlinuz-6.5.0-2-amd64  
|  
+---nocloud  
|   +---ubuntu.desktop  
|   |       meta-data  
|   |       network-config  
|   |       user-data  
|   |       vendor-data  
|   |  
|   \---ubuntu.server  
|           meta-data  
|           network-config  
|           user-data  
|           vendor-data  
|  
\---preseed  
    +---debian  
    |       preseed.cfg  
    |       preseed_old.cfg  
    |       preseed_old_server.cfg  
    |       preseed_server.cfg  
    |       preseed_sub_command.sh  
    |  
    \---ubuntu  
            preseed.cfg  
            preseed_old.cfg  
            preseed_old_server.cfg  
            preseed_server.cfg  
            preseed_sub_command.sh  
```  
