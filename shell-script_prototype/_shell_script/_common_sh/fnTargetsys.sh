# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnTargetsys() {
	___VIRT=""
	___CNTR=""
	___CHRT=""
	if command -v systemctl > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt 2> /dev/null || true)"
		___CNTR="$(systemctl --no-warn is-system-running 2> /dev/null || true)"
	fi
	if command -v ischroot > /dev/null 2>&1; then
		ischroot -t && ___CHRT="true"
	fi
	printf "%s,%s" "${___VIRT:-}" "${___CHRT:-}"
	unset ___VIRT ___CNTR ___CHRT
}
