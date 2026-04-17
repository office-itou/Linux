# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image partition1
#   input :     $1     : device name
#   input :     $2     : partition
#   input :     $3     : output directory
#   input :     $4     : uuid
#   input :     $5     : distribution
#   input :     $6     : menu entry
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_vmimg_p1() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PART="${2:?}"	# partition
	declare -r    __TGET_OUTD="${3:?}"	# output directory
	declare -r    __TGET_UUID="${4:?}"	# uuid
	declare -r    __TGET_DIST="${5:?}"	# distribution
	declare -r    __TGET_ENTR="${6:?}"	# menu entry
	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/strg"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt1"			# mount point
#	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
#	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
#	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
	declare -r    __SPLS="${__TGET_OUTD:?}/${_MENU_SPLS:?}"	# splash.png
	declare -r    __MBRF="${__OUTD:?}/${_FILE_MBRF:?}"		# mbr image
	declare -r    __UEFI="${__OUTD:?}/${_FILE_UEFI:?}"		# uefi image
	declare -r    __VLNZ="${_PATH_VLNZ:?}"					# kernel
	declare -r    __IRAM="${_PATH_IRAM:?}"					# initramfs
	declare -r    __TITL="Live system"						# title
	declare       __COMD=""									# command
	declare       __PSEC=""									# physical sector size
	declare       __STRT=""									# partition start offset (in 512-byte sectors)
	declare       __SIZE=""									# size of the device (bytes)
	declare       __CONT=""									# partition sector size (in 512-byte sectors)
	declare       __PATH=""									# work
	declare       __WORK=""									# work
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	mkdir -p "${__MNTP:?}"
	# --- install grub module -------------------------------------------------
	  if command -v grub-install  > /dev/null 2>&1; then __COMD="grub-install"
	elif command -v grub2-install > /dev/null 2>&1; then __COMD="grub2-install"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	"${__COMD:?}" \
		--target=x86_64-efi \
		--efi-directory="${__MNTP}" \
		--boot-directory="${__MNTP}/boot" \
		--bootloader-id="${__TGET_DIST,,}" \
		--removable
	"${__COMD:?}" \
		--target=i386-pc \
		--boot-directory="${__MNTP}/boot" \
		"${__TGET_DEVS}"
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# --- create uefi/bios image ----------------------------------------------
	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__TGET_DEVS:?}${__TGET_PART:?}")"
	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK:?}")
	__CONT="$(("${__SIZE:?}" / "${__PSEC:?}"))"
	dd if="${__TGET_DEVS:?}" of="${__UEFI:?}" bs="${__PSEC:?}" skip="${__STRT:?}" count="${__CONT:?}"
	dd if="${__TGET_DEVS:?}" of="${__MBRF:?}" bs=1 count=440
	# --- create grub.cfg -----------------------------------------------------
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	fnGrub_conf  "${__GCFG:?}" "${__INPD}/${_FILE_MENU:?}" "${__INPD}/${_FILE_THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "${__INPD}/${_MENU_SPLS:?}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_ENTR}" {
		  set gfxpayload="keep"
		  set background_color="black"
		  set uuid="${__TGET_UUID:?}"
		  search --no-floppy --fs-uuid --set=root \${uuid}
		  echo root=\${root}
		  set devs=/dev/sda2
		  set ttys=console=ttyS0
		  set options="\${ttys} root=\${devs}${_SECU_OPTN:+" ${_SECU_OPTN}"}"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__VLNZ:?} \${options} ---
		  echo 'Loading initramfs ...'
		  initrd ${__IRAM:?}
		}
_EOT_
#	[[ -e "${__EGRU:?}" ]] && cp --preserve=timestamps "${__EGRU:?}" "${__MNTP:?}/EFI/BOOT/${_FILE_GCFG##*/}"
	[[ -e "${__GCFG:?}" ]] && cp --preserve=timestamps "${__GCFG:?}" "${__MNTP:?}/${__INPD:?}"
#	[[ -e "${__ICFG:?}" ]] && cp --preserve=timestamps "${__ICFG:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__THME:?}" ]] && cp --preserve=timestamps "${__THME:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__MENU:?}" ]] && cp --preserve=timestamps "${__MENU:?}" "${__MNTP:?}/${__INPD:?}"
	[[ -e "${__SPLS:?}" ]] && cp --preserve=timestamps "${__SPLS:?}" "${__MNTP:?}/${__INPD:?}"
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	# -------------------------------------------------------------------------
	unset __WORK __PATH __COMD
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
