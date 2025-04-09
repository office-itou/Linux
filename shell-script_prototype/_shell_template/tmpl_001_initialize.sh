	# -------------------------------------------------------------------------
	declare       _CODE_NAME=""
	              _CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      _CODE_NAME

	if command -v apt-get > /dev/null 2>&1; then
		if ! ls /var/lib/apt/lists/*_"${_CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
			echo "please execute apt-get update:"
			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get update" 1>&2
			exit 1
		fi
		# ---------------------------------------------------------------------
		declare       _MAIN_ARHC=""
		              _MAIN_ARHC="$(dpkg --print-architecture)"
		readonly      _MAIN_ARHC
		declare       _OTHR_ARCH=""
		              _OTHR_ARCH="$(dpkg --print-foreign-architectures)"
		readonly      _OTHR_ARCH
		declare -r -a PAKG_LIST=(\
		)
		# --- for custom iso --------------------------------------------------
#		declare -r -a PAKG_LIST=(\
#			"curl" \
#			"wget" \
#			"fdisk" \
#			"file" \
#			"initramfs-tools-core" \
#			"isolinux" \
#			"isomd5sum" \
#			"procps" \
#			"xorriso" \
#			"xxd" \
#			"cpio" \
#			"gzip" \
#			"zstd" \
#			"xz-utils" \
#			"lz4" \
#			"bzip2" \
#			"lzop" \
#		)
		# --- for pxeboot -----------------------------------------------------
#		declare -r -a PAKG_LIST=(\
#			"procps" \
#			"syslinux-common" \
#			"pxelinux" \
#			"syslinux-efi" \
#			"grub-common" \
#			"grub-pc-bin" \
#			"grub-efi-amd64-bin" \
#			"curl" \
#			"rsync" \
#		)
		# ---------------------------------------------------------------------
		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]:-bash}" 2> /dev/null | sed -ne '/[ \t]'"${_OTHR_ARCH:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')"
		readonly      PAKG_FIND
		if [[ -n "${PAKG_FIND% *}" ]]; then
			echo "please install these:"
			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
				echo -n "sudo "
			fi
			echo "apt-get install ${PAKG_FIND% *}" 1&2
			exit 1
		fi
	fi
