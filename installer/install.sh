#!/bin/bash
###############################################################################
##
##	ファイル名	:	install.sh
##
##	機能概要	:	Debian & Ubuntu Install用シェル [VMware対応]
##
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2014/11/02
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- ----------------------------------------
##	2014/11/02 000.0000 J.Itou         新規作成
##	2018/02/28 000.0000 J.Itou         IPV6対応等
##	2018/03/07 000.0000 J.Itou         cron用シェル修正
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#set -nvx

# Pause処理 -------------------------------------------------------------------
funcPause() {
	RET_STS=$1

	if [ ${RET_STS} -ne 0 ]; then
		echo "Enterキーを押して下さい。"
		read DUMMY
	fi
}

# プロセス制御処理 ------------------------------------------------------------
funcProc() {
	INP_NAME=$1
	INP_COMD=$2

	case "${INP_COMD}" in
		"start" )
			which insserv
			if [ $? -eq 0 ]; then
				insserv -d ${INP_NAME}; funcPause $?
			else
				systemctl enable ${INP_NAME}; funcPause $?
			fi
			/etc/init.d/${INP_NAME} start
			;;
		"stop" )
			/etc/init.d/${INP_NAME} stop
			which insserv
			if [ $? -eq 0 ]; then
				insserv -r ${INP_NAME}; funcPause $?
			else
				systemctl disable ${INP_NAME}; funcPause $?
			fi
			;;
		* )
			/etc/init.d/${INP_NAME} ${INP_COMD}
#			systemctl ${INP_COMD} ${INP_NAME}
			funcPause $?
			;;
	esac
}

