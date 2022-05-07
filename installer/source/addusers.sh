#!/bin/bash
###############################################################################
##
##	ファイル名	:	addusers.sh
##
##	機能概要	:	ユーザー追加用シェル
##	---------------------------------------------------------------------------
##	<対象OS>	:	Debian 7 ～
##				:	Ubuntu 18.04 ～
##				:	CentOS 7 ～
##	---------------------------------------------------------------------------
##	<サービス>	:	samba / smbd,nmbd / smb,nmb
##	---------------------------------------------------------------------------
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2016/02/11
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- -----------------------------------------
##	2016/02/11 000.0000 J.Itou         新規作成
##	2018/02/25 000.0000 J.Itou         改善対応
##	2018/05/05 000.0000 J.Itou         改善対応
##	2018/06/03 000.0000 J.Itou         改善対応
##	2021/06/24 000.0000 J.Itou         不具合修正
##	2022/05/06 000.0000 J.Itou         不具合修正
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
###############################################################################
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

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

# *****************************************************************************
# 初期設定
# *****************************************************************************
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
	# ユーザー環境に合わせて変更する部分 --------------------------------------
	# 登録ユーザーリスト (pdbedit -L -w の出力結果を拡張) ･････････････････････
	#   UAR_ARRAY=("login name:full name:uid::lanman passwd hash:nt passwd hash:account flag:last change time:admin flag")
	USR_ARRY=(                                                                                                                             \
	    "administrator:Administrator:1001::XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX:8846F7EAEE8FB117AD06BDD830B7586C:[U          ]:LCT-5A90A998:1" \
	)	# sample: administrator's password="password"
	# samba -------------------------------------------------------------------
	SMB_USER=sambauser															# smb.confのforce user
	SMB_GRUP=sambashare															# smb.confのforce group
	SMB_GADM=sambaadmin															# smb.confのadmin group
	# ワーク変数設定 ----------------------------------------------------------
	DIR_SHAR=/share																# 共有ディレクトリーのルート
	DIR_WK=${PWD}
	LST_USER=${DIR_WK}/addusers.txt
	USR_FILE=${DIR_WK}/${PGM_NAME}.sh.usr.list
	SMB_FILE=${DIR_WK}/${PGM_NAME}.sh.smb.list
	# -------------------------------------------------------------------------
	if [ -f /etc/lightdm/users.conf ]; then
		LIN_CHSH=`awk -F '[ =]' '$1=="hidden-shells" {print $2;}' /etc/lightdm/users.conf`
	else
		LIN_CHSH=`find /bin/ /sbin/ /usr/sbin/ -mindepth 1 -maxdepth 1 \( -name 'false' -o -name 'nologin' \) -print | head -n 1`
	fi
	if [ "`which usermod 2> /dev/null`" != "" ]; then
		CMD_CHSH="`which usermod` -s ${LIN_CHSH}"
	else
		CMD_CHSH="`which chsh` -s ${LIN_CHSH}"
	fi
	# -------------------------------------------------------------------------
	pdbedit -L > /dev/null
	funcPause $?
	SMB_PWDB=`find /var/lib/samba/ -name passdb.tdb -type f -print`

# *****************************************************************************
# Main処理                                                                    *
# *****************************************************************************
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
	# Termination
	# *************************************************************************
	echo - Termination -----------------------------------------------------------------
	# -------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}

# *****************************************************************************
# Exit
# *****************************************************************************
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` 設定処理が終了しました。"
	echo "*******************************************************************************"

	exit 0

#==============================================================================
# End of file                                                                 =
#==============================================================================
