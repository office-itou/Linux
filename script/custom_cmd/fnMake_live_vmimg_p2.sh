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
	declare       __FSTB=""									# work
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
#	cp --preserve=mode,ownership,timestamps,links,xattr --no-preserve --recursive "${__TGET_RTFS}"/. "${__MNTP}"
	cp --no-dereference --recursive --preserve=all --no-preserve=context "${__TGET_RTFS}"/. "${__MNTP}"
	# --- /etc/fstab ----------------------------------------------------------
	__FSTB="/etc/fstab"
	__SRCS="${__OUTD:?}/${__FSTB##*/}"
	__DEST="${__MNTP:?}/${__FSTB#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	{
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "# <file system>"  "<mount point>" "<type>"           "<options>"            "<dump>" "<pass>"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "UUID=${__UUID:?}" "/"             "ext4"             "defaults"             "0"      "0"
		printf "%-43s %-43s %-31s %-31s %-7s %-s\n" "#.host:/"         "/srv/hgfs"     "fuse.vmhgfs-fuse" "allow_other,defaults" "0"      "0"
	} > "${__SRCS:?}"
	[[ -e "${__SRCS:?}" ]] && cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	# --- run-once.sh ---------------------------------------------------------
	__SRVC="/etc/systemd/system/run-once.service"
	__ADMN="/var/admin/autoinst"
	__TGET="${__ADMN:?}/run-once.sh"
	__SRCS="${__OUTD:?}/${__TGET##*/}"
	__DEST="${__MNTP:?}/${__TGET#/}"
	mkdir -p "${__SRCS%/*}"
	mkdir -p "${__DEST%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		#!/bin/bash
		set -eu
		declare -r    _PROG_PATH="\$0"
		declare -r    _PROG_NAME="\${_PROG_PATH##*/}"
		declare -r    __ADMN="${__ADMN:?}"
		declare -r    __STAT="\${__ADMN:?}/\${_PROG_NAME}.success"
		declare -r    __SRVC="${__SRVC:?}"
		declare -r    __FSTB="${__FSTB:?}"
		declare -r -a __LIST=(
		 	"/usr/bin/thunderbird       thunderbird"
		 	"/usr/bin/firefox           firefox"
		 	"/usr/bin/chromium-browser  chromium"
		)
		declare       __PATH=""
		declare       __PACK=""
		declare -i    I=0
		{
		 	printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "\$(date +"%Y/%m/%d %H:%M:%S" || true)"
		#	touch /.autorelabel
		 	if command -v /usr/bin/snap > /dev/null 2>&1; then
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "snap install"
		 		for I in "\${!__LIST[@]}"
		 		do
		 			read -r __PATH __PACK < <(echo "\${__LIST[I]}")
		 			[[ ! -e "\${__PATH}" ]] && continue
		 			echo "snap install \\"\${__PACK}\\""
		 			snap install "\${__PACK}"
		 		done
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "snap install"
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "start" "snap capabilities"
		 		getcap /usr/lib/snapd/snap-confine
		 		getfattr --dump --match="^security\\." /usr/lib/snapd/snap-confine
		#		setcap -q - /usr/lib/snapd/snap-confine < /usr/lib/snapd/snap-confine.caps
		#		getcap /usr/lib/snapd/snap-confine
		#		getfattr --dump --match="^security\\." /usr/lib/snapd/snap-confine
		 		printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "snap capabilities"
		 	fi
		 	[[ -e "\${__FSTB:?}" ]] &&sed -i "\${__FSTB:?}" -e '/^UUID=/d'
		 	ls -lahZ /
		 	[[ -e "\${__SRVC:?}" ]] && systemctl disable "\${__SRVC##*/}"
		 	mkdir -p "\${__ADMN:?}"
		 	[[ -e "\${__SRVC:?}"     ]] && mv "\${__SRVC:?}" "\${__ADMN:?}"
		#	[[ -e "\${_PROG_PATH:?}" ]] && mv "\${_PROG_PATH:?}" "\${__ADMN:?}"
		 	touch "\${__STAT}"
		 	shutdown -h now
		 	printf "\\033[m%s\\033[m: \\033[92m--- %-8.8s: %s ---\\033[m\\n" "\${_PROG_NAME:-}" "complete" "\$(date +"%Y/%m/%d %H:%M:%S" || true)"
		} > /dev/console 2>&1
		exit 0
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
#	[[ -e "${__DEST:?}" ]] && chmod +x "${__DEST}"
	# --- setup ---------------------------------------------------------------
	chroot "${__MNTP:?}" bash -c "systemctl enable ${__SRVC##*/}"
	# -------------------------------------------------------------------------
	umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __TGET __SRVC __DEST __SRCS __FSTB
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
