#!/bin/bash
###############################################################################
##
##	ファイル名	:	install.sh
##
##	機能概要	:	Install用シェル [VMware対応]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian 10 ～
##				:	Ubuntu 20.04 ～
##				:	CentOS 8 ～
##				:	Fedora 32 ～
##				:	openSUSE 15.2 ～
##	---------------------------------------------------------------------------
##	<サービス>	:	clamav-freshclam / clamd
##				:	ssh / sshd
##				:	bind9 / named
##				:	isc-dhcp-server / dhcpd
##				:	samba / smbd,nmbd / smb,nmb
##	---------------------------------------------------------------------------
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
##	2022/05/02 000.0000 J.Itou         処理見直し
##	2022/05/06 000.0000 J.Itou         処理見直し
##	2022/05/06 000.0000 J.Itou         処理見直し(unattended-upgrades対策)
##	2022/05/06 000.0000 J.Itou         不具合修正
##	2022/06/06 000.0000 J.Itou         AlmaLinux追加
##	2022/06/15 000.0000 J.Itou         不具合修正
##	2022/06/17 000.0000 J.Itou         処理見直し
##	2022/06/19 000.0000 J.Itou         不具合修正
##	2022/06/27 000.0000 J.Itou         処理見直し
##	2022/06/29 000.0000 J.Itou         処理見直し
##	2022/11/19 000.0000 J.Itou         不具合修正
##	2023/03/12 000.0000 J.Itou         不具合修正
##	2023/03/16 000.0000 J.Itou         不具合修正
##	2023/03/19 000.0000 J.Itou         不具合修正
##	2023/04/08 000.0000 J.Itou         処理見直し
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

	trap 'exit 1' 1 2 3 15

	export PATH=${PATH}:/usr/local/bin

	DBG_FLAG=${@:-0}
	OWN_PIDS=$$
	OWN_RSTA=0

# ユーザー設定 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fncUserSetting () {
	# ユーザー環境に合わせて変更する部分 --------------------------------------
	# 登録ユーザーリスト (pdbedit -L -w の出力結果を拡張) ･････････････････････
	#   UAR_ARRAY=("login name:full name:uid::lanman passwd hash:nt passwd hash:account flag:last change time:admin flag")
	# sample: administrator's password="password"
	#         NT Password hash: echo -n "password" | iconv -f UTF-8 -t UTF-16LE | openssl md4 | tr a-z A-Z
	#         Last Change Time: echo "obase=16; `date +%s -d '2018-02-24 08:54:00'`" | bc
	USR_ARRY=(                                                                                                                             \
	    "administrator:Administrator:1001::XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-5A90A998:1" \
	)

	# ･････････････････････････････････････････････････････････････････････････
	NTP_NAME=ntp.nict.jp														# NTPサーバー
	# ･････････････････････････････････････････････････････････････････････････
	EXT_ZONE=""																	# マスターDNSのドメイン名
	EXT_ADDR=""																	#   〃         IPアドレス
	# ･････････････････････････････････････････････････････････････････････････
#	VGA_RESO=("800x600x32"   "789")												# コンソールの解像度： 800× 600：1600万色
#	VGA_RESO=("1024x768x32"  "792")												#   〃              ：1024× 768：1600万色
	VGA_RESO=("1280x1024x32" "795")												#   〃              ：1280×1024：1600万色
#	VGA_RESO=("1920x1080x32"    "")												#   〃              ：1920×1080：1600万色
	# ･････････････････････････････････････････････････････････････････････････
	DIR_SHAR=/share																# 共有ディレクトリーのルート
	# ･････････････････････････････････････････････････････････････････････････
	SET_LANG="ja_JP.UTF-8"														# 使用言語設定
#	SET_LNGE="ja:en"															# 環境変数 LANGUAGE
	# ･････････････････････････････････････････････････････････････････････････
#	RUN_CLAM=("enable"  "")														# 起動停止設定：clamav-freshclam
	RUN_SSHD=("enable"  "")														#   〃        ：ssh / sshd
	RUN_HTTP=("disable" "")														#   〃        ：apache2 / httpd
#	RUN_FTPD=("disable" "")														#   〃        ：vsftpd
	RUN_BIND=("enable"  "")														#   〃        ：bind9 / named
	RUN_DHCP=("disable" "")														#   〃        ：isc-dhcp-server / dhcpd
	RUN_SMBD=("enable"  "")														#   〃        ：samba / smbd,nmbd / smb,nmb
#	RUN_WMIN=("disable" "")														#   〃        ：webmin
	RUN_DLNA=("disable" "")														#   〃        ：minidlna
	# -------------------------------------------------------------------------
	FLG_SVER=1																	# 0以外でサーバー仕様でセッティング
	DEF_USER="${SUDO_USER}"														# インストール時に作成したユーザー名
}

# 共通処理 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
# Pause処理 -------------------------------------------------------------------
fncPause () {
	local RET_STS=$1

	if [ ${RET_STS} -ne 0 ]; then
		echo "Enterキーを押して下さい。"
		read DUMMY
	fi
}

# プロセス制御処理 ------------------------------------------------------------
fncProc () {
	local INP_NAME=$1
	local INP_COMD=$2

	if [ "${INP_COMD}" = "" ]; then
		return
	fi

	if [ "`${CMD_WICH} systemctl 2> /dev/null`" != "" ]; then
		if [ "`systemctl is-enabled ${INP_NAME} 2> /dev/null`" != "masked" -o "${INP_COMD}" = "mask" -o "${INP_COMD}" = "unmask" ]; then
			systemctl --quiet --no-reload ${INP_COMD} ${INP_NAME}; fncPause $?
		else
			echo "${INP_NAME} is masked."
		fi
	elif [ "${INP_COMD}" != "enable" ] && [ "${INP_COMD}" != "disable" ]; then
		if [ "`${CMD_WICH} service 2> /dev/null`" != ""                              ] && \
		   [ "`find ${DIR_SYSD}/system/ -name \"${INP_NAME}.*\" -print`" != "" ]; then
			service ${INP_NAME} ${INP_COMD}; fncPause $?
		elif [ -f /etc/init.d/${INP_NAME} ]; then
			/etc/init.d/${INP_NAME} ${INP_COMD}
		fi
	else
		if [ ${DIR_SYSD} != "" ] && [ -f ${DIR_SYSD}/systemd-sysv-install ]; then
			${DIR_SYSD}/systemd-sysv-install ${INP_COMD} ${INP_NAME}; fncPause $?
		elif [ "`${CMD_WICH} insserv 2> /dev/null`" != "" ]; then
			case "${INP_COMD}" in
				"enable"  )	insserv -d ${INP_NAME}; fncPause $?;;
				"disable" )	insserv -r ${INP_NAME}; fncPause $?;;
			esac
		elif [ "`${CMD_WICH} chkconfig 2> /dev/null`" != "" ]; then
			case "${INP_COMD}" in
				"enable"  )	chkconfig -a ${INP_NAME}; fncPause $?;;
				"disable" )	chkconfig -d ${INP_NAME}; fncPause $?;;
			esac
		elif [ -d /etc/init/ ]; then
			case "${INP_COMD}" in
				"enable" )
					if [ -f /etc/init/${INP_NAME}.override ]; then
						rm -f /etc/init/${INP_NAME}.override
					fi
					;;
				"disable" )
					echo manual > /etc/init/${INP_NAME}.override
					;;
				* )	;;
			esac
#		elif [ -f /etc/init.d/${INP_NAME} ]; then
#			/etc/init.d/${INP_NAME} ${INP_COMD}
		fi
	fi
}

# プロセス制御検索処理 --------------------------------------------------------
fncProcFind () {
	local INP_NAME=$1

	if [ "`find ${DIR_SYSD}/system/ -name \"${INP_NAME}.*\" -print`" != "" ]; then
		echo 1
	elif [ -d /etc/init.d/ ] &&
	     [ "`find /etc/init.d/ -name \"${INP_NAME}\" -print`" != "" ]; then
		echo 1
	else
		echo 0
	fi
}

# diff拡張処理 ----------------------------------------------------------------
fncDiff () {
	set +e
	diff -y -W ${COL_SIZE} --suppress-common-lines "$1" "$2"
	local RET_CD=$?
	set -e
	if [ $RET_CD -ge 2 ]; then
		fncPause $RET_CD
		return 1
	fi
}

# substr処理 ------------------------------------------------------------------
fncSubstr () {
	echo ${@:1:($#-2)} | \
	    awk '{for (i=1;i<=NF;i++) print substr($i,'"${@:$#-1:1}"','"${@:$#:1}"');}'
}

# addstr処理 ------------------------------------------------------------------
fncAddstr () {
	echo ${@:1:($#-1)} | \
	    awk '{for (i=1;i<=NF;i++) print $1 "'"${@:($#):1}"'";}'
}

# IPアドレス取得処理 ----------------------------------------------------------
fncGetIPaddr () {
	local DMY_STAT

	DMY_STAT="`LANG=C ip -oneline -$1 address show scope $2 dev $3 mngtmpaddr | awk '{print $4;}'`"
	if [ "${DMY_STAT}" = "" ]; then
		DMY_STAT="`LANG=C ip -oneline -$1 address show scope $2 dev $3 | awk '{print $4;}'`"
	fi
	echo "${DMY_STAT}"
}

# NetworkManager設定値取得処理 ------------------------------------------------
fncGetNM () {
	local DMY_STAT

	case "$1" in
		"DHCP4" )
			if [ "`LANG=C ip -oneline -4 address show dev $2 scope global dynamic`" = "" ]; then
				DMY_STAT="static"
			else
				DMY_STAT="auto"
			fi
			;;
		"DHCP6" )
			if [ "`LANG=C ip -oneline -6 address show dev $2 scope global dynamic`" = "" ]; then
				DMY_STAT="static"
			else
				DMY_STAT="auto"
			fi
			;;
		"IP4.DNS" )
				DMY_STAT="`LANG=C ip -oneline -4 route list dev $2 default | awk '{print $3;}'`"
				if [ "${DMY_STAT}" = "" ]; then
					DMY_STAT="`LANG=C awk '/nameserver.*\./ {print$2}' /etc/resolv.conf`"
				fi
			;;
		"IP6.DNS" )
				DMY_STAT="`LANG=C ip -oneline -6 route list dev $2 default | awk '{print $3;}'`"
				if [ "${DMY_STAT}" = "" ]; then
					DMY_STAT="`LANG=C awk '/nameserver.*\:/ {print$2}' /etc/resolv.conf`"
				fi
			;;
		* )
			DMY_STAT=""
			;;
	esac
	echo "${DMY_STAT}"
}

# IPv6逆引き処理 --------------------------------------------------------------
fncIPv6Reverse () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		if [ "${INP_ADDR}" != "" ]; then
			OUT_ARRY+=($(echo ${INP_ADDR//:/} | \
			    awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1));     \
			                                  printf("%c" , substr($0,1,1));}'))
		fi
	done
	echo "${OUT_ARRY[@]}"
}

