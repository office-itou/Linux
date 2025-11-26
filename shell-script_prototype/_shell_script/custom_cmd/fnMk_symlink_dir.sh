# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make directory
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _DIRS_TOPS : read
#   g-var : _DIRS_HGFS : read
#   g-var : _DIRS_HTML : read
#   g-var : _DIRS_SAMB : read
#   g-var : _DIRS_TFTP : read
#   g-var : _DIRS_USER : read
#   g-var : _DIRS_SHAR : read
#   g-var : _DIRS_CONF : read
#   g-var : _DIRS_DATA : read
#   g-var : _DIRS_KEYS : read
#   g-var : _DIRS_MKOS : read
#   g-var : _DIRS_TMPL : read
#   g-var : _DIRS_SHEL : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_ISOS : read
#   g-var : _DIRS_LOAD : read
#   g-var : _DIRS_RMAK : read
#   g-var : _DIRS_CACH : read
#   g-var : _DIRS_CTNR : read
#   g-var : _DIRS_CHRT : read
#   g-var : _SAMB_USER : read
#   g-var : _SAMB_GRUP : read
function fnMk_symlink_dir() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create directory ----------------------------------------------------
	mkdir -p \
		"${_DIRS_TOPS:?}" \
		"${_DIRS_HGFS:?}" \
		"${_DIRS_HTML:?}" \
		"${_DIRS_SAMB:?}"/{adm/{commands,profiles},pub/{_license,contents/{disc,dlna/{movies,others,photos,sounds}},hardware,software,resource/{image/{linux,windows},source/git}},usr} \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,locale,i386-pc,i386-efi,x86_64-efi},ipxe,menu-bios/pxelinux.cfg,menu-efi64/pxelinux.cfg} \
		"${_DIRS_USER:?}"/private \
		"${_DIRS_SHAR:?}" \
		"${_DIRS_CONF:?}"/{_repository,agama,autoyast,kickstart,nocloud,preseed,windows} \
		"${_DIRS_DATA:?}" \
		"${_DIRS_KEYS:?}" \
		"${_DIRS_MKOS:?}"/{mkosi.build.d,mkosi.clean.d,mkosi.conf.d,mkosi.extra,mkosi.finalize.d,mkosi.postinst.d,mkosi.postoutput.d,mkosi.prepare.d,mkosi.repart,mkosi.sync.d} \
		"${_DIRS_TMPL:?}" \
		"${_DIRS_SHEL:?}" \
		"${_DIRS_IMGS:?}" \
		"${_DIRS_ISOS:?}" \
		"${_DIRS_LOAD:?}" \
		"${_DIRS_RMAK:?}" \
		"${_DIRS_CACH:?}" \
		"${_DIRS_CTNR:?}" \
		"${_DIRS_CHRT:?}"
	# --- change file mode ------------------------------------------------
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB}/"*
	chmod -R  770 "${_DIRS_SAMB}/"*
	chmod    1777 "${_DIRS_SAMB}/adm/profiles"
	# --- create symbolic link --------------------------------------------
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ]] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ]] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ]] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ]] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ]] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_HTML:?}/${_DIRS_TFTP##*/}"               ]] && ln -s "${_DIRS_TFTP#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_CONF##*/}"               ]] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}"               ]] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}"               ]] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}"               ]] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/${_DIRS_RMAK##*/}"               ]] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ]] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ]] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ]] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ]] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ]] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ]] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ]] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ]] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ]] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ]] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ]] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[[ ! -h "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" ]] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"
	# --- create autoexec.ipxe ------------------------------------------------
	[[ ! -e "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"  ]] && touch "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"
	[[ ! -e "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg" ]] && touch "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
