#!/bin/bash
###############################################################################
##
##	ファイル名 / 機能概要 :
##		dist_remaster_mini.sh	/	ブータブルCDの作成用シェル [mini.iso/initrd版]
##		dist_remaster_net.sh	/	ブータブルDVDの作成用シェル [netinst版]
##		dist_remaster_dvd.sh	/	ブータブルDVDの作成用シェル [DVD版]
##		live-custom.sh			/	Live diskの作成用シェル [DVD版]
##
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian (64bit)
##	---------------------------------------------------------------------------
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2021/08/16
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- ----------------------------------------
##	2021/08/16 000.0000 J.Itou         新規作成
##	2022/05/14 000.0000 J.Itou         シェル統合
##	2022/05/15 000.0000 J.Itou         不具合修正
##	2022/05/16 000.0000 J.Itou         処理見直し
##	2022/05/28 000.0000 J.Itou         AlmaLinux追加
##	2022/06/06 000.0000 J.Itou         リスト更新
##	2022/06/10 000.0000 J.Itou         処理見直し
##	2022/06/14 000.0000 J.Itou         処理見直し
##	2022/06/18 000.0000 J.Itou         処理見直し
##	2022/06/19 000.0000 J.Itou         処理見直し
##	2022/06/27 000.0000 J.Itou         処理見直し
##	2022/06/29 000.0000 J.Itou         処理見直し
##	2022/07/05 000.0000 J.Itou         処理見直し
##	2022/07/15 000.0000 J.Itou         Rocky Linux 9.0追加
##	2022/07/22 000.0000 J.Itou         不具合修正
##	2022/07/27 000.0000 J.Itou         Ubuntu 22.10 (Kinetic Kudu) Daily Build追加
##	2022/08/02 000.0000 J.Itou         リスト更新: Ubuntu 21.10 (Impish_Indri) 削除
##	2022/09/19 000.0000 J.Itou         処理見直し
##	2022/09/21 000.0000 J.Itou         処理見直し
##	2022/09/23 000.0000 J.Itou         処理見直し
##	2022/09/26 000.0000 J.Itou         処理見直し(Ubuntu 22.10 login画面対策)
##	2022/10/05 000.0000 J.Itou         処理見直し
##	2022/10/10 000.0000 J.Itou         処理見直し
##	2022/10/15 000.0000 J.Itou         リスト更新: Ubuntu 22.10 (Kinetic Kudu) Beta 追加
##	2022/10/15 000.0000 J.Itou         リスト更新: Ubuntu 22.10 (Kinetic Kudu) 変更
##	2022/11/01 000.0000 J.Itou         リスト更新: MIRACLELINUX 8.6 / 9.0 追加
##	2022/11/01 000.0000 J.Itou         リスト更新: Fedora 37 追加・その他修正
##	2022/11/23 000.0000 J.Itou         リスト更新: Ubuntu 22.10 (Kinetic Kudu) Daily Build 削除
##	2022/11/27 000.0000 J.Itou         メモ欄更新
##	2022/12/17 000.0000 J.Itou         処理見直し(Ubuntu 22.10 login画面対策)
##	2023/01/03 000.0000 J.Itou         リスト更新: CentOS 取得先変更
##	2023/02/26 000.0000 J.Itou         リスト更新: Ubuntu 23.04 (Lunar Lobster) Daily Build 追加 / Fedora 35 削除
##	2023/03/01 000.0000 J.Itou         処理見直し
##	2023/03/10 000.0000 J.Itou         処理見直し
##	2023/03/12 000.0000 J.Itou         リスト更新: Ubuntu 23.04 (Lunar Lobster) Daily Build 変更
##	2023/03/13 000.0000 J.Itou         処理見直し
##	2023/03/16 000.0000 J.Itou         不具合修正
##	2023/03/23 000.0000 J.Itou         リスト更新:
##	2023/04/01 000.0000 J.Itou         処理見直し
##	2023/04/13 000.0000 J.Itou         リスト更新: Ubuntu 23.04 (Lunar Lobster) Beta 変更
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	sudo apt-get install curl xorriso isomd5sum isolinux
# -----------------------------------------------------------------------------
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

	trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
	INP_INDX=""							# 処理ID
# -----------------------------------------------------------------------------
	FLG_LOGOUT=0						# ログ出力フラグ
	FLG_DEBUG=0							# Debugフラグ
	FLG_SKIP=0							# サブシェルスキップフラグ
	FLG_MENU=0							# メニュー画面スキップフラグ
# -----------------------------------------------------------------------------
	readonly WORK_DIRS=`basename $0 | sed -e 's/\..*$//'`	# 作業ディレクトリ名(プログラム名)
# -----------------------------------------------------------------------------
#	readonly ARC_TYPE=i386				# CPUタイプ(32bit)
	readonly ARC_TYPE=amd64				# CPUタイプ(64bit)
# -----------------------------------------------------------------------------
	ARRAY_NAME=()

	readonly ARRAY_NAME_MINI=(                                                                                                                                                                                                                                                                                                            \
	    "debian         http://deb.debian.org/debian/dists/oldoldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                   -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://deb.debian.org/debian/dists/oldstable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                      -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://deb.debian.org/debian/dists/stable/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                         -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         https://d-i.debian.org/daily-images/${ARC_TYPE}/daily/netboot/mini.iso                                                                       -                                           preseed_debian.cfg                          202x-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                             -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   bionic          Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         http://archive.ubuntu.com/ubuntu/dists/focal-updates/main/installer-${ARC_TYPE}/current/legacy-images/netboot/mini.iso                       -                                           preseed_ubuntu.cfg                          2020-04-23   2030-04-23   focal           Ubuntu_20.04(Focal_Fossa):LTS    " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                          2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2
#	    "debian         http://deb.debian.org/debian/dists/bookworm/main/installer-${ARC_TYPE}/current/images/netboot/mini.iso                                       mini-bookworm-${ARC_TYPE}.iso               preseed_debian.cfg                          202x-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \

	readonly ARRAY_NAME_NET=(                                                                                                                                                                                                                                                                                                             \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-cd/debian-[0-9.]*-amd64-netinst.iso                                 -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable   Debian__9.xx(stretch)             " \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-[0-9.]*-amd64-netinst.iso                                    -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable      Debian_10.xx(buster)              " \
	    "debian         https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-[0-9.]*-amd64-netinst.iso                                             -                                           preseed_debian.cfg                          2019-07-06   2026-xx-xx   stable         Debian_11.xx(bullseye)            " \
	    "debian         https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso                              -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing        Debian_12.xx(bookworm)            " \
	    "centos         https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-boot.iso                                           -                                           kickstart_common.cfg                        20xx-xx-xx   2024-05-31   RHEL_8.x       -                                 " \
	    "centos         https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso                              -                                           kickstart_common.cfg                        2021-xx-xx   20xx-xx-xx   RHEL_9.x       -                                 " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/x86_64/iso/Fedora-Server-netinst-x86_64-36-1.5.iso                    -                                           kickstart_common.cfg                        2022-05-10   2023-05-16   kernel_5.17     -                                " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-netinst-x86_64-37-1.7.iso                    -                                           kickstart_common.cfg                        2022-11-15   2023-11-14   kernel_6.0      -                                " \
	    "rocky          https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-[0-9.]*-x86_64-boot.iso                                                        -                                           kickstart_common.cfg                        2022-11-14   20xx-xx-xx   RHEL_8.x       -                                 " \
	    "rocky          https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-[0-9.]*-x86_64-boot.iso                                                        -                                           kickstart_common.cfg                        2022-07-14   20xx-xx-xx   RHEL_9.x       -                                 " \
	    "miraclelinux   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.6-released/x86_64/MIRACLELINUX-[0-9.]*-rtm-minimal-x86_64.iso                         -                                           kickstart_common.cfg                        2021-10-04   20xx-xx-xx   RHEL_x.x        -                                " \
	    "miraclelinux   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.0-released/x86_64/MIRACLELINUX-[0-9.]*-rtm-minimal-x86_64.iso                         -                                           kickstart_common.cfg                        2021-10-04   20xx-xx-xx   RHEL_x.x        -                                " \
	    "almalinux      https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-[0-9.]*-latest-x86_64-boot.iso                                                  -                                           kickstart_common.cfg                        2022-05-26   20xx-xx-xx   RHEL_9.x        -                                " \
	    "suse           https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-current/iso/openSUSE-Leap-[0-9.]*-NET-x86_64-Media.iso                             -                                           yast_opensuse.xml                           2022-06-08   2023-xx-xx   kernel_5.14.21 -                                 " \
	    "suse           https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                -                                           yast_opensuse.xml                           20xx-xx-xx   20xx-xx-xx   kernel_x.x     -                                 " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                          2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2
#	    "debian         https://cdimage.debian.org/cdimage/bookworm_di_alpha2/amd64/iso-cd/debian-bookworm-DI-alpha2-amd64-netinst.iso                               -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing        Debian_12.xx(bookworm)            " \
#	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/35/Server/x86_64/iso/Fedora-Server-netinst-x86_64-35-1.2.iso                    -                                           kickstart_common.cfg                        2021-11-02   2022-12-13   kernel_5.14    -                                 " \
#	    "suse           https://download.opensuse.org/distribution/openSUSE-current/iso/openSUSE-Leap-[0-9.]*-NET-x86_64-Current.iso                                 -                                           yast_opensuse.xml                           2022-06-08   2023-xx-xx   kernel_5.14.21 -                                 " \
#	    "suse           https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso                                                      -                                           yast_opensuse.xml                           20xx-xx-xx   20xx-xx-xx   kernel_x.x     -                                 " \

	readonly ARRAY_NAME_DVD=(                                                                                                                                                                                                                                                                                                             \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldoldstable/amd64/iso-dvd/debian-[0-9.]*-amd64-DVD-1.iso                                  -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-[0-9.]*-amd64-DVD-1.iso                                     -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-[0-9.]*-amd64-DVD-1.iso                                              -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso                                                -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         http://cdimage.ubuntu.com/releases/bionic/release/ubuntu-[0-9.]*-server-amd64.iso                                                            -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9.]*-live-server-amd64.iso                                                                       -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2020-04-23   2030-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9.]*-live-server-amd64.iso                                                                       -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	    "ubuntu         https://releases.ubuntu.com/kinetic/ubuntu-[0-9.]*-live-server-amd64.iso                                                                     -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
	    "ubuntu         https://releases.ubuntu.com/lunar/ubuntu-[0-9.]*-beta-live-server-amd64.iso                                                                  -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	    "centos         https://ftp.iij.ad.jp/pub/linux/centos/8-stream/isos/x86_64/CentOS-Stream-8-x86_64-latest-dvd1.iso                                           -                                           kickstart_common.cfg                        2019-xx-xx   2024-05-31   RHEL_8.x        -                                " \
	    "centos         https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso                              -                                           kickstart_common.cfg                        2021-xx-xx   20xx-xx-xx   RHEL_9.x        -                                " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/36/Server/x86_64/iso/Fedora-Server-dvd-x86_64-36-1.5.iso                        -                                           kickstart_common.cfg                        2022-05-10   2023-05-16   kernel_5.17     -                                " \
	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-dvd-x86_64-37-1.7.iso                        -                                           kickstart_common.cfg                        2022-11-15   2023-11-14   kernel_6.0      -                                " \
	    "rocky          https://download.rockylinux.org/pub/rocky/8/isos/x86_64/Rocky-[0-9.]*-x86_64-dvd1.iso                                                        -                                           kickstart_common.cfg                        2022-11-14   20xx-xx-xx   RHEL_8.x        -                                " \
	    "rocky          https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-[0-9.]*-x86_64-dvd.iso                                                         -                                           kickstart_common.cfg                        2022-07-14   20xx-xx-xx   RHEL_9.x       -                                 " \
	    "miraclelinux   https://repo.dist.miraclelinux.net/miraclelinux/isos/8.6-released/x86_64/MIRACLELINUX-[0-9.]*-rtm-x86_64.iso                                 -                                           kickstart_common.cfg                        2021-10-04   20xx-xx-xx   RHEL_x.x        -                                " \
	    "miraclelinux   https://repo.dist.miraclelinux.net/miraclelinux/isos/9.0-released/x86_64/MIRACLELINUX-[0-9.]*-rtm-x86_64.iso                                 -                                           kickstart_common.cfg                        2021-10-04   20xx-xx-xx   RHEL_x.x        -                                " \
	    "almalinux      https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-[0-9.]*-latest-x86_64-dvd.iso                                                   -                                           kickstart_common.cfg                        2022-05-26   20xx-xx-xx   RHEL_9.x        -                                " \
	    "suse           https://ftp.riken.jp/Linux/opensuse/distribution/openSUSE-current/iso/openSUSE-Leap-[0-9.]*-DVD-x86_64-Media.iso                             -                                           yast_opensuse.xml                           2022-06-08   2023-xx-xx   kernel_5.14.21  -                                " \
	    "suse           https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                -                                           yast_opensuse.xml                           2021-xx-xx   20xx-xx-xx   kernel_x.x      -                                " \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                       -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                          -                                           preseed_debian.cfg                          2019-07-06   2024-06-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                                   -                                           preseed_debian.cfg                          2021-08-14   2026-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                     -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         https://releases.ubuntu.com/bionic/ubuntu-[0-9.]*-desktop-amd64.iso                                                                          -                                           preseed_ubuntu.cfg                          2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9.]*-desktop-amd64.iso                                                                           -                                           preseed_ubuntu.cfg                          2020-04-23   2030-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9.]*-desktop-amd64.iso                                                                           -                                           preseed_ubuntu.cfg                          2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	    "ubuntu         https://releases.ubuntu.com/kinetic/ubuntu-[0-9.]*-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
	    "ubuntu         https://releases.ubuntu.com/lunar/ubuntu-[0-9.]*-beta-desktop-amd64.iso                                                                      -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	    "ubuntu         http://cdimage.ubuntu.com/ubuntu-server/daily-live/current/lunar-live-server-amd64.iso                                                       -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	    "ubuntu         http://cdimage.ubuntu.com/ubuntu/daily-live/current/lunar-desktop-amd64.iso                                                                  -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	    "ubuntu         http://cdimage.ubuntu.com/daily-legacy/current/lunar-desktop-legacy-amd64.iso                                                                -                                           preseed_ubuntu.cfg                          2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                          2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-cinnamon.iso                                 -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-gnome.iso                                    -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-kde.iso                                      -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxqt.iso                                     -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-mate.iso                                     -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-standard.iso                                 -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-xfce.iso                                     -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
#	    "debian         https://cdimage.debian.org/cdimage/bookworm_di_alpha2/amd64/iso-dvd/debian-bookworm-DI-alpha2-amd64-DVD-1.iso                                -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing        Debian_12.xx(bookworm)            " \
#	    "fedora         https://download.fedoraproject.org/pub/fedora/linux/releases/35/Server/x86_64/iso/Fedora-Server-dvd-x86_64-35-1.2.iso                        -                                           kickstart_common.cfg                        2021-11-02   2022-12-13   kernel_5.14     -                                " \
#	    "ubuntu         https://releases.ubuntu.com/bionic/ubuntu-[0-9.]*-live-server-amd64.iso                                                                      -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2018-04-26   2028-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
#	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9.]*-live-server-amd64.iso                                                                      -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
#	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9.]*-desktop-amd64.iso                                                                          -                                           preseed_ubuntu.cfg                          2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-canary/current/kinetic-desktop-canary-amd64.iso                                                              -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/current/kinetic-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/current/lunar-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/current/lunar-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/pending/lunar-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "ubuntu         http://cdimage.ubuntu.com/ubuntu-server/daily-live/current/lunar-live-server-amd64.iso                                                       -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "ubuntu         http://cdimage.ubuntu.com/ubuntu/daily-live/current/lunar-desktop-amd64.iso                                                                  -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "suse           https://download.opensuse.org/distribution/openSUSE-current/iso/openSUSE-Leap-[0-9.]*-DVD-x86_64-Current.iso                                 -                                           yast_opensuse.xml                           2022-06-08   2023-xx-xx   kernel_5.14.21  -                                " \
#	    "suse           https://download.opensuse.org/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso                                                      -                                           yast_opensuse.xml                           2021-xx-xx   20xx-xx-xx   kernel_x.x      -                                " \

	readonly ARRAY_NAME_LIVE=(                                                                                                                                                                                                                                                                                                            \
	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                          -                                           preseed_debian.cfg                          2019-07-06   2024-xx-xx   oldstable       Debian_10.xx(buster)             " \
	    "debian         http://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                                   -                                           preseed_debian.cfg                          2021-08-14   20xx-xx-xx   stable          Debian_11.xx(bullseye)           " \
	    "debian         http://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso                                     -                                           preseed_debian.cfg                          20xx-xx-xx   20xx-xx-xx   testing         Debian_12.xx(bookworm)           " \
	    "ubuntu         https://releases.ubuntu.com/bionic/ubuntu-[0-9.]*-desktop-amd64.iso                                                                          -                                           preseed_ubuntu.cfg                          2018-04-26   2023-04-26   Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS  " \
	    "ubuntu         https://releases.ubuntu.com/focal/ubuntu-[0-9.]*-desktop-amd64.iso                                                                           -                                           preseed_ubuntu.cfg                          2020-04-23   2025-04-23   Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS    " \
	    "ubuntu         https://releases.ubuntu.com/jammy/ubuntu-[0-9.]*-desktop-amd64.iso                                                                           -                                           preseed_ubuntu.cfg                          2022-04-21   2032-04-21   Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS" \
	    "ubuntu         https://releases.ubuntu.com/kinetic/ubuntu-[0-9.]*-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
	    "ubuntu         http://cdimage.ubuntu.com/daily-legacy/current/lunar-desktop-legacy-amd64.iso                                                                -                                           preseed_ubuntu.cfg                          2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
	)   # 0:区分        1:ダウンロード先URL                                                                                                                          2:別名                                      3:定義ファイル                              4:リリース日 5:サポ終了日 6:備考          7:備考2
#	    "debian         http://cdimage.debian.org/cdimage/archive/latest-oldoldstable-live/amd64/iso-hybrid/debian-live-[0-9.]*-amd64-lxde.iso                       -                                           preseed_debian.cfg                          2017-06-17   2022-06-30   oldoldstable    Debian__9.xx(stretch)            " \
#	    "ubuntu         https://releases.ubuntu.com/impish/ubuntu-[0-9.]*-desktop-amd64.iso                                                                          -                                           preseed_ubuntu.cfg                          2021-10-24   2022-07-14   Impish_Indri    Ubuntu_21.10(Impish_Indri)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-canary/current/kinetic-desktop-canary-amd64.iso                                                              -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/current/kinetic-desktop-amd64.iso                                                                       -                                           preseed_ubuntu.cfg                          2022-10-20   2023-07-xx   Kinetic_Kudu    Ubuntu_22.10(Kinetic_Kudu)       " \
#	    "ubuntu         http://cdimage.ubuntu.com/daily-live/current/lunar-desktop-amd64.iso                                                                         -                                           preseed_ubuntu.cfg,nocloud-ubuntu-user-data 2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \
#	    "ubuntu         http://cdimage.ubuntu.com/ubuntu/daily-live/current/lunar-desktop-amd64.iso                                                                  -                                           preseed_ubuntu.cfg                          2023-04-20   2024-01-20   Lunar_Lobster   Ubuntu_23.04(Lunar_Lobster)      " \

	case "${WORK_DIRS}" in
		"dist_remaster_mini" )	ARRAY_NAME=("${ARRAY_NAME_MINI[@]}");;
		"dist_remaster_net"  )	ARRAY_NAME=("${ARRAY_NAME_NET[@]}");;
		"dist_remaster_dvd"  )	ARRAY_NAME=("${ARRAY_NAME_DVD[@]}");;
		"live-custom"        )	ARRAY_NAME=("${ARRAY_NAME_LIVE[@]}");;
		*                    )	;;
	esac
# -----------------------------------------------------------------------------
	readonly TXT_RESET="\033[m"			# 全属性解除
	readonly TXT_ULINE="\033[4m"		# 下線設定
	readonly TXT_ULINERST="\033[24m"	# 下線解除
	readonly TXT_REV="\033[7m"			# 反転設定
	readonly TXT_REVRST="\033[27m"		# 反転解除
	readonly TXT_BLACK="\033[30m"		# 文字黒色
	readonly TXT_RED="\033[31m"			#  〃 赤色
	readonly TXT_GREEN="\033[32m"		#  〃 緑色
	readonly TXT_YELLOW="\033[33m"		#  〃 黄色
	readonly TXT_BLUE="\033[34m"		#  〃 青色
	readonly TXT_MAGENTA="\033[35m"		#  〃 紫色
	readonly TXT_CYAN="\033[36m"		#  〃 水色
	readonly TXT_WHITE="\033[37m"		#  〃 白色
	readonly TXT_BBLACK="\033[40m"		# 背景黒色
	readonly TXT_BRED="\033[41m"		#  〃 赤色
	readonly TXT_BGREEN="\033[42m"		#  〃 緑色
	readonly TXT_BYELLOW="\033[43m"		#  〃 黄色
	readonly TXT_BBLUE="\033[44m"		#  〃 青色
	readonly TXT_BMAGENTA="\033[45m"	#  〃 紫色
	readonly TXT_BCYAN="\033[46m"		#  〃 水色
	readonly TXT_BWHITE="\033[47m"		#  〃 白色
