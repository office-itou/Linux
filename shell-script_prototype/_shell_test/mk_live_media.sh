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
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	declare -r -a _BOOT_OPTN=(\
		"live" \
		"components" \
		"overlay-size=90%" \
		"hooks=medium" \
		"xorg-resolution=1680x1050" \
		"utc=yes" \
		"locales=ja_JP.UTF-8" \
		"timezone=Asia/Tokyo" \
		"keyboard-model=pc105" \
		"keyboard-layouts=jp" \
		"keyboard-variants=OADG109A" \
		"---" \
		"quiet" \
		"splash" \
	)

function fnCreate_squashfs() {
	if [[ -e "${_FILE_MDIA}" ]]; then
		return
	fi
	if ! bdebstrap \
		--output-base-dir "${_DIRS_BASE:?}" \
		--tmpdir "${_DIRS_WORK}" \
		--config "${_FILE_CONF:?}" \
		--name "${_DIRS_WORK##*/}" \
		--customize-hook "mkdir -p \"\$1/my-script\"" \
		--customize-hook "cp -a \"/srv/user/share/conf/script/autoinst_cmd_late.sh\" \"\$1/my-script\"" \
		--customize-hook "chmod +x \"\$1/my-script/autoinst_cmd_late.sh\"" \
		--customize-hook "chroot \"\$1\" \"/my-script/autoinst_cmd_late.sh\"" \
		--customize-hook "rm -rf \"\$1/my-script\"" \
		--customize-hook "rm -rf \"\$1/etc/NetworkManager/system-connections/*\"" \
		--suite "${_TGET_SUIT}"; then
			rm -f "${_FILE_MDIA:?}" "${_FILE_MDIA%/*}/config.yaml"
			exit $?
	fi
	ls -lh "${_DIRS_WORK:?}/live-${_TGET_DIST}/"
}