# IPv6補間処理 ----------------------------------------------------------------
fncIPv6Conv () {
	local OLD_IFS
	local OUT_TEMP
	local INP_ADDR
	local STR_FSEP
	local CNT_FSEP
	local -a OUT_ARRY=()
	local -a OUT_ADDR=()

	for INP_ADDR in "$@"
	do
		if [ "${INP_ADDR}" != "" ]; then
			STR_FSEP=${INP_ADDR//[^:]}
			CNT_FSEP=$((7-${#STR_FSEP}))
			(($CNT_FSEP)) && \
			    INP_ADDR=${INP_ADDR/::/"$(eval printf ':%.s' {1..$((CNT_FSEP+2))})"}
			OLD_IFS=${IFS}
			IFS=:
			OUT_ARRY=(${INP_ADDR/%:/::})
			IFS=${OLD_IFS}
			OUT_TEMP=$(printf ':%04x' "${OUT_ARRY[@]/#/0x0}")
			OUT_ADDR+=("${OUT_TEMP:1}")
		fi
	done
	echo "${OUT_ADDR[@]}"
}

# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmask () {
	local INP_ADDR
	local DEC_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		if [ "${INP_ADDR}" != "" ]; then
			DEC_ADDR=$((0xFFFFFFFF ^ ((2 ** (32-$((${INP_ADDR}))))-1)))
			OUT_ARRY+=($(printf '%d.%d.%d.%d' \
			    $((${DEC_ADDR} >> 24)) \
			    $(((${DEC_ADDR} >> 16) & 0xFF)) \
			    $(((${DEC_ADDR} >> 8) & 0xFF)) \
			    $((${DEC_ADDR} & 0xFF))))
		fi
	done
	echo "${OUT_ARRY[@]}"
}

# IPv4 netmask変換処理 bit用 --------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		if [ "${INP_ADDR}" != "" ]; then
			OUT_ARRY+=`echo ${INP_ADDR} | awk -F. '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
		fi
	done
	echo "${OUT_ARRY[@]}"
}

# 画面表示処理 ----------------------------------------------------------------
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

# 連続文字出力 ----------------------------------------------------------------
fncString () {
	if [ "$2" = " " ]; then
		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
	else
		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
	fi
}

# 初期設定 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fncInitialize () {
	# *************************************************************************
	# Initialize
	# *************************************************************************
	fncPrint "- Initialize $(fncString ${COL_SIZE} '-')"
	#--------------------------------------------------------------------------
	WHO_AMI=`whoami`															# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
	#--------------------------------------------------------------------------
	WHO_USER=`who | awk -v ORS="," '$1!="root" {print $1;}' | sed -e 's/,$//'`	# ログイン中ユーザ一覧
#	if [ "${WHO_USER}" != "" ]; then
#		echo "以下のユーザーがログインしています。"
#		echo "[${WHO_USER}]"
#		echo "全てのユーザーをログアウトしてから、"
#		echo "rootユーザーで実行して下さい。"
#		exit 1
#	fi

	# user setting ------------------------------------------------------------
	fncUserSetting

	# cpu type ----------------------------------------------------------------
	CPU_TYPE=`LANG=C lscpu | awk '/Architecture:/ {print $2;}'`					# CPU TYPE (x86_64/armv5tel/...)

	# system info -------------------------------------------------------------
	SYS_NAME=`awk -F '=' '$1=="ID"               {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
	SYS_CODE=`awk -F '=' '$1=="VERSION_CODENAME" {gsub("\"",""); print $2;}' /etc/os-release`	# コード名
	SYS_VERS=`awk -F '=' '$1=="VERSION"          {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン名
	SYS_VRID=`awk -F '=' '$1=="VERSION_ID"       {gsub("\"",""); print $2;}' /etc/os-release`	# バージョン番号
	SYS_VNUM=`echo ${SYS_VRID:--1} | bc`										#   〃          (取得できない場合は-1)
	SYS_NOOP=0																	# 対象OS=1,それ以外=0
	if [ "${SYS_CODE}" = "" -o `echo "${SYS_VNUM} <= 0" | bc` -ne 0 ]; then
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
	if [ "${SYS_NAME}" = "debian" ] && [ "${SYS_CODE}" = "sid" -o `echo "${SYS_VNUM} ==  7" | bc` -ne 0 ]; then
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

	# samba -------------------------------------------------------------------
	SMB_USER=sambauser															# smb.confのforce user
	SMB_GRUP=sambashare															# smb.confのforce group
	SMB_GADM=sambaadmin															# smb.confのadmin group

	# network -----------------------------------------------------------------
	#   NIC複数枚運用には非対応です                                            	<お願い>
	#   NIC_ARRY[0]のNICのみの設定を想定しています                             	<お願い>
	#   複数枚運用の場合は手作業にて対応願います                               	<お願い>
	# -------------------------------------------------------------------------
	SVR_FQDN=`hostname`															# 本機のFQDN
	SVR_NAME=`hostname -s`														# 本機のホスト名
	if [ "${SVR_FQDN}" != "${SVR_NAME}" ]; then									# ワークグループ名(ドメイン名)
		WGP_NAME=`hostname | awk -F '.' '{ print $2; }'`
	else
		WGP_NAME=`hostname -d`
		SVR_FQDN=${SVR_NAME}.${WGP_NAME}										# 本機のFQDN
	fi
	# -------------------------------------------------------------------------
	ACT_NMAN=""
	if [ "`${CMD_WICH} connmanctl 2> /dev/null`" != "" ] && [ "`systemctl is-enabled connman`" = "enabled" ]; then
		CON_NAME=`LANG=C connmanctl services | awk '{print $3;}'`				# 接続名
		CON_UUID=""																# 接続UUID
	elif [ "`${CMD_WICH} nmcli 2> /dev/null`" != "" ]; then
		if [ "`${CMD_WICH} systemctl 2> /dev/null`" != "" ]; then
			ACT_NMAN="`systemctl -q status NetworkManager | awk '/Active:/ {print $2;}'`"
		elif [ "`${CMD_WICH} status 2> /dev/null`" != "" ]; then
			if [ "`status network-manager | sed -n '/^.*running.*$/p'`" != "" ]; then
				ACT_NMAN="active"
			fi
		elif [ -f /etc/init.d/network-manager ]; then
			if [ "`/etc/init.d/network-manager status | sed -n '/^.*is running.*$/p'`" != "" ]; then
				ACT_NMAN="active"
			fi
		fi
		if [ "$ACT_NMAN" = "active" ]; then
			CON_NAME=`nmcli -t -f name c | head -n 1`								# 接続名
			CON_UUID=`nmcli -t -f uuid c | head -n 1`								# 接続UUID
		else
			CON_NAME=`LANG=C ip -o link show | awk -F '[: ]*' '!/lo:/ {print $2;}'`	# 接続名
			CON_UUID=""																# 接続UUID
		fi
	else
		CON_NAME=`LANG=C ip -o link show | awk -F '[: ]*' '!/lo:/ {print $2;}'`	# 接続名
		CON_UUID=""																# 接続UUID
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	NIC_ARRY=(`LANG=C ip -o link show | awk -F '[: ]*' '!/lo:/ {print $2;}'`)	# NICデバイス名
#	NIC_ARRY=(`LANG=C ip -4 -o a show scope global noprefixroute | awk -F '[: ]*' '{print $2;}'`)
	DEV_NICS=(`LANG=C ip -4 -o a show scope global | awk -F '[: ]*' '{print $2;}'`)
	for DEV_NAME in ${DEV_NICS[@]}
	do
		WRK_DHCP=`fncGetNM "DHCP4"   "${DEV_NAME}" "${CON_UUID}"`
		if [ "${WRK_DHCP}" != "auto" ]; then
			NIC_ARRY+=(`echo ${DEV_NAME}`)
		fi
	done
	for DEV_NAME in ${DEV_NICS[@]}
	do
		WRK_DHCP=`fncGetNM "DHCP4"   "${DEV_NAME}" "${CON_UUID}"`
		if [ "${WRK_DHCP}" = "auto" ]; then
			NIC_ARRY+=(`echo ${DEV_NAME}`)
		fi
	done
	for DEV_NAME in ${NIC_ARRY[@]}
	do
		IP4_ARRY+=(`fncGetIPaddr 4 "global" "${DEV_NAME}"`)						# IPv4:IPアドレス/サブネットマスク(bit)
		IP6_ARRY+=(`fncGetIPaddr 6 "global" "${DEV_NAME}"`)						# IPv6:IPアドレス/サブネットマスク(bit)
		LNK_ARRY+=(`fncGetIPaddr 6 "link"   "${DEV_NAME}"`)						# Link:IPアドレス/サブネットマスク(bit)
		IP4_DHCP+=(`fncGetNM "DHCP4"   "${DEV_NAME}" "${CON_UUID}"`)			# IPv4:DHCPフラグ(auto/static)
		IP6_DHCP+=(`fncGetNM "DHCP6"   "${DEV_NAME}" "${CON_UUID}"`)			# IPv6:DHCPフラグ(auto/static)
		IP4_DNSA+=(`fncGetNM "IP4.DNS" "${DEV_NAME}" "${CON_UUID}"`)			# IPv4:DNSアドレス
		IP6_DNSA+=(`fncGetNM "IP6.DNS" "${DEV_NAME}" "${CON_UUID}"`)			# IPv6:DNSアドレス
	done
																				# IPv4:デフォルトゲートウェイ
	IP4_GATE=`ip -4 r show table all | awk 'BEGIN{ORS = ""} /default/&&!a[$3]++ {print $3 " ";}'`
	# ･････････････････････････････････････････････････････････････････････････
	IP4_ADDR=("${IP4_ARRY[@]%/*}")												# IPv4:IPアドレス
	IP4_BITS=("${IP4_ARRY[@]#*/}")												# IPv4:サブネットマスク(bit)
	IP6_ADDR=("${IP6_ARRY[@]%/*}")												# IPv6:IPアドレス
	IP6_BITS=("${IP6_ARRY[@]#*/}")												# IPv6:サブネットマスク(bit)
	LNK_ADDR=("${LNK_ARRY[@]%/*}")												# Link:IPアドレス
	LNK_BITS=("${LNK_ARRY[@]#*/}")												# Link:サブネットマスク(bit)
	if [ "`${CMD_WICH} connmanctl 2> /dev/null`" != "" ] && [ "`systemctl is-enabled connman`" = "enabled" ]; then
		IP4_ADDR[0]=`sed -n "/iface ${NIC_ARRY[0]}/,/^$/p" /etc/network/interfaces | awk -F '[/ \t]*' '$2=="address" {print $3;}'`
		IP4_BITS[0]=`sed -n "/iface ${NIC_ARRY[0]}/,/^$/p" /etc/network/interfaces | awk -F '[/ \t]*' '$2=="address" {print $4;}'`
		IP4_GATE[0]=`sed -n "/iface ${NIC_ARRY[0]}/,/^$/p" /etc/network/interfaces | awk -F '[/ \t]*' '$2=="gateway" {print $3;}'`
		IP4_MASK[0]=`fncIPv4GetNetmask "${IP4_BITS[0]}"`
	fi
	# ･････････････････････････････････････････････････････････････････････････
	IP4_UADR=("${IP4_ADDR[@]%.*}")												# IPv4:本機のIPアドレスの上位値(/24決め打ち)
	IP4_LADR=("${IP4_ADDR[@]##*.}")												# IPv4:本機のIPアドレスの下位値
	IP4_LGAT=`echo ${IP4_GATE} | awk -F '.' '{print $4;}'`						# IPv4:デフォルトゲートウェイの下位値
	IP4_RADR=(`echo ${IP4_ADDR[@]}|awk -F '.' '{printf"%s.%s.%s", $3,$2,$1;}'`)	# IPv4:BIND(逆引き用
	IP4_NTWK=(`fncAddstr "${IP4_UADR[@]}"   ".0"`)								# IPv4:ネットワークアドレス
	IP4_BCST=(`fncAddstr "${IP4_UADR[@]}" ".255"`)								# IPv4:ブロードキャストアドレス
	IP4_MASK=(`fncIPv4GetNetmask "${IP4_BITS[@]}"`)								# IPv4:サブネットマスク
	# ･････････････････････････････････････････････････････････････････････････
	IP6_CONV=(`fncIPv6Conv "${IP6_ADDR[@]}"`)									# IPv6:補間済みアドレス
	LNK_CONV=(`fncIPv6Conv "${LNK_ADDR[@]}"`)									# Link:補間済みアドレス
	IP6_UADR=(`fncSubstr "${IP6_CONV[@]}"  1 19`)								# IPv6:本機のIPアドレスの上位値(/64決め打ち)
	IP6_LADR=(`fncSubstr "${IP6_CONV[@]}" 21 19`)								# IPv6:本機のIPアドレスの下位値
	LNK_UADR=(`fncSubstr "${LNK_CONV[@]}"  1 19`)								# Link:本機のIPアドレスの上位値(/64決め打ち)
	LNK_LADR=(`fncSubstr "${LNK_CONV[@]}" 21 19`)								# Link:本機のIPアドレスの下位値
	IP6_RADU=(`fncIPv6Reverse "${IP6_UADR[@]}"`)								# IPv6:BIND逆引き用上位値
	IP6_RADL=(`fncIPv6Reverse "${IP6_LADR[@]}"`)								# IPv6:BIND逆引き用下位値
	LNK_RADU=(`fncIPv6Reverse "${LNK_UADR[@]}"`)								# Link:BIND逆引き用上位値
	LNK_RADL=(`fncIPv6Reverse "${LNK_LADR[@]}"`)								# Link:BIND逆引き用下位値
	IP6_CDNS=(`fncIPv6Conv "${IP6_DNSA[@]}"`)									# IPv6:補間済みアドレス[DNS]
	IP6_UDNS=(`fncSubstr "${IP6_CDNS[@]}"  1 19`)								# IPv6:本機のIPアドレスの上位値(/64決め打ち)[DNS]
	IP6_LDNS=(`fncSubstr "${IP6_CDNS[@]}" 21 19`)								# IPv6:本機のIPアドレスの下位値[DNS]
	IP6_RDNU=(`fncIPv6Reverse "${IP6_UDNS[@]}"`)								# IPv6:BIND逆引き用上位値[DNS]
	IP6_RDNL=(`fncIPv6Reverse "${IP6_LDNS[@]}"`)								# IPv6:BIND逆引き用下位値[DNS]
	# ･････････････････････････････････････････････････････････････････････････
	RNG_DHCP="${IP4_UADR[0]}.64 ${IP4_UADR[0]}.79"								# IPv4:DHCPの提供アドレス範囲
	# プライベートIPアドレス --------------------------------------------------
	# クラス  | 使用できるIPアドレス範囲       | 使用できるサブネットマスク範囲
	# クラスA | 10.0.0.0 ～ 10.255.255.255     | 255.0.0.0 ～ 255.255.255.255（最大16,777,214台接続が可能）
	# クラスB | 172.16.0.0 ～ 172.31.255.255   | 255.255.0.0 ～ 255.255.255.255（最大65,534台接続が可能）
	# クラスC | 192.168.0.0 ～ 192.168.255.255 | 255.255.255.0 ～ 255.255.255.255（最大254台接続が可能）
	#
	#  8 | 11111111.00000000.00000000.00000000 | 255.0.0.0
	# 16 | 11111111.11111111.00000000.00000000 | 255.255.0.0
	# 24 | 11111111.11111111.11111111.00000000 | 255.255.255.0

	# ワーク変数設定 ----------------------------------------------------------
	MNT_CD=/media
	DEV_CD=/dev/sr0
	# -------------------------------------------------------------------------
	DIR_WK=${PWD}
	LST_USER=${DIR_WK}/addusers.txt
	TGZ_WORK=${DIR_WK}/${PGM_NAME}.sh.tgz
	CRN_FILE=${DIR_WK}/${PGM_NAME}.sh.crn
	USR_FILE=${DIR_WK}/${PGM_NAME}.sh.usr.list
	SMB_FILE=${DIR_WK}/${PGM_NAME}.sh.smb.list
	SMB_WORK=${DIR_WK}/${PGM_NAME}.sh.smb.work
	# -------------------------------------------------------------------------
	if [ "${SVR_NAME}" = "" ]; then
		if [ ${FLG_SVER} -ne 0 ]; then
			SVR_NAME=sv-${SYS_NAME}
		else
			SVR_NAME=ws-${SYS_NAME}
		fi
	fi
	# -------------------------------------------------------------------------
	if [ "`lscpu | grep -i vmware`" = "" ]; then
		FLG_VMTL=0																# 0以外でVMware Toolsをインストール
	else
		FLG_VMTL=1																# 0以外でVMware Toolsをインストール
	fi
	# -------------------------------------------------------------------------
	NUM_HDDS=`ls -l /dev/[hs]d[a-z] 2> /dev/null | wc -l`						# インストール先のHDD台数
	DEV_HDDS=("/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/sdf" "/dev/sdg" "/dev/sdh")
	HDD_ARRY=(${DEV_HDDS[@]:0:${NUM_HDDS}})
	USB_ARRY=(${DEV_HDDS[@]:${NUM_HDDS}:${#DEV_HDDS[@]}-${NUM_HDDS}})
	# -------------------------------------------------------------------------
	if [ -d "/lib/systemd/" ]; then
		DIR_SYSD="/lib/systemd"
	elif [ -d "/usr/lib/systemd/" ]; then
		DIR_SYSD="/usr/lib/systemd"
	else
		DIR_SYSD=""
	fi
	# -------------------------------------------------------------------------
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			CMD_AGET="apt-get -y -qq"
			;;
		"centos"       | \
		"fedora"       | \
		"rocky"        | \
		"miraclelinux" | \
		"almalinux"    )
			CMD_AGET="dnf -y -q"
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
#			CMD_AGET="zypper --non-interactive --terse --quiet"
			CMD_AGET="zypper --non-interactive --terse"
			;;
		* )
			;;
	esac
	# -------------------------------------------------------------------------
	if [ -f /etc/lightdm/users.conf ]; then
		LIN_CHSH=`awk -F '[ =]' '$1=="hidden-shells" {print $2;}' /etc/lightdm/users.conf`
	else
		LIN_CHSH=`awk -F ':' '$1=="root" && $7~/(false|nologin)/ {print $7;}' /etc/passwd`
		if [ "${LIN_CHSH}" = "" ]; then
			LIN_CHSH=`${CMD_WICH} nologin 2> /dev/null || ${CMD_WICH} false 2> /dev/null`
		fi
	fi
	if [ "`${CMD_WICH} usermod 2> /dev/null`" != "" ]; then
		CMD_CHSH="`${CMD_WICH} usermod` -s ${LIN_CHSH}"
	else
		CMD_CHSH="`${CMD_WICH} chsh` -s ${LIN_CHSH}"
	fi

	# --- chrony --------------------------------------------------------------
	INF_CHRO=`LANG=C find /etc/ -name "chrony.conf" -type f -exec ls -l '{}' \;`
	FUL_CHRO=`echo ${INF_CHRO} | awk '{print $9;}'`

	# --- bind ----------------------------------------------------------------
	INF_BIND=`LANG=C find /etc/ -name "named.conf" -type f -exec ls -l '{}' \;`
#	DNS_USER=`echo ${INF_BIND} | awk '{print $3;}'`
#	DNS_GRUP=`echo ${INF_BIND} | awk '{print $4;}'`
	if [ "`id bind 2> /dev/null`" != "" ]; then
		DNS_USER="bind"
		DNS_GRUP=""
	else
		DNS_USER="named"
		DNS_GRUP=""
	fi
	FUL_BIND=`echo ${INF_BIND} | awk '{print $9;}'`
	DIR_BIND=`dirname ${FUL_BIND}`
	FIL_BIND=`basename ${FUL_BIND}`
	FIL_BOPT=${FIL_BIND}.options
	FIL_BLOC=${FIL_BIND}.local
	DIR_ZONE=`sed -n '/^options {/,/^};/p' ${DIR_BIND}/${FIL_BIND} | awk '$1=="directory" {gsub("[\";]", ""); print $2;}'`
	case "${SYS_NAME}" in
		"debian"              | \
		"ubuntu"              )
			;;
		"centos"              | \
		"fedora"              | \
		"rocky"               | \
		"miraclelinux"        |  \
		"almalinux"           )
			FIL_BOPT=${FIL_BIND}
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			FIL_BOPT=${FIL_BIND}
			;;
		* )
			;;
	esac
	for FIL_NAME in ${DIR_BIND}/${FIL_BIND} ${DIR_BIND}/${FIL_BOPT} ${DIR_BIND}/${FIL_BIND}
	do
		if [ "${FIL_NAME}" != "" ] && [ -f ${FIL_NAME} ]; then
			DIR_ZONE=`sed -n '/^options {/,/^};/p' ${FIL_NAME} | awk '$1=="directory" {gsub("[\";]", ""); print $2;}'`
			if [ "${DIR_ZONE}" != "" ]; then
				break
			fi
		fi
	done

	# dhcpd -------------------------------------------------------------------
	INF_DHCP=`LANG=C find /etc/ -name "dhcpd.conf" -type f -exec ls -l '{}' \;`
	if [ "${INF_DHCP}" != "" ]; then
		FUL_DHCP=`echo ${INF_DHCP} | awk '{print $9;}'`
		DIR_DHCP=`dirname ${FUL_DHCP}`
		FIL_DHCP=`basename ${FUL_DHCP}`
	else
		FUL_DHCP=""
		DIR_DHCP=""
		FIL_DHCP=""
	fi

	# --- samba ---------------------------------------------------------------
	pdbedit -L > /dev/null
	fncPause $?
	SMB_PWDB=`find /var/lib/samba/ -name passdb.tdb -type f -print`
	SMB_CONF=`find /etc/ -name "smb.conf" -type f -print`
	SMB_BACK=${SMB_CONF}.orig
}

# Main処理 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fncMain () {
	fncPrint "$(fncString ${COL_SIZE} '*')"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 設定処理を開始します。"
	fncPrint "$(fncString ${COL_SIZE} '*')"

	# *************************************************************************
	# Initialize
	# *************************************************************************
	fncInitialize
	fncPrint "    ${SYS_NAME} ${SYS_VERS:-${SYS_CODE}} (${CPU_TYPE})"

	# *************************************************************************
	# Make work dir
	# *************************************************************************
	fncPrint "- Make work dir $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	chmod 700 ${DIR_WK}

	# *************************************************************************
	# NTP Setup
	# *************************************************************************
	if [ "${FUL_CHRO}" != "" ] && [ -f ${FUL_CHRO} ]; then
		fncPrint "- Set Up chrony $(fncString ${COL_SIZE} '-')"
		if [ ! -f ${FUL_CHRO}.orig ]; then
			cp -p ${FUL_CHRO} ${FUL_CHRO}.orig
		fi
		cp -p ${FUL_CHRO}.orig ${FUL_CHRO}
		if [ "`awk '$1==\"server\" && $2==\"ntp.nict.jp\" {print;}' ${FUL_CHRO}`" = "" ]; then
			INS_STR=`awk '($1=="pool" || $1=="server") && !a[$1]++ {print $1 " '${NTP_NAME}' iburst";}' ${FUL_CHRO}`
			sed -i ${FUL_CHRO}                                                     \
			    -e 's/^\([pool|server]\)/#\1/g'                                    \
			    -e "0,/^#[pool|server]/{s/^\(#[pool|server].*$\)/${INS_STR}\n\1/}"
			if [ "`fncProcFind \"chrony\"`" = "1" ]; then
				fncProc chrony restart
			elif [ "`fncProcFind \"chronyd\"`" = "1" ]; then
				fncProc chronyd restart
			fi
		fi
	fi
	# -------------------------------------------------------------------------
	# memo: sudo journalctl -xeu systemd-timesyncd.service
	if [ -f /etc/systemd/timesyncd.conf ]; then
		fncPrint "- Set Up timesyncd $(fncString ${COL_SIZE} '-')"
		if [ ! -d /etc/systemd/timesyncd.conf.d/ ]; then
			mkdir -p /etc/systemd/timesyncd.conf.d/
		fi
		if [ ! -f /etc/systemd/timesyncd.conf.d/* ]; then
			cat <<- _EOT_ > /etc/systemd/timesyncd.conf.d/ntp.conf
				# --- user settings ---
				[Time]
				NTP=${NTP_NAME}
_EOT_
		fi
		if [ "`systemctl is-enabled systemd-timesyncd 2> /dev/null`" = "enabled" ]; then
			fncPrint "--- timedatectl set-timezone $(fncString ${COL_SIZE} '-')"
			timedatectl set-timezone Asia/Tokyo
			fncPrint "--- timedatectl set-ntp $(fncString ${COL_SIZE} '-')"
			timedatectl set-ntp true
			fncPrint "--- timesyncd restart $(fncString ${COL_SIZE} '-')"
			fncProc systemd-timesyncd restart
		fi
	fi

	# *************************************************************************
	# System Update
	# *************************************************************************
	set +e
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			# --- unattended-upgrades停止 -------------------------------------
			if [ "`${CMD_WICH} unattended-upgrades 2> /dev/null`" != "" ] \
			&& [ "`systemctl is-active unattended-upgrades.service`" = "active" ]; then
				fncPrint "- stopping unattended-upgrades $(fncString ${COL_SIZE} '-')"
				systemctl --quiet --no-reload stop unattended-upgrades.service
			fi
			# --- sources.list更新 --------------------------------------------
			fncPrint "- System Update $(fncString ${COL_SIZE} '-')"
			if [ ! -f /etc/apt/sources.list.orig ]; then
				cp -p /etc/apt/sources.list /etc/apt/sources.list.orig
			fi
			cp -p /etc/apt/sources.list.orig /etc/apt/sources.list
			sed -i /etc/apt/sources.list \
			    -e 's/^deb cdrom.*$/# &/'
			# --- パッケージ更新 ----------------------------------------------
			if [ "${SYS_NAME}" = "debian" ] && [ "${CPU_TYPE}" = "armv5tel" ]; then
				fncPrint "- Package Update & Upgrade skipped $(fncString ${COL_SIZE} '-')"
			else
				fncPrint "- Package Update $(fncString ${COL_SIZE} '-')"
				${CMD_AGET} update
				fncPrint "- Package Upgrade $(fncString ${COL_SIZE} '-')"
				${CMD_AGET} upgrade
				${CMD_AGET} dist-upgrade
			fi
			;;
		"centos"       | \
		"fedora"       | \
		"rocky"        | \
		"miraclelinux" | \
		"almalinux"    )
			fncPrint "- System Update $(fncString ${COL_SIZE} '-')"
			# --- パッケージ更新 ----------------------------------------------
			fncPrint "- Package Update $(fncString ${COL_SIZE} '-')"
			${CMD_AGET} --refresh check-update
			fncPrint "- Package Upgrade $(fncString ${COL_SIZE} '-')"
			${CMD_AGET} update
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			fncPrint "- System Update $(fncString ${COL_SIZE} '-')"
			# --- パッケージ更新 ----------------------------------------------
			fncPrint "- Package Update $(fncString ${COL_SIZE} '-')"
			${CMD_AGET} update
			fncPrint "- Package Upgrade $(fncString ${COL_SIZE} '-')"
			${CMD_AGET} dist-upgrade
			;;
		* )
			;;
	esac
	set -e

	# *************************************************************************
	# Install snapd
	# *************************************************************************
#	case "${SYS_NAME}" in
#		"debian" | \
#		"ubuntu" )
#			case "${SYS_CODE}" in
#				"buster" | \
#				"sid"    | \
#				"bionic" | \
#				"focal"  | \
#				"groovy" )
#					if [ "`${CMD_WICH} snap 2> /dev/null`" = "" ]; then
#						fncPrint "--- Install snapd [${SYS_NAME} ${SYS_CODE}] $(fncString ${COL_SIZE} '-')"
#						${CMD_AGET} install snapd
#					fi
#					;;
#				* )
#					;;
#			esac
#			;;
#		* )
#			;;
#	esac

	# *************************************************************************
	# Install chromium
	# *************************************************************************
	# google-chrome -----------------------------------------------------------
	if [ "`${CMD_WICH} startx 2> /dev/null`" != "" ]; then
		case "${SYS_NAME}" in
			"debian" | \
			"ubuntu" )
				if [ "`LANG=C dpkg -l chromium ungoogled-chromium google-chrome-stable 2> /dev/null | awk '$1=="ii" {print $2;}'`" = "" ]; then
					fncPrint "--- Install google-chrome [${SYS_NAME} ${SYS_CODE}] $(fncString ${COL_SIZE} '-')"
					curl -L -# -O -R -S "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
					${CMD_AGET} install ${DIR_WK}/google-chrome-stable_current_amd64.deb
				fi
				;;
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				if [ "`LANG=C dnf list chromium ungoogled-chromium google-chrome-stable 2> /dev/null | sed -n '/Installed Packages/,/Available Packages/p' | awk '/chromium|chrome/ {print $1;}'`" = "" ]; then
					fncPrint "--- Install google-chrome [${SYS_NAME} ${SYS_CODE}] $(fncString ${COL_SIZE} '-')"
					curl -L -# -O -R -S "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
					${CMD_AGET} install google-chrome-stable_current_x86_64.rpm
				fi
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
				if [ "`LANG=C zypper --quiet search chromium ungoogled-chromium google-chrome-stable 2> /dev/null | awk -F '|' '/chromium|chrome/ {print $1;}' | sed -e 's/ *//g'`" = "" ]; then
					fncPrint "--- Install google-chrome [${SYS_NAME} ${SYS_CODE}] $(fncString ${COL_SIZE} '-')"
					curl -L -# -O -R -S "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
					${CMD_AGET} --no-gpg-checks -n install google-chrome-stable_current_x86_64.rpm
					zypper --gpg-auto-import-keys refresh
				fi
				;;
			* )
				;;
		esac
	fi

	# ungoogled-chromium --------------------------------------------------
#	URL_SYS=""
#	URL_DEB=""
#	URL_KEY=""
#	case "${SYS_NAME}" in
#		"debian" | \
#		"ubuntu" )
#			case "${SYS_CODE}" in
#				"buster" | \
#				"sid"    | \
#				"bionic" | \
#				"focal"  )
#					if [ "`dpkg -l chromium ungoogled-chromium google-chrome* 2>&1 | awk '$1=="ii" {print $2;}'`" = "" ]; then
#						fncPrint "--- Install ungoogled-chromium [${SYS_NAME} ${SYS_CODE}] $(fncString ${COL_SIZE} '-')"
#						URL_SYS="`echo ${SYS_NAME} | sed -e 's/\(.\)\(.*\)/\U\1\L\2/g'`_`echo ${SYS_CODE} | sed -e 's/\(.\)\(.*\)/\U\1\L\2/g'`"
#						URL_DEB="http://download.opensuse.org/repositories/home:/ungoogled_chromium/${URL_SYS}/"
#						URL_KEY="https://download.opensuse.org/repositories/home:ungoogled_chromium/${URL_SYS}/Release.key"
#						echo "deb ${URL_DEB} /" | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
#						curl -fsSL ${URL_KEY} | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_ungoogled_chromium.gpg > /dev/null
#						${CMD_AGET} install ungoogled-chromium ungoogled-chromium-common ungoogled-chromium-driver ungoogled-chromium-sandbox ungoogled-chromium-l10n
#					fi
#					;;
#				* )
#					;;
#			esac
#			;;
#		* )
#			;;
#	esac

	# *************************************************************************
	# Locale Setup
	# *************************************************************************
	fncPrint "- Set Up Locale $(fncString ${COL_SIZE} '-')"
	# --- /etc/locale.gen -----------------------------------------------------
	if [ -f /etc/locale.gen ]; then
		if [ ! -f /etc/locale.gen.orig ]; then
			cp -p /etc/locale.gen /etc/locale.gen.orig
		fi
		cp -p /etc/locale.gen.orig /etc/locale.gen
		sed -i /etc/locale.gen                              \
		    -e '/^#\|^$/! s/.*/# \0/'                       \
		    -e '1,/en_US.UTF-8/ s/.*\(en_US.UTF-8 .*\)/\1/' \
		    -e "1,/${SET_LANG}/ s/.*\(${SET_LANG} .*\)/\1/"
		locale-gen; fncPause $?
		update-locale LANG=${SET_LANG}; fncPause $?
	fi
	#--------------------------------------------------------------------------
	fncPrint "- Set Up User environment $(fncString ${COL_SIZE} '-')"
	for USER_NAME in "${USER}" "${SUDO_USER}"
	do
		fncPrint "--- ${USER_NAME}: $(fncString ${COL_SIZE} '-')"
		USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		pushd ${USER_HOME} > /dev/null
			case "${SYS_NAME}" in
				"debian" | \
				"ubuntu" )
					LNG_FILE=".bashrc"
					;;
				"centos"       | \
				"fedora"       | \
				"rocky"        | \
				"miraclelinux" | \
				"almalinux"    )
					LNG_FILE=".i18n"
					;;
				"opensuse-leap"       | \
				"opensuse-tumbleweed" )
					LNG_FILE=".i18n"
					;;
				* )
					;;
			esac
			VIM_VER=`LANG=C vi --version 2>&1 | sed -n '/IMproved/p' | awk '{print $5;}'`
			VIM_ARRY=`find /etc/ -name 'vimrc' -o -name 'virc' -type f | awk '{gsub("\"", ""); gsub(".*/", ""); print $0;}'`
			if [ "${VIM_ARRY}" = "" ]; then
				VIM_FILE=`LANG=C vi --version | awk '/^[ \t]*user vimrc file/ {gsub("\"", ""); gsub(".*/", ""); print $0;}'`
				[ "${VIM_FILE}" != "" ] && [ ! -f ${VIM_FILE} ] && { touch ${VIM_FILE}; chown ${USER_NAME}: ${VIM_FILE}; }
			else
				for VIMRC in ${VIM_ARRY}
				do
					[ ! -f .${VIMRC} ] && { touch .${VIMRC}; chown ${USER_NAME}: .${VIMRC}; }
				done
			fi
			[                            ! -f .curlrc     ] && { touch .curlrc;     chown ${USER_NAME}: .curlrc;     }
			[ "${LNG_FILE}" != "" ] && [ ! -f ${LNG_FILE} ] && { touch ${LNG_FILE}; chown ${USER_NAME}: ${LNG_FILE}; }
			# -----------------------------------------------------------------
			# 参照: http://vimdoc.sourceforge.net/htmldoc/usr_toc.html
			#       http://vimdoc.sourceforge.net/htmldoc/options.html
			# -----------------------------------------------------------------
			for VIMRC in ".vimrc" ".virc"
			do
				if [ "${VIMRC}" != "" ] && [ -f ${VIMRC} ]; then
					fncPrint "---- ${VIMRC} $(fncString ${COL_SIZE} '-')"
					if [ ! -f ${VIMRC}.orig ]; then
						cp -p ${VIMRC} ${VIMRC}.orig
					fi
					cp -p ${VIMRC}.orig ${VIMRC}
					cp -p ${VIMRC} ${VIMRC}.orig
					cat <<- '_EOT_' >> ${VIMRC}
						set number              " Print the line number in front of each line.
						set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
						set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
						set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
						set nowrap              " This option changes how text is displayed.
						set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
						set laststatus=2        " The value of this option influences when the last window will have a status line always.
						syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
					if [ "`${CMD_WICH} vim 2> /dev/null`" = "" -o `echo "${VIM_VER} < 8.0" | bc` -ne 0 ]; then
						sed -i ${VIMRC}                  \
						    -e 's/^\(syntax on\)/\" \1/'
					fi
				fi
			done
			# -----------------------------------------------------------------
