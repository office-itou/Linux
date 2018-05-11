#!/bin/bash
###############################################################################
##
##	ファイル名	:	install.sh
##
##	機能概要	:	Install用シェル [VMware対応]
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian 7 ～
##				:	Ubuntu 18.04 ～
##				:	CentOS 7 ～
##	---------------------------------------------------------------------------
##	<サービス>	:	clamav-freshclam / clamd
##				:	ssh / sshd
##				:	apache2 / httpd
##				:	vsftpd
##				:	bind9 / named
##				:	isc-dhcp-server / dhcpd
##				:	samba / smbd,nmbd / smb,nmb
##				:	webmin
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
##	2018/02/28 000.0000 J.Itou         IPV6対応等
##	2018/03/07 000.0000 J.Itou         cron用シェル修正
##	2018/03/10 000.0000 J.Itou         .curlrc追加
##	2018/03/12 000.0000 J.Itou         cifs関連修正
##	2018/03/20 000.0000 J.Itou         rootログインの抑制追加・他
##	2018/04/29 000.0000 J.Itou         処理見直し(CentOS 7対応含む)
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -m								# ジョブ制御を有効にする
	set -eu								# ステータス0以外と未定義変数の参照で終了

	DBG_FLAG=${@:-0}

	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 設定処理を開始します。"
	echo "*******************************************************************************"

	trap 'exit 1' 1 2 3 15

# Pause処理 -------------------------------------------------------------------
funcPause() {
	local RET_STS=$1

	if [ ${RET_STS} -ne 0 ]; then
		echo "Enterキーを押して下さい。"
		read DUMMY
	fi
}

# プロセス制御処理 ------------------------------------------------------------
funcProc() {
	local INP_NAME=$1
	local INP_COMD=$2

	if [ "${INP_COMD}" = "" ]; then
		return
	fi

	if [ "`which systemctl 2> /dev/null`" != "" ] && [ "${INP_NAME}" != "webmin" ]; then
		systemctl ${INP_COMD} ${INP_NAME}; funcPause $?
	else
		if [ -f /lib/systemd/systemd-sysv-install ] && [ "${INP_COMD}" = "enable" -o "${INP_COMD}" = "disable" ]; then
			/lib/systemd/systemd-sysv-install ${INP_COMD} ${INP_NAME}; funcPause $?
		else
			case "${INP_COMD}" in
				"enable" )	insserv -d ${INP_NAME};      funcPause $?;;
				"disable" )	insserv -r ${INP_NAME};      funcPause $?;;
				* )	/etc/init.d/${INP_NAME} ${INP_COMD}; funcPause $?;;
			esac
		fi
	fi
}

# diff拡張処理 ----------------------------------------------------------------
funcDiff () {
	set +e
	diff -y --suppress-common-lines "$1" "$2"
	local RET_CD=$?
	set -e
	if [ $RET_CD -ge 2 ]; then
		funcPause $RET_CD
		exit 1
	fi
}

