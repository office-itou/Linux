#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

#	readonly    PROG_PATH="$0"
	readonly    PROG_PATH="9999-user-conf-debug.sh"
#	readonly    PROG_DIRS="${PROG_PATH%/*}"
	readonly    PROG_NAME="${PROG_PATH##*/}"

	# --- start -------------------------------------------------------------------
	if [ -f "/var/lib/live/config/${PROG_NAME%.*}" ]; then
		# shellcheck disable=SC2028
		printf "\033[m\033[41malready runned: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1
		return
	fi

	printf "\033[m\033[45mstart: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1

	# --- put debug parameter -------------------------------------------------
	if [ "${LIVE_DEBUGOUT:-}" = "true" ] || [ "${LIVE_BOOT_DEBUG:-}" = "true" ] || [ "${LIVE_CONFIG_DEBUG:-}" = "true" ]; then
		echo "=== put debug parameter [ start ] =============================================" | tee /dev/console 2>&1
		echo "--- common parameter ----------------------------------------------------------" | tee /dev/console 2>&1
		echo "LIVE_DEBUGOUT                         = [${LIVE_DEBUGOUT:-}]"                    | tee /dev/console 2>&1
		echo "LIVE_OS_NAME                          = [${LIVE_OS_NAME:-}]"                     | tee /dev/console 2>&1
		echo "LIVE_OS_ID                            = [${LIVE_OS_ID:-}]"                       | tee /dev/console 2>&1
		echo "LIVE_PASSWORD                         = [${LIVE_PASSWORD:-}]"                    | tee /dev/console 2>&1
		echo "LIVE_HGFS                             = [${LIVE_HGFS:-}]"                        | tee /dev/console 2>&1
		echo "--- live-boot - System Boot Components ----------------------------------------" | tee /dev/console 2>&1
		echo "DISABLE_CDROM                         = [${DISABLE_CDROM:-}]"                    | tee /dev/console 2>&1
		echo "DISABLE_DM_VERITY                     = [${DISABLE_DM_VERITY:-}]"                | tee /dev/console 2>&1
		echo "DISABLE_FAT                           = [${DISABLE_FAT:-}]"                      | tee /dev/console 2>&1
		echo "DISABLE_FUSE                          = [${DISABLE_FUSE:-}]"                     | tee /dev/console 2>&1
		echo "DISABLE_NTFS                          = [${DISABLE_NTFS:-}]"                     | tee /dev/console 2>&1
		echo "DISABLE_USB                           = [${DISABLE_USB:-}]"                      | tee /dev/console 2>&1
		echo "MINIMAL                               = [${MINIMAL:-}]"                          | tee /dev/console 2>&1
		echo "PERSISTENCE_FSCK                      = [${PERSISTENCE_FSCK:-}]"                 | tee /dev/console 2>&1
		echo "FSCKFIX                               = [${FSCKFIX:-}]"                          | tee /dev/console 2>&1
		echo "LIVE_BOOT_CMDLINE                     = [${LIVE_BOOT_CMDLINE:-}]"                | tee /dev/console 2>&1
		echo "LIVE_BOOT_DEBUG                       = [${LIVE_BOOT_DEBUG:-}]"                  | tee /dev/console 2>&1
		echo "LIVE_MEDIA                            = [${LIVE_MEDIA:-}]"                       | tee /dev/console 2>&1
		echo "LIVE_MEDIA_OFFSET                     = [${LIVE_MEDIA_OFFSET:-}]"                | tee /dev/console 2>&1
		echo "LIVE_MEDIA_PATH                       = [${LIVE_MEDIA_PATH:-}]"                  | tee /dev/console 2>&1
		echo "LIVE_MEDIA_TIMEOUT                    = [${LIVE_MEDIA_TIMEOUT:-}]"               | tee /dev/console 2>&1
		echo "LIVE_PERSISTENCE_REMOVE               = [${LIVE_PERSISTENCE_REMOVE:-}]"          | tee /dev/console 2>&1
		echo "LIVE_READ_ONLY                        = [${LIVE_READ_ONLY:-}]"                   | tee /dev/console 2>&1
		echo "LIVE_READ_ONLY_DEVICES                = [${LIVE_READ_ONLY_DEVICES:-}]"           | tee /dev/console 2>&1
		echo "LIVE_SWAP                             = [${LIVE_SWAP:-}]"                        | tee /dev/console 2>&1
		echo "LIVE_SWAP_DEVICES                     = [${LIVE_SWAP_DEVICES:-}]"                | tee /dev/console 2>&1
		echo "LIVE_VERIFY_CHECKSUMS                 = [${LIVE_VERIFY_CHECKSUMS:-}]"            | tee /dev/console 2>&1
		echo "LIVE_VERIFY_CHECKSUMS_DIGESTS         = [${LIVE_VERIFY_CHECKSUMS_DIGESTS:-}]"    | tee /dev/console 2>&1
		echo "--- live-config - System Configuration Components -----------------------------" | tee /dev/console 2>&1
		echo "LIVE_CONFIG_CMDLINE                   = [${LIVE_CONFIG_CMDLINE:-}]"              | tee /dev/console 2>&1
		echo "LIVE_CONFIG_COMPONENTS                = [${LIVE_CONFIG_COMPONENTS:-}]"           | tee /dev/console 2>&1
		echo "LIVE_CONFIG_NOCOMPONENTS              = [${LIVE_CONFIG_NOCOMPONENTS:-}]"         | tee /dev/console 2>&1
		echo "LIVE_DEBCONF_PRESEED                  = [${LIVE_DEBCONF_PRESEED:-}]"             | tee /dev/console 2>&1
		echo "LIVE_HOSTNAME                         = [${LIVE_HOSTNAME:-}]"                    | tee /dev/console 2>&1
		echo "LIVE_USERNAME                         = [${LIVE_USERNAME:-}]"                    | tee /dev/console 2>&1
		echo "LIVE_USER_DEFAULT_GROUPS              = [${LIVE_USER_DEFAULT_GROUPS:-}]"         | tee /dev/console 2>&1
		echo "LIVE_USER_FULLNAME                    = [${LIVE_USER_FULLNAME:-}]"               | tee /dev/console 2>&1
		echo "LIVE_LOCALES                          = [${LIVE_LOCALES:-}]"                     | tee /dev/console 2>&1
		echo "LIVE_TIMEZONE                         = [${LIVE_TIMEZONE:-}]"                    | tee /dev/console 2>&1
		echo "LIVE_KEYBOARD_MODEL                   = [${LIVE_KEYBOARD_MODEL:-}]"              | tee /dev/console 2>&1
		echo "LIVE_KEYBOARD_LAYOUTS                 = [${LIVE_KEYBOARD_LAYOUTS:-}]"            | tee /dev/console 2>&1
		echo "LIVE_KEYBOARD_VARIANTS                = [${LIVE_KEYBOARD_VARIANTS:-}]"           | tee /dev/console 2>&1
		echo "LIVE_KEYBOARD_OPTIONS                 = [${LIVE_KEYBOARD_OPTIONS:-}]"            | tee /dev/console 2>&1
		echo "LIVE_SYSV_RC                          = [${LIVE_SYSV_RC:-}]"                     | tee /dev/console 2>&1
		echo "LIVE_UTC                              = [${LIVE_UTC:-}]"                         | tee /dev/console 2>&1
		echo "LIVE_NTP                              = [${LIVE_NTP:-}]"                         | tee /dev/console 2>&1
		echo "LIVE_FBACK_NTP                        = [${LIVE_FBACK_NTP:-}]"                   | tee /dev/console 2>&1
		echo "LIVE_X_SESSION_MANAGER                = [${LIVE_X_SESSION_MANAGER:-}]"           | tee /dev/console 2>&1
		echo "LIVE_XORG_DRIVER                      = [${LIVE_XORG_DRIVER:-}]"                 | tee /dev/console 2>&1
		echo "LIVE_XORG_RESOLUTION                  = [${LIVE_XORG_RESOLUTION:-}]"             | tee /dev/console 2>&1
		echo "LIVE_WLAN_DRIVER                      = [${LIVE_WLAN_DRIVER:-}]"                 | tee /dev/console 2>&1
		echo "LIVE_HOOKS                            = [${LIVE_HOOKS:-}]"                       | tee /dev/console 2>&1
		echo "LIVE_CONFIG_NOROOT                    = [${LIVE_CONFIG_NOROOT:-}]"               | tee /dev/console 2>&1
		echo "LIVE_CONFIG_NOAUTOLOGIN               = [${LIVE_CONFIG_NOAUTOLOGIN:-}]"          | tee /dev/console 2>&1
		echo "LIVE_CONFIG_NOX11AUTOLOGIN            = [${LIVE_CONFIG_NOX11AUTOLOGIN:-}]"       | tee /dev/console 2>&1
		echo "LIVE_CONFIG_DEBUG                     = [${LIVE_CONFIG_DEBUG:-}]"                | tee /dev/console 2>&1
		echo "=== put debug parameter [ end ] ===============================================" | tee /dev/console 2>&1
		set -x
	fi

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	printf "\033[m\033[45mcomplete: %s\033[m\n" "${PROG_PATH}" | tee /dev/console 2>&1

### eof #######################################################################