#			if [ ! -f .bash_history.orig ] && [ -f .bash_history ]; then
#				fncPrint "---- .bash_history $(fncString ${COL_SIZE} '-')"
#				cp -p .bash_history .bash_history.orig
#				cat <<- '_EOT_' > .bash_history
#					sudo bash -c 'apt update && apt -y upgrade && apt -y full-upgrade'
#					sudo mount //windows-pc/share /mnt/share.win/ -t cifs -o vers=2.0,noperm,nounix,credentials=${HOME}/.credentials
#_EOT_
#			fi
			# -----------------------------------------------------------------
			if [ ! -f .curlrc.orig ]; then
				fncPrint "---- .curlrc $(fncString ${COL_SIZE} '-')"
				cp -p .curlrc .curlrc.orig
				cat <<- '_EOT_' >> .curlrc
					location
					progress-bar
					remote-time
					show-error
_EOT_
			fi
			# -----------------------------------------------------------------
			if [ "${LNG_FILE}" != "" ] && [ ! -f ${LNG_FILE}.orig ]; then
				fncPrint "---- ${LNG_FILE} $(fncString ${COL_SIZE} '-')"
				cp -p ${LNG_FILE} ${LNG_FILE}.orig
				cat <<- '_EOT_' >> ${LNG_FILE}
					# --- 日本語文字化け対策 ---
					case "${TERM}" in
					    "linux" ) export LANG=C;;
					    *       )              ;;
					esac
_EOT_
			fi
		popd > /dev/null
	done
	#--------------------------------------------------------------------------

	# *************************************************************************
	# Network Setup
	# *************************************************************************
	fncPrint "- Set Up Network $(fncString ${COL_SIZE} '-')"
	# hosts -------------------------------------------------------------------
	if [ -f /etc/hosts ]; then
		fncPrint "--- hosts $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/hosts.orig ]; then
			cp -p /etc/hosts /etc/hosts.orig
		fi
		cp -p /etc/hosts.orig /etc/hosts
		if [ "${IP4_DHCP[0]}" != "auto" ]; then
			sed -i /etc/hosts.orig                      \
			    -e "s/127.0.1.1/${IP4_ADDR}/"           \
			    -e "s/\(${SVR_FQDN}\)$/\1 ${SVR_NAME}/"
		fi
		if [ "`sed -n '/${SVR_NAME}/p' /etc/hosts`" = "" ]; then
			cat <<- _EOT_ >> /etc/hosts
				${IP4_ADDR[0]}	${SVR_FQDN} ${SVR_NAME}
_EOT_
		fi
	fi
	# hosts.allow -------------------------------------------------------------
	if [ -f /etc/hosts.allow ]; then
		fncPrint "--- hosts.allow $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/hosts.allow.orig ]; then
			cp -p /etc/hosts.allow /etc/hosts.allow.orig
		fi
		cp -p /etc/hosts.allow.orig /etc/hosts.allow
		cat <<- _EOT_ >> /etc/hosts.allow
			ALL : 127.0.0.1
			ALL : [::1]
			ALL : ${IP4_UADR[0]}.0/${IP4_BITS[0]}
			ALL : [fe80::]/64
			ALL : [${IP6_UADR[0]}::]/${IP6_BITS[0]}
_EOT_
	fi
	# hosts.deny --------------------------------------------------------------
	if [ -f /etc/hosts.deny ]; then
		fncPrint "--- hosts.deny $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/hosts.deny.orig ]; then
			cp -p /etc/hosts.deny /etc/hosts.deny.orig
		fi
		cp -p /etc/hosts.deny.orig /etc/hosts.deny
		cat <<- '_EOT_' >> /etc/hosts.deny
			ALL : ALL
_EOT_
	fi
	# cifs --------------------------------------------------------------------
	fncPrint "--- cifs $(fncString ${COL_SIZE} '-')"
	mkdir -p /mnt/share.nfs \
	         /mnt/share.win
	for USER_NAME in "${SUDO_USER}"
	do
		USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		pushd ${USER_HOME} > /dev/null
			cat <<- '_EOT_' > .credentials
				username=value
				password=value
				domain=value
_EOT_
			chown ${USER_NAME}: .credentials
			chmod 0600 .credentials
		popd > /dev/null
	done
	# ipv4 / ipv6 -------------------------------------------------------------
	fncPrint "--- ipv4 / ipv6 $(fncString ${COL_SIZE} '-')"
	# --- /etc/resolv.conf ------------------------------------------------
	if [   -f /etc/resolv.conf ] && \
	   [ ! -h /etc/resolv.conf ]; then
		fncPrint "----- /etc/resolv.conf $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/resolv.conf.orig ]; then
			cp -p /etc/resolv.conf /etc/resolv.conf.orig
		fi
		cp -p /etc/resolv.conf.orig /etc/resolv.conf
		sed -i /etc/resolv.conf     \
		    -e '/^search .*$/d'     \
		    -e '/^nameserver .*$/d'
		cat <<- _EOT_ >> /etc/resolv.conf
			search ${WGP_NAME}
			nameserver ::1
			nameserver 127.0.0.1
_EOT_
	fi
	# --- /etc/resolvconf/resolv.conf.d/head ----------------------------------
	if [ -f /etc/resolvconf/resolv.conf.d/head ]; then
		fncPrint "---- /etc/resolvconf/resolv.conf.d/head $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/resolvconf/resolv.conf.d/head.orig ]; then
			cp -p /etc/resolvconf/resolv.conf.d/head /etc/resolvconf/resolv.conf.d/head.orig
		fi
		cp -p /etc/resolvconf/resolv.conf.d/head.orig /etc/resolvconf/resolv.conf.d/head
		cat <<- _EOT_ >> /etc/resolvconf/resolv.conf.d/head
			# /etc/resolvconf/resolv.conf.d/head
			nameserver ::1
			nameserver 127.0.0.1
_EOT_
	fi
	# --- connmanctl ----------------------------------------------------------
	if [ "`${CMD_WICH} connmanctl 2> /dev/null`" != "" ]; then
		fncPrint "---- connmanctl $(fncString ${COL_SIZE} '-')"
		if [ -f /etc/connman/main.conf ]; then
			if [ ! -f /etc/connman/main.conf.orig ]; then
				cp -p /etc/connman/main.conf /etc/connman/main.conf.orig
			fi
			cp -p /etc/connman/main.conf.orig /etc/connman/main.conf
			sed -i /etc/connman/main.conf                         \
			    -e 's/^[ \t]*\(AllowHostnameUpdates\)/# \1/'      \
			    -e 's/^[ \t]*\(PreferredTechnologies\)/# \1/'     \
			    -e 's/^[ \t]*\(SingleConnectedTechnology\)/# \1/' \
			    -e '$a \\n# --- user settings ---'                \
			    -e '$a AllowHostnameUpdates = false'              \
			    -e '$a PreferredTechnologies = ethernet,wifi'     \
			    -e '$a SingleConnectedTechnology = true'
		fi
		mkdir -p /etc/systemd/system/connman.service.d/
		cat <<- _EOT_ > /etc/systemd/system/connman.service.d/disable_dns_proxy.conf
			[Service]
			ExecStart=
			ExecStart=`${CMD_WICH} connmand` -n --nodnsproxy
_EOT_
#		connmanctl config "${CON_NAME}" --ipv4 manual "${IP4_ADDR[0]}" "${IP4_MASK[0]}" "${IP4_GATE[0]}"
#		connmanctl config "${CON_NAME}" --ipv6 auto preferred
#		connmanctl config "${CON_NAME}" --nameservers ${IP6_DNSA[0]} ${IP4_DNSA[0]} 127.0.0.1
#		connmanctl config "${CON_NAME}" --domains ${WGP_NAME}
#		connmanctl config "${CON_NAME}" timeservers ${NTP_NAME};
#		connmanctl config "${CON_NAME}" mdns true
	fi
	# --- NetworkManager ------------------------------------------------------
	if [ "`${CMD_WICH} nmcli 2> /dev/null`" != "" ]; then
		fncPrint "---- NetworkManager $(fncString ${COL_SIZE} '-')"
		if [ -f /etc/NetworkManager/NetworkManager.conf ]; then
			if [ ! -f /etc/NetworkManager/NetworkManager.conf.orig ]; then
				cp -p /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.orig
			fi
			cp -p /etc/NetworkManager/NetworkManager.conf.orig /etc/NetworkManager/NetworkManager.conf
			if [ "`sed -n '/^dns/p' /etc/NetworkManager/NetworkManager.conf`" != "" ]; then
				sed -i /etc/NetworkManager/NetworkManager.conf \
				    -e 's/^\(dns=.*$\)/#\1/'
			fi
		fi