# substr処理 ------------------------------------------------------------------
funcSubstr () {
	echo ${@:1:($#-2)} | \
	    awk '{for (i=1;i<=NF;i++) print substr($i,'"${@:$#-1:1}"','"${@:$#:1}"');}'
}

# addstr処理 ------------------------------------------------------------------
funcAddstr () {
	echo ${@:1:($#-1)} | \
	    awk '{for (i=1;i<=NF;i++) print $1 "'"${@:($#):1}"'";}'
}

# APTの更新可否判断 -----------------------------------------------------------
funcChkAptTime () {
	local NOW_TIME=`date +"%s"`													# 現在時刻のEpoch形式 (1970-01-01 00:00:00 UTC からの秒数)
	local LOG_TIME																# ログファイルの最終更新日時のEpoch形式 (Epoch からの秒数)
	local IVL_TIME=600															# 比較時間の秒数

	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		LOG_TIME=`stat /var/log/apt/term.log --format %Y`
	else																		# Red Hat系
		LOG_TIME=`stat /var/log/yum.log --format %Y`
	fi

	if [ $((${NOW_TIME})) -ge $((${LOG_TIME} + ${IVL_TIME})) ]; then
		echo "OK"
	else
		echo "WAIT"
	fi
}

# IPアドレス取得処理 ----------------------------------------------------------
fncGetIPaddr () {
	LANG=C ip -o -$1 a show scope $2 dev $3 | awk '{print $4;}'
}

# NetworkManager設定値取得処理 ------------------------------------------------
fncGetNM () {
	local DMY_STAT

	LANG=C nmcli c show help 2> /dev/null
	if [ $? -ge 2 ]; then
		DMY_STAT="`LANG=C nmcli dev list iface "$2" | awk '/^'"$1"'/'`"
	else
		DMY_STAT="`LANG=C nmcli con show uuid "$3" | awk '/^'"$1"'/'`"
	fi

	case "$1" in
		"DHCP4" | \
		"DHCP6" )
			if [ "${DMY_STAT}" != "" ]; then
				echo "auto"
			else
				echo "static"
			fi
			;;
		"IP4.DNS" | \
		"IP6.DNS" )
			echo "${DMY_STAT}" | awk '{print $2;}'
			;;
		* )
			echo ""
			;;
	esac
}

# IPv6逆引き処理 --------------------------------------------------------------
fncIPv6Reverse () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=($(echo ${INP_ADDR//:/} | \
		    awk '{for(i=length();i>1;i--) printf("%c.", substr($0,i,1));     \
		                                  printf("%c" , substr($0,1,1));}'))
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
		DEC_ADDR=$((0xFFFFFFFF ^ ((2 ** (32-$((${INP_ADDR}))))-1)))
		OUT_ARRY+=($(printf '%d.%d.%d.%d' \
		    $((${DEC_ADDR} >> 24)) \
		    $(((${DEC_ADDR} >> 16) & 0xFF)) \
		    $(((${DEC_ADDR} >> 8) & 0xFF)) \
		    $((${DEC_ADDR} & 0xFF))))
	done
	echo "${OUT_ARRY[@]}"
}

# 初期設定 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
funcInitialize () {
	# *************************************************************************
	# Initialize
	# *************************************************************************
	echo - Initialize ------------------------------------------------------------------
	#--------------------------------------------------------------------------
	NOW_DATE=`date +"%Y/%m/%d"`													# yyyy/mm/dd
	NOW_TIME=`date +"%Y%m%d%H%M%S"`												# yyyymmddhhmmss
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`									# プログラム名
	#--------------------------------------------------------------------------
	WHO_AMI=`whoami`															# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
	#--------------------------------------------------------------------------
	WHO_USER=`who | awk -v ORS="," '$1!="root" {print $1;}' | sed -e 's/,$//'`	# ログイン中ユーザ一覧
	if [ "${WHO_USER}" != "" ]; then
		echo "以下のユーザーがログインしています。"
		echo "[${WHO_USER}]"
#		echo "全てのユーザーをログアウトしてから、"
#		echo "rootユーザーで実行して下さい。"
#		exit 1
	fi
	# ユーザー環境に合わせて変更する部分 --------------------------------------
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
	RUN_CLAM=("enable"  "")														# 起動停止設定：clamav-freshclam
	RUN_SSHD=("enable"  "")														#   〃        ：ssh / sshd
	RUN_HTTP=("disable"  "")													#   〃        ：apache2 / httpd
	RUN_FTPD=("disable"  "")													#   〃        ：vsftpd
	RUN_BIND=("enable"  "")														#   〃        ：bind9 / named
	RUN_DHCP=("disable"  "")													#   〃        ：isc-dhcp-server / dhcpd
	RUN_SMBD=("enable"  "")														#   〃        ：samba / smbd,nmbd / smb,nmb
	RUN_WMIN=("disable"  "")													#   〃        ：webmin
	# -------------------------------------------------------------------------
	FLG_RHAT=`[ ! -f /etc/redhat-release ]; echo $?`							# CentOS時=1,その他=0
	FLG_SVER=1																	# 0以外でサーバー仕様でセッティング
	DEF_USER="${SUDO_USER}"														# インストール時に作成したユーザー名
	# system info -------------------------------------------------------------
	SYS_NAME=`awk -F '=' '$1=="ID" {gsub("\"",""); print $2;}' /etc/os-release`	# ディストリビューション名
	SYS_VRID=`awk -F '=' '$1=="VERSION_ID" { print $2; }' /etc/os-release`		# バージョン番号
	SYS_VNUM=`echo ${SYS_VRID:--1} | bc`										#   〃          (取得できない場合は-1)
	# samba -------------------------------------------------------------------
	SMB_USER=sambauser															# smb.confのforce user
	SMB_GRUP=sambashare															# smb.confのforce group
	SMB_GADM=sambaadmin															# smb.confのadmin group
	# apache2 / httpd ---------------------------------------------------------
	WWW_DATA=www-data															# apach2 / httpdのユーザ名
	# cpu type ----------------------------------------------------------------
	CPU_TYPE=`LANG=C lscpu | awk '/Architecture:/ {print $2;}'`					# CPU TYPE (x86_64/armv5tel/...)
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
	CON_NAME=`nmcli -t -f name c | head -n 1`									# 接続名
	CON_UUID=`nmcli -t -f uuid c | head -n 1`									# 接続UUID
	# ･････････････････････････････････････････････････････････････････････････
	NIC_ARRY=(`LANG=C ip -o link show | awk -F '[: ]*' '!/lo:/ {print $2;}'`)	# NICデバイス名
	for DEV_NAME in ${NIC_ARRY[@]}
	do
		IP4_ARRY+=(`fncGetIPaddr 4 "global primary"  "${DEV_NAME}"`)			# IPv4:IPアドレス/サブネットマスク(bit)
		IP6_ARRY+=(`fncGetIPaddr 6 "global primary"  "${DEV_NAME}"`)			# IPv6:IPアドレス/サブネットマスク(bit)
		LNK_ARRY+=(`fncGetIPaddr 6 "link"            "${DEV_NAME}"`)			# Link:IPアドレス/サブネットマスク(bit)
		IP4_DHCP+=(`fncGetNM "DHCP4"   "${DEV_NAME}" "${CON_UUID}"`)			# IPv4:DHCPフラグ(auto/static)
		IP6_DHCP+=(`fncGetNM "DHCP6"   "${DEV_NAME}" "${CON_UUID}"`)			# IPv6:DHCPフラグ(auto/static)
		IP4_DNSA+=(`fncGetNM "IP4.DNS" "${DEV_NAME}" "${CON_UUID}"`)			# IPv4:DNSアドレス
		IP6_DNSA+=(`fncGetNM "IP6.DNS" "${DEV_NAME}" "${CON_UUID}"`)			# IPv6:DNSアドレス
	done
	IP4_GATE=`ip -4 r show table all | awk '/default/ {print $3;}'`				# IPv4:デフォルトゲートウェイ
	# ･････････････････････････････････････････････････････････････････････････
	IP4_ADDR=("${IP4_ARRY[@]%/*}")												# IPv4:IPアドレス
	IP4_BITS=("${IP4_ARRY[@]#*/}")												# IPv4:サブネットマスク(bit)
	IP6_ADDR=("${IP6_ARRY[@]%/*}")												# IPv6:IPアドレス
	IP6_BITS=("${IP6_ARRY[@]#*/}")												# IPv6:サブネットマスク(bit)
	LNK_ADDR=("${LNK_ARRY[@]%/*}")												# Link:IPアドレス
	LNK_BITS=("${LNK_ARRY[@]#*/}")												# Link:サブネットマスク(bit)
	# ･････････････････････････････････････････････････････････････････････････
	IP4_UADR=("${IP4_ADDR[@]%.*}")												# IPv4:本機のIPアドレスの上位値(/24決め打ち)
	IP4_LADR=("${IP4_ADDR[@]##*.}")												# IPv4:本機のIPアドレスの下位値
	IP4_LGAT=`echo ${IP4_GATE} | awk -F '.' '{print $4;}'`						# IPv4:デフォルトゲートウェイの下位値
	IP4_RADR=(`echo ${IP4_ADDR[@]}|awk -F '.' '{printf"%s.%s.%s", $3,$2,$1;}'`)	# IPv4:BIND(逆引き用
	IP4_NTWK=(`funcAddstr "${IP4_UADR[@]}"   ".0"`)								# IPv4:ネットワークアドレス
	IP4_BCST=(`funcAddstr "${IP4_UADR[@]}" ".255"`)								# IPv4:ブロードキャストアドレス
	IP4_MASK=(`fncIPv4GetNetmask "${IP4_BITS[@]}"`)								# IPv4:サブネットマスク
	# ･････････････････････････････････････････････････････････････････････････
	IP6_CONV=(`fncIPv6Conv "${IP6_ADDR[@]}"`)									# IPv6:補間済みアドレス
	LNK_CONV=(`fncIPv6Conv "${LNK_ADDR[@]}"`)									# Link:補間済みアドレス
	IP6_UADR=(`funcSubstr "${IP6_CONV[@]}"  1 19`)								# IPv6:本機のIPアドレスの上位値(/64決め打ち)
	IP6_LADR=(`funcSubstr "${IP6_CONV[@]}" 21 19`)								# IPv6:本機のIPアドレスの下位値
	LNK_UADR=(`funcSubstr "${LNK_CONV[@]}"  1 19`)								# Link:本機のIPアドレスの上位値(/64決め打ち)
	LNK_LADR=(`funcSubstr "${LNK_CONV[@]}" 21 19`)								# Link:本機のIPアドレスの下位値
	IP6_RADU=(`fncIPv6Reverse "${IP6_UADR[@]}"`)								# IPv6:BIND逆引き用上位値
	IP6_RADL=(`fncIPv6Reverse "${IP6_LADR[@]}"`)								# IPv6:BIND逆引き用下位値
	LNK_RADU=(`fncIPv6Reverse "${LNK_UADR[@]}"`)								# Link:BIND逆引き用上位値
	LNK_RADL=(`fncIPv6Reverse "${LNK_LADR[@]}"`)								# Link:BIND逆引き用下位値
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
#	DST_NAME=`awk '/[A-Za-z]./ {print $1;}' /etc/issue | head -n 1 | tr '[A-Z]' '[a-z]'`
	# -------------------------------------------------------------------------
#	MNT_FD=/media/floppy0
#	MNT_CD=/media/cdrom0
	MNT_CD=/media
	DEV_CD=/dev/sr0
	# -------------------------------------------------------------------------
	DIR_WK=${PWD}
	LST_USER=${DIR_WK}/addusers.txt
#	LOG_FILE=${DIR_WK}/${PGM_NAME}.sh.${NOW_TIME}.log
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
	NUM_HDDS=`ls -l /dev/[hs]d[a-z] | wc -l`									# インストール先のHDD台数
	DEV_ARRY=("/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde" "/dev/sdf" "/dev/sdg" "/dev/sdh")
	HDD_ARRY=(${DEV_ARRY[@]:0:${NUM_HDDS}})
	USB_ARRY=(${DEV_ARRY[@]:${NUM_HDDS}:${#DEV_ARRY[@]}-${NUM_HDDS}})
#	DEV_RATE="${USB_ARRY[@]}"
#	DEV_TEMP="${HDD_ARRY[@]} ${DEV_RATE}"
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		if [ "`which apt 2> /dev/null`" != "" ]; then
			CMD_AGET="apt -y -qq"
		else																	# Debian 7
			CMD_AGET="aptitude -y -q"
		fi
	else																		# Red Hat系
		CMD_AGET="yum -y -q"
	fi
	# -------------------------------------------------------------------------
	LIN_CHSH=`which nologin`
	if [ "`which usermod 2> /dev/null`" != "" ]; then
		CMD_CHSH="`which usermod` -s ${LIN_CHSH}"
	else
		CMD_CHSH="`which chsh` -s ${LIN_CHSH}"
	fi
	# -------------------------------------------------------------------------
	FILE_USERDIRCONF=`find /etc -name "userdir.conf" -type f -print`
	if [ "${FILE_USERDIRCONF}" = "" ]; then
		a2enmod userdir; funcPause $?
		FILE_USERDIRCONF=`find /etc -name "userdir.conf" -type f -print`
	fi
	# -------------------------------------------------------------------------
	FILE_VSFTPDCONF=`find /etc -name "vsftpd.conf" -type f -print`
	DIR_VSFTPD=`dirname ${FILE_VSFTPDCONF}`
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		DIR_BIND=/etc/bind
		DIR_ZONE=/var/cache/bind
	else																		# Red Hat系
		DIR_BIND=/etc
		DIR_ZONE=/var/named
	fi
	# -------------------------------------------------------------------------
	pdbedit -L > /dev/null
	funcPause $?
	SMB_PWDB=`find /var/lib/samba/ -name passdb.tdb -type f -print`
	SMB_CONF=`find /etc -name "smb.conf" -type f -print`
	SMB_BACK=${SMB_CONF}.orig
	# -------------------------------------------------------------------------
	VER_WMIN=1.881						# 最新バージョンを設定
	VER_WMIN=""							# カレントバージョンを取得 (たまに接続エラーになるので注意)
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		if [ "${VER_WMIN}" = "" ]; then
			SET_WMIN="webmin-current.deb"
			URL_WMIN="http://www.webmin.com/download/deb/${SET_WMIN}"
		else
			SET_WMIN="webmin_${VER_WMIN}_all.deb"
			URL_WMIN="https://prdownloads.sourceforge.net/webadmin/${SET_WMIN}"
		fi
	else																		# Red Hat系
		if [ "${VER_WMIN}" = "" ]; then
			SET_WMIN="webmin-current.rpm"
			URL_WMIN="http://www.webmin.com/download/rpm/${SET_WMIN}"
		else
			SET_WMIN="webmin-${VER_WMIN}-1.noarch.rpm"
			URL_WMIN="https://prdownloads.sourceforge.net/webadmin/${SET_WMIN}"
		fi
	fi
}

# Main処理 ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
funcMain () {
	# *************************************************************************
	# 事前ダウンロード
	# *************************************************************************
	echo - Download --------------------------------------------------------------------
	while [ ! -f "${DIR_WK}/${SET_WMIN}" ]
	do
		wget -nv "${URL_WMIN}"
		funcPause $?
		sleep 1s
	done

	# *************************************************************************
	# Make work dir
	# *************************************************************************
	echo - Make work dir ---------------------------------------------------------------
	# -------------------------------------------------------------------------
	chmod 700 ${DIR_WK}

	# *************************************************************************
	# System Update
	# *************************************************************************
	echo - System Update ---------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ] && [ ! -f /etc/apt/sources.list.orig ]; then		# 非Red Hat系
		sed -i.orig /etc/apt/sources.list \
		    -e 's/^deb cdrom.*$/# &/'
	fi
	# --- パッケージ更新 ------------------------------------------------------
#	if [ "`funcChkAptTime`" = "OK" ]; then										# APTの更新可否判断
		echo --- Package Update ------------------------------------------------------------
		${CMD_AGET} update ; funcPause $?
		echo --- Package Upgrade -----------------------------------------------------------
		${CMD_AGET} upgrade; funcPause $?
		# --- リポジトリを追加 	[ Red Hat系 ] ---------------------------------
		if [ ${FLG_RHAT} -ne 0 ] && [ ! -f /etc/yum.repos.d/CentOS-Base.repo.orig ]; then
			echo --- Install Repository [yum-plugin-priorities] --------------------------------
			${CMD_AGET} install yum-plugin-priorities; funcPause $?
			sed -i.orig -e "s/\]$/\]\npriority=1/g"  /etc/yum.repos.d/CentOS-Base.repo
			# ---------------------------------------------------------------------
			echo --- Install Repository [epel-release centos-release-scl-rh] -------------------
			${CMD_AGET} install epel-release centos-release-scl-rh; funcPause $?
			sed -i.orig -e "s/\]$/\]\npriority=5/g"  /etc/yum.repos.d/epel.repo
			# ---------------------------------------------------------------------
			echo --- Install Repository [centos-release-scl] -----------------------------------
			${CMD_AGET} install centos-release-scl; funcPause $?
			sed -i.orig -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo
			sed -i.orig -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
			# ---------------------------------------------------------------------
			echo --- Install Repository [remi-release-7.rpm] -----------------------------------
			${CMD_AGET} install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm; funcPause $?
			sed -i.orig -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/remi-safe.repo
		fi
#	fi
	# -------------------------------------------------------------------------
#	echo --- Package Cleaning ----------------------------------------------------------
#	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
#		${CMD_AGET} autoclean; funcPause $?
#	else																		# Red Hat系
#		${CMD_AGET} autoremove; funcPause $?
#	fi
	# --- 自動起動設定 	[ Red Hat系 ] -----------------------------------------
#	if [ ${FLG_RHAT} -ne 0 ]; then
#		systemctl enable named dhcpd smb vsftpd httpd
#		funcPause $?
#		# --- 	Firewalld を有効にしている場合 --------------------------------
#		firewall-cmd --add-service=dns   --permanent		# named
#		firewall-cmd --add-service=dhcp  --permanent		# dhcpd
#		firewall-cmd --add-service=samba --permanent		# smb
#		firewall-cmd --add-service=ftp   --permanent		# vsftpd
#		firewall-cmd --add-service=http  --permanent		# httpd
#		firewall-cmd --reload
#	fi

	# *************************************************************************
	# Locale Setup
	# *************************************************************************
	echo - Locale Setup ----------------------------------------------------------------
	# --- /etc/locale.gen -----------------------------------------------------
	if [ -f /etc/locale.gen ] && [ ! -f /etc/locale.gen.orig ]; then
		sed -i.orig /etc/locale.gen             \
		    -e "s/^# \(${SET_LANG} UTF-8\)/\1/"
		locale-gen; funcPause $?
		update-locale LANG=${SET_LANG}; funcPause $?
	fi
	# -------------------------------------------------------------------------
#	if [ ! -f /etc/locale.conf.orig ]; then
#		locale > /etc/locale.conf
#		sed -i.orig /etc/locale.conf                \
#		    -e "s/\(LANG\)=\S.*$/\1=${SET_LANG}/"   \
#		    -e "s/\(LC_.*\)=\S.*$/\1=${SET_LANG}/g"
#	fi
	#--------------------------------------------------------------------------
	for USER_NAME in "${USER}" "${SUDO_USER}"
	do
		USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		pushd ${USER_HOME} > /dev/null
			if [ ${FLG_RHAT} -eq 0 ]; then										# 非Red Hat系
				LNG_FILE=".bashrc"
			else																# Red Hat系
				LNG_FILE=".i18n"
			fi
			[ ! -f .vimrc      ] && { touch .vimrc;      chown "${USER_NAME}":"${USER_NAME}" .vimrc;      }
			[ ! -f .curlrc     ] && { touch .curlrc;     chown "${USER_NAME}":"${USER_NAME}" .curlrc;     }
			[ ! -f ${LNG_FILE} ] && { touch ${LNG_FILE}; chown "${USER_NAME}":"${USER_NAME}" ${LNG_FILE}; }
			# -----------------------------------------------------------------
			if [ ! -f .vimrc.orig ]; then
				echo --- .vimrc --------------------------------------------------------------------
				cp -p .vimrc .vimrc.orig
				cat <<- _EOT_ >> .vimrc
					set number
					set tabstop=4
					set list
					set listchars=tab:\>_
_EOT_
			fi
			# -----------------------------------------------------------------
			if [ ! -f .curlrc.orig ]; then
				echo --- .curlrc -------------------------------------------------------------------
				cp -p .curlrc .curlrc.orig
				cat <<- _EOT_ >> .curlrc
					location
					progress-bar
					remote-time
					show-error
_EOT_
			fi
			# -----------------------------------------------------------------
			if [ ! -f ${LNG_FILE}.orig ]; then
				echo --- ${LNG_FILE} -------------------------------------------------------------------
				cp -p ${LNG_FILE} ${LNG_FILE}.orig
				cat <<- _EOT_ >> ${LNG_FILE}
					# --- 日本語文字化け対策 ---
					case "\${TERM}" in
					    "linux" ) export LANG=C;;
					    * )                      ;;
					esac
_EOT_
			fi
			# -----------------------------------------------------------------
#			if [ -f .profile ]; then
#				. .profile
#			fi
		popd > /dev/null
	done
	#--------------------------------------------------------------------------

	# *************************************************************************
	# Network Setup
	# *************************************************************************
	echo - Network Setup ---------------------------------------------------------------
	# hosts.allow -------------------------------------------------------------
	if [ ! -f /etc/hosts.allow.orig ]; then
		cp -p /etc/hosts.allow /etc/hosts.allow.orig
		cat <<- _EOT_ >> /etc/hosts.allow
			ALL : 127.0.0.1
			ALL : [::1]
			# ALL : 169.254.0.0/16
			ALL : [fe80::]/${LNK_BITS[0]}
			ALL : ${IP4_UADR[0]}.0/${IP4_BITS[0]}
			# ALL : [${IP6_UADR[0]}::]/${IP6_BITS[0]}
_EOT_
	fi
	# hosts.deny --------------------------------------------------------------
	if [ ! -f /etc/hosts.deny.orig ]; then
		cp -p /etc/hosts.deny /etc/hosts.deny.orig
		cat <<- _EOT_ >> /etc/hosts.deny
			ALL : ALL
_EOT_
	fi
	# nsswitch.conf -----------------------------------------------------------
	if [ ! -f /etc/nsswitch.conf.orig ]; then
		sed -i.orig /etc/nsswitch.conf                            \
		    -e 's/^hosts:.*/# &\nhosts:          files wins dns/'
	fi
	# ipv6 disable ------------------------------------------------------------
#	if [ ! -f /etc/sysctl.conf.orig ]; then
#		sed -i.orig /etc/sysctl.conf                  \
#		    -e '$anet.ipv6.conf.all.disable_ipv6 = 1'
#		sysctl -p
#	fi
	# ipv4 dns changed --------------------------------------------------------
	if [ "${SYS_NAME}" = "debian" ] \
	&& [ ${SYS_VNUM} -lt 8 -a ${SYS_VNUM} -ge 0 ]; then							# Debian 8以前の判定
		if [ -f "/etc/NetworkManager/system-connections/${CON_NAME}" ]; then
			if [ "${IP4_DHCP[0]}" == "auto" ]; then
				if [ ! -f "/etc/dhcp/dhclient.conf.orig" ]; then
					sed -i.orig /etc/dhcp/dhclient.conf                           \
					    -e 's/^#\(prepend domain-name-servers\).*$/\1 127.0.0.1;/'
				fi
			else
				if [ ! -h /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.orig ]; then
					cp -p /etc/resolv.conf /etc/resolv.conf.orig
				fi
				if [ ! -f "/etc/NetworkManager/system-connections/${CON_NAME}.orig" ]; then
					sed -i.orig "/etc/NetworkManager/system-connections/${CON_NAME}"              \
					    -e "/^\[ipv4\]/,/^dns=${IP4_DNSA[0]}/s/\(dns\)=${IP4_DNSA[0]}/\1=127\.0\.0\.1/"
				fi
			fi
		else
			if [ ! -h /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.orig ]; then
				sed -i.orig /etc/resolv.conf                            \
				    -e "s/\(nameserver\) ${IP4_DNSA[0]}/\1 127\.0\.0\.1/g"
			fi
		fi
	else
		nmcli c modify "${CON_UUID}" ipv4.dns 127.0.0.1
	fi
	#--------------------------------------------------------------------------
#	funcProc NetworkManager "${RUN_CLAM[0]}"
#	funcProc NetworkManager "${RUN_CLAM[1]}"
	#--------------------------------------------------------------------------
	if [ "${SYS_NAME}" = "ubuntu" ]; then										# Ubuntuの判定
		funcProc systemd-resolved disable										# nameserver 127.0.0.53 の無効化
	fi

	# *************************************************************************
	# Make share dir
	# *************************************************************************
	echo - Make share dir --------------------------------------------------------------
	# -------------------------------------------------------------------------
	RET_GADM=`awk -F ':' '$1=="'${SMB_GADM}'" { print $1; }' /etc/group`
	if [ "${RET_GADM}" = "" ]; then
		groupadd --system "${SMB_GADM}"
		funcPause $?
	fi
	# -------------------------------------------------------------------------
	RET_GRUP=`awk -F ':' '$1=="'${SMB_GRUP}'" { print $1; }' /etc/group`
	if [ "${RET_GRUP}" = "" ]; then
		groupadd --system "${SMB_GRUP}"
		funcPause $?
	fi
	# -------------------------------------------------------------------------
	RET_USER=`awk -F ':' '$1=="'${SMB_USER}'" { print $1; }' /etc/passwd`
	if [ "${RET_USER}" = "" ]; then
		useradd --system "${SMB_USER}" --groups "${SMB_GRUP}"
		funcPause $?
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
	echo - Make usb dir ----------------------------------------------------------------
	# -------------------------------------------------------------------------
	mkdir -p /mnt/usb1
	mkdir -p /mnt/usb2
	mkdir -p /mnt/usb3
	mkdir -p /mnt/usb4

	# *************************************************************************
	# Make shell dir
	# *************************************************************************
	echo - Make shell dir --------------------------------------------------------------
	# -------------------------------------------------------------------------
	mkdir -p /usr/sh
	mkdir -p /var/log/sh
	# -------------------------------------------------------------------------
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
		##	2018/03/20 000.0000 J.Itou         処理見直し
		##	${NOW_DATE} 000.0000 J.Itou         自動作成
		##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
		##	---------- -------- -------------- ----------------------------------------
		###############################################################################

		#------------------------------------------------------------------------------
		# ユーザー変数定義
		#------------------------------------------------------------------------------

		# USBデバイス変数定義
		APL_MNT_DV1="${USB_ARRY[0]}1"
		APL_MNT_DV2="${USB_ARRY[1]}1"
		APL_MNT_DV3="${USB_ARRY[2]}1"
		APL_MNT_DV4="${USB_ARRY[3]}1"

		# USBデバイス変数定義
		APL_MNT_LN1="/mnt/usb1"
		APL_MNT_LN2="/mnt/usb2"
		APL_MNT_LN3="/mnt/usb3"
		APL_MNT_LN4="/mnt/usb4"

		SYS_MNT_DV1="/sys/block/`echo ${USB_ARRY[0]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV2="/sys/block/`echo ${USB_ARRY[1]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV3="/sys/block/`echo ${USB_ARRY[2]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
		SYS_MNT_DV4="/sys/block/`echo ${USB_ARRY[3]} | awk -F '/' '{print $3}'`/device/scsi_disk/*/cache_type"
_EOT_

	# *************************************************************************
	# Install clamav
	# *************************************************************************
	echo - Install clamav --------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ "`which freshclam 2> /dev/null`" = "" ]; then							# Install clamav
		${CMD_AGET} install clamav clamav-update clamav-scanner-systemd
		funcPause $?
	fi
	# -------------------------------------------------------------------------
	FILE_FRESHCONF=`find /etc -name "freshclam.conf" -type f -print`
	FILE_CLAMDCONF=`dirname ${FILE_FRESHCONF}`/clamd.conf
	# -------------------------------------------------------------------------
	if [ ! -f ${FILE_CLAMDCONF} ]; then
		cp -p ${FILE_FRESHCONF} ${FILE_CLAMDCONF}
		: > ${FILE_CLAMDCONF}
	fi
	# -------------------------------------------------------------------------
	if [ ! -f ${FILE_FRESHCONF}.orig ]; then
		sed -i.orig ${FILE_FRESHCONF}                                        \
		    -e 's/^Example/#&/'                                              \
		    -e 's/\(# Check for new database\) 24 \(times a day\)/\1 12 \2/' \
		    -e 's/\(Checks\) 24/\1 12/'                                      \
		    -e 's/^NotifyClamd/#&/'
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		if [ "${CPU_TYPE}" = "armv5tel" ]; then
			funcProc clamav-freshclam disable
			funcProc clamav-freshclam stop
		else
			funcProc clamav-freshclam "${RUN_CLAM[0]}"
			funcProc clamav-freshclam "${RUN_CLAM[1]}"
		fi
#	else																		# Red Hat系
#		funcProc clamd "${RUN_CLAM[0]}"
#		funcProc clamd "${RUN_CLAM[1]}"
	fi

	#--------------------------------------------------------------------------
	# Install ssh
	#--------------------------------------------------------------------------
	echo - Install ssh -----------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ ! -f /etc/ssh/sshd_config.orig ]; then
		sed -i.orig /etc/ssh/sshd_config           \
		    -e 's/^\(PermitRootLogin\) .*/\1 no/'  \
		    -e 's/^#\(PermitRootLogin\) .*/\1 no/' \
		    -e '$a UseDNS no'
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		funcProc ssh "${RUN_SSHD[0]}"
		funcProc ssh "${RUN_SSHD[1]}"
	else																		# Red Hat系
		funcProc sshd "${RUN_SSHD[0]}"
		funcProc sshd "${RUN_SSHD[1]}"
	fi

	# *************************************************************************
	# Install apache2
	# *************************************************************************
	echo - Install apache2 -------------------------------------------------------------
	# -------------------------------------------------------------------------
#	adduser ${WWW-DATA} ${SMB_GRUP}		# webにユーザーディレクトリーを開放する
#	deluser ${WWW-DATA} ${SMB_GRUP}		# webにユーザーディレクトリーを開放しない
	# -------------------------------------------------------------------------
	if [ ! -f ${FILE_USERDIRCONF}.orig ]; then
		cp -p ${FILE_USERDIRCONF} ${FILE_USERDIRCONF}.orig
		cat <<- _EOT_ > ${FILE_USERDIRCONF}
			<IfModule mod_userdir.c>
			 	UserDir web/public_html
			 	UserDir disabled root

			 	<Directory ${DIR_SHAR}/data/usr/*/web/public_html>
			 		AllowOverride FileInfo AuthConfig Limit Indexes
			 		Options MultiViews Indexes SymLinksIfOwnerMatch IncludesNoExec
			 		<Limit GET POST OPTIONS>
			 			Order allow,deny
			 			Allow from all
			 			Require all granted
			 		</Limit>
			 		<LimitExcept GET POST OPTIONS>
			 			Order deny,allow
			 			Deny from all
			 			Require all granted
			 		</LimitExcept>
			 	</Directory>
			</IfModule>
_EOT_
	fi
	# -------------------------------------------------------------------------
	if [ "`which httpd 2> /dev/null`" != "" ]; then
		VER_BIND=`httpd -v | awk -F '.' '/version/ {sub(".*Apache/",""); printf "%d.%d",$1,$2;}'`
		funcPause $?
	else
		VER_BIND=`apache2ctl -v | awk -F '.' '/version/ {sub(".*Apache/",""); printf "%d.%d",$1,$2;}'`
		funcPause $?
	fi
	if [ "$(echo "${VER_BIND} >= 2.4" | bc)" -eq 1 ]; then						# Ver.2.4以降
		sed -i ${FILE_USERDIRCONF}   \
		    -e '/Order allow,deny/d' \
		    -e '/Allow from all/d'   \
		    -e '/Order deny,allow/d' \
		    -e '/Deny from all/d'
	else																		# Ver.2.4以前
		sed -i ${FILE_USERDIRCONF}      \
		    -e '/Require all granted/d'
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		funcProc apache2 "${RUN_HTTP[0]}"
		funcProc apache2 "${RUN_HTTP[1]}"
	else																		# Red Hat系
		funcProc httpd "${RUN_HTTP[0]}"
		funcProc httpd "${RUN_HTTP[1]}"
	fi

	# *************************************************************************
	# Install vsftpd
	# *************************************************************************
	echo - Install vsftpd --------------------------------------------------------------
	# -------------------------------------------------------------------------
	touch ${DIR_VSFTPD}/vsftpd.chroot_list		# chrootを許可するユーザーのリスト
	touch ${DIR_VSFTPD}/vsftpd.user_list		# 接続拒否するユーザーのリスト
	touch ${DIR_VSFTPD}/vsftpd.banned_emails	# 接続拒否する電子メール・パスワードのリスト
	touch ${DIR_VSFTPD}/vsftpd.email_passwords	# 匿名ログイン用の電子メール・パスワードのリスト
	# -------------------------------------------------------------------------
	chmod 0600 ${DIR_VSFTPD}/vsftpd.chroot_list     \
			   ${DIR_VSFTPD}/vsftpd.user_list       \
			   ${DIR_VSFTPD}/vsftpd.banned_emails   \
			   ${DIR_VSFTPD}/vsftpd.email_passwords
	# -------------------------------------------------------------------------
	if [ ! -f ${DIR_VSFTPD}/vsftpd.conf.orig ]; then
		sed -i.orig ${DIR_VSFTPD}/vsftpd.conf                                      \
		    -e 's/^\(listen\)=.*$/\1=YES/'                                         \
		    -e 's/^\(listen_ipv6\)=.*$/\1=NO/'                                     \
		    -e 's/^\(anonymous_enable\)=.*$/\1=NO/'                                \
		    -e 's/^\(local_enable\)=.*$/\1=YES/'                                   \
		    -e 's/^#\(write_enable\)=.*$/\1=YES/'                                  \
		    -e 's/^#\(local_umask\)=.*$/\1=022/'                                   \
		    -e 's/^\(dirmessage_enable\)=.*$/\1=NO/'                               \
		    -e 's/^\(use_localtime\)=.*$/\1=YES/'                                  \
		    -e 's/^\(xferlog_enable\)=.*$/\1=YES/'                                 \
		    -e 's/^\(connect_from_port_20\)=.*$/\1=YES/'                           \
		    -e 's/^#\(xferlog_std_format\)=.*$/\1=NO/'                             \
		    -e 's/^#\(idle_session_timeout\)=.*$/\1=300/'                          \
		    -e 's/^#\(data_connection_timeout\)=.*$/\1=30/'                        \
		    -e 's/^#\(ascii_upload_enable\)=.*$/\1=YES/'                           \
		    -e 's/^#\(ascii_download_enable\)=.*$/\1=YES/'                         \
		    -e 's/^#\(chroot_local_user\)=.*$/\1=NO/'                              \
		    -e 's/^#\(chroot_list_enable\)=.*$/\1=NO/'                             \
		    -e "s~^#\(chroot_list_file\)=.*$~\1=${DIR_VSFTPD}/vsftpd.chroot_list~" \
		    -e 's/^#\(ls_recurse_enable\)=.*$/\1=YES/'                             \
		    -e 's/^\(pam_service_name\)=.*$/\1=vsftpd/'                            \
		    -e '$atcp_wrappers=YES'                                                \
		    -e '$auserlist_enable=YES'                                             \
		    -e '$auserlist_deny=YES'                                               \
		    -e "\$auserlist_file=${DIR_VSFTPD}\/vsftpd.user_list"                  \
		    -e '$achmod_enable=YES'                                                \
		    -e '$aforce_dot_files=YES'                                             \
		    -e '$adownload_enable=YES'                                             \
		    -e '$avsftpd_log_file=\/var\/log\/vsftpd\.log'                         \
		    -e '$adual_log_enable=NO'                                              \
		    -e '$asyslog_enable=NO'                                                \
		    -e '$alog_ftp_protocol=NO'                                             \
		    -e '$aftp_data_port=20'                                                \
		    -e '$apasv_enable=YES'
	fi
	# -------------------------------------------------------------------------
	funcProc vsftpd "${RUN_FTPD[0]}"
	funcProc vsftpd "${RUN_FTPD[1]}"

	# *************************************************************************
	# Install bind9
	# *************************************************************************
	echo - Install bind9 ---------------------------------------------------------------
	# -------------------------------------------------------------------------
	DNS_SCNT="`date +"%Y%m%d"`01"
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > ${DIR_ZONE}/${WGP_NAME}.zone
		\$TTL 1H																; 1 hour
		@										IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 														${DNS_SCNT}	; serial
		 														30M			; refresh (30 minutes)
		 														15M			; retry (15 minutes)
		 														1D			; expire (1 day)
		 														20M			; minimum (20 minutes)
		 												)
		@										IN		NS		${SVR_NAME}.${WGP_NAME}.
		${SVR_NAME}								IN		A		${IP4_ADDR[0]}
		${SVR_NAME}								IN		AAAA	${IP6_ADDR[0]}
		${SVR_NAME}								IN		AAAA	${LNK_ADDR[0]}
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > ${DIR_ZONE}/${WGP_NAME}.rev
		\$TTL 1H																; 1 hour
		@										IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 														${DNS_SCNT}	; serial
		 														30M			; refresh (30 minutes)
		 														15M			; retry (15 minutes)
		 														1D			; expire (1 day)
		 														20M			; minimum (20 minutes)
		 												)
		@										IN		NS		${SVR_NAME}.${WGP_NAME}.
		${IP4_LADR[0]}										IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > ${DIR_ZONE}/${IP6_UADR[0]}.rev
		\$TTL 1H																; 1 hour
		@										IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 														${DNS_SCNT}	; serial
		 														30M			; refresh (30 minutes)
		 														15M			; retry (15 minutes)
		 														1D			; expire (1 day)
		 														20M			; minimum (20 minutes)
		 												)
		@										IN		NS		${SVR_NAME}.${WGP_NAME}.
		${IP6_RADL[0]}			IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	cat <<- _EOT_ > ${DIR_ZONE}/${LNK_UADR[0]}.rev
		\$TTL 1H																; 1 hour
		@										IN		SOA		${SVR_NAME}.${WGP_NAME}. root.${WGP_NAME}. (
		 														${DNS_SCNT}	; serial
		 														30M			; refresh (30 minutes)
		 														15M			; retry (15 minutes)
		 														1D			; expire (1 day)
		 														20M			; minimum (20 minutes)
		 												)
		@										IN		NS		${SVR_NAME}.${WGP_NAME}.
		${LNK_RADL[0]}			IN		PTR		${SVR_NAME}.${WGP_NAME}.
_EOT_
	#--------------------------------------------------------------------------
	if [ ! -f ${DIR_BIND}/named.conf.local.orig ]; then
		if [ ! -f ${DIR_BIND}/named.conf.local ]; then
			cp -p ${DIR_BIND}/named.conf ${DIR_BIND}/named.conf.local
			: > ${DIR_BIND}/named.conf.local
			sed -i.orig ${DIR_BIND}/named.conf \
			    -e "/include \"\/etc\/named\.rfc1912\.zones\";/i\include \"${DIR_BIND}\/named\.conf\.local\";"
		fi
		# ---------------------------------------------------------------------
		cp -p ${DIR_BIND}/named.conf.local ${DIR_BIND}/named.conf.local.orig
		# ---------------------------------------------------------------------
		cat <<- _EOT_ >> ${DIR_BIND}/named.conf.local
			acl ${WGP_NAME}-net {
			 	127.0.0.1;
			 	::1;
			 	// 169.254.0.0/16;
			 	fe80::0/${LNK_BITS[0]};
			 	${IP4_NTWK[0]}/${IP4_BITS[0]};
			};

			zone "${WGP_NAME}" {
			 	type master;
			 	file "${WGP_NAME}.zone";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${IP4_RADR[0]}.in-addr.arpa" {
			 	type master;
			 	file "${WGP_NAME}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${IP6_RADU[0]}.ip6.arpa." {
			 	type master;
			 	file "${IP6_UADR[0]}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};

			zone "${LNK_RADU[0]}.ip6.arpa." {
			 	type master;
			 	file "${LNK_UADR[0]}.rev";
			 	allow-update { ${WGP_NAME}-net; };
			};
_EOT_
	fi
	#--------------------------------------------------------------------------
	if [ "${IP4_DHCP[0]}" = "auto" ]; then
		sed -i.orig ${DIR_ZONE}/${WGP_NAME}.zone -e "/^${SVR_NAME}.*${IP4_ADDR[0]}$/d"
		sed -i.orig ${DIR_ZONE}/${WGP_NAME}.rev  -e "/^${IP4_LADR[0]}.*${SVR_NAME}\.${WGP_NAME}\.$/d"
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		funcProc bind9 "${RUN_BIND[0]}"
		funcProc bind9 "${RUN_BIND[1]}"
	else																		# Red Hat系
		funcProc named "${RUN_BIND[0]}"
		funcProc named "${RUN_BIND[1]}"
	fi

#	echo --- dns check -----------------------------------------------------------------
#	dig ${SVR_NAME}.${WGP_NAME} A
#	dig ${SVR_NAME}.${WGP_NAME} AAAA
#	dig -x ${IP4_ADDR[0]}
#	dig -x ${IP6_ADDR[0]}
#	echo --- dns check -----------------------------------------------------------------

	# *************************************************************************
	# Install dhcp
	# *************************************************************************
	echo - Install dhcp ----------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ ! -f /etc/dhcp/dhcpd.conf.orig ]; then
		cp -p /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig
		cat <<- _EOT_ > /etc/dhcp/dhcpd.conf
			subnet ${IP4_NTWK[0]} netmask ${IP4_MASK[0]} {
			 	option time-servers ntp.nict.jp;
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
	if [ -f /etc/default/isc-dhcp-server ] && [ ! -f /etc/default/isc-dhcp-server.orig ]; then
		sed -i.orig /etc/default/isc-dhcp-server     \
		    -e "s/^\(INTERFACESv4\)=.*$/\1=${NIC_ARRY[0]}/" \
		    -e 's/^INTERFACESv6=/#&/'
	fi
	# -------------------------------------------------------------------------
	if [ "${IP4_DHCP[0]}" = "auto" ]; then
		RUN_DHCP[0]=disable
#		RUN_DHCP[1]=stop
	fi
	 # ------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		funcProc isc-dhcp-server "${RUN_DHCP[0]}"
		funcProc isc-dhcp-server "${RUN_DHCP[1]}"
		if [ "${SYS_NAME}" != "debian" ] || [ ${SYS_VNUM} -eq 8 ]; then			# Debian 8のみ判定
			funcProc isc-dhcp-server6 disable
#			funcProc isc-dhcp-server6 stop
		fi
	else																		# Red Hat系
		funcProc dhcpd "${RUN_DHCP[0]}"
		funcProc dhcpd "${RUN_DHCP[1]}"
	fi

	# *************************************************************************
	# Install Webmin
	# *************************************************************************
	echo - Install Webmin --------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ ! -d /etc/webmin ]; then
		if [ -f "${DIR_WK}/${SET_WMIN}" ]; then
			if [ ${FLG_RHAT} -eq 0 ]; then										# 非Red Hat系
				dpkg -i "${DIR_WK}/${SET_WMIN}"
				funcPause $?
			else																# Red Hat系
				${CMD_AGET} install "${DIR_WK}/${SET_WMIN}"
				funcPause $?
			fi
		fi
	fi
	#--------------------------------------------------------------------------
	if [ -f /etc/webmin/config ]; then
		if [ ! -f /etc/webmin/config.orig ]; then
			cp -p /etc/webmin/config /etc/webmin/config.orig
			cat <<- _EOT_ >> /etc/webmin/config
				webprefix=
				lang_root=${SET_LANG}
_EOT_
		fi
		#----------------------------------------------------------------------
		if [ ! -f /etc/webmin/time/config.orig ]; then
			cp -p /etc/webmin/time/config /etc/webmin/time/config.orig
			cat <<- _EOT_ >> /etc/webmin/time/config
				timeserver=ntp.nict.jp
_EOT_
		fi
		#----------------------------------------------------------------------
		funcProc webmin "${RUN_WMIN[0]}"
		funcProc webmin "${RUN_WMIN[1]}"
		PSW_WMIN=`find /usr/ -name "changepass.pl" -print`
		echo "==============================================================================="
		echo "===  webminはrootのパスワードを設定しないと利用できません。                 ==="
		echo "===  rootのパスワードを一時的に設定し、                                     ==="
		echo "===    webminにログイン後に以下のコマンドで変更して下さい。                 ==="
		echo "===      ${PSW_WMIN} ログインアカウント パスワード      ==="
		echo "==============================================================================="
	fi

	# *************************************************************************
	# Add smb.conf
	# *************************************************************************
	echo - Add smb.conf ----------------------------------------------------------------
	# -------------------------------------------------------------------------
	if [ ! -f ${SMB_BACK} ]; then
		CMD_UADD=`which useradd`
		CMD_UDEL=`which userdel`
		CMD_GADD=`which groupadd`
		CMD_GDEL=`which groupdel`
		CMD_GPWD=`which gpasswd`
		CMD_FALS=`which false`
		# ---------------------------------------------------------------------
		testparm -s -v ${SMB_CONF} |                                                                \
			sed -e '/\[homes\]/,/^$/d'                                                              \
			    -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
			    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
			    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
			    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
			    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
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
			    -e 's/\(os level\) =.*$/\1 = 35/'                                                   \
			    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
			    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
			    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
			    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
			    -e '/idmap config \* : backend =/i\\tidmap config \* : range = 1000-10000'          \
			    -e 's/\(admin users\) =.*$/\1 = administrator/'                                     \
			    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
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
		> ${SMB_WORK}
		# ---------------------------------------------------------------------
		cat <<- _EOT_ >> ${SMB_WORK}
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
			 	profile acls = Yes
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

_EOT_
		# ---------------------------------------------------------------------
		cp -p ${SMB_CONF} ${SMB_BACK}
		testparm -s ${SMB_WORK} > ${SMB_CONF}
		funcPause $?
	fi
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		if [ -f /etc/init.d/samba ]; then
			if [ "${SYS_NAME}" = "debian" ] \
			&& [ ${SYS_VNUM} -lt 8 -a ${SYS_VNUM} -ge 0 ]; then					# Debian 8以前の判定
				funcProc samba "${RUN_SMBD[0]}"
			else
				funcProc smbd "${RUN_SMBD[0]}"
				funcProc nmbd "${RUN_SMBD[0]}"
			fi
			funcProc samba "${RUN_SMBD[1]}"
		else
			funcProc smbd "${RUN_SMBD[0]}"
			funcProc nmbd "${RUN_SMBD[0]}"
			funcProc smbd "${RUN_SMBD[1]}"
			funcProc nmbd "${RUN_SMBD[1]}"
		fi
	else																		# Red Hat系
		funcProc smb "${RUN_SMBD[0]}"
		funcProc smb "${RUN_SMBD[1]}"
		funcProc nmb "${RUN_SMBD[0]}"
		funcProc nmb "${RUN_SMBD[1]}"
	fi

	# *************************************************************************
	# Make User file (${DIR_WK}/addusers.txtが有ればそれを使う)
	# *************************************************************************
	echo - Make User file --------------------------------------------------------------
	# -------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	touch ${USR_FILE}
	touch ${SMB_FILE}
	# -------------------------------------------------------------------------
	if [ ! -f ${LST_USER} ]; then
		# Make User List File (sample) ----------------------------------------
		cat <<- _EOT_ > ${USR_FILE}
			Administrator:Administrator:1001::1
_EOT_
		# Make Samba User List File (pdbedit -L -w にて出力) (sample) ---------
		# administrator's password="password"
		cat <<- _EOT_ > ${SMB_FILE}
			administrator:1001:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-5A90A998:
_EOT_
	else
		while IFS=: read WORKNAME FULLNAME USERIDNO PASSWORD LMPASSWD NTPASSWD ACNTFLAG CHNGTIME ADMINFLG
		do
			USERNAME="${WORKNAME,,}"	# 全文字小文字変換
			if [ "${USERNAME}" != "" ]; then
				echo "${USERNAME}:${FULLNAME}:${USERIDNO}:${PASSWORD}:${ADMINFLG}"              >> ${USR_FILE}
				echo "${USERNAME}:${USERIDNO}:${LMPASSWD}:${NTPASSWD}:${ACNTFLAG}:${CHNGTIME}:" >> ${SMB_FILE}
			fi
		done < ${LST_USER}
	fi

	# *************************************************************************
	# Setup Login User
	# *************************************************************************
	echo - Setup Login User ------------------------------------------------------------
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
			useradd  -b ${DIR_SHAR}/data/usr -m -c "${FULLNAME}" -G ${SMB_GRUP} -u ${USERIDNO} ${USERNAME}; funcPause $?
			${CMD_CHSH} ${USERNAME}; funcPause $?
			if [ "${ADMINFLG}" = "1" ]; then
				usermod -G ${SMB_GADM} -a ${USERNAME}; funcPause $?
			fi
			# Make user dir ---------------------------------------------------
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/app
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/dat
			mkdir -p ${DIR_SHAR}/data/usr/${USERNAME}/web/public_html
			touch -f ${DIR_SHAR}/data/usr/${USERNAME}/web/public_html/index.html
			# Change user dir mode --------------------------------------------
			chmod -R 770 ${DIR_SHAR}/data/usr/${USERNAME}; funcPause $?
			chown -R ${SMB_USER}:${SMB_GRUP} ${DIR_SHAR}/data/usr/${USERNAME}; funcPause $?
		fi
	done < ${USR_FILE}
	# -------------------------------------------------------------------------
	echo --- ${SMB_GRUP} ---------------------------------------------------------------
	awk -F ':' '$1=="'${SMB_GRUP}'" {print $4;}' /etc/group
	echo --- ${SMB_GADM} ---------------------------------------------------------------
	awk -F ':' '$1=="'${SMB_GADM}'" {print $4;}' /etc/group
	echo ------------------------------------------------------------------------------

	# *************************************************************************
	# Setup Samba User
	# *************************************************************************
	echo - Setup Samba User ------------------------------------------------------------
	# -------------------------------------------------------------------------
	pdbedit -i smbpasswd:${SMB_FILE} -e tdbsam:${SMB_PWDB}
	funcPause $?

	# *************************************************************************
	# Cron shell (cd /usr/sh 後に tar -cz CMD*sh | xxd -ps にて出力されたもの)
	# *************************************************************************
	echo - Cron shell ------------------------------------------------------------------
	# -------------------------------------------------------------------------
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
	# -------------------------------------------------------------------------
	pushd /usr/sh > /dev/null
		xxd -r -p ${TGZ_WORK} | tar -xz
		funcPause $?
		ls -al
	popd > /dev/null

	# *************************************************************************
	# Crontab
	# *************************************************************************
	echo - Crontab ---------------------------------------------------------------------
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
	# -------------------------------------------------------------------------
	crontab ${CRN_FILE}
	funcPause $?

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
	if [ -f /etc/default/grub ] && [ ! -f /etc/default/grub.orig ]; then
		echo - GRUB ------------------------------------------------------------------------
		if [ ${FLG_RHAT} -eq 0 ]; then											# 非Red Hat系
			sed -i.orig /etc/default/grub                                                             \
			    -e 's/^GRUB_CMDLINE_LINUX_DEFAULT/#&/'                                                \
			    -e "s/#\(GRUB_GFXMODE\)=.*$/GRUB_GFXPAYLOAD_LINUX=${VGA_RESO[0]}\n\1=${VGA_RESO[0]}/"
			# -----------------------------------------------------------------
			update-grub
			funcPause $?
		else																	# Red Hat系
			sed -i.orig /etc/default/grub                    \
			    -e '/^GRUB_TERMINAL_OUTPUT/ s/console//'     \
			    -e '/^GRUB_CMDLINE_LINUX/ s/ rhgb quiet//'   \
			    -e "\$aGRUB_GFXPAYLOAD_LINUX=${VGA_RESO[0]}" \
			    -e "\$aGRUB_GFXMODE=${VGA_RESO[0]}"
			# -----------------------------------------------------------------
			if [ -f /boot/efi/EFI/centos/grub.cfg ]; then						# efi
				grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				funcPause $?
			else																# mbr
				grub2-mkconfig -o /boot/grub2/grub.cfg
				funcPause $?
			fi
		fi
	fi

	# *************************************************************************
	# Install VMware Tools
	# *************************************************************************
	if [ ${FLG_VMTL} -ne 0 ]; then
		echo - Install VMware Tools --------------------------------------------------------
		# ---------------------------------------------------------------------
		if [ "`which vmware-checkvm 2> /dev/null`" = "" ]; then
			if [ "`${CMD_AGET} search open-vm-tools-desktop`" = "" ]; then
				${CMD_AGET} install open-vm-tools
				funcPause $?
			else
				${CMD_AGET} install open-vm-tools open-vm-tools-desktop
				funcPause $?
			fi
		fi
		# ---------------------------------------------------------------------
		mkdir -p /mnt/hgfs
		# ---------------------------------------------------------------------
		if [ ! -f /etc/fstab.vmware ]; then
			if [ "`which vmhgfs-fuse 2> /dev/null`" != "" ]; then
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
		echo - RAID Status -----------------------------------------------------------------
		# ---------------------------------------------------------------------
		echo --- cat /proc/mdstat ----------------------------------------------------------
		cat /proc/mdstat
		echo --- cat /proc/mdstat ----------------------------------------------------------
	fi

	# *************************************************************************
	# Termination
	# *************************************************************************
	echo - Termination -----------------------------------------------------------------
	# -------------------------------------------------------------------------
	rm -f ${TGZ_WORK}
	rm -f ${CRN_FILE}
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	rm -f ${SMB_WORK}
	# --- SELinux を有効にしている場合 ----------------------------------------
	if [ ${FLG_RHAT} -ne 0 ]; then
		setsebool -P ftpd_full_access on										# vsftpd
		setsebool -P samba_enable_home_dirs on									# smb
#		restorecon -R ${DIR_SHAR}
		chcon -R -t samba_share_t ${DIR_SHAR}/
	fi
	# -------------------------------------------------------------------------
#	systemctl list-unit-files -t service
#	systemctl -t service
	# -------------------------------------------------------------------------
	if [ ${FLG_RHAT} -eq 0 ]; then												# 非Red Hat系
		GRP_SUDO=sudo
	else																		# Red Hat系
		GRP_SUDO=wheel
	fi
	# -------------------------------------------------------------------------
	if [ "`which groupmems 2> /dev/null`" != "" ]; then
		USR_SUDO=`groupmems -l -g ${GRP_SUDO}`
	else
		USR_SUDO=`awk -F ':' -v ORS="," '$1=="'${GRP_SUDO}'" {print $4;}' /etc/group | sed -e 's/,$//'`
	fi
	# -------------------------------------------------------------------------
	if [ "${USR_SUDO}" != "" ]; then
		echo "=== 以下のユーザーが ${GRP_SUDO} に属しています。 ===================================="
		echo ${USR_SUDO}
		echo "==============================================================================="
		while :
		do
			echo -n "root ログインできないように変更しますか？ ('YES' or 'no') "
			read DUMMY
			case "${DUMMY}" in
				"YES" )
					${CMD_CHSH} root
					if [ $? -ne 0 ]; then
						echo "変更に失敗しました。"
						echo "==============================================================================="
					else
						echo "変更を実行しました。"
						echo "==============================================================================="
						break
					fi
					;;
				"no" )
					echo "変更を中止しました。"
					echo "==============================================================================="
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
	echo - Backup ----------------------------------------------------------------------
	# -------------------------------------------------------------------------
	pushd / > /dev/null
		set +e
		tar -czf ${DIR_WK}/bk_boot.tgz   --exclude "bk_*.tgz" boot
		tar -czf ${DIR_WK}/bk_etc.tgz    --exclude "bk_*.tgz" etc
		tar -czf ${DIR_WK}/bk_home.tgz   --exclude "bk_*.tgz" home
		tar -czf ${DIR_WK}/bk_share.tgz  --exclude "bk_*.tgz" share
		tar -czf ${DIR_WK}/bk_usr_sh.tgz --exclude "bk_*.tgz" usr/sh
		# ---------------------------------------------------------------------
		if [ ${FLG_RHAT} -eq 0 ]; then											# 非Red Hat系
			tar -czf ${DIR_WK}/bk_bind.tgz   --exclude "bk_*.tgz" var/cache/bind/
			tar -czf ${DIR_WK}/bk_cron.tgz   --exclude "bk_*.tgz" var/spool/cron/crontabs
		else																	# Red Hat系
			tar -czf ${DIR_WK}/bk_bind.tgz   --exclude "bk_*.tgz" var/named/
			tar -czf ${DIR_WK}/bk_cron.tgz   --exclude "bk_*.tgz" var/spool/cron/root
		fi
		set -e
	popd > /dev/null
}

# Debug :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
funcDebug () {
	echo - Debug mode ------------------------------------------------------------------
	echo "NOW_DATE=${NOW_DATE}"													# yyyy/mm/dd
	echo "NOW_TIME=${NOW_TIME}"													# yyyymmddhhmmss
	echo "PGM_NAME=${PGM_NAME}"													# プログラム名
	echo "WHO_AMI =${WHO_AMI}"													# 実行ユーザー名
	echo "WHO_USER=${WHO_USER[@]}"												# ログイン中ユーザ一覧
	echo "VGA_RESO=${VGA_RESO[@]}"												# コンソールの解像度：縦×横×色
	echo "DIR_SHAR=${DIR_SHAR}"													# 共有ディレクトリーのルート
	echo "RUN_CLAM=${RUN_CLAM[@]}"												# 起動停止設定：clamav-freshclam
	echo "RUN_SSHD=${RUN_SSHD[@]}"												#   〃        ：ssh / sshd
	echo "RUN_HTTP=${RUN_HTTP[@]}"												#   〃        ：apache2 / httpd
	echo "RUN_FTPD=${RUN_FTPD[@]}"												#   〃        ：vsftpd
	echo "RUN_BIND=${RUN_BIND[@]}"												#   〃        ：bind9 / named
	echo "RUN_DHCP=${RUN_DHCP[@]}"												#   〃        ：isc-dhcp-server / dhcpd
	echo "RUN_SMBD=${RUN_SMBD[@]}"												#   〃        ：samba / smbd,nmbd / smb,nmb
	echo "RUN_WMIN=${RUN_WMIN[@]}"												#   〃        ：webmin
	echo "FLG_RHAT=${FLG_RHAT}"													# CentOS時=1,その他=0
	echo "FLG_SVER=${FLG_SVER}"													# 0以外でサーバー仕様でセッティング
	echo "DEF_USER=${DEF_USER}"													# インストール時に作成したユーザー名
	echo "SYS_NAME=${SYS_NAME}"													# ディストリビューション名
	echo "SYS_VRID=${SYS_VRID}"													# バージョン番号
	echo "SYS_VNUM=${SYS_VNUM}"													#   〃          (取得できない場合は-1)
	echo "SMB_USER=${SMB_USER}"													# smb.confのforce user
	echo "SMB_GRUP=${SMB_GRUP}"													# smb.confのforce group
	echo "SMB_GADM=${SMB_GADM}"													# smb.confのadmin group
	echo "WWW_DATA=${WWW_DATA}"													# apach2 / httpdのユーザ名
	echo "CPU_TYPE=${CPU_TYPE}"													# CPU TYPE (x86_64/armv5tel/...)
	echo "SVR_FQDN=${SVR_FQDN}"													# 本機のFQDN
	echo "SVR_NAME=${SVR_NAME}"													# 本機のホスト名
	echo "WGP_NAME=${WGP_NAME}"													# ワークグループ名(ドメイン名)
	echo "CON_NAME=${CON_NAME}"													# 接続名
	echo "CON_UUID=${CON_UUID}"													# 接続UUID
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
	echo "RNG_DHCP=${RNG_DHCP}"													# IPv4:DHCPの提供アドレス範囲
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
	echo "DEV_ARRY=${DEV_ARRY[@]}"												#  〃   ：
	echo "HDD_ARRY=${HDD_ARRY[@]}"												#  〃   ：
	echo "USB_ARRY=${USB_ARRY[@]}"												#  〃   ：
#	echo "DEV_RATE=${DEV_RATE[@]}"												#  〃   ：
#	echo "DEV_TEMP=${DEV_TEMP[@]}"												#  〃   ：
	echo "CMD_AGET=${CMD_AGET}"													#  〃   ：
	echo "LIN_CHSH=${LIN_CHSH}"													#  〃   ：
	echo "CMD_CHSH=${CMD_CHSH}"													#  〃   ：
	echo "FILE_USERDIRCONF=${FILE_USERDIRCONF}"									#  〃   ：
	echo "FILE_VSFTPDCONF=${FILE_VSFTPDCONF}"									#  〃   ：
	echo "DIR_VSFTPD=${DIR_VSFTPD}"												#  〃   ：
	echo "DIR_BIND=${DIR_BIND}"													#  〃   ：
	echo "DIR_ZONE=${DIR_ZONE}"													#  〃   ：
	echo "SMB_PWDB=${SMB_PWDB}"													#  〃   ：
	echo "SMB_CONF=${SMB_CONF}"													#  〃   ：
	echo "SMB_BACK=${SMB_BACK}"													#  〃   ：
	echo "VER_WMIN=${VER_WMIN}"													#  〃   ：最新Ver.またはカレントのファイル名
	echo "SET_WMIN=${SET_WMIN}"													#  〃   ：
	echo "URL_WMIN=${URL_WMIN}"													#  〃   ：
	# Network Setup ***********************************************************
	if [ -f /etc/network/interfaces ]; then
		echo --- cat /etc/network/interfaces -----------------------------------------------
		expand -t 4 /etc/network/interfaces
		if [ -f /etc/network/interfaces.orig ]; then
			echo --- diff /etc/network/interfaces ----------------------------------------------
			funcDiff /etc/network/interfaces /etc/network/interfaces.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	echo --- cat /etc/hosts ------------------------------------------------------------
	expand -t 4 /etc/hosts
	if [ -f /etc/hosts.orig ]; then
		echo --- diff /etc/hosts -----------------------------------------------------------
		funcDiff /etc/hosts /etc/hosts.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f "/etc/NetworkManager/system-connections/${CON_NAME}" ]; then
		echo --- cat /etc/NetworkManager/system-connections/${CON_NAME} -------------
		expand -t 4 "/etc/NetworkManager/system-connections/${CON_NAME}"
		if [ -f "/etc/NetworkManager/system-connections/${CON_NAME}.orig" ]; then
			echo --- diff /etc/NetworkManager/system-connections/${CON_NAME} ------------
			funcDiff "/etc/NetworkManager/system-connections/${CON_NAME}" "/etc/NetworkManager/system-connections/${CON_NAME}.orig"
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f /etc/resolv.conf ]; then
		echo --- cat /etc/resolv.conf ------------------------------------------------------
		expand -t 4 /etc/resolv.conf
		if [ -f /etc/resolv.conf.orig ]; then
			echo --- diff /etc/resolv.conf -----------------------------------------------------
			funcDiff /etc/resolv.conf /etc/resolv.conf.orig
		fi
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	echo --- cat /etc/hosts.allow ------------------------------------------------------
#	expand -t 4 /etc/hosts.allow
	if [ -f /etc/hosts.allow.orig ]; then
		echo --- diff /etc/hosts.allow -----------------------------------------------------
		funcDiff /etc/hosts.allow /etc/hosts.allow.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	echo --- cat /etc/hosts.deny -------------------------------------------------------
#	expand -t 4 /etc/hosts.deny
	if [ -f /etc/hosts.deny.orig ]; then
		echo --- diff /etc/hosts.deny ------------------------------------------------------
		funcDiff /etc/hosts.deny /etc/hosts.deny.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
#	echo --- cat /etc/nsswitch.conf ----------------------------------------------------
#	expand -t 4 /etc/nsswitch.conf
	if [ -f /etc/nsswitch.conf ] && [ -f /etc/nsswitch.conf.orig ]; then
		echo --- diff /etc/nsswitch.conf ---------------------------------------------------
		funcDiff /etc/nsswitch.conf /etc/nsswitch.conf.orig
	fi
	# Install clamav **********************************************************
	FILE_FRESHCONF=`find /etc -name "freshclam.conf" -type f -print`
	if [ "${FILE_FRESHCONF}" != "" ]; then
		FILE_CLAMDCONF=`dirname ${FILE_FRESHCONF}`/clamd.conf
#		echo --- cat ${FILE_FRESHCONF} ----------------------------------------------------
#		expand -t 4 ${FILE_FRESHCONF}
		if [ -f ${FILE_FRESHCONF}.orig ]; then
			echo --- diff ${FILE_FRESHCONF} ------------------------------------------
			funcDiff ${FILE_FRESHCONF} ${FILE_FRESHCONF}.orig
		fi
		if [ -f ${FILE_CLAMDCONF} ]; then
			echo --- cat ${FILE_CLAMDCONF} ----------------------------------------------------
			expand -t 4 ${FILE_CLAMDCONF}
		fi
	fi
	# Install ssh *************************************************************
#	echo --- cat /etc/ssh/sshd_config --------------------------------------------------
#	expand -t 4 /etc/ssh/sshd_config
	if [ -f /etc/ssh/sshd_config.orig ]; then
		echo --- diff /etc/ssh/sshd_config -------------------------------------------------
		funcDiff /etc/ssh/sshd_config /etc/ssh/sshd_config.orig
	fi
	# Install apache2 *********************************************************
#	echo --- cat ${FILE_USERDIRCONF} --------------------------------
#	expand -t 4 ${FILE_USERDIRCONF}
	if [ -f ${FILE_USERDIRCONF}.orig ]; then
		echo --- diff ${FILE_USERDIRCONF} ----------------------------------------
		funcDiff ${FILE_USERDIRCONF} ${FILE_USERDIRCONF}.orig
	fi
	# Install vsftpd **********************************************************
#	echo --- cat ${DIR_VSFTPD}/vsftpd.conf ------------------------------------------------------
#	expand -t 4 ${DIR_VSFTPD}/vsftpd.conf
	if [ -f ${DIR_VSFTPD}/vsftpd.conf.orig ]; then
		echo --- diff ${DIR_VSFTPD}/vsftpd.conf ----------------------------------
		funcDiff ${DIR_VSFTPD}/vsftpd.conf ${DIR_VSFTPD}/vsftpd.conf.orig
	fi
	# Install bind9 ***********************************************************
	if [ -f ${DIR_ZONE}/${WGP_NAME}.zone ]; then
		echo --- cat ${DIR_ZONE}/${WGP_NAME}.zone --------------------------------
		expand -t 4 ${DIR_ZONE}/${WGP_NAME}.zone
	fi
	if [ -f ${DIR_ZONE}/${WGP_NAME}.rev ]; then
		echo --- cat ${DIR_ZONE}/${WGP_NAME}.rev ---------------------------------
		expand -t 4 ${DIR_ZONE}/${WGP_NAME}.rev
	fi
	if [ -f ${DIR_ZONE}/${IP6_UADR}.rev ]; then
		echo --- cat ${DIR_ZONE}/${IP6_UADR}.rev ---------------------------------
		expand -t 4 ${DIR_ZONE}/${IP6_UADR}.rev
	fi
	if [ -f ${DIR_ZONE}/${LNK_UADR}.rev ]; then
		echo --- cat ${DIR_ZONE}/${LNK_UADR}.rev ---------------------------------
		expand -t 4 ${DIR_ZONE}/${LNK_UADR}.rev
	fi
	# ･････････････････････････････････････････････････････････････････････････
	echo --- cat ${DIR_BIND}/named.conf --------------------------------------------------
	expand -t 4 ${DIR_BIND}/named.conf
	if [ -f ${DIR_BIND}/named.conf.orig ]; then
		echo --- diff ${DIR_BIND}/named.conf -------------------------------------
		funcDiff ${DIR_BIND}/named.conf ${DIR_BIND}/named.conf.orig
	fi
	# ･････････････････････････････････････････････････････････････････････････
	if [ -f ${DIR_BIND}/named.conf.local ]; then
		echo --- cat ${DIR_BIND}/named.conf.local --------------------------------------------
		expand -t 4 ${DIR_BIND}/named.conf.local
	fi
	# ･････････････････････････････････････････････････････････････････････････
	echo --- dns check -----------------------------------------------------------------
	dig ${SVR_NAME}.${WGP_NAME} A +nostats +nocomments
	echo ･･･････････････････････････････････････････････････････････････････････････････
	dig ${SVR_NAME}.${WGP_NAME} AAAA +nostats +nocomments
	echo ･･･････････････････････････････････････････････････････････････････････････････
	dig -x ${IP4_ADDR[0]} +nostats +nocomments
	echo ･･･････････････････････････････････････････････････････････････････････････････
	dig -x ${IP6_ADDR[0]} +nostats +nocomments
	echo ･･･････････････････････････････････････････････････････････････････････････････
	dig -x ${LNK_ADDR[0]} +nostats +nocomments
	echo --- dns check -----------------------------------------------------------------
	# Install dhcp ************************************************************
	echo --- diff /etc/dhcp/dhcpd.conf -------------------------------------------------
	expand -t 4 /etc/dhcp/dhcpd.conf
#	funcDiff /etc/dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf.orig
	# Install Webmin **********************************************************
	if [ -f /etc/webmin/config.orig ]; then
		echo --- diff /etc/webmin/config ---------------------------------------------------
		funcDiff /etc/webmin/config /etc/webmin/config.orig
	fi
	if [ -f /etc/webmin/time/config.orig ]; then
		echo --- diff /etc/webmin/time/config ----------------------------------------------
		funcDiff /etc/webmin/time/config /etc/webmin/time/config.orig
	fi
	# Add smb.conf ************************************************************
	echo --- cat ${SMB_CONF} -------------------------------------------------
	expand -t 4 ${SMB_CONF}
	# Setup Samba User ********************************************************
	echo --- pdbedit -L ----------------------------------------------------------------
	pdbedit -L
	# GRUB ********************************************************************
	if [ -f /etc/default/grub.orig ]; then
		echo --- diff /etc/default/grub ----------------------------------------------------
		funcDiff /etc/default/grub /etc/default/grub.orig
	fi
	# Install VMware Tools ****************************************************
	if [ -f /etc/fstab.vmware ]; then
		echo --- diff /etc/fstab /etc/fstab.vmware -----------------------------------------
		funcDiff /etc/fstab /etc/fstab.vmware
	fi
}

# *****************************************************************************
# Main処理                                                                    *
# *****************************************************************************
	# Common ------------------------------------------------------------------
	funcInitialize
	if [ ${DBG_FLAG} -lt 2 ]; then												# 引数<=1又は無しでmain処理
		# Main ----------------------------------------------------------------
		funcMain
	else																		# 引数>=2でdebug処理のみ
		funcDebug
	fi
	# -------------------------------------------------------------------------
	echo --- End -----------------------------------------------------------------------

# *****************************************************************************
# Exit
# *****************************************************************************
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 設定処理が終了しました。"
	echo " [ sudo reboot ] して下さい。"
	echo "*******************************************************************************"

	exit 0

###############################################################################
# memo                                                                        #
###############################################################################
# sudo apt update && sudo apt -y upgrade
# -----------------------------------------------------------------------------
# <参照> http://tech.nikkeibp.co.jp/it/article/COLUMN/20060227/230881/
#==============================================================================
# End of file                                                                 =
#==============================================================================