# -----------------------------------------------------------------------------
funcHelp () {
	cat <<- _EOT_
		使用法: sudo $0 [OPTION]... [NUMBER]...
		  [OPTION]
		    -h, --help      このヘルプ
		    -i, --init      初期設定
		    -l, --log       ログ出力（メディア作成時）
		    -d, --debug     デバッグモード（未実装）
		    -s, --skip      サブシェル処理スキップ
		    -a, --all       全登録リスト処理
		  [NUMBER]
		    処理する登録リスト番号
		    ブレース展開可（重複チェック未実装）
_EOT_
}
# -----------------------------------------------------------------------------
funcOption () {
	local RET_CD
	local SCRIPT_NAME
	local PARAM
	local TARGET
	local FLG_LINK

	PARAM=$(getopt -n $0 -o hildas -l help,init,log,debug,all,skip -- "$@")
	eval set -- "$PARAM"

	while [ -n "${1:-}" ]
	do
		case $1 in
			-h | --help )
				funcHelp
				exit 0
				;;
			-i | --init )
				SCRIPT_NAME=`basename $0`
				FLG_LINK=0
				for TARGET in "dist_remaster_mini" "dist_remaster_net" "dist_remaster_dvd" "live-custom"
				do
					if [ ! -f "./${TARGET}.sh" ] && [ ! -L "./${TARGET}.sh" ]; then
						ln -s "./${SCRIPT_NAME}" "./${TARGET}.sh"
						FLG_LINK=1
					fi
				done
				if [ ${FLG_LINK} -ne 0 ]; then
					echo "シンボリックリンクを作成しました。"
				fi
				exit 0
				;;
			-l | --log )
				shift
				FLG_LOGOUT=1
				;;
			-d | --debug )
				shift
				FLG_DEBUG=1
				;;
			-a | --all )
				shift
				INP_INDX="{1..${#ARRAY_NAME[@]}}"
				;;
			-s | --skip )
				shift
				FLG_SKIP=1
				;;
			-- )
				shift
				if [ -z "${INP_INDX}" ]; then
					set +e
					printf "%d" $@ > /dev/null 2>&1
					RET_CD=$?
					set -e
					if [ ${RET_CD} -eq 0 ]; then
						INP_INDX=$@
					fi
				fi
				;;
			* )
				shift
				;;
		esac
	done
}
# -----------------------------------------------------------------------------
fncMenu () {
	local OLD_IFS
	local RET_CD											# 戻り値退避用
	local ARRY_NAME=()										# 配列展開
	local CODE_NAME=()										# 配列宣言
	local DIR_NAME											# ディレクトリ名
	local FIL_INFO=()										# ファイル情報
	local WEB_INFO=()										# WEB情報
#	local FIL_NAME											# ファイル名
	local FIL_DATE											# ファイル日付
	local DVD_INFO											# DVD情報
	local DVD_SIZE											# DVDサイズ
	local DVD_DATE											# DVD日付
	local WEB_STAT
	local WEB_SIZE
	local WEB_LAST
	local WEB_DATE
	local TXT_COLOR
	local DST_FILE
	local DST_DATE
	local DSP_INDX=(`eval echo "${INP_INDX}"`)
	local DSP_WORK=()
	# -------------------------------------------------------------------------
	# <表示色>
	#  赤色：通信エラー（リンク先消失等）
	#  白色：作成ファイル最新（ダウンロード不要）
	#  緑色：作成ファイル無し（ファイル作成対象）
	#  黄色：作成ファイル在り（ファイル作成対象）
	#  水色：原本ファイル無し（ファイル作成対象）
	#  反転：原本ダウンロード（ファイル作成対象）
	# -------------------------------------------------------------------------
	fncPrint "# $(fncString $((${COL_SIZE}-5)) '-') #"
	fncPrint "#ID：Version$(fncString $((${COL_SIZE}-55)) ' ')：リリース日：サポ終了日：備考           #"
	for ((I=1; I<=${#ARRAY_NAME[@]}; I++))
	do
		if [ "${INP_INDX}" != "" ]; then
			if [ ${#DSP_INDX[@]} -le 0 ]; then
				continue
			elif [ "${DSP_INDX[0]}" != "$I" ]; then
				continue
			else
				DSP_WORK=("${DSP_INDX[@]}")
				unset DSP_WORK[0]
				DSP_INDX=("${DSP_WORK[@]}")
			fi
		fi
		TXT_COLOR=""
		ARRY_NAME=(${ARRAY_NAME[$I-1]})
		CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
		CODE_NAME[1]=`basename ${ARRY_NAME[1]} | sed -e 's/.iso//ig'`	# DVDファイル名
		CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
		CODE_NAME[3]=${ARRY_NAME[3]}									# 定義ファイル
		CODE_NAME[4]=${ARRY_NAME[4]}									# リリース日
		CODE_NAME[5]=${ARRY_NAME[5]}									# サポ終了日
		CODE_NAME[6]=${ARRY_NAME[6]}									# 備考
		CODE_NAME[7]=${ARRY_NAME[7]}									# 備考2
		DIR_NAME=`dirname ${CODE_NAME[2]}`
		# ---------------------------------------------------------------------
		OLD_IFS=${IFS}
		IFS=
		set +e
		WEB_INFO=($(curl -L -R -S -s -f --connect-timeout 3 --retry 3 "${DIR_NAME}" 2> /dev/null))
		RET_CD=$?
		set -e
		IFS=${OLD_IFS}
		if [ ${RET_CD} -eq 18 -o ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then	# WEB情報取得失敗
			TXT_COLOR=${TXT_RED}
		else												# WEB取得取得成功
			FIL_INFO=($(echo "${WEB_INFO[@]}" | LANG=C sed -n "s/^.*<a href=.*> *\(${CODE_NAME[1]}\.iso\) *<\/a.*> *\([0-9a-zA-Z]*-[0-9a-zA-Z]*-[0-9a-zA-Z]*\) *\([0-9]*:[0-9]*\).*$/\1 \2 \3/p"))
			if [ "${FIL_INFO[1]:+UNSET}" = "" ]; then
				TXT_COLOR=${TXT_RED}
			else
				if [ "${FIL_INFO[2]:+UNSET}" = "" ]; then
					FIL_INFO[2]="00:00"
				fi
				FIL_DATE=`TZ=UTC date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y%m%d%H%M%S"`
				CODE_NAME[1]=`echo "${FIL_INFO[0]}" | sed -e 's/.iso//ig'`	# dvd/net
				CODE_NAME[2]=`echo "${DIR_NAME}/${FIL_INFO[0]}"`
				CODE_NAME[4]=`TZ=UTC date -d "${FIL_INFO[1]} ${FIL_INFO[2]}" "+%Y-%m-%d"`
			fi
		fi
		if [ "${CODE_NAME[1]}" = "mini" ]; then
			CODE_NAME[1]="mini-${ARRY_NAME[6]}-${ARC_TYPE}"	# mini.iso
		fi
		# ---------------------------------------------------------------------
		if [ "${ARRY_NAME[2]}" != "-" ]; then				# DVDファイル別名
			CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`
		fi
		# ---------------------------------------------------------------------
		if [ -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
			CODE_NAME[4]=`TZ=UTC ls -lL --time-style="+%Y-%m-%d JST" "${WORK_DIRS}/${CODE_NAME[1]}.iso" | awk '{print $6;}'`
		fi
		# ---------------------------------------------------------------------
		if [ "${TXT_COLOR}" != "${TXT_RED}" ]; then
			if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
				TXT_COLOR=${TXT_CYAN}
				TXT_COLOR+=${TXT_REV}
			else
				DST_FILE="`find "${WORK_DIRS}" -type f -regextype posix-basic -regex "${WORK_DIRS}/${CODE_NAME[1]}-*\(custom\)*-\(autoyast\|kickstart\|nocloud\|preseed\)\.iso" -print`"
				if [ "${DST_FILE}" = "" ]; then
					DST_DATE=""
					TXT_COLOR=${TXT_GREEN}
				else
					DST_DATE=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${DST_FILE}" | awk '{print $6;}'`
				fi
				# -------------------------------------------------------------
				DVD_DATE=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${WORK_DIRS}/${CODE_NAME[1]}.iso" | awk '{print $6;}'`
				if [ -n "${DST_DATE}" ] && [ ${DVD_DATE} -gt ${DST_DATE} ]; then
					TXT_COLOR=${TXT_YELLOW}
				fi
				if [ ${FIL_DATE} -ne ${DVD_DATE} ]; then
					set +e
					curl -L -R -S -s -f --connect-timeout 3 --retry 3 -I --dump-header "${WORK_DIRS}/header.txt" "${CODE_NAME[2]}" > /dev/null
					RET_CD=$?
					set -e
					# -------------------------------------------------------------
					if [ ${RET_CD} -eq 18 -o ${RET_CD} -eq 22 -o ${RET_CD} -eq 28  ]; then
						TXT_COLOR=${TXT_RED}
					else
						DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "${WORK_DIRS}/${CODE_NAME[1]}.iso"`
						DVD_SIZE=`echo "${DVD_INFO}" | awk '{print $5;}'`
						DVD_DATE=`echo "${DVD_INFO}" | awk '{print $6;}'`
						WEB_STAT=`cat ${WORK_DIRS}/header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
						WEB_SIZE=`cat ${WORK_DIRS}/header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
						WEB_LAST=`cat ${WORK_DIRS}/header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
						WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
						if [ ${WEB_STAT:--1} -eq 200 ] && [ "${WEB_SIZE}" -ne "${DVD_SIZE}" -o "${WEB_DATE}" -gt "${DVD_DATE}" ]; then
							if [ -n "${DST_DATE}" ] && [ ${WEB_DATE} -gt ${DST_DATE} ]; then
								TXT_COLOR=${TXT_YELLOW}
							fi
							TXT_COLOR+=${TXT_REV}
							CODE_NAME[4]=`echo "${WEB_DATE:0:4}-${WEB_DATE:4:2}-${WEB_DATE:6:2}"`
						fi
						if [ -f "${WORK_DIRS}/header.txt" ]; then
							rm -f "${WORK_DIRS}/header.txt"
						fi
					fi
				fi
			fi
		fi
		if [ ! -f "${WORK_DIRS}/${CODE_NAME[1]}.iso" ]; then
			TXT_COLOR+=${TXT_REV}
		fi
		# ---------------------------------------------------------------------
		ARRAY_NAME[$I-1]=`printf "%s %s %s %s %s %s %s %s" ${CODE_NAME[0]} ${CODE_NAME[2]} ${CODE_NAME[1]}.iso ${CODE_NAME[3]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]} ${CODE_NAME[7]}`
		# ---------------------------------------------------------------------
		printf "#${TXT_COLOR}%2d：%-"$((${COL_SIZE}-48))"."$((${COL_SIZE}-48))"s：%-10.10s：%-10.10s：%-15.15s${TXT_RESET}#\n" ${I} ${CODE_NAME[1]} ${CODE_NAME[4]} ${CODE_NAME[5]} ${CODE_NAME[6]}
	done
	fncPrint "# $(fncString $((${COL_SIZE}-5)) '-') #"
	if [ ${#INP_INDX} -le 0 ]; then							# 引数無しで入力スキップ
		echo "ID番号+Enterを入力して下さい。"
		read INP_INDX
		case "${INP_INDX,,}" in
			"a" | "all" )
				INP_INDX="{1..${#ARRAY_NAME[@]}}"
				;;
			* )
				;;
		esac
	fi
}
# -----------------------------------------------------------------------------
fncIsInt () {
	set +e
	expr ${1:-""} + 1 > /dev/null 2>&1
	if [ $? -ge 2 ]; then echo 1; else echo 0; fi
	set -e
}
# -----------------------------------------------------------------------------
fncString () {
	local OLD_IFS=${IFS}
	IFS=$'\n'
	if [ "$2" = " " ]; then
		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
	else
		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
	fi
	IFS=${OLD_IFS}
}
# -----------------------------------------------------------------------------
fncPrint () {
	local RET_STR=""
	local MAX_COLS=$((COL_SIZE-1))
	local OLD_IFS=${IFS}
	IFS=$'\n'
	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	if [ $? -ne 0 ]; then
		MAX_COLS=$((COL_SIZE-2))
		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	fi
	echo "${RET_STR}"
	IFS=${OLD_IFS}
}
# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=`echo ${INP_ADDR} | awk -F '.' '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
	done
	echo "${OUT_ARRY[@]}"
}
# -----------------------------------------------------------------------------
fncCreate_late_command () {
	fncPrint "    create_late_command"
	local DIR_PRESEED="$1"
	local OLD_IFS
	local INS_STR
	local DIR_CDROM
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > ${DIR_PRESEED}/sub_late_command.sh
		#!/bin/bash
		
		# --- Initialization ----------------------------------------------------------
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# Ends with status other than 0
		 	set -u								# End with undefined variable reference
		
		 	trap 'exit 1' 1 2 3 15
		
		# --- IPv4 netmask conversion -------------------------------------------------
		fncIPv4GetNetmask () {
		 	local INP_ADDR="$@"
		 	local DEC_ADDR
		
		 	DEC_ADDR=$((0xFFFFFFFF ^ ((2 ** (32-$((${INP_ADDR}))))-1)))
		 	printf '%d.%d.%d.%d' \
		 	    $((${DEC_ADDR} >> 24)) \
		 	    $(((${DEC_ADDR} >> 16) & 0xFF)) \
		 	    $(((${DEC_ADDR} >> 8) & 0xFF)) \
		 	    $((${DEC_ADDR} & 0xFF))
		}
		
		# --- Get network interface information ---------------------------------------
		 	NIC_INF4="`sed -n '/^iface.*static$/,/^iface/ s/^[ \t]*//gp' /etc/network/interfaces`"
		 	NIC_NAME="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"iface\" {print $2;}'`"
		 	NIC_IPV4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"address\" {print $2;}'`"
		 	NIC_BIT4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"address\" {print $3;}'`"
		 	NIC_GATE="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"gateway\" {print $2;}'`"
		 	NIC_DNS4="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"dns-nameservers\" {print $2;}'`"
		 	NIC_WGRP="`echo "${NIC_INF4[@]}" | awk -F '[ \t/]' '$1==\"dns-search\" {print $2;}'`"
		 	NIC_MASK="`fncIPv4GetNetmask "${NIC_BIT4}"`"
		 	NIC_MADR="`LANG=C ip address show dev "${NIC_NAME}" | sed -n '/link\/ether/ s/^[ \t]*//gp' | awk '{gsub(":","",$2); print $2;}'`"
		 	CON_NAME="ethernet_${NIC_MADR}_cable"
		#	NIC_DNS4="`LANG=C ip -4 rule show dev "${NIC_NAME}" default | awk '{print $3;}'`"
		#	NIC_INF6="`LANG=C ip -6 address show dev "${NIC_NAME}" | sed -n '/scope global/p'`"
		#	NIC_IPV6="`echo "${NIC_INF6[@]}" | sed -n '/scope global/p' | sed -n 's/^[ \t]*//gp' | awk -F '[ /]' '{print $2;}'`"
		#	NIC_BIT6="`echo "${NIC_INF6[@]}" | sed -n '/scope global/p' | sed -n 's/^[ \t]*//gp' | awk -F '[ /]' '{print $3;}'`"
		#	NIC_DNS6="`LANG=C ip -6 rule show dev "${NIC_NAME}" default | awk '{print $3;}'`"
		
		# --- Set up IPv4/IPv6 --------------------------------------------------------
		 	if [ -d /etc/connman ]; then
		 		mkdir -p /var/lib/connman/${CON_NAME}
		 		cat <<- _EOT_ | sed 's/^ *//g' > /var/lib/connman/settings
		 			[global]
		 			OfflineMode=false
		 			
		 			[Wired]
		 			Enable=true
		 			Tethering=false
		_EOT_
		 		cat <<- _EOT_ | sed 's/^ *//g' > /var/lib/connman/${CON_NAME}/settings
		 			[${CON_NAME}]
		 			Name=Wired
		 			AutoConnect=true
		 			Modified=
		 			IPv6.method=auto
		 			IPv6.privacy=preferred
		 			IPv6.DHCP.DUID=
		 			IPv4.method=manual
		 			IPv4.DHCP.LastAddress=
		 			IPv4.netmask_prefixlen=${NIC_BIT4}
		 			IPv4.local_address=${NIC_IPV4}
		 			IPv4.gateway=${NIC_GATE}
		 			Nameservers=${NIC_DNS4};127.0.0.1;::1;
		 			Domains=${NIC_WGRP};
		 			Timeservers=ntp.nict.jp;
		 			mDNS=true
		_EOT_
		 	fi
		 	if [ -d /etc/netplan ]; then
		 		cat <<- _EOT_ > /etc/netplan/99-network-manager-static.yaml
		 			network:
		 			  version: 2
		 			  ethernets:
		 			    ${NIC_NAME}:
		 			      dhcp4: false
		 			      addresses: [ ${NIC_IPV4}/${NIC_BIT4} ]
		 			      gateway4: ${NIC_GATE}
		 			      nameservers:
		 			          search: [ ${NIC_WGRP} ]
		 			          addresses: [ ${NIC_DNS4} ]
		 			      dhcp6: true
		 			      ipv6-privacy: true
		 _EOT_
		 	fi
		
		# --- Termination -------------------------------------------------------------
		 	exit 0
		# --- EOF ---------------------------------------------------------------------
_EOT_SH_
	chmod 544 "${DIR_PRESEED}/sub_late_command.sh"
	OLD_IFS=${IFS}
	case "basename ${DIR_PRESEED}" in
		"." )	DIR_CDROM="";;								# mini.iso
		*   )	DIR_CDROM="/cdrom/preseed";;				# dvd/netinst
	esac
	IFS= INS_STR=$(
		cat <<- _EOT_ | sed ':l; N; s/\n//; b l;'
			      cp -p ${DIR_CDROM}/sub_late_command.sh /target/tmp/; \\\\\\n
			      in-target --pass-stdout /tmp/sub_late_command.sh;
_EOT_
	)
	sed -i "${DIR_PRESEED}/preseed.cfg"                              \
	    -e 's/#[ \t]\(d-i[ \t]*preseed\/late_command string\)/  \1/' \
	    -e "/preseed\/late_command/a \\${INS_STR}"
	IFS=${OLD_IFS}
}
# -----------------------------------------------------------------------------
fncCreate_success_command () {
	fncPrint "    create_success_command"
	local DIR_PRESEED="$1"
	local OLD_IFS
	local INS_STR
	cat <<- '_EOT_SH_' | sed 's/^ *//g' > ${DIR_PRESEED}/sub_success_command.sh
		#!/bin/bash
		
		# --- Initialization ----------------------------------------------------------
		#	set -n								# Check for syntax errors
		#	set -x								# Show command and argument expansion
		 	set -o ignoreeof					# Do not exit with Ctrl+D
		 	set +m								# Disable job control
		 	set -e								# Ends with status other than 0
		 	set -u								# End with undefined variable reference
		
		 	trap 'exit 1' 1 2 3 15
		
		 	readonly PGM_NAME=`basename $0 | sed -e 's/\..*$//'`
		 	readonly LOG_NAME="/var/log/installer/${PGM_NAME}.log"
		
		# --- IPv4 netmask conversion -------------------------------------------------
		fncIPv4GetNetmask () {
		 	local INP_ADDR="$@"
		 	local DEC_ADDR
		
		 	DEC_ADDR=$((0xFFFFFFFF ^ ((2 ** (32-$((${INP_ADDR}))))-1)))
		 	printf '%d.%d.%d.%d' \
		 	    $((${DEC_ADDR} >> 24)) \
		 	    $(((${DEC_ADDR} >> 16) & 0xFF)) \
		 	    $(((${DEC_ADDR} >> 8) & 0xFF)) \
		 	    $((${DEC_ADDR} & 0xFF))
		}
		
		# --- IPv4 netmask bit conversion ---------------------------------------------
		fncIPv4GetNetmaskBits () {
		 	local INP_ADDR="$@"
		
		 	echo ${INP_ADDR} | \
		 	    awk -F '.' '{
		 	        split($0, octets);
		 	        for (i in octets) {
		 	            mask += 8 - log(2^8 - octets[i])/log(2);
		 	        }
		 	        print mask
		 	    }'
		}
		
		# --- packages ----------------------------------------------------------------
		fncInstallPackages () {
		 	echo "fncInstallPackages" 2>&1 | tee -a /target/${LOG_NAME}
		 	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg  | \
		 	           sed -z 's/\n//g'                                                                 | \
		 	           sed -e 's/.* multiselect *//'                                                      \
		 	               -e 's/[,|\\\\]//g'                                                             \
		 	               -e 's/\t/ /g'                                                                  \
		 	               -e 's/  */ /g'                                                                 \
		 	               -e 's/^ *//'`
		 	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' /cdrom/preseed/preseed.cfg | \
		 	           sed -z 's/\n//g'                                                                 | \
		 	           sed -e 's/.* string *//'                                                           \
		 	               -e 's/[,|\\\\]//g'                                                             \
		 	               -e 's/\t/ /g'                                                                  \
		 	               -e 's/  */ /g'                                                                 \
		 	               -e 's/^ *//'`
		 	# -------------------------------------------------------------------------
		 	sed -i /target/etc/apt/sources.list \
		 	    -e '/cdrom/ s/^ *\(deb\)/# \1/g'
		 	set +e
		 	in-target --pass-stdout bash -c "
		 		apt-get -qq    update               2>&1 | tee -a ${LOG_NAME}
		 		apt-get -qq -y upgrade              2>&1 | tee -a ${LOG_NAME}
		 		apt-get -qq -y dist-upgrade         2>&1 | tee -a ${LOG_NAME}
		 		apt-get -qq -y install ${LIST_PACK} 2>&1 | tee -a ${LOG_NAME}
		 		if [ \"`which tasksel 2> /dev/null`\" != \"\" ]; then
		 			tasksel install ${LIST_TASK}    2>&1 | tee -a ${LOG_NAME}
		 		fi
		 	# -------------------------------------------------------------------------
		#	if [ -f /etc/bind/named.conf.options ]; then
		#		cp -p /etc/bind/named.conf.options /etc/bind/named.conf.options.original
		#		sed -i /etc/bind/named.conf.options            \
		#		    -e 's/\(dnssec-validation\) auto;/\1 no;/'
		#	fi
		 	# -------------------------------------------------------------------------
		#		if [ -f /usr/lib/systemd/system/connman.service ]; then
		#			systemctl disable connman.service 2>&1 | tee -a ${LOG_NAME}
		#			systemctl stop connman.service    2>&1 | tee -a ${LOG_NAME}
		#		fi
		#		if [ -f /usr/lib/systemd/system/NetworkManager.service ]; then
		#			systemctl enable NetworkManager.service  2>&1 | tee -a ${LOG_NAME}
		#			systemctl restart NetworkManager.service 2>&1 | tee -a ${LOG_NAME}
		#		fi
		 	"
		 	set -e
		}
		
		# --- network -----------------------------------------------------------------
		fncSetupNetwork () {
		 	echo "fncSetupNetwork" 2>&1 | tee -a /target/${LOG_NAME}
		 	IPV4_DHCP=`awk 'BEGIN {result="true";}
		 	                !/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {if ($4=="true") result="false";}
		 	                END {print result;}' /cdrom/preseed/preseed.cfg`
		 	if [ "${IPV4_DHCP}" != "true" ]; then
		 		NIC_NAME="ens160"
		 		NIC_IPV4="`awk '!/#/&&/netcfg\/get_ipaddress/    {print $4;}' /cdrom/preseed/preseed.cfg`"
		 		NIC_MASK="`awk '!/#/&&/netcfg\/get_netmask/      {print $4;}' /cdrom/preseed/preseed.cfg`"
		 		NIC_GATE="`awk '!/#/&&/netcfg\/get_gateway/      {print $4;}' /cdrom/preseed/preseed.cfg`"
		 		NIC_DNS4="`awk '!/#/&&/netcfg\/get_nameservers/  {print $4;}' /cdrom/preseed/preseed.cfg`"
		 		NIC_WGRP="`awk '!/#/&&/netcfg\/get_domain/       {print $4;}' /cdrom/preseed/preseed.cfg`"
		 		NIC_BIT4="`fncIPv4GetNetmaskBits "${NIC_MASK}"`"
		 		# --- connman ---------------------------------------------------------
		 		if [ -d /target/etc/connman ]; then
		 			set +e
		 			NIC_MADR="`LANG=C ip address show dev "${NIC_NAME}" 2> /dev/null | sed -n '/link\/ether/ s/^[ \t]*//gp' | awk '{gsub(":","",$2); print $2;}'`"
		 			CON_NAME="ethernet_${NIC_MADR}_cable"
		 			set -e
		 			mkdir -p /target/var/lib/connman/${CON_NAME}
		 			cat <<- _EOT_ | sed 's/^ *//g' > /target/var/lib/connman/settings
		 				[global]
		 				OfflineMode=false
		 				
		 				[Wired]
		 				Enable=true
		 				Tethering=false
		_EOT_
		 			if [ "${CON_NAME}" != ""]; then
		 				cat <<- _EOT_ | sed 's/^ *//g' > /target/var/lib/connman/${CON_NAME}/settings
		 					[${CON_NAME}]
		 					Name=Wired
		 					AutoConnect=true
		 					Modified=
		 					IPv6.method=auto
		 					IPv6.privacy=preferred
		 					IPv6.DHCP.DUID=
		 					IPv4.method=manual
		 					IPv4.DHCP.LastAddress=
		 					IPv4.netmask_prefixlen=${NIC_BIT4}
		 					IPv4.local_address=${NIC_IPV4}
		 					IPv4.gateway=${NIC_GATE}
		 					Nameservers=${NIC_DNS4};127.0.0.1;::1;
		 					Domains=${NIC_WGRP};
		 					Timeservers=ntp.nict.jp;
		 					mDNS=true
		_EOT_
		 			fi
		 		fi
		 		# --- netplan ---------------------------------------------------------
		 		if [ -d /target/etc/netplan ]; then
		 			cat <<- _EOT_ > /target/etc/netplan/99-network-manager-static.yaml
		 				network:
		 				  version: 2
		 				  ethernets:
		 				    ${NIC_NAME}:
		 				      dhcp4: false
		 				      addresses: [ ${NIC_IPV4}/${NIC_BIT4} ]
		 				      gateway4: ${NIC_GATE}
		 				      nameservers:
		 				          search: [ ${NIC_WGRP} ]
		 				          addresses: [ ${NIC_DNS4} ]
		 				      dhcp6: true
		 				      ipv6-privacy: true
		 _EOT_
		 		fi
		 	fi
		}
		
		# --- gdm3 --------------------------------------------------------------------
		fncChange_gdm3_configure () {
		 	echo "fncChange_gdm3_configure" 2>&1 | tee -a /target/${LOG_NAME}
		 	if [ -f /target/etc/gdm3/custom.conf ]; then
		 		sed -i.orig /target/etc/gdm3/custom.conf \
		 		    -e '/WaylandEnable=false/ s/^#//'
		 	fi
		}
		
		# --- Main --------------------------------------------------------------------
		 	fncInstallPackages
		 	fncSetupNetwork
		#	fncChange_gdm3_configure
		
		# --- Termination -------------------------------------------------------------
		 	cp -p /var/log/syslog /target/var/log/installer/syslog.source
		 	exit 0
		# --- EOF ---------------------------------------------------------------------
_EOT_SH_
	chmod 544 "${DIR_PRESEED}/sub_success_command.sh"
	# -------------------------------------------------------------------------
	OLD_IFS=${IFS}
	# -------------------------------------------------------------------------
	IFS= INS_STR=$(
		cat <<- _EOT_ | sed ':l; N; s/\n//; b l;'
			  ubiquity ubiquity/success_command string \\\\\n
			      /cdrom/preseed/sub_success_command.sh;
_EOT_
	)
	sed -i "${DIR_PRESEED}/preseed.cfg"                       \
	    -e "/ubiquity\/success_command/i \\${INS_STR}"        \
	    -e '/^[^#].*preseed\/late_command/,/[^\\]$/ s/^ /#/g'
	# -------------------------------------------------------------------------
	IFS=${OLD_IFS}
}
# -----------------------------------------------------------------------------
fncMake_setup_sh () {
	local HOSTNAME=""
	local WORKGROUP=""

	fncPrint "      make setup.sh"
	# --- copy media -> fsimg -------------------------------------------------
	fncPrint "      copy media -> fsimg"
	if [ -f ./image/live/filesystem.squashfs ]; then
		mount -r -o loop ./image/live/filesystem.squashfs    ./mnt
	elif [ -f ./image/install/filesystem.squashfs ]; then
		mount -r -o loop ./image/install/filesystem.squashfs ./mnt
	elif [ -f ./image/casper/filesystem.squashfs ]; then
		mount -r -o loop ./image/casper/filesystem.squashfs  ./mnt
	elif [ -f ./image/casper/minimal.squashfs ]; then
		mount -r -o loop ./image/casper/minimal.squashfs     ./mnt
	fi
	cp -pr ./mnt/* ./decomp/
	umount ./mnt
	# ---------------------------------------------------------
	if [ -f ./image/live/config.conf.d/0000-user.conf ]; then
		fncPrint "      copy 0000-user.conf"
		if [ ! -d ./decomp/etc/live/config.conf.d/ ]; then
			mkdir -p ./decomp/etc/live/config.conf.d
		fi
#		cp -p ./image/live/config.conf.d/0000-user.conf ./decomp/etc/live/config.conf.d/
		mv ./image/live/config.conf.d/0000-user.conf ./decomp/etc/live/config.conf.d/
		chown root:root ./decomp/etc/live/config.conf.d/0000-user.conf
		chmod +x ./decomp/etc/live/config.conf.d/0000-user.conf
	fi
	# -------------------------------------------------------------------------
	HOSTNAME="`cat ./decomp/etc/hostname`"
	WORKGROUP="`sed -n "s/^[^ \t]*[ \t]${HOSTNAME}\.\([^ \t]*\).*/\1/p" ./decomp/etc/hostname`"
#	HOSTFQDN="cat ./decomp/etc/hosts`"
#	HOSTNAME="${HOSTFQDN%%\.*}"
#	WORKGROUP="${HOSTFQDN#*\.}"
#	if [ "${WORKGROUP}" = "${HOSTNAME}" ]; then
#		WORKGROUP=""
#	fi
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' | \
		sed -e 's/^ //g'                      \
		    -e "s/_HOSTNAME_/${HOSTNAME}/g"   \
		    -e "s/_WORKGROUP_/${WORKGROUP}/g" \
		> ./decomp/setup.sh
		#!/bin/bash
		# =============================================================================
		#	set -n								# 構文エラーのチェック
		#	set -x								# コマンドと引数の展開を表示
		 	set -o ignoreeof					# Ctrl+Dで終了しない
		 	set +m								# ジョブ制御を無効にする
		 	set -e								# ステータス0以外で終了
		 	set -u								# 未定義変数の参照で終了
		 	trap 'exit 1' 1 2 3 15
		# -- initialize ---------------------------------------------------------------
		 	ROW_SIZE=25
		 	COL_SIZE=80
		 	if [ "`which tput 2> /dev/null`" != "" ]; then
		 		ROW_SIZE=`tput lines`
		 		COL_SIZE=`tput cols`
		 	fi
		 	if [ ${COL_SIZE} -lt 80 ]; then
		 		COL_SIZE=80
		 	fi
		 	if [ ${COL_SIZE} -gt 100 ]; then
		 		COL_SIZE=100
		 	fi
		# -- string -------------------------------------------------------------------
		fncString () {
		 	if [ "$2" = " " ]; then
		 		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
		 	else
		 		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
		 	fi
		}
		# -- print --------------------------------------------------------------------
		fncPrint () {
		 	local RET_STR=""
		 	MAX_COLS=$((COL_SIZE-1))
		 	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
		 	if [ $? -ne 0 ]; then
		 		MAX_COLS=$((COL_SIZE-2))
		 		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
		 	fi
		 	echo "${RET_STR}"
		}
		# -- systemctl ----------------------------------------------------------------
		fncSystemctl () {
		 	echo "systemctl $@"
		 	case "$1" in
		 		"disable" | "mask" )
		 			shift
		 			systemctl --quiet --no-reload disable $@ 2> /dev/null
		 			systemctl --quiet --no-reload mask $@ 2> /dev/null
		 			;;
		 		"enable" | "unmask" )
		 			shift
		 			systemctl --quiet --no-reload unmask $@ 2> /dev/null
		 			systemctl --quiet --no-reload enable $@ 2> /dev/null
		 			;;
		 		* )
		 			systemctl --quiet --no-reload $@ 2> /dev/null
		 			;;
		 	esac
		}
		# -- terminate ----------------------------------------------------------------
		fncEnd() {
		 	fncPrint "--- termination $(fncString ${COL_SIZE} '-')"
		 	RET_STS=$1
		 	history -c
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]: ${OS_NAME} ${OS_VERS}"
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	exit ${RET_STS}
		}
		# == main =====================================================================
		 	OS_NAME=`awk -F '=' '$1=="NAME"             {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
		 	OS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
		 	OS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
		 	OS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
		 	OS_DIST=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
		 	if [ "${OS_CODE}" = "" ]; then
		 		OS_CODE=`echo ${OS_VERS} | awk -F ',' '{split($2,array," "); print tolower(array[1]);}'`
		 	fi
		# -----------------------------------------------------------------------------
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]: ${OS_NAME} ${OS_VERS}"
		 	fncPrint "$(fncString ${COL_SIZE} '=')"
		 	fncPrint "--- initialize $(fncString ${COL_SIZE} '-')"
		 	fncPrint "     os name  : ${OS_NAME}"
		 	fncPrint "     version  : ${OS_VERS}"
		 	fncPrint "     hostname : _HOSTNAME_"
		 	fncPrint "     workgroup: _WORKGROUP_"
		 	export PS1="(chroot) "
		#	echo "_HOSTNAME_" > /etc/hostname
		#	hostname -b -F /etc/hostname
		 	if [ -d "/usr/lib/systemd/" ]; then
		 		DIR_SYSD="/usr/lib/systemd/"
		 	elif [ -d "/lib/systemd/" ]; then
		 		DIR_SYSD="/lib/systemd"
		 	else
		 		DIR_SYSD=""
		 	fi
		# -- module update, upgrade, tasksel, install ---------------------------------
		 	fncPrint "--- module update, install, clean $(fncString ${COL_SIZE} '-')"
		 	# -- apt setup ---------------------------------------------------------- #
		 	fncPrint "     update sources.list"
		 	case "`echo ${OS_NAME} | awk '{print tolower($1);}'`" in
		 		"debian" )
		 			APT_HOST="http://deb.debian.org/debian/"
		 			APT_SECU="http://security.debian.org/debian-security"
		 			APT_OPTI=""
		#			cp -p > /etc/apt/sources.list > /etc/apt/sources.list.orig
		 			cat <<- _EOT_ > /etc/apt/sources.list
		 				deb     ${APT_HOST} ${OS_CODE} main non-free contrib
		 				deb-src ${APT_HOST} ${OS_CODE} main non-free contrib
		 				deb     ${APT_SECU} ${OS_CODE}-security main non-free contrib
		 				deb-src ${APT_SECU} ${OS_CODE}-security main non-free contrib
		 				deb     ${APT_HOST} ${OS_CODE}-updates main non-free contrib
		 				deb-src ${APT_HOST} ${OS_CODE}-updates main non-free contrib
		 				deb     ${APT_HOST} ${OS_CODE}-backports main non-free contrib
		 				deb-src ${APT_HOST} ${OS_CODE}-backports main non-free contrib
		_EOT_
		 			if [ ${OS_VRID} -ge 9 ]; then
		 				sed -i /etc/apt/sources.list    \
		 				    -e '/security.debian.org/d'
		 			fi
		 			;;
		 		"ubuntu" )
		 			APT_HOST="http://jp.archive.ubuntu.com/ubuntu/"
		 			APT_SECU="http://security.ubuntu.com/ubuntu"
		 			APT_OPTI="http://archive.canonical.com/ubuntu"
		#			cp -p > /etc/apt/sources.list > /etc/apt/sources.list.orig
		 			cat <<- _EOT_ > /etc/apt/sources.list
		 				deb     ${APT_HOST} ${OS_CODE} main restricted universe multiverse
		 				deb-src ${APT_HOST} ${OS_CODE} main restricted universe multiverse
		 				deb     ${APT_SECU} ${OS_CODE}-security main restricted universe multiverse
		 				deb-src ${APT_SECU} ${OS_CODE}-security main restricted universe multiverse
		 				deb     ${APT_HOST} ${OS_CODE}-updates main restricted universe multiverse
		 				deb-src ${APT_HOST} ${OS_CODE}-updates main restricted universe multiverse
		 				deb     ${APT_HOST} ${OS_CODE}-backports main restricted universe multiverse
		 				deb-src ${APT_HOST} ${OS_CODE}-backports main restricted universe multiverse
		 				#deb     ${APT_OPTI} ${OS_CODE} partner
		 				#deb-src ${APT_OPTI} ${OS_CODE} partner
		_EOT_
		 			;;
		 		* ) ;;
		 	esac
		 	# -------------------------------------------------------------------------
		 	if [ -d /var/lib/apt/lists ]; then
		 		fncPrint "     remove /var/lib/apt/lists"
		 		rm -rf /var/lib/apt/lists
		 	fi
		 	# -------------------------------------------------------------------------
		 	export DEBIAN_FRONTEND=noninteractive
		 	APT_OPTIONS="-o Dpkg::Options::=--force-confdef    \
		 	             -o Dpkg::Options::=--force-confnew    \
		 	             -o Dpkg::Options::=--force-overwrite"
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "     module dpkg --audit / dpkg --configure -a"
		 	dpkg --audit                                                           || fncEnd $?
		 	dpkg --configure -a                                                    || fncEnd $?
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "     module apt-get update"
		 	apt-get update       -qq                                   > /dev/null || fncEnd $?
		 	fncPrint "     module apt-get upgrade"
		 	apt-get upgrade      -qq -y ${APT_OPTIONS}                 > /dev/null || fncEnd $?
		 	fncPrint "     module apt-get dist-upgrade"
		 	apt-get dist-upgrade -qq -y ${APT_OPTIONS}                 > /dev/null || fncEnd $?
		 	fncPrint "     module apt-get install"
		 	apt-get install      -qq -y ${APT_OPTIONS} --auto-remove                \
		 	    __INST_PACK__                                                       \
		 	    open-vm-tools open-vm-tools-desktop                                 \
		 	                                                           > /dev/null || fncEnd $?
		 	if [ "`which tasksel 2> /dev/null`" != "" ]; then
		 		fncPrint "     tasksel"
		 		tasksel install                                                     \
		 		    _LST_TASK_                                                      \
		 		                                                       > /dev/null || fncEnd $?
		 	fi
		 	# ----------------------------------------------------------------------- #
		 	if [ `getconf LONG_BIT` -eq 64 ]; then
		 		fncPrint "     google-chrome install"
		 		APP_CHROME="google-chrome-stable_current_amd64.deb"
		 		URL_CHROME="https://dl.google.com/linux/direct/${APP_CHROME}"
		 		KEY_CHROME="https://dl-ssl.google.com/linux/linux_signing_key.pub"
		 		pushd /tmp/ > /dev/null
		 			if [ "`which curl 2> /dev/null`" != "" ]; then
		 				curl -L -# -O -R -S "${URL_CHROME}" || fncEnd $?
		 			elif [ "`which wget 2> /dev/null`" != "" ]; then
		 				wget -q -N "${URL_CHROME}" || fncEnd $?
		 			fi
		 			apt-get install -qq -y ${APT_OPTIONS} --auto-remove             \
		 			    ./${APP_CHROME}                                             \
		 			                                                   > /dev/null || fncEnd $?
		 		popd > /dev/null
		 	fi
		 	# ----------------------------------------------------------------------- #
		 	fncPrint "     module autoremove, autoclean, clean"
		 	apt-get autoremove   -qq -y                                > /dev/null || fncEnd $?
		 	apt-get autoclean    -qq                                   > /dev/null || fncEnd $?
		 	apt-get clean        -qq                                   > /dev/null || fncEnd $?
		# -- Change system control ----------------------------------------------------
		# 	Set disable to mask because systemd-sysv-generator will recreate the symbolic link.
		 	fncPrint "--- change system control $(fncString ${COL_SIZE} '-')"
		 	fncSystemctl  enable clamav-freshclam
		 	fncSystemctl  enable ssh
		 	if [ "`systemctl is-enabled named 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl enable named
		 	else
		 		fncSystemctl enable bind9
		 	fi
		 	fncSystemctl  enable smbd
		 	fncSystemctl  enable nmbd
		 	fncSystemctl disable isc-dhcp-server
		 	if [ "`systemctl is-enabled isc-dhcp-server6 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable isc-dhcp-server6
		 	fi
		 	if [ "`systemctl is-enabled apache2 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable apache2
		 	fi
		 	fncSystemctl disable minidlna
		 	if [ "`systemctl is-enabled unattended-upgrades 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable unattended-upgrades
		 	fi
		 	if [ "`systemctl is-enabled brltty 2> /dev/null || :`" != "" ]; then
		 		fncSystemctl disable brltty-udev
		 		fncSystemctl disable brltty
		 	fi
		 	case "`sed -n '/^UBUNTU_CODENAME=/ s/.*=\(.*\)/\1/p' /etc/os-release`" in
		 		"focal"   | \
		 		"impish"  | \
		 		"jammy"   | \
		 		"kinetic" | \
		 		"lunar"   )
		 			if [ "`systemctl is-enabled systemd-udev-settle 2> /dev/null || :`" != "" ]; then
		 				fncSystemctl disable systemd-udev-settle
		 			fi
		 			;;
		 		* )
		 			;;
		 	esac
		# -- Change service configure -------------------------------------------------
		#	if [ -f /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service ]; then
		#		fncPrint "--- change cups-browsed configure $(fncString ${COL_SIZE} '-')"
		#		cat <<- _EOT_ > /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service.override
		#			[Service]
		#			TimeoutStopSec=3
		#_EOT_
		#	fi
		# -- Change resolv configure --------------------------------------------------
		 	if [ -d /etc/NetworkManager/ ]; then
		 		fncPrint "--- change NetworkManager configure $(fncString ${COL_SIZE} '-')"
		 		touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
		 		cat <<- _EOT_ > /etc/NetworkManager/conf.d/NetworkManager.conf.override
		 			[main]
		 			dns=default
		 _EOT_
		 		fncPrint "--- change resolv.conf configure $(fncString ${COL_SIZE} '-')"
		 		cat <<- _EOT_ > /etc/systemd/resolved.conf.override
		 			[Resolve]
		 			DNSStubListener=no
		_EOT_
		 		ln -sf /run/systemd/resolve/resolv.conf etc/resolv.conf
		 	fi
		# -- Change avahi-daemon configure --------------------------------------------
		 	if [ -f /etc/nsswitch.conf ]; then
		 		fncPrint "--- change avahi-daemon configure $(fncString ${COL_SIZE} '-')"
		 		OLD_IFS=${IFS}
		 		IFS=$'\n'
		 		INS_ROW=$((`sed -n '/^hosts:/ =' /etc/nsswitch.conf | awk 'NR==1 {print}'`))
		 		INS_TXT=`sed -n '/^hosts:/ s/\(hosts:[ \t]*\).*$/\1mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns mdns/p' /etc/nsswitch.conf`
		 		sed -e '/^hosts:/ s/^/#/' /etc/nsswitch.conf | \
		 		sed -e "${INS_ROW}a ${INS_TXT}"                \
		 		> nsswitch.conf
		 		cat nsswitch.conf > /etc/nsswitch.conf
		 		rm nsswitch.conf
		 		IFS=${OLD_IFS}
		 	fi
		# -- Change localize configure ------------------------------------------------
		 	if [ -f /etc/locale.gen ]; then
		 		fncPrint "--- change localize configure $(fncString ${COL_SIZE} '-')"
		 		sed -i /etc/locale.gen                   \
		 		    -e 's/^[a-zA-Z]/# &/g'               \
		 		    -e 's/# *\(ja_JP.UTF-8 UTF-8\)/\1/g' \
		 		    -e 's/# *\(en_US.UTF-8 UTF-8\)/\1/g'
		 		locale-gen
		 		update-locale LANG="ja_JP.UTF-8" LANGUAGE="ja:en"
		 		localectl set-x11-keymap --no-convert "jp,us" "pc105"
		 	fi
		# -- Change mozc configure ----------------------------------------------------
		 	if [ -f /usr/share/ibus/component/mozc.xml ]; then
		 		fncPrint "--- change mozc configure $(fncString ${COL_SIZE} '-')"
		 		sed -i /usr/share/ibus/component/mozc.xml                                     \
		 		    -e '/<engine>/,/<\/engine>/ s/\(<layout>\)default\(<\/layout>\)/\1jp\2/g'
		 	fi
		# -- Change clamav configure --------------------------------------------------
		 	if [ "`which freshclam 2> /dev/null`" != "" ]; then
		 		fncPrint "     change freshclam.conf"
		 		sed -i /etc/clamav/freshclam.conf     \
		 		    -e 's/^Example/#&/'               \
		 		    -e 's/^CompressLocalDatabase/#&/' \
		 		    -e 's/^SafeBrowsing/#&/'          \
		 		    -e 's/^NotifyClamd/#&/'
		 		fncPrint "     run freshclam"
		 		set +e
		 		freshclam --quiet
		 		set -e
		 	fi
		# -- Change sshd configure ----------------------------------------------------
		 	if [ -d /etc/ssh/ ]; then
		 		fncPrint "--- change sshd configure $(fncString ${COL_SIZE} '-')"
		 		if [ ! -d /etc/ssh/sshd_config.d/ ]; then
		 			cat <<- _EOT_ >> /etc/ssh/sshd_config
		 				
		 				# --- user settings ---
		 				PermitRootLogin no
		 				PubkeyAuthentication yes
		 				PasswordAuthentication yes
		_EOT_
		 			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
		 				cat <<- _EOT_ >> /etc/ssh/sshd_config
		 					PubkeyAcceptedAlgorithms +ssh-rsa
		 					HostkeyAlgorithms +ssh-rsa
		_EOT_
		 			fi
		 		else
		 			cat <<- _EOT_ > /etc/ssh/sshd_config.d/sshd_config.override
		 				PermitRootLogin no
		 				PubkeyAuthentication yes
		 				PasswordAuthentication yes
		_EOT_
		 			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
		 				cat <<- _EOT_ >> /etc/ssh/sshd_config.d/sshd_config.override
		 					PubkeyAcceptedAlgorithms +ssh-rsa
		 					HostkeyAlgorithms +ssh-rsa
		_EOT_
		 			fi
		 		fi
		 	fi
		# -- Change samba configure ---------------------------------------------------
			if [ -f /etc/samba/smb.conf ]; then
		 		fncPrint "--- change samba configure $(fncString ${COL_SIZE} '-')"
		 		SVR_NAME="_HOSTNAME_"						# 本機のホスト名
		 		WGP_NAME="_WORKGROUP_"						# 本機のワークグループ名
		 		CMD_UADD=`which useradd`
		 		CMD_UDEL=`which userdel`
		 		CMD_GADD=`which groupadd`
		 		CMD_GDEL=`which groupdel`
		 		CMD_GPWD=`which gpasswd`
		 		CMD_FALS=`which false`
		 		# ---------------------------------------------------------------------
		 		testparm -s -v |                                                                        \
		 		sed -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
		 		    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
		 		    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
		 		    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
		 		    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
		 		    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
		 		    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
		 		    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
		 		    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
		 		    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
		 		    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
		 		    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
		 		    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
		 		    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
		 		    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
		 		    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
		 		    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
		 		    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
		 		    -e 's/\(min protocol\) =.*$/\1 = NT1/g'                                             \
		 		    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
		 		    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
		 		    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
		 		    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
		 		    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
		 		    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
		 		    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
		 		    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
		 		    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
		 		    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
		 		    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
		 		    -e '/[ \t]*.* = $/d'                                                                \
		 		    -e '/[ \t]*\(client ipc\|client\|server\) min protocol = .*$/d'                     \
		 		    -e '/[ \t]*acl check permissions =.*$/d'                                            \
		 		    -e '/[ \t]*allocation roundup size =.*$/d'                                          \
		 		    -e '/[ \t]*blocking locks =.*$/d'                                                   \
		 		    -e '/[ \t]*client NTLMv2 auth =.*$/d'                                               \
		 		    -e '/[ \t]*client lanman auth =.*$/d'                                               \
		 		    -e '/[ \t]*client plaintext auth =.*$/d'                                            \
		 		    -e '/[ \t]*client schannel =.*$/d'                                                  \
		 		    -e '/[ \t]*client use spnego =.*$/d'                                                \
		 		    -e '/[ \t]*client use spnego principal =.*$/d'                                      \
		 		    -e '/[ \t]*copy =.*$/d'                                                             \
		 		    -e '/[ \t]*dns proxy =.*$/d'                                                        \
		 		    -e '/[ \t]*domain logons =.*$/d'                                                    \
		 		    -e '/[ \t]*domain master =.*$/d'                                                    \
		 		    -e '/[ \t]*enable privileges =.*$/d'                                                \
		 		    -e '/[ \t]*encrypt passwords =.*$/d'                                                \
		 		    -e '/[ \t]*idmap backend =.*$/d'                                                    \
		 		    -e '/[ \t]*idmap gid =.*$/d'                                                        \
		 		    -e '/[ \t]*idmap uid =.*$/d'                                                        \
		 		    -e '/[ \t]*lanman auth =.*$/d'                                                      \
		 		    -e '/[ \t]*logon path =.*$/d'                                                       \
		 		    -e '/[ \t]*logon script =.*$/d'                                                     \
		 		    -e '/[ \t]*lsa over netlogon =.*$/d'                                                \
		 		    -e '/[ \t]*map to guest =.*$/d'                                                     \
		 		    -e '/[ \t]*nbt client socket address =.*$/d'                                        \
		 		    -e '/[ \t]*null passwords =.*$/d'                                                   \
		 		    -e '/[ \t]*obey pam restrictions =.*$/d'                                            \
		 		    -e '/[ \t]*only user =.*$/d'                                                        \
		 		    -e '/[ \t]*pam password change =.*$/d'                                              \
		 		    -e '/[ \t]*paranoid server security =.*$/d'                                         \
		 		    -e '/[ \t]*password level =.*$/d'                                                   \
		 		    -e '/[ \t]*preferred master =.*$/d'                                                 \
		 		    -e '/[ \t]*raw NTLMv2 auth =.*$/d'                                                  \
		 		    -e '/[ \t]*realm =.*$/d'                                                            \
		 		    -e '/[ \t]*security =.*$/d'                                                         \
		 		    -e '/[ \t]*server role =.*$/d'                                                      \
		 		    -e '/[ \t]*server schannel =.*$/d'                                                  \
		 		    -e '/[ \t]*server services =.*$/d'                                                  \
		 		    -e '/[ \t]*server string =.*$/d'                                                    \
		 		    -e '/[ \t]*share modes =.*$/d'                                                      \
		 		    -e '/[ \t]*syslog =.*$/d'                                                           \
		 		    -e '/[ \t]*syslog only =.*$/d'                                                      \
		 		    -e '/[ \t]*time offset =.*$/d'                                                      \
		 		    -e '/[ \t]*unicode =.*$/d'                                                          \
		 		    -e '/[ \t]*unix password sync =.*$/d'                                               \
		 		    -e '/[ \t]*use spnego =.*$/d'                                                       \
		 		    -e '/[ \t]*usershare allow guests =.*$/d'                                           \
		 		    -e '/[ \t]*winbind separator =.*$/d'                                                \
		 		    -e '/[ \t]*wins support =.*$/d'                                                     \
		 		    -e '/[ \t]*netbios name =.*$/d'                                                     \
		 		    -e '/[ \t]*workgroup =.*$/d'                                                        \
		 		> ./smb.conf
		 		# ---------------------------------------------------------------------
		 		testparm -s ./smb.conf > /etc/samba/smb.conf
		 		rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
		fi
		# -- Change open vm tools configure -------------------------------------------
		#	if [ "`dpkg -l open-vm-tools | awk '$1==\"ii\" && $2=\"open-vm-tools\" {print $2;}'`" = "open-vm-tools" ]; then
		#		fncPrint "--- change open vm tools configure $(fncString ${COL_SIZE} '-')"
		#		if [ ! -d /media/hgfs ]; then
		#			mkdir -p /media/hgfs
		#		fi
		#		echo -e '# Added by User\n' \
		#		        '.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,noauto,users,defaults 0 0' \
		#		>> /etc/fstab
		#	fi
		# -- Change gdm3 configure ----------------------------------------------------
		#	if [ -f /etc/gdm3/custom.conf ] && [ ! -f /etc/gdm3/daemon.conf ]; then
		#		fncPrint "--- create gdm3 daemon.conf $(fncString ${COL_SIZE} '-')"
		#		cp -p /etc/gdm3/custom.conf /etc/gdm3/daemon.conf
		#		: > /etc/gdm3/daemon.conf
		#	fi
		# -- Change xdg configure -----------------------------------------------------
		 	if [  -f /etc/xdg/autostart/gnome-initial-setup-first-login.desktop ]; then
		 		fncPrint "--- change xdg configure $(fncString ${COL_SIZE} '-')"
		 		mkdir -p /etc/skel/.config
		 		touch /etc/skel/.config/gnome-initial-setup-done
		 	fi
		# -- Change dconf configure ---------------------------------------------------
		 	if [ "`which dconf 2> /dev/null`" != "" ]; then
		 		fncPrint "--- change dconf configure $(fncString ${COL_SIZE} '-')"
		 		# -- create dconf profile ---------------------------------------------
		 		fncPrint "--- create dconf profile $(fncString ${COL_SIZE} '-')"
		 		if [ ! -d /etc/dconf/db/local.d/ ]; then
		 			mkdir -p /etc/dconf/db/local.d
		 		fi
		 		if [ ! -d /etc/dconf/profile/ ]; then
		 			mkdir -p /etc/dconf/profile
		 		fi
		 		cat <<- _EOT_ > /etc/dconf/profile/user
		 			user-db:user
		 			system-db:local
		_EOT_
		 		# -- dconf org/gnome/desktop/screensaver ------------------------------
		 		fncPrint "     dconf org/gnome/desktop/screensaver"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-screensaver
		 			[org/gnome/desktop/screensaver]
		 			idle-activation-enabled=false
		 			lock-enabled=false
		_EOT_
		 		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		 		fncPrint "     dconf org/gnome/shell/extensions/dash-to-dock"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-dash-to-dock
		 			[org/gnome/shell/extensions/dash-to-dock]
		 			hot-keys=false
		 			hotkeys-overlay=false
		 			hotkeys-show-dock=false
		_EOT_
		 		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		 		fncPrint "     dconf apps/update-manager"
		 		cat <<- _EOT_ > /etc/dconf/db/local.d/01-update-manager
		 			[apps/update-manager]
		 			check-dist-upgrades=false
		 			first-run=false
		_EOT_
		 		# -- dconf update -----------------------------------------------------
		 		fncPrint "     dconf update"
		 		dconf update
		 	fi
		# -- Change release-upgrades configure ----------------------------------------
		#	if [ -f /etc/update-manager/release-upgrades ]; then
		#		fncPrint "--- change release-upgrades configure $(fncString ${COL_SIZE} '-')"
		#		sed -i /etc/update-manager/release-upgrades \
		#		    -e 's/^\(Prompt\)=.*$/\1=never/'
		#	fi
		#	if [ -f /usr/lib/ubuntu-release-upgrader/check-new-release-gtk ]; then
		#	fi
		# -- Copy pulse configure -----------------------------------------------------
		 	if [ -f /usr/share/gdm/default.pa ]; then
		 		fncPrint "--- copy pulse configure $(fncString ${COL_SIZE} '-')"
		 		mkdir -p /etc/skel/.config/pulse
		 		cp -p /usr/share/gdm/default.pa /etc/skel/.config/pulse/
		 	fi
		# -- root and user's setting --------------------------------------------------
		 	fncPrint "--- root and user's setting $(fncString ${COL_SIZE} '-')"
		 	LST_SHELL="`sed -n '/^#/! s~/~\\\\/~gp' /etc/shells |  sed -z 's/\n/|/g' | sed -e 's/|$//'`"
		 	for USER_NAME in "skel" `awk -F ':' '$7~/'"${LST_SHELL}"'/ {print $1;}' /etc/passwd`
		 	do
		 		fncPrint "     ${USER_NAME}'s setting"
		 		if [ "${USER_NAME}" == "skel" ]; then
		 			USER_HOME="/etc/skel"
		 		else
		 			USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		 		fi
		 		if [ "${USER_HOME}" != "" ]; then
		 			pushd ${USER_HOME} > /dev/null
		 				# --- .bashrc -------------------------------------------------
		 				cat <<- _EOT_ >> .bashrc
		 					# --- 日本語文字化け対策 ---
		 					case "\${TERM}" in
		 					    "linux" ) export LANG=C;;
		 					    * )                    ;;
		 					esac
		 					export GTK_IM_MODULE=ibus
		 					export XMODIFIERS=@im=ibus
		 					export QT_IM_MODULE=ibus
		_EOT_
		 				# --- .vimrc --------------------------------------------------
		 				cat <<- _EOT_ > .vimrc
		 					set number              " Print the line number in front of each line.
		 					set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
		 					set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
		 					set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
		 					set nowrap              " This option changes how text is displayed.
		 					set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
		 					set laststatus=2        " The value of this option influences when the last window will have a status line always.
		 					syntax on               " Vim5 and later versions support syntax highlighting.
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .vimrc
		 				fi
		 				# --- .curlrc -------------------------------------------------
		 				cat <<- _EOT_ > .curlrc
		 					location
		 					progress-bar
		 					remote-time
		 					show-error
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .curlrc
		 				fi
		 				# --- xinput.d ------------------------------------------------
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					mkdir .xinput.d
		 					ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
		 					chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
		 				fi
		 				# --- .credentials --------------------------------------------
		 				cat <<- _EOT_ > .credentials
		 					username=value
		 					password=value
		 					domain=value
		_EOT_
		 				if [ "${USER_NAME}" != "skel" ]; then
		 					chown ${USER_NAME}: .credentials
		 					chmod 0600 .credentials
		 				fi
		 				# --- libfm.conf ----------------------------------------------
		 				if [   -f .config/libfm/libfm.conf      ] \
		 				&& [ ! -f .config/libfm/libfm.conf.orig ]; then
		 					sed -i.orig .config/libfm/libfm.conf   \
		 					    -e 's/^\(single_click\)=.*$/\1=0/'
		 				fi
		 			popd > /dev/null
		 		fi
		 	done
		# -----------------------------------------------------------------------------
		 	fncPrint "--- cleaning and exit $(fncString ${COL_SIZE} '-')"
		 	fncEnd 0
		# == EOF ======================================================================
		# *****************************************************************************
		# <memo>
		#   [im-config]
		#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
		# *****************************************************************************