# IPV6補間処理 ----------------------------------------------------------------
fncIPV6Conv () {
	declare -a OUT_ARRY
	INP_ADDR=$1
	STR_FSEP=${INP_ADDR//[^:]}
	CNT_FSEP=$((7-${#STR_FSEP}))
	(($CNT_FSEP)) && INP_ADDR=${INP_ADDR/::/"$(eval printf ':%.s' {1..$((CNT_FSEP+2))})"}
	OLDIFS=${IFS}
	IFS=':'
	OUT_ARRY=(${INP_ADDR/%:/::})
	IFS=${OLDIFS}
	OUT_ADDR=$(printf ':%04x' "${OUT_ARRY[@]/#/0x0}")
	echo ${OUT_ADDR:1}
}

#------------------------------------------------------------------------------
# Initialize
#------------------------------------------------------------------------------
	NOW_DATE=`date +"%Y/%m/%d"`
	NOW_TIME=`date +"%Y%m%d%H%M%S"`
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`
	DBG_FLAG=${DBG_FLAG:-0}
	if [ ${DBG_FLAG} -ne 0 ]; then
		set -vx
	fi

	WHO_AMI=`whoami`
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーでログインして実行して下さい。"
		exit 1
	fi

#	WHO_USER=`who | awk '$1!="root" {print $1;}'`
#	if [ "${WHO_USER}" != "" ]; then
#		echo "${WHO_USER}がログインしています。"
#		echo "全てのユーザーをログアウトしてから、"
#		echo "rootユーザーでログインして実行して下さい。"
#		exit 1
#	fi

	# ユーザー環境に合わせて変更する部分 --------------------------------------
	SVR_NAME=`hostname`															# 本機の名前
	WGP_NAME=`hostname -d`														# ワークグループ名
#	GWR_NAME=gw-router															# ゲートウェイの名前
#	DEF_USER=`ls /home/`														# インストール時に作成したユーザー名
#	NUM_HDDS=1																	# インストール先のHDD台数
	FLG_DHCP=0																	# DHCP自動起動フラグ(0以外で自動起動)
#	FLG_VMTL=0																	# 0以外でVMware Toolsをインストール
#	FLG_SVER=1																	# 0以外でサーバー仕様でセッティング
#	VER_WMIN=1.870																# webminの最新バージョンを登録
#	VGA_RESO=1024x768x32														# コンソールの解像度：1024×768：1600万色
	VGA_RESO=1280x1024x32														#   〃              ：1280×1024：1600万色
#	VGA_RESO=800x600x32															#   〃              ： 800× 600：1600万色
	SMB_USER=sambauser															# smb.confのforce user
	SMB_GRUP=sambashare															# smb.confのforce group
	SMB_GADM=sambaadmin															# smb.confのadmin group
	CPU_TYPE=`uname -r | awk -F - '{print $3;}'`								# CPU TYPE (amd64/iop32x/...)

	# プライベートIPアドレス --------------------------------------------------
	# クラス  | 使用できるIPアドレス範囲       | 使用できるサブネットマスク範囲
	# クラスA | 10.0.0.0 ～ 10.255.255.255     | 255.0.0.0 ～ 255.255.255.255（最大16,777,214台接続が可能）
	# クラスB | 172.16.0.0 ～ 172.31.255.255   | 255.255.0.0 ～ 255.255.255.255（最大65,534台接続が可能）
	# クラスC | 192.168.0.0 ～ 192.168.255.255 | 255.255.255.0 ～ 255.255.255.255（最大254台接続が可能）
	#
	#  8 | 11111111.00000000.00000000.00000000 | 255.0.0.0
	# 16 | 11111111.11111111.00000000.00000000 | 255.255.0.0
	# 24 | 11111111.11111111.11111111.00000000 | 255.255.255.0

	# NICデバイス名 -----------------------------------------------------------
	NWK_NAME=`awk '$4=="static" {print $2;}' /etc/network/interfaces`
	NIC_NAME=`ip a show | awk -F "[ :]" '$1=="2" {print $3;}'`

	# IPV4 --------------------------------------------------------------------
	NIC_INET=`ip -4 a show dev ${NIC_NAME} | awk '$6=="global" {print $2;}'`	# IPアドレス/サブネットマスク(bit)
	NIC_BCST=`ip -4 a show dev ${NIC_NAME} | awk '$6=="global" {print $4;}'`	# ブロードキャストアドレス
	NIC_ADDR=`echo ${NIC_INET} | awk -F / '{print $1;}'`						# IPアドレス
	NIC_BITS=`echo ${NIC_INET} | awk -F / '{print $2;}'`						# サブネットマスク(bit)
	NIC_IPAD=`echo ${NIC_ADDR} | awk -F . '{printf"%s.%s.%s", $1,$2,$3;}'`		# 本機の属するプライベート・アドレス

	NIC_NTWK=`route -n | awk '$2=="0.0.0.0" && !/169.254./ {print $1;}'`		# ネットワークアドレス
	NIC_MASK=`route -n | awk '$2=="0.0.0.0" && !/169.254./ {print $3;}'`		# サブネットマスク
	NIC_GATE=`route -n | awk '$1=="0.0.0.0" {print $2;}'`						# デフォルトゲートウェイ
#	NIC_DADR=`awk '$1=="nameserver" {print $2;}' /etc/resolv.conf`				# DNS サーバのアドレス
#	NIC_DNAM=`awk '$1=="search" {print $2;}' /etc/resolv.conf`					# DNS 検索で優先するドメインサフィックス

	REV_IPAD=`echo ${NIC_ADDR} | awk -F . '{printf"%s.%s.%s", $3,$2,$1;}'`		# BIND用
	SVR_ADDR=`echo ${NIC_ADDR} | awk -F . '{print $4;}'`						# 本機のIPアドレス
	GWR_ADDR=`echo ${NIC_GATE} | awk -F . '{print $4;}'`						# ゲートウェイのIPアドレス

	ADR_DHCP="${NIC_IPAD}.64 ${NIC_IPAD}.79"									# DHCPの提供アドレス範囲

	# IPV6 グローバル ---------------------------------------------------------
																				# IPv6アドレス/サブネットマスク(bit)
	IP6_INET=`ip -6 a show dev ${NIC_NAME} | awk '/inet6/ && !/fe80::/ {print $2;}'`
	IP6_ADDR=`echo ${IP6_INET} | awk -F / '{print $1;}'`						# IPv6アドレス
	IP6_MASK=`echo ${IP6_INET} | awk -F / '{print $2;}'`						#  〃 サブネットマスク(bit)
																				# 本機の属するIPv6アドレス
	IP6_IPAD=`ip -6 r show dev ${NIC_NAME} | awk -F / '!/default/ && !/fe80::/ {print $1;}'`
																				# BIND用
	IP6_CONV=`fncIPV6Conv "${IP6_ADDR}"`
	IP6_ADUP=`echo ${IP6_CONV} | awk -F : '{print $1 $2 $3 $4;}'`
	IP6_ADLO=`echo ${IP6_CONV} | awk -F : '{print $5 $6 $7 $8;}'`
	REV_IPV6=`echo ${IP6_ADUP} | awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1)); printf("%c", substr($0,1,1));}'`
	SVR_IPV6=`echo ${IP6_ADLO} | awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1)); printf("%c", substr($0,1,1));}'`
	# IPV6 リンクローカル -----------------------------------------------------
																				# IPv6アドレス/サブネットマスク(bit)
	LNK_INET=`ip -6 a show dev ${NIC_NAME} | awk '/inet6/ &&  /fe80::/ {print $2;}'`
	LNK_ADDR=`echo ${LNK_INET} | awk -F / '{print $1;}'`						# IPv6アドレス
	LNK_MASK=`echo ${LNK_INET} | awk -F / '{print $2;}'`						#  〃 サブネットマスク(bit)
																				# 本機の属するIPv6アドレス
	LNK_IPAD=`ip -6 r show dev ${NIC_NAME} | awk -F / '!/default/ &&  /fe80::/ {print $1;}'`
																				# BIND用
	LNK_CONV=`fncIPV6Conv "${LNK_ADDR}"`
	LNK_ADUP=`echo ${LNK_CONV} | awk -F : '{print $1 $2 $3 $4;}'`
	LNK_ADLO=`echo ${LNK_CONV} | awk -F : '{print $5 $6 $7 $8;}'`
	REV_LNK6=`echo ${LNK_ADUP} | awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1)); printf("%c", substr($0,1,1));}'`
	SVR_LNK6=`echo ${LNK_ADLO} | awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1)); printf("%c", substr($0,1,1));}'`

	# ワーク変数設定 ----------------------------------------------------------
	DST_NAME=`awk '/[A-Za-z]./ {print $1;}' /etc/issue | head -n 1 | tr '[A-Z]' '[a-z]'`

#	MNT_FD=/media/floppy0
#	MNT_CD=/media/cdrom0
	MNT_CD=/media
	DEV_CD=/dev/sr0

	DIR_WK=/work
	LST_USER=${DIR_WK}/addusers.txt
#	LOG_FILE=${DIR_WK}/${PGM_NAME}.sh.${NOW_TIME}.log
	TGZ_WORK=${DIR_WK}/${PGM_NAME}.sh.tgz
	CRN_FILE=${DIR_WK}/${PGM_NAME}.sh.crn
	USR_FILE=${DIR_WK}/${PGM_NAME}.sh.usr.list
	SMB_FILE=${DIR_WK}/${PGM_NAME}.sh.smb.list
	SMB_WORK=${DIR_WK}/${PGM_NAME}.sh.smb.work
	SMB_CONF=/etc/samba/smb.conf
	SMB_BACK=${SMB_CONF}.orig

	if [ "${SVR_NAME}" = "" ]; then
		if [ ${FLG_SVER} -ne 0 ]; then
			SVR_NAME=sv-${DST_NAME}
		else
			SVR_NAME=ws-${DST_NAME}
		fi
	fi

	if [ "`lscpu | grep -i vmware`" = "" ]; then
		FLG_VMTL=0																# 0以外でVMware Toolsをインストール
	else
		FLG_VMTL=1																# 0以外でVMware Toolsをインストール
	fi

	if [ "${VER_WMIN}" = "" ]; then
		SET_WMIN="webmin-current.deb"
	else
		SET_WMIN="webmin_${VER_WMIN}_all.deb"
	fi

	DEV_NUM1=sda
	DEV_NUM2=sdb
	DEV_NUM3=sdc
	DEV_NUM4=sdd
	DEV_NUM5=sde
	DEV_NUM6=sdf
	DEV_NUM7=sdg
	DEV_NUM8=sdh

	NUM_HDDS=`ls -l /dev/[hs]d[a-z] | wc -l`									# インストール先のHDD台数

	case "${NUM_HDDS}" in
		# HDD 1台 -------------------------------------------------------------
		1 )	DEV_HDD1=/dev/${DEV_NUM1}
			DEV_HDD2=
			DEV_HDD3=
			DEV_HDD4=

			DEV_USB1=/dev/${DEV_NUM2}
			DEV_USB2=/dev/${DEV_NUM3}
			DEV_USB3=/dev/${DEV_NUM4}
			DEV_USB4=/dev/${DEV_NUM5}
			;;
		# HDD 2台 -------------------------------------------------------------
		2 )	DEV_HDD1=/dev/${DEV_NUM1}
			DEV_HDD2=/dev/${DEV_NUM2}
			DEV_HDD3=
			DEV_HDD4=

			DEV_USB1=/dev/${DEV_NUM3}
			DEV_USB2=/dev/${DEV_NUM4}
			DEV_USB3=/dev/${DEV_NUM5}
			DEV_USB4=/dev/${DEV_NUM6}
			;;
		# HDD 4台 ~ -----------------------------------------------------------
		* )	DEV_HDD1=/dev/${DEV_NUM1}
			DEV_HDD2=/dev/${DEV_NUM2}
			DEV_HDD3=/dev/${DEV_NUM3}
			DEV_HDD4=/dev/${DEV_NUM4}

			DEV_USB1=/dev/${DEV_NUM5}
			DEV_USB2=/dev/${DEV_NUM6}
			DEV_USB3=/dev/${DEV_NUM7}
			DEV_USB4=/dev/${DEV_NUM8}
			;;
	esac

	DEV_RATE="${DEV_USB1} ${DEV_USB2} ${DEV_USB3} ${DEV_USB4}"
	DEV_TEMP="${DEV_HDD1} ${DEV_HDD2} ${DEV_HDD3} ${DEV_HDD4} ${DEV_RATE}"

	CMD_AGET="apt-get -y -q"

	# 事前ダウンロード --------------------------------------------------------
	while :
	do
		if [ -f "${DIR_WK}/${SET_WMIN}" ]; then
			break
		fi

		if [ "${SET_WMIN}" = "webmin-current.deb" ]; then
			wget "http://www.webmin.com/download/deb/webmin-current.deb"
		else
			wget "https://jaist.dl.sourceforge.net/project/webadmin/webmin/${VER_WMIN}/webmin_${VER_WMIN}_all.deb"
		fi
		sleep 1s
	done

#------------------------------------------------------------------------------
# Make work dir
#------------------------------------------------------------------------------
	mkdir -p ${DIR_WK}
	chmod 700 ${DIR_WK}
	pushd ${DIR_WK}

#------------------------------------------------------------------------------
# System Update
#------------------------------------------------------------------------------
	${CMD_AGET} update
	${CMD_AGET} upgrade
	${CMD_AGET} dist-upgrade

