**Debian/Ubuntu/CentOS/Fedora/OpenSUSEの無人インストール用メディアのカスタマイズ**  
  
【事前準備】  
  
・開発環境  
　**Debian 11.2.0 64bit版**  
  
・実行確認  
　**debian 11.2.0 / ubuntu 21.10 / CentOS 8.5.2111 / Fedora 35-1.2 / openSUSE 15.3 各64bit版**  
  
【無人インストールISO作成シェル】  
  
| ファイル名              | 機能                  |
| ----------------------- | --------------------- |
| [dist_remaster_dvd.sh](https://github.com/office-itou/Linux/blob/master/installer/source/dist_remaster_dvd.sh)    | DVDイメージ用         |
| [dist_remaster_mini.sh](https://github.com/office-itou/Linux/blob/master/installer/source/dist_remaster_mini.sh)   | mini.iso用            |
| [dist_remaster_net.sh](https://github.com/office-itou/Linux/blob/master/installer/source/dist_remaster_net.sh)    | net installファイル用 |
  
【無人インストール定義ファイル】  
  
| ファイル名              | 機能     |
| ----------------------- | -------- |
| [preseed_debian.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/preseed_debian.cfg)      | debian用 |
| [preseed_ubuntu.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/preseed_ubuntu.cfg)      | ubuntu用 |
| [kickstart_centos.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/kickstart_centos.cfg)    | CentOS用 |
| [kickstart_fedora.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/kickstart_fedora.cfg)    | Fedora用 |
| [kickstart_miraclelinux.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/kickstart_miraclelinux.cfg)    | MIRACLELINUX用 |
| [kickstart_rocky.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/kickstart_rocky.cfg)    | Rocky Linux用 |
| [yast_opensuse.xml](https://github.com/office-itou/Linux/blob/master/installer/source/yast_opensuse.xml) | OpenSUSE用 |
| [nocloud-ubuntu-user-data](https://github.com/office-itou/Linux/blob/master/installer/source/nocloud-ubuntu-user-data) | ubuntu用nocloud |

  
【インストール補助作業シェル】  
  
| ファイル名              | 機能                |
| ----------------------- | ------------------- |
| [install.sh](https://github.com/office-itou/Linux/blob/master/installer/source/install.sh)              | インストール作業用  |
| [addusers.sh](https://github.com/office-itou/Linux/blob/master/installer/source/addusers.sh)             | ユーザー登録用      |
| [addusers_txt_maker.sh](https://github.com/office-itou/Linux/blob/master/installer/source/addusers_txt_maker.sh)   | 登録ユーザー取得用  |
| [cloud_preseed.sh](https://github.com/office-itou/Linux/blob/master/installer/source/cloud_preseed.sh)   | preseed.cfg→user-data変換  |
  
【メニュー画面】  
**文字色について**  
　・白：作成不要（ローカルが最新）  
　・黄：作成必要（ローカルが古い）  
　・赤：通信障害（ダウンロード不可）  
**ログについて**  
　・exec &> >(tee -a "working.log") でのログ取得が可能
  
| 作業内容              | スクリーンショット                                                              |
| --------------------- | ------------------------------------------------------------------------------- |
| dist_remaster_dvd.sh  | ![dist_remaster_dvd.sh](https://github.com/office-itou/Linux/blob/master/installer/picture/dist_remaster_dvd.sh.jpg) |
| dist_remaster_mini.sh | ![dist_remaster_mini.sh](https://github.com/office-itou/Linux/blob/master/installer/picture/dist_remaster_mini.sh.jpg) |
| dist_remaster_net.sh  | ![dist_remaster_net.sh](https://github.com/office-itou/Linux/blob/master/installer/picture/dist_remaster_net.sh.jpg) |
  
**preseed.cfgの環境設定値例** (各自の環境に合わせて変更願います)  
　*※USBメモリーからMBR環境にインストールする場合は以下の様に変更願います。*  
　・partman-auto/disk string /dev/sdb ← 実際のドライブに合わせる  
　・grub-installer/bootdev string /dev/sdb ← 実際のドライブに合わせる  
　　参照：[preseedの利用](https://www.debian.org/releases/stable/amd64/apbs02.ja.html)  
  
```text
# == Network configuration ====================================================
  d-i netcfg/choose_interface select auto
  d-i netcfg/disable_dhcp boolean true
# -- Static network configuration. --------------------------------------------
  d-i netcfg/get_ipaddress string 192.168.1.1
  d-i netcfg/get_netmask string 255.255.255.0
  d-i netcfg/get_gateway string 192.168.1.254
  d-i netcfg/get_nameservers string 192.168.1.254
  d-i netcfg/confirm_static boolean true
# -- hostname and domain names ------------------------------------------------
  d-i netcfg/get_hostname string sv-debian
  d-i netcfg/get_domain string workgroup
```
  
```text
# == Account setup ============================================================
  d-i passwd/root-login boolean false
  d-i passwd/make-user boolean true
# -- Root password, either in clear text or encrypted -------------------------
# d-i passwd/root-password password r00tme
# d-i passwd/root-password-again password r00tme
# d-i passwd/root-password-crypted password [crypt(3) hash]
# -- Normal user's password, either in clear text or encrypted ----------------
  d-i passwd/user-fullname string Master
  d-i passwd/username string master
  d-i passwd/user-password password master
  d-i passwd/user-password-again password master
# d-i passwd/user-password-crypted password [crypt(3) hash]
```
  
```text
# == Package selection ========================================================
  tasksel tasksel/first multiselect \
    desktop, lxde-desktop, ssh-server, web-server
  d-i pkgsel/include string \
    sudo tasksel network-manager curl bc \
    perl apt-show-versions libapt-pkg-perl libauthen-pam-perl libio-pty-perl libnet-ssleay-perl perl-openssl-defaults \
    clamav bind9 dnsutils apache2 vsftpd isc-dhcp-server ntpdate samba smbclient cifs-utils rsync \
    chromium chromium-l10n
```
  
【ダウンロード用コピペ】  
  
```text
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/addusers.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/addusers_txt_maker.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cloud_preseed.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/dist_remaster_dvd.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/dist_remaster_mini.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/dist_remaster_net.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/install.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_centos.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_fedora.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_miraclelinux.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_rocky.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/nocloud-ubuntu-meta-data"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/nocloud-ubuntu-user-data"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_debian.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_ubuntu.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/yast_opensuse.xml"
chmod u+x *.sh
```
  