#		if [ "${CON_UUID}" != "" ] && [ "`LANG=C nmcli con help 2>&1 | sed -n '/COMMAND :=.*modify/p'`" != "" ]; then
#			nmcli c modify "${CON_UUID}" ipv6.method auto
#			nmcli c modify "${CON_UUID}" ipv6.ip6-privacy 1
#			nmcli c modify "${CON_UUID}" ipv6.dns "::1 ${IP6_DNSA[0]} ${IP6_UADR}:${IP6_LDNS}"
#			nmcli c modify "${CON_UUID}" ipv6.dns-search ${WGP_NAME}.
#			nmcli c modify "${CON_UUID}" ipv4.dns "127.0.0.1 ${IP4_DNSA[0]}"
#			nmcli c modify "${CON_UUID}" ipv4.dns-search ${WGP_NAME}.
#			nmcli c down   "${CON_UUID}" > /dev/null
#			nmcli c up     "${CON_UUID}" > /dev/null
#			for CON_INFO in `nmcli -t -f device,uuid c`
#			do
#				CON_INFO_DEV=`echo ${CON_INFO} | awk -F ':' '{print $1;}'`
#				CON_INFO_UUID=`echo ${CON_INFO} | awk -F ':' '{print $2;}'`
#				if [ "${CON_INFO_DEV}" != "${DEV_NAME}" ]; then
#					nmcli c delete uuid ${CON_INFO_UUID}
#				fi
#			done
#		fi
	fi
	# --- netplan -------------------------------------------------------------
	if [ "`${CMD_WICH} netplan 2> /dev/null`" != "" ]; then
		fncPrint "---- netplan $(fncString ${COL_SIZE} '-')"
		if [ -d /etc/netplan/ ]; then
			for FIL_NAME in /etc/netplan/99-network-manager-static.yaml /etc/netplan/00-installer-config.yaml
			do
				if [ "${FIL_NAME}" != "" ] && [ -f ${FIL_NAME} ]; then
					fncPrint "----- ${FIL_NAME} $(fncString ${COL_SIZE} '-')"
					if [ ! -f ${FIL_NAME}.orig ]; then
						cp -p ${FIL_NAME} ${FIL_NAME}.orig
					fi
					cp -p ${FIL_NAME}.orig ${FIL_NAME}
				fi
			done
		fi
	fi
	# --- systemd-resolved ----------------------------------------------------
	if [ "`systemctl is-enabled systemd-resolved 2> /dev/null`" = "enabled" ] && \
	   [ "`sed -n '/127.0.0.53/p' /etc/resolv.conf`" != "" ]; then
		fncPrint "--- Disable systemd-resolved $(fncString ${COL_SIZE} '-')"
		fncProc systemd-resolved disable										# nameserver 127.0.0.53 の無効化
	fi
	# SELinux -----------------------------------------------------------------
	if [ "`${CMD_WICH} getenforce 2> /dev/null`" != "" ]; then
		fncPrint "--- SELinux $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/selinux/config.orig ]; then
			cp -p /etc/selinux/config /etc/selinux/config.orig
		fi
		cp -p /etc/selinux/config.orig /etc/selinux/config
		if [ "`getenforce`" = "Enforcing" ]; then
			fncPrint "---- Disabled SELinux $(fncString ${COL_SIZE} '-')"
			sed -i /etc/selinux/config                     \
			    -e 's/\(SELINUX\)=enforcing/\1=disabled/g'
		fi
	fi
	# Virtual Bridge ----------------------------------------------------------
	if [ "`fncProcFind \"libvirtd\"`" = "1" ]; then
		fncPrint "--- Disable Virtual Bridge $(fncString ${COL_SIZE} '-')"
		fncProc libvirtd disable
	fi
	# firewalld ---------------------------------------------------------------
	if [ "`fncProcFind \"firewalld\"`" = "1" ]; then
		fncPrint "--- firewalld $(fncString ${COL_SIZE} '-')"
		fncProc firewalld enable
		fncProc firewalld restart
		# --- 	Firewalld を有効にしている場合 --------------------------------
		firewall-cmd --zone=home --permanent --add-service=dns			# named
#		firewall-cmd --zone=home --permanent --add-service=dhcp			# dhcpd
		firewall-cmd --zone=home --permanent --add-service=samba		# smb
#		firewall-cmd --zone=home --permanent --add-service=ftp			# vsftpd
#		firewall-cmd --zone=home --permanent --add-service=http			# httpd
#		firewall-cmd --zone=home --permanent --add-service=nfs			# nfs
		firewall-cmd --zone=home --permanent --add-source-port=137/udp	# ファイルマネージャー対策
		firewall-cmd --set-default-zone=home
		firewall-cmd --reload
		# --- ファイルマネージャー対策 [一時的] -------------------------------
#		iptables -t raw -A OUTPUT -p udp -m udp --dport 137 -j CT --helper netbios-ns
	fi
	# nsswitch.conf -----------------------------------------------------------
	if [   -f /etc/nsswitch.conf ]; then
		fncPrint "--- nsswitch.conf $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/nsswitch.conf.orig ]; then
			cp -p /etc/nsswitch.conf /etc/nsswitch.conf.orig
		fi
		cp -p /etc/nsswitch.conf.orig /etc/nsswitch.conf
#		sed -i /etc/nsswitch.conf \
#		    -e 's/mdns4/mdns/g'
		OLD_IFS=${IFS}
		IFS=$'\n'
		INS_ROW=$((`sed -n '/^hosts:/ =' /etc/nsswitch.conf | head -n 1`))
		INS_TXT=`sed -n '/^hosts:/ s/\(hosts:[ |\t]*\).*$/\1mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns mdns/p' /etc/nsswitch.conf`
		sed -e '/^hosts:/ s/^/#/' /etc/nsswitch.conf | \
		sed -e "${INS_ROW}a ${INS_TXT}"                \
		> nsswitch.conf
		cat nsswitch.conf > /etc/nsswitch.conf
		rm nsswitch.conf
		IFS=${OLD_IFS}
	fi

	# *************************************************************************
	# Make share dir
	# *************************************************************************
	fncPrint "- Make share dir $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	RET_GADM=`awk -F ':' '$1=="'${SMB_GADM}'" { print $1; }' /etc/group`
	if [ "${RET_GADM}" = "" ]; then
		groupadd --system "${SMB_GADM}"
		fncPause $?
	fi
	# -------------------------------------------------------------------------
	RET_GRUP=`awk -F ':' '$1=="'${SMB_GRUP}'" { print $1; }' /etc/group`
	if [ "${RET_GRUP}" = "" ]; then
		groupadd --system "${SMB_GRUP}"
		fncPause $?
	fi
	# -------------------------------------------------------------------------
	RET_USER=`awk -F ':' '$1=="'${SMB_USER}'" { print $1; }' /etc/passwd`
	if [ "${RET_USER}" = "" ]; then
		useradd --system "${SMB_USER}" --groups "${SMB_GRUP}"
		fncPause $?
	fi
	# -------------------------------------------------------------------------
	mkdir -p ${DIR_SHAR}
	mkdir -p ${DIR_SHAR}/cifs
	mkdir -p ${DIR_SHAR}/data
	mkdir -p ${DIR_SHAR}/data/adm
	mkdir -p ${DIR_SHAR}/data/adm/netlogon
	mkdir -p ${DIR_SHAR}/data/adm/profiles
	mkdir -p ${DIR_SHAR}/data/arc
	mkdir -p ${DIR_SHAR}/data/bak
	mkdir -p ${DIR_SHAR}/data/pub
	mkdir -p ${DIR_SHAR}/data/usr
	mkdir -p ${DIR_SHAR}/dlna
	mkdir -p ${DIR_SHAR}/dlna/movies
	mkdir -p ${DIR_SHAR}/dlna/others
	mkdir -p ${DIR_SHAR}/dlna/photos
	mkdir -p ${DIR_SHAR}/dlna/sounds
	# -------------------------------------------------------------------------
	touch -f ${DIR_SHAR}/data/adm/netlogon/logon.bat
	# -------------------------------------------------------------------------
	chown -R ${SMB_USER}:${SMB_GRUP} ${DIR_SHAR}/*
	chmod -R  770 ${DIR_SHAR}/*
	chmod    1777 ${DIR_SHAR}/data/adm/profiles

	# *************************************************************************
	# Make usb dir
	# *************************************************************************
#	fncPrint "- Make usb dir $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
#	mkdir -p /mnt/usb1
#	mkdir -p /mnt/usb2
#	mkdir -p /mnt/usb3
#	mkdir -p /mnt/usb4

	# *************************************************************************
	# Make shell dir
	# *************************************************************************
#	fncPrint "- Make shell dir $(fncString ${COL_SIZE} '-')"
#	# -------------------------------------------------------------------------
#	mkdir -p /usr/sh
#	mkdir -p /var/log/sh
#	# -------------------------------------------------------------------------
#	cat <<- _EOT_ > /usr/sh/USRCOMMON.def
#		#!/bin/bash
#		###############################################################################
#		##
#		##	ファイル名	:	USRCOMMON.def
#		##
#		##	機能概要	:	ユーザー環境共通処理
#		##
#		##	入出力 I/F
#		##		INPUT	:	
#		##		OUTPUT	:	
#		##
#		##	作成者		:	J.Itou
#		##
#		##	作成日付	:	2014/10/27
#		##
#		##	改訂履歴	:	
#		##	   日付       版         名前      改訂内容
#		##	---------- -------- -------------- ----------------------------------------
#		##	2013/10/27 000.0000 J.Itou         新規作成
#		##	2014/11/04 000.0000 J.Itou         4HDD版仕様変更
#		##	2018/03/20 000.0000 J.Itou         処理見直し
#		##	${NOW_DATE} 000.0000 J.Itou         自動作成
#		##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
#		##	---------- -------- -------------- ----------------------------------------
#		###############################################################################
#
#		#------------------------------------------------------------------------------
#		# ユーザー変数定義
#		#------------------------------------------------------------------------------
#
#		# USBデバイス変数定義
#		APL_MNT_DV1="${USB_ARRY[0]}1"
#		APL_MNT_DV2="${USB_ARRY[1]}1"
#		APL_MNT_DV3="${USB_ARRY[2]}1"
#		APL_MNT_DV4="${USB_ARRY[3]}1"
#
#		# USBデバイス変数定義
#		APL_MNT_LN1="/mnt/usb1"
#		APL_MNT_LN2="/mnt/usb2"
#		APL_MNT_LN3="/mnt/usb3"
#		APL_MNT_LN4="/mnt/usb4"
#
#		SYS_MNT_DV1="/sys/block/`echo ${USB_ARRY[0]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
#		SYS_MNT_DV2="/sys/block/`echo ${USB_ARRY[1]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
#		SYS_MNT_DV3="/sys/block/`echo ${USB_ARRY[2]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
#		SYS_MNT_DV4="/sys/block/`echo ${USB_ARRY[3]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
#_EOT_
#
	# *************************************************************************
	# Install clamav
	# *************************************************************************
	if [ "`${CMD_WICH} freshclam 2> /dev/null`" != "" ]; then
		fncPrint "- Set Up clamav $(fncString ${COL_SIZE} '-')"
		FILE_FRESHCONF=`find /etc/ -name "freshclam.conf" -type f -print`
		FILE_CLAMDCONF=`dirname ${FILE_FRESHCONF}`/clamd.conf
		# ---------------------------------------------------------------------
		cp -p ${FILE_FRESHCONF} ${FILE_CLAMDCONF}
		: > ${FILE_CLAMDCONF}
		# ---------------------------------------------------------------------
		if [ "${FILE_FRESHCONF}" != "" ] && [ ! -f ${FILE_FRESHCONF}.orig ]; then
			cp -p ${FILE_FRESHCONF} ${FILE_FRESHCONF}.orig
		fi
		cp -p ${FILE_FRESHCONF}.orig ${FILE_FRESHCONF}
		sed -i ${FILE_FRESHCONF}                                             \
		    -e 's/^Example/#&/'                                              \
		    -e 's/\(# Check for new database\) 24 \(times a day\)/\1 12 \2/' \
		    -e 's/\(Checks\) 24/\1 12/'                                      \
		    -e 's/^NotifyClamd/#&/'
		# ---------------------------------------------------------------------
		if [ "${SYS_NAME}" = "debian" ] && [ "${CPU_TYPE}" = "armv5tel" ]; then
			fncProc clamav-freshclam disable
			fncProc clamav-freshclam stop
		fi
	fi

	# *************************************************************************
	# Install apache2 / httpd
	# *************************************************************************
	if [ -f /etc/apache2/apache2.conf ]; then
		fncPrint "- Set Up apache2 $(fncString ${COL_SIZE} '-')"
		fncProc apache2 "${RUN_SSHD[0]}"
		fncProc apache2 "${RUN_SSHD[1]}"
	fi
	if [ -f /etc/httpd/conf/httpd.conf ]; then
		fncPrint "- Set Up httpd $(fncString ${COL_SIZE} '-')"
		fncProc httpd "${RUN_SSHD[0]}"
		fncProc httpd "${RUN_SSHD[1]}"
	fi

	# *************************************************************************
	# Install ssh
	# *************************************************************************
	if [ -f /etc/ssh/sshd_config ]; then
		fncPrint "- Set Up ssh $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/ssh/sshd_config.orig ]; then
			cp -p /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
		fi
		cp -p /etc/ssh/sshd_config.orig /etc/ssh/sshd_config
		sed -i /etc/ssh/sshd_config             \
		    -e '$a \\n# --- user settings ---'  \
		    -e '$a PermitRootLogin no'          \
		    -e '$a UseDNS no'                   \
		    -e '$a #PubkeyAuthentication yes'   \
		    -e '$a #PasswordAuthentication yes'
		if [ "`fncProcFind \"ssh\"`" = "1" ]; then
			fncProc ssh "${RUN_SSHD[0]}"
			fncProc ssh "${RUN_SSHD[1]}"
		fi
		if [ "`fncProcFind \"sshd\"`" = "1" ]; then
			fncProc sshd "${RUN_SSHD[0]}"
			fncProc sshd "${RUN_SSHD[1]}"
		fi
	fi

	# *************************************************************************
	# Install bind9
	# *************************************************************************
	fncPrint "- Set Up bind9 $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	DNS_SCNT="`date +"%Y%m%d"`01"
	#--------------------------------------------------------------------------
	if [ ! -d ${DIR_ZONE}/master ]; then
		fncPrint "--- mkdir master $(fncString ${COL_SIZE} '-')"
		mkdir -p ${DIR_ZONE}/master
		chown ${DNS_USER}:${DNS_GRUP} ${DIR_ZONE}/master
	fi
	if [ ! -d ${DIR_ZONE}/slaves ]; then
		fncPrint "--- mkdir slaves $(fncString ${COL_SIZE} '-')"
		mkdir -p ${DIR_ZONE}/slaves
		chown ${DNS_USER}:${DNS_GRUP} ${DIR_ZONE}/slaves
	fi
	fncPrint "--- db.xxx $(fncString ${COL_SIZE} '-')"
	for FIL_NAME in ${WGP_NAME} ${IP4_RADR[0]}.in-addr.arpa ${LNK_RADU[0]}.ip6.arpa ${IP6_RADU[0]}.ip6.arpa
	do
		cat <<- _EOT_ | sed -e 's/^ //g' > ${DIR_ZONE}/master/db.${FIL_NAME}
			\$TTL 1H																; 1 hour
			@										IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
			 														${DNS_SCNT}	; serial
			 														30M			; refresh (30 minutes)
			 														15M			; retry (15 minutes)
			 														1D			; expire (1 day)
			 														20M			; minimum (20 minutes)
			 												)
			 										IN		NS		${SVR_NAME}.${WGP_NAME}.
_EOT_
#		chmod 640 ${DIR_ZONE}/master/db.${FIL_NAME}
		chown ${DNS_USER}:${DNS_GRUP} ${DIR_ZONE}/master/db.${FIL_NAME}
	done
	#--------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e 's/^ //g' >> ${DIR_ZONE}/master/db.${WGP_NAME}
		${SVR_NAME}								IN		A		${IP4_ADDR[0]}
		 										IN		AAAA	${LNK_ADDR[0]}
		 										IN		AAAA	${IP6_ADDR[0]}
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e 's/^ //g' >> ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa
		 										IN		PTR		${WGP_NAME}.
		 										IN		A		${IP4_MASK}
		${IP4_LADR[0]}										IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e 's/^ //g' >> ${DIR_ZONE}/master/db.${LNK_RADU[0]}.ip6.arpa
		 										IN		PTR		${WGP_NAME}.
		${LNK_RADL[0]}			IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ | sed -e 's/^ //g' >> ${DIR_ZONE}/master/db.${IP6_RADU[0]}.ip6.arpa
		 										IN		PTR		${WGP_NAME}.
		${IP6_RADL[0]}			IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	if [ "${IP4_DHCP[0]}" = "auto" ]; then
		fncPrint "--- dhcp対応 $(fncString ${COL_SIZE} '-')"
		sed -i.orig ${DIR_ZONE}/master/db.${WGP_NAME}                 -e "/^${SVR_NAME}.*${IP4_ADDR[0]}$/d"
		sed -i.orig ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa -e "/^${IP4_LADR[0]}.*${SVR_NAME}\.${WGP_NAME}\.$/d"
	fi
	# --- named.conf ----------------------------------------------------------
	if [ "${DIR_BIND}" != "" ] && [ "${FIL_BIND}" != "" ] && [ -f ${DIR_BIND}/${FIL_BIND} ]; then
		fncPrint "--- ${FIL_BIND} $(fncString ${COL_SIZE} '-')"
		if [ ! -f ${DIR_BIND}/${FIL_BIND}.orig ]; then
			cp -p ${DIR_BIND}/${FIL_BIND} ${DIR_BIND}/${FIL_BIND}.orig
		fi
		cp -p ${DIR_BIND}/${FIL_BIND}.orig ${DIR_BIND}/${FIL_BIND}
		# ---------------------------------------------------------------------
		if [ "${FIL_BOPT}" != "${FIL_BIND}" ] && [ "`sed -n "/include.*${FIL_BOPT}/p" ${DIR_BIND}/${FIL_BIND}`" = "" ]; then
			INS_ROW=`sed -n '/^include/ =' ${DIR_BIND}/${FIL_BIND} | tail -n 1`
			if [ "${INS_ROW:+UNSET}" = "" ]; then INS_ROW='$ '; fi
			sed -i ${DIR_BIND}/${FIL_BIND}                            \
			    -e "${INS_ROW}a include \"${DIR_BIND}/${FIL_BOPT}\";"
		fi
		if [ "${FIL_BLOC}" != "${FIL_BIND}" ] && [ "`sed -n "/include.*${FIL_BLOC}/p" ${DIR_BIND}/${FIL_BIND}`" = "" ]; then
			INS_ROW=`sed -n '/^include/ =' ${DIR_BIND}/${FIL_BIND} | tail -n 1`
			if [ "${INS_ROW:+UNSET}" = "" ]; then INS_ROW='$ '; fi
			sed -i ${DIR_BIND}/${FIL_BIND}                            \
			    -e "${INS_ROW}a include \"${DIR_BIND}/${FIL_BLOC}\";"
		fi
	fi
	# -------------------------------------------------------------------------
	for FIL_NAME in `sed -n 's/^include "\(.*\)";$/\1/gp' ${DIR_BIND}/${FIL_BIND}`
	do
		if [ "${FIL_NAME}" != "" ] && [ ! -f ${FIL_NAME} ]; then
			fncPrint "---- make ${FIL_NAME} $(fncString ${COL_SIZE} '-')"
			cp -p ${DIR_BIND}/named.conf ${FIL_NAME}
			: > ${FIL_NAME}
		fi
	done
	# --- named.conf.options --------------------------------------------------
	if [ "${DIR_BIND}" != "" ] && [ "${FIL_BOPT}" != "" ] && [ -f ${DIR_BIND}/${FIL_BOPT} ]; then
		fncPrint "--- ${FIL_BOPT} $(fncString ${COL_SIZE} '-')"
		if [ "${FIL_BOPT}" != "${FIL_BIND}" ]; then
			if [ ! -f ${DIR_BIND}/${FIL_BOPT}.orig ]; then
				cp -p ${DIR_BIND}/${FIL_BOPT} ${DIR_BIND}/${FIL_BOPT}.orig
			fi
			cp -p ${DIR_BIND}/${FIL_BOPT}.orig ${DIR_BIND}/${FIL_BOPT}
		fi
		# ---------------------------------------------------------------------
		sed -i ${DIR_BIND}/${FIL_BOPT}    \
		    -e '/version/         s%^%//%' \
		    -e '/listen-on-v6/    s%^%//%' \
		    -e '/allow-update/    s%^%//%' \
		    -e '/allow-query/     s%^%//%' \
		    -e '/allow-transfer/  s%^%//%' \
		    -e '/allow-recursion/ s%^%//%' \
		    -e '/also-notify/     s%^%//%' \
		    -e '/notify/          s%^%//%' \
		    -e '/recursion/       s%^%//%'
		# ---------------------------------------------------------------------
		OLD_IFS=${IFS}
		# ---------------------------------------------------------------------
		INS_ROW=$((`sed -n '/^options/,/^};/ =' ${DIR_BIND}/${FIL_BOPT} | tail -n 1`-1))
		IFS= INS_STR=$(
			cat <<- _EOT_ | sed -e 's/^ //g'
				 	version "unknown";
				 	listen-on-v6    { any; };
				 	allow-update    { none; };
				 	allow-query     { localhost; ${IP4_UADR[0]}.0/${IP4_BITS[0]}; };
				 	allow-transfer  { localhost; ${IP4_UADR[0]}.0/${IP4_BITS[0]}; };
				 	allow-recursion { localhost; ${IP4_UADR[0]}.0/${IP4_BITS[0]}; };
				//	also-notify     { ; };
				//	notify yes;
				//	recursion no;
_EOT_
	)
		if [ ${INS_ROW} -ge 1 ]; then
			IFS= INS_CFG=$(echo -e ${INS_STR} | sed "${INS_ROW}r /dev/stdin" ${DIR_BIND}/${FIL_BOPT})
		else
			IFS= INS_CFG=$(echo -e ${INS_STR} | cat ${DIR_BIND}/${FIL_BOPT}) /dev/stdin
		fi
		# ---------------------------------------------------------------------
		echo ${INS_CFG} > ${DIR_BIND}/${FIL_BOPT}
		# ---------------------------------------------------------------------
#		echo ${INS_CFG} | \
#		sed -e 's/\/.*\(listen-on-v6\)/\1/g' \
#		> ${DIR_BIND}/${FIL_BOPT}
		# ---------------------------------------------------------------------
		IFS=${OLD_IFS}
		# ---------------------------------------------------------------------
#		if [ "${SYS_NAME}" = "ubuntu" ]; then
			sed -i ${DIR_BIND}/${FIL_BOPT}    \
			    -e 's/\(dnssec-validation\) auto;/\1 no;/'
#		fi
	fi
	# --- named.conf.local -----------------------------------------------------
	if [ "${DIR_BIND}" != "" ] && [ "${FIL_BLOC}" != "" ] && [ -f ${DIR_BIND}/${FIL_BLOC} ]; then
		fncPrint "--- ${FIL_BLOC} $(fncString ${COL_SIZE} '-')"
		if [ ! -f ${DIR_BIND}/${FIL_BLOC}.orig ]; then
			cp -p ${DIR_BIND}/${FIL_BLOC} ${DIR_BIND}/${FIL_BLOC}.orig
		fi
		cp -p ${DIR_BIND}/${FIL_BLOC}.orig ${DIR_BIND}/${FIL_BLOC}
		# ---------------------------------------------------------------------
		cat <<- _EOT_ >> ${DIR_BIND}/${FIL_BLOC}
			# -----------------------------------------------------------------------------
			# ${WGP_NAME}
			# -----------------------------------------------------------------------------
_EOT_
		# ---------------------------------------------------------------------
		for FIL_NAME in ${WGP_NAME} ${IP4_RADR[0]}.in-addr.arpa ${LNK_RADU[0]}.ip6.arpa ${IP6_RADU[0]}.ip6.arpa
		do
			cat <<- _EOT_ | sed -e 's/^ //g' >> ${DIR_BIND}/${FIL_BLOC}
				zone "${FIL_NAME}" {
				 	type master;
				 	file "master/db.${FIL_NAME}";
				};

_EOT_
		done
		# ---------------------------------------------------------------------
		if [ "${EXT_ADDR}" != "" ]; then
			fncPrint "--- Set Up slaves $(fncString ${COL_SIZE} '-')"
			sed -i.master ${DIR_BIND}/${FIL_BOPT}                         \
			    -e 's/^\([ |\t]*allow-query[ |\t]*\).*$/\1{ any; };/'     \
			    -e 's/^\([ |\t]*allow-transfer[ |\t]*\).*$/\1{ none; };/'
			sed -i.master ${DIR_BIND}/${FIL_BLOC}                  \
			    -e 's/^\([ |\t]*type\).*$/\1 slave;/g'             \
			    -e '/^[ |\t]*file[ |\t]*/ s/master/slaves/g'       \
			    -e "/^[ |\t]*type/a \\\tmasterfile-format text;"   \
			    -e "/^[ |\t]*type/a \\\tmasters { ${EXT_ADDR}; };"
		fi
		# ---------------------------------------------------------------------
		cat <<- _EOT_ >> ${DIR_BIND}/${FIL_BLOC}
			# -----------------------------------------------------------------------------
