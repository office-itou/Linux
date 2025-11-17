# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: detecting target virtualization
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _TGET_VIRT : write
# shellcheck disable=SC2148,SC2317,SC2329
fnDetect_virt() {
	if ! command -v systemd-detect-virt > /dev/null 2>&1; then
		return
	fi
	_TGET_VIRT="$(systemd-detect-virt || true)"
	readonly _TGET_VIRT
	_TGET_CNTR=""
	case "$(systemctl is-system-running || true)" in
		offline) _TGET_CNTR="true";;
		*) ;;
	esac
	readonly _TGET_CNTR
}
