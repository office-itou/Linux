#!/bin/bash
# *****************************************************************************
# preseed → user-data 変換
# *****************************************************************************
# == initialize ===============================================================
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了

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
	#--------------------------------------------------------------------------
	if [ "`which aptitude 2> /dev/null`" != "" ]; then
		CMD_AGET="aptitude -y -q"
	else
		CMD_AGET="apt -y -qq"
	fi
	#--------------------------------------------------------------------------
	if [ "`which mkpasswd 2> /dev/null`" = "" ]; then
		sudo ${CMD_AGET} update
		sudo ${CMD_AGET} install whois
	fi
# =============================================================================
	PRESEED_CFG=$1
	USER_DATA=${PRESEED_CFG}-user_data
	# --- header --------------------------------------------------------------
	cat <<- _EOT_ > ${USER_DATA}
		#cloud-config
		autoinstall:
		  version: 1
		# =============================================================================
		# debug:
		#   verbose: true
		#   output:
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
		#   disable_components: []
		#   fallback: abort
		#   geoip: true
		#   mirror-selection:
		#     primary:
		#     - country-mirror
		#     - arches:
		#       - amd64
		#       - i386
		#       uri: http://${MIRROR_HTTP_MIRROR}/${MIRROR_HTTP_DIRECTORY}
		#     - arches:
		#       - s390x
		#       - arm64
		#       - armhf
		#       - powerpc
		#       - ppc64el
		#       - riscv64
		#       uri: http://ports.ubuntu.com/ubuntu-ports
		#   preserve_sources_list: false
_EOT_
	# --- bootcmd -------------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# bootcmd:
