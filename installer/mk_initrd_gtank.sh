#!/bin/bash
# -----------------------------------------------------------------------------
#	set -x													# コマンドと引数の展開を表示
#	set -n													# 構文エラーのチェック
	set -eu													# ステータス0以外と未定義変数の参照で終了
#	set -o ignoreof											# Ctrl+Dで終了しない
	trap 'exit 1' 1 2 3 15
# -----------------------------------------------------------------------------
	INP_INDX=${@:-""}										# 処理ID
# -----------------------------------------------------------------------------
	WHO_AMI=`whoami`										# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi
# -----------------------------------------------------------------------------
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 作成処理を開始します。"
	echo "*******************************************************************************"
# -----------------------------------------------------------------------------
	readonly DIR_WORK=`basename $0 | sed -e 's/\..*$//'`	# 作業ディレクトリ名(プログラム名)
	readonly DIR_PROG="//ftp.yz.yamagata-u.ac.jp/pub/linux/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank"
	readonly DIR_SEED="//raw.githubusercontent.com/office-itou/Linux/master/installer/glantank"
# -----------------------------------------------------------------------------
	readonly IP4_ADDR=192.168.1.1							# IPv4:IPアドレス
	readonly IP4_MASK=255.255.255.0							# IPv4:サブネットマスク
	readonly IP4_GATE=192.168.1.254							# IPv4:デフォルトゲートウェイ
	readonly IP4_DNSA=192.168.1.254							# IPv4:DNSアドレス
	readonly IP4_DHCP=true									# IPv4:DHCPフラグ(true:固定/false:DHCP)
	readonly SVR_NAME=sv-debian								# 本機のホスト名
	readonly WGP_NAME=workgroup								# ワークグループ名(ドメイン名)
	readonly PWD_INST=install								# コンソール画面ログイン・パスワード
# -----------------------------------------------------------------------------
	rm -rf   ${DIR_WORK}/glantank/image ${DIR_WORK}/glantank/decomp ${DIR_WORK}/glantank/mnt
	mkdir -p ${DIR_WORK}/glantank/image ${DIR_WORK}/glantank/decomp ${DIR_WORK}/glantank/mnt
	# -------------------------------------------------------------------------
	pushd ${DIR_WORK}/glantank > /dev/null
		[ ! -f initrd.gz            ] && wget "http:${DIR_PROG}/initrd.gz"
		[ ! -f zImage               ] && wget "http:${DIR_PROG}/zImage"
		[ ! -f preseed.cfg          ] && wget "http:${DIR_PROG}/preseed.cfg"
		[ ! -f preseed_glantank.cfg ] && wget "https:${DIR_SEED}/preseed_glantank.cfg"
		# ---------------------------------------------------------------------
		sed -i "preseed_glantank.cfg"                                                    \
		    -e "s~.*\(d-i netcfg/get_ipaddress\).*~  \1 string ${IP4_ADDR}~"             \
		    -e "s~.*\(d-i netcfg/get_netmask\).*~  \1 string ${IP4_MASK}~"               \
		    -e "s~.*\(d-i netcfg/get_gateway\).*~  \1 string ${IP4_GATE}~"               \
		    -e "s~.*\(d-i netcfg/get_nameservers\).*~  \1 string ${IP4_DNSA}~"           \
		    -e "s~.*\(d-i netcfg/confirm_static\).*~  \1 boolean ${IP4_DHCP}~"           \
		    -e "s~.*\(d-i netcfg/get_hostname\).*~  \1 string ${SVR_NAME}~"              \
		    -e "s~.*\(d-i netcfg/get_domain\).*~  \1 string ${WGP_NAME}~"                \
		    -e 's~.*\(d-i anna/choose_modules\)~# \1~'                                   \
		    -e 's~.*\(d-i network-console/authorized_keys_url\)~# \1~'                   \
		    -e 's~.*\(d-i network-console/login\)~# \1~'                                 \
		    -e "s~.*\(d-i network-console/password password\).*~  \1 ${PWD_INST}~"       \
		    -e "s~.*\(d-i network-console/password-again password\).*~  \1 ${PWD_INST}~" \
		    -e 's~.*\(d-i partman/default_filesystem\)~# \1~'                            \
		    -e 's~.*\(d-i partman-partitioning/confirm_write_new_label\)~# \1~'          \
		    -e 's~.*\(d-i partman/choose_partition\)~# \1~'                              \
		    -e 's~.*\(d-i partman/confirm\)~# \1~'                                       \
		    -e 's~.*\(d-i partman/confirm_nooverwrite\)~# \1~'                           \
		    -e 's~.*\(d-i partman/mount_style\)~# \1~'                                   \
		    -e 's~.*\(d-i finish-install/keep-consoles\)~# \1~'                          \
		    -e 's~.*\(d-i finish-install/reboot_in_progress\)~# \1~'                     
		# ---------------------------------------------------------------------
		pushd decomp > /dev/null							# initrd.gz 展開先
			zcat ../initrd.gz | cpio -if -
			cp --preserve=timestamps ../preseed_glantank.cfg ./preseed.cfg
			find | cpio --quiet -o -H newc | gzip -9 > ../initrd
		popd > /dev/null
		# ---------------------------------------------------------------------
		ls -alh
	popd > /dev/null
# -----------------------------------------------------------------------------
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 作成処理が終了しました。"
	echo "*******************************************************************************"
# -----------------------------------------------------------------------------
	exit 0
# = eof =======================================================================