_EOT_SH_
	# -------------------------------------------------------------------------
	chmod +x ./decomp/setup.sh
}
# -----------------------------------------------------------------------------
fncExec_setup_sh () {
	fncPrint "      exec setup.sh"
	# --- packages ------------------------------------------------------------
	OLD_IFS=${IFS}
	IFS=$'\n'
	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg  | \
	           sed -z 's/\n//g'                                                                | \
	           sed -e 's/.* multiselect *//'                                                     \
	               -e 's/[,|\\\\]//g'                                                            \
	               -e 's/\t/ /g'                                                                 \
	               -e 's/  */ /g'                                                                \
	               -e 's/^ *//'`
	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg | \
	           sed -z 's/\n//g'                                                                | \
	           sed -e 's/.* string *//'                                                          \
	               -e 's/[,|\\\\]//g'                                                            \
	               -e 's/\t/ /g'                                                                 \
	               -e 's/  */ /g'                                                                \
	               -e 's/^ *//'`
	INST_TASK=${LIST_TASK}
	INST_PACK=`echo "${LIST_PACK}" | sed -e 's/ *isc-dhcp-server//'`
#	INST_PACK+=" whois"
	sed -i ./decomp/setup.sh               \
	    -e "s/__INST_PACK__/${INST_PACK}/" \
	    -e "s/__INST_TASK__/${INST_TASK}/"
	IFS=${OLD_IFS}
	# --- network -------------------------------------------------------------
	cp -p ./decomp/etc/apt/sources.list      \
	      ./decomp/etc/apt/sources.list.orig
	# --- time zone -----------------------------------------------------------
	rm -f ./decomp/etc/localtime
	ln -s /usr/share/zoneinfo/Asia/Tokyo ./decomp/etc/localtime
	# --- mount ---------------------------------------------------------------
	mount --bind /run     ./decomp/run
	mount --bind /dev     ./decomp/dev
	mount --bind /dev/pts ./decomp/dev/pts
	mount --bind /proc    ./decomp/proc
	mount --bind /sys     ./decomp/sys
	# --- chroot --------------------------------------------------------------
	LANG=C chroot ./decomp /bin/bash /setup.sh
	RET_STS=$?
	# --- unmount -------------------------------------------------------------
	umount ./decomp/sys     || umount -lf ./decomp/sys
	umount ./decomp/proc    || umount -lf ./decomp/proc
	umount ./decomp/dev/pts || umount -lf ./decomp/dev/pts
	umount ./decomp/dev     || umount -lf ./decomp/dev
	umount ./decomp/run     || umount -lf ./decomp/run
	# --- error check ---------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# --- cleaning ------------------------------------------------------------
	if [ -f ./decomp/etc/resolv.conf.orig ]; then
		mv ./decomp/etc/resolv.conf.orig \
		   ./decomp/etc/resolv.conf
	fi
	if [ -f ./decomp/etc/apt/sources..orig ]; then
		mv ./decomp/etc/apt/sources.list.orig \
		   ./decomp/etc/apt/sources.list
	fi
	find   ./decomp/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./decomp/root/.bash_history           \
	       ./decomp/root/.viminfo                \
	       ./decomp/tmp/*                        \
	       ./decomp/var/cache/apt/*.bin          \
	       ./decomp/var/cache/apt/archives/*.deb \
	       ./decomp/setup.sh
	# --- filesystem manifest -------------------------------------------------
	case "${CODE_NAME[0]}" in
		"debian" )	# ･････････････････････････････････････････････････････････
			;;
		"ubuntu" )	# ･････････････････････････････････････････････････････････
			rm -f ./image/casper/filesystem.size                    \
			      ./image/casper/filesystem.manifest                \
			      ./image/casper/filesystem.manifest-remove         
#			      ./image/casper/filesystem.manifest-minimal-remove 
			# -----------------------------------------------------------------
			touch ./image/casper/filesystem.size
			touch ./image/casper/filesystem.manifest
			touch ./image/casper/filesystem.manifest-remove
#			touch ./image/casper/filesystem.manifest-minimal-remove
			# -----------------------------------------------------------------
			printf $(LANG=C chroot ./decomp du -sx --block-size=1 | cut -f1) > ./image/casper/filesystem.size
			LANG=C chroot ./decomp dpkg-query -W --showformat='${Package} ${Version}\n' > ./image/casper/filesystem.manifest
			cp -p ./image/casper/filesystem.manifest ./image/casper/filesystem.manifest-desktop
			sed -i ./image/casper/filesystem.manifest-desktop \
			    -e '/^casper.*$/d'                            \
			    -e '/^lupin-casper.*$/d'                      \
			    -e '/^ubiquity.*$/d'                          \
			    -e '/^ubiquity-casper.*$/d'                   \
			    -e '/^ubiquity-frontend-gtk.*$/d'             \
			    -e '/^ubiquity-slideshow-ubuntu.*$/d'         \
			    -e '/^ubiquity-ubuntu-artwork.*$/d'
			;;
		* )	;;
	esac
	# --- copy fsimg -> media -------------------------------------------------
	fncPrint "    copy fsimg -> media"
	case "${CODE_NAME[0]}" in
		"debian" )			# ･････････････････････････････････････････････････
			rm -f ./image/live/filesystem.squashfs
			mksquashfs ./decomp ./image/live/filesystem.squashfs -noappend -quiet
			ls -lht ./image/live/filesystem.squashfs
			FSIMG_SIZE=`LANG=C ls -lh ./image/live/filesystem.squashfs | awk '{print $5;}'`
			;;
		"ubuntu" )			# ･････････････････････････････････････････････････
			rm -f ./image/casper/filesystem.squashfs.gpg
			rm -f ./image/casper/filesystem.squashfs
			mksquashfs ./decomp ./image/casper/filesystem.squashfs -noappend -quiet
			ls -lht ./image/casper/filesystem.squashfs
			FSIMG_SIZE=`LANG=C ls -lh ./image/casper/filesystem.squashfs | awk '{print $5;}'`
			;;
		* )	;;
	esac
}
# -----------------------------------------------------------------------------
fncLive_custom () {
	local HOSTNAME="$1"

	if [ ! -d ./image/live/ ]; then
		return
	fi
	mkdir -p ./image/live/config.conf.d
	# ---------------------------------------------------------
	fncPrint "      make 0000-user.conf"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > ./image/live/config.conf.d/0000-user.conf
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		
		# Reading configuration files from filesystem and live-media
		set -o allexport
		for _FILE in /run/live/medium/live/config.conf /run/live/medium/live/config.conf.d/*.conf \
		 	         ${rootmnt}/lib/live/mount/medium/live/config.conf ${rootmnt}/lib/live/mount/medium/live/config.conf.d/*.conf
		do
		 	if [ -e "${_FILE}" ]; then
		 		. "${_FILE}"
		 	fi
		done
		set +o allexport
_EOT_SH_

	chmod +x ./image/live/config.conf.d/0000-user.conf
	# ---------------------------------------------------------
	fncPrint "      make 9999-user.conf"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > ./image/live/config.conf.d/9999-user.conf
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		#set -o allexport
		#set -o
		
		# === Fix Parameters ==========================================================
		# /bin/live-config or /lib/live/init-config.sh
		#  LIVE_HOSTNAME="debian"
		#  LIVE_USERNAME="user"
		#  LIVE_USER_FULLNAME="Debian Live user"
		#  LIVE_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"
		
		# === Fix Parameters [ /lib/live/config/0030-live-debconfig_passwd ] ======
		#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
		
		# === Fix Parameters [ /lib/live/config/0030-user-setup ] =================
		#_PASSWORD="8Ab05sVQ4LLps"				# '/bin/echo "live" | mkpasswd -s'
		
		# === User parameters =========================================================
		export LIVE_CONFIG_CMDLINE				# この変数はブートローダのコマンドラインに相当します。(/proc/cmdline)
		export LIVE_CONFIG_COMPONENTS			# この変数は「live-config.components=構成要素1,構成要素2, ...  構成要素n」パラメータに相当します。
		export LIVE_CONFIG_NOCOMPONENTS			# この変数は「live-config.nocomponents=構成要素1,構成要素2,  ... 構成要素n」パラメータに相当します。
		export LIVE_DEBCONF_PRESEED				# この変数は「live-config.debconf-preseed=filesystem|medium|URL1|URL2|  ...  |URLn」パラメータに相当します。
		export LIVE_HOSTNAME					# この変数は「live-config.hostname=ホスト名」パラメータに相当します。
		export LIVE_USERNAME					# この変数は「live-config.username=ユーザ名」パラメータに相当します。
		export LIVE_PASSWORD					# ユーザーパスワード
		export LIVE_EMPTYPWD					# TRUEで空パスワード
		export LIVE_CRYPTPWD					# 暗号化パスワード
		export LIVE_USER_DEFAULT_GROUPS			# この変数は「live-config.user-default-groups="グループ1,グループ2  ... グループn"」パラメータに相当します。
		export LIVE_USER_FULLNAME				# この変数は「live-config.user-fullname="ユーザのフルネーム"」パラメータに相当します。
		export LIVE_LOCALES						# この変数は「live-config.locales=ロケール1,ロケール2 ...  ロケールn」パラメータに相当します。
		export LIVE_TIMEZONE					# この変数は「live-config.timezone=タイムゾーン」パラメータに相当します。
		export LIVE_KEYBOARD_MODEL				# この変数は「live-config.keyboard-model=キーボードの種類」パラメータに相当します。
		export LIVE_KEYBOARD_LAYOUTS			# この変数は「live-config.keyboard-layouts=キーボードレイアウト1,キーボードレイアウト2... キーボードレイアウトn」パラメータに相当します。
		export LIVE_KEYBOARD_VARIANTS			# この変数は「live-config.keyboard-variants=キーボード配列1,キーボード配列2 ... キーボード配列n」パラメータに相当します。
		export LIVE_KEYBOARD_OPTIONS			# この変数は「live-config.keyboard-options=キーボードオプション」パラメータに相当します。
		export LIVE_SYSV_RC						# この変数は「live-config.sysv-rc=サービス1,サービス2  ... サービスn」パラメータに相当します。
		export LIVE_UTC							# この変数は「live-config.utc=yes|no」パラメータに相当します。
		export LIVE_X_SESSION_MANAGER			# この変数は「live-config.x-session-manager=Xセッションマネージャ」パラメータに相当します。
		export LIVE_XORG_DRIVER					# この変数は「live-config.xorg-driver=XORGドライバ」パラメータに相当します。
		export LIVE_XORG_RESOLUTION				# この変数は「live-config.xorg-resolution=XORG解像度」パラメータに相当します。
		export LIVE_WLAN_DRIVER					# この変数は「live-config.wlan-driver=WLANドライバ」パラメータに相当します。
		export LIVE_HOOKS						# この変数は「live-config.hooks=filesystem|medium|URL1|URL2| ... |URLn」パラメータに相当します。
		export LIVE_CONFIG_DEBUG				# この変数は「live-config.debug」パラメータに相当します。
		export LIVE_CONFIG_NOAUTOLOGIN			# 
		export LIVE_CONFIG_NOROOT				# 
		export LIVE_CONFIG_NOX11AUTOLOGIN		# 
		export LIVE_SESSION						# 固定値
		export LIVE_DEBUGOUT					# Debug変数
		
		LIVE_HOSTNAME="_HOSTNAME_"				# hostname
		
		LIVE_USER_FULLNAME="Debian Live user"	# full name
		LIVE_USERNAME="user"					# user name
		LIVE_PASSWORD="live"					# password
		#LIVE_CRYPTPWD='8Ab05sVQ4LLps'			# '/bin/echo "live" | mkpasswd -s'
		
		LIVE_LOCALES="ja_JP.UTF-8"				# locales
		LIVE_KEYBOARD_MODEL="pc105"				# keybord
		LIVE_KEYBOARD_LAYOUTS="jp"
		LIVE_KEYBOARD_VARIANTS="OADG109A"
		LIVE_TIMEZONE="Asia/Tokyo"				# timezone
		LIVE_UTC="yes"
		LIVE_XORG_RESOLUTION="1024x768"			# xorg resolution
		
		# === Change hostname =========================================================
		if [ -n "${LIVE_HOSTNAME:-""}" ]; then
		 	/bin/echo "${LIVE_HOSTNAME}" > /etc/hostname
		fi
		
		# === Copy shell file =========================================================
		for _FILE in /lib/live/mount/medium/live/config.conf.d/????-user-* \
		             /run/live/medium/live/config.conf.d/????-user-*
		do
		 	if [ -e "${_FILE}" ]; then
		 		cp -p "${_FILE}" /lib/live/config/
		 	fi
		done
		
		# === Creating state file =====================================================
		touch /var/lib/live/config/9999-user-config
		
		# =============================================================================
		#set +e
		# === Memo ====================================================================
		#	/lib/live/init-config.sh
		#	/lib/live/config/0020-hostname
		#	/lib/live/config/0030-live-debconfig_passwd
		#	/lib/live/config/0030-user-setup
		#	/lib/live/config/1160-openssh-server
		# *****************************************************************************
_EOT_SH_

	chmod +x ./image/live/config.conf.d/9999-user.conf
	# ---------------------------------------------------------
	fncPrint "      make 9999-user-setting"
	cat <<- '_EOT_SH_' | sed 's/^ //g' > ./image/live/config.conf.d/9999-user-setting
		#!/bin/sh
		
		#set -o ignoreeof					# Ctrl+Dで終了しない
		#set +m								# ジョブ制御を無効にする
		#set -e								# ステータス0以外で終了
		#set -u								# 未定義変数の参照で終了
		#set -e
		#set -o allexport
		#set -o
		
		/bin/echo ""
		/bin/echo "Start 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		
		#. /lib/live/config.sh
		
		#set -e
		
		Cmdline ()
		{
		 	# Reading kernel command line
		 	for _PARAMETER in ${LIVE_CONFIG_CMDLINE}
		 	do
		 		case "${_PARAMETER}" in
		 			debug   | \
		 			debugout)
		 				LIVE_DEBUGOUT="true"
		 				;;
		 			username=*)
		 				LIVE_USERNAME="${_PARAMETER#*username=}"
		 				;;
		 			password=*)
		 				LIVE_PASSWORD="${_PARAMETER#*password=}"
		 				;;
		 			emptypwd=*)
		 				LIVE_EMPTYPWD="${_PARAMETER#*emptypwd=}"
		 				;;
		 		esac
		 	done
		}
		
		Init ()
		{
		 	:
		}
		
		Config ()
		{
		 	# === Change user password ================================================
		 	if [ -n "${LIVE_USERNAME:-""}" ]; then
		#		useradd ${LIVE_USERNAME}
		 		if [ "${LIVE_EMPTYPWD:-""}" = "true" ]; then
		 			/bin/echo ""
		 			/bin/echo "Remove user password ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			passwd -d ${LIVE_USERNAME}
		 			LIVE_PASSWORD=""
		 		elif [ -n "${LIVE_PASSWORD:-""}" ]; then
		 			/bin/echo ""
		 			/bin/echo "Change user password ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | passwd ${LIVE_USERNAME}
		 		fi
		 		# === Change smb password =============================================
		 		if [ -n "`which smbpasswd 2> /dev/null`" ]; then
		 			/bin/echo ""
		 			/bin/echo "Create an smb user ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			smbpasswd -a ${LIVE_USERNAME} -n
		 			/bin/echo ""
		 			/bin/echo "Change smb password :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			/bin/echo -e "${LIVE_PASSWORD}\n${LIVE_PASSWORD}" | smbpasswd ${LIVE_USERNAME}
		 		fi
		 		# === Change user mode ====================================================
		 		if [ `passwd -S ${LIVE_USERNAME} | awk '{print $7;}'` -ne -1 ]; then
		 			/bin/echo ""
		 			/bin/echo "Change user mode ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			usermod -f -1 ${LIVE_USERNAME}
		 		fi
		 	fi
		
		 	# === Change sshd configure ===============================================
		 	if [ -f /etc/ssh/sshd_config ]; then
		 		/bin/echo ""
		 		/bin/echo "Change sshd configure :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		sed -i /etc/ssh/sshd_config \
		 		    -e 's/^#*[ \t]*\(PasswordAuthentication\)[ \t]*.*$/\1 yes/g'
		 	fi
		
		 	# === Setup VMware configure ==============================================
		 	if [ "`lscpu | grep -i vmware`" != "" ]; then
		 		/bin/echo ""
		 		/bin/echo "Setup VMware configure ::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		mkdir -p /media/hgfs
		 		chmod a+w /media/hgfs
		 		cat <<- _EOT_ >> /etc/fstab
		 			.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,defaults,users 0 0
		 _EOT_
		 		cat <<- _EOT_ >> /etc/fuse.conf
		 			user_allow_other
		 _EOT_
		 	fi
		
		 	# === Change gdm3 configure ===============================================
		 	if [ -f /etc/gdm3/custom.conf ] && [ -n "${LIVE_USERNAME:-""}" ]; then
		 		/bin/echo ""
		 		/bin/echo "Change gdm3 configure :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		OLD_IFS=${IFS}
		 		IFS= INS_STR=$(
		 			cat <<- _EOT_ | sed ':l; N; s/\n//; b l;'
		 				WaylandEnable=false\\n
		 				AutomaticLoginEnable=true\n
		 				AutomaticLogin=${LIVE_USERNAME}\\n
		 				TimedLoginEnable=false\\n
		 _EOT_
		 		)
		 		IFS=${OLD_IFS}
		 		sed -i /etc/gdm3/custom.conf \
		 		    -e '/^\[daemon\]/,/^\[/ {/^[#|\[]/! s/\(.*\)$/#  \1/g}' \
		 		    -e "/^\\[daemon\\]/a ${INS_STR}"
		 		if [ ! -f /etc/gdm3/daemon.conf ]; then
		 			/bin/echo ""
		 			/bin/echo "Create gdm3 daemon.conf :::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 			touch /etc/gdm3/daemon.conf
		 		fi
		 	fi
		
		 	# === Change video mode configure =========================================
		 	if [ -f /etc/X11/Xsession.d/21xvidemode ]; then
		 		/bin/echo ""
		 		/bin/echo "Change video mode configure :::::::::::::::::::::::::::::::::::::::::::::::::::"
		 		sed -i /etc/X11/Xsession.d/21xvidemode \
		 		    -e '1i {\nsleep 10' \
		 		    -e '$a } &'
		 	fi
		}
		
		Debug ()
		{
		 	if [ -z ${LIVE_DEBUGOUT:-""} ]; then
		 		return 0
		 	fi
		 	# === Display of parameters ===============================================
		 	/bin/echo ""
		 	/bin/echo "Display of parameters :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		 	set | grep -e "^LIVE_.*="
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	dconf dump /org/gnome/desktop/screensaver/
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	dconf dump /org/gnome/todo/
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	printenv | sort
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	for F in $(find "/lib/systemd/system/" -type f -name "*.service" -print | sort -u)
		 	do
		 		S=`basename $F`
		 		R=`systemctl is-enabled "$S" || :`
		 		/bin/echo "$S: $R"
		 	done
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	mount | sort
		 	/bin/echo "-------------------------------------------------------------------------------"
		 	set -o
		 	/bin/echo "-------------------------------------------------------------------------------"
		}
		
		Cmdline
		Init
		Config
		Debug
		
		# === Creating state file =====================================================
		/bin/echo ""
		/bin/echo "Creating state file :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
		touch /var/lib/live/config/9999-user-setting

		/bin/echo ""
		/bin/echo "End 9999-user-setting :::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
_EOT_SH_

	chmod +x ./image/live/config.conf.d/9999-user-setting
	# ---------------------------------------------------------
	OLD_IFS=${IFS}
	IFS=$'\n'
	FULLNAME="`awk '(!/#/&&/d-i[ \t]+passwd\/user-fullname[ \t]+/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg | sed -z 's/\n//g' | sed -e 's/.*[ \t]*string[ \t]*//'`"
	USERNAME="`awk '(!/#/&&/d-i[ \t]+passwd\/username[ \t]+/),(!/\\\\/)      {print $0;}' image/preseed/preseed.cfg | sed -z 's/\n//g' | sed -e 's/.*[ \t]*string[ \t]*//'`"
	PASSWORD="`awk '(!/#/&&/d-i[ \t]+passwd\/user-password[ \t]+/),(!/\\\\/) {print $0;}' image/preseed/preseed.cfg | sed -z 's/\n//g' | sed -e 's/.*[ \t]*password[ \t]*//'`"
	IFS=${OLD_IFS}
	# ---------------------------------------------------------
	if [ -z "${CODE_NAME[0]}" ]; then sed -i ./image/live/config.conf.d/9999-user.conf -e 's/^[ \t]*\(LIVE_HOSTNAME=\)/#\1/'; fi
	if [ -z "${FULLNAME}"     ]; then sed -i ./image/live/config.conf.d/9999-user.conf -e 's/^[ \t]*\(LIVE_USER_FULLNAME=\)/#\1/'; fi
	if [ -z "${USERNAME}"     ]; then sed -i ./image/live/config.conf.d/9999-user.conf -e 's/^[ \t]*\(LIVE_USERNAME=\)/#\1/'; fi
	if [ -z "${PASSWORD}"     ]; then sed -i ./image/live/config.conf.d/9999-user.conf -e 's/^[ \t]*\(LIVE_PASSWORD=\)/#\1/'; fi
	# ---------------------------------------------------------
	sed -i ./image/live/config.conf.d/9999-user.conf         \
	    -e "s/_HOSTNAME_/${HOSTNAME}/"                       \
	    -e "s/^\(LIVE_USER_FULLNAME\)=.*$/\1='${FULLNAME}'/" \
	    -e "s/^\(LIVE_USERNAME\)=.*$/\1='${USERNAME}'/"      \
	    -e "s/^\(LIVE_PASSWORD\)=.*$/\1='${PASSWORD}'/"
}
# -----------------------------------------------------------------------------
fncRemaster () {
	# --- ARRAY_NAME ----------------------------------------------------------
	local ARRY_NAME=($1)											# 配列展開
	local CODE_NAME=()												# 配列宣言
	CODE_NAME[0]=${ARRY_NAME[0]}									# 区分
	CODE_NAME[1]=`basename ${ARRY_NAME[2]} | sed -e 's/.iso//ig'`	# DVDファイル名
	CODE_NAME[2]=${ARRY_NAME[1]}									# ダウンロード先URL
	CODE_NAME[3]=${ARRY_NAME[3]}									# 定義ファイル
	CODE_NAME[4]=${ARRY_NAME[4]}									# リリース日
	CODE_NAME[5]=${ARRY_NAME[5]}									# サポ終了日
	CODE_NAME[6]=${ARRY_NAME[6]}									# 備考
	CODE_NAME[7]=${ARRY_NAME[7]}									# 備考2
	# -------------------------------------------------------------------------
	fncPrint "=== ↓処理中：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '=')"
	# --- DVD -----------------------------------------------------------------
	local DVD_NAME="${CODE_NAME[1]}"
	local DVD_URL="${CODE_NAME[2]}"
	# --- preseed.cfg ---------------------------------------------------------
	local CFG_NAME="${CODE_NAME[3]}"
	local CFG_URL="https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/${CFG_NAME}"
	# -------------------------------------------------------------------------
	for POINT in `mount | sed -n "/${WORK_DIRS}\/${CODE_NAME[1]}/ s/.*on[ \t]*\(.*\)[ \t]*type.*\$/\1/gp"`
	do
		set +e
		mountpoint -q "${POINT}"
		if [ $? -eq 0 ]; then
			if [ "`basename ${POINT}`" = "dev" ]; then
				umount -q "${POINT}/pts" || umount -q -lf "${POINT}/pts"
			fi
			umount -q "${POINT}" || umount -q -lf "${POINT}"
		fi
		set -e
	done
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	mkdir -p ${WORK_DIRS}/${CODE_NAME[1]}/image ${WORK_DIRS}/${CODE_NAME[1]}/decomp ${WORK_DIRS}/${CODE_NAME[1]}/mnt
	# --- remaster ------------------------------------------------------------
	pushd ${WORK_DIRS}/${CODE_NAME[1]} > /dev/null
		# --- get iso file ----------------------------------------------------
		set +e
		curl -L -R -S -s -f --connect-timeout 60 --retry 3 -I --dump-header "./header.txt" "${DVD_URL}" > /dev/null || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
		set -e
		local WEB_STAT=`cat ./header.txt | awk '/^HTTP\// {print $2;}' | tail -n 1`
		local WEB_SIZE=`cat ./header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
		local WEB_LAST=`cat ./header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
		local WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
		if [ -f "./header.txt" ]; then
			rm -f "./header.txt"
		fi
		if [ ${WEB_STAT:--1} -ne 200 ]; then
			echo "web error: ${WEB_STAT}"
			return 1
		fi
															# Download
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			fncPrint "    get ${DVD_NAME}.iso (`printf \"%'d\n\" ${WEB_SIZE}` byte)"
			set +e
			curl -L -# -R -S -f --create-dirs --connect-timeout 60 --retry 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
			set -e
		else
			local DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../${DVD_NAME}.iso"`
			local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
			local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
			if [ "${WEB_SIZE}" != "${DVD_SIZE}" ] || [ "${WEB_DATE}" != "${DVD_DATE}" ]; then
				fncPrint "    get ${DVD_NAME}.iso (`printf \"%'d\n\" ${WEB_SIZE}` byte)"
				set +e
				curl -L -# -R -S -f --create-dirs --connect-timeout 60 --retry 3 -o "../${DVD_NAME}.iso" "${DVD_URL}" || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
				set -e
			fi
		fi
															# compare
		if [ ! -f "../${DVD_NAME}.iso" ]; then
			echo "file not exist: ../${DVD_NAME}.iso"
			return 1
		fi
		local DVD_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../${DVD_NAME}.iso"`
		local DVD_SIZE=`echo ${DVD_INFO} | awk '{print $5;}'`
		local DVD_DATE=`echo ${DVD_INFO} | awk '{print $6;}'`
		if [ "${WEB_SIZE}" != "${DVD_SIZE}" ]; then
			echo "file size error: ../${DVD_NAME}.iso (`printf \"%'d\n\" ${WEB_SIZE}` != `printf \"%'d\n\" ${DVD_SIZE}`)"
			return 1
		fi
															# Volume ID
		if [ "`${CMD_WICH} volname 2> /dev/null`" != "" ]; then
			local VOLID=`volname "../${DVD_NAME}.iso"`
		else
			local VOLID=`LANG=C blkid -s LABEL "../${DVD_NAME}.iso" | sed -e 's/.*="\(.*\)"/\1/g'`
		fi
		# --- mnt -> image ----------------------------------------------------
		fncPrint "    copy DVD -> work directory"
		mount -r -o loop "../${DVD_NAME}.iso" mnt
		pushd mnt > /dev/null								# 作業用マウント先
			find . -depth -print | cpio -pdm --quiet ../image/
		popd > /dev/null
		umount mnt
		# --- image -----------------------------------------------------------
		pushd image > /dev/null								# 作業用ディスクイメージ
			# --- splash.png --------------------------------------------------
			case "${CODE_NAME[0]}" in
				"ubuntu" )
