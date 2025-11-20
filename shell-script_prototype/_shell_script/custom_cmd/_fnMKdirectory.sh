# -----------------------------------------------------------------------------
# descript: create directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _DBGS_FAIL : write
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
#   g-var : _DIRS_TMPL : read
#   g-var : _DIRS_PVAT : read
#   g-var : _DIRS_SHEL : read
#   g-var : _DIRS_IMGS : read
#   g-var : _DIRS_ISOS : read
#   g-var : _DIRS_LOAD : read
#   g-var : _DIRS_RMAK : read
#   g-var : _DIRS_CACH : read
#   g-var : _DIRS_CTNR : read
#   g-var : _DIRS_CHRT : read
#   g-var : _LIST_MDIA : read
# shellcheck disable=SC2148
function fnMKdirectory() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "start" "[${__FUNC_NAME}]"

	declare -a    __DIRS=()				# directory list
	declare -a    __LINK=()				# symbolic link list
	declare       __FLAG=""				# flag (add/relative/...)
	declare       __TGET=""				# taget path
	declare       __SLNK=""				# symlink path
	declare       __RNAM=""				# rename path
	declare -a    __LIST=()				# work variable
	declare -i    I=0

	# === create directory and symbolic link ==================================
	# tree --charset=C --filesfirst -a /srv/
	# --- directory list ------------------------------------------------------
	__DIRS=( \
		"${_DIRS_TOPS:?}" \
		"${_DIRS_HGFS:?}" \
		"${_DIRS_HTML:?}" \
		"${_DIRS_SAMB:?}"/{adm/{commands,profiles},pub/{contents/{disc,dlna/{movies,others,photos,sounds}},resource/{image/{linux,windows},source/git},software,hardware,_license},usr} \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg} \
		"${_DIRS_USER:?}" \
		"${_DIRS_PVAT:?}" \
		"${_DIRS_SHAR:?}" \
		"${_DIRS_CONF:?}"/{_mkosi/{mkosi.build.d,mkosi.clean.d,mkosi.conf.d,mkosi.extra,mkosi.finalize.d,mkosi.postinst.d,mkosi.postoutput.d,mkosi.prepare.d,mkosi.repart,mkosi.sync.d},_repository,agama,autoyast,kickstart,nocloud,preseed,windows} \
		"${_DIRS_DATA:?}" \
		"${_DIRS_KEYS:?}" \
		"${_DIRS_TMPL:?}" \
		"${_DIRS_SHEL:?}" \
		"${_DIRS_IMGS:?}" \
		"${_DIRS_ISOS:?}" \
		"${_DIRS_LOAD:?}" \
		"${_DIRS_RMAK:?}" \
		"${_DIRS_CACH:?}" \
		"${_DIRS_CTNR:?}" \
		"${_DIRS_CHRT:?}" \
	)
	readonly __DIRS
	# --- symbolic link list --------------------------------------------------
	# 0: a:add, r:relative
	# 1: target
	# 2: symlink
	__LINK=( \
		"a  ${_DIRS_CONF:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_IMGS:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_ISOS:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_LOAD:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_RMAK:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_TFTP:?}             ${_DIRS_HTML:?}/" \
		"a  ${_DIRS_CONF:?}             ${_DIRS_TFTP:?}/" \
		"a  ${_DIRS_IMGS:?}             ${_DIRS_TFTP:?}/" \
		"a  ${_DIRS_ISOS:?}             ${_DIRS_TFTP:?}/" \
		"a  ${_DIRS_LOAD:?}             ${_DIRS_TFTP:?}/" \
		"a  ${_DIRS_RMAK:?}             ${_DIRS_TFTP:?}/" \
		"a  ../${_DIRS_CONF##*/}        ${_DIRS_TFTP:?}/menu-bios/" \
		"a  ../${_DIRS_IMGS##*/}        ${_DIRS_TFTP:?}/menu-bios/" \
		"a  ../${_DIRS_ISOS##*/}        ${_DIRS_TFTP:?}/menu-bios/" \
		"a  ../${_DIRS_LOAD##*/}        ${_DIRS_TFTP:?}/menu-bios/" \
		"a  ../${_DIRS_RMAK##*/}        ${_DIRS_TFTP:?}/menu-bios/" \
		"a  ../menu-bios/syslinux.cfg   ${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default" \
		"a  ../${_DIRS_CONF##*/}        ${_DIRS_TFTP:?}/menu-efi64/" \
		"a  ../${_DIRS_IMGS##*/}        ${_DIRS_TFTP:?}/menu-efi64/" \
		"a  ../${_DIRS_ISOS##*/}        ${_DIRS_TFTP:?}/menu-efi64/" \
		"a  ../${_DIRS_LOAD##*/}        ${_DIRS_TFTP:?}/menu-efi64/" \
		"a  ../${_DIRS_RMAK##*/}        ${_DIRS_TFTP:?}/menu-efi64/" \
		"a  ../menu-efi64/syslinux.cfg  ${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" \
	)
	readonly __LINK
	# --- create directory ----------------------------------------------------
	mkdir -p "${__DIRS[@]:?}"
	chown -R "${_SAMB_USER}":"${_SAMB_GRUP}" "${_DIRS_SAMB}/"*
	chmod -R  770 "${_DIRS_SAMB}/"*
	chmod    1777 "${_DIRS_SAMB}/adm/profiles"
	# --- create symbolic link ------------------------------------------------
	for I in "${!__LINK[@]}"
	do
		read -r -a __LIST < <(echo "${__LINK[I]}")
		__FLAG="${__LIST[0]:-}"			# a:add, r:relative
		__TGET="${__LIST[1]:-}"			# target
		__SLNK="${__LIST[2]:-}"			# symlink
		case "${__FLAG:-}" in
			a) ;;
			r) ;;
			*) continue;;
		esac
		# --- check target file path ------------------------------------------
		if [[ -z "${__SLNK##*/}" ]]; then
			__SLNK="${__SLNK%/}/${__TGET##*/}"
		fi
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__SLNK}" ]]; then
#			fnMsgout "exist" "  symlink: [${__SLNK}]"
			continue
		fi
		# --- check directory -------------------------------------------------
		if [[ -d "${__SLNK}/." ]]; then
			__RNAM="${__SLNK}.$(TZ=UTC find "${__SLNK}" -printf '%TY%Tm%Td%TH%TM%.2TS')"
			fnMsgout "exist"  "directory: [${__SLNK}]"
			fnMsgout "backup" "directory: [${__RNAM}]"
			mv "${__SLNK}" "${__RNAM}"
		fi
		# --- check target directory ------------------------------------------
		if [[ -z "${__TGET##*/}" ]] && [[ ! -e "${__TGET%%/}"/. ]]; then
			fnMsgout "create" "directory: [${__TGET%%/}]"
			mkdir -p "${__TGET%%/}"
		fi
		# --- create destination directory ------------------------------------
		if [[ ! -e "${__SLNK%/*}/." ]]; then
			fnMsgout "create" "directory: [${__SLNK%/*}]"
			mkdir -p "${__SLNK%/*}"
		fi
		# --- create symbolic link --------------------------------------------
		fnMsgout "create" "  symlink: ${_FLAG_WIDE:+"[${__TGET}] -> "}[${__SLNK}]"
		case "${__FLAG}" in
			r) ln -sr "${__TGET}" "${__SLNK}";;
			*) ln -s  "${__TGET}" "${__SLNK}";;
		esac
	done

	# === create symbolic link (isos) =========================================
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
		__FLAG="${__LIST[1]:-}"
		__SLNK="${__LIST[13]:-}"
		__TGET="${__LIST[25]:-}/${__SLNK##*/}"
		case "${__FLAG}" in
			o) ;;
			*) continue;;
		esac
		case "${__SLNK}" in
			-) continue;;
			*) ;;
		esac
		case "${__TGET%%/*}" in
			-) continue;;
			*) ;;
		esac
		# --- check symbolic link ---------------------------------------------
		if [[ -h "${__SLNK}" ]]; then
#			fnMsgout "exist" "  symlink: [${__SLNK}]"
			continue
		fi
		# --- create symbolic link --------------------------------------------
		fnMsgout "create" "  symlink: ${_FLAG_WIDE:+"[${__TGET}] -> "}[${__SLNK}]"
		ln -s  "${__TGET}" "${__SLNK}"
	done

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
}
