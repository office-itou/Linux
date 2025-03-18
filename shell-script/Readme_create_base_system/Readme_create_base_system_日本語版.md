# **USBメモリーに保存した設定ファイルによる自動インストール**  
  
USBメモリーに保存した設定ファイルを使用し自動インストールを行う  
(完全自動ではない)  
  
## **前提**  
  
当方の試用環境  
(各自の環境に合わせ読み替えの事)  
  
* **ストレージ、ネットワーク設定、言語設定は事前設定ファイルに設定項目がある**  
(ブートパラメーターでも設定できるが手動入力は大変なのでここでは省略)  
  
### USBメモリー:  
  
FAT32でフォーマット済み  
(今回はインストーラーから/dev/sda1で見える前提)  
  
### Virtual machine:  
  
VMware Workstation 16 Pro (16.2.5 build-20904516) or later  
  
#### ハードウェア:  
  
| デバイス  | 設定                                 |
| :-------- | :----------------------------------- |
| processor | 1processor / 2core (Intel 64bit CPU) |
| memory    | 4GiB 以上                            |
| storage   | NVMe 20GiB 以上                      |
| nic       | e1000e                               |
| sound     | ES1371                               |
  
#### ネットワーク設定(IPv4):  
  
|      項目      |           設定値           |
| :------------- | :------------------------- |
| IPアドレス     | 192.168.1.1                |
| ネットマスク   | 255.255.255.0              |
| ゲートウェイ   | 192.168.1.254              |
| ネームサーバー | 192.168.1.254              |
| ホスト名       | sv-ディストリビューション  |
  
#### インストールするアプリ類:  
  