#					WALL_URL="http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
					WALL_URL="http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/ubuntu-installer/amd64/boot-screens/splash.png"
					WALL_FILE="ubuntu_splash.png"
					if [ -f isolinux/txt.cfg ]; then
						if [ ! -f "../../../${WALL_FILE}" ]; then
							fncPrint "    get ${WALL_FILE}"
							set +e
							curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
							set -e
						else
							set +e
							curl -L -R -S -s -f --connect-timeout 3 --retry 3 -I --dump-header "./header.txt" "${WALL_URL}" > /dev/null
							set -e
							WEB_SIZE=`cat ./header.txt | awk 'sub(/\r$/,"") tolower($1)~/content-length/ {print $2;}' | awk 'END{print;}'`
							WEB_LAST=`cat ./header.txt | awk 'sub(/\r$/,"") tolower($1)~/last-modified/ {print substr($0,16);}' | awk 'END{print;}'`
							WEB_DATE=`TZ=UTC date -d "${WEB_LAST}" "+%Y%m%d%H%M%S"`
							FILE_INFO=`TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S JST" "../../../${WALL_FILE}"`
							FILE_SIZE=`echo ${FILE_INFO} | awk '{print $5;}'`
							FILE_DATE=`echo ${FILE_INFO} | awk '{print $6;}'`
							if [ "${WEB_SIZE}" != "${FILE_SIZE}" ] || [ "${WEB_DATE}" != "${FILE_DATE}" ]; then
								fncPrint "    get ${WALL_FILE}"
								set +e
								curl -L -# -R -S -f --connect-timeout 3 --retry 3 -o "../../../${WALL_FILE}" "${WALL_URL}" || { rm -f "../../../${WALL_FILE}"; exit 1; }
								set -e
							fi
							if [ -f "./header.txt" ]; then
								rm -f "./header.txt"
							fi
						fi
					fi
					;;
				* )	;;
			esac
			# --- preseed.cfg -> image ----------------------------------------
			case "${CODE_NAME[0]}" in
				"debian" | \
				"ubuntu" )
					EFI_IMAG="boot/grub/efi.img"
					ISO_NAME="${DVD_NAME}-preseed"
					# ---------------------------------------------------------
					mkdir -p "preseed"
					CFG_FILE=`echo ${CFG_NAME} | awk -F ',' '{print $1;}'`
					CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${CFG_FILE}~"`
					# --- preseed.cfg -> image --------------------------------
					if [ ! -f "../../../${CFG_FILE}" ]; then
						fncPrint "    get ${CFG_FILE}"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --retry 3 --output-dir "../../../" -O "${CFG_ADDR}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_FILE}" "preseed/preseed.cfg"
					# ---------------------------------------------------------
					if [ "${CODE_NAME[0]}" = "ubuntu" ]; then
						if [[ "${CODE_NAME[1]}" =~ ^.*-live-server-.*$ ]] || \
						 { [[ "${CODE_NAME[1]}" =~ ^.*-desktop-.*$ ]] && [ ! -f casper/filesystem.squashfs ] && [ ! -f install/filesystem.squashfs ]; } then
							EFI_IMAG="boot/grub/efi.img"
							ISO_NAME="${DVD_NAME}-nocloud"
							# ---------------------------------------------
							mkdir -p "nocloud"
							touch nocloud/user-data			# 必須
							touch nocloud/meta-data			# 必須
							touch nocloud/vendor-data		# 省略可能
							touch nocloud/network-config	# 省略可能
							CFG_FILE=`echo ${CFG_NAME} | awk -F ',' '{print $2;}'`
							CFG_ADDR=`echo ${CFG_URL} | sed -e "s~${CFG_NAME}~${CFG_FILE}~"`
							if [ ! -f "../../../${CFG_FILE}" ]; then
								fncPrint "    get ${CFG_FILE}"
								set +e
								curl -L -# -R -S -f --connect-timeout 3 --retry 3 --output-dir "../../../" -O "${CFG_ADDR}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
								set -e
							fi
							cp --preserve=timestamps "../../../${CFG_FILE}" "nocloud/user-data"
						fi
					fi
					# oldoldstable    Debian__9.xx(stretch)
					# oldstable       Debian_10.xx(buster)
					# stable          Debian_11.xx(bullseye)
					# testing         Debian_12.xx(bookworm)
					# Trusty_Tahr     Ubuntu_14.04(Trusty_Tahr):LTS
					# Xenial_Xerus    Ubuntu_16.04(Xenial_Xerus):LTS
					# Bionic_Beaver   Ubuntu_18.04(Bionic_Beaver):LTS
					# Focal_Fossa     Ubuntu_20.04(Focal_Fossa):LTS
					# Impish_Indri    Ubuntu_21.10(Impish_Indri)
					# Jammy_Jellyfish Ubuntu_22.04(Jammy_Jellyfish):LTS
					# Kinetic_Kudu    Ubuntu_22.10(Kinetic Kudu)
					# Lunar_Lobster   Ubuntu_23.04(Lunar Lobster)
					fncCreate_late_command "./preseed"
					case "`echo ${CODE_NAME[7]} | sed -e 's/^.*(\(.*\)).*$/\1/'`" in
						wheezy         | \
						jessie         )
							sed -i preseed/preseed.cfg          \
							    -e 's/bind9-utils/bind9utils/'  \
							    -e 's/bind9-dnsutils/dnsutils/'
							sed -i "preseed/preseed.cfg"                                                                               \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/hostname\).*$/\1 string archive.debian.org/'                     \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror\/http\/directory\).*$/\1 string \/debian-archive\/debian/'              \
							    -e 's/\(^[ \t]*d-i[ \t]*mirror/http/mirror select\).*$/\1 select archive.debian.org/'                  \
							    -e 's/\(^[ \t]*d-i[ \t]*apt-setup\/services-select\).*$/\1 multiselect updates/'
							;;
						stretch        | \
						buster         )
							sed -i preseed/preseed.cfg          \
							    -e 's/bind9-utils/bind9utils/'  \
							    -e 's/bind9-dnsutils/dnsutils/'
							;;
						bullseye       | \
						bookworm       | \
						testing        )
							;;
						Trusty_Tahr    | \
						Xenial_Xerus   | \
						Bionic_Beaver  )
