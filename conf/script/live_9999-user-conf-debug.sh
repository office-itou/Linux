#!/bin/sh

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
#	set -o ignoreeof					# Do not exit with Ctrl+D
#	set +m								# Disable job control
#	set -e								# End with status other than 0
#	set -u								# End with undefined variable reference
#	set -o pipefail						# End with in pipe error

#	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	PROG_PATH="9999-user-conf-debug.sh"
#	PROG_DIRS="${PROG_PATH%/*}"
	PROG_NAME="${PROG_PATH##*/}"

	if [ -f "/var/lib/live/config/${PROG_NAME%.*}" ]; then
		# shellcheck disable=SC2028
		echo "\033[m\033[41malready runned: ${PROG_PATH}\033[m" | tee /dev/console
		return
	fi

	# shellcheck disable=SC2028
	echo "\033[m\033[45mstart: ${PROG_PATH}\033[m" | tee /dev/console

	# --- put debug parameter -------------------------------------------------
	if [ "${LIVE_BOOT_DEBUG:-}" = "true" ] || [ "${LIVE_CONFIG_DEBUG:-}" = "true" ]; then
		echo "=== put debug parameter [ start ] =============================================" | tee /dev/console
		echo "--- common parameter ----------------------------------------------------------" | tee /dev/console
		echo "LIVE_DEBUGOUT                         = [${LIVE_DEBUGOUT:-}]"                    | tee /dev/console
		echo "LIVE_OS_NAME                          = [${LIVE_OS_NAME:-}]"                     | tee /dev/console
		echo "LIVE_OS_ID                            = [${LIVE_OS_ID:-}]"                       | tee /dev/console
		echo "LIVE_PASSWORD                         = [${LIVE_PASSWORD:-}]"                    | tee /dev/console
		echo "LIVE_HGFS                             = [${LIVE_HGFS:-}]"                        | tee /dev/console
		echo "--- live-boot - System Boot Components ----------------------------------------" | tee /dev/console
		echo "DISABLE_CDROM                         = [${DISABLE_CDROM:-}]"                    | tee /dev/console
		echo "DISABLE_DM_VERITY                     = [${DISABLE_DM_VERITY:-}]"                | tee /dev/console
		echo "DISABLE_FAT                           = [${DISABLE_FAT:-}]"                      | tee /dev/console
		echo "DISABLE_FUSE                          = [${DISABLE_FUSE:-}]"                     | tee /dev/console
		echo "DISABLE_NTFS                          = [${DISABLE_NTFS:-}]"                     | tee /dev/console
		echo "DISABLE_USB                           = [${DISABLE_USB:-}]"                      | tee /dev/console
		echo "MINIMAL                               = [${MINIMAL:-}]"                          | tee /dev/console
		echo "PERSISTENCE_FSCK                      = [${PERSISTENCE_FSCK:-}]"                 | tee /dev/console
		echo "FSCKFIX                               = [${FSCKFIX:-}]"                          | tee /dev/console
		echo "LIVE_BOOT_CMDLINE                     = [${LIVE_BOOT_CMDLINE:-}]"                | tee /dev/console
		echo "LIVE_BOOT_DEBUG                       = [${LIVE_BOOT_DEBUG:-}]"                  | tee /dev/console
		echo "LIVE_MEDIA                            = [${LIVE_MEDIA:-}]"                       | tee /dev/console
		echo "LIVE_MEDIA_OFFSET                     = [${LIVE_MEDIA_OFFSET:-}]"                | tee /dev/console
		echo "LIVE_MEDIA_PATH                       = [${LIVE_MEDIA_PATH:-}]"                  | tee /dev/console
		echo "LIVE_MEDIA_TIMEOUT                    = [${LIVE_MEDIA_TIMEOUT:-}]"               | tee /dev/console
		echo "LIVE_PERSISTENCE_REMOVE               = [${LIVE_PERSISTENCE_REMOVE:-}]"          | tee /dev/console
		echo "LIVE_READ_ONLY                        = [${LIVE_READ_ONLY:-}]"                   | tee /dev/console
		echo "LIVE_READ_ONLY_DEVICES                = [${LIVE_READ_ONLY_DEVICES:-}]"           | tee /dev/console
		echo "LIVE_SWAP                             = [${LIVE_SWAP:-}]"                        | tee /dev/console
		echo "LIVE_SWAP_DEVICES                     = [${LIVE_SWAP_DEVICES:-}]"                | tee /dev/console
		echo "LIVE_VERIFY_CHECKSUMS                 = [${LIVE_VERIFY_CHECKSUMS:-}]"            | tee /dev/console
		echo "LIVE_VERIFY_CHECKSUMS_DIGESTS         = [${LIVE_VERIFY_CHECKSUMS_DIGESTS:-}]"    | tee /dev/console
		echo "--- live-config - System Configuration Components -----------------------------" | tee /dev/console
		echo "LIVE_CONFIG_CMDLINE                   = [${LIVE_CONFIG_CMDLINE:-}]"              | tee /dev/console
		echo "LIVE_CONFIG_COMPONENTS                = [${LIVE_CONFIG_COMPONENTS:-}]"           | tee /dev/console
		echo "LIVE_CONFIG_NOCOMPONENTS              = [${LIVE_CONFIG_NOCOMPONENTS:-}]"         | tee /dev/console
		echo "LIVE_DEBCONF_PRESEED                  = [${LIVE_DEBCONF_PRESEED:-}]"             | tee /dev/console
		echo "LIVE_HOSTNAME                         = [${LIVE_HOSTNAME:-}]"                    | tee /dev/console
		echo "LIVE_USERNAME                         = [${LIVE_USERNAME:-}]"                    | tee /dev/console
		echo "LIVE_USER_DEFAULT_GROUPS              = [${LIVE_USER_DEFAULT_GROUPS:-}]"         | tee /dev/console
		echo "LIVE_USER_FULLNAME                    = [${LIVE_USER_FULLNAME:-}]"               | tee /dev/console
		echo "LIVE_LOCALES                          = [${LIVE_LOCALES:-}]"                     | tee /dev/console
		echo "LIVE_TIMEZONE                         = [${LIVE_TIMEZONE:-}]"                    | tee /dev/console
		echo "LIVE_KEYBOARD_MODEL                   = [${LIVE_KEYBOARD_MODEL:-}]"              | tee /dev/console
		echo "LIVE_KEYBOARD_LAYOUTS                 = [${LIVE_KEYBOARD_LAYOUTS:-}]"            | tee /dev/console
		echo "LIVE_KEYBOARD_VARIANTS                = [${LIVE_KEYBOARD_VARIANTS:-}]"           | tee /dev/console
		echo "LIVE_KEYBOARD_OPTIONS                 = [${LIVE_KEYBOARD_OPTIONS:-}]"            | tee /dev/console
		echo "LIVE_SYSV_RC                          = [${LIVE_SYSV_RC:-}]"                     | tee /dev/console
		echo "LIVE_UTC                              = [${LIVE_UTC:-}]"                         | tee /dev/console
		echo "LIVE_X_SESSION_MANAGER                = [${LIVE_X_SESSION_MANAGER:-}]"           | tee /dev/console
		echo "LIVE_XORG_DRIVER                      = [${LIVE_XORG_DRIVER:-}]"                 | tee /dev/console
		echo "LIVE_XORG_RESOLUTION                  = [${LIVE_XORG_RESOLUTION:-}]"             | tee /dev/console
		echo "LIVE_WLAN_DRIVER                      = [${LIVE_WLAN_DRIVER:-}]"                 | tee /dev/console
		echo "LIVE_HOOKS                            = [${LIVE_HOOKS:-}]"                       | tee /dev/console
		echo "LIVE_CONFIG_NOROOT                    = [${LIVE_CONFIG_NOROOT:-}]"               | tee /dev/console
		echo "LIVE_CONFIG_NOAUTOLOGIN               = [${LIVE_CONFIG_NOAUTOLOGIN:-}]"          | tee /dev/console
		echo "LIVE_CONFIG_NOX11AUTOLOGIN            = [${LIVE_CONFIG_NOX11AUTOLOGIN:-}]"       | tee /dev/console
		echo "LIVE_CONFIG_DEBUG                     = [${LIVE_CONFIG_DEBUG:-}]"                | tee /dev/console
		echo "=== put debug parameter [ end ] ===============================================" | tee /dev/console
		set -x
	fi

	# --- create state file ---------------------------------------------------
	mkdir -p /var/lib/live/config
	touch "/var/lib/live/config/${PROG_NAME%.*}"
	# shellcheck disable=SC2028
	echo "\033[m\033[45mcomplete: ${PROG_PATH}\033[m" | tee /dev/console

### eof #######################################################################