_EOT_
	fi
	# -------------------------------------------------------------------------
	named-checkconf
	fncPause $?
	# -------------------------------------------------------------------------
	if [ "`fncProcFind \"named\"`" = "1" ]; then
		fncProc named "${RUN_BIND[0]}"
		fncProc named "${RUN_BIND[1]}"
	fi
	if [ "`fncProcFind \"bind9\"`" = "1" ]; then
		fncProc bind9 "${RUN_BIND[0]}"
		fncProc bind9 "${RUN_BIND[1]}"
	fi

#	fncPrint "--- dns check $(fncString ${COL_SIZE} '-')"
#	dig ${SVR_NAME}.${WGP_NAME} A
#	dig ${SVR_NAME}.${WGP_NAME} AAAA
#	dig -x ${IP4_ADDR[0]}
#	dig -x ${IP6_ADDR[0]}
#	fncPrint "--- dns check $(fncString ${COL_SIZE} '-')"

	# *************************************************************************
	# Install dhcp
	# *************************************************************************
	# -------------------------------------------------------------------------
	if [ "${INF_DHCP}" != "" ]; then
		fncPrint "- Set Up dhcp $(fncString ${COL_SIZE} '-')"
		if [ "${DIR_DHCP}" != "" ] && [ "${FIL_DHCP}" != "" ] && [ -f ${DIR_DHCP}/${FIL_DHCP} ]; then
			fncPrint "--- ${FIL_DHCP} $(fncString ${COL_SIZE} '-')"
			if [ ! -f ${DIR_DHCP}/${FIL_DHCP}.orig ]; then
				cp -p ${DIR_DHCP}/${FIL_DHCP} ${DIR_DHCP}/${FIL_DHCP}.orig
			fi
			cp -p ${DIR_DHCP}/${FIL_DHCP}.orig ${DIR_DHCP}/${FIL_DHCP}
			cat <<- _EOT_ | sed -e 's/^ //g' > ${DIR_DHCP}/${FIL_DHCP}
				subnet ${IP4_NTWK[0]} netmask ${IP4_MASK[0]} {
				 	option time-servers ${NTP_NAME};
				 	option domain-name-servers ${IP4_ADDR[0]};
				 	option domain-name "${WGP_NAME}";
				 	range ${RNG_DHCP};
				 	option routers ${IP4_GATE};
				 	option subnet-mask ${IP4_MASK[0]};
				 	option broadcast-address ${IP4_BCST[0]};
				 	option netbios-dd-server ${IP4_ADDR[0]};
				 	default-lease-time 3600;
				 	max-lease-time 86400;
				}

_EOT_
		fi
		# -------------------------------------------------------------------------
		if [ -f /etc/default/isc-dhcp-server ]; then
			fncPrint "--- isc-dhcp-server $(fncString ${COL_SIZE} '-')"
			if [ ! -f /etc/default/isc-dhcp-server.orig ]; then
				cp -p /etc/default/isc-dhcp-server /etc/default/isc-dhcp-server.orig
			fi
			cp -p /etc/default/isc-dhcp-server.orig /etc/default/isc-dhcp-server
			sed -i /etc/default/isc-dhcp-server                 \
			    -e "s/^\(INTERFACESv4\)=.*$/\1=${NIC_ARRY[0]}/" \
			    -e 's/^INTERFACESv6=/#&/'
		fi
		# -------------------------------------------------------------------------
		if [ "${IP4_DHCP[0]}" = "auto" ]; then
			RUN_DHCP[0]=disable
		#	RUN_DHCP[1]=stop
		fi
		# -------------------------------------------------------------------------
		if [ "`fncProcFind \"isc-dhcp-server\"`" = "1" ]; then
			fncProc isc-dhcp-server "${RUN_DHCP[0]}"
			fncProc isc-dhcp-server "${RUN_DHCP[1]}"
		fi
		if [ "`fncProcFind \"dhcpd\"`" = "1" ]; then
			fncProc dhcpd "${RUN_DHCP[0]}"
			fncProc dhcpd "${RUN_DHCP[1]}"
		fi
		if [ "`fncProcFind \"isc-dhcp-server6\"`" = "1" ]; then
			fncProc isc-dhcp-server6 disable
		#	fncProc isc-dhcp-server6 stop
		fi
	fi

	# *************************************************************************
	# Add smb.conf
	# *************************************************************************
	# -------------------------------------------------------------------------
	if [ "${SMB_CONF}" != "" ] && [ -f ${SMB_CONF} ]; then
		fncPrint "- Set Up samba $(fncString ${COL_SIZE} '-')"
		if [ "${SMB_BACK}" != "" ] && [ ! -f ${SMB_BACK} ]; then
			cp -p ${SMB_CONF} ${SMB_BACK}
		fi
		cp -p ${SMB_BACK} ${SMB_CONF}
		# ---------------------------------------------------------------------
		CMD_UADD=`${CMD_WICH} useradd`
		CMD_UDEL=`${CMD_WICH} userdel`
		CMD_GADD=`${CMD_WICH} groupadd`
		CMD_GDEL=`${CMD_WICH} groupdel`
		CMD_GPWD=`${CMD_WICH} gpasswd`
		CMD_FALS=`${CMD_WICH} false`
		# ---------------------------------------------------------------------
		testparm -s -v ${SMB_CONF} |                                                                \
			sed -e '/\[homes\]/,/^$/ d'                                                             \
			    -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
			    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
			    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
			    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
			    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
			    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
			    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
			    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
			    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
			    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
			    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
			    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
			    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
			    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
			    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
			    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
			    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
			    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
			    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
			    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
			    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
			    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
			    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
			    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
			    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
			    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
			    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
			    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
			    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
			    -e '/map to guest =.*$/d'                                                           \
			    -e '/null passwords =.*$/d'                                                         \
			    -e '/obey pam restrictions =.*$/d'                                                  \
			    -e '/enable privileges =.*$/d'                                                      \
			    -e '/password level =.*$/d'                                                         \
			    -e '/client use spnego principal =.*$/d'                                            \
			    -e '/syslog =.*$/d'                                                                 \
			    -e '/syslog only =.*$/d'                                                            \
			    -e '/use spnego =.*$/d'                                                             \
			    -e '/paranoid server security =.*$/d'                                               \
			    -e '/dns proxy =.*$/d'                                                              \
			    -e '/time offset =.*$/d'                                                            \
			    -e '/usershare allow guests =.*$/d'                                                 \
			    -e '/idmap backend =.*$/d'                                                          \
			    -e '/idmap uid =.*$/d'                                                              \
			    -e '/idmap gid =.*$/d'                                                              \
			    -e '/winbind separator =.*$/d'                                                      \
			    -e '/acl check permissions =.*$/d'                                                  \
			    -e '/only user =.*$/d'                                                              \
			    -e '/share modes =.*$/d'                                                            \
			    -e '/nbt client socket address =.*$/d'                                              \
			    -e '/lsa over netlogon =.*$/d'                                                      \
			    -e '/.* = $/d'                                                                      \
			    -e '/client lanman auth =.*$/d'                                                     \
			    -e '/client NTLMv2 auth =.*$/d'                                                     \
			    -e '/client plaintext auth =.*$/d'                                                  \
			    -e '/client schannel =.*$/d'                                                        \
			    -e '/client use spnego principal =.*$/d'                                            \
			    -e '/client use spnego =.*$/d'                                                      \
			    -e '/domain logons =.*$/d'                                                          \
			    -e '/enable privileges =.*$/d'                                                      \
			    -e '/encrypt passwords =.*$/d'                                                      \
			    -e '/idmap backend =.*$/d'                                                          \
			    -e '/idmap gid =.*$/d'                                                              \
			    -e '/idmap uid =.*$/d'                                                              \
			    -e '/lanman auth =.*$/d'                                                            \
			    -e '/lsa over netlogon =.*$/d'                                                      \
			    -e '/nbt client socket address =.*$/d'                                              \
			    -e '/null passwords =.*$/d'                                                         \
			    -e '/raw NTLMv2 auth =.*$/d'                                                        \
			    -e '/server schannel =.*$/d'                                                        \
			    -e '/syslog =.*$/d'                                                                 \
			    -e '/syslog only =.*$/d'                                                            \
			    -e '/unicode =.*$/d'                                                                \
			    -e '/acl check permissions =.*$/d'                                                  \
			    -e '/allocation roundup size =.*$/d'                                                \
			    -e '/blocking locks =.*$/d'                                                         \
			    -e '/copy =.*$/d'                                                                   \
			    -e '/winbind separator =.*$/d'                                                      \
			    -e '/client ipc min protocol =.*$/d'                                                \
			    -e '/client min protocol =.*$/d'                                                    \
			    -e '/domain master =.*$/d'                                                          \
			    -e '/logon path =.*$/d'                                                             \
			    -e '/logon script =.*$/d'                                                           \
			    -e '/pam password change =.*$/d'                                                    \
			    -e '/preferred master =.*$/d'                                                       \
			    -e '/server role =.*$/d'                                                            \
			    -e '/wins support =.*$/d'                                                           \
		> ${SMB_WORK}
		# ---------------------------------------------------------------------
		VER_BIND=`testparm -V | awk -F '.' '/Version/ {sub(".* ",""); printf "%d.%d",$1,$2;}'`
		fncPause $?
		if [ "$(echo "${VER_BIND} < 4.0" | bc)" -eq 1 ]; then					# Ver.4.0以前
			fncPrint "--- Add SMB2 Protocol $(fncString ${COL_SIZE} '-')"
			sed -i ${SMB_WORK}                          \
			    -e 's/\(max protocol\) =.*$/\1 = SMB2/'							# SMB2対応
		fi
		# ---------------------------------------------------------------------
		cat <<- _EOT_ | sed -e 's/^ //g' >> ${SMB_WORK}
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
			 	path = ${DIR_SHAR}/data/adm/netlogon
			 	valid users = @${SMB_GRUP}
			 	write list = @${SMB_GADM}
			 	force user = ${SMB_USER}
			 	force group = ${SMB_GRUP}
			 	create mask = 0770
			 	directory mask = 0770
			 	browseable = No

			[profiles]
			 	comment = User profiles
			 	path = ${DIR_SHAR}/data/adm/profiles
			 	valid users = @${SMB_GRUP}
			 	write list = @${SMB_GRUP}
			#	profile acls = Yes
			 	browseable = No

			[share]
			 	comment = Shared directories
			 	path = ${DIR_SHAR}
			 	valid users = @${SMB_GADM}
			 	browseable = No

			[cifs]
			 	comment = CIFS directories
			 	path = ${DIR_SHAR}/cifs
			 	valid users = @${SMB_GADM}
			 	write list = @${SMB_GADM}
			 	force user = ${SMB_USER}
			 	force group = ${SMB_GRUP}
			 	create mask = 0770
			 	directory mask = 0770
			 	browseable = No

			[data]
			 	comment = Data directories
			 	path = ${DIR_SHAR}/data
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
			 	path = ${DIR_SHAR}/dlna
			 	write list = @${SMB_GRUP}
			 	force user = ${SMB_USER}
			 	force group = ${SMB_GRUP}
			 	create mask = 0770
			 	directory mask = 0770
			 	browseable = No

			[pub]
			 	comment = Public directories
			 	path = ${DIR_SHAR}/data/pub
			 	valid users = @${SMB_GRUP}

			[lusr]
			 	comment = Linux /usr directories
			 	path = /usr
			 	valid users = @${SMB_GRUP}

			[lhome]
			 	comment = Linux /home directories
			 	path = /home
			 	valid users = @${SMB_GRUP}

