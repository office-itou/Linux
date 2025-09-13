#!/bin/bash

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	declare -r    _PROG_PATH="$0"
#	declare -r -a _PROG_PARM=("${@:-}")
#	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	declare       _DIRS_BASE="live/${1:?}"
	shift
	declare       _FLAG_FORC=""
	declare       _FLAG_HOLD=""
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			-f|--force) _FLAG_FORC="true";;
			-h|--hold ) _FLAG_HOLD="true";;
			*         ) ;;
		esac
		shift
	done
	readonly      _FLAG_FORC
	readonly      _FLAG_HOLD

	mkdir -p "${_DIRS_BASE}"
	              _DIRS_BASE="$(realpath "${_DIRS_BASE%/}")"
	readonly      _DIRS_BASE
	declare -r    _DIRS_OLAY="${_DIRS_BASE}/overlay"
	declare -r    _FILE_CONF="${_DIRS_BASE}/mkosi.conf"
	declare       _FILE_SQFS=""
#	declare -r    _FILE_SQFS="${_DIRS_BASE:?}/filesystem.squashfs"
#	declare -r    _FILE_SQFS="${_DIRS_BASE:?}/minimal.squashfs"
	declare -r    _DIRS_TGET="${_DIRS_OLAY}/merged"

	rm -rf "${_DIRS_OLAY:?}"
	mkdir -p "${_DIRS_BASE}"/image \
	         "${_DIRS_OLAY}"/{upper,lower,work,merged}
	mv "${_DIRS_OLAY}"/lower "${_DIRS_OLAY}"/lower.back
	ln -sr "${_DIRS_BASE}"/image "${_DIRS_OLAY}"/lower

	declare       _FILE_INRD="${_DIRS_TGET}/initrd"
	declare       _FILE_KENL="${_DIRS_TGET}/vmlinuz"

	declare       _DIST_INFO="${_DIRS_BASE##*/}"
	readonly      _DIST_INFO="${_DIST_INFO,,}"
	declare       _DIST_NAME="${_DIST_INFO%%-*}"
	              _TEXT_WRK1="${_DIST_NAME%linux}"
	              _TEXT_WRK2="${_DIST_NAME#"${_TEXT_WRK1}"}"
	              _DIST_NAME="${_TEXT_WRK1}"
	readonly      _DIST_NAME
	declare -r    _DIST_VERS="${_DIST_INFO#*-}"
	declare       _DIRS_LIVE=""
	case "${_DIST_INFO}" in
		debian-*           | \
		ubuntu-*           ) _DIRS_LIVE="live"; _FILE_SQFS="${_DIRS_BASE:?}/filesystem.squashfs";;
		fedora-*           | \
		centos-stream-*    | \
		almalinux-*        | \
		rockylinux-*       | \
		miraclelinux-*     ) _DIRS_LIVE="LiveOS"; _FILE_SQFS="${_DIRS_BASE:?}/squashfs.img";;
		opensuse-leap-15.* ) ;;
		opensuse-leap-16.* ) ;;
		opensuse-tumbleweed) ;;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
#	_DIRS_LIVE="live"
#	_FILE_SQFS="${_DIRS_BASE:?}/filesystem.squashfs"
	readonly      _DIRS_LIVE
	readonly      _FILE_SQFS
	# fedora,  debian,  kali,  ubuntu,  arch,  opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure or custom
	case "${_DIST_INFO}" in
		debian-11          ) sed -e '/^Release/ s/=.*$/=bullseye/' /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-12          ) sed -e '/^Release/ s/=.*$/=bookworm/' /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-13          ) sed -e '/^Release/ s/=.*$/=trixie/'   /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-14          ) sed -e '/^Release/ s/=.*$/=forky/'    /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-15          ) sed -e '/^Release/ s/=.*$/=duke/'     /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-testing     ) sed -e '/^Release/ s/=.*$/=testing/'  /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		debian-sid         ) sed -e '/^Release/ s/=.*$/=sid/'      /srv/user/share/conf/_template/mkosi.debian.conf > "${_FILE_CONF}";;
		ubuntu-22.04       ) sed -e '/^Release/ s/=.*$/=jammy/'    /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-22.10       ) sed -e '/^Release/ s/=.*$/=kinetic/'  /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-23.04       ) sed -e '/^Release/ s/=.*$/=lunar/'    /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-23.10       ) sed -e '/^Release/ s/=.*$/=mantic/'   /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-24.04       ) sed -e '/^Release/ s/=.*$/=noble/'    /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-24.10       ) sed -e '/^Release/ s/=.*$/=oracular/' /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-25.04       ) sed -e '/^Release/ s/=.*$/=plucky/'   /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		ubuntu-25.10       ) sed -e '/^Release/ s/=.*$/=questing/' /srv/user/share/conf/_template/mkosi.ubuntu.conf > "${_FILE_CONF}";;
		fedora-*           | \
		centos-stream-*    | \
		almalinux-*        | \
		rockylinux-*       | \
		miraclelinux-*     )
			sed -e '/^Distribution/ s/=.*$/='"${_DIST_NAME}"'/'         \
			    -e '/^Release/      s/=.*$/='"${_DIST_VERS}"'/'         \
				  /srv/user/share/conf/_template/mkosi.rhel-series.conf \
				> "${_FILE_CONF}"
			;;
		opensuse-leap-15.* ) ;;
		opensuse-leap-16.* ) ;;
		opensuse-tumbleweed) ;;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
	declare       _FILE_SPLS=""
	case "${_DIST_INFO}" in
		debian-6           ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/spacefun-theme/grub/grub-16x9.png       ;;
		debian-7           ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/joy-theme/grub/grub-16x9.png            ;;
		debian-8           ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/lines-theme/grub/grub-16x9.png          ;;
		debian-9           ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/softwaves-theme/grub/grub-16x9.png      ;;
#		debian-10          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/moonlight-theme/grub/grub-16x9.png      ;;
		debian-10          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/futureprototype-theme/grub/grub-16x9.png;;
		debian-11          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/homeworld-theme/grub/grub-16x9.png      ;;
		debian-12          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/emerald-theme/grub/grub-16x9.png        ;;
		debian-13          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/ceratopsian-theme/grub/grub-16x9.png    ;;