#------------------------------------------------------------------------------
# UDEV Rules
#------------------------------------------------------------------------------
#	if [ ! -f /etc/udev/rules.d/11-media-auto-mount.rules ]; then
#		cat <<- _EOT_ > /etc/udev/rules.d/11-media-auto-mount.rules
#			KERNEL!="sd[b-z][0-9]", GOTO="media_auto_mount_end"
#			ACTION=="add", RUN+="/bin/mkdir -p /media/usb-%k"
#
#			# Global mount options
#			ACTION=="add", ENV{mount_options}="relatime,users"
#			# Filesystem specific options
#			ACTION=="add", PROGRAM=="/lib/initcpio/udev/vol_id -t %N", RESULT=="vfat|ntfs", ENV{mount_options}="$env{mount_options},utf8,gid=100,umask=002"
#
#			ACTION=="add", RUN+="/bin/mount -o $env{mount_options} /dev/%k /media/usb-%k"
#			ACTION=="remove", RUN+="/bin/umount -l /media/usb-%k", RUN+="/bin/rmdir /media/usb-%k"
#			LABEL="media_auto_mount_end"
#_EOT_
#	fi
#
#	udevadm control --reload
#	udevadm trigger
#
#------------------------------------------------------------------------------
# Locale Setup
#------------------------------------------------------------------------------
	if [ ! -f ~/.vimrc ]; then
		cat <<- _EOT_ > ~/.vimrc
			set number
			set tabstop=4
			set list
			set listchars=tab:>_
_EOT_
	fi

	if [ ! -f ~/.bashrc.orig ]; then
		locale | sed -e 's/LANG=C/LANG=ja_JP.UTF-8/' \
					 -e 's/LANGUAGE=$/LANGUAGE=ja:en/' \
					 -e 's/"C"/"ja_JP.UTF-8"/' > /etc/locale.conf
		funcPause $?
		#----------------------------------------------------------------------
		cp -p ~/.bashrc ~/.bashrc.orig
		cat <<- _EOT_ >> ~/.bashrc
			#
			case "\${TERM}" in
			    "linux" )
			        LANG=C
			        ;;
			    * )
			        LANG=ja_JP.UTF-8
			        ;;
			esac
			export LANG
_EOT_
		. ~/.profile
	fi

#------------------------------------------------------------------------------
# Network Setup
#------------------------------------------------------------------------------
	# network interface -------------------------------------------------------
	if [ ! -f /etc/network/interfaces.orig ]; then
		sed -i.orig /etc/network/interfaces \
		    -e '/dns-*/d'
	fi
	# hosts -------------------------------------------------------------------
	if [ ! -f /etc/hosts.orig ]; then
		sed -i.orig /etc/hosts              \
		    -e 's/^127.0.1.1/# &/g'
	fi
	# resolv.conf -------------------------------------------------------------
	if [ ! -h /etc/resolv.conf ]; then
		if [ ! -f /etc/resolv.conf.orig ]; then
			sed -i.orig /etc/resolv.conf                             \
			    -e "s/nameserver ${NIC_GATE}/nameserver 127\.0\.0\.1/g"
		fi
	fi
	# hosts.allow -------------------------------------------------------------
	if [ ! -f /etc/hosts.allow.orig ]; then
		cp -p /etc/hosts.allow /etc/hosts.allow.orig
		cat <<- _EOT_ >> /etc/hosts.allow
			ALL : 127.0.0.1
			ALL : [::1]
			ALL : 169.254.0.0/16
			ALL : [fe80::]/64
			ALL : ${NIC_NTWK}/${NIC_BITS}
			# ALL : [${IP6_IPAD}]/${IP6_MASK}
_EOT_
	fi
	# hosts.deny --------------------------------------------------------------
	if [ ! -f /etc/hosts.deny.orig ]; then
		cp -p /etc/hosts.deny /etc/hosts.deny.orig
		cat <<- _EOT_ >> /etc/hosts.deny
			ALL : ALL
_EOT_
	fi

#------------------------------------------------------------------------------
# Make share dir
#------------------------------------------------------------------------------
	cat /etc/group | grep ${SMB_GADM}
	if [ $? -ne 0 ]; then
		groupadd --system "${SMB_GADM}"
	fi

	cat /etc/group | grep ${SMB_GRUP}
	if [ $? -ne 0 ]; then
		groupadd --system "${SMB_GRUP}"
	fi

	id ${SMB_USER}
	if [ $? -ne 0 ]; then
		useradd --system "${SMB_USER}" --groups "${SMB_GRUP}"
	fi

	usermod root -G ${SMB_GRUP}

	mkdir -p /share
	mkdir -p /share/data
	mkdir -p /share/data/adm
	mkdir -p /share/data/adm/netlogon
	mkdir -p /share/data/adm/profiles
	mkdir -p /share/data/arc
	mkdir -p /share/data/bak
	mkdir -p /share/data/pub
	mkdir -p /share/data/usr
	mkdir -p /share/dlna
	mkdir -p /share/dlna/movies
	mkdir -p /share/dlna/others
	mkdir -p /share/dlna/photos
	mkdir -p /share/dlna/sounds

	touch -f /share/data/adm/netlogon/logon.bat

	chown -R ${SMB_USER}:${SMB_GRUP} /share/.
	chmod -R  770 /share/.
	chmod    1777 /share/data/adm/profiles

#------------------------------------------------------------------------------
# Move home dir
#------------------------------------------------------------------------------
#	useradd -D -b /share/data/usr
#	usermod -d /share/data/usr/${DEF_USER} -m ${DEF_USER}
#	usermod ${DEF_USER} -G ${SMB_GRUP}
#	usermod -L ${DEF_USER}

#------------------------------------------------------------------------------
# Make shell dir
#------------------------------------------------------------------------------
	mkdir -p /usr/sh
	mkdir -p /var/log/sh

	cat <<- _EOT_ > /usr/sh/USRCOMMON.def
		#!/bin/bash
		###############################################################################
		##
		##	ファイル名	:	USRCOMMON.def
		##
		##	機能概要	:	ユーザー環境共通処理
		##
		##	入出力 I/F
		##		INPUT	:	
		##		OUTPUT	:	
		##
		##	作成者		:	J.Itou
		##
		##	作成日付	:	2014/10/27
		##
		##	改訂履歴	:	
		##	   日付       版         名前      改訂内容
		##	---------- -------- -------------- ----------------------------------------
		##	2013/10/27 000.0000 J.Itou         新規作成
		##	2014/11/04 000.0000 J.Itou         4HDD版仕様変更
		##	2014/12/22 000.0000 J.Itou         処理見直し
		##	2016/10/30 000.0000 J.Itou         処理見直し
		##	${NOW_DATE} 000.0000 J.Itou         自動作成
		##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
		##	---------- -------- -------------- ----------------------------------------
		###############################################################################

		#------------------------------------------------------------------------------
		# ユーザー変数定義
		#------------------------------------------------------------------------------

		# USBデバイス変数定義
		APL_MNT_DV1="${DEV_USB1}1"
		APL_MNT_DV2="${DEV_USB2}1"
		APL_MNT_DV3="${DEV_USB3}1"
		APL_MNT_DV4="${DEV_USB4}1"

		# USBデバイス変数定義
		APL_MNT_LN1="/mnt/usb1"
		APL_MNT_LN2="/mnt/usb2"
		APL_MNT_LN3="/mnt/usb3"
		APL_MNT_LN4="/mnt/usb4"

		SYS_MNT_DV1="/sys/block/`echo ${DEV_USB1} | awk -F/ '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV2="/sys/block/`echo ${DEV_USB2} | awk -F/ '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV3="/sys/block/`echo ${DEV_USB3} | awk -F/ '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV4="/sys/block/`echo ${DEV_USB4} | awk -F/ '{print $3}'`/device/scsi_disk/*/cache_type"
_EOT_