_EOT_
		# ---------------------------------------------------------------------
		cp -p ${SMB_CONF} ${SMB_BACK}
		testparm -s ${SMB_WORK} > ${SMB_CONF}
		fncPause $?
		# ---------------------------------------------------------------------
		case "${SYS_NAME}" in
			"debian" | \
			"ubuntu" )
				if [ -f /etc/init.d/samba ]; then
					if [ "${SYS_NAME}" = "debian" ] \
					&& [ ${SYS_VNUM} -lt 8 ] && [ ${SYS_VNUM} -ge 0 ]; then		# Debian 8以前の判定
						fncProc samba "${RUN_SMBD[0]}"
						fncProc samba "${RUN_SMBD[1]}"
					else
						fncProc smbd "${RUN_SMBD[0]}"
						fncProc nmbd "${RUN_SMBD[0]}"
						fncProc smbd "${RUN_SMBD[1]}"
						fncProc nmbd "${RUN_SMBD[1]}"
					fi
				else
					fncProc smbd "${RUN_SMBD[0]}"
					fncProc nmbd "${RUN_SMBD[0]}"
					fncProc smbd "${RUN_SMBD[1]}"
					fncProc nmbd "${RUN_SMBD[1]}"
				fi
				;;
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				fncProc smb "${RUN_SMBD[0]}"
				fncProc smb "${RUN_SMBD[1]}"
				fncProc nmb "${RUN_SMBD[0]}"
				fncProc nmb "${RUN_SMBD[1]}"
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
				fncProc smb "${RUN_SMBD[0]}"
				fncProc smb "${RUN_SMBD[1]}"
				fncProc nmb "${RUN_SMBD[0]}"
				fncProc nmb "${RUN_SMBD[1]}"
				;;
			* )
				;;
		esac
	fi

	# *************************************************************************
	# Install minidlna
	# *************************************************************************
	if [ -f /etc/minidlna.conf ]; then
		fncPrint "- Set Up minidlna $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/minidlna.conf.orig ]; then
			cp -p /etc/minidlna.conf /etc/minidlna.conf.orig
		fi
		cp -p /etc/minidlna.conf.orig /etc/minidlna.conf
		OLD_IFS=${IFS}
		IFS= INS_STR=$(
		cat <<- _EOT_ | sed ':l; N; s/\n//; b l;'
			media_dir=A,${DIR_SHAR}/dlna/sounds\\n
			media_dir=P,${DIR_SHAR}/dlna/photos\\n
			media_dir=V,${DIR_SHAR}/dlna/movies
_EOT_
		)
		IFS=${OLD_IFS}
		sed -i /etc/minidlna.conf                           \
		    -e 's/^\(media_dir\)=/#\1=/'                    \
		    -e 's/^#\(friendly_name\)=.*$/\1=Media Server/' \
		    -e 's/^#\(inotify\)=.*$/\1=yes/'                \
		    -e 's/^#\(notify_interval\)=.*$/\1=10/'         \
		    -e "/^#media_dir=/a ${INS_STR}"
		# ---------------------------------------------------------------------
		usermod -aG sambashare minidlna
		fncProc minidlna "${RUN_DLNA[0]}"
		fncProc minidlna "${RUN_DLNA[1]}"
	fi

	# *************************************************************************
	# Make User file (${DIR_WK}/addusers.txtが有ればそれを使う)
	# *************************************************************************
	fncPrint "- Make User file $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	touch ${USR_FILE}
	touch ${SMB_FILE}
	# -------------------------------------------------------------------------
	if [ "${LST_USER}" != "" ] && [ ! -f ${LST_USER} ]; then
		touch ${LST_USER}
		for I in "${USR_ARRY[@]}"
		do
			echo "$I" >> ${LST_USER}
		done
	fi
	# -------------------------------------------------------------------------
	while IFS=: read WORKNAME FULLNAME USERIDNO PASSWORD LMPASSWD NTPASSWD ACNTFLAG CHNGTIME ADMINFLG
	do
		USERNAME="${WORKNAME,,}"	# 全文字小文字変換
		if [ "${USERNAME}" != "" ]; then
			echo "${USERNAME}:${FULLNAME}:${USERIDNO}:${PASSWORD}:${ADMINFLG}"              >> ${USR_FILE}
			echo "${USERNAME}:${USERIDNO}:${LMPASSWD}:${NTPASSWD}:${ACNTFLAG}:${CHNGTIME}:" >> ${SMB_FILE}
		fi
	done < ${LST_USER}

	# *************************************************************************
	# Setup Login User
	# *************************************************************************
	fncPrint "- Set Up Login User $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	while IFS=: read WORKNAME FULLNAME USERIDNO PASSWORD ADMINFLG
	do
		USERNAME="${WORKNAME,,}"		# 全文字小文字変換
		# Account name to be checked ------------------------------------------
		RET_NAME=`awk -F ':' '$1=="'${USERNAME}'" { print $1; }' /etc/passwd`
		if [ "${RET_NAME}" != "" ]; then
			echo "[${RET_NAME}] already exists."
		else
			# Add users -------------------------------------------------------
			useradd  -b ${DIR_SHAR}/data/usr -m -c "${FULLNAME}" -G ${SMB_GRUP} -u ${USERIDNO} ${USERNAME}; fncPause $?
			${CMD_CHSH} ${USERNAME}; fncPause $?
			if [ "${ADMINFLG}" = "1" ]; then
				usermod -G ${SMB_GADM} -a ${USERNAME}; fncPause $?
			fi
			# Make user dir ---------------------------------------------------
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/app
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/dat
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/web/public_html
			touch -f ${DIR_SHAR}/data/usr/${USERNAME}/web/public_html/index.html
			# Change user dir mode --------------------------------------------
			chmod -R 770 ${DIR_SHAR}/data/usr/${USERNAME}; fncPause $?
			chown -R ${SMB_USER}:${SMB_GRUP} ${DIR_SHAR}/data/usr/${USERNAME}; fncPause $?
			if [ -d /var/lib/AccountsService/users/ ] && [ ! -f "/var/lib/AccountsService/users/${USERNAME}" ]; then
				cat <<- '_EOT_' > "/var/lib/AccountsService/users/${USERNAME}"
					[User]
					SystemAccount=true
_EOT_
			fi
		fi
	done < ${USR_FILE}
	# -------------------------------------------------------------------------
	fncPrint "--- ${SMB_GRUP} $(fncString ${COL_SIZE} '-')"
	awk -F ':' '$1=="'${SMB_GRUP}'" {print $4;}' /etc/group
	fncPrint "--- ${SMB_GADM} $(fncString ${COL_SIZE} '-')"
	awk -F ':' '$1=="'${SMB_GADM}'" {print $4;}' /etc/group
	fncPrint "$(fncString ${COL_SIZE} '-')"

	# *************************************************************************
	# Setup Samba User
	# *************************************************************************
	fncPrint "- Set Up Samba User $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	pdbedit -i smbpasswd:${SMB_FILE} -e tdbsam:${SMB_PWDB}
	fncPause $?

	# *************************************************************************
	# Cron shell (cd /usr/sh 後に tar -cz CMD*sh | xxd -ps にて出力されたもの)
	# *************************************************************************
	fncPrint "- Cron shell $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	cat <<- '_EOT_' > ${TGZ_WORK}
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
	# -------------------------------------------------------------------------
#	pushd /usr/sh > /dev/null
#		xxd -r -p ${TGZ_WORK} | tar -xz
#		fncPause $?
#		ls -al
#	popd > /dev/null

	# *************************************************************************
	# Crontab
	# *************************************************************************
#	fncPrint "- Crontab $(fncString ${COL_SIZE} '-')"
#	cat <<- _EOT_ > ${CRN_FILE}
#		SHELL = /bin/bash
#		PATH = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#		# @reboot /sbin/sysctl -p
#		0 0,3,6,9,12,15,18,21 * * * /usr/sbin/ntpdate -s ${NTP_NAME}
#		# @reboot /usr/sh/CMDMOUNT.sh
#		# @reboot /usr/sh/CMDBACKUP.sh
#		# 0 1 * * * /usr/sh/CMDFRESHCLAM.sh
#		# 0 3 * * * /usr/sh/CMDRSYNC.sh
#_EOT_
#	# -------------------------------------------------------------------------
#	crontab ${CRN_FILE}
#	fncPause $?

	# *************************************************************************
	# GRUB
	#   注)高解像度にならない場合は.vmxに以下を追加してみる。
	#     svga.minVRAMSize = 8388608
	#     svga.minVRAM8MB = TRUE
	#   計算式)
	#     MRAM = XRez * YRez * 4 / 65536
	#     VRAM = (int(MRAM) + (int(MRAM) != MRAM)) * 65536
	#     svga.minVRAMSize = VRAM
	#   例) 2560 x 2048 の場合
	#     vmotion.checkpointSVGAPrimarySize = "20971520"
	#     svga.guestBackedPrimaryAware = "TRUE"
	#     svga.minVRAMSize = "20971520"
	#     svga.minVRAM8MB = TRUE
	#     svga.autodetect = "FALSE"
	#     svga.maxWidth = "2560"
	#     svga.maxHeight = "2048"
	#     svga.vramSize = "20971520"
	# -------------------------------------------------------------------------
	#     番号 解像度：色数
	# vga=771  800×600：256色
	#     773  1024×768：256色
	#     775  1280×1024：色
	#     788  800×600：6万5000色
	#     791  1024×768：6万5000色
	#     794  1280×1024：6万5000色
	#     789  800×600：1600万色
	#     792  1024×768：1600万色
	#     795  1280×1024：1600万色
	# *************************************************************************
	if [ -f /etc/default/grub ]; then
		fncPrint "- Set Up GRUB $(fncString ${COL_SIZE} '-')"
		if [ ! -f /etc/default/grub.orig ]; then
			cp -p /etc/default/grub /etc/default/grub.orig
		fi
		cp -p /etc/default/grub.orig /etc/default/grub
		# ---------------------------------------------------------------------
		VGA_MODE=`echo ${VGA_RESO[0]} | sed -e "s/\(.*\)x\(.*\)x\(.*\)/\1x\2x\3/"`
		sed -i /etc/default/grub                             \
		    -e "\$a\\\n### User Custom ###"                  \
		    -e "\$aGRUB_GFXMODE=${VGA_MODE}"                 \
		    -e "\$aGRUB_GFXPAYLOAD_LINUX=keep"               \
		    -e "\$aGRUB_CMDLINE_LINUX_DEFAULT=quiet"         \
		    -e "\$aGRUB_RECORDFAIL_TIMEOUT=5"                \
		    -e "\$aGRUB_TIMEOUT=0"                           \
		    -e 's/[ \t][ \t]*/ /g'                           \
		    -e 's/[ \t]*$//g'
#		sed -i /etc/default/grub                             \
#		    -e '/^GRUB_TERMINAL/ s/ *console//'              \
#		    -e '/^GRUB_CMDLINE_LINUX/ s/ *rhgb//'            \
#		    -e '/^GRUB_CMDLINE_LINUX/ s/ *quiet//'           \
#		...
#		if [ "${SYS_NAME}" = "ubuntu" ]; then
#			sed -i /etc/default/grub                             \
#			    -e '/^GRUB_RECORDFAIL_TIMEOUT=/d'                \
#			    -e '/^GRUB_TIMEOUT=/a GRUB_RECORDFAIL_TIMEOUT=5'
#		fi
		case "${SYS_NAME}" in
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				sed -i /etc/default/grub                              \
				    -e '$a GRUB_FONT=\/usr\/share\/grub\/unicode.pf2'
				;;
			*              )
				;;
		esac
		# ---------------------------------------------------------------------
		case "${SYS_NAME}" in
			"debian" | \
			"ubuntu" )
					update-grub
					fncPause $?
				;;
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"almalinux"    )
					if [ -f /boot/efi/EFI/${SYS_NAME}/grub.cfg ]; then			# efi
						grub2-mkconfig -o /boot/efi/EFI/${SYS_NAME}/grub.cfg
						fncPause $?
					else														# mbr
						grub2-mkconfig -o /boot/grub2/grub.cfg
						fncPause $?
					fi
				;;
			"miraclelinux" )
					if [ -f /boot/efi/EFI/asianux/grub.cfg ]; then				# efi
						grub2-mkconfig -o /boot/efi/EFI/asianux/grub.cfg
						fncPause $?
					else														# mbr
						grub2-mkconfig -o /boot/grub2/grub.cfg
						fncPause $?
					fi
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
					if [ -f /boot/efi/EFI/${SYS_NAME}/grub.cfg ]; then			# efi
#						grub2-mkconfig -o /boot/efi/EFI/${SYS_NAME}/grub.cfg
						grub2-mkconfig -o /boot/grub2/grub.cfg
						fncPause $?
					else														# mbr
						grub2-mkconfig -o /boot/grub2/grub.cfg
						fncPause $?
					fi
				;;
			* )
				;;
		esac
	fi

	# *************************************************************************
	# Install VMware Tools
	# *************************************************************************
	if [ ${FLG_VMTL} -ne 0 ]; then
		fncPrint "- Set Up VMware Tools $(fncString ${COL_SIZE} '-')"
		# ---------------------------------------------------------------------
		case "${SYS_NAME}" in
			"debian"       | \
			"ubuntu"       | \
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				if [ "`${CMD_WICH} vmware-checkvm 2> /dev/null`" = "" ]; then
					fncPrint "--- Install VMware Tools $(fncString ${COL_SIZE} '-')"
					if [ "`${CMD_AGET/apt-get -y/apt-cache} search open-vm-tools-desktop`" = "" ]; then
						${CMD_AGET} install open-vm-tools
						fncPause $?
					else
						${CMD_AGET} install open-vm-tools open-vm-tools-desktop
						fncPause $?
					fi
				fi
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
				;;
			* )
				;;
		esac
		# ---------------------------------------------------------------------
		mkdir -p /mnt/hgfs
		# ---------------------------------------------------------------------
		if [ ! -f /etc/fstab.vmware ]; then
			if [ "`${CMD_WICH} vmhgfs-fuse 2> /dev/null`" != "" ]; then
				HGFS_FS="fuse.vmhgfs-fuse"
			else
				HGFS_FS="vmhgfs"
			fi
			# -----------------------------------------------------------------
			cp -p /etc/fstab /etc/fstab.vmware
			cat <<- _EOT_ >> /etc/fstab
				.host:/ /mnt/hgfs ${HGFS_FS} allow_other,auto_unmount,defaults 0 0
_EOT_
		fi
	fi

	# *************************************************************************
	# RAID Status
	# *************************************************************************
	if [ -f /proc/mdstat ]; then
		fncPrint "- RAID Status $(fncString ${COL_SIZE} '-')"
		# ---------------------------------------------------------------------
		fncPrint "--- cat /proc/mdstat $(fncString ${COL_SIZE} '-')"
		cat /proc/mdstat
		fncPrint "--- cat /proc/mdstat $(fncString ${COL_SIZE} '-')"
	fi

	# *************************************************************************
	# Termination
	# *************************************************************************
	fncPrint "- Termination $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	rm -f ${TGZ_WORK}
	rm -f ${CRN_FILE}
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	rm -f ${SMB_WORK}
	# --- SELinux を有効にしている場合 ----------------------------------------
#	if [ ${FLG_RHAT} -ne 0 ]; then
#		setsebool -P ftpd_full_access on										# vsftpd
#		setsebool -P samba_enable_home_dirs on									# smb
#		restorecon -R ${DIR_SHAR}
#		chcon -R -t samba_share_t ${DIR_SHAR}/
#	fi
	# -------------------------------------------------------------------------
#	systemctl -q list-unit-files -t service
#	systemctl -q -t service
	# -------------------------------------------------------------------------
	case "${SYS_NAME}" in
		"debian" | \
		"ubuntu" )
			GRP_SUDO=sudo
			;;
		"centos"       | \
		"fedora"       | \
		"rocky"        | \
		"miraclelinux" | \
		"almalinux"    )
			GRP_SUDO=wheel
			;;
		"opensuse-leap"       | \
		"opensuse-tumbleweed" )
			GRP_SUDO=wheel
			;;
		* )
			;;
	esac
	# -------------------------------------------------------------------------
	if [ "`${CMD_WICH} groupmems 2> /dev/null`" != "" ]; then
		USR_SUDO=`groupmems -l -g ${GRP_SUDO}`
	else
		USR_SUDO=`awk -F ':' -v ORS="," '$1=="'${GRP_SUDO}'" {print $4;}' /etc/group | sed -e 's/,$//'`
	fi
	# -------------------------------------------------------------------------
	OLD_CHSH=`awk -F ':' '$1=="root" {print $7;}' /etc/passwd`
	if [ "${USR_SUDO}" != "" ] && [ "`echo ${OLD_CHSH} | awk '$1~/(false|nologin)/ {print $1;}'`" = "" ]; then
		fncPrint "=== 以下のユーザーが ${GRP_SUDO} に属しています。 $(fncString ${COL_SIZE} '=')"
		echo ${USR_SUDO}
		fncPrint "$(fncString ${COL_SIZE} '=')"
		while :
		do
			echo -n "root ログインできないように変更しますか？ ('YES' or 'no') "
			set +e
			read -t 10 DUMMY
			RET_CD=$?
			set -e
			if [ ${RET_CD} -ne 0 ] && [ "${DUMMY}" = "" ]; then
				OWN_RSTA=1
				DUMMY="YES"
				echo ${DUMMY}
			fi
			case "${DUMMY}" in
				"YES" )
					${CMD_CHSH} root	# sudo usermod -s `which bash` root 等で復元
					RET_CD=$?
					NEW_CHSH=`awk -F ':' '$1=="root" {print $7;}' /etc/passwd`
					if [ ${RET_CD} -ne 0 ]; then
						echo "変更に失敗しました。: '${OLD_CHSH}'→'${NEW_CHSH}'"
						fncPrint "$(fncString ${COL_SIZE} '=')"
					else
						echo "変更を実行しました。: '${OLD_CHSH}'→'${NEW_CHSH}'"
						fncPrint "$(fncString ${COL_SIZE} '=')"
						break
					fi
					;;
				"no" )
					echo "変更を中止しました。: '${OLD_CHSH}'"
					fncPrint "$(fncString ${COL_SIZE} '=')"
					break
					;;
				* )
					;;
			esac
		done
	fi

	# *************************************************************************
	# Backup
	# *************************************************************************
	fncPrint "- Backup $(fncString ${COL_SIZE} '-')"
	# -------------------------------------------------------------------------
	pushd / > /dev/null
#		set +e
		tar -czf ${DIR_WK}/bk_boot.tgz                                                               boot           || [[ $? == 1 ]]
		tar -czf ${DIR_WK}/bk_etc.tgz                                                                etc            || [[ $? == 1 ]]
#		tar -czf ${DIR_WK}/bk_usr_sh.tgz                                                             usr/sh         || [[ $? == 1 ]]
		tar -czf ${DIR_WK}/bk_cron.tgz                                                               var/spool/cron || [[ $? == 1 ]]
		tar -czf ${DIR_WK}/bk_home.tgz   --exclude="bk_*.tgz" --exclude="*chrome*" --exclude="*.log" home           || [[ $? == 1 ]]
		# ---------------------------------------------------------------------
		case "${SYS_NAME}" in
			"debian" | \
			"ubuntu" )
				tar -czf ${DIR_WK}/bk_bind.tgz   --exclude="bk_*.tgz" var/cache/bind/ || [[ $? == 1 ]]
				;;
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				tar -czf ${DIR_WK}/bk_bind.tgz   --exclude="bk_*.tgz" var/named/ || [[ $? == 1 ]]
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
				tar -czf ${DIR_WK}/bk_bind.tgz   --exclude="bk_*.tgz" --exclude var/lib/named/dev/log var/lib/named/ || [[ $? == 1 ]]
				;;
			* )
				;;
		esac
		# ---------------------------------------------------------------------
		SIZ_SHARE=($(du -s -b /share/ | awk '{print $1;}'))
		if [ `echo "${SIZ_SHARE} < 1048576" | bc` -ge 1 ]; then
			tar -czf ${DIR_WK}/bk_share.tgz  --exclude="bk_*.tgz" share || [[ $? == 1 ]]
		fi
