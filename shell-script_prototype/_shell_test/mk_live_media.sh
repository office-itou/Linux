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

function fnCreate_UEFI_image() {
	# === dummy file ==========================================================
	# --- create disk image ---------------------------------------------------
	dd if=/dev/zero of="${_FILE_UEFI}" bs=1M count=100
	# --- format efi partition ------------------------------------------------
	mkfs.vfat -F 32 "${_FILE_UEFI}"
	# --- mount efi partition -------------------------------------------------
	mount "${_FILE_UEFI}" "${_DIRS_MNTP}"
	# --- install grub module -------------------------------------------------
	grub-install \
		--target=x86_64-efi \
		--efi-directory="${_DIRS_MNTP}" \
		--bootloader-id=boot \
		--boot-directory="${_DIRS_TEMP}" \
		--removable
	# --- file copy -----------------------------------------------------------
	cp -a "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI"  "${_DIRS_TEMP}/bootx64.efi"
	cp -a "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi"  "${_DIRS_TEMP}/grubx64.efi"
	# --- unmount efi partition -----------------------------------------------
	umount "${_DIRS_MNTP}"

	# === real file ===========================================================
	# --- create disk image ---------------------------------------------------
	dd if=/dev/zero of="${_FILE_UEFI}" bs=1M count=100
	# --- format efi partition ------------------------------------------------
	mkfs.vfat -F 32 "${_FILE_UEFI}"
	# --- mount efi partition -------------------------------------------------
	mount "${_FILE_UEFI}" "${_DIRS_MNTP}"
	# --- create --------------------------------------------------------------
	mkdir -p "${_DIRS_MNTP}/"{EFI/boot,boot/grub}
	cp -a "${_DIRS_TEMP}/"{bootx64.efi,grubx64.efi} "${_DIRS_MNTP}/EFI/boot/"
	cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_MNTP}/boot/grub/grub.cfg"
		search --set=root --file /.disk/info
		set prefix=($root)'/boot/grub'
		configfile $prefix/grub.cfg
_EOT_
	# --- unmount efi partition -----------------------------------------------
	umount "${_DIRS_MNTP}"
}

