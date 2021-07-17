#!/bin/bash
# *****************************************************************************
# set static IP address and install packages
# *****************************************************************************

# == initialize ===============================================================
#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	trap 'exit 1' 1 2 3 15
# =============================================================================
# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=`echo ${INP_ADDR} | awk -F. '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
	done
	echo "${OUT_ARRY[@]}"
}
# == main =====================================================================
	CFG_NAME=$1
	DIR_TARGET=$2
	# -------------------------------------------------------------------------
	if [ -f "${CFG_NAME}" ]; then
		# -- バージョン番号 ---------------------------------------------------
		SYS_VRID=`awk -F '=' '/VERSION_ID/ {gsub("\"",""); print $2;}' /etc/os-release`
		SYS_VNUM=`echo ${SYS_VRID:--1} | bc`									#   〃          (取得できない場合は-1)
		SYS_NOOP=0																# 対象OS=1,それ以外=0
		# -- netplan ----------------------------------------------------------
		IPV4_DHCP=`awk '!/#/&&(/netcfg\/disable_dhcp/||/netcfg\/disable_autoconfig/)&&/true/&&!a[$4]++ {print $4;}' ${CFG_NAME}`
		if [ "${IPV4_DHCP,,}" = "true" ]; then
			ARRY_ETHS=(`nmcli device show | awk '/GENERAL.DEVICE:/&&!/lo/ {print $2;}'`)
			IPV4_ADDR=`awk '!/#/&&/netcfg\/get_ipaddress/   {print $4;}' ${CFG_NAME}`
			IPV4_MASK=`awk '!/#/&&/netcfg\/get_netmask/     {print $4;}' ${CFG_NAME}`
			IPV4_GWAY=`awk '!/#/&&/netcfg\/get_gateway/     {print $4;}' ${CFG_NAME}`
			IPV4_NAME=`awk '!/#/&&/netcfg\/get_nameservers/ {print $4;}' ${CFG_NAME}`
			IPV4_BITS=`fncIPv4GetNetmaskBits "${IPV4_MASK}"`
			# -----------------------------------------------------------------
			if [ ! -d ${DIR_TARGET}/etc/netplan ]; then
				mkdir -p ${DIR_TARGET}/etc/netplan
			fi
			cat <<- _EOT_ > ${DIR_TARGET}/etc/netplan/99-network-manager-static.yaml
				network:
				  version: 2
				  renderer: NetworkManager
				  ethernets:
				    ${ARRY_ETHS[0]}:
				      dhcp4: false
				      addresses: [${IPV4_ADDR}/${IPV4_BITS}]
				      gateway4: ${IPV4_GWAY}
				      nameservers:
				        addresses: [${IPV4_NAME}]
_EOT_
		fi
		# -- packages ---------------------------------------------------------
		LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' ${CFG_NAME} | \
		           sed -z 's/\n//g'                                                 | \
		           sed -e 's/.* multiselect *//'                                      \
		               -e 's/[,|\\\\]//g'                                             \
		               -e 's/  */ /g'                                                 \
		               -e 's/^ *//'                                                   \
		               -e 's/\(\S*\)/\1^/g'`
		LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' ${CFG_NAME} | \
		           sed -z 's/\n//g'                                                  | \
		           sed -e 's/.* string *//'                                            \
		               -e 's/[,|\\\\]//g'                                              \
		               -e 's/  */ /g'                                                  \
		               -e 's/^ *//'`
		in-target apt -qq    update;
		in-target apt -qq -y install ${LIST_TASK} ${LIST_PACK}
	fi
	exit 0
# == EOF ======================================================================