#		debian-13          ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/desktop-base/ceratopsian-theme/grub/grub-16x9.png    ;;
		debian-14          ) ;;
		debian-15          ) ;;
		debian-testing     ) ;;
		debian-sid         ) ;;
		ubuntu-16.04       ) ;;
		ubuntu-18.04       ) ;;
		ubuntu-20.04       ) ;;
		ubuntu-22.04       ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/backgrounds/warty-final-ubuntu.png;;
		ubuntu-24.04       ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/backgrounds/warty-final-ubuntu.png;;
		ubuntu-24.10       ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/backgrounds/warty-final-ubuntu.png;;
		ubuntu-25.04       ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/backgrounds/warty-final-ubuntu.png;;
		ubuntu-25.10       ) _FILE_SPLS="${_DIRS_TGET}"/usr/share/backgrounds/warty-final-ubuntu.png;;
		fedora-42          ) ;;
		fedora-43          ) ;;
		centos-stream-9    ) ;;
		centos-stream-10   ) ;;
		almalinux-9        ) ;;
		almalinux-10       ) ;;
		rockylinux-9       ) ;;
		rockylinux-10      ) ;;
		miraclelinux-9     ) ;;
		miraclelinux-10    ) ;;
		opensuse-leap-15   ) ;;
		opensuse-leap-16   ) ;;
		opensuse-tumbleweed) ;;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
	readonly      _FILE_SPLS

#	declare -r    _VIDE_MODE="1280x720"
	declare -r    _VIDE_MODE="854x480"	# 16:9
#	declare -r    _VIDE_MODE="1024x768"	# 4:3

	declare       _TGET_DIST=""
	              _TGET_DIST="$(sed -ne '/^\[Distribution\]$/,/\(^$\|^\[.*\]$\)/ {/^Distribution=/ s/^.*=//p}' "${_FILE_CONF:?}")"
	readonly      _TGET_DIST="${_TGET_DIST,,}"
	declare       _TGET_SUIT=""
	              _TGET_SUIT="$(sed -ne '/^\[Distribution\]$/,/\(^$\|^\[.*\]$\)/ {/^Release=/ s/^.*=//p}'      "${_FILE_CONF:?}")"
	readonly      _TGET_SUIT="${_TGET_SUIT,,}"

	declare -r    _FILE_ISOS="/srv/user/share/rmak/live-${_DIST_INFO%"-${_TGET_SUIT}"}-${_TGET_SUIT}-amd64.iso"
	declare -r    _FILE_VLID="${_DIST_INFO^}-Live-Media"
#	declare -r    _FILE_VLID="LiveOS_rootfs"

	declare -r    _DIRS_MNTP="${_DIRS_BASE}/mnt"
	declare -r    _DIRS_CDFS="${_DIRS_BASE}/cdfs"
	declare       _FILE_WORK=""
	              _FILE_WORK="${_DIRS_BASE}/${_FILE_ISOS##*/}.work"
	readonly      _FILE_WORK
	declare -r    _FILE_UEFI="${_DIRS_BASE}/efi.img"
	declare -r    _FILE_BIOS="${_DIRS_BASE}/boot.img"
	declare -r    _PATH_ETRI="/usr/lib/grub/i386-pc/eltorito.img"
	if [[ -e "${_PATH_ETRI}" ]]; then
		declare -r    _FILE_BCAT="boot/grub/boot.catalog"
		declare -r    _FILE_ETRI="boot/grub/i386-pc/${_PATH_ETRI##*/}"
	else
		declare -r    _FILE_BCAT="isolinux/boot.catalog"
		declare -r    _FILE_ETRI="isolinux/isolinux.bin"
	fi
	declare -r    _MENU_SLNX="${_DIRS_CDFS}/isolinux/isolinux.cfg"
	declare -r    _MENU_GRUB="${_DIRS_CDFS}/boot/grub/grub.cfg"
	declare -r    _MENU_FTHM="${_DIRS_CDFS}/boot/grub/theme.txt"
	declare       _MENU_DIST=""

	declare -r -a _BOOT_DEBS=(\
		"boot=${_DIRS_LIVE}" \
		"nonetworking" \
		"dhcp" \
		"components" \
		"overlay-size=90%" \
		"hooks=medium" \
		"utc=yes" \
		"locales=ja_JP.UTF-8" \
		"timezone=Asia/Tokyo" \
		"keyboard-layouts=jp,us" \
		"keyboard-model=pc105" \
		"keyboard-variants=," \
		"---" \
		"quiet" \
		"splash" \
		"fsck.mode=skip" \
		"raid=noautodetect" \
	)

	declare -r -a _BOOT_RHEL=(\
		"selinux=0" \
		"ip=dhcp" \
		"root=LABEL=${_FILE_VLID}" \
		"iso-scan/filename=${_FILE_ISOS##*/}" \
		"timezone=Asia/Tokyo" \
		"rd.locale.LANG=ja_JP.UTF-8" \
		"rd.vconsole.keymap=jp" \
		"rd.live.ram=1" \
	)
