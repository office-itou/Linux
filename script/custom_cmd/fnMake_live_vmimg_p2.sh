# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image partition2
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
function fnMake_live_vmimg_p2() {
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
	declare       __SRCS=""				# work
	declare       __DEST=""				# work

	__MNTP="${__TGET_OUTD}/mnt2"
	mkdir -p "${__MNTP}"
	mount "${__TGET_DEVS}${__TGET_PART}" "${__MNTP}"
	# --- root files ----------------------------------------------------------
	cp --preserve=mode,ownership,timestamps,links --recursive "${__TGET_RTMP}"/. "${__MNTP}"
	# --- /etc/fstab ----------------------------------------------------------
	__PATH="/etc/fstab"
	__SRCS="${__OUTD}/${__PATH##*/}"
	__DEST="${__MNTP}/${__PATH#/}"
	mkdir -p "${__SRCS%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		UUID=${__TGET_UUID:?} / ext4 defaults 0 0
_EOT_
	mkdir -p "${__DEST%/*}"
	cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	# --- run-once.sh ---------------------------------------------------------
	__SRVC="/etc/systemd/system/run-once.service"
	__TGET="/var/admin/autoinst/run-once.sh"
	__SRCS="${__OUTD}/${__TGET##*/}"
	__DEST="${__MNTP}/${__TGET#/}"
	mkdir -p "${__SRCS%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		#!/bin/bash
		# touch /.autorelabel
		systemctl disable ${__SRVC##*/}
		rm -f "${__SRVC}"
		rm -f "\${0:?}"
		ls -lahZ / > /var/admin/autoinst/"\${0##*/}".success
		shutdown -h now
_EOT_
	mkdir -p "${__DEST%/*}"
	cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	chmod +x "${__DEST}"
	# --- /etc/systemd/system/run-once.service --------------------------------
	__SRCS="${__OUTD}/${__SRVC##*/}"
	__DEST="${__MNTP}/${__SRVC#/}"
	mkdir -p "${__SRCS%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__SRCS:?}"
		[Unit]
		Description=Run the script once after all services have started.
		After=network.target multi-user.target
		Requires=multi-user.target

		[Service]
		Type=oneshot
		ExecStart=${__TGET#"${__MNTP}"}
		RemainAfterExit=yes

		[Install]
		WantedBy=multi-user.target
_EOT_
	mkdir -p "${__DEST%/*}"
	cp --preserve=timestamps "${__SRCS:?}" "${__DEST:?}"
	chmod +x "${__DEST}"
	chroot "${__MNTP:?}" bash -c "systemctl enable ${__SRVC##*/}"
	# -------------------------------------------------------------------------
	umount "${__MNTP}"
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
