	# shellcheck disable=SC2148
	# -------------------------------------------------------------------------
	declare       _CODE_NAME=""
	              _CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      _CODE_NAME

	if command -v apt-get > /dev/null 2>&1; then
		if ! ls /var/lib/apt/lists/*_"${_CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
			echo "please execute apt-get update:"
			if [[ -n "${SUDO_USER:-}" ]] || { [[ -z "${SUDO_USER:-}" ]] && [[ "${_USER_NAME:-}" != "root" ]]; }; then
				echo -n "sudo "
			fi
			echo "apt-get update" 1>&2
			exit 1
		fi
		# ---------------------------------------------------------------------
		declare       _ARHC_MAIN=""
		              _ARHC_MAIN="$(dpkg --print-architecture)"
		readonly      _ARHC_MAIN
		declare       _ARCH_OTHR=""
		              _ARCH_OTHR="$(dpkg --print-foreign-architectures)"
		readonly      _ARCH_OTHR
		# --- for custom iso --------------------------------------------------
		declare -r -a PAKG_LIST=(\
			"curl" \
			"wget" \
			"fdisk" \
			"file" \
			"initramfs-tools-core" \
			"isolinux" \
			"isomd5sum" \
			"procps" \
			"xorriso" \
			"xxd" \
			"cpio" \
			"gzip" \
			"zstd" \
			"xz-utils" \
			"lz4" \
			"bzip2" \
			"lzop" \
			"syslinux-common" \
			"pxelinux" \
			"syslinux-efi" \
			"grub-common" \
			"grub-pc-bin" \
			"grub-efi-amd64-bin" \
			"rsync" \
		)
		# ---------------------------------------------------------------------
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_ARCH_OTHR:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g' || true)"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			echo "please install these:"
			if [[ "${_USER_NAME:-}" != "root" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get install ${PAKG_FIND% *}" 1>&2
			exit 1
		fi
	fi
