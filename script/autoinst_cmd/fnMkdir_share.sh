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
#   g-var : _DIRS_XNBD : read
#   g-var : _DIRS_XNFS : read
#   g-var : _DIRS_XSMB : read
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
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/almalinux
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/centos
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/debian
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/emmabuntus
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/fedora
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/knoppix
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/memtest86plus
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/miraclelinux
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/opensuse
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/rockylinux
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/ubcd
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/linux/ubuntu
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/aomei
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/ati
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/free-dos
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/office-365
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/windows-7
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/windows-8.1
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/windows-10
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/windows-11
#	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/windows-adk
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/isos/windows/winpe
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/image/rmak
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/pub/resource/source/git
	[ -n "${_DIRS_SAMB:-}" ] && mkdir -p "${_DIRS_SAMB:?}"/usr
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/fonts
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/locale
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-pc
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/i386-efi
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/boot/grub/x86_64-efi
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/exports
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/ipxe/menu
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/menu-bios/pxelinux.cfg
	[ -n "${_DIRS_TFTP:-}" ] && mkdir -p "${_DIRS_TFTP:?}"/menu-efi64/pxelinux.cfg
	[ -n "${_DIRS_USER:-}" ] && mkdir -p "${_DIRS_USER:?}"/private
	[ -n "${_DIRS_SHAR:-}" ] && mkdir -p "${_DIRS_SHAR:?}"
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_data
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_keyring
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.build.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.clean.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.conf.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.extra
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.finalize.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postinst.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.postoutput.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.prepare.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.repart
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/mkosi.sync.d
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_mkosi/script
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_repository/opensuse
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/_template
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/agama
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/autoyast
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/kickstart
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_desktop
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/nocloud/ubuntu_server
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/preseed
#	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/script
	[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_CONF:?}"/windows
	[ -n "${_DIRS_DATA:-}" ] && mkdir -p "${_DIRS_DATA:?}"
	[ -n "${_DIRS_KEYS:-}" ] && mkdir -p "${_DIRS_KEYS:?}"
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/_template
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.build.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.clean.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.conf.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.extra
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.finalize.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.postinst.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.postoutput.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.prepare.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.repart
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/mkosi.sync.d
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}"/repository
	[ -n "${_DIRS_MKOS:-}" ] && mkdir -p "${_DIRS_MKOS:?}/${_DIRS_SHEL##*/}"
	[ -n "${_DIRS_TMPL:-}" ] && mkdir -p "${_DIRS_TMPL:?}"
	[ -n "${_DIRS_SHEL:-}" ] && mkdir -p "${_DIRS_SHEL:?}"
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
	[ -n "${_DIRS_XNBD:-}" ] && mkdir -p "${_DIRS_XNBD:?}"
	[ -n "${_DIRS_XNFS:-}" ] && mkdir -p "${_DIRS_XNFS:?}"
	[ -n "${_DIRS_XSMB:-}" ] && mkdir -p "${_DIRS_XSMB:?}"
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/bin
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/src/git
	[ -n "${_DIRS_PVAT:-}" ] && mkdir -p "${_DIRS_PVAT:?}"/wrk

	# --- exports -------------------------------------------------------------
	if [ -n "${_DIRS_XNFS:-}" ]; then
		[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_XNFS}/${_DIRS_CONF##*/}"
		[ -n "${_DIRS_IMGS:-}" ] && mkdir -p "${_DIRS_XNFS}/${_DIRS_IMGS##*/}"
	fi
	if [ -n "${_DIRS_XSMB:-}" ]; then
		[ -n "${_DIRS_CONF:-}" ] && mkdir -p "${_DIRS_XSMB}/${_DIRS_CONF##*/}"
		[ -n "${_DIRS_IMGS:-}" ] && mkdir -p "${_DIRS_XSMB}/${_DIRS_IMGS##*/}"
		[ -n "${_DIRS_ISOS:-}" ] && mkdir -p "${_DIRS_XSMB}/${_DIRS_ISOS##*/}"
		[ -n "${_DIRS_LOAD:-}" ] && mkdir -p "${_DIRS_XSMB}/${_DIRS_LOAD##*/}"
		[ -n "${_DIRS_RMAK:-}" ] && mkdir -p "${_DIRS_XSMB}/${_DIRS_RMAK##*/}"
	fi

	# --- fstab ---------------------------------------------------------------
	__PATH="${_DIRS_TGET:-}/etc/fstab"
	fnFile_backup "${__PATH}"			# backup original file
	mkdir -p "${__PATH%/*}"
	cp --preserve=timestamps "${_DIRS_ORIG}/${__PATH#*"${_DIRS_TGET:-}/"}" "${__PATH}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}"
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "# <file system>" "<mount point>"                     "<type>" "<options>" "<dump>" "<pass>")
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_SHEL:?}" "${_DIRS_MKOS:?}/${_DIRS_SHEL##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_CONF:?}" "${_DIRS_XNFS:?}/${_DIRS_CONF##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_IMGS:?}" "${_DIRS_XNFS:?}/${_DIRS_IMGS##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_CONF:?}" "${_DIRS_XSMB:?}/${_DIRS_CONF##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_IMGS:?}" "${_DIRS_XSMB:?}/${_DIRS_IMGS##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_ISOS:?}" "${_DIRS_XSMB:?}/${_DIRS_ISOS##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_LOAD:?}" "${_DIRS_XSMB:?}/${_DIRS_LOAD##*/}" "none"   "bind,ro"   "0"      "0"     )
		$(printf "%-27s %-35s %-7s %-27s %-7s %s" "${_DIRS_RMAK:?}" "${_DIRS_XSMB:?}/${_DIRS_RMAK##*/}" "none"   "bind,ro"   "0"      "0"     )
_EOT_
	# --- check mount ---------------------------------------------------------
	if [ -z "${_TGET_CHRT:-}" ]; then
		systemctl --quiet daemon-reload
		for __MNTP in \
			"${_DIRS_MKOS:?}/${_DIRS_SHEL##*/}" \
			"${_DIRS_XNFS:?}/${_DIRS_CONF##*/}" \
			"${_DIRS_XNFS:?}/${_DIRS_IMGS##*/}" \
			"${_DIRS_XSMB:?}/${_DIRS_CONF##*/}" \
			"${_DIRS_XSMB:?}/${_DIRS_IMGS##*/}" \
			"${_DIRS_XSMB:?}/${_DIRS_ISOS##*/}" \
			"${_DIRS_XSMB:?}/${_DIRS_LOAD##*/}" \
			"${_DIRS_XSMB:?}/${_DIRS_RMAK##*/}" 
		do
			if mount "${__MNTP:?}"; then
				fnMsgout "${_PROG_NAME:-}" "success" "mounted: ${__MNTP}"
			else
				fnMsgout "${_PROG_NAME:-}" "failed" "not mounted: ${__MNTP}"
			fi
		done
	fi
	fnDbgdump "${__PATH}"				# debugout
	fnFile_backup "${__PATH}" "init"	# backup initial file

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
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_CONF##*/}"               ] && ln -s "${_DIRS_CONF#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/exports/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_IMGS##*/}"               ] && ln -s "${_DIRS_IMGS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/exports/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_ISOS##*/}"               ] && ln -s "${_DIRS_ISOS#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/exports/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_LOAD##*/}"               ] && ln -s "${_DIRS_LOAD#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/exports/"
	[ ! -h "${_DIRS_TFTP:?}/${_DIRS_RMAK##*/}"               ] && ln -s "${_DIRS_RMAK#"${_DIRS_TGET:-}"}" "${_DIRS_TFTP:?}/exports/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_CONF##*/}"     ] && ln -s "../exports/${_DIRS_CONF##*/}"    "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_IMGS##*/}"     ] && ln -s "../exports/${_DIRS_IMGS##*/}"    "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_ISOS##*/}"     ] && ln -s "../exports/${_DIRS_ISOS##*/}"    "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_LOAD##*/}"     ] && ln -s "../exports/${_DIRS_LOAD##*/}"    "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/${_DIRS_RMAK##*/}"     ] && ln -s "../exports/${_DIRS_RMAK##*/}"    "${_DIRS_TFTP:?}/menu-bios/"
	[ ! -h "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"  ] && ln -s "../syslinux.cfg"                 "${_DIRS_TFTP:?}/menu-bios/pxelinux.cfg/default"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_CONF##*/}"    ] && ln -s "../exports/${_DIRS_CONF##*/}"    "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_IMGS##*/}"    ] && ln -s "../exports/${_DIRS_IMGS##*/}"    "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_ISOS##*/}"    ] && ln -s "../exports/${_DIRS_ISOS##*/}"    "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_LOAD##*/}"    ] && ln -s "../exports/${_DIRS_LOAD##*/}"    "${_DIRS_TFTP:?}/menu-efi64/"
	[ ! -h "${_DIRS_TFTP:?}/menu-efi64/${_DIRS_RMAK##*/}"    ] && ln -s "../exports/${_DIRS_RMAK##*/}"    "${_DIRS_TFTP:?}/menu-efi64/"
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

		# --- Define colour pair ------------------------------------------------------
		# Reset the default colour pair
		cpair 0 ||
		# Redefine the editable text pair as black on white
		cpair --foreground 7 --background 0 4 ||

		# --- Check x86 CPU feature ---------------------------------------------------
		# Check if CPU supports 64-bit operation ("long mode")
		cpuid --ext 29 && set arch x86_64 || set arch i386

		# --- Automatically configure interfaces --------------------------------------
		# Automatically configure the first available interface using DHCP
		ifconf --configurator dhcp ||
		# Automatically configure the first available interface using IPv6
		ifconf --configurator ipv6 ||

		# --- Set the IP address of the PXE boot server -------------------------------
		isset \${66} && set srvraddr \${66} || set srvraddr ${_NICS_IPV4:?}

		# --- Set the parameters. -----------------------------------------------------
		set srvrhttp http://\${srvraddr}
		set ipxebase \${srvrhttp}/tftp/ipxe/
		set optn-timeout 1000
		set menu-timeout 0
		set esc:hex 1b

		# --- Preventing multiple instances -------------------------------------------
		isset \${menu-default} || set menu-default exit

		# --- chain -------------------------------------------------------------------
		chain \${ipxebase}/menu/menu.ipxe
_EOT_
	fnFile_backup "${_DIRS_TFTP:-}/ipxe/autoexec.ipxe" "init"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_TFTP:?}/ipxe/menu/menu.ipxe"
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		:menu
		menu Select the OS type you want to boot
		item --gap --                                   [ System command ]
		item -- shell                                   - iPXE shell
		item -- shutdown                                - System shutdown
		item -- restart                                 - System reboot
		choose --timeout \${menu-timeout} --default \${menu-default} selected && goto \${selected}
		goto menu

		# --- Interactive form block --------------------------------------------------
		:shell
		echo "Booting iPXE shell ..."
		shell
		goto menu

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	fnFile_backup "${_DIRS_TFTP:-}/ipxe/menu/menu.ipxe" "init"

	# --- debug output --------------------------------------------------------
	if [ -n "${_DBGS_FLAG:-}" ]; then
		command -v tree > /dev/null 2>&1 && tree --charset C -n --filesfirst "${_DIRS_TOPS}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]" 
	unset __FUNC_NAME
}
