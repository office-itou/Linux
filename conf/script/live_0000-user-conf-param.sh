#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	PROG_PATH="0000-user-conf-param.sh"
#	PROG_DIRS="${PROG_PATH%/*}"
	PROG_NAME="${PROG_PATH##*/}"

	# shellcheck disable=SC2028
	echo "\033[m\033[45mstart: ${PROG_PATH}\033[m" | tee /dev/console

	# --- set live parameter --------------------------------------------------
	LIVE_DEBUGOUT=""

	_DISTRIBUTION="$(lsb_release --id --short)"
	LIVE_OS_NAME="${_DISTRIBUTION:-Linux}"
	LIVE_OS_ID="$(echo "${LIVE_OS_NAME}" | sed -e 's/\(.*\)/\L\1/g' -e 's% %-%g')"

	LIVE_HOSTNAME="${LIVE_HOSTNAME:-live-${LIVE_OS_ID:-unknown}}"
	LIVE_USERNAME="${LIVE_USERNAME:-user}"
	LIVE_PASSWORD="${LIVE_PASSWORD:-live}"
	LIVE_USER_FULLNAME="${LIVE_USER_FULLNAME:-${LIVE_OS_NAME:-Unknown} Live user}"
	LIVE_USER_DEFAULT_GROUPS="${LIVE_USER_DEFAULT_GROUPS:-audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor sudo}"

	LIVE_UTC="yes"
	LIVE_LOCALES="ja_JP.UTF-8"
	LIVE_TIMEZONE="Asia/Tokyo"
	LIVE_KEYBOARD_MODEL="pc105"
	LIVE_KEYBOARD_LAYOUTS="jp"
	LIVE_KEYBOARD_VARIANTS="OADG109A"
	LIVE_KEYBOARD_OPTIONS=""
	LIVE_XORG_RESOLUTION="${LIVE_XORG_RESOLUTION:-1024x768}"

	LIVE_HGFS="/mnt/hgfs"

	export LIVE_DEBUGOUT
	export LIVE_OS_NAME
	export LIVE_OS_ID
	export LIVE_HGFS

	# --- live-boot - System Boot Components ----------------------------------
	# https://manpages.debian.org/bookworm/live-boot-doc/index.html
	# /etc/live/boot.conf
	# /etc/live/boot/*
	# (media)/live/boot.conf
	# (media)/live/boot/*
	export DISABLE_CDROM									# Disable support for booting from CD-ROMs. If set to 'true' mkinitramfs will build an initramfs without the kernel modules for reading CD-ROMs.
	export DISABLE_DM_VERITY								# Disable support for dm-verity. If set to true true' mkinitramfs will build an initramfs without the kernel module dm-verity and some other dm modules. Also the default mount binary is used instead of the util-linux one.
	export DISABLE_FAT										# Disable support for booting from FAT file systems. If set to 'true' mkinitramfs will build an initramfs without the kernel module vfat and some nls_* modules.
	export DISABLE_FUSE										# Disable support for booting from FUSE-based file systems. If set to 'true' mkinitramfs will build an initramfs without the kernel module fuse and file systems that depend on it (like curlftpfs and httpfs2).
	export DISABLE_NTFS										# Disable support for booting from NTFS file systems. If set to 'true' mkinitramfs will build an initramfs without the kernel module ntfs.
	export DISABLE_USB										# Disable support for booting from USB devices. If set to 'true' mkinitramfs will build an initramfs without the kernel module sd_mod.
	export MINIMAL											# Build a minimal initramfs. If set to 'true' mkinitramfs will build an initramfs without some udev scripts and without rsync.
	export PERSISTENCE_FSCK									# Run fsck on persistence filesystem on boot. Will attempt to repair errors. The execution log will be saved in /var/log/live/fsck.log.
	export FSCKFIX											# If PERSISTENCE_FSCK or forcefsck are set, will pass -y to fsck to stop it from asking questions interactively and assume yes to all queries.
	export LIVE_BOOT_CMDLINE								# This variable corresponds to the bootloader command line.
	export LIVE_BOOT_DEBUG									# 
	export LIVE_MEDIA										# 
	export LIVE_MEDIA_OFFSET								# 
	export LIVE_MEDIA_PATH									# 
	export LIVE_MEDIA_TIMEOUT								# 
	export LIVE_PERSISTENCE_REMOVE							# 
	export LIVE_READ_ONLY									# 
	export LIVE_READ_ONLY_DEVICES							# 
	export LIVE_SWAP										# 
	export LIVE_SWAP_DEVICES								# 
	export LIVE_VERIFY_CHECKSUMS							# 
	export LIVE_VERIFY_CHECKSUMS_DIGESTS					# 

	# --- live-config - System Configuration Components -----------------------
	# https://manpages.debian.org/bookworm/live-config-doc/live-config.7.en.html
	# /etc/live/config.conf
	# /etc/live/config.conf.d/*.conf
	# (media)live/config.conf
	# (media)live/config.conf.d/*.conf
	export LIVE_CONFIG_CMDLINE								# This variable corresponds to the bootloader command line.
	export LIVE_CONFIG_COMPONENTS							# This variable corresponds to the 'live-config.components=COMPONENT1,COMPONENT2, ... COMPONENTn' parameter.
	export LIVE_CONFIG_NOCOMPONENTS							# This variable corresponds to the 'live-config.nocomponents=COMPONENT1,COMPONENT2, ... COMPONENTn' parameter.
	export LIVE_DEBCONF_PRESEED								# This variable corresponds to the 'live-config.debconf-preseed=filesystem|medium|URL1|URL2| ... |URLn' parameter.
	export LIVE_HOSTNAME									# This variable corresponds to the 'live-config.hostname=HOSTNAME' parameter.
	export LIVE_USERNAME									# This variable corresponds to the 'live-config.username=USERNAME' parameter.
	export LIVE_USER_DEFAULT_GROUPS							# This variable corresponds to the 'live-config.user-default-groups="GROUP1,GROUP2 ... GROUPn"' parameter.
	export LIVE_USER_FULLNAME								# This variable corresponds to the 'live-config.user-fullname="USER FULLNAME"' parameter.
	export LIVE_LOCALES										# This variable corresponds to the 'live-config.locales=LOCALE1,LOCALE2 ... LOCALEn' parameter.
	export LIVE_TIMEZONE									# This variable corresponds to the 'live-config.timezone=TIMEZONE' parameter.
	export LIVE_KEYBOARD_MODEL								# This variable corresponds to the 'live-config.keyboard-model=KEYBOARD_MODEL' parameter.
	export LIVE_KEYBOARD_LAYOUTS							# This variable corresponds to the 'live-config.keyboard-layouts=KEYBOARD_LAYOUT1,KEYBOARD_LAYOUT2 ... KEYBOARD_LAYOUTn' parameter.
	export LIVE_KEYBOARD_VARIANTS							# This variable corresponds to the 'live-config.keyboard-variants=KEYBOARD_VARIANT1,KEYBOARD_VARIANT2 ... KEYBOARD_VARIANTn' parameter.
	export LIVE_KEYBOARD_OPTIONS							# This variable corresponds to the 'live-config.keyboard-options=KEYBOARD_OPTIONS' parameter.
	export LIVE_SYSV_RC										# This variable corresponds to the 'live-config.sysv-rc=SERVICE1,SERVICE2 ... SERVICEn' parameter.
	export LIVE_UTC											# This variable corresponds to the 'live-config.utc=yes|no' parameter.
	export LIVE_X_SESSION_MANAGER							# This variable corresponds to the 'live-config.x-session-manager=X_SESSION_MANAGER' parameter.
	export LIVE_XORG_DRIVER									# This variable corresponds to the 'live-config.xorg-driver=XORG_DRIVER' parameter.
	export LIVE_XORG_RESOLUTION								# This variable corresponds to the 'live-config.xorg-resolution=XORG_RESOLUTION' parameter.
	export LIVE_WLAN_DRIVER									# This variable corresponds to the 'live-config.wlan-driver=WLAN_DRIVER' parameter.
	export LIVE_HOOKS										# This variable corresponds to the 'live-config.hooks=filesystem|medium|URL1|URL2| ... |URLn' parameter.
	export LIVE_CONFIG_DEBUG								# This variable corresponds to the 'live-config.debug' parameter.

	# --- set command line ----------------------------------------------------
	_CMDLINE="$(cat /proc/cmdline)"
	if [ -n "${_CMDLINE}" ]; then
		LIVE_BOOT_CMDLINE="${LIVE_BOOT_CMDLINE:-${_CMDLINE}}"
		LIVE_CONFIG_CMDLINE="${LIVE_CONFIG_CMDLINE:-${_CMDLINE}}"
	fi

	# --- set boot parameter --------------------------------------------------
	for _PARAMETER in ${_CMDLINE:-}
	do
		case "${_PARAMETER}" in
			debug        | \
			debugout       ) LIVE_DEBUGOUT="true";;
			username=*     ) LIVE_USERNAME="${_PARAMETER#*username=}";;
			password=*     ) LIVE_PASSWORD="${_PARAMETER#*password=}";;
			emptypwd       ) LIVE_PASSWORD="";;
			hostname=*     ) LIVE_HOSTNAME="${_PARAMETER#*hostname=}";;
			utc=*          ) LIVE_UTC="${_PARAMETER#*utc=}";;
			locales=*      ) LIVE_LOCALES="${_PARAMETER#*locales=}";;
			timezone=*     ) LIVE_TIMEZONE="${_PARAMETER#*timezone=}";;
			key_model=*    ) LIVE_KEYBOARD_MODEL="${_PARAMETER#*key_model=}";;
			key_layouts=*  ) LIVE_KEYBOARD_LAYOUTS="${_PARAMETER#*key_layouts=}";;
			key_variants=* ) LIVE_KEYBOARD_VARIANTS="${_PARAMETER#*key_variants=}";;
			key_options=*  ) LIVE_KEYBOARD_OPTIONS="${_PARAMETER#*key_options=}";;
			xresolution=*  ) LIVE_XORG_RESOLUTION="${_PARAMETER#*xresolution=}";;
			*) ;;
		esac
	done

	# --- set debug parameter -------------------------------------------------
	LIVE_BOOT_DEBUG="${LIVE_DEBUGOUT:-${LIVE_BOOT_DEBUG}}"
	LIVE_CONFIG_DEBUG="${LIVE_DEBUGOUT:-${LIVE_CONFIG_DEBUG}}"

	# --- set system parameter ------------------------------------------------
	LIVE_HOSTNAME="live-${LIVE_OS_ID:-unknown}"
	LIVE_USER_FULLNAME="${LIVE_OS_NAME:-Unknown} Live user (${LIVE_USERNAME:-unknown})"

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console

### eof #######################################################################