#		"rd.live.overlay.overlayfs=1" \
#		"rd.live.overlay=/dev/sr0:auto" \
#		"rd.live.dir=/${_DIRS_LIVE}" \
#		"rd.locale.LANG=ja_JP.UTF-8" \
#		"rd.locale.LC_ALL=ja_JP.UTF-8" \
#		"rd.vconsole.keymap=jp" \
#		"rd.vconsole.font=default8x16" \
#		"rd.live.ram=1" \
#		"rd.info" \
#		"rd.debug" \
#		"rd.shell" \
#		"rd.live.debug=1" \
#	declare -r -a _BOOT_RHEL=(\
#		"ip=dhcp" \
#		"boot=${_DIRS_LIVE}" \
#		"iso-scan/filename=${_FILE_ISOS##*/}" \
#		"root=live:LABEL=${_FILE_VLID}" \
#		"rd.live.image" \
#		"rd.live.overlay.overlayfs=1" \
#	)

	declare -r -a _OPTN_XORR=(\
		-quiet -rational-rock \
		${_FILE_VLID:+-volid "${_FILE_VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		${_FILE_BIOS:+--grub2-mbr "${_FILE_BIOS}"} \
		--mbr-force-bootable \
		${_FILE_UEFI:+-append_partition 2 0xEF "${_FILE_UEFI}"} \
		-appended_part_as_gpt \
		${_FILE_BCAT:+-eltorito-catalog "${_FILE_BCAT}"} \
		${_FILE_ETRI:+-eltorito-boot "${_FILE_ETRI}"} \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot
	)

	# --- trap ----------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${_DIRS_TEMP:?}")

# -----------------------------------------------------------------------------
# descript: trap
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnTrap() {
	echo "fnTrap"
	declare       __PATH=""				# full path
	declare -i    I=0
	# --- unmount -------------------------------------------------------------
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -rV)
	do
		__PATH="${_LIST_RMOV[I]}"
		if [[ -e "${__PATH}" ]] && mountpoint --quiet "${__PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		fi
	done
	# --- remove temporary ----------------------------------------------------
	if [[ -e "${_DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${_DIRS_TEMP}" 1>&2
		while read -r __PATH
		do
			printf "[%s]: umount \"%s\"\n" "-" "${__PATH}" 1>&2
			umount --quiet         --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${__PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${__PATH}" || true
		done < <(grep "${_DIRS_TEMP:?}" /proc/mounts | cut -d ' ' -f 2 | sort -rV || true)
		rm -rf "${_DIRS_TEMP:?}"
	fi
}

	trap fnTrap EXIT

# -----------------------------------------------------------------------------
# descript: create filesystem image
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_fsimage() {
	echo "fnCreate_fsimage"
#	rm -rf "${_DIRS_TGET:?}"
	if ! nice -n 19 mkosi \
		--force \
		--wipe-build-dir \
		${_TGET_SUIT:+--release ${_TGET_SUIT}} \
		--directory="${_DIRS_BASE}" \
		--architecture=x86-64 \
		; then
		exit "$?"
	fi
}

# -----------------------------------------------------------------------------
# descript: create initramfs
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_initrd() {
	echo "fnCreate_initrd"
	_SHEL_NAME="/tmp/create_initrd.sh"
	_FILE_PATH="${_DIRS_TGET}${_SHEL_NAME}"
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		#!/bin/bash
		set -eu
		declare -a    _INST_PAKG=(\\
		)
		readonly      _INST_PAKG
		declare -a    _MODU_ADDS=(\\
		 	"busybox" \\
		 	"rescue" \\
		 	"pollcdrom" \\
		 	"ecryptfs" \\
		 	"dbus" \\
		 	"kernel-network-modules" \\
		 	"network" \\
		 	"net-lib" \\
		 	"ssh-client" \\
		 	"url-lib" \\
		 	"numlock" \\
		 	"overlayfs" \\
		 	"pcmcia" \\
			"systemd-timedated" \\
			"warpclock" \\
		)
		readonly      _MODU_ADDS
		declare -a    _MODU_OMIT=(\\
		)
		readonly      _MODU_OMIT
		# -----------------------------------------------------------------------------
		_SHEL_NAME="mount_sysroot.sh"
		_FILE_PATH="/tmp/\${_SHEL_NAME}"
		mkdir -p "\${_FILE_PATH%/*}"
		cat <<- __EOT__ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "\${_FILE_PATH}" || true
		 	#!/bin/bash
		 	set -eu
		 	_PATH_MDIA="\\\${root:-}"
		 	_PATH_MDIA="\\\${_PATH_MDIA#block:}"
		 	if [[ -n "\\\${_PATH_MDIA:-}" ]]; then
		 	 	mkdir -p /run/${_DIRS_LIVE}/{cdrom,overlay/{lowerdir,upperdir,workdir,merged}}
		 	 	mount -t iso9660  -o ro,nofail "\\\${_PATH_MDIA}" /run/${_DIRS_LIVE}/cdrom
		 	 	mount -t squashfs -o ro,nofail /run/${_DIRS_LIVE}/cdrom/${_DIRS_LIVE}/${_FILE_SQFS##*/} /run/${_DIRS_LIVE}/overlay/lowerdir
		 	 	mount -t overlay overlay -o lowerdir=/run/${_DIRS_LIVE}/overlay/lowerdir,upperdir=/run/${_DIRS_LIVE}/overlay/upperdir,workdir=/run/${_DIRS_LIVE}/overlay/workdir /run/${_DIRS_LIVE}/overlay/merged
		 	 	mount --bind /run/${_DIRS_LIVE}/overlay/merged /sysroot
		 	fi
		__EOT__
		chmod +x "\${_FILE_PATH}"
		# -----------------------------------------------------------------------------
		ln -s ../usr/share/zoneinfo/Asia/Tokyo /tmp/localtime
		echo 'LANG="ja_JP.UTF-8"' > /tmp/locale.conf
		_KRNL_INFO="\$(ls /usr/lib/modules/)"
		_ARCH_TYPE="\${_KRNL_INFO##*[-.]}"
		_KRNL_VERS="\${_KRNL_INFO%"[-.]\${_ARCH_TYPE}"}"
		cp -a "/usr/lib/modules/\${_KRNL_INFO}/vmlinuz" "/boot/vmlinuz-\${_KRNL_INFO}"
		dracut \\
		 	--force \\
		 	--no-hostonly \\
		 	--no-hostonly-i18n \\
		 	--regenerate-all \\
		 	\${_MODU_ADDS[*]:+--add "\${_MODU_ADDS[*]}"} \\
		 	\${_MODU_OMIT[*]:+--omit "\${_MODU_OMIT[*]}"} \\
		 	--filesystems "ext4 fat exfat isofs squashfs udf xfs" \\
			--include "/tmp/localtime"                 "/etc/localtime" \\
		 	--include "/usr/share/zoneinfo"            "/usr/share/zoneinfo" \\
		 	--include "\${_FILE_PATH}" "/lib/dracut/hooks/mount/00-\${_SHEL_NAME}"
		#	--mount "/dev/sr0 /cdrom/ iso9660 ro,nofail" \\
		#	--mount "/cdrom/\${_DIRS_LIVE}/${_FILE_SQFS##*/} /squashfs/ squashfs ro,nofail" \\
		#	--mount "/tmp /overlay tmpfs bind" \\
		#	--mount "/squashfs /sysroot overlay lowerdir=/squashfs,upperdir=/overlay/upperdir,workdir=/overlay/workdir"
		rm -f /tmp/localtime
		rm -f /tmp/locale.conf
		rm -f "\${_FILE_PATH:?}"
_EOT_

	chmod +x "${_FILE_PATH}"
	chroot "${_DIRS_TGET}" "${_SHEL_NAME}" || exit $?
	rm -f "${_FILE_PATH:?}"
}

# -----------------------------------------------------------------------------
# descript: configure filesystem image
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnConfig_fsimage() {
	echo "fnConfig_fsimage"
	mount --rbind /dev/                  "${_DIRS_TGET}/dev/"  && mount --make-rslave "${_DIRS_TGET}/dev/" && _LIST_RMOV+=("${_DIRS_TGET}/dev/"  )
	mount -t proc /proc/                 "${_DIRS_TGET}/proc/"                                             && _LIST_RMOV+=("${_DIRS_TGET}/proc/" )
	mount --rbind /sys/                  "${_DIRS_TGET}/sys/"  && mount --make-rslave "${_DIRS_TGET}/sys/" && _LIST_RMOV+=("${_DIRS_TGET}/sys/"  )
	mount  --bind /run/                  "${_DIRS_TGET}/run/"                                              && _LIST_RMOV+=("${_DIRS_TGET}/run/"  )
	mount --rbind /tmp/                  "${_DIRS_TGET}/tmp/"  && mount --make-rslave "${_DIRS_TGET}/tmp/" && _LIST_RMOV+=("${_DIRS_TGET}/tmp/"  )
	# -------------------------------------------------------------------------
	_SHEL_NAME="/usr/local/bin/zz-all-ethernet.sh"
	_EXEC_TGET="${_DIRS_TGET:?}${_SHEL_NAME}"
	mkdir -p "${_EXEC_TGET%/*}"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_EXEC_TGET}"
		#!/bin/sh

		/usr/bin/nmcli connection up zz-all-en  2> /dev/null || true
		/usr/bin/nmcli connection up zz-all-eth 2> /dev/null || true

		exit 0
_EOT_
	chmod +x "${_EXEC_TGET}"
	# -------------------------------------------------------------------------
	_FILE_PATH="${_DIRS_TGET:?}/etc/systemd/system/zz-all-ethernet.service"
	mkdir -p "${_FILE_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
		[Unit]
		Description=Up zz-all-ethernet
		After=NetworkManager.service

		[Service]
		ExecStart=${_SHEL_NAME}
		Type=oneshot

		[Install]
		WantedBy=default.target
_EOT_
	chroot "${_DIRS_TGET}" systemctl enable "${_FILE_PATH##*/}"
	# -------------------------------------------------------------------------
	case "${_DIST_INFO}" in
		debian-*           | \
		ubuntu-*           ) ;;
		fedora-*           | \
		centos-stream-*    | \
		almalinux-*        | \
		rockylinux-*       | \
		miraclelinux-*     )
			_FILE_PATH="${_DIRS_TGET:?}/etc/systemd/system-preset/00-user-custom.preset"
			mkdir -p "${_FILE_PATH%/*}"
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FILE_PATH}"
				enable sshd.service
				#enable sshd.socket
				enable systemd-resolved.service
				enable dnsmasq.service
				enable smb.service
				enable nmb.service
				enable httpd.service
				#enable httpd.socket
				enable firewalld.service
_EOT_
			chroot "${_DIRS_TGET}" systemctl set-default graphical.target
			chroot "${_DIRS_TGET}" systemctl enable sshd.service systemd-resolved.service dnsmasq.service smb.service nmb.service httpd.service firewalld.service
			chroot "${_DIRS_TGET}" useradd --create-home --user-group --groups audio,cdrom,floppy,video,wheel --comment "${_DIST_INFO%%-[0-9]*} Live user" --password '$y$j9T$ke439aNLCgDVj6bFX9yO//$61x.uzoS5y.XV.dx31D0fwQgvV0bFLuhfi.xiDzT1P8' "master"
			# echo "master" | mkpasswd -s
			;;
		opensuse-leap-*    | \
		opensuse-tumbleweed) ;;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
	# -------------------------------------------------------------------------
	_SHEL_NAME="/srv/user/share/conf/script/autoinst_cmd_late.sh"
	if [[ -e "${_SHEL_NAME}" ]]; then
		_EXEC_TGET="/tmp/${_SHEL_NAME##*/}"
		cp -a "${_SHEL_NAME}" "${_DIRS_TGET}${_EXEC_TGET%/*}"
		chmod +x "${_DIRS_TGET}${_EXEC_TGET:?}"
		chroot "${_DIRS_TGET}" "${_EXEC_TGET:?}" \
			ip=192.168.1.0::192.168.1.254:255.255.255.0:${_TGET_DIST:+"live-${_TGET_DIST}.workgroup"}:-:192.168.1.254
		rm -f "${_DIRS_TGET:?}${_EXEC_TGET:?}"
	fi
	[[ -e "${_DIRS_TGET:?}/usr/lib/systemd/user/orca.service"        ]] && chroot "${_DIRS_TGET}" systemctl --global disable orca.service
	# -------------------------------------------------------------------------
	case "${_DIST_INFO}" in
		debian-*           | \
		ubuntu-*           ) ;;
		fedora-*           | \
		centos-stream-*    | \
		almalinux-*        | \
		rockylinux-*       | \
		miraclelinux-*     ) fnCreate_initrd;;
		opensuse-leap-*    | \
		opensuse-tumbleweed) ;;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
	# -------------------------------------------------------------------------
	umount --recursive     "${_DIRS_TGET}/tmp/"
	umount                 "${_DIRS_TGET}/run/"
	umount --recursive     "${_DIRS_TGET}/sys/"
	umount                 "${_DIRS_TGET}/proc/"
	umount --recursive     "${_DIRS_TGET}/dev/"
	# -------------------------------------------------------------------------
	rm -f "${_DIRS_BASE:?}"/{initrd*,initramfs*,vmlinuz*,linux*splash.png,os-release}
	_FILE_INRD="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  -o -name 'initramfs' -o -name 'initramfs-*' \) | sort -Vu || true)"
	_FILE_KENL="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*'                                             \) | sort -Vu || true)"
	[[ -e "${_FILE_KENL:-}"                ]] && cp -aL "${_FILE_KENL}"                  "${_DIRS_BASE}"
	[[ -e "${_FILE_INRD:-}"                ]] && cp -aL "${_FILE_INRD}"                  "${_DIRS_BASE}"
	[[ -e "${_FILE_SPLS:-}"                ]] && cp -aL "${_FILE_SPLS}"                  "${_DIRS_BASE}/splash.png"
	[[ -e "${_DIRS_TGET:-}/etc/os-release" ]] && cp -aL "${_DIRS_TGET:-}/etc/os-release" "${_DIRS_BASE}"
	# -------------------------------------------------------------------------
