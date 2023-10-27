# mk_usb4inst.sh (make usb device for install)

複数のインストールISOファイルに対応したUSBデバイスの作成 (exFAT対応)  
(当作業では128GBのUSBメモリーの利用を想定)

## 起動方法

sudo ./mk_usb4inst.sh -d sd[a-z] -n  

| オプション | 機能 |
| --- | --- |
| -d or --device sdX  | 本作業で作成するUSBデバイス名 [sda～sdz] |
| -s or --source sdX  | インストール作業時のUSBデバイス名 [sda～sdz] (未指定時 sda) |
| -f or --format ntfs | フォーマットの種類 [ntfs] (未指定時 exFAT) |
| -n or --noformat    | フォーマット作業のスキップ (作成済みメディアに対する作業用) |

**Warning**
openSUSEのDVD版は`NTFS`でのみ利用可能  
（`exFAT`でメディア検索ができない）  

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