#		set -e
	popd > /dev/null

	fncPrint "$(fncString ${COL_SIZE} '*')"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 設定処理が終了しました。"
	echo " [ sudo reboot ] して下さい。"
	fncPrint "$(fncString ${COL_SIZE} '*')"
#	if [ ${OWN_RSTA} -ne 0 ]; then
#		reboot
#	fi
}

# Debug :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fncDebug () {
	fncInitialize
	fncPrint "- Debug mode start $(fncString ${COL_SIZE} '-')"
	echo "NOW_DATE=${NOW_DATE}"													# yyyy/mm/dd
	echo "NOW_TIME=${NOW_TIME}"													# yyyymmddhhmmss
	echo "PGM_NAME=${PGM_NAME}"													# プログラム名
	echo "WHO_AMI =${WHO_AMI}"													# 実行ユーザー名
	echo "WHO_USER=${WHO_USER[@]}"												# ログイン中ユーザ一覧
	echo "VGA_RESO=${VGA_RESO[@]}"												# コンソールの解像度：縦×横×色
	echo "DIR_SHAR=${DIR_SHAR}"													# 共有ディレクトリーのルート
#	echo "RUN_CLAM=${RUN_CLAM[@]}"												# 起動停止設定：clamav-freshclam
	echo "RUN_SSHD=${RUN_SSHD[@]}"												#   〃        ：ssh / sshd
	echo "RUN_HTTP=${RUN_HTTP[@]}"												#   〃        ：apache2 / httpd
#	echo "RUN_FTPD=${RUN_FTPD[@]}"												#   〃        ：vsftpd
	echo "RUN_BIND=${RUN_BIND[@]}"												#   〃        ：bind9 / named
	echo "RUN_DHCP=${RUN_DHCP[@]}"												#   〃        ：isc-dhcp-server / dhcpd
	echo "RUN_SMBD=${RUN_SMBD[@]}"												#   〃        ：samba / smbd,nmbd / smb,nmb
#	echo "RUN_WMIN=${RUN_WMIN[@]}"												#   〃        ：webmin
	echo "RUN_DLNA=${RUN_DLNA[@]}"												#   〃        ：minidlna
	echo "EXT_ZONE=${EXT_ZONE}"													# マスターDNSのドメイン名
	echo "EXT_ADDR=${EXT_ADDR}"													#   〃         IPアドレス
#	echo "FLG_RHAT=${FLG_RHAT}"													# CentOS時=1,その他=0
	echo "FLG_SVER=${FLG_SVER}"													# 0以外でサーバー仕様でセッティング
	echo "DEF_USER=${DEF_USER}"													# インストール時に作成したユーザー名
	echo "SYS_NAME=${SYS_NAME}"													# ディストリビューション名
	echo "SYS_CODE=${SYS_CODE}"													# コード名
	echo "SYS_VERS=${SYS_VERS}"													# バージョン名
	echo "SYS_VRID=${SYS_VRID}"													# バージョン番号
	echo "SYS_VNUM=${SYS_VNUM}"													#   〃          (取得できない場合は-1)
	echo "SYS_NOOP=${SYS_NOOP}"													# 対象OS=1,それ以外=0
	echo "SMB_USER=${SMB_USER}"													# smb.confのforce user
	echo "SMB_GRUP=${SMB_GRUP}"													# smb.confのforce group
	echo "SMB_GADM=${SMB_GADM}"													# smb.confのadmin group
#	echo "WWW_DATA=${WWW_DATA}"													# apache2 / httpdのユーザ名
	echo "CPU_TYPE=${CPU_TYPE}"													# CPU TYPE (x86_64/armv5tel/...)
	echo "SVR_FQDN=${SVR_FQDN}"													# 本機のFQDN
	echo "SVR_NAME=${SVR_NAME}"													# 本機のホスト名
	echo "WGP_NAME=${WGP_NAME}"													# ワークグループ名(ドメイン名)
	echo "ACT_NMAN=${ACT_NMAN}"													# NetworkManager起動状態
	echo "CON_NAME=${CON_NAME}"													# 接続名
	echo "CON_UUID=${CON_UUID}"													# 接続UUID
	echo "DEV_NICS=${DEV_NICS[@]}"												# NICデバイス名
	echo "NIC_ARRY=${NIC_ARRY[@]}"												# NICデバイス名
	echo "IP4_ARRY=${IP4_ARRY[@]}"												# IPv4:IPアドレス/サブネットマスク(bit)
	echo "IP6_ARRY=${IP6_ARRY[@]}"												# IPv6:IPアドレス/サブネットマスク(bit)
	echo "LNK_ARRY=${LNK_ARRY[@]}"												# Link:IPアドレス/サブネットマスク(bit)
	echo "IP4_DHCP=${IP4_DHCP[@]}"												# IPv4:DHCPフラグ(1:dhcp/0:static)
	echo "IP6_DHCP=${IP6_DHCP[@]}"												# IPv6:DHCPフラグ(1:dhcp/0:static)
	echo "IP4_DNSA=${IP4_DNSA[@]}"												# IPv4:DNSアドレス
	echo "IP6_DNSA=${IP6_DNSA[@]}"												# IPv6:DNSアドレス
	echo "IP4_GATE=${IP4_GATE}"													# IPv4:デフォルトゲートウェイ
	echo "IP4_ADDR=${IP4_ADDR[@]}"												# IPv4:IPアドレス
	echo "IP4_BITS=${IP4_BITS[@]}"												# IPv4:サブネットマスク(bit)
	echo "IP4_UADR=${IP4_UADR[@]}"												# IPv4:本機のIPアドレスの上位値(/24決め打ち)
	echo "IP4_LADR=${IP4_LADR[@]}"												# IPv4:本機のIPアドレスの下位値
	echo "IP4_LGAT=${IP4_LGAT[@]}"												# IPv4:デフォルトゲートウェイの下位値
	echo "IP4_RADR=${IP4_RADR[@]}"												# IPv4:BIND逆引き用
	echo "IP4_NTWK=${IP4_NTWK[@]}"												# IPv4:ネットワークアドレス
	echo "IP4_BCST=${IP4_BCST[@]}"												# IPv4:ブロードキャストアドレス
	echo "IP4_MASK=${IP4_MASK[@]}"												# IPv4:サブネットマスク
	echo "IP6_ADDR=${IP6_ADDR[@]}"												# IPv6:IPアドレス
	echo "IP6_BITS=${IP6_BITS[@]}"												# IPv6:サブネットマスク(bit)
	echo "IP6_CONV=${IP6_CONV[@]}"												# IPv6:補間済みアドレス
	echo "IP6_UADR=${IP6_UADR[@]}"												# IPv6:本機のIPアドレスの上位値(/64決め打ち)
	echo "IP6_LADR=${IP6_LADR[@]}"												# IPv6:本機のIPアドレスの下位値
	echo "IP6_RADU=${IP6_RADU[@]}"												# IPv6:BIND逆引き用上位値
	echo "IP6_RADL=${IP6_RADL[@]}"												# IPv6:BIND逆引き用下位値
	echo "LNK_ADDR=${LNK_ADDR[@]}"												# Link:IPアドレス
	echo "LNK_BITS=${LNK_BITS[@]}"												# Link:サブネットマスク(bit)
	echo "LNK_CONV=${LNK_CONV[@]}"												# Link:補間済みアドレス
	echo "LNK_UADR=${LNK_UADR[@]}"												# Link:本機のIPアドレスの上位値(/64決め打ち)
	echo "LNK_LADR=${LNK_LADR[@]}"												# Link:本機のIPアドレスの下位値
	echo "LNK_RADU=${LNK_RADU[@]}"												# Link:BIND逆引き用上位値
	echo "LNK_RADL=${LNK_RADL[@]}"												# Link:BIND逆引き用下位値
	echo "IP6_CDNS=${IP6_CDNS[@]}"												# IPv6:補間済みアドレス[DNS]
	echo "IP6_UDNS=${IP6_UDNS[@]}"												# IPv6:本機のIPアドレスの上位値(/64決め打ち)[DNS]
	echo "IP6_LDNS=${IP6_LDNS[@]}"												# IPv6:本機のIPアドレスの下位値[DNS]
	echo "IP6_RDNU=${IP6_RDNU[@]}"												# IPv6:BIND逆引き用上位値[DNS]
	echo "IP6_RDNL=${IP6_RDNL[@]}"												# IPv6:BIND逆引き用下位値[DNS]
	echo "RNG_DHCP=${RNG_DHCP}"													# IPv4:DHCPの提供アドレス範囲
#	echo "URL_SYS =${URL_SYS}"													# ungoogled-chromium:OS別URL
#	echo "URL_DEB =${URL_DEB}"													# ungoogled-chromium:/etc/apt/sources.list.d/home:ungoogled_chromium.list
#	echo "URL_KEY =${URL_KEY}"													# ungoogled-chromium:/etc/apt/trusted.gpg.d/home_ungoogled_chromium.gpg
#	echo "DST_NAME=${DST_NAME}"													# ワーク：
#	echo "MNT_FD  =${MNT_FD}"													#  〃   ：
#	echo "MNT_CD  =${MNT_CD}"													#  〃   ：
	echo "DEV_CD  =${DEV_CD}"													#  〃   ：
	echo "DIR_WK  =${DIR_WK}"													#  〃   ：
	echo "LST_USER=${LST_USER}"													#  〃   ：
#	echo "LOG_FILE=${LOG_FILE}"													#  〃   ：
	echo "TGZ_WORK=${TGZ_WORK}"													#  〃   ：
	echo "CRN_FILE=${CRN_FILE}"													#  〃   ：
	echo "USR_FILE=${USR_FILE}"													#  〃   ：
	echo "SMB_FILE=${SMB_FILE}"													#  〃   ：
	echo "SMB_WORK=${SMB_WORK}"													#  〃   ：
#	echo "SVR_NAME=${SVR_NAME}"													#  〃   ：
	echo "FLG_VMTL=${FLG_VMTL}"													#  〃   ：0以外でVMware Toolsをインストール
	echo "NUM_HDDS=${NUM_HDDS}"													#  〃   ：インストール先のHDD台数
	echo "DEV_HDDS=${DEV_HDDS[@]}"												#  〃   ：
	echo "HDD_ARRY=${HDD_ARRY[@]}"												#  〃   ：
	echo "USB_ARRY=${USB_ARRY[@]}"												#  〃   ：
#	echo "DEV_RATE=${DEV_RATE[@]}"												#  〃   ：
#	echo "DEV_TEMP=${DEV_TEMP[@]}"												#  〃   ：
	echo "CMD_AGET=${CMD_AGET}"													#  〃   ：
	echo "LIN_CHSH=${LIN_CHSH}"													#  〃   ：
	echo "CMD_CHSH=${CMD_CHSH}"													#  〃   ：
#	echo "FILE_USERDIRCONF=${FILE_USERDIRCONF}"									#  〃   ：
#	echo "FILE_VSFTPDCONF=${FILE_VSFTPDCONF}"									#  〃   ：
#	echo "DIR_VSFTPD=${DIR_VSFTPD}"												#  〃   ：
	echo "INF_CHRO=${INF_CHRO}"													#  〃   ：chrony
	echo "FUL_CHRO=${FUL_CHRO}"													#  〃   ：
	echo "INF_BIND=${INF_BIND}"													#  〃   ：bind
	echo "DNS_USER=${DNS_USER}"													#  〃   ：
	echo "DNS_GRUP=${DNS_GRUP}"													#  〃   ：
	echo "FUL_BIND=${FUL_BIND}"													#  〃   ：
	echo "DIR_BIND=${DIR_BIND}"													#  〃   ：
	echo "FIL_BIND=${FIL_BIND}"													#  〃   ：
	echo "FIL_BOPT=${FIL_BOPT}"													#  〃   ：
	echo "FIL_BLOC=${FIL_BLOC}"													#  〃   ：
	echo "DIR_ZONE=${DIR_ZONE}"													#  〃   ：
	echo "INF_DHCP=${INF_DHCP}"													#  〃   ：dhcpd
	echo "FUL_DHCP=${FUL_DHCP}"													#  〃   ：
	echo "DIR_DHCP=${DIR_DHCP}"													#  〃   ：
	echo "FIL_DHCP=${FIL_DHCP}"													#  〃   ：
	echo "SMB_PWDB=${SMB_PWDB}"													#  〃   ：samba
	echo "SMB_CONF=${SMB_CONF}"													#  〃   ：
	echo "SMB_BACK=${SMB_BACK}"													#  〃   ：
#	echo "SEL_WMIN=${SEL_WMIN}"													#  〃   ：webmin
#	echo "HTM_WMIN=${HTM_WMIN}"													#  〃   ：
#	echo "WEB_WMIN=${WEB_WMIN}"													#  〃   ：
#	echo "WRK_WMIN=${WRK_WMIN}"													#  〃   ：
#	echo "URL_WMIN=${URL_WMIN}"													#  〃   ：
#	echo "SET_WMIN=${SET_WMIN}"													#  〃   ：
#	echo "PKG_WMIN=${PKG_WMIN}"													#  〃   ：
	# Network Setup ***********************************************************
	if [ -f /etc/network/interfaces ]; then
		fncPrint "--- cat /etc/network/interfaces $(fncString ${COL_SIZE} '-')"
		expand -t 4 /etc/network/interfaces
		if [ -f /etc/network/interfaces.orig ]; then
			fncPrint "--- diff /etc/network/interfaces $(fncString ${COL_SIZE} '-')"
			fncDiff /etc/network/interfaces /etc/network/interfaces.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	fncPrint "--- cat /etc/hosts $(fncString ${COL_SIZE} '-')"
	expand -t 4 /etc/hosts
	if [ -f /etc/hosts.orig ]; then
		fncPrint "--- diff /etc/hosts $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/hosts /etc/hosts.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f "/etc/NetworkManager/system-connections/${CON_NAME}" ]; then
		fncPrint "--- cat /etc/NetworkManager/system-connections/${CON_NAME} $(fncString ${COL_SIZE} '-')"
		expand -t 4 "/etc/NetworkManager/system-connections/${CON_NAME}"
		if [ -f "/etc/NetworkManager/system-connections/${CON_NAME}.orig" ]; then
			fncPrint "--- diff /etc/NetworkManager/system-connections/${CON_NAME} $(fncString ${COL_SIZE} '-')"
			fncDiff "/etc/NetworkManager/system-connections/${CON_NAME}" "/etc/NetworkManager/system-connections/${CON_NAME}.orig"
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [  -f /etc/netplan/99-network-manager-static.yaml ]; then
		fncPrint "--- cat /etc/netplan/99-network-manager-static.yaml $(fncString ${COL_SIZE} '-')"
		expand -t 4 /etc/netplan/99-network-manager-static.yaml
		if [ -f /etc/netplan/99-network-manager-static.yaml.orig ]; then
			fncPrint "--- diff /etc/netplan/99-network-manager-static.yaml $(fncString ${COL_SIZE} '-')"
			fncDiff /etc/netplan/99-network-manager-static.yaml /etc/netplan/99-network-manager-static.yaml.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [  -f /etc/netplan/00-installer-config.yaml ]; then
		fncPrint "--- cat /etc/netplan/00-installer-config.yaml $(fncString ${COL_SIZE} '-')"
		expand -t 4 /etc/netplan/00-installer-config.yaml
		if [ -f /etc/netplan/00-installer-config.yaml.orig ]; then
			fncPrint "--- diff /etc/netplan/00-installer-config.yaml $(fncString ${COL_SIZE} '-')"
			fncDiff /etc/netplan/00-installer-config.yaml /etc/netplan/00-installer-config.yaml.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f /etc/resolv.conf ]; then
		fncPrint "--- cat /etc/resolv.conf $(fncString ${COL_SIZE} '-')"
		expand -t 4 /etc/resolv.conf
		if [ -f /etc/resolv.conf.orig ]; then
			fncPrint "--- diff /etc/resolv.conf $(fncString ${COL_SIZE} '-')"
			fncDiff /etc/resolv.conf /etc/resolv.conf.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	fncPrint "--- cat /etc/hosts.allow $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/hosts.allow
	if [ -f /etc/hosts.allow.orig ]; then
		fncPrint "--- diff /etc/hosts.allow $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/hosts.allow /etc/hosts.allow.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	fncPrint "--- cat /etc/hosts.deny $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/hosts.deny
	if [ -f /etc/hosts.deny.orig ]; then
		fncPrint "--- diff /etc/hosts.deny $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/hosts.deny /etc/hosts.deny.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	fncPrint "--- cat /etc/nsswitch.conf $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/nsswitch.conf
	if [ -f /etc/nsswitch.conf ] && [ -f /etc/nsswitch.conf.orig ]; then
		fncPrint "--- diff /etc/nsswitch.conf $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/nsswitch.conf /etc/nsswitch.conf.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	fncPrint "--- cat /etc/gai.conf $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/gai.conf
	if [ -f /etc/gai.conf ] && [ -f /etc/gai.conf.orig ]; then
		fncPrint "--- diff /etc/gai.conf $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/gai.conf /etc/gai.conf.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	fncPrint "--- cat /etc/avahi/avahi-daemon.conf $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/avahi/avahi-daemon.conf
	if [ -f /etc/avahi/avahi-daemon.conf ] && [ -f /etc/avahi/avahi-daemon.conf.orig ]; then
		fncPrint "--- diff /etc/avahi/avahi-daemon.conf $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/avahi/avahi-daemon.conf /etc/avahi/avahi-daemon.conf.orig
	fi
	# Install clamav **********************************************************
	FILE_FRESHCONF=`find /etc/ -name "freshclam.conf" -type f -print`
	if [ "${FILE_FRESHCONF}" != "" ]; then
		FILE_CLAMDCONF=`dirname ${FILE_FRESHCONF}`/clamd.conf
#		fncPrint "--- cat ${FILE_FRESHCONF} $(fncString ${COL_SIZE} '-')"
#		expand -t 4 ${FILE_FRESHCONF}
		if [ -f ${FILE_FRESHCONF}.orig ]; then
			fncPrint "--- diff ${FILE_FRESHCONF} $(fncString ${COL_SIZE} '-')"
			fncDiff ${FILE_FRESHCONF} ${FILE_FRESHCONF}.orig
		fi
#		if [ -f ${FILE_CLAMDCONF} ]; then
#			fncPrint "--- cat ${FILE_CLAMDCONF} $(fncString ${COL_SIZE} '-')"
#			expand -t 4 ${FILE_CLAMDCONF}
#		fi
	fi
	# Install ssh *************************************************************
