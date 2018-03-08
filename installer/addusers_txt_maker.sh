#!/bin/bash
################################################################################
##
##	ファイル名	:	addusers_txt_maker.sh
##
##	機能概要	:	addusers.txt作成用シェル
##					(既存sambaユーザーの抜き出し)
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

	# ワーク・ディレクトリーの変更 --------------------------------------------
	pushd ${DIR_WK}

#------------------------------------------------------------------------------
# Make User file
#------------------------------------------------------------------------------
	rm -f ${LST_USER}
	touch ${LST_USER}

	OLDIFS=${IFS}
	IFS=$'\n'
	for LINE in `pdbedit -L -w`
	do
		USERNAME=`echo ${LINE} | awk -F : '{print $1;}'`
		USERIDNO=`echo ${LINE} | awk -F : '{print $2;}'`
		LMPASSWD=`echo ${LINE} | awk -F : '{print $3;}'`
		NTPASSWD=`echo ${LINE} | awk -F : '{print $4;}'`
		ACNTFLAG=`echo ${LINE} | awk -F : '{print $5;}'`
		CHNGTIME=`echo ${LINE} | awk -F : '{print $6;}'`

		FULLNAME=`pdbedit -u ${USERNAME} | awk -F : '{print $3;}'`
		PASSWORD=""

		IDGROUPS=`id -G -n ${USERNAME} | awk '/sambaadmin/'`
		if [ "${IDGROUPS}" = "" ]; then
			ADMINFLG=0
		else
			ADMINFLG=1
		fi

		echo "${USERNAME}:${FULLNAME}:${USERIDNO}:${PASSWORD}:${LMPASSWD}:${NTPASSWD}:${ACNTFLAG}:${CHNGTIME}:${ADMINFLG}" >> ${LST_USER}
	done
	IFS=${OLDIFS}

#------------------------------------------------------------------------------
# Termination
#------------------------------------------------------------------------------
	popd

#------------------------------------------------------------------------------
# Exit
#------------------------------------------------------------------------------
	exit 0

#------------------------------------------------------------------------------
# End of file
#------------------------------------------------------------------------------
