# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: input method skeleton
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
fnSetup_skel_im() {
	__FUNC_NAME="fnSetup_skel_im"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if command -v fcitx5 > /dev/null 2>&1; then
		fnSetup_skel_im_fcitx5
	elif command -v ibus > /dev/null 2>&1; then
		fnSetup_skel_im_ibus
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