function fnCreate_UEFI_image() {
	# === dummy file ==========================================================
	# --- create disk image ---------------------------------------------------
	dd if=/dev/zero of="${_FILE_UEFI}" bs=1M count=100
	# --- create loop device --------------------------------------------------
	_DEVS_LOOP="$(losetup --find --show "${_FILE_UEFI}")"
	# --- create partition ----------------------------------------------------
	sfdisk "${_DEVS_LOOP}" << _EOF_
		,,U,*
_EOF_
	# --- format efi partition ------------------------------------------------
	sleep 1
	partprobe "${_DEVS_LOOP}"
	mkfs.vfat -F 32 "${_DEVS_LOOP}p1"
	# --- mount efi partition -------------------------------------------------
	mount "${_DEVS_LOOP}p1" "${_DIRS_MNTP}"
	# --- install grub module -------------------------------------------------
	grub-install \
		--target=x86_64-efi \
		--efi-directory="${_DIRS_MNTP}" \
		--bootloader-id=boot \
		--boot-directory="${_DIRS_WORK}" \
		--removable
	grub-install \
		--target=i386-pc \
		--boot-directory="${_DIRS_WORK}" \
		"${_DEVS_LOOP}"
	# --- file copy -----------------------------------------------------------
	[[ -e "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI"  "${_DIRS_WORK}/bootx64.efi"
	[[ -e "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi"  "${_DIRS_WORK}/grubx64.efi"
	# --- unmount efi partition -----------------------------------------------
	umount "${_DIRS_MNTP}"
	# --- detach loop device --------------------------------------------------
	losetup --detach "${_DEVS_LOOP}"
	# === real file ===========================================================
	# --- create disk image ---------------------------------------------------
	dd if=/dev/zero of="${_FILE_UEFI}" bs=1M count=100
	# --- format efi partition ------------------------------------------------
	mkfs.vfat -F 32 "${_FILE_UEFI}"
	# --- mount efi partition -------------------------------------------------
	mount "${_FILE_UEFI}" "${_DIRS_MNTP}"
	# --- create --------------------------------------------------------------
	mkdir -p "${_DIRS_MNTP}/"{EFI/boot,boot/grub}
	[[ -e "${_DIRS_WORK}/bootx64.efi" ]] && cp -a "${_DIRS_WORK}/bootx64.efi" "${_DIRS_MNTP}/EFI/boot/"
	[[ -e "${_DIRS_WORK}/grubx64.efi" ]] && cp -a "${_DIRS_WORK}/grubx64.efi" "${_DIRS_MNTP}/EFI/boot/"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_MNTP}/boot/grub/grub.cfg"
		search --set=root --file /.disk/info
		set prefix=($root)'/boot/grub'
		configfile $prefix/grub.cfg
_EOT_
	# --- unmount efi partition -----------------------------------------------
	umount "${_DIRS_MNTP}"
}

function fnCreate_ISOLINUX_menu() {
	if [[ -e /usr/lib/grub/i386-pc/eltorito.img ]]; then
		return
	fi
	# ---- copy isolinux module -------------------------------------------
	nice -n 19 cp -a /usr/lib/syslinux/modules/bios/* "${_DIRS_CDFS}/isolinux"
	nice -n 19 cp -a /usr/lib/ISOLINUX/isolinux.bin   "${_DIRS_CDFS}/isolinux"
	# --- create isolinux.cfg ---------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_CDFS}/isolinux/isolinux.cfg"
		menu resolution 1024 768
		menu hshift 12
		menu width 100
		
		menu title Boot menu

		menu background		splash.png
		menu color title	* #FFFFFFFF *
		menu color border	* #00000000 #00000000 none
		menu color sel		* #ffffffff #76a1d0ff *
		menu color hotsel	1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg	* #ffffffff #00000000 *
		menu color help		37;40 #ffdddd00 #00000000 none
		menu vshift 12
		menu rows 10
		menu helpmsgrow 15
		# The command line must be at least one line from the bottom.
		menu cmdlinerow 16
		menu timeoutrow 16
		menu tabmsgrow 18
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		label live-media
		  menu label ^live-media
		  menu default
		  linux /live/vmlinuz
		  initrd /live/initrd
		  append boot=${_BOOT_OPTN}
		menu begin utilities
		  menu label ^Utilities
		  menu title Utilities
		  label hdt
		    menu label ^Hardware Detection Tool (HDT)
		    com32 hdt.c32
		  label poweroff
		    menu label ^System shutdown
		    com32 poweroff.c32
		  label reboot
		    menu label ^System restart
		    com32 reboot.c32
		  label mainmenu
		    menu label ^Back..
		    menu exit
		menu end
		
		menu clear

		default vesamenu.c32
		prompt 0
		timeout 50
_EOT_
}

function fnCreate_GRUB_menu() {
	# --- copy grub module ----------------------------------------------------
	nice -n 19 cp -a "${_DIRS_WORK}/grub/"       "${_DIRS_CDFS}/boot/"      
	if [[ -e /usr/lib/grub/i386-pc/eltorito.img ]]; then
		nice -n 19 cp -a "/usr/lib/grub/i386-pc/eltorito.img" "${_DIRS_CDFS}/boot/grub/i386-pc/"
	fi
	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_CDFS}/boot/grub/grub.cfg"
		set timeout=5
		set default=0
		set gfxmode=auto
		set lang=ja_JP
		
		if [ x\${feature_default_font_path} = xy ] ; then
		  font=unicode
		else
		  font=\${prefix}/font.pf2
		fi
		
		set gfxmode=1024x768
		set gfxpayload=keep
		set menu_color_normal=cyan/blue
		set menu_color_highlight=white/blue
		
		insmod play
		play 960 440 1 0 4 440 1
		#set theme=/boot/grub/theme/1
		
		menuentry "live-media" {
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  linux  /live/vmlinuz boot=${_BOOT_OPTN[@]}
		  initrd /live/initrd
		}
		menuentry "System shutdown" {
		  echo "System shutting down ..."
		  halt
		}
		menuentry "System restart" {
		  echo "System rebooting ..."
		  reboot
		}
_EOT_
}

function fnCreate_CDFS_image() {
	# ---- create .disk/info --------------------------------------------------
	rm -rf "${_DIRS_CDFS:?}"
	mkdir -p "${_DIRS_CDFS}/"{.disk,EFI/boot,boot/grub/{live-theme,i386-pc,x86_64-efi},isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
	: > "${_DIRS_CDFS}/.disk/info"
	# ---- copy efi image -----------------------------------------------------
	nice -n 19 cp -a "${_FILE_UEFI}"             "${_DIRS_CDFS}/boot/grub/"
	# ---- copy filesystem ----------------------------------------------------
	[[ -e "${_FILE_MDIA}"             ]] && nice -n 19 cp -a "${_FILE_MDIA}"             "${_FILE_SQFS}"
	[[ -e "${_FILE_MDIA%/*}/manifest" ]] && nice -n 19 cp -a "${_FILE_MDIA%/*}/manifest" "${_FILE_SQFS%.*}.packages"
	# --- mount squashfs ------------------------------------------------------
	mount -r -t squashfs "${_FILE_SQFS}" "${_DIRS_MNTP}"
	# --- copy vmlinuz/initrd -------------------------------------------------
	find "${_DIRS_MNTP}" "${_DIRS_MNTP}/boot/" -maxdepth 1 \( -name 'vmlinuz' -o -name linux        \) | while read -r _FILE_PATH
	do
		cp -a "$(realpath "${_FILE_PATH}" || true)" "${_DIRS_CDFS}/live/vmlinuz"
	done
	find "${_DIRS_MNTP}" "${_DIRS_MNTP}/boot/" -maxdepth 1 \( -name 'initrd'  -o -name 'initrd.img' \) | while read -r _FILE_PATH
	do
		cp -a "$(realpath "${_FILE_PATH}" || true)" "${_DIRS_CDFS}/live/initrd"
	done
	# --- umount squashfs -----------------------------------------------------
	umount "${_DIRS_MNTP}"
	# === create isolinux / grub menu =========================================
	fnCreate_ISOLINUX_menu
	fnCreate_GRUB_menu
}

function fnCreate_ISO_file() {
	# --- create iso image file -------------------------------------------
	_OPTN_XORR=(\
		-quiet -rational-rock \
		${_FILE_VLID:+-volid "${_FILE_VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		${_FILE_BIOS:+--grub2-mbr "${_FILE_BIOS}"} \
		--mbr-force-bootable \
		${_FILE_UEFI:+-append_partition 2 0xEF "boot/grub/${_FILE_UEFI##*/}"} \
		-appended_part_as_gpt \
		${_FILE_BCAT:+-eltorito-catalog "${_FILE_BCAT}"} \
		${_FILE_ETRI:+-eltorito-boot "${_FILE_ETRI}"} \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot
	)
	pushd "${_DIRS_CDFS:?}" > /dev/null || exit
	if ! nice -n 19 xorrisofs "${_OPTN_XORR[@]}" -output "${_FILE_WORK}" .; then
		printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [xorriso]" "${_FILE_ISOS##*/}" 1>&2
	else
		if ! cp --preserve=timestamps "${_FILE_WORK}" "${_FILE_ISOS}"; then
			printf "\033[m\033[41m%20.20s: %s\033[m\n" "error [cp]" "${_FILE_ISOS##*/}" 1>&2
		else
			printf "\033[m\033[42m%20.20s: %s\033[m\n" "complete" "${_FILE_ISOS}" 1>&2
		fi
	fi
	rm -f "${_FILE_WORK:?}"
	popd > /dev/null || exit
}

	declare -r    _FILE_BIOS="boot/grub/i386-pc/boot.img"
	if [[ -e /usr/lib/grub/i386-pc/eltorito.img ]]; then
		declare -r    _FILE_BCAT="boot/grub/boot.catalog"
		declare -r    _FILE_ETRI="boot/grub/i386-pc/eltorito.img"
	else
		declare -r    _FILE_BCAT="isolinux/boot.catalog"
		declare -r    _FILE_ETRI="isolinux/isolinux.bin"
	fi

#	declare -r    _TGET_DIST="debian"
	declare -r    _TGET_DIST="ubuntu"
#	declare -r    _TGET_SUIT="bookworm"
#	declare -r    _TGET_SUIT="jammy"	# ubuntu-22.04
	declare -r    _TGET_SUIT="noble"	# ubuntu-24.04
#	declare -r    _TGET_SUIT="oracular"	# ubuntu-24.10
#	declare -r    _TGET_SUIT="plucky"	# ubuntu-25.04
#	declare -r    _TGET_SUIT="questing"	# ubuntu-25.10

	declare -r    _DIRS_BASE="/srv/user/private/live"
	declare -r    _DIRS_WORK="${_DIRS_BASE}/${_TGET_DIST}-${_TGET_SUIT}"
	declare -r    _DIRS_MNTP="${_DIRS_WORK}/mnt"
	declare -r    _FILE_UEFI="${_DIRS_WORK}/efi.img"
	declare -r    _DIRS_CDFS="${_DIRS_WORK}/cdfs"
	declare -r    _FILE_SQFS="${_DIRS_CDFS}/live/filesystem.squashfs"

	declare -r    _FILE_CONF="/srv/user/share/conf/_template/live-${_TGET_DIST}.yaml"
	declare -r    _FILE_ISOS="/srv/user/share/rmak/live-${_TGET_DIST}-${_TGET_SUIT}.iso"
	declare -r    _FILE_WORK="${_DIRS_WORK}/${_FILE_ISOS##*/}.work"
	declare -r    _FILE_MDIA="${_DIRS_WORK}/filesystem.squashfs"
	declare -r    _FILE_VLID="LIVE-MEDIA"

#	mkdir -p "${_DIRS_MNTP}"

#	rm -rf "${_FILE_MDIA:?}"

	fnCreate_squashfs
	fnCreate_UEFI_image
	fnCreate_CDFS_image
	fnCreate_ISO_file

	ls -lh "${_FILE_ISOS}"

	rm -rf "${_DIRS_TEMP:?}"

	exit 0