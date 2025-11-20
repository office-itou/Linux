# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: clean device
#   input :     $1     : device name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
fnClean_device() {
	__FUNC_NAME="fnClean_device"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	__DEVS="${1:-}"
	# --- remove lvm ----------------------------------------------------------
	if [ -n "${__DEVS:-}" ]; then
		__PATH="$(fnFind_command 'pvs' | sort | head -n 1)"
		if [ -n "${__PATH:-}" ]; then
			for __LINE in $(pvs --noheading --separator '|' | cut -d '|' -f 1-2 | grep "${__DEVS}" | sort -u)
			do
				__NAME="${__LINE#*\|}"		# vg
				fnMsgout "${_PROG_NAME:-}" "remove" "vg=[${__NAME}]"
				lvremove -q -y -ff "${__NAME}"
			done
			for __LINE in $(pvs --noheading --separator '|' | cut -d '|' -f 1-2 | grep "${__DEVS}" | sort -u)
			do
				__NAME="${__LINE%\|*}"		# pv
				fnMsgout "${_PROG_NAME:-}" "remove" "pv=[${__NAME}]"
				pvremove -q -y -ff "${__NAME}"
			done
		fi
		# --- cleaning the device ---------------------------------------------
		dd if=/dev/zero of="/dev/${__DEVS}" bs=1M count=10
	fi
	# --- unmount -------------------------------------------------------------
	if mount | grep -q '/media'; then
		umount /media || umount -l /media || true
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
}
