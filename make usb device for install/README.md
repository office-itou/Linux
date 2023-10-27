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
> openSUSEのDVD版は`NTFS`でのみ利用可能  
> （`exFAT`でメディア検索ができない）  

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

master@sv-server:~/mkcd$ lsblk -o NAME,TYPE,TRAN,FSTYPE,FSVER,LABEL,SIZE,MOUNTPOINTS,VENDOR,MODEL /dev/sdb
| NAME | TYPE | TRAN | FSTYPE | FSVER | LABEL   | SIZE   | MOUNTPOINTS | VENDOR   | MODEL           |
| ---  | ---  | ---  | ---    | ---   | ---     | ---    | ---         |          | ---             |
| sdb  | disk | usb  |        |       |         | 112.6G |             | JetFlash | Transcend 128GB |
| sdb1 | part |      |        |       |         | 1007K  |             |          |                 |
| sdb2 | part |      | vfat   | FAT32 |         | 256M   |             |          |                 |
| sdb3 | part |      | ntfs   |       | ISOFILE | 112.4G |             |          |                 |

