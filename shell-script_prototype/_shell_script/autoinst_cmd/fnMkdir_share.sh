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
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create system user id -----------------------------------------------
	if ! id "${_SAMB_USER}" > /dev/null 2>&1; then
		if ! grep -qE '^'"${_SAMB_GADM}"':' /etc/group; then groupadd --system "${_SAMB_GADM}"; fi
		if ! grep -qE '^'"${_SAMB_GRUP}"':' /etc/group; then groupadd --system "${_SAMB_GRUP}"; fi
		useradd --system --shell "${_SHEL_NLIN}" --groups "${_SAMB_GRUP}" "${_SAMB_USER}"
	fi
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
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/creations/rmak
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/debian
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/ubuntu
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/fedora
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/centos
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/almalinux
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/rockylinux
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/miraclelinux
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/opensuse
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/linux/memtest86plus
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows/windows-10
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows/windows-11
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows/winpe
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows/ati
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/windows/aomei
	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_data
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_keyring
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.build.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.clean.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.conf.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.extra
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.finalize.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.postinst.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.postoutput.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.prepare.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.repart
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_mkosi/mkosi.sync.d
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_repository/opensuse
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/_template
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/agama
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/autoyast
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/kickstart
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/nocloud/ubuntu_desktop
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/nocloud/ubuntu_server
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/preseed
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/script
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/linux/conf/windows
#	mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git/office-itou/windows
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
	mkdir -p "${_DIRS_CONF:?}"/_data
	mkdir -p "${_DIRS_CONF:?}"/_keyring
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.build.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.clean.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.conf.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.extra
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.finalize.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postinst.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postoutput.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.prepare.d
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.repart
	mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.sync.d
	mkdir -p "${_DIRS_CONF:?}"/_repository/opensuse
	mkdir -p "${_DIRS_CONF:?}"/_template
	mkdir -p "${_DIRS_CONF:?}"/agama
	mkdir -p "${_DIRS_CONF:?}"/autoyast
	mkdir -p "${_DIRS_CONF:?}"/kickstart
	mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_desktop
	mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_server
	mkdir -p "${_DIRS_CONF:?}"/preseed
	mkdir -p "${_DIRS_CONF:?}"/script
	mkdir -p "${_DIRS_CONF:?}"/windows
#	mkdir -p "${_DIRS_DATA:?}"
#	mkdir -p "${_DIRS_KEYS:?}"
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.build.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.clean.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.conf.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.extra
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.finalize.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.postinst.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.postoutput.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.prepare.d
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.repart
#	mkdir -p "${_DIRS_MKOS:?}"/mkosi.sync.d
#	mkdir -p "${_DIRS_TMPL:?}"
#	mkdir -p "${_DIRS_SHEL:?}"
	mkdir -p "${_DIRS_IMGS:?}"
	mkdir -p "${_DIRS_ISOS:?}"
	mkdir -p "${_DIRS_LOAD:?}"
	mkdir -p "${_DIRS_RMAK:?}"
	mkdir -p "${_DIRS_CACH:?}"
	mkdir -p "${_DIRS_CTNR:?}"
	mkdir -p "${_DIRS_CHRT:?}"

	# --- change file mode ----------------------------------------------------
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB}/"*
	chmod -R 2770 "${_DIRS_SAMB}/"*
#	chmod    1777 "${_DIRS_SAMB}/adm/profiles"
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_CONF}/"*
	chmod -R 2775 "${_DIRS_CONF}/"*
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_ISOS}/"*
	chmod -R 2775 "${_DIRS_ISOS}/"*
	chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_RMAK}/"*
	chmod -R 2775 "${_DIRS_RMAK}/"*

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
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_TOPS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
