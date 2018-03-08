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
##	YYYY/MM/DD 000.0000 xxxxxxxxxxxxxx 
##	---------- -------- -------------- -----------------------------------------
################################################################################
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

#-------------------------------------------------------------------------------
# Initialize
#-------------------------------------------------------------------------------
	DBG_FLAG=${DBG_FLAG:-0}
	if [ ${DBG_FLAG} -ne 0 ]; then
		set -vx
	fi

	# ワーク変数設定 -----------------------------------------------------------
	NOW_TIME=`date +"%Y%m%d%H%M%S"`
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`

	DST_NAME=`awk '/[A-Za-z]./ {print $1;}' /etc/issue | head -n 1 | tr '[A-Z]' '[a-z]'`

	DIR_WK=.

	LST_USER=${DIR_WK}/addusers.txt
	USR_FILE=${DIR_WK}/${PGM_NAME}.sh.usr.list
	SMB_FILE=${DIR_WK}/${PGM_NAME}.sh.smb.list
	SMB_USER=sambauser
	SMB_GRUP=sambashare

	# ワーク・ディレクトリーの変更 --------------------------------------------
	pushd ${DIR_WK}

#------------------------------------------------------------------------------
# Make User file
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
# Termination
#------------------------------------------------------------------------------
	rm -f ${USR_FILE}
	rm -f ${SMB_FILE}
	popd

#------------------------------------------------------------------------------
# Exit
#------------------------------------------------------------------------------
	exit 0

#------------------------------------------------------------------------------
# End of file
#------------------------------------------------------------------------------
