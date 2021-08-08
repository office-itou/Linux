#!/bin/bash
# *****************************************************************************
# preseed → user-data 変換
# *****************************************************************************
# == initialize ===============================================================
#	set -o ignoreof						# Ctrl+Dで終了しない
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了

	if [ "$1" = "" ]; then
		echo "$0 [preseedファイル名]"
		exit 1
	fi

	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0}]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# =============================================================================
# IPv4 netmask変換処理 --------------------------------------------------------
fncIPv4GetNetmaskBits () {
	local INP_ADDR
	local -a OUT_ARRY=()

	for INP_ADDR in "$@"
	do
		OUT_ARRY+=`echo ${INP_ADDR} | awk -F '.' '{split($0, octets); for (i in octets) {mask += 8 - log(2^8 - octets[i])/log(2);} print mask}'`
	done
	echo "${OUT_ARRY[@]}"
}
# =============================================================================
	echo "-- Initialize -----------------------------------------------------------------"
	#--------------------------------------------------------------------------
	NOW_DATE=`date +"%Y/%m/%d"`													# yyyy/mm/dd
	NOW_TIME=`date +"%Y%m%d%H%M%S"`												# yyyymmddhhmmss
	PGM_NAME=`basename $0 | sed -e 's/\..*$//'`									# プログラム名
# =============================================================================
	PRESEED_CFG=$1
	USER_DATA=${PRESEED_CFG}-user_data
	# --- header --------------------------------------------------------------
	cat <<- _EOT_ > ${USER_DATA}
		#cloud-config
		autoinstall:
		  version: 1
		# =============================================================================
		# refresh-installer:
		#   update: yes
_EOT_
	# --- apt -----------------------------------------------------------------
	MIRROR_HTTP_MIRROR=`awk '!/#/&&/ mirror\/http\/mirror / {print $4;}' ${PRESEED_CFG}`
	MIRROR_HTTP_DIRECTORY=`awk '!/#/&&/ mirror\/http\/directory / {print $4;}' ${PRESEED_CFG}| sed -e 's/^\///g'`
	MIRROR_HTTP_PORTS=`awk '!/#/&&/ mirror\/http\/mirror / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# apt:
		#   geoip: true
		#   preserve_sources_list: false
		#   primary:
		#   - arches: [amd64, i386]
		#     uri: http://${MIRROR_HTTP_MIRROR}/${MIRROR_HTTP_DIRECTORY}
		#   - arches: [default]
		#     uri: http://ports.ubuntu.com/ubuntu-ports
_EOT_
	# --- early-commands ------------------------------------------------------
	PARTMAN_AUTO_DISK=`awk '!/#/&&/ partman-auto\/disk / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# early-commands:
		#   - dd if=/dev/zero of=${PARTMAN_AUTO_DISK} bs=512 count=34