#							sed -i preseed/preseed.cfg                                                \
#							    -e 's/\(^[ \t]*d-i[ \t]*debian-installer\/language\).*$/\1 string C/' \
#							    -e 's/bind9-utils/bind9utils/'                                        \
#							    -e 's/bind9-dnsutils/dnsutils/'                                       \
#							    -e 's/network-manager//'
#							if [ -f "nocloud/user-data" ]; then
#								sed -i "nocloud/user-data"          \
#								    -e 's/bind9-utils/bind9utils/'  \
#								    -e 's/bind9-dnsutils/dnsutils/' \
#								    -e 's/network-manager//'
#							fi
							sed -i preseed/preseed.cfg                                                \
							    -e 's/bind9-utils/bind9utils/'                                        \
							    -e 's/bind9-dnsutils/dnsutils/'                                       
							if [ -f "nocloud/user-data" ]; then
								sed -i "nocloud/user-data"          \
								    -e 's/bind9-utils/bind9utils/'  \
								    -e 's/bind9-dnsutils/dnsutils/' 
							fi
							fncCreate_success_command "./preseed"
							;;
						Focal_Fossa     | \
						Groovy_Gorilla  | \
						Hirsute_Hippo   | \
						Impish_Indri    | \
						Jammy_Jellyfish | \
						Kinetic_Kudu    | \
						Lunar_Lobster   )
							fncCreate_success_command "./preseed"
							;;
						* )	;;
					esac
					case "${CODE_NAME[1]}" in
						*netinst* )
							sed -i "preseed/preseed.cfg"                                              \
							    -e 's/\(^[ \t]*d-i[ \t]*debian-installer\/language\).*$/\1 string C/'
							;;
						* )	;;
					esac
					case "${CODE_NAME[1]}" in
						*mini* )
							pushd ../decomp > /dev/null		# initrd.gz 展開先
								fncPrint "    unzip initrd.gz"
								gunzip < ../image/initrd.gz | cpio -i --quiet
								cp --preserve=timestamps "../image/preseed/preseed.cfg" "./"
								cp --preserve=timestamps "../image/preseed/sub_late_command.sh" "./"
								sed -i ./preseed.cfg                                                \
								    -e '/^[^#].*preseed\/late_command/,/[^\\]$/ s~/cdrom/preseed~~'
								fncPrint "    create initps.gz"
								find . | cpio -H newc --create --quiet | gzip -9 > ../image/initps.gz
							popd > /dev/null
							;;
						* )	;;
					esac
					;;
				"centos"       | \
				"fedora"       | \
				"rocky"        | \
				"miraclelinux" | \
				"almalinux"    )	# --- get ks.cfg ----------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-kickstart"
					mkdir -p "kickstart"
					if [ ! -f "../../../${CFG_NAME}" ]; then
						fncPrint "    get ${CFG_NAME}"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --retry 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_NAME}" "kickstart/ks.cfg"
					sed -i kickstart/ks.cfg                \
					    -e "s/_HOSTNAME_/${CODE_NAME[0]}/" \
					    -e '/^url /   s/^/#/g'             \
					    -e '/^repo /  s/^/#/g'
					case "${CODE_NAME[1]}" in
						Fedora-* )
							VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '-' '{print $5;}')
							sed -i kickstart/ks.cfg                          \
							    -e "/url /  {/repo=${CODE_NAME[0]}/ s/^#//}" \
							    -e "/repo / {/repo=${CODE_NAME[0]}/ s/^#//}"
							if [ ${VER_NUM} -ge 36 ]; then
								sed -i kickstart/ks.cfg                    \
								    -e '/%anaconda/,/%end/{/^#/! s/^/#/g}'
							fi
							;;
						MIRACLELINUX-8* | \
						MIRACLELINUX-9* )
							VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '[-.]' '{print $2;}')
							ARC_NUM=$(echo "${CODE_NAME[1]}" | awk -F '[-.]' '{print $5;}')
							if [ "${ARC_NUM}" = "minimal" ]; then
								ARC_NUM=$(echo "${CODE_NAME[1]}" | awk -F '[-.]' '{print $6;}')
							fi
							sed -i kickstart/ks.cfg                       \
							    -e "/url /  {/${CODE_NAME[0]}/ s/^#//}"   \
							    -e "/repo / {/${CODE_NAME[0]}/ s/^#//}"   \
							    -e "/^url /  s/\$releasever/${VER_NUM}/g" \
							    -e "/^url /  s/\$basearch/${ARC_NUM}/g"   \
							    -e "/^repo / s/\$releasever/${VER_NUM}/g" \
							    -e "/^repo / s/\$basearch/${ARC_NUM}/g"
							;;
						* )
							sed -i kickstart/ks.cfg             \
							    -e '/--name=epel/      s/^#//'  \
							    -e '/--name=epel_next/ s/^#//'  \
							    -e '/--name=Remi/      s/^#//'  \
							    -e '/%packages/,/%end/ s/^#//g'
							case "${CODE_NAME[1]}" in
								CentOS-Stream-8* )
									sed -i kickstart/ks.cfg                                   \
									    -e "/url .*mirrorlist\./  {/${CODE_NAME[0]}/ s/^#//}" \
									    -e "/repo .*mirrorlist\./ {/${CODE_NAME[0]}/ s/^#//}"
									;;
								CentOS-Stream-9* )
									sed -i kickstart/ks.cfg                                     \
									    -e "/url .*mirror\.stream/  {/${CODE_NAME[0]}/ s/^#//}" \
									    -e "/repo .*mirror\.stream/ {/${CODE_NAME[0]}/ s/^#//}" \
									    -e '/%anaconda/,/%end/ {/^#/! s/^/#/g}'                 \
									    -e '/%packages/,/%end/ {/^ibus-mozc/ s/^/#/}'
									;;
								AlmaLinux-9*     )
									sed -i kickstart/ks.cfg                      \
									    -e "/url /  {/${CODE_NAME[0]}/ s/^#//}"  \
									    -e "/repo / {/${CODE_NAME[0]}/ s/^#//}"  \
									    -e '/%anaconda/,/%end/{/^#/!   s/^/#/g}'
									;;
								Rocky-9*         )
									VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '[-.]' '{print $2;}')
									ARC_NUM=$(echo "${CODE_NAME[1]}" | awk -F '[-.]' '{print $4;}')
									sed -i kickstart/ks.cfg                       \
									    -e "/url /  {/${CODE_NAME[0]}/ s/^#//}"   \
									    -e "/repo / {/${CODE_NAME[0]}/ s/^#//}"   \
									    -e '/%anaconda/,/%end/{/^#/!   s/^/#/g}'  \
									    -e "/^url /  s/\$releasever/${VER_NUM}/g" \
									    -e "/^url /  s/\$basearch/${ARC_NUM}/g"   \
									    -e "/^repo / s/\$releasever/${VER_NUM}/g" \
									    -e "/^repo / s/\$basearch/${ARC_NUM}/g"
									;;
								* )
									sed -i kickstart/ks.cfg                     \
									    -e "/url /  {/${CODE_NAME[0]}/ s/^#//}" \
									    -e "/repo / {/${CODE_NAME[0]}/ s/^#//}"
									;;
							esac
							;;
					esac
					case "${CODE_NAME[1]}" in
						CentOS-Stream-8* | \
						MIRACLELINUX-8*  | \
						Rocky-8*         )
							local TMZONE=`awk '$1=="timezone" {print $2;}' kickstart/ks.cfg`
							local NTPSVR=`awk -F '[ \t=]' '$1=="timesource" {print $3;}' kickstart/ks.cfg`
							sed -i kickstart/ks.cfg                                                   \
							    -e "s~^\(timezone\).*\$~\1 ${TMZONE} --isUtc --ntpservers=${NTPSVR}~" \
							    -e '/timesource/d'
							;;
						* )
							;;
					esac
					case "${WORK_DIRS}" in
						*dvd* )
							sed -i kickstart/ks.cfg                      \
							    -e '/^#cdrom/                   s/^#//'  \
							    -e '/^url /                     s/^/#/g' \
							    -e '/^repo .* --name=AppStream/ s/^/#/g'
							;;
						*     )
							sed -i kickstart/ks.cfg    \
							    -e '/^cdrom/  s/^/#/'
							;;
					esac
					;;
				"suse")	# --- get autoinst.xml --------------------------------
					EFI_IMAG="EFI/BOOT/efiboot.img"
					ISO_NAME="${DVD_NAME}-autoyast"
					mkdir -p "autoyast"
					if [ ! -f "../../../${CFG_NAME}" ]; then
						fncPrint "    get ${CFG_NAME}"
						set +e
						curl -L -# -R -S -f --connect-timeout 3 --retry 3 --output-dir "../../../" -O "${CFG_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
						set -e
					fi
					cp --preserve=timestamps "../../../${CFG_NAME}" "autoyast/autoinst.xml"
					case "${CODE_NAME[1]}" in
						*Leap* )
							VER_NUM=$(echo "${CODE_NAME[1]}" | awk -F '-' '{print $3;}')
							sed -i autoyast/autoinst.xml                                                 \
							    -e "/<media_url>/ s~\(update/leap\)/.*/\(oss\)~\1/${VER_NUM}/\2~"        \
							    -e "/<media_url>/ s~\(distribution/leap\)/.*/\(repo\)~\1/${VER_NUM}/\2~" \
							    -e 's~\(<product>\).*\(</product>\)~\1Leap\2~'
							;;
						*Tumbleweed* )
							sed -i autoyast/autoinst.xml                                        \
							    -e '/<media_url>/ s~update/leap/.*/oss~update/tumbleweed~'      \
							    -e '/<media_url>/ s~distribution/leap/.*/repo~tumbleweed/repo~' \
							    -e 's~\(<product>\).*\(</product>\)~\1openSUSE\2~'              \
							    -e 's/eth0/ens160/g'
							;;
					esac
					;;
				* )	;;
			esac
			# --- Get EFI Image -----------------------------------------------
			if [ ! -f ${EFI_IMAG} ]; then
				ISO_SKIPS=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $2;}'`
				ISO_COUNT=`fdisk -l "../../${DVD_NAME}.iso" | awk '/EFI/ {print $4;}'`
				dd if="../../${DVD_NAME}.iso" of=${EFI_IMAG} bs=512 skip=${ISO_SKIPS} count=${ISO_COUNT} status=none
			fi
			# --- mrb:txt.cfg / efi:grub.cfg ----------------------------------
			case "${CODE_NAME[1]}" in
				mini* )
					# --- txt.cfg -------------------------------------
					sed -i isolinux.cfg -e 's/\(timeout\).*$/\1 50/'
					sed -i prompt.cfg   -e 's/\(timeout\).*$/\1 50/'