* 下記(外部リンク)のInstall packagesを参照  
[Base system specifications](https://github.com/office-itou/Linux/blob/master/shell-script/Readme_create_base_system/Readme_base_system_specifications.md)  
  
#### 主なディレクトリー構成(Debian)  
  
* 下記(外部リンク)を参照  
[/etc/](https://github.com/office-itou/Linux/blob/master/shell-script/Readme_specification/Readme_tree_etc.md)  
[/srv/](https://github.com/office-itou/Linux/blob/master/shell-script/Readme_specification/Readme_tree_srv.md)  
  
## **自動インストール**  
  
**Intel 64bit CPUを想定**  
  
### **Debian preseed編**  
  
* ここでは次のISOイメージを使用する  
[mini.iso](https://deb.debian.org/debian/dists/stable/main/installer-amd64/current/images/netboot/mini.iso) stable  
  
* USBメモリーの同じ所に次の3ファイルを保存する  
  
|                                                         ファイル名                                                                           | 用途                                         |
| :------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [preseed.cfg](https://github.com/office-itou/Linux/blob/master/shell-script/conf/_fixed_address/preseed.cfg)                                 | 事前設定ファイル                             |
| [preseed_kill_dhcp.sh](https://github.com/office-itou/Linux/blob/master/shell-script/conf/preseed/preseed_kill_dhcp.sh)                      | ネットワーク設定の補助シェル                 |
| [preseed_late_command.sh](https://github.com/office-itou/Linux/blob/master/shell-script/conf/preseed/preseed_late_command.sh)                | 初期設定用シェル(サンプルを実行する時に必要) |
  
* DVD(ISOイメージ)をインストール環境に設定する  
  
* USBメモリーをインストール環境に接続する  
(VMwareではパワーオンしないと接続できない)  
  
* パワーオンしDVDから起動させる  
  
* インストーラーのメニューが表示されたらブートパラメーターを編集できるようにする  
  
| 環境     | キー |
| :------: | :--: |
| isolinux | TAB  |
| grub     | e    |
  
* ブートパラメーターの最後に 'auto=true' と入力する  
  
* インストーラーを起動する  
  
| 環境     | キー  |
| :------: | :---: |
| isolinux | Enter |
| grub     | F10   |
  
* 入力待ちになったら以下を実行する  
ホスト名とドメイン名を入力し 'Enter'  
  
* 入力待ちになったら以下を実行する  
(DebianのみUSBメモリーを手動でマウントさせる)  
  
'Alt+F2' キーを押し別のコンソール画面を開く  
  
``` bash:
modprobe vfat
mount /dev/sda1 /mnt
ls -l /mnt
```
  
'Alt+F1' キーを押し元のコンソール画面を戻る  
入力欄に 'file:///mnt/preseed.cfg' を入力し 'Enter'  
  
* インストールの完了後に再起動される  
(環境によってはDVDドライブより起動されるので注意)
  
### **Ubuntu cloud-init編**  
  
* ここでは次のISOイメージを使用する  
[ubuntu-24.04.2-live-server-amd64.iso](https://releases.ubuntu.com/noble/ubuntu-24.04.2-live-server-amd64.iso)  
  
* USBメモリーのボリュームラベルに 'CIDATA' と設定する  
  
* USBメモリーのルートに次の5ファイルを保存する  
  
|                                                         ファイル名                                                                           | 用途                                         |
| :------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [vendor-data](https://github.com/office-itou/Linux/blob/master/shell-script/conf/nocloud/ubuntu_server/vendor-data)                          | 空ファイル                                   |
| [meta-data](https://github.com/office-itou/Linux/blob/master/shell-script/conf/nocloud/ubuntu_server/meta-data)                              | 空ファイル                                   |
| [network-config](https://github.com/office-itou/Linux/blob/master/shell-script/conf/nocloud/ubuntu_server/network-config)                    | 空ファイル                                   |
| [user-data](https://github.com/office-itou/Linux/blob/master/shell-script/conf/_fixed_address/user-data)                                     | ユーザーデーター                             |
| [nocloud_late_command.sh](https://github.com/office-itou/Linux/blob/master/shell-script/conf/nocloud/ubuntu_server/nocloud_late_command.sh)  | 初期設定用シェル(サンプルを実行する時に必要) |
  
* ブートパラメーターの編集前までは”Debian preseed編”と同じ  
(コピーするファイルはこちらの内容で)  
  
* ブートパラメーターの最後に 'autoinstall' と入力する  
  
* インストーラーを起動する  
(”Debian preseed編”と同じ)  
  
* インストールの完了後に再起動される  
(環境によってはDVDドライブより起動されるので注意)  
  
### **RHEL系 kickstart編**  
  
* ここでは次のISOイメージを使用する  
[AlmaLinux-9-latest-x86_64-boot.iso](https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso)  
  
* USBメモリーの同じ所に次の2ファイルを保存する  
  
|                                                         ファイル名                                                                           | 用途                                         |
| :------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [kickstart.cfg](https://github.com/office-itou/Linux/blob/master/shell-script/conf/_fixed_address/kickstart.cfg)                             | 事前設定ファイル                             |
| [late_command.sh](https://github.com/office-itou/Linux/blob/master/shell-script/conf/kickstart/late_command.sh)                              | 初期設定用シェル(サンプルを実行する時に必要) |
  
* ブートパラメーターの編集前までは”Debian preseed編”と同じ  
(コピーするファイルはこちらの内容で)  
  
* ブートパラメーターの最後に 'inst.ks=hd:sda1=/kickstart.cfg' と入力する  
  
* インストーラーを起動する  
(”Debian preseed編”と同じ)  
  
* インストールの完了後に再起動される  
(環境によってはDVDドライブより起動されるので注意)  
  
### **openSUSE autoyast編**  
  
* ここでは次のISOイメージを使用する  
[openSUSE-Leap-15.6-DVD-x86_64-Media.iso](https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Media.iso)  
  
* USBメモリーの同じ所に次の2ファイルを保存する  
  
|                                                         ファイル名                                                                           | 用途                                         |
| :------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------- |
| [autoinst.xml](https://github.com/office-itou/Linux/blob/master/shell-script/conf/_fixed_address/autoinst.xml)                               | 事前設定ファイル                             |
| [late_command.sh](https://github.com/office-itou/Linux/blob/master/shell-script/conf/autoyast/late_command.sh)                               | 初期設定用シェル(サンプルを実行する時に必要) |
  
* ブートパラメーターの編集前までは”Debian preseed編”と同じ  
(コピーするファイルはこちらの内容で)  
  
* ブートパラメーターの最後に 'autoyast=usb://autoinst.xml' と入力する  
  
* インストーラーを起動する  
(”Debian preseed編”と同じ)  
  
* インストール処理  
(通信環境によるが完了までかなりの時間がかかる)  
  
* インストールの完了後に再起動される  
(環境によってはDVDドライブより起動されるので注意)  
  
## 参考  
  
### githubからのダウンロード  
右上に 'Download raw file' のボタンが有るのでそれをクリックしてダウンロードする  
  
### 事前設定ファイルの作成例  
  
* Debian 12 ～  
preseed server 仕様  
  
``` bash: Debian preseed
wget -O - https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script/conf/preseed/ps_debian_server.cfg | \
sed -e '\%debian-installer/locale[ \t]\+string%              s/^#./  /' \
    -e '\%debian-installer/language[ \t]\+string%            s/^#./  /' \
    -e '\%debian-installer/country[ \t]\+string%             s/^#./  /' \
    -e '\%localechooser/supported-locales[ \t]\+multiselect% s/^#./  /' \
    -e '\%keyboard-configuration/xkb-keymap[ \t]\+select%    s/^#./  /' \
    -e '\%keyboard-configuration/toggle[ \t]\+select%        s/^#./  /' \
    -e '\%netcfg/enable[ \t]\+boolean%                       s/^#./  /' \
    -e '\%netcfg/disable_autoconfig[ \t]\+boolean%           s/^#./  /' \
    -e '\%netcfg/dhcp_options[ \t]\+select%                  s/^#./  /' \
    -e '\%IPv4 example%,\%IPv6 example% {                             ' \
    -e '\%netcfg/get_ipaddress[ \t]\+string%                 s/^#./  /' \
    -e '\%netcfg/get_netmask[ \t]\+string%                   s/^#./  /' \
    -e '\%netcfg/get_gateway[ \t]\+string%                   s/^#./  /' \
    -e '\%netcfg/get_nameservers[ \t]\+string%               s/^#./  /' \
    -e '\%netcfg/confirm_static[ \t]\+boolean%               s/^#./  /' \
    -e '}'                                                              \
    -e '\%netcfg/get_hostname[ \t]\+string%                  s/^#./  /' \
    -e '\%netcfg/get_domain[ \t]\+string%                    s/^#./  /' \
    -e '\%apt-setup/services-select[ \t]\+multiselect%       s/^#./  /' \
    -e '\%preseed/run[ \t]\+string%,\%[^\\]$%                s/^#./  /' \
>   preseed.cfg
```
  
* Ubuntu 24.04 ～  
cloud-init server 仕様  
  
``` bash: Ubuntu cloud-init
wget -O - https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script/conf/nocloud/ubuntu_server/user-data | \
sed -e '/^#[ \t]\+[-=]\+[ \t]\+ipv4:[ \t]\+static[ \t]\+[-=]\+$/,/^\# [-=]\+\(\|[ \t]\+ipv4:[ \t]\+.*\)[-=]\+\(\|.*\)$/{' \
    -e '/^\# [-=]\+\(\|[ \t]\+ipv4:[ \t]\+.*\)[-=]\+\(\|.*\)$/! s/^#/ /g}' \
>   user-data

```
  
* RHEL-9系 ～  
kickstart server 仕様  
  
``` bash: AlmaLinux-9
wget -O - https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script/conf/kickstart/ks_almalinux-9_net.cfg | \
sed -e '/Network information/,/^$/ {' \
    -e '/network/ s/^#//           }' \
>   kickstart.cfg
```
  
* openSUSE-Leap-15.6 ～  
autoyast server 仕様  
  
``` bash: openSUSE-Leap-15.6
wget -O - https://raw.githubusercontent.com/office-itou/Linux/refs/heads/master/shell-script/conf/autoyast/autoinst_leap-15.6_net.xml | \
sed -e '\%<networking .*>%,\%</networking>% { ' \
    -e '/<!-- fixed address$/ s/$/ -->/g      ' \
    -e '/^fixed address -->/  s/^/<!-- /g   } ' \
>   autoinst.xml
```
  
