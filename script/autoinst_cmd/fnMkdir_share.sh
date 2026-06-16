# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: creating a shared directory
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DIRS_TOPS : read
#   g-var : _DIRS_EXPO : read
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
#   g-var : _DIRS_CACH : read
#   g-var : _DIRS_CTNR : read
#   g-var : _DIRS_CHRT : read
#   g-var : _DIRS_EXPO : read
#   g-var : _DIRS_NBDS : read
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
	[ -n "${_DIRS_TOPS:-}" ] && mkdir -p "${_DIRS_TOPS:?}"
	[ -n "${_DIRS_HGFS:-}" ] && mkdir -p "${_DIRS_HGFS:?}"
	[ -n "${_DIRS_HTML:-}" ] && mkdir -p "${_DIRS_HTML:?}"
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/adm/commands
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/adm/profiles
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/_license
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/contents/disc
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/movies
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/others
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/photos
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/contents/dlna/sounds
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/hardware
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/software
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/git
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/usr
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/fonts
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/locale
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-pc
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-efi
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/x86_64-efi
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/ipxe
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/menu-bios/pxelinux.cfg
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/menu-efi64/pxelinux.cfg
	[ -n "${_DIRS_USER:-}" ] && mkdir -p "${_DIRS_USER:?}"/private
	[ -n "${_DIRS_SHAR:-}" ] && mkdir -p "${_DIRS_SHAR:?}"
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_data
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_keyring
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.build.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.clean.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.conf.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.extra
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.finalize.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postinst.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postoutput.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.prepare.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.repart
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.sync.d
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_repository/opensuse
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_template
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/agama
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/autoyast
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/kickstart
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_desktop
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_server
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/preseed
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/script
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/windows
	[ -n "${_DIRS_IMGS:-}" ] && mkdir -p "${_DIRS_IMGS:?}"
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/debian
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/ubuntu
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/fedora
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/centos
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/almalinux
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/rockylinux
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/miraclelinux
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/opensuse
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/linux/memtest86plus
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows/windows-10
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows/windows-11
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows/winpe
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows/ati
	[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_ISOS:?}"/windows/aomei
	[ -n "${_DIRS_LOAD:-}" ] && mkdir -p "${_DIRS_LOAD:?}"
	[ -n "${_DIRS_RMAK:-}" ] && mkdir -p "${_DIRS_RMAK:?}"
	[ -n "${_DIRS_CACH:-}" ] && mkdir -p "${_DIRS_CACH:?}"
	[ -n "${_DIRS_CTNR:-}" ] && mkdir -p "${_DIRS_CTNR:?}"
	[ -n "${_DIRS_CHRT:-}" ] && mkdir -p "${_DIRS_CHRT:?}"
	[ -n "${_DIRS_EXPO:-}" ] && mkdir -p "${_DIRS_EXPO:?}"
	[ -n "${_DIRS_NBDS:-}" ] && mkdir -p "${_DIRS_NBDS:?}"
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/bin
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/src/git
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/wrk

	# --- exports -------------------------------------------------------------
	if [ -n "${_DIRS_EXPO:-}" ]; then
		mkdir -p "${_DIRS_EXPO}"/nbd
		mkdir -p "${_DIRS_EXPO}"/nfs
		[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_EXPO}/nfs/${_DIRS_CONF##*/}"
		[ -n "${_DIRS_IMGS:-}" ] && mkdir -p "${_DIRS_EXPO}/nfs/${_DIRS_IMGS##*/}"
	fi

	# --- change file mode ----------------------------------------------------
	if [ -n "${_DIRS_SAMB:-}" ] && [ -e "${_DIRS_SAMB:?}/." ]; then
		chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB}/"
		chmod -R 2770 "${_DIRS_SAMB}/"
	fi
	if [ -n "${_DIRS_CONF:-}" ] && [ -e "${_DIRS_CONF:?}/." ]; then
		chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_CONF}/"
		chmod -R 2775 "${_DIRS_CONF}/"
	fi
	if [ -n "${_DIRS_ISOS:-}" ] && [ -e "${_DIRS_ISOS:?}/." ]; then
		chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_ISOS}/"
		chmod -R 2775 "${_DIRS_ISOS}/"
	fi
	if [ -n "${_DIRS_RMAK:-}" ] && [ -e "${_DIRS_RMAK:?}/." ]; then
		chown -R "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_RMAK}/"
		chmod -R 2775 "${_DIRS_RMAK}/"
	fi

	# --- create symbolic link ------------------------------------------------
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
#	[ ! -e "${_DIRS_TFTP:?}/ipxe/autoexec.ipxe" ] && ln -sr "${_DIRS_TFTP:?}/autoexec.ipxe" "${_DIRS_TFTP:?}/ipxe/autoexec.ipxe"
#	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_TFTP:?}/autoexec.ipxe"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_TFTP:?}/ipxe/autoexec.ipxe"
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
	fnFile_backup "${_DIRS_TFTP:-}/ipxe/autoexec.ipxe" "init"

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_TOPS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
