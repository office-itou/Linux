**Debian/Ubuntu/CentOS/Fedoraのカスタマイズ**  
  
【無人インストールISO作成シェル】  
  
| ファイル名              | 機能                  |
| ----------------------- | --------------------- |
| [dist_remaster_dvd.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_dvd.sh)    | DVDイメージ用         |
| [dist_remaster_mini.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_mini.sh)   | mini.iso用            |
| [dist_remaster_net.sh](https://github.com/office-itou/Linux/blob/master/installer/dist_remaster_net.sh)    | net installファイル用 |
  
【無人インストール定義ファイル】  
  
| ファイル名              | 機能     |
| ----------------------- | -------- |
| [preseed_debian.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_debian.cfg)      | debian用 |
| [preseed_ubuntu.cfg](https://github.com/office-itou/Linux/blob/master/installer/preseed_ubuntu.cfg)      | ubuntu用 |
| [kickstart_centos.cfg](https://github.com/office-itou/Linux/blob/master/installer/kickstart_centos.cfg)    | CentOS用 |
| [kickstart_fedora.cfg](https://github.com/office-itou/Linux/blob/master/installer/kickstart_fedora.cfg)    | Fedora用 |
  
【インストール補助作業ファイル】  
  
| ファイル名              | 機能                |
| ----------------------- | ------------------- |
| [install.sh](https://github.com/office-itou/Linux/blob/master/installer/install.sh)              | インストール作業用  |
| [addusers.sh](https://github.com/office-itou/Linux/blob/master/installer/addusers.sh)             | ユーザー登録用      |
| [addusers_txt_maker.sh](https://github.com/office-itou/Linux/blob/master/installer/addusers_txt_maker.sh)   | 登録ユーザー取得用  |
  
【メニュー画面】  
  
| 作業内容              | スクリーンショット                                                              |
| --------------------- | ------------------------------------------------------------------------------- |
| dist_remaster_dvd.sh  | # ----------------------------------------------------------------------------# |
|                       | # ID：Version                        ：リリース日：サポ終了日：備考           # |
|                       | #  1：debian-8.11.1-amd64-DVD-1      ：2015-04-25：2020-04-xx：oldoldstable   # |
|                       | #  2：debian-9.12.0-amd64-DVD-1      ：2017-06-17：2022-xx-xx：oldstable      # |
|                       | #  3：debian-10.3.0-amd64-DVD-1      ：2019-07-06：20xx-xx-xx：stable         # |
|                       | #  4：debian-testing-amd64-DVD-1     ：20xx-xx-xx：20xx-xx-xx：testing        # |
|                       | #  5：ubuntu-16.04.6-server-amd64    ：2016-04-21：2021-04-xx：Xenial Xerus   # |
|                       | #  6：ubuntu-16.04.6-desktop-amd64   ：    〃    ：    〃    ：  〃           # |
|                       | #  7：ubuntu-18.04.4-server-amd64    ：2018-04-26：2023-04-xx：Bionic Beaver  # |
|                       | #  8：ubuntu-18.04.4-desktop-amd64   ：    〃    ：    〃    ：  〃           # |
|                       | #  9：ubuntu-19.10-server-amd64      ：2019-10-17：2020-07-xx：Eoan Ermine    # |
|                       | # 10：ubuntu-19.10-desktop-amd64     ：    〃    ：    〃    ：  〃           # |
|                       | # 11：CentOS-8.1.1911-x86_64-dvd1    ：2019-09-24：2029-05-31：RHEL 8.0       # |
|                       | # 12：CentOS-Stream-8-x86_64-20191219：2019-xx-xx：20xx-xx-xx：RHEL x.x       # |
|                       | # 13：Fedora-Server-dvd-x86_64-31-1.9：2019-10-29：20xx-xx-xx：kernel 5.3     # |
|                       | # ----------------------------------------------------------------------------# |
  
| 作業内容              | スクリーンショット                                                              |
| --------------------- | ------------------------------------------------------------------------------- |
| dist_remaster_mini.sh | # ---------------------------------------------------------------------------#  |
|                       | # ID：Version     ：コードネーム    ：リリース日：サポ終了日：備考           #  |
|                       | #  1：Debian  8.xx：jessie          ：2015-04-25：2020-06-30：oldoldstable   #  |
|                       | #  2：Debian  9.xx：stretch         ：2017-06-17：2022-06-xx：oldstable      #  |
|                       | #  3：Debian 10.xx：buster          ：2019-07-06：          ：stable         #  |
|                       | #  4：Debian 11.xx：bullseye        ：2021-xx-xx：          ：testing        #  |
|                       | #  5：Ubuntu 16.04：Xenial Xerus    ：2016-04-21：2021-04-xx：LTS            #  |
|                       | #  6：Ubuntu 18.04：Bionic Beaver   ：2018-04-26：2023-04-xx：LTS            #  |
|                       | #  7：Ubuntu 19.04：Disco Dingo     ：2019-04-18：2020-01-23：               #  |
|                       | #  8：Ubuntu 19.10：Eoan Ermine     ：2019-10-17：2020-07-xx：               #  |
|                       | #  9：Ubuntu 20.04：Focal Fossa     ：2020-04-23：2025-04-xx：LTS            #  |
|                       | # ---------------------------------------------------------------------------#  |
  
| 作業内容              | スクリーンショット                                                              |
| --------------------- | ------------------------------------------------------------------------------- |
| dist_remaster_net.sh  | # ----------------------------------------------------------------------------# |
|                       | # ID：Version                            ：リリース日：サポ終了日：備考       # |
|                       | #  1：debian-8.11.1-amd64-netinst        ：2015-04-25：2020-06-30：oldoldstable |
|                       | #  2：debian-9.12.0-amd64-netinst        ：2017-06-17：2022-06-xx：oldstable  # |
|                       | #  3：debian-10.3.0-amd64-netinst        ：2019-07-06：20xx-xx-xx：stable     # |
|                       | #  4：debian-testing-amd64-netinst       ：20xx-xx-xx：20xx-xx-xx：testing    # |
|                       | #  5：CentOS-8.1.1911-x86_64-boot        ：2019-09-24：2029-05-31：RHEL 8.0   # |
|                       | #  6：CentOS-Stream-8-x86_64-20191219-boo：20xx-xx-xx：20xx-xx-xx：RHEL x.x   # |
|                       | #  7：Fedora-Server-netinst-x86_64-31-1.9：2019-10-29：20xx-xx-xx：kernel 5.3 # |
|                       | # ----------------------------------------------------------------------------# |
  