#					sed -i gtk.cfg      -e '/^.*menu default.*$/d'
					sed -i txt.cfg      -e '/^.*menu default.*$/d'
					INS_ROW=$((`sed -n '/^label/ =' txt.cfg | awk 'NR==1 {print}'`-1))
					INS_STR="\\`sed -n '/menu label/p' txt.cfg | awk 'NR==1 {print}' | sed -e 's/\(^.*menu\).*/\1 default/'`"
					if [ ${INS_ROW} -ge 1 ]; then
						sed -n '/label install/,/append/p' txt.cfg | \
						sed -e 's/^\(label\) install/\1 autoinst/'   \
						    -e 's/\(Install\)/Auto \1/'              \
						    -e "s/initrd.gz/initps.gz/"              \
						    -e "/menu label/a ${INS_STR}"          | \
						sed -e "${INS_ROW}r /dev/stdin" txt.cfg      \
						    -e '1i timeout 50'                       \
						> txt.cfg.temp
					else
						sed -n '/label install/,/append/p' txt.cfg | \
						sed -e 's/^\(label\) install/\1 autoinst/'   \
						    -e 's/\(Install\)/Auto \1/'              \
						    -e "s/initrd.gz/initps.gz/"              \
						    -e "/menu label/a ${INS_STR}"            \
						    -e '1i timeout 50'                       \
						> txt.cfg.temp
						cat txt.cfg >> txt.cfg.temp
					fi
					mv txt.cfg.temp txt.cfg
					# --- grub.cfg ----------------------------------------------------
					INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
					if [ ${INS_ROW} -ge 1 ]; then
						sed -n '/^menuentry .*['\''"]Install['\''\"]/,/^}/p' boot/grub/grub.cfg | \
						sed -e 's/\(Install\)/Auto \1/'                                           \
						    -e "s/initrd.gz/initps.gz/"                                           \
						    -e 's/\(--hotkey\)=./\1=a/'                                         | \
						sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                      | \
						sed -e 's/\(set default\)="1"/\1="0"/'                                    \
						    -e '1i set timeout=5'                                                 \
						    -e 's/\(set theme\)/# \1/g'                                           \
						    -e 's/\(set gfxmode\)/# \1/g'                                         \
						    -e 's/ vga=[0-9]*//g'                                                 \
						> grub.cfg.temp
						mv grub.cfg.temp boot/grub/grub.cfg
					else
						cat <<- _EOT_ >> boot/grub/grub.cfg
							menuentry 'Auto Install' {
							    set background_color=black
							    linux    /linux vga=788 --- quiet
							    initrd   /initps.gz
							}