function fnCreate_ISOLINUX_menu() {
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
	nice -n 19 cp -a /usr/lib/grub/i386-pc/*     "${_DIRS_CDFS}/boot/grub/i386-pc/"
	nice -n 19 cp -a /usr/lib/grub/x86_64-efi/*  "${_DIRS_CDFS}/boot/grub/x86_64-efi/"
	nice -n 19 cp -a /usr/share/grub/unicode.pf2 "${_DIRS_CDFS}/boot/grub/"
	if [[ -z "${_FLAG_ILNK}" ]]; then
		nice -n 19 cp -a "/srv/user/share/imgs/ubuntu-live-24.10/boot/grub/i386-pc/eltorito.img" "${_DIRS_CDFS}/boot/grub/i386-pc/"
	fi
	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_DIRS_CDFS}/boot/grub/grub.cfg"
		set timeout=5
		set default=0
		set gfxmode=auto
		set lang=ja_JP
		
		if [ x\$feature_default_font_path = xy ] ; then
		 	font=unicode
		else
		 	font=\$prefix/font.pf2
		fi
		
		if loadfont \$font ; then
		 	set gfxmode=1024x768
		 	set gfxpayload=keep
		 	insmod efi_gop
		 	insmod efi_uga
		 	insmod video_bochs
		 	insmod video_cirrus
		 	insmod gfxterm
		 	insmod png
		 	terminal_output gfxterm
		fi
		
		if background_image /isolinux/splash.png; then
		 	set color_normal=light-gray/black
		 	set color_highlight=white/black
		elif background_image /splash.png; then
		 	set color_normal=light-gray/black
		 	set color_highlight=white/black
		else
		 	set menu_color_normal=cyan/blue
		 	set menu_color_highlight=white/blue
		fi
		
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
	nice -n 19 cp -a "${_FILE_MDIA}"             "${_FILE_SQFS}"
	nice -n 19 cp -a "${_FILE_MDIA%/*}/manifest" "${_FILE_SQFS%.*}.packages"
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

	# === create isolinux =====================================================
	if [[ -n "${_FLAG_ILNK}" ]]; then
		fnCreate_ISOLINUX_menu
	fi
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
#	_OPTN_XORR=(\
#		-quiet -rational-rock \
#		${_FILE_VLID:+-volid "${_FILE_VLID}"}           \
#		-joliet -joliet-long \
#		-cache-inodes \
#		${_FILE_HBRD:+-isohybrid-mbr "${_FILE_HBRD}"} \
#		${_FILE_ETRI:+-eltorito-boot "${_FILE_ETRI}"}   \
#		${_FILE_BCAT:+-eltorito-catalog "${_FILE_BCAT}"} \
#		-boot-load-size 4 -boot-info-table \
#		-no-emul-boot \
#		-eltorito-alt-boot ${_FILE_UEFI:+-e "boot/grub/${_FILE_UEFI##*/}"} \
#		-no-emul-boot \
#		-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
#	)
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

	declare -r    _PROG_PATH="$0"
	declare -r -a _PROG_PARM=("${@:-}")
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP
	declare -r    _DIRS_WORK="/srv/user/private/live"
	declare -r    _DIRS_MNTP="${_DIRS_TEMP}/mnt"
	declare -r    _FILE_UEFI="${_DIRS_TEMP}/efi.img"
	declare -r    _FILE_MDIA="${_DIRS_WORK}/live-debian/filesystem.squashfs"
	declare -r    _DIRS_CDFS="${_DIRS_TEMP}/cdfs"
	declare -r    _FILE_SQFS="${_DIRS_CDFS}/live/filesystem.squashfs"
	declare -r    _FILE_CONF="/srv/user/share/conf/_template/live-debian.yaml"
	declare -r -a _BOOT_OPTN=(\
		"live" \
		"components" \
		"quiet" \
		"splash" \
		"overlay-size=90%" \
		"hooks=medium" \
		"xorg-resolution=1680x1050" \
		"utc=yes" \
		"locales=ja_JP.UTF-8" \
		"timezone=Asia/Tokyo" \
		"keyboard-model=pc105" \
		"keyboard-layouts=jp" \
		"keyboard-variants=OADG109A" \
)

	declare -r    _FILE_VLID="LIVE-MEDIA"
	declare -r    _FILE_ISOS="/srv/hgfs/linux/live-media.iso"
	declare -r    _FILE_WORK="${_DIRS_TEMP}/${_FILE_ISOS##*/}.work"
	declare -r    _FLAG_ILNK="true"

	declare -r    _FILE_BIOS="boot/grub/i386-pc/boot.img"

	if [[ -n "${_FLAG_ILNK}" ]]; then
		declare -r    _FILE_ETRI="isolinux/isolinux.bin"
		declare -r    _FILE_BCAT="isolinux/boot.catalog"
	else
		declare -r    _FILE_BCAT="boot/grub/boot.catalog"
		declare -r    _FILE_ETRI="boot/grub/i386-pc/eltorito.img"
	fi

	mkdir -p "${_DIRS_MNTP}"

	if [[ ! -e "${_FILE_MDIA}" ]]; then
		rm -rf "${_DIRS_WORK:?}/live-debian/"
		bdebstrap \
			--output-base-dir "${_DIRS_WORK:?}" \
			--config "${_FILE_CONF:?}" \
			--customize-hook "mkdir -p \"\$1/my-script\"" \
			--customize-hook "cp -a \"/srv/user/share/conf/script/autoinst_cmd_late.sh\" \"\$1/my-script\"" \
			--customize-hook "chmod +x \"\$1/my-script/autoinst_cmd_late.sh\"" \
			--customize-hook "chroot \"\$1\" \"/my-script/autoinst_cmd_late.sh\"" \
			--customize-hook "rm -rf \"\$1/my-script\"" \
			--customize-hook "rm -rf \"\$1/etc/NetworkManager/system-connections/*\"" \
			--suite bookworm
	fi

	ls -lh "${_DIRS_WORK:?}/live-debian/"

	fnCreate_UEFI_image
	fnCreate_CDFS_image
	fnCreate_ISO_file

	ls -lh "${_FILE_ISOS}"

	rm -rf "${_DIRS_TEMP:?}"

	exit 0
