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
		"${_DIRS_SAMB:?}"/adm/{commands,profiles} \
		"${_DIRS_SAMB:?}"/pub/{_license,contents/{disc,dlna/{movies,others,photos,sounds}},hardware,software} \
		"${_DIRS_SAMB:?}"/pub/resource/image/creations/rmak \
		"${_DIRS_SAMB:?}"/pub/resource/image/linux/{debian,ubuntu,fedora,centos,almalinux,rockylinux,miraclelinux,opensuse,memtest86plus} \
		"${_DIRS_SAMB:?}"/pub/resource/image/windows/{windows-{10,11},winpe,ati,aomei} \
		"${_DIRS_SAMB:?}"/pub/resource/source/git \
		"${_DIRS_SAMB:?}"/usr \
		"${_DIRS_TFTP:?}"/{boot/grub/{fonts,locale,i386-pc,i386-efi,x86_64-efi},ipxe,menu-{bios,efi64}/pxelinux.cfg} \
		"${_DIRS_USER:?}"/private \
		"${_DIRS_SHAR:?}" \
		"${_DIRS_CONF:?}"/{_data,_keyring,_repository/opensuse,_template} \
		"${_DIRS_CONF:?}"/_mkosi/mkosi.{build.d,clean.d,conf.d,extra,finalize.d,postinst.d,postoutput.d,prepare.d,repart,sync.d} \
		"${_DIRS_CONF:?}"/{agama,autoyast,kickstart,nocloud/{ubuntu_desktop,ubuntu_server},preseed,script,windows} \
		"${_DIRS_IMGS:?}" \
		"${_DIRS_ISOS:?}" \
		"${_DIRS_LOAD:?}" \
		"${_DIRS_RMAK:?}" \
		"${_DIRS_CACH:?}" \
		"${_DIRS_CTNR:?}" \
		"${_DIRS_CHRT:?}"
	# --- change file mode ----------------------------------------------------
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB}/"*
	chmod -R 2770 "${_DIRS_SAMB}/"*
#	chmod    1777 "${_DIRS_SAMB}/adm/profiles"
	# --- create symbolic link ------------------------------------------------
#	[ ! -e "${_DIRS_CONF:?}.orig"                            ] && mv "${_DIRS_CONF:?}" "${_DIRS_CONF:?}.orig"
	[ ! -e "${_DIRS_RMAK:?}.orig"                            ] && mv "${_DIRS_RMAK:?}" "${_DIRS_RMAK:?}.orig"
#	[ ! -h "${_DIRS_CONF:?}"                                 ] && ln -s "${_DIRS_SAMB#"${_DIRS_TGET:-}"}/pub/resource/source/git/office-itou/linux/conf" "${_DIRS_CONF:?}"
	[ ! -h "${_DIRS_RMAK:?}"                                 ] && ln -s "${_DIRS_SAMB#"${_DIRS_TGET:-}"}/pub/resource/image/creations/rmak"              "${_DIRS_RMAK:?}"
	[ ! -h "${_DIRS_ISOS:?}/linux"                           ] && ln -s "${_DIRS_SAMB#"${_DIRS_TGET:-}"}/pub/resource/image/linux"                       "${_DIRS_ISOS:?}/"
	[ ! -h "${_DIRS_ISOS:?}/windows"                         ] && ln -s "${_DIRS_SAMB#"${_DIRS_TGET:-}"}/pub/resource/image/windows"                     "${_DIRS_ISOS:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_HTML:?}/${_DIRS_TFTP##*/}"               ] && ln -s "${_DIRS_TFTP#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_CONF##*/}"    ] && ln -s "../${_DIRS_CONF##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_IMGS##*/}"    ] && ln -s "../${_DIRS_IMGS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_ISOS##*/}"    ] && ln -s "../${_DIRS_ISOS##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_LOAD##*/}"    ] && ln -s "../${_DIRS_LOAD##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_RMAK##*/}"    ] && ln -s "../${_DIRS_RMAK##*/}"            "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" ] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"
	# --- create index.html ---------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_HTML}/index.html"
		"Hello, world!" from ${_NICS_HOST}
_EOT_
	# --- create autoexec.ipxe ------------------------------------------------
	touch "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"
	touch "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg"
	# --- create autoexec.ipxe ------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_DIRS_TFTP:?}/autoexec.ipxe"
		#!ipxe

		cpuid --ext 29 && set arch amd64 || set arch x86

		dhcp

		set optn-timeout 1000
		set menu-timeout 0
		isset \${menu-default} || set menu-default exit

		:start

		:menu
		menu Select the OS type you want to boot
		item --gap --                                   --------------------------------------------------------------------------
		item --gap --                                   [ System command ]
		item -- shell                                   - iPXE shell
		#item -- shutdown                               - System shutdown
		item -- restart                                 - System reboot
		item --gap --                                   --------------------------------------------------------------------------
		choose --timeout \${menu-timeout} --default \${menu-default} selected || goto menu
		goto \${selected}

		:shell
		echo "Booting iPXE shell ..."
		shell
		goto start

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:error
		prompt Press any key to continue
		exit

		:exit
		exit
_EOT_

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