_EOT_
					fi
					;;
				* )
					case "${CODE_NAME[0]}" in
						"debian" )	# ･････････････････････････････････････････
							case "${CODE_NAME[1]}" in
								*-live-* )
									# === 日本語化 ============================
									INS_CFG="locales=ja_JP.UTF-8 timezone=Asia\/Tokyo keyboard-model=jp106 keyboard-layouts=jp"
									# --- grub.cfg --------------------------------------------------------
									touch grub.cfg
									if [ "`sed -n '/^menuentry \"Debian GNU\/Linux.*\"/,/^}/p' boot/grub/grub.cfg`" != "" ]; then
										INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/^menuentry \"Debian GNU\/Linux.*\"/,/^}/p' boot/grub/grub.cfg | \
										sed -e 's/\(Debian GNU\/Linux.*)\)/\1 for Japanese language/'            \
										    -e "s~\(components\)~\1 ${INS_CFG}~"                               | \
										sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       \
										    -e '1i set default=0'                                                \
										    -e '1i set timeout=5'                                                \
										> grub.cfg
									else
										INS_ROW=$((`sed -n '/^# Live boot/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/^menuentry \"Live system (amd64)\"/,/^}/p' boot/grub/grub.cfg | \
										sed -e 's/\(Live system.*)\)/\1 for Japanese language/'                  \
										    -e "s~\(components\)~\1 ${INS_CFG}~"                                 \
										    -e 's/--hotkey=. *//'                                                \
										    -e '1i # User added menu'                                            \
										    -e '$ a \\n'                                                       | \
										sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                       \
										    -e '1i set default=0'                                                \
										    -e '1i set timeout=5'                                                \
										> grub.cfg
									fi
									mv grub.cfg boot/grub/
									# --- menu.cfg ----------------------------
									touch menu.cfg
									if [ "`sed -n '/LABEL Debian GNU\/Linux Live.*/,/^$/p' isolinux/menu.cfg`" != "" ]; then
										INS_ROW=$((`sed -n '/^LABEL/ =' isolinux/menu.cfg | awk 'NR==1 {print}'`-1))
										INS_STR=`sed -n 's/LABEL \(Debian GNU\/Linux Live.*\)/\1 for Japanese language/p' isolinux/menu.cfg`
										sed -n '/LABEL Debian GNU\/Linux Live.*/,/^$/p' isolinux/menu.cfg | \
										sed -e "s~\(LABEL\) .*~\1 ${INS_STR}~"                              \
										    -e "s~\(SAY\) .*~\1 \"${INS_STR}\.\.\.\"~"                      \
										    -e "s~\(APPEND .* components\) \(.*$\)~\1 ${INS_CFG} \2~"     | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                 | \
										sed -e "s~^\(DEFAULT\) .*$~\1 ${INS_STR}~"                          \
										> menu.cfg
									else
										INS_ROW=$((`sed -n '/^include live.cfg/ =' isolinux/menu.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/^label live-amd64$/,/^$/p' isolinux/live.cfg         | \
										sed -e "s~^\(label .*$\)~\1-jp~"                                \
										    -e "s~\(menu label .*\)~\1 for Japanese language~"          \
										    -e "s~\(append .* components\) \(.*$\)~\1 ${INS_CFG} \2~"   \
										    -e '1i # User added menu'                                 | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg               \
										> menu.cfg
										sed -e '/menu default/d' -i isolinux/live.cfg
									fi
									mv menu.cfg isolinux/
									# -----------------------------------------
									sed -i isolinux/isolinux.cfg     \
									    -e 's/\(timeout\).*$/\1 50/'
									# === preseed =============================
									INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
									# --- grub.cfg ----------------------------
									touch grub.cfg
									if [ "`sed -n '/^menuentry \"Graphical Debian Installer\"/,/^}/p' boot/grub/grub.cfg`" != "" ]; then
										INS_ROW=$((`sed -n '/^menuentry "Graphical Debian Installer"/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/^menuentry "Graphical Debian Installer"/,/^}/p' boot/grub/grub.cfg | \
										sed -e 's/\(menuentry "Graphical Debian\) \(Installer"\)/\1 Auto \2/'         \
										    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                                   | \
										sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                            \
										> grub.cfg
									else
										INS_ROW=$((`sed -n '/^menuentry ".* for Japanese language"/,/^}/ =' boot/grub/grub.cfg | awk 'END{print}'`))
										sed -n '/^submenu '\''Graphical installer \.\.\./,/^}/p' boot/grub/install.cfg | \
										sed -n '/menuentry '\''Install'\''/,/}/p'                                      | \
										sed -e 's/\(menuentry '\''\)\(Install'\''\)/\1Graphical Auto \2/'                \
										    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                                        \
										    -e 's/--hotkey=. *//'                                                        \
										    -e 's/^[ \t]//g'                                                           | \
										sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                               \
										> grub.cfg
									fi
									mv grub.cfg boot/grub/
									# --- menu.cfg ----------------------------
									touch menu.cfg
									if [ "`sed -n '/LABEL Graphical Debian Installer$/,/^$/p' isolinux/menu.cfg`" != "" ]; then
										INS_ROW=$((`sed -n '/^LABEL Graphical Debian Installer/ =' isolinux/menu.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/LABEL Graphical Debian Installer$/,/^$/p' isolinux/menu.cfg | \
										sed -e 's/^\(LABEL Graphical Debian\) \(Installer\)/\1 Auto \2/'       \
										    -e "s/\(APPEND.*\$\)/\1 ${INS_CFG}/"                             | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg                      \
										> menu.cfg
									else
										INS_ROW=$((`sed -n '/^include live.cfg/ =' isolinux/menu.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/^label installstart$/,/^$/p' isolinux/install.cfg | \
										sed -e "s~^\(label\) installstart$~\1 install-gui~"          \
										    -e "s~\(menu label\).*~\1 ^Auto Install~"                \
										    -e "s~\(append\) \(.*$\)~\1 ${INS_CFG} \2~"            | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/menu.cfg            \
										> menu.cfg
										sed -e '/menu default/d' -i isolinux/install.cfg
									fi
									mv menu.cfg isolinux/
									# -----------------------------------------
									OLD_IFS=${IFS}
									IFS=$'\n'
									# --- packages ----------------------------
									LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' preseed/preseed.cfg  | \
									           sed -z 's/\n//g'                                                          | \
									           sed -e 's/.* multiselect *//'                                               \
									               -e 's/[,|\\\\]//g'                                                      \
									               -e 's/\t/ /g'                                                           \
									               -e 's/  */ /g'                                                          \
									               -e 's/^ *//'`
									LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' preseed/preseed.cfg | \
									           sed -z 's/\n//g'                                                          | \
									           sed -e 's/.* string *//'                                                    \
									               -e 's/[,|\\\\]//g'                                                      \
									               -e 's/\t/ /g'                                                           \
									               -e 's/  */ /g'                                                          \
									               -e 's/^ *//'`
									IFS=${OLD_IFS}
									# --- firmware ----------------------------
#									fncPrint "    firmware download"
#									CODE_VER="`cat .disk/info | sed -e 's/.*"\(.*\)".*/\L\1/'`"
#									FIRM_URL="https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/${CODE_VER}/current/firmware.zip"
#									set +e
#									curl -L -# -R -S -f --connect-timeout 3 --retry 3 --output-dir "firmware/" -O "${FIRM_URL}"  || if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then return 1; fi
#									set -e
#									unzip -q -o firmware/firmware.zip -d firmware/
									;;
								* )
									INS_CFG="auto=true file=\/cdrom\/preseed\/preseed.cfg"
									# --- grub.cfg ----------------------------
									INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
									sed -n '/^menuentry .*'\''Install'\''/,/^}/p' boot/grub/grub.cfg | \
									sed -e 's/\(Install\)/Auto \1/'                                    \
									    -e "s/\(vmlinuz.*\$\)/\1 ${INS_CFG}/"                          \
									    -e 's/\(--hotkey\)=./\1=a/'                                  | \
									sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg               | \
									sed -e 's/\(set default\)="1"/\1="0"/'                             \
									    -e '1i set timeout=5'                                          \
									    -e 's/\(set theme\)/# \1/g'                                    \
									    -e 's/\(set gfxmode\)/# \1/g'                                  \
									    -e 's/ vga=[0-9]*//g'                                          \
									> grub.cfg
									mv grub.cfg boot/grub/
									# --- txt.cfg -----------------------------
									sed -i isolinux/isolinux.cfg     \
									    -e 's/\(timeout\).*$/\1 50/'
									sed -i isolinux/prompt.cfg       \
									    -e 's/\(timeout\).*$/\1 50/'
									sed -i isolinux/gtk.cfg        \
									    -e '/^.*menu default.*$/d'
									sed -i isolinux/txt.cfg        \
									    -e '/^.*menu default.*$/d'
									INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | awk 'NR==1 {print}'`-1))
									INS_STR="\\`sed -n '/menu label/p' isolinux/txt.cfg | awk 'NR==1 {print}' | sed -e 's/\(^.*menu\) label.*$/\1 default/'`"
									if [ ${INS_ROW} -ge 1 ]; then
										sed -n '/label install/,/^$/p' isolinux/txt.cfg  | \
										sed -e 's/^\(label\) install/\1 autoinst/'         \
										    -e 's/\(Install\)/Auto \1/'                    \
										    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"           \
										    -e "/menu label/a  ${INS_STR}"               | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg   \
										    -e 's/\(timeout\).*$/\1 50/'                   \
										> txt.cfg
									else
										sed -n '/label install/,/^$/p' isolinux/txt.cfg  | \
										sed -e 's/^\(label\) install/\1 autoinst/'         \
										    -e 's/\(Install\)/Auto \1/'                    \
										    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"           \
										    -e "/menu label/a  ${INS_STR}"                 \
										> txt.cfg
										cat isolinux/txt.cfg >> txt.cfg
									fi
									mv txt.cfg isolinux/
									;;
							esac
							# -------------------------------------------------
							chmod 444 "preseed/preseed.cfg"
							;;
						"ubuntu" )	# ･････････････････････････････････････････
							if [ -f isolinux/isolinux.cfg ]; then
								sed -i isolinux/isolinux.cfg     \
								    -e 's/\(timeout\).*$/\1 50/'
							fi
							if [ -f isolinux/prompt.cfg ]; then
								sed -i isolinux/prompt.cfg       \
								    -e 's/\(timeout\).*$/\1 50/'
							fi
							case "${CODE_NAME[1]}" in
#								*canary* | \
								*live*   | \
								*server* )
									case "${CODE_NAME[1]}" in
#										*canary* | \
										*live*   ) INS_CFG="fsck.mode=skip autoinstall \"ds=nocloud-net;s=file:\/\/\/cdrom\/nocloud\/\" ip=dhcp ipv6.disable=1";;
										*server* ) INS_CFG="file=\/cdrom\/preseed\/preseed.cfg auto=true"                                                      ;;
										* )	;;
									esac
									INS_CFG+=" debian-installer\/language=ja keyboard-configuration\/layoutcode\=jp keyboard-configuration\/modelcode\=jp106"
									# --- grub.cfg ----------------------------
									INS_ROW=$((`sed -n '/^menuentry \".*\(Install \)*Ubuntu\( Server\)*\"/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
									sed -n '/^menuentry \".*\(Install \)*Ubuntu\( Server\)*\"/,/^}/p' boot/grub/grub.cfg | \
									sed -n '0,/\}/p'                                                                     | \
									sed -e 's/\".*\(Install \)*\(Ubuntu.*\)\"/\"Auto Install \2\"/'                        \
									    -e 's/file.*seed//'                                                                \
									    -e "s/\(vmlinuz\) */\1 ${INS_CFG} /"                                               \
									    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/'                | \
									sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                                   | \
									sed -e '1i set timeout=5'                                                              \
									    -e 's/\(set default\)="1"/\1="0"/'                                                 \
									    -e 's/\(set timeout\).*$/\1=5/'                                                    \
									    -e 's/\(set gfxmode\)/# \1/g'                                                      \
									    -e 's/ vga=[0-9]*//g'                                                              \
									> grub.cfg
									mv grub.cfg boot/grub/
									# --- txt.cfg -----------------------------
									if [ -f isolinux/txt.cfg ]; then
										INS_ROW=$((`sed -n '/^label \(install\|live\)$/ =' isolinux/txt.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/label \(install\|live\)$/,/append/p' isolinux/txt.cfg | \
										sed -e 's/^\(label\).*/\1 autoinst/'                             \
										    -e 's/\(Install\)/Auto \1/'                                  \
										    -e 's/file.*seed//'                                          \
										    -e "s/\(append\) */\1 ${INS_CFG//\"/} /"                   | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg               | \
										sed -e 's/\(default\) .*/\1 autoinst/'                           \
										    -e 's/\(set gfxmode\)/# \1/g'                                \
										    -e 's/ vga=[0-9]*//g'                                        \
										> txt.cfg
										mv txt.cfg isolinux/
										# --- isolinux.cfg --------------------
										sed -i isolinux/isolinux.cfg         \
										    -e 's/\(timeout\) .*/\1 50/'     \
										    -e '/ui gfxboot bootlogo/d'
										# --- menu.cfg ------------------------
										sed -i isolinux/menu.cfg             \
										    -e '/menu hshift .*/d'           \
										    -e '/menu width .*/d'            \
										    -e '/menu margin .*/d'
										# --- stdmenu.cfg ---------------------
										sed -i isolinux/stdmenu.cfg          \
										    -e 's/\(menu vshift\) .*/\1 9/'  \
										    -e '/menu rows .*/d'             \
										    -e '/menu helpmsgrow .*/d'       \
										    -e '/menu cmdlinerow .*/d'       \
										    -e '/menu timeoutrow .*/d'       \
										    -e '/menu tabmsgrow .*/d'
										# --- splash.png ----------------------
										cp -p ../../../${WALL_FILE} isolinux/splash.png
										chmod 444 "isolinux/splash.png"
									fi
									;;
								*desktop* )					# --- preseed.cfg -
									# https://manpages.ubuntu.com/manpages/jammy/man7/casper.7.html
									# === 日本語化 ============================
									INS_CFG="debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
									# --- grub.cfg ----------------------------
									INS_ROW=$((`sed -n '/^menuentry/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
									sed -n '/^menuentry \"Try Ubuntu.*\"\|\"Ubuntu\"\|\"Try or Install Ubuntu\"/,/^}/p' boot/grub/grub.cfg | \
									sed -e 's/\"\(Try Ubuntu.*\)\"/\"\1 for Japanese language\"/'                                            \
									    -e 's/\"\(Ubuntu\)\"/\"\1 for Japanese language\"/'                                                  \
									    -e 's/\"\(Try or Install Ubuntu\)\"/\"\1 for Japanese language\"/'                                   \
									    -e 's/textonly\|\(automatic\|only\|maybe\)-ubiquity/noninteractive/'                               | \
									sed -e "s~\(file\)~${INS_CFG} \1~"                                                                     | \
									sed -e "s~\(layerfs-path\)~${INS_CFG} \1~"                                                             | \
									sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                                                     | \
									sed -e 's/\(set default\)="1"/\1="0"/'                                                                   \
									    -e 's/\(set timeout\).*$/\1=5/'                                                                      \
									> grub.cfg
									mv grub.cfg boot/grub/
									# --- txt.cfg -----------------------------
									if [ -f isolinux/txt.cfg ]; then
										INS_ROW=$((`sed -n '/^label/ =' isolinux/txt.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/label live$/,/append/p' isolinux/txt.cfg            | \
										sed -e 's/^\(label\) \(.*\)/\1 \2_for_japanese_language/'      \
										    -e 's/\^\(Try Ubuntu.*\)/\1 for \^Japanese language/'    | \
										sed -e "s~\(file\)~${INS_CFG} \1~"                           | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg             | \
										sed -e 's/^\(default\) .*$/\1 live_for_japanese_language/'     \
										> txt.cfg
										mv txt.cfg isolinux/
										# --- isolinux.cfg --------------------
										sed -i isolinux/isolinux.cfg         \
										    -e 's/\(timeout\) .*/\1 50/'     \
										    -e '/ui gfxboot bootlogo/d'
										# --- menu.cfg ------------------------
										sed -i isolinux/menu.cfg             \
										    -e '/menu hshift .*/d'           \
										    -e '/menu width .*/d'            \
										    -e '/menu margin .*/d'
										# --- stdmenu.cfg ---------------------
										sed -i isolinux/stdmenu.cfg          \
										    -e 's/\(menu vshift\) .*/\1 9/'  \
										    -e '/menu rows .*/d'             \
										    -e '/menu helpmsgrow .*/d'       \
										    -e '/menu cmdlinerow .*/d'       \
										    -e '/menu timeoutrow .*/d'       \
										    -e '/menu tabmsgrow .*/d'
										# --- splash.png ----------------------
										cp -p ../../../${WALL_FILE} isolinux/splash.png
										chmod 444 "isolinux/splash.png"
									fi
									if [ -f "nocloud/user-data" ]; then 
										INS_CFG="fsck.mode=skip autoinstall \"ds=nocloud-net;s=file:\/\/\/cdrom\/nocloud\/\" ip=dhcp ipv6.disable=1"
										INS_CFG+=" debian-installer\/locale=ja_JP.UTF-8 keyboard-configuration\/layoutcode\=jp keyboard-configuration\/modelcode\=jp106"
#										INS_CFG+=" timezone=Asia\/Tokyo"
#										INS_CFG+=" automatic-ubiquity noprompt"
#										INS_CFG+=" iso-url=http:\/\/cdimage.ubuntu.com\/daily-live\/current\/lunar-desktop-amd64\.iso"
									else
										INS_CFG="file=\/cdrom\/preseed\/preseed.cfg auto=true"
									fi
									# --- grub.cfg ----------------------------
									INS_ROW=$((`sed -n '/^menuentry "Try Ubuntu without installing"\|menuentry "Ubuntu"\|menuentry "Ubuntu (safe graphics)"/ =' boot/grub/grub.cfg | awk 'NR==1 {print}'`-1))
									sed -n '/^menuentry \"Install\|Ubuntu\"/,/^}/p' boot/grub/grub.cfg    | \
									sed -e 's/\"Install \(Ubuntu\)\"/\"Auto Install \1\"/'                  \
									    -e 's/\"\(Ubuntu\)\"/\"Auto Install \1\"/'                          \
									    -e 's/\"Try or Install \(Ubuntu\)\"/\"Auto Install \1\"/'           \
									    -e 's/file.*seed//'                                                 \
									    -e "s/\(vmlinuz\) */\1 ${INS_CFG} /"                                \
									    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
									sed -e "${INS_ROW}r /dev/stdin" boot/grub/grub.cfg                    | \
									sed -e 's/\(set default\)="1"/\1="0"/'                                  \
									    -e 's/\(set timeout\).*$/\1=5/'                                     \
									    -e 's/\(set gfxmode\)/# \1/g'                                       \
									    -e 's/ vga=[0-9]*//g'                                               \
									> grub.cfg
									mv grub.cfg boot/grub/
									# --- txt.cfg -----------------------------
									if [ -f isolinux/txt.cfg ]; then
										INS_ROW=$((`sed -n '/^label live$/ =' isolinux/txt.cfg | awk 'NR==1 {print}'`-1))
										sed -n '/label live-install$/,/append/p' isolinux/txt.cfg             | \
										sed -e 's/^\(label\).*/\1 autoinst/'                                    \
										    -e 's/\(Install\)/Auto \1/'                                         \
										    -e 's/file.*seed//'                                                 \
										    -e "s/\(append\) */\1 ${INS_CFG//\"/} /"                            \
										    -e 's/maybe-ubiquity\|only-ubiquity/automatic-ubiquity noprompt/' | \
										sed -e "${INS_ROW}r /dev/stdin" isolinux/txt.cfg                        \
										> txt.cfg
										mv txt.cfg isolinux/
									fi
									;;
								* )	;;
							esac
							# -------------------------------------------------
							if [ -f "nocloud/user-data"              ]; then chmod 444 "nocloud/user-data";              fi
							if [ -f "nocloud/meta-data"              ]; then chmod 444 "nocloud/meta-data";              fi
							if [ -f "nocloud/vendor-data"            ]; then chmod 444 "nocloud/vendor-data";            fi
							if [ -f "nocloud/network-config"         ]; then chmod 444 "nocloud/network-config";         fi
							if [ -f "preseed/preseed.cfg"            ]; then chmod 444 "preseed/preseed.cfg";            fi
#							if [ -f "preseed/sub_success_command.sh" ]; then chmod 544 "preseed/sub_success_command.sh"; fi
							;;
						"centos"       | \
						"fedora"       | \
						"rocky"        | \
						"miraclelinux" | \
						"almalinux"    )	# ･････････････････････････････････
							INS_CFG="inst.ks=cdrom:\/kickstart\/ks.cfg"
							# --- isolinux.cfg --------------------------------
							if [ -f isolinux/isolinux.cfg ]; then
								INS_ROW=$((`sed -n '/^label/ =' isolinux/isolinux.cfg | awk 'NR==1 {print}'`-1))
								INS_STR="\\`sed -n '/menu default/p' isolinux/isolinux.cfg`"
								sed -n '/label linux/,/^$/p' isolinux/isolinux.cfg    | \
								sed -e 's/^\(label\) linux/\1 autoinst/'                \
								    -e 's/\(Install\)/Auto \1/'                         \
								    -e "s/\(append.*\$\)/\1 ${INS_CFG}/"                \
								    -e "/menu label/a  ${INS_STR}"                    | \
								sed -e "${INS_ROW}r /dev/stdin" isolinux/isolinux.cfg   \
								    -e '/menu default/{/menu default/d}'                \
								    -e 's/\(timeout\).*$/\1 50/'                        \
								> isolinux.cfg
								mv isolinux.cfg isolinux/
							fi
							# --- grub.cfg ------------------------------------
							INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | awk 'NR==1 {print}'`-1))
							sed -n '/^menuentry '\''Install/,/^}/p' EFI/BOOT/grub.cfg | \
							sed -e 's/\(Install\)/Auto \1/'                             \
							    -e "s/\(linuxefi.*\$\)/\1 ${INS_CFG}/"                | \
							sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg         | \
							sed -e 's/\(set default\)="1"/\1="0"/'                      \
							    -e 's/\(set timeout\).*$/\1=5/'                         \
							> grub.cfg
							mv grub.cfg EFI/BOOT/
							# -------------------------------------------------
							chmod 444 "kickstart/ks.cfg"
							;;
						"suse" )	# ･････････････････････････････････････････
							INS_CFG="autoyast=cd:\/autoyast\/autoinst\.xml ifcfg=e*=dhcp"
							# --- isolinux.cfg --------------------------------
							sed -n '/#[ \t][ \t]*install/,/append/p' boot/x86_64/loader/isolinux.cfg | \
							sed -e 's/\(install\)/auto \1/'                                            \
							    -e 's/\(label\) linux/\1 autoinst/'                                    \
							    -e "/append/ s/\$/ ${INS_CFG}/"                                      | \
							sed -e '/^default.*$/r /dev/stdin' boot/x86_64/loader/isolinux.cfg       | \
							sed -e 's/^\(default\) harddisk$/\1=autoinst\n/'                           \
							    -e 's/\(timeout\).*$/\1 50/'                                           \
							> isolinux.cfg
							mv isolinux.cfg boot/x86_64/loader/
							# --- grub.cfg ------------------------------------
							case "${CODE_NAME[1]}" in
								*15.2* )
									sed -n '/menuentry[ \t][ \t]*'\''Installation'\''.*{/,/}/p' EFI/BOOT/grub.cfg             | \
									sed -e 's/^}/}\n/'                                                                          \
									    -e 's/'\''\(Installation\)'\''/'\''Auto \1'\''/'                                        \
									    -e "/linuxefi/ s/\$/ ${INS_CFG}/"                                                     | \
									sed -e '/\# look for an installed SUSE system and boot it/r /dev/stdin' EFI/BOOT/grub.cfg | \
									sed -e 's/^\(default\)=1$/\1=0/'                                                            \
									    -e 's/\(timeout\).*$/\1=5/'                                                             \
									> grub.cfg
									mv grub.cfg EFI/BOOT/
									;;
								* )
									INS_ROW=$((`sed -n '/^menuentry/ =' EFI/BOOT/grub.cfg | awk 'NR==1 {print}'`-1))
									sed -n '/menuentry[ \t][ \t]*'\''Installation'\''.*{/,/}/p' EFI/BOOT/grub.cfg             | \
									sed -e 's/^}/}\n/'                                                                          \
									    -e 's/'\''\(Installation\)'\''/'\''Auto \1'\''/'                                        \
									    -e "/linux/ s/\$/ ${INS_CFG}/"                                                        | \
									sed -e "${INS_ROW}r /dev/stdin" EFI/BOOT/grub.cfg                                         | \
									sed -e 's/^\(default\)=1$/\1=0/'                                                            \
									    -e 's/\(timeout\).*$/\1=5/'                                                             \
									> grub.cfg
									mv grub.cfg EFI/BOOT/
									;;
							esac
							# -------------------------------------------------
							chmod 444 "autoyast/autoinst.xml"
							;;
						* )	;;
					esac
					;;
			esac
			case "${WORK_DIRS}" in
				"live-custom" )
					# --- customize live disc [chroot] ------------------------
					fncPrint "    customize live disc"
					ISO_NAME="${DVD_NAME}-custom-preseed"
					case "${CODE_NAME[0]}" in
						"debian"       | \
						"ubuntu"       )					# ･････････････････
							pushd ../ > /dev/null			# 作業用ディレクトリー
								local HOSTNAME="live-${CODE_NAME[0]}"
								fncLive_custom "${HOSTNAME}"
								if [ ${FLG_SKIP} -eq 0 ]; then
									fncMake_setup_sh
									fncExec_setup_sh
								fi
							popd > /dev/null
							;;
						"centos"       | \
						"fedora"       | \
						"rocky"        | \
						"miraclelinux" | \
						"almalinux"    )					# ･････････････････
							;;
						"suse"         )					# ･････････････････
							;;
						*              ) ;;					# ･････････････････
					esac
					;;
				* ) ;;
			esac
			# --- create iso file ---------------------------------------------
			fncPrint "    create iso"
			case "${CODE_NAME[0]}" in
				"debian"       | \
				"ubuntu"       | \
				"centos"       | \
				"fedora"       | \
				"rocky"        | \
				"miraclelinux" | \
				"almalinux"    )	# ･････････････････････････････････････････
					rm -f md5sum.txt
					find . ! -name "md5sum.txt" ! -name "boot.catalog" ! -name "boot.cat" ! -name "isolinux.bin" ! -name "eltorito.img" ! -path "./isolinux/*" -type f -exec md5sum {} \; > md5sum.txt
					if [ -f isolinux.bin ]; then
						ELT_BOOT=isolinux.bin
						ELT_CATA=boot.cat
					elif [ -f isolinux/isolinux.bin ]; then
						ELT_BOOT=isolinux/isolinux.bin
						ELT_CATA=isolinux/boot.cat
					elif [ -f boot/grub/i386-pc/eltorito.img ]; then
						ELT_BOOT=boot/grub/i386-pc/eltorito.img
						ELT_CATA=boot.catalog
					elif [ -f images/eltorito.img ]; then
						ELT_BOOT=images/eltorito.img
						ELT_CATA=boot.catalog
					fi
					xorriso -as mkisofs \
					    -quiet \
					    -iso-level 3 \
					    -full-iso9660-filenames \
					    -volid "${VOLID}" \
					    -eltorito-boot "${ELT_BOOT}" \
					    -eltorito-catalog "${ELT_CATA}" \
					    -no-emul-boot -boot-load-size 4 -boot-info-table \
					    -isohybrid-mbr "${DIR_LINX}" \
					    -eltorito-alt-boot \
					    -e "${EFI_IMAG}" \
					    -no-emul-boot -isohybrid-gpt-basdat \
					    -output "../../${ISO_NAME}.iso" \
					    . > /dev/null 2>&1
					;;
				"suse" )	# ･････････････････････････････････････････････････
#					find boot EFI docu media.1 -type f -exec sha256sum {} \; > CHECKSUMS
					xorriso -as mkisofs \
					    -quiet \
					    -iso-level 3 \
					    -full-iso9660-filenames \
					    -volid "${VOLID}" \
					    -eltorito-boot boot/x86_64/loader/isolinux.bin \
					    -no-emul-boot -boot-load-size 4 -boot-info-table \
					    -isohybrid-mbr "${DIR_LINX}" \
					    -eltorito-alt-boot \
					    -e boot/x86_64/efi \
					    -no-emul-boot -isohybrid-gpt-basdat \
					    -output "../../${ISO_NAME}.iso" \
					    . > /dev/null 2>&1
					;;
				* )	;;
			esac
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" != "" ]; then
				LANG=C implantisomd5 "../../${ISO_NAME}.iso" > /dev/null
			fi
		popd > /dev/null
	popd > /dev/null
	rm -rf   ${WORK_DIRS}/${CODE_NAME[1]}
	fncPrint "=== ↑処理済：${CODE_NAME[0]}：${CODE_NAME[1]} $(fncString ${COL_SIZE} '=')"
	return 0
}
# which command ---------------------------------------------------------------
	if [ "`command -v which 2> /dev/null`" != "" ]; then
		CMD_WICH="command -v"
	else
		CMD_WICH="which"
	fi
# terminal size ---------------------------------------------------------------
	ROW_SIZE=25
	COL_SIZE=80
	if [ "`${CMD_WICH} tput 2> /dev/null`" != "" ]; then
		ROW_SIZE=`tput lines`
		COL_SIZE=`tput cols`
	fi
	if [ ${COL_SIZE} -lt 80 ]; then
		COL_SIZE=80
	fi
	if [ ${COL_SIZE} -gt 100 ]; then
		COL_SIZE=100
	fi
# -----------------------------------------------------------------------------
	funcOption $@
	# -------------------------------------------------------------------------
	WHO_AMI=`whoami`					# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_LOGOUT} -ne 0 ]; then
		exec &> >(tee "./${WORK_DIRS}.log")
	fi
# -----------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` 作成処理を開始します。"
	fncPrint "$(fncString ${COL_SIZE} '*')"
# cpu type --------------------------------------------------------------------
	CPU_TYPE=`LANG=C lscpu | awk '/Architecture:/ {print $2;}'`					# CPU TYPE (x86_64/armv5tel/...)
# system info -----------------------------------------------------------------
	SYS_NAME=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
	SYS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
	SYS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
	SYS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
	SYS_VNUM=`echo ${SYS_VRID:--1} | bc`										#   〃          (取得できない場合は-1)
	SYS_NOOP=0																	# 対象OS=1,それ以外=0
	if [ "${SYS_CODE}" = "" -o ${SYS_VNUM} -lt 0 ]; then
		if [ -f /etc/lsb-release ]; then
			SYS_CODE=`awk -F '=' '$1=="DISTRIB_CODENAME" {gsub("\"",""); print $2;}' /etc/lsb-release`	# コード名
		else
			case "${SYS_NAME}" in
				"debian"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`       ;;
				"ubuntu"              ) SYS_CODE=`awk -F '/'             '{gsub("\"",""); print $2;}' /etc/debian_version`       ;;
				"centos"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/centos-release`       ;;
				"fedora"              ) SYS_CODE=`awk                    '{gsub("\"",""); print $3;}' /etc/fedora-release`       ;;
				"rocky"               ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/rocky-release`        ;;
				"miraclelinux"        ) SYS_CODE=`awk                    '{gsub("\"",""); print $4;}' /etc/miraclelinux-release` ;;
				"almalinux"           ) SYS_CODE=`awk                    '{gsub("\"",""); print $3;}' /etc/redhat-release`       ;;
				"opensuse-leap"       ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`           ;;
				"opensuse-tumbleweed" ) SYS_CODE=`awk -F '[=-]' '$1=="ID" {gsub("\"",""); print $3;}' /etc/os-release`           ;;
				*                     )                                                                                          ;;
			esac
		fi
	fi
	if [ "${SYS_NAME}" = "debian" ] && [ "${SYS_CODE}" = "sid" ]; then
		SYS_NOOP=1
	else
		if [ "${CPU_TYPE}" = "x86_64" ]; then
			case "${SYS_NAME}" in
				"debian"              ) SYS_NOOP=`echo "${SYS_VNUM} >=  9"       | bc`;;
				"ubuntu"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 18.04"    | bc`;;
				"centos"              ) SYS_NOOP=`echo "${SYS_VNUM} >=  8"       | bc`;;
				"fedora"              ) SYS_NOOP=`echo "${SYS_VNUM} >= 32"       | bc`;;
				"rocky"               ) SYS_NOOP=`echo "${SYS_VNUM} >=  8.4"     | bc`;;
				"miraclelinux"        ) SYS_NOOP=`echo "${SYS_VNUM} >=  8"       | bc`;;
				"almalinux"           ) SYS_NOOP=`echo "${SYS_VNUM} >=  9"       | bc`;;
				"opensuse-leap"       ) SYS_NOOP=`echo "${SYS_VNUM} >= 15.2"     | bc`;;
				"opensuse-tumbleweed" ) SYS_NOOP=`echo "${SYS_VNUM} >= 20201002" | bc`;;
				*                     )                                               ;;
			esac
		fi
	fi
	if [ ${SYS_NOOP} -eq 0 ]; then
		echo "${SYS_NAME} ${SYS_VERS:-${SYS_CODE}} (${CPU_TYPE}) ではテストをしていないので実行できません。"
		exit 1
	fi
