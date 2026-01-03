# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make autoinst.cfg files for isolinux
#   input :     $1     : kernel path
#   input :     $2     : initrd path
#   input :     $3     : initrd path (gui)
#   input :     $4     : nic name
#   input :     $5     : host name
#   input :     $6     : ipv4 cidr
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var : _OSET_MDIA : read
#   g-var : _NWRK_HOST : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NWRK_WGRP : read
#   g-var : _NICS_NAME : read
#   g-var : _IPV4_ADDR : read
#   g-var : _IPV4_MASK : read
#   g-var : _IPV4_GWAY : read
#   g-var : _IPV4_NSVR : read
function fnMk_isofile_ilnx_autoinst() {
	declare -r    __PATH_FKNL="${1:?}"
	declare -r    __PATH_FIRD="${2:?}"
	declare -r    __PATH_GUIS="${3:-}"
	declare -r    __NICS_NAME="${4:?}"
	declare -r    __NWRK_HOST="${5:?}"
	declare -r    __IPV4_CIDR="${6:-}"
	declare -r -a __OPTN_BOOT=("${@:7}")
	declare -a    __BOPT=()				# boot options
	declare       __DIRS=""
	# --- convert -------------------------------------------------------------
	__BOPT=("${__OPTN_BOOT[@]:-}")
	__BOPT=("${__BOPT[@]//\$\{srvraddr\}/}")
	__BOPT=("${__BOPT[@]//\$\{hostname\}/${__NWRK_HOST:-}}")
	__BOPT=("${__BOPT[@]//\$\{ethrname\}/${__NICS_NAME:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4addr\}/${_IPV4_ADDR:-}${__IPV4_CIDR:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4mask\}/${_IPV4_MASK:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4gway\}/${_IPV4_GWAY:-}}")
	__BOPT=("${__BOPT[@]//\$\{ipv4nsvr\}/${_IPV4_NSVR:-}}")
	__BOPT=("${__BOPT[@]}")
	# --- default--------------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		label auto-install
		  menu label ^Automatic installation
		  menu default
		  linux  ${__PATH_FKNL}
		  initrd ${__PATH_FIRD}
		  append ${__BOPT[@]} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
_EOT_
	# --- gui -----------------------------------------------------------------
	if [[ -n "${__PATH_GUIS:-}" ]]; then
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true

			label auto-install-gui
			  menu label ^Automatic installation gui
			  linux  ${__PATH_FKNL}
			  initrd ${__PATH_GUIS}
			  append ${__BOPT[@]} --- quiet${_MENU_MODE:+" vga=${_MENU_MODE}"}
_EOT_
	fi
	# --- system command ------------------------------------------------------
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
#
#		label System-command
#		  menu label ^[ System command ... ]
#
#		label Hardware-info
#		  menu label ^- Hardware info
#		  com32 hdt.c32
#
#		label System-shutdown
#		  menu label ^- System shutdown
#		  com32 poweroff.c32
#
#		label System-restart
#		  menu label ^- System restart
#		  com32 reboot.c32
#_EOT_
	unset __DIRS
}