_EOT_
	# --- early-commands ------------------------------------------------------
	PARTMAN_AUTO_DISK=`awk '!/#/&&/ partman-auto\/disk / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# early-commands:
		# - dd if=/dev/zero of=${PARTMAN_AUTO_DISK} bs=512 count=34
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
		      match:
		        ssd: yes
		    swap:
		      size: 0
		# -----------------------------------------------------------------------------
		# /dev/nvme0n1p1: 512MB: /boot/efi
		#      nvme0n1p2: 512MB: /boot
		#      nvme0n1p3:    -1: vg00
		# lv-root       :  100%: /
		# storage:
		#   config:
		#   - { type: disk, ptable: gpt, path: /dev/nvme0n1, wipe: superblock-recursive, preserve: false, name: '', grub_device: false, id: disk-nvme0n1 }
		#   - { type: partition, device: disk-nvme0n1, size: 512M, wipe: superblock, flag: boot, number: 1, preserve: false, grub_device: true, id: partition-0 }
		#   - { type: partition, device: disk-nvme0n1, size: 512M, wipe: superblock,             number: 2, preserve: false,                    id: partition-1 }
		#   - { type: partition, device: disk-nvme0n1, size:   -1, wipe: superblock,             number: 3, preserve: false,                    id: partition-2 }
		#   - { type: lvm_volgroup, devices: [partition-2], preserve: false, name: vg00, id: lvm_volgroup-0 }
		#   - { type: lvm_partition, volgroup: lvm_volgroup-0, size: 100%, wipe: superblock, preserve: false, name: lv-root, id: lvm_partition-0 }
		#   - { type: format, fstype: fat32, volume: partition-0,     preserve: false, id: format-0 }
		#   - { type: format, fstype: ext4,  volume: partition-1,     preserve: false, id: format-1 }
		#   - { type: format, fstype: ext4,  volume: lvm_partition-0, preserve: false, id: format-2 }
		#   - { type: mount, device: format-0, path: /boot/efi, id: mount-0 }
		#   - { type: mount, device: format-1, path: /boot    , id: mount-1 }
		#   - { type: mount, device: format-2, path: /        , id: mount-2 }
		# -----------------------------------------------------------------------------
		# /dev/nvme0n1p1: 512MB: /boot/efi
		#      nvme0n1p2: 512MB: /boot
		#      nvme0n1p3:    -1: vg00
		# /dev/sda1:         -1: vg01
		# lv-root       :  100%: /
		# lv-home       :  100%: /home
		# storage:
		#   config:
		#   - { type: disk, ptable: gpt, path: /dev/nvme0n1, wipe: superblock-recursive, preserve: false, name: '', grub_device: false, id: disk-nvme0n1 }
		#   - { type: partition, device: disk-nvme0n1, size: 512M, wipe: superblock, flag: boot, number: 1, preserve: false, grub_device: true, id: partition-0 }
		#   - { type: partition, device: disk-nvme0n1, size: 512M, wipe: superblock,             number: 2, preserve: false,                    id: partition-1 }
		#   - { type: partition, device: disk-nvme0n1, size:   -1, wipe: superblock,             number: 3, preserve: false,                    id: partition-2 }
		#   - { type: lvm_volgroup, devices: [partition-2], preserve: false, name: vg00, id: lvm_volgroup-0 }
		#   - { type: lvm_partition, volgroup: lvm_volgroup-0, size: 100%, wipe: superblock, preserve: false, name: lv-root, id: lvm_partition-0 }
		#   - { type: format, fstype: fat32, volume: partition-0,     preserve: false, id: format-0 }
		#   - { type: format, fstype: ext4,  volume: partition-1,     preserve: false, id: format-1 }
		#   - { type: format, fstype: ext4,  volume: lvm_partition-0, preserve: false, id: format-2 }
		#   - { type: mount, device: format-0, path: /boot/efi, id: mount-0 }
		#   - { type: mount, device: format-1, path: /boot    , id: mount-1 }
		#   - { type: mount, device: format-2, path: /        , id: mount-2 }
		#   - { type: disk, ptable: gpt, path: /dev/sda,     wipe: superblock-recursive, preserve: false, name: '', grub_device: false, id: disk-sda     }
		#   - { type: partition, device: disk-sda,     size:   -1, wipe: superblock,             number: 1, preserve: false,                    id: partition-3 }
		#   - { type: lvm_volgroup, devices: [partition-3], preserve: false, name: vg01, id: lvm_volgroup-1 }
		#   - { type: lvm_partition, volgroup: lvm_volgroup-1, size: 100%, wipe: superblock, preserve: false, name: lv-home, id: lvm_partition-1 }
		#   - { type: format, fstype: ext4,  volume: lvm_partition-1, preserve: false, id: format-3 }
		#   - { type: mount, device: format-3, path: /home    , id: mount-3 }
_EOT_
	# --- identity ------------------------------------------------------------
	NETCFG_GET_HOSTNAME=`awk '!/#/&&/ netcfg\/get_hostname / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_DOMAIN=`awk '!/#/&&/ netcfg\/get_domain / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_FULLNAME=`awk '!/#/&&/ passwd\/user-fullname / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USERNAME=`awk '!/#/&&/ passwd\/username / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_PASSWORD=`awk '!/#/&&/ passwd\/user-password / {print $4;}' ${PRESEED_CFG}`
	PASSWD_USER_PASSWORD_CRYPTED=`awk '!/#/&&/ passwd\/user-password-crypted / {print $4;}' ${PRESEED_CFG}`
	if [ "${PASSWD_USER_PASSWORD_CRYPTED}" = "" ]; then
		PASSWD_USER_PASSWORD_CRYPTED=`mkpasswd --method=SHA-512 --rounds=4096 ${PASSWD_USER_PASSWORD}`
	fi
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  identity:
		    hostname: ${NETCFG_GET_HOSTNAME}.${NETCFG_GET_DOMAIN}
		    realname: ${PASSWD_USER_FULLNAME}
		    username: ${PASSWD_USERNAME}
		    password: "${PASSWD_USER_PASSWORD_CRYPTED}"
		#   plain_text_passwd: "${PASSWD_USER_PASSWORD}"
_EOT_
	# --- locale --------------------------------------------------------------
	DEBIAN_INSTALLER_LOCALE=`awk '!/#/&&/ debian-installer\/locale / {print $4;}' ${PRESEED_CFG}`
	KEYBOARD_CONFIGURATION_LAYOUTCODE=`awk '!/#/&&/ keyboard-configuration\/layoutcode / {print $4;}' ${PRESEED_CFG}`
	TIME_ZONE=`awk '!/#/&&/ time\/zone / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  locale: ${DEBIAN_INSTALLER_LOCALE}
		  keyboard:
		    layout: ${KEYBOARD_CONFIGURATION_LAYOUTCODE}
		  timezone: ${TIME_ZONE}
_EOT_
	# --- network -------------------------------------------------------------
	NETCFG_CHOOSE_INTERFACE=`awk '!/#/&&/ netcfg\/choose_interface / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_IPADDRESS=`awk '!/#/&&/ netcfg\/get_ipaddress / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NETMASK=`awk '!/#/&&/ netcfg\/get_netmask / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_GATEWAY=`awk '!/#/&&/ netcfg\/get_gateway / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NAMESERVERS=`awk '!/#/&&/ netcfg\/get_nameservers / {print $4;}' ${PRESEED_CFG}`
	NETCFG_GET_NETMASK_BITS=`fncIPv4GetNetmaskBits "${NETCFG_GET_NETMASK}"`
	NETCFG_GET_DOMAIN=`awk '!/#/&&/ netcfg\/get_domain / {print $4;}' ${PRESEED_CFG}`
	DISABLE_DHCP=`awk '!/#/&&(/ netcfg\/disable_dhcp /||/ netcfg\/disable_autoconfig /)&&/true/&&!a[$4]++ {print $4;}' ${PRESEED_CFG}`
	if [ "${NETCFG_CHOOSE_INTERFACE}" = "auto" ]; then
		NETCFG_CHOOSE_INTERFACE=ens160
	fi
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  network:
		    version: 2
		    ethernets:
		      any:
		        match:
		          name: "en*"
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
			          search:
			          - ${NETCFG_GET_DOMAIN}
			          addresses:
			          - ::1
			          - 127.0.0.1
			          - ${NETCFG_GET_NAMESERVERS}