# -----------------------------------------------------------------------------
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			CMD_AGET="apt-get -y -qq"
			DIR_LINX="/usr/lib/ISOLINUX/isohdpfx.bin"
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`${CMD_WICH} dnf 2> /dev/null`" != "" ]; then
				CMD_AGET="dnf -y -q --allowerasing"
			else
				CMD_AGET="yum -y -q"
			fi
			DIR_LINX="/usr/share/syslinux/isohdpfx.bin"
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			CMD_AGET="zypper -n -t"
			DIR_LINX="/usr/share/syslinux/isohdpfx.bin"
			;;
		* )
			;;
	esac
# -----------------------------------------------------------------------------
	LST_PACK=""
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			if [ "`${CMD_WICH} curl 2> /dev/null`" = "" ]; then
				LST_PACK+="curl "
			fi
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
				LST_PACK+="xorriso "
			fi
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" ]; then
				LST_PACK+="isomd5sum "
			fi
			if [ ! -f "${DIR_LINX}" ]; then
				LST_PACK+="isolinux "
			fi
			if [ "`which mksquashfs 2> /dev/null`" = "" ]; then
				LST_PACK+="squashfs-tools "
			fi
			;;
		"centos" | \
		"fedora" | \
		"rocky"  )
			if [ "`${CMD_WICH} curl 2> /dev/null`" = "" ]; then
				LST_PACK+="curl "
			fi
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
				LST_PACK+="xorriso "
			fi
			if [ "`${CMD_WICH} implantisomd5 2> /dev/null`" = "" ]; then
				LST_PACK+="isomd5sum "
			fi
			if [ ! -f "${DIR_LINX}" ]; then
				LST_PACK+="syslinux "
			fi
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			if [ "`${CMD_WICH} curl 2> /dev/null`" = "" ]; then
				LST_PACK+="curl "
			fi
			if [ "`${CMD_WICH} xorriso 2> /dev/null`" = "" ]; then
				LST_PACK+="xorriso "
			fi
			if [ ! -f "${DIR_LINX}" ]; then
				LST_PACK+="isolinux "
			fi
			ARRAY_WORK=("${ARRAY_NAME[@]}")
			for ((I=1; I<=${#ARRAY_NAME[@]}; I++))
			do
				ARRY_NAME=(${ARRAY_WORK[$I-1]})
				if [ "${ARRY_NAME[0]}" != "suse" ]; then
					unset ARRAY_WORK[$I-1]
				fi
			done
			ARRAY_NAME=("${ARRAY_WORK[@]}")
			;;
		* )
			;;
	esac
	if [ "${LST_PACK}" != "" ]; then
		${CMD_AGET} update
		${CMD_AGET} install ${LST_PACK}
	fi
# -----------------------------------------------------------------------------
	fncMenu
	# -------------------------------------------------------------------------
	for I in `eval echo "${INP_INDX}"`						# 連番可
	do
		if [ `fncIsInt "$I"` -eq 0 ] && [ $I -ge 1 ] && [ $I -le ${#ARRAY_NAME[@]} ]; then
			case "${WORK_DIRS}" in
				"dist_remaster_mini" )	fncRemaster "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"dist_remaster_net"  )	fncRemaster "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"dist_remaster_dvd"  )	fncRemaster "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				"live-custom"        )	fncRemaster "${ARRAY_NAME[$I-1]}"; RET_CD=$?;;
				*                    )	                                   RET_CD=0 ;;
			esac
			if [ ${RET_CD} != 0 ]; then
				while true
				do
					popd > /dev/null 2>&1
					if [ $? != 0 ]; then
						break
					fi
				done
				printf "    ${TXT_RED}${TXT_REV}エラー${TXT_REVRST}により処理をスキップしました。 [${RET_CD}]${TXT_RESET}\n"
			fi
		fi
	done
	# -------------------------------------------------------------------------
	set +e
	ls -lthLgG --time-style="+%Y/%m/%d %H:%M:%S" "${WORK_DIRS}/"*iso 2> /dev/null | \
	    grep -e ".*-*\(custom\)*-\(autoyast\|kickstart\|nocloud\|preseed\).iso"   | \
	    cut -c 13-
	set -e
# -----------------------------------------------------------------------------
	fncPrint "$(fncString ${COL_SIZE} '*')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` 作成処理が終了しました。"
	fncPrint "$(fncString ${COL_SIZE} '*')"
# -----------------------------------------------------------------------------
	exit 0
# = eof =======================================================================
# <memo>
# -----------------------------------------------------------------------------
# vga：解像度    ：色数
# 771： 800× 600：256色
# 773：1024× 768：256色
# 775：1280×1024：256色
# 788： 800× 600：6万5000色
# 791：1024× 768：6万5000色
# 794：1280×1024：6万5000色
# 789： 800× 600：1600万色
# 792：1024× 768：1600万色
# 795：1280×1024：1600万色
# ---  https://ja.wikipedia.org/wiki/Debian -----------------------------------
# Ver. :コードネーム     :リリース日:サポート期限
#x  1.1:buzz             :1996-06-17:
#x  1.2:rex              :1996-12-12:
#x  1.3:bo               :1997-06-02:
#x  2.0:hamm             :1998-07-24:
#x  2.1:slink            :1999-03-09:
#x  2.2:potato           :2000-08-15:
#x  3.0:woody            :2002-07-19:2006-06-30
#x  3.1:sarge            :2005-06-06:2008-03-31
#x  4.0:etch             :2007-04-08:2010-02-15
#x  5.0:lenny            :2009-02-14:2012-02-06
#x  6.0:squeeze          :2011-02-06:2014-05-31/2016-02-29[LTS]
#x  7.0:wheezy           :2013-05-04:2016-04-25/2018-05-31[LTS]
#x  8.0:jessie           :2015-04-25:2018-06-17/2020-06-30[LTS]
#   9.0:stretch          :2017-06-17:2020-07-06/2022-06-30[LTS]:oldoldstable
#  10.0:buster           :2019-07-06:2022-06-xx/2024-06-xx[LTS]:oldstable
#  11.0:bullseye         :2021-08-14:2024-xx-xx/2026-xx-xx[LTS]:stable
#  12.0:bookworm         :          :                           testing
#  13.0:Trixie           :          :                           
#  14.0:Forky            :          :                           
# --- https://en.wikipedia.org/wiki/Ubuntu_version_history --------------------
# [https://wiki.ubuntu.com/FocalFossa/ReleaseNotes/Ja]
# Ver. :コードネーム     :リリース日:サポート期限
#x 4.10:Warty Warthog    :2004-10-20:2006-04-30
#x 5.04:Hoary Hedgehog   :2005-04-08:2006-10-31
#x 5.10:Breezy Badger    :2005-10-13:2007-04-13
#x 6.06:Dapper Drake     :2006-06-01:2011-06-01(Server)   :LTS
#x 6.10:Edgy Eft         :2006-10-26:2008-04-25
#x 7.04:Feisty Fawn      :2007-04-19:2008-10-19
#x 7.10:Gutsy Gibbon     :2007-10-18:2009-04-18
#x 8.04:Hardy Heron      :2008-04-24:2013-05-09(Server)   :LTS
#x 8.10:Intrepid Ibex    :2008-10-30:2010-04-30
#x 9.04:Jaunty Jackalope :2009-04-23:2010-10-23
#x 9.10:Karmic Koala     :2009-10-29:2011-04-30
#x10.04:Lucid Lynx       :2010-04-29:2015-04-30(Server)   :LTS
#x10.10:Maverick Meerkat :2010-10-10:2012-04-10
#x11.04:Natty Narwhal    :2011-04-28:2012-10-28
#x11.10:Oneiric Ocelot   :2011-10-13:2013-05-09
#x12.04:Precise Pangolin :2012-04-26:2017-04-28/2019-04-26:LTS
#x12.10:Quantal Quetzal  :2012-10-18:2014-05-16
#x13.04:Raring Ringtail  :2013-04-25:2014-01-27
#x13.10:Saucy Salamander :2013-10-17:2014-07-17
#x14.04:Trusty Tahr      :2014-04-17:2019-04-25/2024-04-25:LTS
#x14.10:Utopic Unicorn   :2014-10-23:2015-07-23
#x15.04:Vivid Vervet     :2015-04-23:2016-02-04
#x15.10:Wily Werewolf    :2015-10-22:2016-07-28
#x16.04:Xenial Xerus     :2016-04-21:2021-04-30/2026-04-23:LTS
#x16.10:Yakkety Yak      :2016-10-13:2017-07-20
#x17.04:Zesty Zapus      :2017-04-13:2018-01-13
#x17.10:Artful Aardvark  :2017-10-19:2018-07-19
# 18.04:Bionic Beaver    :2018-04-26:2023-04-26/2028-04-26:LTS
#x18.10:Cosmic Cuttlefish:2018-10-18:2019-07-18
#x19.04:Disco Dingo      :2019-04-18:2020-01-23
#x19.10:Eoan Ermine      :2019-10-17:2020-07-17
# 20.04:Focal Fossa      :2020-04-23:2025-04-23/2030-04-23:LTS
#x20.10:Groovy Gorilla   :2020-10-22:2021-07-22
#x21.04:Hirsute Hippo    :2021-04-22:2022-01-20
# 21.10:Impish Indri     :2021-10-14:2022-07-14
# 22.04:Jammy Jellyfish  :2022-04-21:2027-04-21/2032-04-21:LTS
# 22.10:Kinetic Kudu     :2022-10-20:2023-07-xx
# 23.04:Lunar Lobster    :2023-04-20:2024-01-20
# --- https://ja.wikipedia.org/wiki/CentOS ------------------------------------
# [https://en.wikipedia.org/wiki/CentOS]
# Ver.    :リリース日:RHEL      :メンテ期限:kernel
# 7.4-1708:2017-09-14:2017-08-01:2024-06-30: 3.10.0- 693
# 7.5-1804:2018-05-10:2018-04-10:2024-06-30: 3.10.0- 862
# 7.6-1810:2018-12-03:2018-10-30:2024-06-30: 3.10.0- 957
# 7.7-1908:2019-09-17:2019-08-06:2024-06-30: 3.10.0-1062
# 7.8-2003:2020-04-27:2020-03-30:2024-06-30: 3.10.0-1127
#x8.0-1905:2019-09-24:2019-05-07:2021-12-31: 4.18.0- 80
#x8.1-1911:2020-01-15:2019-11-05:2021-12-31: 4.18.0-147
#x8.2.2004:2020-06-15:2020-04-28:2021-12-31: 4.18.0-193
#x8.3.2011:2020-11-03:2020-12-07:2021-12-31: 4.18.0-240
#x8.4.2015:2021-06-03:2021-05-18:2021-12-31: 4.18.0-305
#x8.5.2111:2021-11-16:2021-11-09:2021-12-31: 4.18.0-348
# --- https://ja.wikipedia.org/wiki/Rocky_Linux -------------------------------
# [https://en.wikipedia.org/wiki/Rocky_Linux]
# Ver. :リリース日:RHEL      :メンテ期限:kernel
#  8.4 :2021-06-21:2021-05-18:          : 4.18.0-305
#  8.5 :2021-11-15:2021-11-09:          : 4.18.0-348
#  8.6 :2022-05-16:2022-05-10:2029-05-31: 4.18.0-372.9.1
#  8.7 :2022-11-14:2022-11-09:          : 4.18.0-425.3.1
#  9.0 :2022-07-14:2022-05-17:          : 5.14.0-70.13.1
#  9.1 :2022-11-xx:2022-11-15:          : 5.14.0-162.6.1
# --- https://ja.wikipedia.org/wiki/Fedora ------------------------------------
# [https://en.wikipedia.org/wiki/Fedora_Linux]
# Ver. :コードネーム     :リリース日:サポ期限  :kernel
#x27   :                 :2017-11-14:2018-11-27: 4.13
#x28   :                 :2018-05-01:2019-05-29: 4.16
#x29   :                 :2018-10-30:2019-11-26: 4.18
#x30   :                 :2019-04-29:2020-05-26: 5.0
#x31   :                 :2019-10-29:2020-11-24: 5.3
#x32   :                 :2020-04-28:2021-05-25: 5.6
# 33   :                 :2020-10-27:2021-11-30: 5.8
# 34   :                 :2021-04-27:2022-05-17: 5.11
# 35   :                 :2021-11-02:2022-12-13: 5.14
# 36   :                 :2022-05-10:2023-05-16: 5.17
# 37   :                 :2022-11-15:2023-11-14: 6.0
# 38   :                 :2023-04-18:2024-05-14:
# --- https://ja.wikipedia.org/wiki/OpenSUSE ----------------------------------
# [https://en.wikipedia.org/wiki/OpenSUSE]
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 15.2 :openSUSE Leap      :2020-07-02:2021-12-31: 5.3.18
# 15.3 :openSUSE Leap      :2021-06-02:2022-11-30: 5.3.18
# 15.4 :openSUSE Leap      :2022-06-02:2023-xx-xx: 5.14.21
# 15.5 :openSUSE Leap      :2023-xx-xx:2024-xx-xx: x.xx.xx
# xx.x :openSUSE Tumbleweed:20xx-xx-xx:20xx-xx-xx:
# --- https://ja.wikipedia.org/wiki/MIRACLE_LINUX -----------------------------
# [https://en.wikipedia.org/wiki/Miracle_Linux]
# Ver. :コードネーム       :リリース日:サポ期限  :kernel
# 8.4  :Peony              :2021-10-04:          :4.18.0-305.el8
# -----------------------------------------------------------------------------
