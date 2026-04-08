# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image partition1
#   input :     $1     : device name
#   input :     $2     : partition
#   input :     $3     : uuid
#   input :     $4     : distribution
#   input :     $5     : volume id
#   input :     $6     : output directory
#   input :     $7     : root image mount point
#   input :     $8     : kernel
#   input :     $9     : initramfs
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_vmimg_p1() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PART="${2:?}"	# partition
	declare -r    __TGET_UUID="${3:?}"	# uuid
	declare -r    __TGET_DIST="${4:?}"	# distribution
	declare -r    __TGET_VLID="${5:?}"	# volume id
	declare -r    __TGET_OUTD="${6:?}"	# output directory
	declare -r    __TGET_RTMP="${7:?}"	# root image mount point
	declare -r    __TGET_VLNZ="${8:?}"	# kernel
	declare -r    __TGET_IRAM="${9:?}"	# initramfs
	declare       __MNTP=""				# mount point
	declare       __COMD=""				# command
	declare       __PATH=""				# work
	declare       __MENU=""				# main menu
	declare       __THME=""				# theme file
	declare       __TITL=""				# menu title
	declare       __SECU=""				# security
	declare       __SPLS=""				# splash.png

	__MNTP="${__TGET_OUTD}/mnt1"
	mkdir -p "${__MNTP}"
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}"
	# --- install grub module -------------------------------------------------
	  if command -v grub-install  > /dev/null 2>&1; then __COMD="grub-install"
	elif command -v grub2-install > /dev/null 2>&1; then __COMD="grub2-install"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
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
	# --- splash.png ----------------------------------------------------------
	__SPLS="/boot/grub/${_MENU_SPLS:?}"
	__SRCS="${__OUTD}/${__SPLS##*/}"
	__DEST="${__MNTP}/${__SPLS#/}"
	mkdir -p "${__SRCS%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		1f8b0808462b8d69000373706c6173682e706e6700eb0cf073e7e592e262
		6060e0f5f47009626060566060608ae060028a888a88aa3330b0767bba38
		8654dc7a7b909117287868c177ff5c3ef3050ca360148c8251300ae8051a
		c299ff4c6660bcb6edd00b10d7d3d5cf659d53421300e6198186c4050000
_EOT_
	mkdir -p "${__DEST%/*}"
	cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	# --- create grub.cfg -----------------------------------------------------
	__PATH="${__OUTD}/${_FILE_GCFG:?}"
	__MENU="${__OUTD}/${_FILE_MENU:?}"
	__THME="${__OUTD}/${_FILE_THME:?}"
	__TITL="Live system"
	__SECU=""
	[[ -e "${__TGET_RTMP:?}"/usr/bin/aa-enabled  ]] && __SECU="security=apparmor apparmor=1"
	[[ -e "${__TGET_RTMP:?}"/usr/sbin/getenforce ]] && __SECU="security=selinux selinux=1 enforcing=0"
	fnGrub_conf "${__PATH:?}" "${__MENU:?}" "${__THME:?}" "${_MENU_TOUT:?}" "${_MENU_RESO:?}" "${_MENU_DPTH:?}"
	fnGrub_theme "${__THME:?}" "${__TITL:?}" "${__SPLS:-}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__MENU:?}"
		menuentry "${__TGET_VLID}" {
		  set gfxpayload="keep"
		  set background_color="black"
		  set uuid="${__TGET_UUID:?}"
		  search --no-floppy --fs-uuid --set=root \${uuid}
		  echo root=\${root}
		  set devs=/dev/sda2
		  set ttys=console=ttyS0
		  set options="\${ttys} root=\${devs} ${__SECU}"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__TGET_VLNZ:?} \${options} --- quiet
		  echo 'Loading initramfs ...'
		  initrd ${__TGET_IRAM:?}
		}
_EOT_
	cp --preserve=timestamps "${__PATH:?}" "${__MNTP}"/boot/grub/
	cp --preserve=timestamps "${__THME:?}" "${__MNTP}"/boot/grub/
	cp --preserve=timestamps "${__MENU:?}" "${__MNTP}"/boot/grub/
	# -------------------------------------------------------------------------
	umount "${__MNTP}"
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