_EOT_
	fi
	cat <<- _EOT_ >> ${USER_DATA}
		        dhcp6: true
		        ipv6-privacy: true
_EOT_
	# --- ssh -----------------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  ssh:
		    allow-pw: true
		    authorized-keys: []
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
	               -e 's/^ *//'
#	               -e 's/ubuntu-desktop[,| ]*//'                                      \
#	               -e 's/ubuntu-server[,| ]*//'                                       \
#	               -e 's/inxi[,| ]*//'                                                \
#	               -e 's/mozc-utils-gui[,| ]*//'                                      \
#	               -e 's/gnome-getting-started-docs-ja[,| ]*//'                       \
#	               -e 's/fonts-noto\([,| ]\)/fonts-noto-core\1/'`
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# source:
		#   id: ubuntu-server
		#   search_drivers: true
		#   id: ubuntu-desktop
		#   search_drivers: true
		# -----------------------------------------------------------------------------
		# codecs:
		#   install: true
		# drivers:
		#   install: true
		# =============================================================================
		  updates: all
		  packages:
_EOT_
	for TASK in ${LIST_TASK}
	do
		echo "  - ${TASK}" >> ${USER_DATA}
	done
#	echo "# -----------------------------------------------------------------------------" >> ${USER_DATA}
	for PACK in ${LIST_PACK}
	do
		echo "  - ${PACK}" >> ${USER_DATA}
	done
	# --- user-data -----------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  user-data:
_EOT_
	# --- user-data: timezone & ntp -------------------------------------------
	TIME_ZONE=`awk '!/#/&&/ time\/zone / {print $4;}' ${PRESEED_CFG}`
	CLOCK_SETUP_NTP_SERVER=`awk '!/#/&&/ clock-setup\/ntp-server / {print $4;}' ${PRESEED_CFG}`
	cat <<- _EOT_ >> ${USER_DATA}
		    ntp:
		      servers:
		      - ${CLOCK_SETUP_NTP_SERVER}
		    timezone: ${TIME_ZONE}
_EOT_
#	# --- user-data: runcmd ---------------------------------------------------
#	cat <<- _EOT_ >> ${USER_DATA}
#		    runcmd:
#		   - shutdown -r now
#	# --- user-data: snap -----------------------------------------------------
#	cat <<- _EOT_ >> ${USER_DATA}
#		#   snap:
#		#     commands:
#		#     - snap install chromium
#_EOT_
#	# --- user-data: runcmd ---------------------------------------------------
#	cat <<- _EOT_ >> ${USER_DATA}
#		    runcmd:
#		    - mkdir -p /etc/NetworkManager/conf.d/
#		    - echo "[keyfile]\nunmanaged-devices=none" > /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
#		    - apt -qq    update
#		    - apt -qq -y full-upgrade
#		    - shutdown -r now
#_EOT_
#	# --- late-commands -------------------------------------------------------
#	cat <<- _EOT_ >> ${USER_DATA}
#		# =============================================================================
#		  late-commands:
#		  - shutdown -r now
#_EOT_
#	# --- InstallProgress -----------------------------------------------------
#	cat <<- _EOT_ >> ${USER_DATA}
#		# =============================================================================
#		# InstallProgress:
#		#   reboot: yes
#_EOT_
	# --- power_state ---------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		  power_state:
		    mode: reboot
_EOT_
	# --- end of file ---------------------------------------------------------
	cat <<- _EOT_ >> ${USER_DATA}
		# =============================================================================
		# memo:
		#   https://ubuntu.com/server/docs/install/autoinstall-reference
		#   https://github.com/canonical/cloud-init/
		#   https://cloudinit.readthedocs.io/
		#   https://curtin.readthedocs.io/
		# =============================================================================
		# Created at `date +"%Y/%m/%d %H:%M:%S"`
		# === EOF =====================================================================
_EOT_
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0}]"
	echo "*******************************************************************************"
	exit 0
# === EOF =====================================================================
