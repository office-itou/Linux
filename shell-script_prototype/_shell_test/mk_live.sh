#!/bin/bash

	set -eu

	declare -r    _PROG_PATH="$0"
#	declare -r -a _PROG_PARM=("${@:-}")
#	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
	declare -r    _PROG_PROC="${_PROG_NAME}.$$"
	              _DIRS_TEMP="$(mktemp -qtd "${_PROG_PROC}.XXXXXX")"
	readonly      _DIRS_TEMP

	declare       _DIRS_BASE="${1:?}"
	              _DIRS_BASE="$(realpath "${_DIRS_BASE%/}")"
	readonly      _DIRS_BASE
	declare -r    _FILE_CONF="${_DIRS_BASE:?}/mkosi.conf"
	declare -r    _FILE_SQFS="${_DIRS_BASE:?}/filesystem.squashfs"

	declare -r    _DIRS_TGET="${_DIRS_BASE:?}/image"
	declare -r    _FILE_INRD="${_DIRS_TGET}/initrd"
	declare -r    _FILE_KENL="${_DIRS_TGET}/vmlinuz"

	declare       _TGET_DIST=""
	              _TGET_DIST="$(sed -ne '/^\[Distribution\]$/,/\(^$\|^\[.*\]$\)/ {/^Distribution=/ s/^.*=//p}' "${_FILE_CONF:?}")"
	readonly      _TGET_DIST
	declare       _TGET_SUIT=""
	              _TGET_SUIT="$(sed -ne '/^\[Distribution\]$/,/\(^$\|^\[.*\]$\)/ {/^Release=/ s/^.*=//p}'      "${_FILE_CONF:?}")"
	readonly      _TGET_SUIT

	declare -r    _FILE_ISOS="/srv/user/share/rmak/live-${_TGET_DIST}-${_TGET_SUIT}.iso"
	declare -r    _FILE_VLID="LIVE-MEDIA"

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

	declare       _FLAG_WORK=""

	declare -r -a _BOOT_OPTN=(\
		"boot=live" \
		"ip=dhcp" \
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

	declare -r -a _OPTN_XORR=(\
		-quiet -rational-rock \
		${_FILE_VLID:+-volid "${_FILE_VLID}"} \
		-joliet -joliet-long \
		-full-iso9660-filenames -iso-level 3 \
		-partition_offset 16 \
		${_FILE_BIOS:+--grub2-mbr "${_FILE_BIOS}"} \
		--mbr-force-bootable \
		${_FILE_UEFI:+-append_partition 2 0xEF "${_FILE_UEFI}.img1"} \
		-appended_part_as_gpt \
		${_FILE_BCAT:+-eltorito-catalog "${_FILE_BCAT}"} \
		${_FILE_ETRI:+-eltorito-boot "${_FILE_ETRI}"} \
		-no-emul-boot \
		-boot-load-size 4 -boot-info-table \
		--grub2-boot-info \
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
		-no-emul-boot
	)

# === mkosi ===================================================================
	if [[ "${2:-}" = "-f" ]] || [[ "${2:-}" = "--force" ]] || [[ ! -e "${_DIRS_TGET:?}/." ]]; then
		rm -rf "${_DIRS_TGET:?}"
		if ! mkosi --directory "${_DIRS_TGET%/*}"; then
			exit "$?"
		fi
		if [[ -e /srv/user/share/conf/script/autoinst_cmd_late.sh ]]; then
			mount --rbind /dev/    "${_DIRS_TGET}/dev/"  && mount --make-rslave "${_DIRS_TGET}/dev/"
			mount -t proc /proc/   "${_DIRS_TGET}/proc/"
			mount --rbind /sys/    "${_DIRS_TGET}/sys/"  && mount --make-rslave "${_DIRS_TGET}/sys/"
			mount  --bind /run/    "${_DIRS_TGET}/run/"
			mount --rbind /tmp/    "${_DIRS_TGET}/tmp/"  && mount --make-rslave "${_DIRS_TGET}/tmp/"
			_FLAG_WORK=""
			if [[ -L "${_DIRS_TGET}/etc/resolv.conf" ]] && [[ ! -e "${_DIRS_TGET}/run/systemd/resolve/stub-resolv.conf" ]]; then
				_FLAG_WORK="true"
				mkdir -p "${_DIRS_TGET}/run/systemd/resolve/"
				cp -a /etc/resolv.conf "${_DIRS_TGET}/run/systemd/resolve/stub-resolv.conf"
			fi
			cp -a /srv/user/share/conf/script/autoinst_cmd_late.sh "${_DIRS_TGET}/tmp/"
			chmod 755 "${_DIRS_TGET}/tmp/autoinst_cmd_late.sh"
			chroot "${_DIRS_TGET}" /tmp/autoinst_cmd_late.sh debug
			rm -f "${_DIRS_TGET}/tmp/autoinst_cmd_late.sh"
			if [[ -n "${_FLAG_WORK:-}" ]]; then
				rm -rf "${_DIRS_TGET}/run/systemd/resolve/"
			fi
			umount --recursive     "${_DIRS_TGET}/tmp/"
			umount                 "${_DIRS_TGET}/run/"
			umount --recursive     "${_DIRS_TGET}/sys/"
			umount                 "${_DIRS_TGET}/proc/"
			umount --recursive     "${_DIRS_TGET}/dev/"
		fi
	fi

# === filesystem ==============================================================
	if [[ "${2:-}" = "-f" ]] || [[ "${2:-}" = "--force" ]] || [[ ! -e "${_FILE_SQFS:?}" ]]; then
		rm -f "${_FILE_SQFS:?}"
		if ! mksquashfs "${_DIRS_TGET:?}" "${_FILE_SQFS:?}"; then
			exit "$?"
		fi
	fi

# === iso image ===============================================================
	rm -rf "${_DIRS_CDFS:?}"
#	mkdir -p "${_DIRS_CDFS}/"{.disk,EFI/boot,boot/grub/{live-theme,i386-pc,x86_64-efi},isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
	mkdir -p "${_DIRS_CDFS}/"{.disk,EFI/boot,isolinux,live/{boot,config.conf.d,config-hooks,config-preseed}}
	: > "${_DIRS_CDFS}/.disk/info"

	dd if=/dev/zero of="${_FILE_UEFI}" bs=1M count=100
	_DEVS_LOOP="$(losetup --find --show "${_FILE_UEFI}")"
	sfdisk "${_DEVS_LOOP}" << _EOF_
		,,U,
_EOF_
	sleep 1
	partprobe "${_DEVS_LOOP}"
	sleep 1
	fdisk -l "${_DEVS_LOOP}"
	mkfs.vfat -F 32 "${_DEVS_LOOP}p1"
	rm -rf "${_DIRS_MNTP:?}"
	mkdir -p "${_DIRS_MNTP}"
	mount "${_DEVS_LOOP}p1" "${_DIRS_MNTP}"
	grub-install \
		--target=x86_64-efi \
		--efi-directory="${_DIRS_MNTP}" \
		--bootloader-id=boot \
		--boot-directory="${_DIRS_CDFS}/boot/" \
		--removable
	grub-install \
		--target=i386-pc \
		--boot-directory="${_DIRS_CDFS}/boot/" \
		"${_DEVS_LOOP}"
	# --- file copy -----------------------------------------------------------
	[[ -e "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/BOOTX64.EFI"  "${_DIRS_CDFS}/EFI/boot/bootx64.efi"
	[[ -e "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi" ]] && cp -a "${_DIRS_MNTP}/EFI/BOOT/grubx64.efi"  "${_DIRS_CDFS}/EFI/boot/grubx64.efi"
	# --- unmount efi partition -----------------------------------------------
	umount "${_DIRS_MNTP}"
	losetup --detach "${_DEVS_LOOP}"
	# --- extract the mbr template --------------------------------------------
	dd if="${_FILE_UEFI}" bs=1 count=446 of="${_FILE_BIOS}" > /dev/null 2>&1
	# --- extract efi partition image -----------------------------------------
	__SKIP=$(fdisk -l "${_FILE_UEFI}" | awk '/.img1/ {print $2;}' || true)
	__SIZE=$(fdisk -l "${_FILE_UEFI}" | awk '/.img1/ {print $4;}' || true)
	dd if="${_FILE_UEFI}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${_FILE_UEFI}.img1" > /dev/null 2>&1
	# --- file copy -----------------------------------------------------------
	[[ -e "${_PATH_ETRI:-}"                    ]] && nice -n 19 cp -a  "${_PATH_ETRI}"            "${_DIRS_CDFS}/boot/grub/i386-pc/"
	[[ -e "${_FILE_UEFI:-}"                    ]] && nice -n 19 cp -a  "${_FILE_UEFI}"            "${_DIRS_CDFS}/boot/grub/"
	[[ -e "${_FILE_SQFS:-}"                    ]] && nice -n 19 cp -a  "${_FILE_SQFS}"            "${_DIRS_CDFS}/live/"
	[[ -e "${_FILE_KENL:-}"                    ]] && nice -n 19 cp -aL "${_FILE_KENL}"            "${_DIRS_CDFS}/live/vmlinuz"
	[[ -e "${_FILE_INRD:-}"                    ]] && nice -n 19 cp -aL "${_FILE_INRD}"            "${_DIRS_CDFS}/live/initrd"
	[[ -e "${_FILE_INRD:-}.img"                ]] && nice -n 19 cp -aL "${_FILE_INRD}.img"        "${_DIRS_CDFS}/live/initrd"
	if [[ -e /usr/lib/ISOLINUX/isolinux.bin ]]; then
		cp -a /usr/lib/syslinux/modules/bios/* "${_DIRS_CDFS}/isolinux/"
		cp -a /usr/lib/ISOLINUX/isolinux.bin   "${_DIRS_CDFS}/isolinux/"
	fi
	# --- get distribution information ----------------------------------------
	_MENU_DIST="$(awk -F '=' '$1=="PRETTY_NAME" {print $2;}' "${_DIRS_BASE:?}/image/etc/os-release")"
	_MENU_DIST="${_MENU_DIST#"${_MENU_DIST%%[!\"]*}"}"
	_MENU_DIST="${_MENU_DIST%"${_MENU_DIST##*[!\"]}"}"
	# --- create isolinux.cfg -------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_MENU_SLNX}" || true
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

		label ${_MENU_DIST//%20/_}
		  menu label ^${_MENU_DIST//%20/ }]
		  menu default
		  linux /live/vmlinuz
		  initrd /live/initrd
		  append boot=${_BOOT_OPTN[@]}

		label hdt
		  menu label ^Hardware Detection Tool (HDT)
		  com32 hdt.c32
		
		label poweroff
		  menu label ^System shutdown
		  com32 poweroff.c32
		
		label reboot
		  menu label ^System restart
		  com32 reboot.c32

		menu clear

		default vesamenu.c32
		prompt 0
		timeout 50
_EOT_
	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_MENU_FTHM}" || true
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
		  if [ x\$feature_all_video_module = xy ]; then
		    insmod all_video
		  else
		    insmod efi_gop
		    insmod efi_uga
		    insmod video_bochs
		    insmod video_cirrus
		  fi
		  insmod gfxterm
		  insmod png
		  terminal_output gfxterm
		fi

		set gfxmode=1024x768,auto
		set default=0
		set timeout=5
		set timeout_style=menu
		set theme=${_MENU_FTHM:+"${_MENU_FTHM#"${_DIRS_CDFS}"}"}
		export theme

		set menu_color_normal="cyan/blue"
		set menu_color_highlight="white/blue"

		#export lang
		export gfxmode
		export gfxpayload
		export menu_color_normal
		export menu_color_highlight

		insmod play
		play 960 440 1 0 4 440 1

		menuentry 'Live mode' {
		  echo 'Loading ${_MENU_DIST:-} ...'
		  set gfxpayload=keep
		  set background_color=black
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		# insmod net
		# insmod http
		# insmod progress
		  echo 'Loading linux ...'
		  linux  /live/vmlinuz ${_BOOT_OPTN[@]}
		  echo 'Loading initrd ...'
		  initrd /live/initrd
		}

		menuentry '[ System command ]' {
		  true
		}

		menuentry '- System shutdown' {
		  echo "System shutting down ..."
		  halt
		}

		menuentry '- System restart' {
		  echo "System rebooting ..."
		  reboot
		}

		if [ "\${grub_platform}" = "efi" ]; then
		  menuentry '- Boot from next volume' {
		    exit 1
		  }

		  menuentry '- UEFI Firmware Settings' {
		    fwsetup
		  }
		fi
_EOT_
	# --- create iso image ----------------------------------------------------
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
	rm -rf "${_DIRS_TEMP:?}" "${_DIRS_MNTP:?}"