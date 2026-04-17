# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live cd-image (create isolinux)
#   input :     $1     : output directory
#   input :     $2     : volume id
#   input :     $3     : menu entry
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_CDFS : read
#   g-var : _FILE_ICFG : read
#   g-var : _FILE_MENU : read
#   g-var : _FILE_THME : read
#   g-var : _MENU_SPLS : read
#   g-var : _MENU_TOUT : read
#   g-var : _MENU_RESO : read
#   g-var : _MENU_DPTH : read
#   g-var : _SECU_OPTN : read
function fnMake_live_cdimg_ilnx() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OUTD="${1:?}"	# output directory
	declare -r    __TGET_VLID="${2:?}"	# volume id
	declare -r    __TGET_ENTR="${3:?}"	# menu entry
	declare -r    __INPD="/isolinux"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/isolinux"		# output directory
	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __TITL="Live system"						# title
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	# --- create isolinux.cfg -------------------------------------------------
	fnIlnx_conf  "${__ICFG:?}" "${__INPD:-}/${_FILE_MENU:?}" "${__INPD:-}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnIlnx_theme "${__THME:?}" "${__TITL:?}" "/LiveOS/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		label ${__TGET_ENTR// /-}
		  menu label ^${__TGET_ENTR}
		  menu default
		  linux  /LiveOS/vmlinuz
		  initrd /LiveOS/initrd.img
		  append root=live:CDLABEL=${__TGET_VLID} rd.live.image rd.live.overlay.overlayfs=1${_SECU_OPTN:+" ${_SECU_OPTN}"} --- quiet
_EOT_
	[[ -e "${__ICFG:?}" ]] && cp --preserve=timestamps "${__ICFG:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__CDFS:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__CDFS:?}/${__INPD:?}"
#	unset 
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