_EOT_
	# --- storage -------------------------------------------------------------
	PARTMAN_AUTO_METHOD=`awk '!/#/&&/ partman-auto\/method / {print $4;}' ${PRESEED_CFG}`
	PARTMAN_AUTO_DISK=`awk '!/#/&&/ partman-auto\/disk / {print $4;}' ${PRESEED_CFG}`
	STORAGE_ID=`echo ${PARTMAN_AUTO_DISK} | sed -e 's/^\///g' -e 's/\//-/g'`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  storage:
		    layout:
		      name: lvm
		# === efi =====================================================================
		# storage:
		#   config:
		#   - {ptable: gpt,              path: ${PARTMAN_AUTO_DISK}, wipe: pvremove,                    preserve: false, name: '',   grub_device: false, type: disk,          id: ${STORAGE_ID}}
		#   - {device: ${STORAGE_ID},          size: 512MB,    wipe: superblock, flag: boot,      preserve: false, number: 1,  grub_device: true,  type: partition,     id: partition-0}
		#   - {device: ${STORAGE_ID},          size: 1GB,      wipe: superblock, flag: '',        preserve: false, number: 2,                      type: partition,     id: partition-1}
		#   - {device: ${STORAGE_ID},          size: -1,       wipe: superblock, flag: '',        preserve: false, number: 3,                      type: partition,     id: partition-2}
		#   - {devices: [partition-2],                                                      preserve: false, name: vg-0,                     type: lvm_volgroup,  id: lvm_volgroup-0}
		#   - {volgroup: lvm_volgroup-0, size: 100%,                                        preserve: false, name: lv-0,                     type: lvm_partition, id: lvm_partition-0}
		#   - {volume: partition-0,      fstype: fat32,                                     preserve: false,                                 type: format,        id: format-0}
		#   - {volume: partition-1,      fstype: ext4,                                      preserve: false,                                 type: format,        id: format-1}
		#   - {volume: lvm_partition-0,  fstype: ext4,                                      preserve: false,                                 type: format,        id: format-2}
		#   - {device: format-0,         path: /boot/efi,                                                                                    type: mount,         id: mount-0}
		#   - {device: format-1,         path: /boot,                                                                                        type: mount,         id: mount-1}
		#   - {device: format-2,         path: /,                                                                                            type: mount,         id: mount-2}
		# === bios ====================================================================
		# storage:
		#   config:
		#   - {ptable: gpt,              path: ${PARTMAN_AUTO_DISK}, wipe: pvremove,                    preserve: false, name: '',   grub_device: true,  type: disk,          id: ${STORAGE_ID}}
		#   - {device: ${STORAGE_ID},          size: 1MB,      wipe: superblock, flag: bios_grub, preserve: false, number: 1,                      type: partition,     id: partition-0}
		#   - {device: ${STORAGE_ID},          size: 1GB,      wipe: superblock, flag: '',        preserve: false, number: 2,                      type: partition,     id: partition-1}
		#   - {device: ${STORAGE_ID},          size: -1,       wipe: superblock, flag: '',        preserve: false, number: 3,                      type: partition,     id: partition-2}
		#   - {devices: [partition-2],                                                      preserve: false, name: vg-0,                     type: lvm_volgroup,  id: lvm_volgroup-0}
		#   - {volgroup: lvm_volgroup-0, size: 100%,     wipe: superblock,                  preserve: false, name: lv-0,                     type: lvm_partition, id: lvm_partition-0}
		#   - {volume: partition-1,      fstype: ext4,                                      preserve: false,                                 type: format,        id: format-0}
		#   - {volume: lvm_partition-0,  fstype: ext4,                                      preserve: false,                                 type: format,        id: format-1}
		#   - {device: format-0,         path: /boot,                                                                                        type: mount,         id: mount-0}
		#   - {device: format-1,         path: /,                                                                                            type: mount,         id: mount-1}
_EOT_
	# --- identity ------------------------------------------------------------
	NETCFG_GET_HOSTNAME=`awk '!/#/&&/ netcfg\/get_hostname / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_DOMAIN=`awk '!/#/&&/ netcfg\/get_domain / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_FULLNAME=`awk '!/#/&&/ passwd\/user-fullname / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USERNAME=`awk '!/#/&&/ passwd\/username / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_PASSWORD=`awk '!/#/&&/ passwd\/user-password / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_PASSWORD_CRYPTED=`awk '!/#/&&/ passwd\/user-password-crypted / {print $4;}' ${PRESEED_CFG}`
	if [ "${PASSWD_USER_PASSWORD_CRYPTED}" = "" ]; then
		PASSWD_USER_PASSWORD_CRYPTED=`mkpasswd -m SHA-512 ${PASSWD_USER_PASSWORD}`
	fi
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  identity:
		    hostname: ${NETCFG_GET_HOSTNAME}.${NETCFG_GET_DOMAIN}
		    realname: ${PASSWD_USER_FULLNAME}
		    username: ${PASSWD_USERNAME}
		    password: "${PASSWD_USER_PASSWORD_CRYPTED}"