#	_PATH_INRD="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  \) | sort -Vu)"
#	_PATH_KENL="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*' \) | sort -Vu)"
#	_FILE_INRD="${_PATH_INRD##*/}"
#	_FILE_KENL="${_PATH_KENL##*/}"
#	for _FILE_PATH in "${_DIRS_TGET}"/{"${_FILE_INRD%%-*}"{,.old},"${_FILE_KENL%%-*}"{,.old}}
#	do
#		if [[ -e "${_FILE_PATH}" ]]; then
#			continue
#		fi
#		case "${_FILE_PATH##*/}" in
#			initrd* ) ln -s "${_PATH_INRD#"${_DIRS_TGET}"/}" "${_FILE_PATH}";;
#			vmlinuz*) ln -s "${_PATH_KENL#"${_DIRS_TGET}"/}" "${_FILE_PATH}";;
#			*       ) ;;
#		esac
#	done
}

# -----------------------------------------------------------------------------
# descript: create config file
#   input :        : unused
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_config() {
	echo "fnCreate_config"
	_PATH_CONF="${_DIRS_TGET}/etc/${_DIRS_LIVE}/config.conf.d/user.conf"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH_CONF}"
		 	export LIVE_HOSTNAME="live-${_TGET_DIST}"
		 	export LIVE_USERNAME="master"
		 	export LIVE_USER_PASSWORD="master"
		 	export LIVE_USER_FULLNAME="${_TGET_DIST^} Live user"
		 	export LIVE_USER_DEFAULT_GROUPS="audio cdrom dip floppy video plugdev netdev powerdev scanner bluetooth debian-tor"

		 	for _PARAMETER in \${LIVE_CONFIG_CMDLINE:-}
		 	do
		 		case "\${_PARAMETER}" in
		 			live-config.user-password=*|user-password=*            ) LIVE_USER_PASSWORD="\${_PARAMETER#*user-password=}";;
		 			live-config.user-default-groups=*|user-default-groups=*) LIVE_USER_DEFAULT_GROUPS="\${_PARAMETER#*user-default-groups=}";;
		 			live-config.user-fullname=*|user-fullname=*            ) LIVE_USER_FULLNAME="\${_PARAMETER#*user-fullname=}";;
		 			live-config.username=*|username=*                      ) LIVE_USERNAME="\${_PARAMETER#*username=}";;
		 			*) ;;
		 		esac
		 	done
