# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: target system state
#   input :            : unused
#   output:   stdout   : result
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnTargetsys() {
	___VIRT=""							# virtualization (ex. vmware)
	___CHRT=""							# is chgroot     (empty: none, else: chroot)
	___CNTR=""							# is container   (empty: none, else: container)
	if command -v systemd-detect-virt > /dev/null 2>&1; then
		___VIRT="$(systemd-detect-virt --vm || true)"
		systemd-detect-virt --quiet --chroot    && ___CHRT="true"
		systemd-detect-virt --quiet --container && ___CNTR="true"
	fi
	readonly ___VIRT
	readonly ___CHRT
	readonly ___CNTR
	printf "%s,%s,%s" "${___VIRT:-}" "${___CHRT:-}" "${___CNTR:-}"
	unset ___VIRT ___CHRT ___CNTR
}