#	fncPrint "--- cat /etc/ssh/sshd_config $(fncString ${COL_SIZE} '-')"
#	expand -t 4 /etc/ssh/sshd_config
	if [ -f /etc/ssh/sshd_config.orig ]; then
		fncPrint "--- diff /etc/ssh/sshd_config $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
	fi
	# Install apache2 *********************************************************
#	fncPrint "--- cat ${FILE_USERDIRCONF} $(fncString ${COL_SIZE} '-')"
#	expand -t 4 ${FILE_USERDIRCONF}
#	if [ -f ${FILE_USERDIRCONF}.orig ]; then
#		fncPrint "--- diff ${FILE_USERDIRCONF} $(fncString ${COL_SIZE} '-')"
#		fncDiff ${FILE_USERDIRCONF} ${FILE_USERDIRCONF}.orig
#	fi
	# Install vsftpd **********************************************************
#	fncPrint "--- cat ${DIR_VSFTPD}/vsftpd.conf $(fncString ${COL_SIZE} '-')"
#	expand -t 4 ${DIR_VSFTPD}/vsftpd.conf
#	if [ -f ${DIR_VSFTPD}/vsftpd.conf.orig ]; then
#		fncPrint "--- diff ${DIR_VSFTPD}/vsftpd.conf $(fncString ${COL_SIZE} '-')"
#		fncDiff ${DIR_VSFTPD}/vsftpd.conf ${DIR_VSFTPD}/vsftpd.conf.orig
#	fi
	# Install bind9 ***********************************************************
#	if [ -f ${DIR_ZONE}/master/db.${WGP_NAME}                 ]; then
#		fncPrint "--- cat ${DIR_ZONE}/master/db.${WGP_NAME} $(fncString ${COL_SIZE} '-')"
#		expand -t 4 ${DIR_ZONE}/master/db.${WGP_NAME}
#	fi
#	if [ -f ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa ]; then
#		fncPrint "--- cat ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa $(fncString ${COL_SIZE} '-')"
#		expand -t 4 ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa
#	fi
#	if [ -f ${DIR_ZONE}/master/db.${IP6_RADU[0]}.ip6.arpa     ]; then
#		fncPrint "--- cat ${DIR_ZONE}/master/db.${IP6_RADU[0]}.ip6.arpa $(fncString ${COL_SIZE} '-')"
#		expand -t 4 ${DIR_ZONE}/master/db.${IP6_RADU[0]}.ip6.arpa
#	fi
#	if [ -f ${DIR_ZONE}/master/db.${LNK_RADU[0]}.ip6.arpa     ]; then
#		fncPrint "--- cat ${DIR_ZONE}/master/db.${LNK_RADU[0]}.ip6.arpa $(fncString ${COL_SIZE} '-')"
#		expand -t 4 ${DIR_ZONE}/master/db.${LNK_RADU[0]}.ip6.arpa
#	fi
	if [ -d ${DIR_ZONE}/master ]; then
		for FILE in `find ${DIR_ZONE}/master ${DIR_ZONE}/slaves -type f -print`
		do
			if [ "file ${FILE} | grep text" = "" ]; then
				fncPrint "--- cat ${FILE} is binary $(fncString ${COL_SIZE} '-')"
			else
				fncPrint "--- cat ${FILE} $(fncString ${COL_SIZE} '-')"
				expand -t 4 ${FILE}
			fi
		done
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f ${DIR_BIND}/${FIL_BIND} ]; then
		fncPrint "--- cat ${DIR_BIND}/${FIL_BIND} $(fncString ${COL_SIZE} '-')"
		expand -t 4 ${DIR_BIND}/${FIL_BIND}
	fi
	if [ -f ${DIR_BIND}/${FIL_BIND}.orig ]; then
		fncPrint "--- diff ${DIR_BIND}/${FIL_BIND} $(fncString ${COL_SIZE} '-')"
		fncDiff ${DIR_BIND}/${FIL_BIND} ${DIR_BIND}/${FIL_BIND}.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f ${DIR_BIND}/${FIL_BIND}.local ]; then
		fncPrint "--- cat ${DIR_BIND}/${FIL_BIND}.local $(fncString ${COL_SIZE} '-')"
		expand -t 4 ${DIR_BIND}/${FIL_BIND}.local
	fi
	if [ -f ${DIR_BIND}/${FIL_BIND}.local.orig ]; then
		fncPrint "--- diff ${DIR_BIND}/${FIL_BIND}.local $(fncString ${COL_SIZE} '-')"
		fncDiff ${DIR_BIND}/${FIL_BIND}.local ${DIR_BIND}/${FIL_BIND}.local.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f ${DIR_BIND}/${FIL_BIND}.options ]; then
		fncPrint "--- cat ${DIR_BIND}/${FIL_BIND}.options $(fncString ${COL_SIZE} '-')"
		expand -t 4 ${DIR_BIND}/${FIL_BIND}.options
	fi
	if [ -f ${DIR_BIND}/${FIL_BIND}.options.orig ]; then
		fncPrint "--- diff ${DIR_BIND}/${FIL_BIND}.options $(fncString ${COL_SIZE} '-')"
		fncDiff ${DIR_BIND}/${FIL_BIND}.options ${DIR_BIND}/${FIL_BIND}.options.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	set +e
	fncPrint "--- ping check $(fncString ${COL_SIZE} '-')"
	if [ "`${CMD_WICH} ping4 2> /dev/null`" != "" ]; then
		ping4 -c 4 www.google.com
	else
		ping -4 -c 1 localhost &> /dev/null
		if [ $? -eq 0 ]; then
			ping -4 -c 4 www.google.com
		else
			ping -c 4 www.google.com
		fi
	fi
	if [ "`${CMD_WICH} ping6 2> /dev/null`" != "" ]; then
		fncPrint "$(fncString ${COL_SIZE} '･')"
		ping6 -c 4 www.google.com
	fi
	fncPrint "--- ping check $(fncString ${COL_SIZE} '-')"
	set -e
	# ･････････････････････････････････････････････････････････････････････････
	set +e
	fncPrint "--- connman chk $(fncString ${COL_SIZE} '-')"
	ss -tulpn | grep ":53"
	fncPrint "--- nslookup $(fncString ${COL_SIZE} '-')"
	nslookup ${SVR_FQDN}
	fncPrint "$(fncString ${COL_SIZE} '･')"
	nslookup ${IP4_ADDR[0]}
	fncPrint "$(fncString ${COL_SIZE} '･')"
	nslookup ${IP6_ADDR[0]}
	fncPrint "$(fncString ${COL_SIZE} '･')"
	nslookup ${LNK_ADDR[0]}
	fncPrint "--- dns check $(fncString ${COL_SIZE} '-')"
	dig @localhost ${IP4_RADR[0]}.in-addr.arpa DNSKEY +dnssec +multi
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig @localhost ${WGP_NAME} DNSKEY +dnssec +multi
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig @${IP4_ADDR[0]} ${WGP_NAME} axfr
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig @${IP6_ADDR[0]} ${WGP_NAME} axfr
#	fncPrint "$(fncString ${COL_SIZE} '･')"
#	dig @${LNK_ADDR[0]} ${WGP_NAME} axfr
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig ${SVR_FQDN} A +nostats +nocomments
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig ${SVR_FQDN} AAAA +nostats +nocomments
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig -x ${IP4_ADDR[0]} +nostats +nocomments
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig -x ${IP6_ADDR[0]} +nostats +nocomments
	fncPrint "$(fncString ${COL_SIZE} '･')"
	dig -x ${LNK_ADDR[0]} +nostats +nocomments
	fncPrint "--- dns check $(fncString ${COL_SIZE} '-')"
	set -e
	# Install dhcp ************************************************************
	if [ -f ${DIR_DHCP}/dhcpd.conf ]; then
		fncPrint "--- diff ${DIR_DHCP}/dhcpd.conf $(fncString ${COL_SIZE} '-')"
		expand -t 4 ${DIR_DHCP}/dhcpd.conf
#		fncDiff ${DIR_DHCP}/dhcpd.conf ${DIR_DHCP}/dhcpd.conf.orig
	fi
	# Install Webmin **********************************************************
	if [ -f /etc/webmin/config.orig ]; then
		fncPrint "--- diff /etc/webmin/config $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/webmin/config /etc/webmin/config.orig
	fi
	if [ -f /etc/webmin/time/config.orig ]; then
		fncPrint "--- diff /etc/webmin/time/config $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/webmin/time/config /etc/webmin/time/config.orig
	fi
	# Add smb.conf ************************************************************
	fncPrint "--- cat ${SMB_CONF} $(fncString ${COL_SIZE} '-')"
	expand -t 4 ${SMB_CONF}
	# Setup Samba User ********************************************************
	fncPrint "--- pdbedit -L $(fncString ${COL_SIZE} '-')"
	pdbedit -L
	if [ "`${CMD_WICH} smbclient 2> /dev/null`" != "" ]; then
		fncPrint "--- smbclient -N -L ${SVR_NAME} $(fncString ${COL_SIZE} '-')"
		smbclient -N -L ${SVR_NAME}
	fi
#	fncPrint "--- smbclient -N -L ${SVR_FQDN} $(fncString ${COL_SIZE} '-')"
#	smbclient -N -L ${SVR_FQDN}
	# Install minidlna ********************************************************
	if [ -f /etc/minidlna.conf.orig ]; then
		fncPrint "--- diff /etc/minidlna.conf $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/minidlna.conf /etc/minidlna.conf.orig
	fi
	# GRUB ********************************************************************
	if [ -f /etc/default/grub.orig ]; then
		fncPrint "--- diff /etc/default/grub $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/default/grub /etc/default/grub.orig
	fi
	# Install VMware Tools ****************************************************
	if [ -f /etc/fstab.vmware ]; then
		fncPrint "--- diff /etc/fstab /etc/fstab.vmware $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/fstab /etc/fstab.vmware
	fi
	# NTP *********************************************************************
	if [ -f /etc/systemd/timesyncd.conf.orig ]; then
		fncPrint "--- diff /etc/systemd/timesyncd.conf $(fncString ${COL_SIZE} '-')"
		fncDiff /etc/systemd/timesyncd.conf /etc/systemd/timesyncd.conf.orig
	fi
	if [ "`${CMD_WICH} timedatectl 2> /dev/null`" != "" ]; then
		fncPrint "--- timedatectl status $(fncString ${COL_SIZE} '-')"
		timedatectl status
		fncPrint "--- timedatectl timesync-status $(fncString ${COL_SIZE} '-')"
		set +e
		timedatectl timesync-status 2> /dev/null
		set -e
	fi
	# *************************************************************************
	fncPrint "- Debug mode end $(fncString ${COL_SIZE} '-')"
}

# Recovery ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
fncRecovery () {
	fncInitialize
#	set +e
	fncPrint "- Recovery mode start $(fncString ${COL_SIZE} '-')"
	[ -f /etc/NetworkManager/NetworkManager.conf.orig           ] && { mv /etc/NetworkManager/NetworkManager.conf.orig            /etc/NetworkManager/NetworkManager.conf          ; }
	[ -f /etc/apt/sources.list.orig                             ] && { mv /etc/apt/sources.list.orig                              /etc/apt/sources.list                            ; }
	[ -f /etc/avahi/avahi-daemon.conf.orig                      ] && { mv /etc/avahi/avahi-daemon.conf.orig                       /etc/avahi/avahi-daemon.conf                     ; }
	[ -f ${DIR_BIND}/${FIL_BLOC}.orig                           ] && { mv ${DIR_BIND}/${FIL_BLOC}.orig                            ${DIR_BIND}/${FIL_BLOC}                          ; }
	[ -f ${DIR_BIND}/${FIL_BOPT}.orig                           ] && { mv ${DIR_BIND}/${FIL_BOPT}.orig                            ${DIR_BIND}/${FIL_BOPT}                          ; }
	[ -f ${DIR_BIND}/${FIL_BIND}.orig                           ] && { mv ${DIR_BIND}/${FIL_BIND}.orig                            ${DIR_BIND}/${FIL_BIND}                          ; }
	[ -f ${FUL_CHRO}.orig                                       ] && { mv ${FUL_CHRO}.orig                                        ${FUL_CHRO}                                      ; }
	FILE_FRESHCONF=`find /etc/ -name "freshclam.conf" -type f -print`
	if [ "${FILE_FRESHCONF}" != "" ]; then
		[ -f ${FILE_FRESHCONF}.orig                                 ] && { mv ${FILE_FRESHCONF}.orig                                  ${FILE_FRESHCONF}                                ; }
	fi
	[ -f /etc/default/grub.orig                                 ] && { mv /etc/default/grub.orig                                  /etc/default/grub                                ; }
	[ -f /etc/default/isc-dhcp-server.orig                      ] && { mv /etc/default/isc-dhcp-server.orig                       /etc/default/isc-dhcp-server                     ; }
	[ -f ${DIR_DHCP}/${FIL_DHCP}.orig                           ] && { mv ${DIR_DHCP}/${FIL_DHCP}.orig                            ${DIR_DHCP}/${FIL_DHCP}                          ; }
	[ -f /etc/hosts.allow.orig                                  ] && { mv /etc/hosts.allow.orig                                   /etc/hosts.allow                                 ; }
	[ -f /etc/hosts.deny.orig                                   ] && { mv /etc/hosts.deny.orig                                    /etc/hosts.deny                                  ; }
	[ -f /etc/hosts.orig                                        ] && { mv /etc/hosts.orig                                         /etc/hosts                                       ; }
	[ -f /etc/locale.gen.orig                                   ] && { mv /etc/locale.gen.orig                                    /etc/locale.gen                                  ; }
	[ -f /etc/nsswitch.conf.orig                                ] && { mv /etc/nsswitch.conf.orig                                 /etc/nsswitch.conf                               ; }
	[ -f /etc/NetworkManager/NetworkManager.conf.orig           ] && { mv /etc/NetworkManager/NetworkManager.conf.orig            /etc/NetworkManager/NetworkManager.conf          ; }
	[ -f /etc/netplan/99-network-manager-static.yaml.orig       ] && { mv /etc/netplan/99-network-manager-static.yaml.orig        /etc/netplan/99-network-manager-static.yaml      ; }
	[ -f /etc/netplan/00-installer-config.yaml.orig             ] && { mv /etc/netplan/00-installer-config.yaml.orig              /etc/netplan/00-installer-config.yaml            ; }
	[ -f /etc/connman/main.conf.orig                            ] && { mv /etc/connman/main.conf.orig                             /etc/connman/main.conf                           ; }
	[ -f /etc/resolv.conf.orig                                  ] && { mv /etc/resolv.conf.orig                                   /etc/resolv.conf                                 ; }
	[ -f ${SMB_BACK}                                            ] && { mv ${SMB_BACK}                                             ${SMB_CONF}                                      ; }
	[ -f /etc/selinux/config.orig                               ] && { mv /etc/selinux/config.orig                                /etc/selinux/config                              ; }
	[ -f /etc/ssh/sshd_config.orig                              ] && { mv /etc/ssh/sshd_config.orig                               /etc/ssh/sshd_config                             ; }
	[ -f /etc/sysconfig/network/config.orig                     ] && { mv /etc/sysconfig/network/config.orig                      /etc/sysconfig/network/config                    ; }
	[ -f /etc/minidlna.conf.orig                                ] && { mv /etc/minidlna.conf.orig                                 /etc/minidlna.conf                               ; }
	for USER_NAME in "${USER}" "${SUDO_USER}"
	do
		USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		case "${SYS_NAME}" in
			"debian" | \
			"ubuntu" )
				LNG_FILE=".bashrc"
				;;
			"centos"       | \
			"fedora"       | \
			"rocky"        | \
			"miraclelinux" | \
			"almalinux"    )
				LNG_FILE=".i18n"
				;;
			"opensuse-leap"       | \
			"opensuse-tumbleweed" )
				LNG_FILE=".i18n"
				;;
			* )
				;;
		esac
		[ -f /root/.bash_history.orig                               ] && { mv /root/.bash_history.orig                                /root/.bash_history                              ; }
		if [ "${LNG_FILE}" != "" ]; then
			[ -f ${USER_HOME}/${LNG_FILE}.orig                                 ] && { mv ${USER_HOME}/${LNG_FILE}.orig                                  ${USER_HOME}/${LNG_FILE}                                ; }
		fi
		[ -f ${USER_HOME}/.curlrc.orig                                     ] && { mv ${USER_HOME}/.curlrc.orig                                      ${USER_HOME}/.curlrc                                    ; }
		[ -f ${USER_HOME}/.vimrc.orig                                      ] && { mv ${USER_HOME}/.vimrc.orig                                       ${USER_HOME}/.vimrc                                     ; }
		[ -f ${USER_HOME}/.virc.orig                                       ] && { mv ${USER_HOME}/.virc.orig                                        ${USER_HOME}/.virc                                      ; }
	done
	[ -f ${DIR_ZONE}/master/db.${WGP_NAME}.orig                 ] && { mv ${DIR_ZONE}/master/db.${WGP_NAME}.orig                 ${DIR_ZONE}/master/db.${WGP_NAME}                ; }
	[ -f ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa.orig ] && { mv ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa.orig ${DIR_ZONE}/master/db.${IP4_RADR[0]}.in-addr.arpa; }
	fncPrint "- Recovery mode end $(fncString ${COL_SIZE} '-')"
#	set -e
}

# Main ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
{
# *****************************************************************************
# Main処理                                                                    *
# *****************************************************************************
	# initialize --------------------------------------------------------------
	NOW_DATE=`date +"%Y/%m/%d"`													# yyyy/mm/dd
	NOW_TIME=`date +"%Y%m%d%H%M%S"`												# yyyymmddhhmmss
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`									# プログラム名

	# which command -----------------------------------------------------------
	if [ "`command -v which 2> /dev/null`" != "" ]; then
		CMD_WICH="command -v"
	else
		CMD_WICH="which"
	fi

	# terminal size -----------------------------------------------------------
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

	# Main --------------------------------------------------------------------
	case "${DBG_FLAG}" in
		"0" )	exec &> >(tee -a "${PGM_NAME}.log")
				fncMain;;				# main処理
		"d" )	fncDebug;;				# debug処理
		"r" )	fncRecovery;;			# recovery処理
		 *  )	;;
	esac

	# Exit --------------------------------------------------------------------
	exit 0
}

###############################################################################
# memo                                                                        #
###############################################################################
# sudo apt update && sudo apt -y upgrade
# -----------------------------------------------------------------------------
# <参照> http://tech.nikkeibp.co.jp/it/article/COLUMN/20060227/230881/
#==============================================================================
# End of file                                                                 =
#==============================================================================