#------------------------------------------------------------------------------
# Make floppy dir
#------------------------------------------------------------------------------
#	if [ ! -d /media/floppy0 ]; then
#		pushd /media
#		mkdir floppy0
#		ln -s floppy0 floppy
#		popd
#	fi
#
#------------------------------------------------------------------------------
# Make cd-rom dir
#------------------------------------------------------------------------------
#	if [ ! -d /media/cdrom0 ]; then
#		pushd /media
#		mkdir cdrom0
#		ln -s cdrom0 cdrom
#		popd
#	fi
#
#------------------------------------------------------------------------------
# Make usb dir
#------------------------------------------------------------------------------
#	mkdir -p /mnt/cdrom
#	mkdir -p /mnt/floppy
	mkdir -p /mnt/usb1
	mkdir -p /mnt/usb2
	mkdir -p /mnt/usb3
	mkdir -p /mnt/usb4
#	#--------------------------------------------------------------------------
#	if [ ! -f /etc/fstab.orig ]; then
#		cp -p /etc/fstab /etc/fstab.orig
#		unexpand -a -t 4 /etc/fstab.orig > /etc/fstab
#		cat <<- _EOT_ >> /etc/fstab
#			# additional devices --------------------------------------------------------------------------------------------------
#			# <file system>									<mount point>	<type>			<options>				<dump>	<pass>
#			# /dev/sr0										/media/cdrom0	udf,iso9660		rw,user,noauto			0		0
#			# /dev/fd0										/media/floppy0	auto			rw,user,noauto			0		0
#			# /dev/sr0										/mnt/cdrom		udf,iso9660		rw,user,noauto			0		0
#			# /dev/fd0										/mnt/floppy		auto			rw,user,noauto			0		0
#			# ${DEV_USB1}1										/mnt/usb1		auto			rw,user,noauto			0		0
#			# ${DEV_USB2}1										/mnt/usb2		auto			rw,user,noauto			0		0
#			# ${DEV_USB3}1										/mnt/usb3		auto			rw,user,noauto			0		0
#			# ${DEV_USB4}1										/mnt/usb4		auto			rw,user,noauto			0		0
#_EOT_
#		vi /etc/fstab
#	fi
#
#------------------------------------------------------------------------------
# Install clamav
#------------------------------------------------------------------------------
	if [ ! -f /etc/clamav/freshclam.conf.orig ]; then
		sed -i.orig /etc/clamav/freshclam.conf \
			-e 's/# Check for new database 24 times a day/# Check for new database 12 times a day/' \
			-e 's/Checks 24/Checks 12/' \
			-e 's/^NotifyClamd/#&/'
	fi

	if [ ! -f /etc/clamav/clamd.conf ]; then
		touch /etc/clamav/clamd.conf
		chown clamav:adm /etc/clamav/clamd.conf
	fi

	if [ "${CPU_TYPE}" != "iop32x" ]; then
		funcProc clamav-freshclam restart
	else
		funcProc clamav-freshclam stop
	fi

#------------------------------------------------------------------------------
# Install ssh
#------------------------------------------------------------------------------
	if [ ! -f /etc/ssh/sshd_config.orig ]; then
		sed -i.orig /etc/ssh/sshd_config \
			-e 's/^PermitRootLogin .*/PermitRootLogin yes/' \
			-e 's/^#PermitRootLogin .*/PermitRootLogin yes/' \
			-e '$a UseDNS no'
	fi

	funcProc ssh restart