_EOT_
	# --- locale --------------------------------------------------------------
	DEBIAN_INSTALLER_LOCALE=`awk '!/#/&&/ debian-installer\/locale / {print $4;}' ${PRESEED_CFG}`
	KEYBOARD_CONFIGURATION_LAYOUTCODE=`awk '!/#/&&/ keyboard-configuration\/layoutcode / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  locale: ${DEBIAN_INSTALLER_LOCALE}
		  keyboard:
		    layout: ${KEYBOARD_CONFIGURATION_LAYOUTCODE}
_EOT_
	# --- network -------------------------------------------------------------
	NETCFG_GET_IPADDRESS=`awk '!/#/&&/ netcfg\/get_ipaddress / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NETMASK=`awk '!/#/&&/ netcfg\/get_netmask / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_GATEWAY=`awk '!/#/&&/ netcfg\/get_gateway / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NAMESERVERS=`awk '!/#/&&/ netcfg\/get_nameservers / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NETMASK_BITS=`fncIPv4GetNetmaskBits "${NETCFG_GET_NETMASK}"`
	NETCFG_GET_DOMAIN=`awk '!/#/&&/ netcfg\/get_domain / {print $4;}' ${PRESEED_CFG}`
	DISABLE_DHCP=`awk '!/#/&&(/ netcfg\/disable_dhcp /||/ netcfg\/disable_autoconfig /)&&/true/&&!a[$4]++ {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  network:
		    version: 2
		    ethernets:
		      ens160:
_EOT_
	if [ "${DISABLE_DHCP}" != "true" ]; then
		cat <<- _EOT_ >> ${USER_DATA}
			        dhcp4: true
_EOT_
	else
		cat <<- _EOT_ >> ${USER_DATA}
			        dhcp4: false
			        addresses:
			        - ${NETCFG_GET_IPADDRESS}/${NETCFG_GET_NETMASK_BITS}
			        gateway4: ${NETCFG_GET_GATEWAY}
			        nameservers:
			          addresses:
			          - ${NETCFG_GET_NAMESERVERS}
			          search:
			          - ${NETCFG_GET_DOMAIN}
_EOT_
	fi
	# --- ssh -----------------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  ssh:
		    install-server: true
_EOT_
	# --- packages ------------------------------------------------------------
	LIST_TASK=`awk '(!/#/&&/tasksel\/first/),(!/\\\\/) {print $0;}' ${PRESEED_CFG} | \
	           sed -z 's/\n//g'                                                    | \
	           sed -e 's/.* multiselect *//'                                         \
	               -e 's/[,|\\\\]//g'                                                \
	               -e 's/  */ /g'                                                    \
	               -e 's/^ *//'                                                      \
	               -e 's/\(\S*\)/\1^/g'`
	LIST_PACK=`awk '(!/#/&&/pkgsel\/include/),(!/\\\\/) {print $0;}' ${PRESEED_CFG} | \
	           sed -z 's/\n//g'                                                     | \
	           sed -e 's/.* string *//'                                               \
	               -e 's/[,|\\\\]//g'                                                 \
	               -e 's/  */ /g'                                                     \
	               -e 's/^ *//'`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# package_update: true
		# package_upgrade: true
		  packages:
_EOT_
	for TASK in ${LIST_TASK}
	do
		echo "  - ${TASK}" >> ${USER_DATA}
	done
	echo "# -----------------------------------------------------------------------------" >> ${USER_DATA}
	for PACK in ${LIST_PACK}
	do
		echo "  - ${PACK}" >> ${USER_DATA}
	done
	# --- user-data -----------------------------------------------------------
	TIME_ZONE=`awk '!/#/&&/ time\/zone / {print $4;}' ${PRESEED_CFG}`
	CLOCK_SETUP_NTP_SERVER=`awk '!/#/&&/ clock-setup\/ntp-server / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  user-data:
		    ntp:
		      enabled: true
		      ntp_client: chrony
		      pools:
		      - ${CLOCK_SETUP_NTP_SERVER}
		    timezone: ${TIME_ZONE}
		#   snap:
		#     commands:
		#     - snap install chromium
		    runcmd:
		    - mkdir -p /etc/NetworkManager/conf.d/
		    - echo "[keyfile]\nunmanaged-devices=none" > /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
		    - systemctl restart network-manager.service
		    - nmcli c modify ens160 +ipv4.dns 192.168.1.254
		    power_state:
		      delay: "+0"
		      mode: reboot
		      message: "System reboot."
		      timeout: 0
		# === EOF =====================================================================
_EOT_
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0}]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
# == EOF ======================================================================
