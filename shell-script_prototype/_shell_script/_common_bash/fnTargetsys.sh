# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnTargetsys() {
	declare       ___VIRT=""
	declare       ___CNTR=""
	___VIRT="$(systemd-detect-virt)"
	___CNTR="$(systemctl is-system-running)"
	printf "%s,%s" "${___VIRT:-}" "${___CNTR:-}"
}
