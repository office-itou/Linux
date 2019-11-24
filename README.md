Debian/Ubuntu/CentOS/Knoppixのカスタマイズ  
  
**日本語化やインストール補助に以下のシェルを作成しました。**  
・Debian/Ubuntu/KnoppixのLive DVDイメージのカスタマイズ  
・Debian/Ubuntu/CentOS7/CentOS8のインストールDVDイメージのカスタマイズ  
・Debian/Ubuntuのインストールmini.isoイメージのカスタマイズ  
・Debian/Ubuntu/CrntOS7/CentOS8のインストール補助(VMware対応)  
*※VMware14上でmbrとuefi環境で動作確認*  
  
**Live CD用** (日本語化とDebian/Ubuntuのモジュール最新化)  
・[debian-lxde.sh](https://github.com/office-itou/Linux/blob/master/customize/debian-lxde.sh?ts=4)  
・[ubuntu-live.sh](https://github.com/office-itou/Linux/blob/master/customize/ubuntu-live.sh?ts=4)  
・[knoppix-live.sh](https://github.com/office-itou/Linux/blob/master/customize/knoppix-live.sh?ts=4)  (Debian 9での作業を推奨)  
  
**DVD用** (preseed.cfg,kickstart.cfgを使用した無人インストールの実現)   
・[dist_remaster_dvd.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_dvd.sh?ts=4)  
**mini.iso用** (preseed.cfgを使用した無人インストールの実現)   
・[dist_remaster_mini.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_mini.sh?ts=4)  
  
**preseed.cfg** (OSの無人インストール設定)  
・[preseed_debian.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_debian.cfg?ts=4)  
・[preseed_ubuntu.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_ubuntu.cfg?ts=4) (mini.iso使用を推奨、DVDでは全機能の導入がされない)  
**kickstart.cfg** (OSの無人インストール設定)  
・[kickstart_centos.cfg](https://github.com/office-itou/Linux/blob/master/installer/kickstart_centos.cfg?ts=4)  
  
**Debian/Ubuntu/CentOS7環境設定** (OS導入後の環境設定)  
・[install.sh](https://github.com/office-itou/Linux/blob/master/installer/install.sh?ts=4)  
  
**preseed.cfgの環境設定値例** (各自の環境に合わせて変更願います)  
参照：[preseedの利用](https://www.debian.org/releases/stable/amd64/apbs02.html.ja)  
  
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
**使用例**

```text:dist_remaster_dvd.sh
master@sv-debian:~/iso$ sudo ./dist_remaster_dvd.sh
*******************************************************************************
2018/05/06 09:50:44 作成処理を開始します。
*******************************************************************************
# ---------------------------------------------------------------------------#
# ID：Version                       ：リリース日：サポ終了日：備考           #
#  1：debian-7.11.0-amd64-DVD-1     ：2013-05-04：2018-05-31：oldoldstable   #
#  2：debian-8.10.0-amd64-DVD-1     ：2015-04-25：2020-04-xx：oldstable      #
#  3：debian-9.4.0-amd64-DVD-1      ：2017-06-17：2022-xx-xx：stable         #
#  4：ubuntu-14.04.5-server-amd64   ：2014-04-17：2019-04-xx：Trusty Tahr    #
#  5：ubuntu-14.04.5-desktop-amd64  ：    〃    ：    〃    ：  〃           #
#  6：ubuntu-16.04.4-server-amd64   ：2016-04-21：2021-04-xx：Xenial Xerus   #
#  7：ubuntu-16.04.4-desktop-amd64  ：    〃    ：    〃    ：  〃           #
#  8：ubuntu-17.10.1-server-amd64   ：2017-10-19：2018-07-xx：Artful Aardvark#
#  9：ubuntu-17.10.1-desktop-amd64  ：    〃    ：    〃    ：  〃           #
# 10：ubuntu-18.04-server-amd64     ：2018-04-26：2023-04-xx：Bionic Beaver  #
# 11：ubuntu-18.04-desktop-amd64    ：    〃    ：    〃    ：  〃           #
# 12：ubuntu-18.04-live-server-amd64：    〃    ：    〃    ：  〃           #
# 13：CentOS-7-x86_64-DVD-1708      ：2017-09-14：2024-06-30：               #
# ---------------------------------------------------------------------------#
ID番号+Enterを入力して下さい。
{1..11} 13
   ～ 省略 ～
```

```text:dist_remaster_mini.sh
master@sv-debian:~/iso$ sudo ./dist_remaster_mini.sh
*******************************************************************************
2018/05/06 09:42:07 作成処理を開始します。
*******************************************************************************
# ---------------------------------------------------------------------------#
# ID：Version     ：コードネーム    ：リリース日：サポ終了日：備考           #
#  1：Debian  7.xx：wheezy          ：2013-05-04：2018-05-31：oldoldstable   #
#  2：Debian  8.xx：jessie          ：2015-04-25：2020-04-xx：oldstable      #
#  3：Debian  9.xx：stretch         ：2017-06-17：2022-xx-xx：stable         #
#  4：Debian 10.xx：buster          ：2019(予定)：          ：testing        #
#  5：Ubuntu 14.04：Trusty Tahr     ：2014-04-17：2019-04-xx：               #
#  6：Ubuntu 16.04：Xenial Xerus    ：2016-04-21：2021-04-xx：               #
#  7：Ubuntu 17.10：Artful Aardvark ：2017-10-19：2018-07-xx：               #
#  8：Ubuntu 18.04：Bionic Beaver   ：2018-04-26：2023-04-xx：               #
# ---------------------------------------------------------------------------#
ID番号+Enterを入力して下さい。
{1..8}
  ～ 省略 ～
*******************************************************************************
2018/05/06 09:44:59 作成処理が終了しました。
*******************************************************************************
```
