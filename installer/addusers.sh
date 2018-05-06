#!/bin/bash
################################################################################
##
##	ファイル名	:	addusers.sh
##
##	機能概要	:	ユーザー追加用シェル
##
##	入出力 I/F
##		INPUT	:	
##		OUTPUT	:	
##
##	作成者		:	J.Itou
##
##	作成日付	:	2015/02/20
##
##	改訂履歴	:	
##	   日付       版         名前      改訂内容
##	---------- -------- -------------- -----------------------------------------
##	2015/02/20 000.0000 J.Itou         新規作成
##	2018/02/25 000.0000 J.Itou         改善対応
##	2018/05/05 000.0000 J.Itou         改善対応
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
##	---------- -------- -------------- -----------------------------------------
################################################################################
	set -eu								# ステータス0以外と未定義変数の参照で終了
	trap 'exit 1' 1 2 3 15

# Pause処理 -------------------------------------------------------------------
funcPause() {
	local RET_STS=$1

	if [ ${RET_STS} -ne 0 ]; then
		echo "Enterキーを押して下さい。"
		read DUMMY
	fi
}

#-------------------------------------------------------------------------------
# Initialize
#-------------------------------------------------------------------------------
	#--------------------------------------------------------------------------
	WHO_AMI=`whoami`					# 実行ユーザー名
	if [ "${WHO_AMI}" != "root" ]; then
		echo "rootユーザーで実行して下さい。"
		exit 1
	fi

	# ワーク変数設定 -----------------------------------------------------------
	NOW_TIME=`date +"%Y%m%d%H%M%S"`
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`

	DST_NAME=`awk '/[A-Za-z]./ {print $1;}' /etc/issue | head -n 1 | tr '[A-Z]' '[a-z]'`

	DIR_WK=.

	LST_USER=${DIR_WK}/addusers.txt
	USR_FILE=${DIR_WK}/${PGM_NAME}.sh.usr.list
	SMB_FILE=${DIR_WK}/${PGM_NAME}.sh.smb.list
	# samba -------------------------------------------------------------------
	SMB_USER=sambauser					# smb.confのforce user
	SMB_GRUP=sambashare					# smb.confのforce group
	SMB_GADM=sambaadmin					# smb.confのadmin group
	SMB_PWDB=`find /var/lib/samba/ -name passdb.tdb -type f -print`

#------------------------------------------------------------------------------
# Make User file (${DIR_WK}/addusers.txtが有ればそれを使う)
#------------------------------------------------------------------------------
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
		while IFS=':' read WORKNAME FULLNAME USERIDNO PASSWORD LMPASSWD NTPASSWD ACNTFLAG CHNGTIME ADMINFLG
		do
			USERNAME="${WORKNAME,,}"
			if [ "${USERNAME}" != "" ]; then
				echo "${USERNAME}:${FULLNAME}:${USERIDNO}:${PASSWORD}:${ADMINFLG}"              >> ${USR_FILE}
				echo "${USERNAME}:${USERIDNO}:${LMPASSWD}:${NTPASSWD}:${ACNTFLAG}:${CHNGTIME}:" >> ${SMB_FILE}
			fi
		done < ${LST_USER}
	fi

#------------------------------------------------------------------------------
# Setup Login User
#------------------------------------------------------------------------------
	echo - Setup Login User ------------------------------------------------------------
	# -------------------------------------------------------------------------
	while IFS=':' read WORKNAME FULLNAME USERIDNO PASSWORD ADMINFLG
	do
		USERNAME="${WORKNAME,,}"
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

#------------------------------------------------------------------------------
# Setup Samba User
#------------------------------------------------------------------------------
	echo - Setup Samba User ------------------------------------------------------------
	# -------------------------------------------------------------------------
	pdbedit -i smbpasswd:${SMB_FILE} -e tdbsam:${SMB_PWDB}
	funcPause $?

#------------------------------------------------------------------------------
# Termination
#------------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}

#------------------------------------------------------------------------------
# Exit
#------------------------------------------------------------------------------
	exit 0

#------------------------------------------------------------------------------
# End of file
#------------------------------------------------------------------------------