_EOT_
	# -------------------------------------------------------------------------
	_PATH_CONF="${_DIRS_TGET}/usr/lib/${_DIRS_LIVE}/config/0000-early-user-settings"
	_FILE_NAME="${_PATH_CONF##*/}"
	_FILE_NAME="${_FILE_NAME#[0-9]*-}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH_CONF}"
		#!/bin/sh

		 	[ -n "\${LIVE_BOOT_DEBUG:-}" ] && set -x

		Cmdline ()
		{
		 	for _PARAMETER in \${LIVE_CONFIG_CMDLINE:-}
		 	do
		 		case "\${_PARAMETER}" in
		 			live-config.user-password=*|user-password=*            ) LIVE_USER_PASSWORD="\${_PARAMETER#*user-password=}";;
		 			live-config.user-default-groups=*|user-default-groups=*) LIVE_USER_DEFAULT_GROUPS="\${_PARAMETER#*user-default-groups=}";;
		 			live-config.user-fullname=*|user-fullname=*            ) LIVE_USER_FULLNAME="\${_PARAMETER#*user-fullname=}";;
		 			live-config.username=*|username=*                      ) LIVE_USERNAME="\${_PARAMETER#*username=}";;
		 			*) ;;
		 		esac
		 	done
		}

		Init ()
		{
		 	printf "%s\n" " ${_FILE_NAME}"
		}

		Config ()
		{
		 	# Creating state file
		 	touch "/var/lib/${_DIRS_LIVE}/config/${_FILE_NAME}"
		}

		 	Cmdline
		 	Init
		 	Config

_EOT_
	chmod 755 "${_PATH_CONF}"
	# -------------------------------------------------------------------------
	_PATH_CONF="${_DIRS_TGET}/usr/lib/${_DIRS_LIVE}/config/9999-late-user-settings"
	_FILE_NAME="${_PATH_CONF##*/}"
	_FILE_NAME="${_FILE_NAME#[0-9]*-}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH_CONF}"
		#!/bin/sh

		 	[ -n "\${LIVE_BOOT_DEBUG:-}" ] && set -x

		Cmdline ()
		{
		 	for _PARAMETER in \${LIVE_CONFIG_CMDLINE:-}
		 	do
		 		case "\${_PARAMETER}" in
		 			live-config.user-password=*|user-password=*            ) LIVE_USER_PASSWORD="\${_PARAMETER#*user-password=}";;
		 			live-config.user-default-groups=*|user-default-groups=*) LIVE_USER_DEFAULT_GROUPS="\${_PARAMETER#*user-default-groups=}";;
		 			live-config.user-fullname=*|user-fullname=*            ) LIVE_USER_FULLNAME="\${_PARAMETER#*user-fullname=}";;
		 			live-config.username=*|username=*                      ) LIVE_USERNAME="\${_PARAMETER#*username=}";;
		 			*) ;;
		 		esac
		 	done
		}

		Init ()
		{
		 	printf "%s\n" " ${_FILE_NAME}"
		}

		Config ()
		{
		 	# Setup user
		 	_PASSWORD="\$(echo "\${LIVE_USER_PASSWORD}" | mkpasswd -s)"
		 	if id "\${LIVE_USERNAME}" > /dev/null 2>&1; then
		 		usermod --password "\${_PASSWORD:?}" "\${LIVE_USERNAME}"
		 	else
		 		useradd --create-home --user-group --groups "\${LIVE_USER_DEFAULT_GROUPS}" --comment "\${LIVE_USER_FULLNAME}" --password "\${_PASSWORD:?}" "\${LIVE_USERNAME}"
		 	fi

		 	# Setup samba user
		 	printf "%s\n%s\n" "\${LIVE_USER_PASSWORD}" "\${LIVE_USER_PASSWORD}" | smbpasswd -a -s "\${LIVE_USERNAME}"

		 	# Creating state file
		 	touch "/var/lib/${_DIRS_LIVE}/config/${_FILE_NAME}"
		}

		 	Cmdline
		 	Init
		 	Config

