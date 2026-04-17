# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image partition2
#   input :     $1     : device name
#   input :     $2     : partition
#   input :     $3     : output directory
#   input :     $4     : root image mount point
#   input :     $5     : uuid
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_vmimg_p2() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_DEVS="${1:?}"	# device name
	declare -r    __TGET_PART="${2:?}"	# partition
	declare -r    __TGET_OUTD="${3:?}"	# output directory
	declare -r    __TGET_RTFS="${4:?}"	# root image mount point
	declare -r    __TGET_UUID="${5:?}"	# uuid
#	declare -r    __INPD="/boot/grub"						# input directory
	declare -r    __OUTD="${__TGET_OUTD:?}/strg"			# output directory
	declare -r    __MNTP="${__TGET_OUTD:?}/mnt2"			# mount point
#	declare -r    __CDFS="${__TGET_OUTD:?}/${_DIRS_CDFS:?}"	# cdfs image mount point
#	declare -r    __EGRU="${__OUTD:?}/${_FILE_GCFG:?}.efi"	# grub.cfg (/EFI/BOOT)
#	declare -r    __GCFG="${__OUTD:?}/${_FILE_GCFG:?}"		# grub.cfg (/boot/grub)
#	declare -r    __ICFG="${__OUTD:?}/${_FILE_ICFG:?}"		# isolinux.cfg
#	declare -r    __MENU="${__OUTD:?}/${_FILE_MENU:?}"		# menu.cfg
#	declare -r    __THME="${__OUTD:?}/${_FILE_THME:?}"		# theme.cfg
#	declare -r    __SPLS="${__OUTD:?}/${_MENU_SPLS:?}"		# splash.png
#	declare -r    __TITL="Live system"						# title
#	declare       __COMD=""									# command
	declare       __PATH=""									# work
	declare       __SRCS=""									# work
	declare       __DEST=""									# work
	declare       __SRVC=""									# work
	declare       __TGET=""									# work
#	declare       __WORK=""									# work
	# --- local ---------------------------------------------------------------
	mkdir -p "${__OUTD:?}"
	mkdir -p "${__MNTP:?}"
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
	# --- root files ----------------------------------------------------------
	cp --preserve=mode,ownership,timestamps,links --recursive "${__TGET_RTFS}"/. "${__MNTP}"
	# --- /etc/fstab ----------------------------------------------------------
	__PATH="/etc/fstab"
	__SRCS="${__OUTD:?}/${__PATH##*/}"
	__DEST="${__MNTP:?}/${__PATH#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	{
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "# <file system>"  "<mount point>" "<type>"           "<options>"                   "<dump>" "<pass>"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "UUID=${__UUID:?}" "/"             "ext4"             "defaults"                    "0"      "0"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" ".host:/"          "/srv/hgfs"     "fuse.vmhgfs-fuse" "nofail,allow_other,defaults" "0"      "0"
	} > "${__SRCS:?}"
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	# --- run-once.sh ---------------------------------------------------------
	__SRVC="/etc/systemd/system/run-once.service"
	__TGET="/var/admin/autoinst/run-once.sh"
	__SRCS="${__OUTD:?}/${__TGET##*/}"
	__DEST="${__MNTP:?}/${__TGET#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		#!/bin/bash
		# touch /.autorelabel
		systemctl disable ${__SRVC##*/}
		sed -i "${__PATH:?}" -e '/^UUID=/d'
		rm -f "${__SRVC:?}"
		rm -f "\${0:?}"
		ls -lahZ / > /var/admin/autoinst/"\${0##*/}".success
		shutdown -h now
_EOT_
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	[[ -e "${__DEST:?}" ]] && chmod +x "${__DEST}"
	# --- /etc/systemd/system/run-once.service --------------------------------
	__SRCS="${__OUTD:?}/${__SRVC##*/}"
	__DEST="${__MNTP:?}/${__SRVC#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		[Unit]
		Description=Run the script once after all services have started.
		After=network.target multi-user.target
		Requires=multi-user.target

		[Service]
		Type=oneshot
		ExecStart=${__TGET:?}
		RemainAfterExit=yes

		[Install]
		WantedBy=multi-user.target
_EOT_
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	[[ -e "${__DEST:?}" ]] && chmod +x "${__DEST}"
	# --- setup ---------------------------------------------------------------
	chroot "${__MNTP:?}" bash -c "systemctl enable ${__SRVC##*/}"
	# -------------------------------------------------------------------------
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __TGET __SRVC __DEST __SRCS __PATH
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