#------------------------------------------------------------------------------
# Install apache2
#------------------------------------------------------------------------------
	if [ ! -f /etc/apache2/mods-available/userdir.conf.orig ]; then
		cp -p /etc/apache2/mods-available/userdir.conf /etc/apache2/mods-available/userdir.conf.orig
		cat <<- _EOT_ > /etc/apache2/mods-available/userdir.conf
			<IfModule mod_userdir.c>
			 	UserDir web/public_html
			 	UserDir disabled root

			 	<Directory /share/data/usr/*/web/public_html>
			 		AllowOverride FileInfo AuthConfig Limit Indexes
			 		Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
			 		<Limit GET POST OPTIONS>
			 			Order allow,deny
			 			Allow from all
			 		</Limit>
			 		<LimitExcept GET POST OPTIONS>
			 			Order deny,allow
			 			Deny from all
			 		</LimitExcept>
			 	</Directory>
			</IfModule>
_EOT_
	fi

	a2enmod userdir
	funcProc apache2 stop

#------------------------------------------------------------------------------
# Install ftpd
#------------------------------------------------------------------------------
	if [ ! -f /etc/ftpusers.orig ]; then
		sed -i.orig /etc/ftpusers \
			-e 's/^root/# &/'
	fi
	#--------------------------------------------------------------------------
	which proftpd
	if [ $? -eq 0 ]; then					# Install proftpd
		if [ ! -f /etc/proftpd/proftpd.conf.orig ]; then
			cp -p /etc/proftpd/proftpd.conf /etc/proftpd/proftpd.conf.orig
			cat <<- _EOT_ >> /etc/proftpd/proftpd.conf
				TimesGMT off
				<Global>
				 	RootLogin on
				 	UseFtpUsers on
				</Global>
_EOT_
		fi
		#----------------------------------------------------------------------
		funcProc proftpd stop
	else									# Install vsftpd
		touch /etc/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
		touch /etc/vsftpd.user_list			# 接続拒否するユーザーのリスト
		touch /etc/vsftpd.banned_emails		# 接続拒否する電子メール・パスワードのリスト
		touch /etc/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
		#----------------------------------------------------------------------
		chmod 0600 /etc/vsftpd.chroot_list \
				   /etc/vsftpd.user_list \
				   /etc/vsftpd.banned_emails \
				   /etc/vsftpd.email_passwords
		#----------------------------------------------------------------------
		if [ ! -f /etc/vsftpd.conf.orig ]; then
			sed -i.orig /etc/vsftpd.conf \
				-e 's/^listen=.*$/listen=YES/' \
				-e 's/^listen_ipv6=.*$/listen_ipv6=NO/' \
				-e 's/^anonymous_enable=.*$/anonymous_enable=NO/' \
				-e 's/^local_enable=.*$/local_enable=YES/' \
				-e 's/^#write_enable=.*$/write_enable=YES/' \
				-e 's/^#local_umask=.*$/local_umask=022/' \
				-e 's/^dirmessage_enable=.*$/dirmessage_enable=NO/' \
				-e 's/^use_localtime=.*$/use_localtime=YES/' \
				-e 's/^xferlog_enable=.*$/xferlog_enable=YES/' \
				-e 's/^connect_from_port_20=.*$/connect_from_port_20=YES/' \
				-e 's/^#xferlog_std_format=.*$/xferlog_std_format=NO/' \
				-e 's/^#idle_session_timeout=.*$/idle_session_timeout=300/' \
				-e 's/^#data_connection_timeout=.*$/data_connection_timeout=30/' \
				-e 's/^#ascii_upload_enable=.*$/ascii_upload_enable=YES/' \
				-e 's/^#ascii_download_enable=.*$/ascii_download_enable=YES/' \
				-e 's/^#chroot_local_user=.*$/chroot_local_user=NO/' \
				-e 's/^#chroot_list_enable=.*$/chroot_list_enable=NO/' \
				-e 's/^#chroot_list_file=.*$/chroot_list_file=\/etc\/vsftpd.chroot_list/' \
				-e 's/^#ls_recurse_enable=.*$/ls_recurse_enable=YES/' \
				-e 's/^pam_service_name=.*$/pam_service_name=vsftpd/' \
				-e '$atcp_wrappers=YES' \
				-e '$auserlist_enable=YES' \
				-e '$auserlist_deny=YES' \
				-e '$auserlist_file=\/etc\/vsftpd.user_list' \
				-e '$achmod_enable=YES' \
				-e '$aforce_dot_files=YES' \
				-e '$adownload_enable=YES'\
				-e '$avsftpd_log_file=\/var\/log\/vsftpd\.log' \
				-e '$adual_log_enable=NO' \
				-e '$asyslog_enable=NO' \
				-e '$alog_ftp_protocol=NO' \
				-e '$aftp_data_port=20' \
				-e '$apasv_enable=YES'
		fi
		#----------------------------------------------------------------------
		funcProc vsftpd stop
	fi

#------------------------------------------------------------------------------
# Install bind9
#------------------------------------------------------------------------------
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > /var/cache/bind/${WGP_NAME}.zone
		\$TTL 3600
		@								IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 										1		; serial
		 										1800	; refresh
		 										900		; retry
		 										86400	; expire
		 										1200	; default_ttl
		 								)
		 								IN		NS		${SVR_NAME}.${WGP_NAME}.
		${SVR_NAME}						IN		A		${NIC_ADDR}
		${SVR_NAME}						IN		AAAA	${IP6_ADDR}
		${SVR_NAME}						IN		AAAA	${LNK_ADDR}
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > /var/cache/bind/${WGP_NAME}.rev
		\$TTL 3600
		@								IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 										1		; serial
		 										1800	; refresh
		 										900		; retry
		 										86400	; expire
		 										1200	; default_ttl
		 								)
		 								IN		NS		${SVR_NAME}.${WGP_NAME}.
		${SVR_ADDR}								IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > /var/cache/bind/${IP6_IPAD}.rev
		\$TTL 3600
		@								IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 										1		; serial
		 										1800	; refresh
		 										900		; retry
		 										86400	; expire
		 										1200	; default_ttl
		 								)
		 								IN		NS		${SVR_NAME}.${WGP_NAME}.
		${SVR_IPV6}	IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > /var/cache/bind/${LNK_IPAD}.rev
		\$TTL 3600
		@								IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 										1		; serial
		 										1800	; refresh
		 										900		; retry
		 										86400	; expire
		 										1200	; default_ttl
		 								)
		 								IN		NS		${SVR_NAME}.${WGP_NAME}.
		${SVR_LNK6}	IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	if [ ! -f /etc/bind/named.conf.local.orig ]; then
		cp -p /etc/bind/named.conf.local /etc/bind/named.conf.local.orig
		cat <<- _EOT_ >> /etc/bind/named.conf.local
			acl ${WGP_NAME}-net {
			 	127.0.0.1;
			 	::1;
			 	169.254.0.0/16;
			 	fe80::0/64;
			 	${NIC_NTWK}/${NIC_BITS};
			};

			zone "${WGP_NAME}" {
			 	type master;
			 	file "${WGP_NAME}.zone";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${REV_IPAD}.in-addr.arpa" {
			 	type master;
			 	file "${WGP_NAME}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${REV_IPV6}.ip6.arpa." {
			 	type master;
			 	file "${IP6_IPAD}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${REV_LNK6}.ip6.arpa." {
			 	type master;
			 	file "${LNK_IPAD}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};
_EOT_
	fi
	#--------------------------------------------------------------------------
	if [ "${NWK_NAME}" = "" ]; then
		sed -i.orig /var/cache/bind/${WGP_NAME}.zone -e "/^${SVR_NAME}.*${NIC_ADDR}$/d"
		sed -i.orig /var/cache/bind/${WGP_NAME}.rev  -e "/^${SVR_ADDR}.*${SVR_NAME}$/d"
	fi

	funcProc bind9 restart

	dig ${SVR_NAME}.${WGP_NAME} A
	dig ${SVR_NAME}.${WGP_NAME} AAAA
	dig -x ${NIC_ADDR}
	dig -x ${IP6_ADDR}

#------------------------------------------------------------------------------
# Install dhcp
#------------------------------------------------------------------------------
	if [ ! -f /etc/dhcp/dhcpd.conf.orig ]; then
		cp -p /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig
		cat <<- _EOT_ > /etc/dhcp/dhcpd.conf
			subnet ${NIC_NTWK} netmask ${NIC_MASK} {
			 	option time-servers ntp.nict.jp;
			 	option domain-name-servers ${NIC_ADDR};
			 	option domain-name "${WGP_NAME}";
			 	range ${ADR_DHCP};
			 	option routers ${NIC_GATE};
			 	option subnet-mask ${NIC_MASK};
			 	option broadcast-address ${NIC_BCST};
			 	option netbios-dd-server ${NIC_ADDR};
			 	default-lease-time 3600;
			 	max-lease-time 86400;
			}

_EOT_
	fi

	if [ ${FLG_DHCP} -ne 0 ]; then
		funcProc isc-dhcp-server start
	else
		funcProc isc-dhcp-server stop
	fi

#------------------------------------------------------------------------------
# Install Webmin
#------------------------------------------------------------------------------
	if [ "${SET_WMIN}" = "webmin-current.deb" ]; then
		dpkg -i webmin-current.deb
	else
		dpkg -i webmin_${VER_WMIN}_all.deb
	fi
	#--------------------------------------------------------------------------
	if [ ! -f /etc/webmin/config.orig ]; then
		cp -p /etc/webmin/config /etc/webmin/config.orig
		cat <<- _EOT_ >> /etc/webmin/config
			webprefix=
			lang_root=ja_JP.UTF-8
_EOT_
	fi
	#--------------------------------------------------------------------------
	if [ ! -f /etc/webmin/time/config.orig ]; then
		cp -p /etc/webmin/time/config /etc/webmin/time/config.orig
		cat <<- _EOT_ >> /etc/webmin/time/config
			timeserver=ntp.nict.jp
_EOT_
	fi

	funcProc webmin stop

#------------------------------------------------------------------------------
# Add smb.conf
#------------------------------------------------------------------------------
	cat <<- _EOT_ > ${SMB_WORK}
		# Samba config file created using SWAT
		# from ${SVR_NAME} (${NIC_ADDR})
		# Date: `date +"%Y/%m/%d/ %H:%M:%S"`

		[global]
		 	dos charset = CP932
		 	workgroup = ${WGP_NAME}
		 	pam password change = Yes
		 	unix password sync = No
		 	load printers = No
		 	printcap name = /dev/null
		 	add user script = /usr/sbin/useradd %u
		 	delete user script = /usr/sbin/userdel %u
		 	add group script = /usr/sbin/groupadd %g
		 	delete group script = /usr/sbin/groupdel %g
		 	add user to group script = /usr/bin/gpasswd -a %u %g
		 	delete user from group script = /usr/bin/gpasswd -d %u %g
		 	add machine script = /usr/sbin/useradd -d /dev/null -s /bin/false %u
		 	logon script = logon.bat
		 	logon path = \\\\%L\\profiles\\%U
		 	domain logons = Yes
		 	os level = 35
		 	preferred master = Yes
		 	domain master = Yes
		 	wins support = Yes
		 	idmap config * : backend = tdb
		 	admin users = administrator
		 	printing = bsd
		 	print command = lpr -r -P'%p' %s
		 	lpq command = lpq -P'%p'
		 	lprm command = lprm -P'%p' %j

		[homes]
		 	comment = Home Directories
		 	valid users = %S
		 	write list = @${SMB_GRUP}
		 	force user = ${SMB_USER}
		 	force group = ${SMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No

		[netlogon]
		 	comment = Network Logon Service
		 	path = /share/data/adm/netlogon
		 	valid users = @${SMB_GRUP}
		 	write list = @${SMB_GADM}
		 	force user = ${SMB_USER}
		 	force group = ${SMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No

		[profiles]
		 	comment = Users profiles
		 	path = /share/data/adm/profiles
		 	valid users = @${SMB_GRUP}
		 	write list = @${SMB_GRUP}
		 	profile acls = Yes
		 	browseable = No

		[share]
		 	comment = Shared directories
		 	path = /share
		 	valid users = @${SMB_GADM}
		 	browseable = No

		[data]
		 	comment = Data directories
		 	path = /share/data
		 	valid users = @${SMB_GADM}
		 	write list = @${SMB_GADM}
		 	force user = ${SMB_USER}
		 	force group = ${SMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No

		[dlna]
		 	comment = DLNA directories
		 	valid users = @${SMB_GRUP}
		 	path = /share/dlna
		 	write list = @${SMB_GRUP}
		 	force user = ${SMB_USER}
		 	force group = ${SMB_GRUP}
		 	create mask = 0770
		 	directory mask = 0770
		 	browseable = No

		[pub]
		 	comment = Public directories
		 	path = /share/data/pub
		 	valid users = @${SMB_GRUP}

_EOT_

	if [ ! -f ${SMB_BACK} ]; then
		cp -p ${SMB_CONF} ${SMB_BACK}
		cat ${SMB_WORK} > ${SMB_CONF}
	fi

#	testparm -s
	if [ -f /etc/init.d/samba ]; then
		funcProc samba restart
	else
		funcProc nmbd restart
		funcProc smbd restart
	fi

	if [ -f /etc/init.d/samba-ad-dc ]; then
		funcProc samba-ad-dc restart
	fi

#------------------------------------------------------------------------------
# Make User file (${DIR_WK}/addusers.txtが有ればそれを使う)
#------------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	touch ${USR_FILE}
	touch ${SMB_FILE}

	if [ ! -f ${LST_USER} ]; then
		# Make User List File (sample) ----------------------------------------
		cat <<- _EOT_ > ${USR_FILE}
			Administrator:Administrator:1001::1
_EOT_

		# Make Samba User List File (pdbedit -L -w にて出力されたもの) (sample)
		# administrator's password="password"
		cat <<- _EOT_ > ${SMB_FILE}
			administrator:1001:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-5A90A998:
_EOT_
	else
		while read LINE
		do
			if [ "${LINE}" != "" ]; then
				USERNAME=`echo ${LINE} | awk -F : '{print $1;}' | tr '[A-Z]' '[a-z]'`
				FULLNAME=`echo ${LINE} | awk -F : '{print $2;}'`
				USERIDNO=`echo ${LINE} | awk -F : '{print $3;}'`
				PASSWORD=`echo ${LINE} | awk -F : '{print $4;}'`
				LMPASSWD=`echo ${LINE} | awk -F : '{print $5;}'`
				NTPASSWD=`echo ${LINE} | awk -F : '{print $6;}'`
				ACNTFLAG=`echo ${LINE} | awk -F : '{print $7;}'`
				CHNGTIME=`echo ${LINE} | awk -F : '{print $8;}'`
				ADMINFLG=`echo ${LINE} | awk -F : '{print $9;}'`

				echo "${USERNAME}:${FULLNAME}:${USERIDNO}:${PASSWORD}:${ADMINFLG}"              >> ${USR_FILE}
				echo "${USERNAME}:${USERIDNO}:${LMPASSWD}:${NTPASSWD}:${ACNTFLAG}:${CHNGTIME}:" >> ${SMB_FILE}
			fi
		done < ${LST_USER}
	fi

#------------------------------------------------------------------------------
# Setup Login User
#------------------------------------------------------------------------------
	while read LINE
	do
		USERNAME=`echo ${LINE} | awk -F : '{print $1;}' | tr '[A-Z]' '[a-z]'`
		FULLNAME=`echo ${LINE} | awk -F : '{print $2;}'`
		USERIDNO=`echo ${LINE} | awk -F : '{print $3;}'`
		PASSWORD=`echo ${LINE} | awk -F : '{print $4;}'`
		ADMINFLG=`echo ${LINE} | awk -F : '{print $5;}'`
		# Account name to be checked ------------------------------------------
		id ${USERNAME}
		if [ $? -eq 0 ]; then
			echo "[${USERNAME}] already exists."
#			chown -R ${USERNAME}:${USERNAME} /share/data/usr/${USERNAME}
#			userdel -r ${USERNAME}
#			rm -Rf /share/data/usr/${USERNAME}
		else
			# Add users -------------------------------------------------------
			useradd  -b /share/data/usr -m -c "${FULLNAME}" -G ${SMB_GRUP} -u ${USERIDNO} ${USERNAME}
			chsh -s `which nologin` ${USERNAME}
			if [ "${ADMINFLG}" = "1" ]; then
				usermod -G ${SMB_GADM} -a ${USERNAME}
			fi
			# Make user dir ---------------------------------------------------
			mkdir -p /share/data/usr/${USERNAME}/app
			mkdir -p /share/data/usr/${USERNAME}/dat
			mkdir -p /share/data/usr/${USERNAME}/web/public_html
			touch -f /share/data/usr/${USERNAME}/web/public_html/index.html
			# Change user dir mode --------------------------------------------
			chmod -R 770 /share/data/usr/${USERNAME}
			chown -R ${SMB_USER}:${SMB_GRUP} /share/data/usr/${USERNAME}
		fi
	done < ${USR_FILE}

	echo --- ${SMB_GRUP} ---------------------------------------------------------------
	cat /etc/group | awk -F : '$1=="'${SMB_GRUP}'" {print $4;}'
#	groupmems -l -g ${SMB_GRUP}
	echo --- ${SMB_GADM} ---------------------------------------------------------------
	cat /etc/group | awk -F : '$1=="'${SMB_GADM}'" {print $4;}'
#	groupmems -l -g ${SMB_GADM}
	echo ------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Setup Samba User
#------------------------------------------------------------------------------
	SMB_PWDB=`find /var/lib/samba/ -name passdb.tdb -print`
	USR_LIST=`pdbedit -L | awk -F : '{print $1;}'`
	for USR_NAME in ${USR_LIST}
	do
		pdbedit -x -u ${USR_NAME}
	done
	pdbedit -i smbpasswd:${SMB_FILE} -e tdbsam:${SMB_PWDB}
	funcPause $?

#------------------------------------------------------------------------------
# Cron (cd /usr/sh 後に tar -cz CMD*sh | xxd -ps にて出力されたもの)
#------------------------------------------------------------------------------
	cat <<- _EOT_ > ${TGZ_WORK}
		1f8b0800dea99f5a0003ed5c7d5313491ae7dfcca7e81de1d0dd0a939924
		c4838a5748a2a00cb192b09ee552189281a40c099799a0ac47152487e2db
		6aed2aee2abb7be72aabbbe75bedbaeaeae277719800dfe2bae72599c9eb
		4412227bfd140593c9d33dbf7ebafbe9a77ffd0cfdace7605fffd191635d
		7cb4ad496283e27238e4bf508afed2368661da68c6e174daedae6e06dea7
		6987adbb0dd89a05482f695e08a500684b25934235bd5adfef52d9f31135
		1e4b50e3213e4aec69b010f28f45ccde1433ff1133f7c4eccfd2f5ab961e
		4bbf6ed0a94ab987df6f66ffc8ad66365717a086987921665e89d9f362f6
		dffaf2e2c263317b5dcc66c5cc133173175d646fa955488bf7a50bbf4b97
		ee8041ea10ba61191c3e361284b5c91f7c23c1fc277463fd8f95dcd2f5cd
		f9450bbc77a46b5048a60ddfe46edd5f7ffd35fc8eb1d176cab69f621c1a
		d61baf361f64a467f7738f7e556b070028fa40918d8b4b4013d866e9e255
		e55a2d7a7e517afc0a95b3e605945c94fd5845507d05ac004ead2e34bf80
		d2b63c9cdcf2d3cdd56b4a1bd5220e8ab6552b225d58ddb87e7e73f5f2c6
		9d5fc5855b8652aefa4bd194adde6739291b4dd1a64bed95ee5dccdd7c2a
		3dbebdb1f6307f771faaec04148a65298fa750d959838026744c832716b1
		07bcbb71e5dd8df91dfe919f9b9196becdad7c2f5d5956ac2edfbcd10230
		4417381589a512a1290eb4db4e51d0adf4fb58d6378cdcca443a111e4cc4
		04d04eb7d85c6256715ebfb4da5c7b80e21fa5c525317b41ccfc2066ff8b
		fc68167efc09792979ba10d086639e41ff1872d16eea4c32759a6a3f876e
		1ef11d1c1bf4cc41eb762937fa47fc63271cac67800dcca1ea4b5db3da64
		d4192cc7f3a1490e902c0880c324202b69930431751af62bb04e03e5391a
		9a39700050116e864aa4e371c01cf80b4df8bdc17e8fbbfd6f04119b0027
		a1be7c630e5813704c9c0bfa47bc7360b457887209c26240e1057ee08728
		aa9844f1911bd08fbc7cb9f13cb3fefbf9bd5afdfb48c2929a02d60915e1
		50ffd1b1438343de32082ddc59340acf1dea1b0a78e7888918414ca7f968
		0450a5bad0867599ea245cbb4749584a5ec45120630d7f3e01c822b351e3
		a7c7a0429730f93969b190f012fe410f04ff0402c7016b486b86efb0d20c
		a2be2e3bc9096188a3360aa8a7a2b090f0ba368c7a0d124d4e71262d8254
		f360d087c6a389c7c64d82819a5af7c0cbc623494e0b2691404d0d09bc6c
		f4404161b4a9918214f3bd833e34de26bcf9d9c3eba60f6f6afed40d868b
		c712e9b366f128da0a2452fd44361c533494323b9b64ddbc89d08726d828
		3563164d6a268f2535d30424b3bc5924b37c1ec92cdf7824693e651209d4
		d490c0cb464f6c5825c5474d4d6da80a878b0e0b2cd8f0b13b13326b17a8
		a9618197b5ed329d9c8e9459ba4dc2530209b2c531a982a2d50129329937
		1121d408498ed688563322ff5fa2df3335eb1935f83fdaee64da683b6deb
		b6338ccbe692f93fbb0df37f3b21ade2ff0a1bf5b2fc9fb4f86c6bfeb6e6
		9f9a4defa9fcd72ea1f7aa737515e9bd7a89bac6516eb0b26e04c16eab13
		828bb23929da691ac2b8909ae0a5276bd2db953f13d767fae1662102757a
		e97aacf14f91e926d43f1bcfafe7be5b511f83d678b78d90c91037e37422
		b5015f2038dcc77aa56bcbd2da2d997fd26eb94f4593bc8018be530ac154
		8eb62a144371dda0c7ad670551b123be8360d0a3d353982cf729e8f63855
		11067c3c1701560e74f2d4675d5d1fb75354a75c7ae3da9ab4f200ceffdc
		3719a58ebd6860b1acc73330c0b281c03ea2880c830042028c023fe938d1
		31d511e918e8603b0264b5cad4513a30d0c3b23dfa1a3d7d41ef58701059
		225f27d53145754440c7404f07db5354f19d1558f7bb7f2deb1a8baa39ee
		f51e1d1bf6152a3943aa0685767c235bb3362178dce73feaa684a96954b2
		efd890987da406b77a0f5f0fc538841846187453f164f834dc0554add850
		5a23dcdcba887e0805f4255425aa9ad4559c795a1f44df610de2a41161e6
		691578ea76c100cf77b80cbc522615229e2495ce59953be737f87be3cba7
		d2ddac61592c62bf47027e75518d70134df41a5bcb779beb35105f8e7aff
		b5dcf8976a6fc96d36ef87cb54addba0eddd07ce111638324271c0060e8f
		058201773badbf13fc7bd0ddce1084a5dc94553b4055af73aa5ab87034a9
		6d440de5e6806174c874b68a6e0e8c821ef52384364756de9fca7be5a223
		9aedd8cd603f74a2a2375e60e818828e8c874cb5b57c59faf17251071611
		ef81609f3f2813ef08995282944b0ba9d0b4665a740d3a158a9d2ce2d8c9
		92dd772f50b792bda088e41f061ef4ac372fa4a5dfd4ad772f3030f29d80
		060cb003da298390eedddeba7075f3f90be9f24d31bb20667e545c116191
		0f18cac219ed05ca09438523065d95daf6df52742c6041e7021634f8cbb8
		3e359ab3e48f458a9c5ea941a00193e970d484e9084be108c552fb0ca57c
		0baba0ae787c62fafc44b39452346f2965a4541f6b1a0db3b5f085f4c56b
		d5fb5fbcb4f5cdbdfc5113ac69fdede3dca31fe0041717aed05bf3cfb696
		bf5a7f7d7ffde52518d7cb0907bafc83cc974a79c24221e20aed9d266289
		0828f2f324341e72cc6489bfff5876efc03a25c4e0f79f3861c471960b2b
		349562917373e0b3dee6f453a91d2a768f6ae5e3a198a0cd49f9a9b045ea
		a4878dfcc80dc88ac35f337ea1008cb0c2d2da22dceba1fee7e31c874ef8
		b46ff94a1528cf97ce5f85ce424396e284742a91278d64a7a727b51ae1f1
		549f07dd8ae2f22acc4e6d40987556caa22263ad3e7af3de4b0da355e210
		96ce2dbd163397a4f97be50dc126d309a1817650964e54a9def7c330688c
		1d0e8e79bc9fea164fedeed0f05165019d42e5e0723599e264c7a553a8d3
		1d71ffd00df31a434eff14c51eb9974be2c25b387eb838cfc182e3f1d3b1
		885e15b6a32c203da2aa334f83640693b8f0447af4358c2be0be555c5813
		17ee8899afc4f98cd145aa50cd37b2e0d62caae14b1a68a20b8c4d36e36d
		2af89b72102b2f08f9e69a6f6f6139456e41f965f40feaaa8179e5f2d2cf
		7a0ef9bd8181fea13eb659147075fed76677d1ce36dace385c2ec6de6d77
		22fed7d56dc7fcef4e48abf85ffda0ab94027a57ccfe2287e0abf22efd67
		94110ac331ed240deddee1b2995dda0982d8d64dd9feba1b0862db7e449a
		32fbeb218861113b65ab8b20fe9350abad3c83c569947599eb034aa334ef
		9aaae63fd6590b8ceaf27bce442ccc81c20e34c5f1d1703c04372056b8bb
		2cf095e85e68a6f03dda7b82eae90ddb4ea82c855f29e253c2bdcab63156
		a2467a28bac3a9130d4b9d80939df58d0c079b78fc5f2bfe733076baf8fd
		1fbb03bfffb323d2aaf84f1b74158fff732b17d5e319e814334f641eee3b
		e42991cb5cdad1cc00ba7b37047e1ad60ff8c51f866218fce2cf7666148e
		58dfe188b56e73a959b0f2c163a7c04d4d2753a1d42c38938a091c10a2a9
		647a32da090e202efe4440a10a3fa5e7deab18f37ec5ecef57cc514c7717
		986a03f1095b534420c21b957499625da6b2aebd58d75e59d751ac0b6fe0
		5816a701b754a0ebf4074e0cf7b730fe77a29c5f8dff75ba64fed78ef9df
		9d9156c5ffdaa03311ffebd2b35af3fabf4aa9ba76c32e00d3bfe687270e
		a6dfe160ba6e73ed016a2ea63e7b5a9f0b511c7812fa94889220147d4259
		43017fbf9ba4941727f3373d81a0bbe8dc5b53d946dcabbe4a6732f2ada8
		5d36f6ada85d3efaad333964dbe4f4fadb6f51dac5e2928c50cc3c10b30f
		c5ec1b70d2f8e8d16dbdde8f32cad4c79459c2b26f14e7ab769c9255984f
		44517b5d9f5458251942d3062cca0cd4325caaf0eae58a157246f4f98546
		304dc9462b07a656baa09984c6b20983a6cd613c6830062f5790c7aefa2f
		2dca6b573eba49f1b38930b08666807500ae85112ecec1edaed5ca9d0dc7
		d311ce5dd213baafe2495ef864020ee488a129d093cc51258d238bce7dc8
		a2831fb201273f25ad7f9f939fd24af0c98f7efd69ec6e19aef623c75006
		7acbdeffb4399c2e7b1bcd381dae6edae150ffff9bdd89f77f3b21addaff
		e5079d89ffffd69a9c1f27dc1251b46d376cfa34aca6377d78fbb6edc500
		6fdfea32d707b47dabe95baa27ed982aac0ff842d382759213407a5a7e2d
		6cc7d36f4e1a018c36241da7a4525d9056d272eb2c549b4c8522ad6dbd8c
		a0e1cd576badd1fe488c17acad37821e46832d61ac1ac7ec7aa7834fb8b0
		60c182050b162c58b060c182050b162c58b060c182050b162c58b060c182
		054b73e57f56a7191f00780000
_EOT_

	pushd /usr/sh
	xxd -r -p ${TGZ_WORK} | tar -xz
	funcPause $?
	ls -al
	popd

#------------------------------------------------------------------------------
# Cron
#------------------------------------------------------------------------------
	cat <<- _EOT_ > ${CRN_FILE}
		SHELL = /bin/bash
		PATH = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
		# @reboot /sbin/sysctl -p
		0 0,3,6,9,12,15,18,21 * * * /usr/sbin/ntpdate -s ntp.nict.jp
		# @reboot /usr/sh/CMDMOUNT.sh
		# @reboot /usr/sh/CMDBACKUP.sh
		# 0 1 * * * /usr/sh/CMDFRESHCLAM.sh
		# 0 3 * * * /usr/sh/CMDRSYNC.sh
_EOT_

	crontab ${CRN_FILE}
	funcPause $?

#------------------------------------------------------------------------------
# GRUB
# 注)高解像度にならない場合は.vmxにsvga.minVRAMSize = 8388608を追加してみる。
#    MRAM = XRez * YRez * 4 / 65536
#    VRAM = ( int( MRAM ) + ( int( MRAM ) != MRAM )) * 65536
#    svga.minVRAMSize = VRAM
# 例) 2560 x 2048 の場合
#     vmotion.checkpointSVGAPrimarySize = "20971520"
#     svga.guestBackedPrimaryAware = "TRUE"
#     svga.minVRAMSize = "20971520"
#     svga.autodetect = "FALSE"
#     svga.maxWidth = "2560"
#     svga.maxHeight = "2048"
#     svga.vramSize = "20971520"
#------------------------------------------------------------------------------
	if [ -f /etc/default/grub ]; then
		if [ ! -f /etc/default/grub.orig ]; then
			sed -i.orig /etc/default/grub \
				-e 's/^GRUB_CMDLINE_LINUX_DEFAULT/#&/' \
				-e "s/#GRUB_GFXMODE=640x480/GRUB_GFXPAYLOAD_LINUX=${VGA_RESO}\nGRUB_GFXMODE=${VGA_RESO}/"

			update-grub
			funcPause $?
		fi
	fi

#------------------------------------------------------------------------------
# Disable IPv6
#------------------------------------------------------------------------------
#	if [ ! -f /etc/sysctl.conf.orig ]; then
#		cp -p /etc/sysctl.conf /etc/sysctl.conf.orig
#		cat <<- _EOT_ >> /etc/sysctl.conf
#			# -----------------------------------------------------------------------------
#			# Disable IPv6
#			net.ipv6.conf.all.disable_ipv6 = 1
#			net.ipv6.conf.default.disable_ipv6 = 1
#			net.ipv6.conf.lo.disable_ipv6 = 1
#			# -----------------------------------------------------------------------------
#_EOT_
#	fi
#
#	sysctl -p
#	ifconfig
#	ip a show
#
#------------------------------------------------------------------------------
# Install VMware Tools
#------------------------------------------------------------------------------
	if [ ${FLG_VMTL} -ne 0 ]; then
		VMW_CD=${MNT_CD}/VMwareTools-*.tar.gz
		mount ${DEV_CD} ${MNT_CD}
		if [ ! -f ${VMW_CD} ]; then
			if [ "`apt-cache search open-vm-tools-desktop`" = "" ]; then
				${CMD_AGET} install open-vm-tools open-vm-tools-dev open-vm-tools-dkms
				funcPause $?
			else
				${CMD_AGET} install open-vm-tools open-vm-tools-desktop open-vm-tools-dev open-vm-tools-dkms
				funcPause $?
			fi
			mkdir -p /mnt/hgfs
			if [ ! -f /etc/fstab.vmware ]; then
				cp -p /etc/fstab /etc/fstab.vmware
				which vmhgfs-fuse
				if [ $? -eq 0 ]; then
					HGFS_FS="fuse.vmhgfs-fuse"
				else
					HGFS_FS="vmhgfs"
				fi
				cat <<- _EOT_ >> /etc/fstab
					.host:/ /mnt/hgfs ${HGFS_FS} allow_other,auto_unmount,defaults 0 0
_EOT_
			fi
#			wget "https://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-DSA-KEY.pub"
#			wget "https://packages.vmware.com/tools/keys/VMWARE-PACKAGING-GPG-RSA-KEY.pub"
#			apt-key add ./VMWARE-PACKAGING-GPG-DSA-KEY.pub
#			apt-key add ./VMWARE-PACKAGING-GPG-RSA-KEY.pub
#			cat <<- _EOT_ > /etc/apt/sources.list.d/vmware-tools.list
#				deb https://packages.vmware.com/packages/ubuntu precise main
#_EOT_
#			${CMD_AGET} update
#			${CMD_AGET} install open-vm-tools-deploypkg
		else
			if [ ! -d /usr/src/linux-headers-`uname -r` ]; then
				${CMD_AGET} install linux-headers-`uname -r`
				funcPause $?
			fi
			tar -xzf ${VMW_CD}
			umount ${MNT_CD}
			${DIR_WK}/vmware-tools-distrib/vmware-install.pl -d -f
			funcPause $?
		fi
	fi

#------------------------------------------------------------------------------
# Backup
#------------------------------------------------------------------------------
	pushd /
	tar -czf /work/bk_boot.tgz   boot
	tar -czf /work/bk_etc.tgz    etc
	tar -czf /work/bk_home.tgz   home
	tar -czf /work/bk_share.tgz  share
	tar -czf /work/bk_usr_sh.tgz usr/sh
	tar -czf /work/bk_bind.tgz   var/cache/bind/
	tar -czf /work/bk_cron.tgz   var/spool/cron/crontabs
	popd

#------------------------------------------------------------------------------
# RAID Status
#------------------------------------------------------------------------------
	if [ -f /proc/mdstat ]; then
		cat /proc/mdstat
	fi

#------------------------------------------------------------------------------
# Termination
#------------------------------------------------------------------------------
	rm -f ${TGZ_WORK}
	rm -f ${CRN_FILE}
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	rm -f ${SMB_WORK}
	popd

#	systemctl list-unit-files -t service
#	systemctl -t service

#------------------------------------------------------------------------------
# Exit
#------------------------------------------------------------------------------
	exit 0

###############################################################################
# memo                                                                        #
###############################################################################
# apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
# find . -name *.iso -exec cp --preserve=timestamps {} /mnt/hgfs/Share/My\ Documents/Download/Linux/ \;
#==============================================================================
# End of file                                                                 =
#==============================================================================