_EOT_
	chmod 755 "${_PATH_CONF}"

		 	# Setup network
		 	#find /run/NetworkManager/system-connections/ /etc/NetworkManager/system-connections/ -type f \( ! -name 'lo*' -a ! -name 'netplan-*' \) | while read -r _COMM_NAME
		 	#do
		 	#	nmcli connection down filename "\${_COMM_NAME}" || true
		 	#done

		 	#find /sys/devices/ -name net -exec ls -1 '{}' \; | while read -r _NICS_NAME
		 	#do
		 	#	if [ "\${_NICS_NAME}" = "lo" ]; then
		 	#		continue
		 	#	fi
		 	#	ip link set "\${_NICS_NAME}" down || true
		 	#done

}

function funcMount_overlay() {
	echo "funcMount_overlay"
	# shellcheck disable=SC2140
	mount -t overlay overlay -o lowerdir="${1:?}",upperdir="${2:?}",workdir="${3:?}" "${4:?}" && _LIST_RMOV+=("${4:?}")
}

# === mkosi ===================================================================
	if [[ -n "${_FLAG_FORC:-}" ]] || [[ ! -e "${_FILE_SQFS:?}" ]]; then
		if [[ -z "${_FLAG_HOLD:-}" ]]; then
			fnCreate_fsimage
		fi
	fi
	funcMount_overlay "${_DIRS_OLAY:?}/lower" "${_DIRS_OLAY:?}/upper" "${_DIRS_OLAY:?}/work" "${_DIRS_OLAY:?}/merged"
	if [[ -n "${_FLAG_FORC:-}" ]] || [[ ! -e "${_FILE_SQFS:?}" ]]; then
		fnConfig_fsimage
		case "${_DIST_INFO}" in
			debian-*           | \
			ubuntu-*           ) fnCreate_config;;
			fedora-*           | \
			centos-stream-*    | \
			almalinux-*        | \
			rockylinux-*       | \
			miraclelinux-*     ) ;;
			opensuse-leap-*    | \
			opensuse-tumbleweed) ;;
			*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
		esac
# === filesystem ==============================================================
		rm -f "${_FILE_SQFS:?}"
		if ! nice -n 19 mksquashfs "${_DIRS_TGET:?}" "${_FILE_SQFS:?}"; then
			exit "$?"
		fi
#		rm -rf "${_DIRS_TGET:?}"
	fi

# === iso image ===============================================================
	__DIST="debian"
#	__DIST="${_DIST_NAME}"
	rm -rf "${_DIRS_CDFS:?}"
#	mkdir -p "${_DIRS_CDFS}/"{.disk,EFI/boot,boot/grub/{live-theme,i386-pc,x86_64-efi},isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
	mkdir -p "${_DIRS_CDFS}/"{.disk,EFI/boot,boot/grub,isolinux,${_DIRS_LIVE}/{boot,config.conf.d,config-hooks,config-preseed}}
	: > "${_DIRS_CDFS}/.disk/info"
	rm -f "${_FILE_UEFI:?}"
	dd if=/dev/zero of="${_FILE_UEFI:?}" bs=1M count=100
	_DEVS_LOOP="$(losetup --find --show "${_FILE_UEFI}")"
	sfdisk "${_FILE_UEFI}" << _EOF_
		,,U,
_EOF_
	partprobe "${_DEVS_LOOP}"
	_DEVS_ARRY=()
	while read -r _DEVS_NAME DEVS_NODE
	do
		_DEVS_PART="/dev/${_DEVS_NAME}"
		if [[ ! -e "${_DEVS_PART}" ]]; then
			mknod "${_DEVS_PART}" b "${DEVS_NODE%%:*}" "${DEVS_NODE#*:}"
			_DEVS_ARRY+=("${_DEVS_PART}")
		fi
	done < <(lsblk --raw --output "NAME,MAJ:MIN" --noheadings "${_DEVS_LOOP}" | tail -n +2)
	if [[ -n "${_DEVS_PART[*]:-}" ]]; then
		rm -rf "${_DIRS_MNTP:?}"
		mkdir -p "${_DIRS_MNTP}"
		mkfs.vfat -F 32 "${_DEVS_LOOP}p1"
		mount "${_DEVS_LOOP}p1" "${_DIRS_MNTP}"
		grub-install \
			--target=x86_64-efi \
			--efi-directory="${_DIRS_MNTP}/" \
			--boot-directory="${_DIRS_MNTP}/boot/" \
			--removable
		grub-install \
			--target=i386-pc \
			--boot-directory="${_DIRS_MNTP}/boot/" \
			"${_DEVS_LOOP}"
		# --- file copy -------------------------------------------------------
		mkdir -p "${_DIRS_CDFS}/EFI/${__DIST}/"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_DIRS_CDFS}/EFI/${__DIST}/grub.cfg" || true
			search --file --set=root /.disk/info
			set prefix=($root)/boot/grub
			source $prefix/grub.cfg
