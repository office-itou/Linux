# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: creating a shared directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
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
#   g-var : _DIRS_SAMB : read
# shellcheck disable=SC2148,SC2317,SC2329
fnMkdir_share(){
	__FUNC_NAME="fnMkdir_share"
	fnMsgout "start" "[${__FUNC_NAME}]"

	# --- create directory ----------------------------------------------------
	mkdir -p "${_DIRS_TOPS:?}"
	mkdir -p "${_DIRS_HGFS:?}"
	mkdir -p "${_DIRS_HTML:?}"
	mkdir -p "${_DIRS_SAMB:?}"/adm/commands
	mkdir -p "${_DIRS_SAMB:?}"/adm/profiles
	mkdir -p "${_DIRS_SAMB:?}"/pub/_license
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/disc
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/movies
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/others
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/photos
	mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/sounds
	mkdir -p "${_DIRS_SAMB:?}"/pub/hardware
	mkdir -p "${_DIRS_SAMB:?}"/pub/software
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git
	mkdir -p "${_DIRS_SAMB:?}"/usr
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/fonts
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/locale
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-pc
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-efi
	mkdir -p "${_DIRS_TFTP:?}"/boot/grub/x86_64-efi
	mkdir -p "${_DIRS_TFTP:?}"/ipxe
	mkdir -p "${_DIRS_TFTP:?}"/menu-bios/pxelinux.cfg
	mkdir -p "${_DIRS_TFTP:?}"/menu-efi64/pxelinux.cfg
	mkdir -p "${_DIRS_USER:?}"/private
	mkdir -p "${_DIRS_SHAR:?}"
	mkdir -p "${_DIRS_CONF:?}"/_repository
	mkdir -p "${_DIRS_CONF:?}"/agama
	mkdir -p "${_DIRS_CONF:?}"/autoyast
	mkdir -p "${_DIRS_CONF:?}"/kickstart
	mkdir -p "${_DIRS_CONF:?}"/nocloud
	mkdir -p "${_DIRS_CONF:?}"/preseed
	mkdir -p "${_DIRS_CONF:?}"/windows
	mkdir -p "${_DIRS_DATA:?}"
	mkdir -p "${_DIRS_KEYS:?}"
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.build.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.clean.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.conf.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.extra
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.finalize.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.postinst.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.postoutput.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.prepare.d
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.repart
	mkdir -p "${_DIRS_MKOS:?}"/mkosi.sync.d
	mkdir -p "${_DIRS_TMPL:?}"
	mkdir -p "${_DIRS_SHEL:?}"
	mkdir -p "${_DIRS_IMGS:?}"
	mkdir -p "${_DIRS_ISOS:?}"
	mkdir -p "${_DIRS_LOAD:?}"
	mkdir -p "${_DIRS_RMAK:?}"
	mkdir -p "${_DIRS_CACH:?}"
	mkdir -p "${_DIRS_CTNR:?}"
	mkdir -p "${_DIRS_CHRT:?}"

	# --- change file mode ----------------------------------------------------
	chown -R "${_SAMB_USER}":"${_SAMB_GRUP}" "${_DIRS_SAMB}/"*
	chmod -R  770 "${_DIRS_SAMB}/"*
	chmod    1777 "${_DIRS_SAMB}/adm/profiles"

	# --- create symbolic link ------------------------------------------------
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_TFTP##*/}"               ] && ln -s "${_DIRS_TFTP#"${_DIRS_TGET:-}"}" "${_DIRS_HTML:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -L "${_DIRS_HTML:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ] && ln -s "../${_DIRS_CONF##*/}"             "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ] && ln -s "../${_DIRS_IMGS##*/}"             "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ] && ln -s "../${_DIRS_ISOS##*/}"             "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ] && ln -s "../${_DIRS_LOAD##*/}"             "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ] && ln -s "../${_DIRS_RMAK##*/}"             "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ] && ln -s "../menu-bios/syslinux.cfg"        "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ] && ln -s "../${_DIRS_CONF##*/}"             "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ] && ln -s "../${_DIRS_IMGS##*/}"             "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ] && ln -s "../${_DIRS_ISOS##*/}"             "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ] && ln -s "../${_DIRS_LOAD##*/}"             "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -L "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ] && ln -s "../${_DIRS_RMAK##*/}"             "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -L "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default" ] && ln -s "../menu-efi64/syslinux.cfg"       "${_DIRS_TFTP:?}/menu-efi64/pxelinux.cfg/default"

	# --- create autoexec.ipxe ------------------------------------------------
	touch "${_DIRS_TFTP:?}/menu-bios/syslinux.cfg"
	touch "${_DIRS_TFTP:?}/menu-efi64/syslinux.cfg"
	fnFile_backup "${_DIRS_TFTP:-}/menu-bios/syslinux.cfg"  "init"
	fnFile_backup "${_DIRS_TFTP:-}/menu-efi64/syslinux.cfg" "init"

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
	fnFile_backup "${_DIRS_TFTP:-}/autoexec.ipxe" "init"

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		tree --charset C -n --filesfirst "${_DIRS_TOPS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "complete" "[${__FUNC_NAME}]" 
}
