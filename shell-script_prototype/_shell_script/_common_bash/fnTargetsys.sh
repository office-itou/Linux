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
	if command -v systemctl > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt || true)"
		___CNTR="$(systemctl is-system-running || true)"
	fi
	printf "%s,%s" "${___VIRT:-}" "${___CNTR:-}"
	unset ___VIRT
	unset ___CNTR
}