_EOT_
		[[ -e "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI"  "${_DIRS_CDFS}/EFI/boot/bootx64.efi"
		[[ -e "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi"  "${_DIRS_CDFS}/EFI/boot/grubx64.efi"
		[[ -e "${_DIRS_MNTP}/EFI/BOOT/mmx64.efi"   ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/mmx64.efi"    "${_DIRS_CDFS}/EFI/boot/mmx64.efi"
		[[ -e "${_DIRS_MNTP}/boot/".               ]] && cp -a "${_DIRS_MNTP}/boot/"                 "${_DIRS_CDFS}/"
#		rm -f "${_DIRS_CDFS}/boot/grub/x86_64-efi/load.cfg"
		# --- unmount efi partition -------------------------------------------
		umount "${_DIRS_MNTP}"
		[[ -n "${_DEVS_ARRY[*]:-}" ]] && rm -f "${_DEVS_ARRY[@]:?}"
		# --- extract the mbr template ----------------------------------------
		dd if="${_FILE_UEFI}" bs=1 count=446 of="${_FILE_BIOS}" > /dev/null 2>&1
		# --- extract efi partition image -------------------------------------
		__SKIP=$(fdisk -l "${_FILE_UEFI}" | awk '/.img1/ {print $2;}' || true)
		__SIZE=$(fdisk -l "${_FILE_UEFI}" | awk '/.img1/ {print $4;}' || true)
		dd if="${_FILE_UEFI}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${_FILE_UEFI}1" > /dev/null 2>&1
		mv -f "${_FILE_UEFI}1" "${_FILE_UEFI}"
	fi
	losetup --detach "${_DEVS_LOOP}"
	# --- file copy -----------------------------------------------------------
	echo "file copy ..."
#	_FILE_INRD="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  \) | sort -Vu)"
#	_FILE_KENL="$(find "${_DIRS_TGET}"/{,boot} -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*' \) | sort -Vu)"
	_FILE_INRD="$(find "${_DIRS_BASE}"         -maxdepth 1 -type f \( -name 'initrd'  -o -name 'initrd.img'  -o -name 'initrd.img-*'  -o -name 'initrd-*'  -o -name 'initramfs' -o -name 'initramfs-*' \) | sort -Vu)"
	_FILE_KENL="$(find "${_DIRS_BASE}"         -maxdepth 1 -type f \( -name 'vmlinuz' -o -name 'vmlinuz.img' -o -name 'vmlinuz.img-*' -o -name 'vmlinuz-*'                                             \) | sort -Vu)"
#	[[ -e /usr/lib/grub/i386-pc/boot.img                     ]] && nice -n 19 cp -a /usr/lib/grub/i386-pc/boot.img                  "${_FILE_BIOS}"
#	[[ -e /usr/lib/grub/i386-pc/.                            ]] && nice -n 19 cp -a /usr/lib/grub/i386-pc/                          "${_DIRS_CDFS}/boot/grub/"
#	[[ -e /usr/lib/grub/x86_64-efi/.                         ]] && nice -n 19 cp -a /usr/lib/grub/x86_64-efi/                       "${_DIRS_CDFS}/boot/grub/"
#	[[ -e /usr/lib/grub/x86_64-efi/monolithic/grubnetx64.efi ]] && nice -n 19 cp -a /usr/lib/grub/x86_64-efi/monolithic/grubx64.efi "${_DIRS_CDFS}/EFI/boot/"
#	[[ -e /usr/lib/shim/mmx64.efi                            ]] && nice -n 19 cp -a /usr/lib/shim/mmx64.efi                         "${_DIRS_CDFS}/EFI/boot/"
	[[ -e "${_PATH_ETRI:-}"                                  ]] && nice -n 19 cp -a  "${_PATH_ETRI}"                                "${_DIRS_CDFS}/boot/grub/i386-pc/"
	[[ -e "${_FILE_UEFI:-}"                                  ]] && nice -n 19 cp -a  "${_FILE_UEFI}"                                "${_DIRS_CDFS}/boot/grub/${_FILE_UEFI##*/}"
	[[ -e "${_FILE_SQFS:-}"                                  ]] && nice -n 19 cp -a  "${_FILE_SQFS}"                                "${_DIRS_CDFS}/${_DIRS_LIVE}/"
	[[ -e "${_FILE_KENL:-}"                                  ]] && nice -n 19 cp -aL "${_FILE_KENL}"                                "${_DIRS_CDFS}/${_DIRS_LIVE}/"
	[[ -e "${_FILE_INRD:-}"                                  ]] && nice -n 19 cp -aL "${_FILE_INRD}"                                "${_DIRS_CDFS}/${_DIRS_LIVE}/"
	if [[ -e /usr/lib/ISOLINUX/isolinux.bin ]]; then
		cp -a /usr/lib/syslinux/modules/bios/* "${_DIRS_CDFS}/isolinux/"
		cp -a /usr/lib/ISOLINUX/isolinux.bin   "${_DIRS_CDFS}/isolinux/"
	fi
	if [[ -e "${_DIRS_BASE}/splash.png" ]]; then
		convert "${_DIRS_BASE}/splash.png" -resize "${_VIDE_MODE}" "${_DIRS_CDFS}"/isolinux/splash.png
	fi
	# --- create efi image file -----------------------------------------------
	rm -f "${_FILE_UEFI:?}"
	dd if=/dev/zero of="${_FILE_UEFI:?}" bs=1M count=5
	mkfs.fat -F 12 -n "ESP" "${_FILE_UEFI}"
	rm -rf "${_DIRS_MNTP:?}"
	mkdir -p "${_DIRS_MNTP}"
	mount "${_FILE_UEFI}" "${_DIRS_MNTP}"
	[[ -e "${_DIRS_CDFS}/EFI/".  ]] && cp -a "${_DIRS_CDFS}/EFI/" "${_DIRS_MNTP}/"
	umount "${_DIRS_MNTP}"
	# --- get distribution information ----------------------------------------
	_MENU_DIST="$(awk -F '=' '$1=="PRETTY_NAME" {print $2;}' "${_DIRS_BASE:?}/os-release")"
	_MENU_DIST="${_MENU_DIST#"${_MENU_DIST%%[!\"]*}"}"
	_MENU_DIST="${_MENU_DIST%"${_MENU_DIST##*[!\"]}"}"
	# --- set boot options ----------------------------------------------------
	case "${_DIST_INFO}" in
		debian-*           | \
		ubuntu-*           ) _BOOT_OPTN=("${_BOOT_DEBS[@]}");;
		fedora-*           | \
		centos-stream-*    | \
		almalinux-*        | \
		rockylinux-*       | \
		miraclelinux-*     ) _BOOT_OPTN=("${_BOOT_RHEL[@]}");;
		opensuse-leap-*    | \
		opensuse-tumbleweed) _BOOT_OPTN=();;
		*                  ) echo "not found: ${_DIST_INFO:-}"; exit 1;;
	esac
	# --- create isolinux.cfg -------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_MENU_SLNX}" || true
		path

		default vesamenu.c32

		menu resolution ${_VIDE_MODE//x/ }
		menu title Boot Menu: ${_MENU_DIST:-}
		menu background splash.png
		menu color title        * #FFFFFFFF *
		menu color border       * #00000000 #00000000 none
		menu color sel          * #ffffffff #76a1d0ff *
		menu color hotsel       1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg       * #ffffffff #00000000 *
		menu color help         37;40 #ffdddd00 #00000000 none
		menu vshift 8
		menu rows 12
		menu helpmsgrow 14
		menu cmdlinerow 16
		menu timeoutrow 16
		menu tabmsgrow 18
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		label live
		  menu label ^${_MENU_DIST//%20/ }
		  menu default
		  linux  /${_DIRS_LIVE}/${_FILE_KENL##*/}
		  initrd /${_DIRS_LIVE}/${_FILE_INRD##*/}
		  append ${_BOOT_OPTN[@]}

		label poweroff
		  menu label ^System shutdown
		  com32 poweroff.c32
		
		label reboot
		  menu label ^System restart
		  com32 reboot.c32

		prompt 0
		timeout 50
_EOT_
	# --- create theme.cfg ----------------------------------------------------
#	: > "${_MENU_FTHM%.*}.cfg"
	# --- create theme.txt ----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_MENU_FTHM}" || true
		desktop-image: "/isolinux/splash.png"
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${_MENU_DIST:-}"
		message-font: "Unifont Regular 16"
		terminal-font: "Unifont Regular 16"
		terminal-border: "0"

		#help bar at the bottom
		+ label {
		  top = 100%-50
		  left = 0
		  width = 100%
		  height = 20
		  text = "@KEYMAP_SHORT@"
		  align = "center"
		  color = "#ffffff"
		  font = "Unifont Regular 16"
		}

		#boot menu
		+ boot_menu {
		  left = 10%
		  width = 80%
		  top = 20%
		  height = 50%-80
		  item_color = "#a8a8a8"
		  item_font = "Unifont Regular 16"
		  selected_item_color= "#ffffff"
		  selected_item_font = "Unifont Regular 16"
		  item_height = 16
		  item_padding = 0
		  item_spacing = 4
		  icon_width = 0
		  icon_heigh = 0
		  item_icon_space = 0
		}

		#progress bar
		+ progress_bar {
		  id = "__timeout__"
		  left = 15%
		  top = 100%-80
		  height = 16
		  width = 70%
		  font = "Unifont Regular 16"
		  text_color = "#000000"
		  fg_color = "#ffffff"
		  bg_color = "#a8a8a8"
		  border_color = "#ffffff"
		  text = "@TIMEOUT_NOTIFICATION_LONG@"
		}
_EOT_
	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_MENU_GRUB}" || true
		if [ x\$feature_default_font_path = xy ] ; then
		  font=unicode
		else
		  font=\$prefix/font.pf2
		fi

		if loadfont \$font ; then
		  set gfxpayload=keep
		  set gfxmode=${_VIDE_MODE}
		  insmod efi_gop
		  insmod efi_uga
		  insmod video_bochs
		  insmod video_cirrus
		  insmod all_video
		  load_video
		  insmod gfxterm
		  insmod png
		  terminal_output gfxterm
		fi

		if background_image /isolinux/splash.png 2> /dev/null; then
		  set color_normal=light-gray/black
		  set color_highlight=white/black
		elif background_image /splash.png 2> /dev/null; then
		  set color_normal=light-gray/black
		  set color_highlight=white/black
		else
		  set menu_color_normal=cyan/blue
		  set menu_color_highlight=white/blue
		fi

		insmod play
		play 960 440 1 0 4 440 1

		set default=0
		set timeout=5
		set timeout_style=menu
		set theme=/boot/grub/theme.txt
		export theme

		insmod net
		insmod http
		insmod progress
		insmod gzio
		insmod part_gpt
		insmod ext2
		insmod chain

		menuentry 'Live mode' {
		  echo '${_MENU_DIST:-} ...'
		  set gfxpayload=keep
		  set background_color=black
		  set options="${_BOOT_OPTN[@]}"
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading linux ...'
		  linux  /${_DIRS_LIVE}/${_FILE_KENL##*/} \${options}
		  echo 'Loading initrd ...'
		  initrd /${_DIRS_LIVE}/${_FILE_INRD##*/}
		}

		menuentry 'System shutdown' {
		  echo System shutting down ...
		  halt
		}

		menuentry 'System restart' {
		  echo System rebooting ...
		  reboot
		}

		if [ x\$grub_platform = xefi ]; then
		  menuentry 'Boot from next volume' {
		    exit 1
		  }

		  menuentry 'UEFI Firmware Settings' {
		    fwsetup
		  }
		fi
_EOT_
	# --- create iso image ----------------------------------------------------
	echo "create iso image file ..."
	pushd "${_DIRS_CDFS:?}" > /dev/null || exit
		if ! nice -n 19 xorrisofs "${_OPTN_XORR[@]}" -output "${_FILE_WORK}" .; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${_FILE_ISOS##*/}" 1>&2
		else
			if ! cp --preserve=timestamps "${_FILE_WORK}" "${_FILE_ISOS}"; then
				printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${_FILE_ISOS##*/}" 1>&2
			else
				ls -lh "${_FILE_ISOS}"
				printf "\033[m\033[42m%20.20s: %s\033[m\n" "complete" "${_FILE_ISOS}" 1>&2
			fi
		fi
		rm -f "${_FILE_WORK:?}"
	popd > /dev/null || exit
	umount "${_DIRS_OLAY:?}/merged"
	rm -rf "${_DIRS_TEMP:?}" "${_DIRS_OLAY:?}"
