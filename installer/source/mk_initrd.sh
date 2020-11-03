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
	readonly WORK_DIRS=`basename $0 | sed -e 's/\..*$//'`	# 作業ディレクトリ名(プログラム名)
# -----------------------------------------------------------------------------
	rm -rf   ${WORK_DIRS}/glantank/image ${WORK_DIRS}/glantank/decomp ${WORK_DIRS}/glantank/mnt
	mkdir -p ${WORK_DIRS}/glantank/image ${WORK_DIRS}/glantank/decomp ${WORK_DIRS}/glantank/mnt
	# -------------------------------------------------------------------------
	pushd ${WORK_DIRS}/glantank > /dev/null
		[ ! -f initrd.gz            ] && wget "http://archive.debian.org/debian-archive/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/initrd.gz"
		[ ! -f zImage               ] && wget "http://archive.debian.org/debian-archive/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/zImage"
		[ ! -f preseed.cfg          ] && wget "http://archive.debian.org/debian-archive/debian/dists/wheezy/main/installer-armel/current/images/iop32x/network-console/glantank/preseed.cfg"
		[ ! -f preseed_glantank.cfg ] && wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_glantank.cfg"
		# ---------------------------------------------------------------------
		sed -i "preseed_glantank.cfg"                                            \
		    -e 's~.*\(d-i netcfg/get_ipaddress\).*~  \1 string 192.168.1.11~'    \
		    -e 's~.*\(d-i netcfg/get_netmask\).*~  \1 string 255.255.255.0~'     \
		    -e 's~.*\(d-i netcfg/get_gateway\).*~  \1 string 192.168.1.254~'     \
		    -e 's~.*\(d-i netcfg/get_nameservers\).*~  \1 string 192.168.1.254~' \
		    -e 's~.*\(d-i netcfg/confirm_static\).*~  \1 boolean true~'          \
		    -e 's~.*\(d-i netcfg/get_hostname\).*~  \1 string sv-planet~'        \
		    -e 's~.*\(d-i netcfg/get_domain\).*~  \1 string planet~'
		# ---------------------------------------------------------------------
		pushd decomp > /dev/null							# initrd.gz 展開先
			gunzip < ../initrd.gz | cpio -i
			cp --preserve=timestamps ../preseed_glantank.cfg ./preseed.cfg
			find . | cpio -H newc --create | gzip -9 > ../initrd
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
