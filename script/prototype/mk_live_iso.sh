#!/bin/bash

set -eu

PATH="/home/master/git/mkosi/bin:${PATH}"

# --- packages ----------------------------------------------------------------
#if ! command -v mkosi > /dev/null 2>&1; then
if ! mkosi --version > /dev/null 2>&1; then
	echo "The distribution's packages are out of date."
	echo "Check git and get it from there."
	echo "https://github.com/systemd/mkosi"
	echo ""
	echo "git clone https://github.com/systemd/mkosi"
	echo "mkdir -p ~/.local/bin/"
	echo "ln -s ${PATH}/mkosi/bin/mkosi ~/.local/bin/mkosi"
	echo "mkosi --version"
	echo ""
	echo "ln -s ${PATH}/mkosi/bin/mkosi-addon ~/.local/bin/mkosi-addon"
	echo "ln -s ${PATH}/mkosi/bin/mkosi-initrd ~/.local/bin/mkosi-initrd"
	echo "ln -s ${PATH}/mkosi/bin/mkosi-sandbox ~/.local/bin/mkosi-sandbox"
	echo ""
    echo "sudo apt-get install systemd-ukify systemd-boot systemd-boot-tools systemd-boot-efi-amd64-signed squashfs-tools parted grub-pc-bin"
	exit 0
#	declare -r -a __PACK=(
#		mkosi                           # build Bespoke OS Images
#		systemd-boot                    # simple UEFI boot manager - integration and services
#		apt                             # commandline package manager
#		btrfs-progs                     # Checksumming Copy on Write Filesystem utilities
#		cpio                            # GNU cpio -- a program to manage archives of files
#		cryptsetup-bin                  # disk encryption support - command line tools
#		debian-archive-keyring          # OpenPGP archive certificates of the Debian archive
#		dosfstools                      # utilities for making and checking MS-DOS FAT filesystems
#		e2fsprogs                       # ext2/ext3/ext4 file system utilities
#		efitools                        # Tools to manipulate EFI secure boot keys and signatures
#		erofs-utils                     # Utilities for EROFS File System
#		fdisk                           # collection of partitioning utilities
#		gnupg                           # GNU privacy guard - a free PGP replacement
#		jq                              # lightweight and flexible command-line JSON processor
#		kmod                            # tools for managing Linux kernel modules
#		mtools                          # Tools for manipulating MSDOS files
#		openssl                         # Secure Sockets Layer toolkit - cryptographic utility
#		pesign                          # Signing utility for UEFI binaries
#		python3                         # interactive high-level object-oriented language (default python3 version)
#		python3-cryptography            # Python library exposing cryptographic recipes and primitives
#		python3-pefile                  # Portable Executable (PE) parsing module for Python
#		squashfs-tools                  # Tool to create and append to squashfs filesystems
#		systemd                         # system and service manager
#		systemd-boot-efi                # simple UEFI boot manager - EFI binaries
#		systemd-boot-tools              # simple UEFI boot manager - tools
#		systemd-container               # systemd container/nspawn tools
#		systemd-repart                  # Provides the systemd-repart and systemd-sbsign utilities
#		systemd-ukify                   # tool to build Unified Kernel Images
#		tpm2-tools                      # TPM 2.0 utilities
#		xz-utils                        # XZ-format compression utilities
#		zstd                            # fast lossless compression algorithm -- CLI tool
#		archlinux-keyring               # Arch Linux PGP keyring
#		debian-archive-keyring          # OpenPGP archive certificates of the Debian archive
#		distribution-gpg-keys           # Archive keyrings for RPM-based Linux distributions
#		dnf                             # Dandified Yum package manager
#		ipxe-qemu                       # PXE boot firmware - ROM images for qemu
#		ovmf                            # UEFI firmware for 64-bit x86 virtual machines
#		pacman-package-manager          # Simple library-based package manager
#		qemu-system                     # QEMU full system emulation binaries
#		systemd-timesyncd               # minimalistic service to synchronize local time with NTP servers
#		ubuntu-keyring                  # all GnuPG keys used by Ubuntu Project
#		uidmap                          # programs to help use subuids
#		virtiofsd                       # Virtio-fs vhost-user device daemon
#		zypper                          # command line software manager using libzypp
#	)
#	declare -a    __TGET=()
#
#	mapfile -d $'\n' -t __TGET < <(LANG=C dpkg-query -W -f "\${Status}\t\${Package}\n" "${__PACK[@]}" 2>&1 | awk '/not-installed|no packages found matching/ {gsub(/.*[ \t]/,""); print $0;}' || true)
#	[[ -n "${__TGET[*]}" ]] && echo "sudo apt-get install ${__TGET[*]}"; exit 0
fi

# ---
declare -r -a __LIST=(
	"name                    version_id              code_name                               life            release         support         long_term       "
	"Debian                  1.1                     Buzz                                    EOL             1996-06-17      -               -               "
	"Debian                  1.2                     Rex                                     EOL             1996-12-12      -               -               "
	"Debian                  1.3                     Bo                                      EOL             1997-06-05      -               -               "
	"Debian                  2.0                     Hamm                                    EOL             1998-07-24      -               -               "
	"Debian                  2.1                     Slink                                   EOL             1999-03-09      2000-10-30      -               "
	"Debian                  2.2                     Potato                                  EOL             2000-08-15      2003-06-30      -               "
	"Debian                  3.0                     Woody                                   EOL             2002-07-19      2006-06-30      -               "
	"Debian                  3.1                     Sarge                                   EOL             2005-06-06      2008-03-31      -               "
	"Debian                  4.0                     Etch                                    EOL             2007-04-08      2010-02-15      -               "
	"Debian                  5.0                     Lenny                                   EOL             2009-02-14      2012-02-06      -               "
	"Debian                  6.0                     Squeeze                                 EOL             2011-02-06      2014-05-31      2016-02-29      "
	"Debian                  7.0                     Wheezy                                  EOL             2013-05-04      2016-04-25      2018-05-31      "
	"Debian                  8.0                     Jessie                                  EOL             2015-04-25      2018-06-17      2020-06-30      "
	"Debian                  9.0                     Stretch                                 EOL             2017-06-17      2020-07-18      2022-06-30      "
	"Debian                  10.0                    Buster                                  EOL             2019-07-06      2022-09-10      2024-06-30      "
	"Debian                  11.0                    Bullseye                                LTS             2021-08-14      2024-08-15      2026-08-31      "
	"Debian                  12.0                    Bookworm                                -               2023-06-10      2026-06-10      2028-06-30      "
	"Debian                  13.0                    Trixie                                  -               2025-08-09      2028-08-09      2030-06-30      "
	"Debian                  14.0                    Forky                                   -               2027-xx-xx      20xx-xx-xx      20xx-xx-xx      "
	"Debian                  15.0                    Duke                                    -               2029-xx-xx      20xx-xx-xx      20xx-xx-xx      "
	"Debian                  testing                 Testing                                 -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
	"Debian                  sid                     SID                                     -               20xx-xx-xx      20xx-xx-xx      20xx-xx-xx      "
	"Ubuntu                  4.10                    Warty%20Warthog                         EOL             2004-10-20      2006-04-30      -               "
	"Ubuntu                  5.04                    Hoary%20Hedgehog                        EOL             2005-04-08      2006-10-31      -               "
	"Ubuntu                  5.10                    Breezy%20Badger                         EOL             2005-10-12      2007-04-13      -               "
	"Ubuntu                  6.06                    Dapper%20Drake                          EOL             2006-06-01      2009-07-14      2011-06-01      "
	"Ubuntu                  6.10                    Edgy%20Eft                              EOL             2006-10-26      2008-04-25      -               "
	"Ubuntu                  7.04                    Feisty%20Fawn                           EOL             2007-04-19      2008-10-19      -               "
	"Ubuntu                  7.10                    Gutsy%20Gibbon                          EOL             2007-10-18      2009-04-18      -               "
	"Ubuntu                  8.04                    Hardy%20Heron                           EOL             2008-04-24      2011-05-12      2013-05-09      "
	"Ubuntu                  8.10                    Intrepid%20Ibex                         EOL             2008-10-30      2010-04-30      -               "
	"Ubuntu                  9.04                    Jaunty%20Jackalope                      EOL             2009-04-23      2010-10-23      -               "
	"Ubuntu                  9.10                    Karmic%20Koala                          EOL             2009-10-29      2011-04-30      -               "
	"Ubuntu                  10.04                   Lucid%20Lynx                            EOL             2010-04-29      2013-05-09      2015-04-30      "
	"Ubuntu                  10.10                   Maverick%20Meerkat                      EOL             2010-10-10      2012-04-10      -               "
	"Ubuntu                  11.04                   Natty%20Narwhal                         EOL             2011-04-28      2012-10-28      -               "
	"Ubuntu                  11.10                   Oneiric%20Ocelot                        EOL             2011-10-13      2013-05-09      -               "
	"Ubuntu                  12.04                   Precise%20Pangolin                      EOL             2012-04-26      2017-04-28      2019-04-26      "
	"Ubuntu                  12.10                   Quantal%20Quetzal                       EOL             2012-10-18      2014-05-16      -               "
	"Ubuntu                  13.04                   Raring%20Ringtail                       EOL             2013-04-25      2014-01-27      -               "
	"Ubuntu                  13.10                   Saucy%20Salamander                      EOL             2013-10-17      2014-07-17      -               "
	"Ubuntu                  14.04                   Trusty%20Tahr                           EOL             2014-04-17      2019-04-25      2024-04-25      "
	"Ubuntu                  14.10                   Utopic%20Unicorn                        EOL             2014-10-23      2015-07-23      -               "
	"Ubuntu                  15.04                   Vivid%20Vervet                          EOL             2015-04-23      2016-02-04      -               "
	"Ubuntu                  15.10                   Wily%20Werewolf                         EOL             2015-10-22      2016-07-28      -               "
	"Ubuntu                  16.04                   Xenial%20Xerus                          LTS             2016-04-21      2021-04-30      2026-04-23      "
	"Ubuntu                  16.10                   Yakkety%20Yak                           EOL             2016-10-13      2017-07-20      -               "
	"Ubuntu                  17.04                   Zesty%20Zapus                           EOL             2017-04-13      2018-01-13      -               "
	"Ubuntu                  17.10                   Artful%20Aardvark                       EOL             2017-10-19      2018-07-19      -               "
	"Ubuntu                  18.04                   Bionic%20Beaver                         LTS             2018-04-26      2023-05-31      2028-04-26      "
	"Ubuntu                  18.10                   Cosmic%20Cuttlefish                     EOL             2018-10-18      2019-07-18      -               "
	"Ubuntu                  19.04                   Disco%20Dingo                           EOL             2019-04-18      2020-01-23      -               "
	"Ubuntu                  19.10                   Eoan%20Ermine                           EOL             2019-10-17      2020-07-17      -               "
	"Ubuntu                  20.04                   Focal%20Fossa                           LTS             2020-04-23      2025-05-29      2030-04-23      "
	"Ubuntu                  20.10                   Groovy%20Gorilla                        EOL             2020-10-22      2021-07-22      -               "
	"Ubuntu                  21.04                   Hirsute%20Hippo                         EOL             2021-04-22      2022-01-20      -               "
	"Ubuntu                  21.10                   Impish%20Indri                          EOL             2021-10-14      2022-07-14      -               "
	"Ubuntu                  22.04                   Jammy%20Jellyfish                       -               2022-04-21      2027-06-01      2032-04-21      "
	"Ubuntu                  22.10                   Kinetic%20Kudu                          EOL             2022-10-20      2023-07-20      -               "
	"Ubuntu                  23.04                   Lunar%20Lobster                         EOL             2023-04-20      2024-01-25      -               "
	"Ubuntu                  23.10                   Mantic%20Minotaur                       EOL             2023-10-12      2024-07-11      -               "
	"Ubuntu                  24.04                   Noble%20Numbat                          -               2024-04-25      2029-05-31      2034-04-25      "
	"Ubuntu                  24.10                   Oracular%20Oriole                       EOL             2024-10-10      2025-07-10      -               "
	"Ubuntu                  25.04                   Plucky%20Puffin                         -               2025-04-17      2026-01-15      -               "
	"Ubuntu                  25.10                   Questing%20Quokka                       -               2025-10-09      2026-07-09      -               "
	"Ubuntu                  26.04                   Resolute%20Raccoon                      -               2026-04-23      2031-05-29      2036-04-23      "
)

# ---
declare       __DIST="${1:?}"			# distribution
              __DIST="${__DIST,,}"
readonly      __DIST
declare       __VERS="${2:-}"			# version
              __VERS="${__VERS,,}"
readonly      __VERS
declare       __PROF="${3:-}"			# profile
              __PROF="${__PROF,,}"
readonly      __PROF
declare       __OPRT="${4:-}"			# operation
              __OPRT="${__OPRT,,}"
readonly      __OPRT
# ---
declare       __CODE=""
case "${__DIST,,}" in
	debian | \
	ubuntu )
		for I in "${!__LIST[@]}"
		do
			read -r -a __LINE < <(echo "${__LIST[I]}")
			[[ "${__LINE[0],,}"  != "${__DIST}" ]] && continue
			[[ "${__LINE[1],,}"  != "${__VERS}" ]] && continue
			__CODE="${__LINE[2],,}"
			__CODE="${__CODE%%\%20*}"
			break
		done
		;;
	*) ;;
esac
readonly      __CODE
# ---
declare -r    _DIRS_MKOS="/srv/user/share/conf/_mkosi"
declare -r    _DIRS_CACH="/srv/user/share/cache"
declare -r    _DIRS_IMGS="/srv/user/share/imgs"
declare -r    _DIRS_ISOS="/srv/user/share/isos"
declare -r    _DIRS_RMAK="/srv/user/share/rmak"
declare -r    __HOME="${SUDO_HOME:-"${SUDO_USER:-"${HOME:-"/root"}"}${SUDO_USER:+"/home/${SUDO_USER}"}"}"
declare -r    __WTOP="${__HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
mkdir -p   "${__WTOP}"
[[ -n "${UDO_USE:-}" ]] && chown "${SUDO_USER:?}": "${__WTOP}"
declare       __TEMP=""
              __TEMP="$(mktemp -qd "${__WTOP}/mkosi.XXXXXX")"
readonly      __TEMP
declare -r    __MKOS="${_DIRS_MKOS:?}"
declare -r    __CACH="${_DIRS_CACH:?}/${__DIST}-${__VERS}"
declare -r    __OUTD="${__TEMP:?}/${__DIST}-${__VERS}${__PROF+-"${__PROF}"}"
#declare -r    __OUTD="${_DIRS_IMGS:?}/mkosi/${__DIST}-${__VERS}"
#declare -r    __VLID="Live ${__DIST} ${__VERS}${__CODE:+" (${__CODE})"}"
declare -r    __VLID="${__DIST^}-Live-Media"
declare -r    __ISOS="${_DIRS_RMAK:?}/live-${__DIST}-${__VERS}${__PROF+-"${__PROF}"}.iso"
declare -r    __SQFS="squashfs.img"
declare -r    __BOOT="no"
declare -r    __OUTP="rootfs"
declare -r    __FMAT="directory"
#declare -r    __FMAT="tar"
#declare -r    __FMAT="cpio"
#declare -r    __FMAT="disk"
#declare -r    __FMAT="uki"
#declare -r    __FMAT="esp"
#declare -r    __FMAT="oci"
#declare -r    __FMAT="sysext"
#declare -r    __FMAT="confext"
#declare -r    __FMAT="portable"
#declare -r    __FMAT="addon"
#declare -r    __FMAT="none"
#declare -r    __HBRD="/usr/lib/ISOLINUX/isohdpfx.bin"
declare -r    __ETRI="/usr/lib/ISOLINUX/isolinux.bin"
#declare -r    __BIOS="/usr/lib/syslinux/mbr/gptmbr.bin"
declare -r    __BIOS="${__OUTD:?}/mbr.bin"
declare -r    __UEFI="${__OUTD:?}/efi.img"
declare -r    __MNTP="${__OUTD:?}/mnt"
declare -r    __CDFS="${__OUTD:?}/img"
declare -r    __BCAT="boot.cat"

declare -a    __COMD=()

# --- mkosi -------------------------------------------------------------------
function fnMk_mkosi() {
	__COMD=(
		${__BOOT:+--bootable="${__BOOT}"}
		${__OUTP:+--output="${__OUTP}"}
		${__FMAT:+--format="${__FMAT}"}
		${__DIST:+--distribution="${__DIST}"}
		${__VERS:+--release="${__CODE:-"${__VERS}"}"}
		${__MKOS:+--directory="${__MKOS}"}
		${__CACH:+--package-cache-dir="${__CACH}"}
		${__OUTD:+--output-directory="${__OUTD}"}
		${__PROF:+--profile="${__PROF}"}
	)

	case "${__OPRT:-}" in
		build) __COMD=("${__COMD[@]}" --wipe-build-dir --force build);;
		*    ) __COMD=("${__COMD[@]}" --no-pager summary);;
	esac

	if ! mkosi "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "mkosi ${__COMD[*]}"
		exit "${__RTCD}"
	fi
}

# --- mksquashfs --------------------------------------------------------------
function fnMk_mksquashfs() {
	__COMD=(
		"${__OUTD}/${__OUTP}"
		"${__OUTD}/${__SQFS}"
		-quiet
		-progress
	)

	if ! mksquashfs "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "mksquashfs ${__COMD[*]}"
		exit "${__RTCD}"
	fi
}

# --- uefi --------------------------------------------------------------------
function fnMk_uefi() {
	__WORK="${__UEFI:?}.work"
	dd if=/dev/zero of="${__WORK}" bs=1M count=100
	__LOOP="$(losetup --find --show "${__WORK}")"
	partprobe "${__LOOP}"
	sfdisk "${__LOOP}" <<- _EOT_
		,,U,
	_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1

	# --- install grub module -------------------------------------------------
	mkdir -p "${__MNTP:?}"
	mount "${__LOOP}"p1 "${__MNTP}"
	grub-install \
		--target=x86_64-efi \
		--efi-directory="${__MNTP}" \
		--boot-directory="${__MNTP}/boot" \
		--bootloader-id="${__DIST}" \
		--removable
	grub-install \
		--target=i386-pc \
		--boot-directory="${__MNTP}/boot" \
		"${__LOOP}"
	umount "${__MNTP}"
	losetup --detach "${__LOOP}"

	# --- create uefi/bios image ----------------------------------------------
	__ARRY=("$(fdisk -l "${__WORK}")")
	__SECT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/Sector size/ s/^.*:[ \t]*\([0-9,]\+\)[ \t]*.*$/\1/p')"
	__STRT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/'"${__WORK##*/}"'1/ s/^[^ \t]\+[ \t]\+\([0-9,]\+\)[ \t]\+.*$/\1/p')"
	__CONT="$(printf "%s\n" "${__ARRY[@]}" | sed -ne '/'"${__WORK##*/}"'1/ s/^[^ \t]\+[ \t]\+[0-9,]\+[ \t]\+[0-9,]\+[ \t]\+\([0-9,]\+\)[ \t]\+.*$/\1/p')"
	dd if="${__WORK}" of="${__UEFI}" bs="${__SECT}" skip="${__STRT}" count="${__CONT}"
#	dd if="${__WORK}" of="${__BIOS}" bs=1 count=446
}

# --- cdfs --------------------------------------------------------------------
function fnMk_cdfs() {
#	__KRNL="$(find "${__OUTD}/${__OUTP}"/{boot,} -maxdepth 1 -name 'linux'    -print -quit)"
	__VLNZ="$(find "${__OUTD}/${__OUTP}"/{boot,} -maxdepth 1 -name 'vmlinuz'  -print -quit)"
	__IRAM="$(find "${__OUTD}/${__OUTP}"/{boot,} -maxdepth 1 -name 'initrd-*' -print -quit)"
	__IRAM="${__IRAM:-"$(find "${__OUTD}/${__OUTP}"/{boot,} -maxdepth 1 -name 'initrd.img' -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__OUTD}/${__OUTP}"/{boot,} -maxdepth 1 -name 'initrd'     -print -quit)"}"
	mkdir -p "${__CDFS:?}"/{.disk,EFI/BOOT,boot/grub/{live-theme,x86_64-efi,i386-pc},isolinux,LiveOS}
	cp --preserve=timestamps "${__OUTD}/${__SQFS}"                                             "${__CDFS}/LiveOS"
	cp --preserve=timestamps "${__IRAM}"                                                       "${__CDFS}/LiveOS"
	cp --preserve=timestamps "${__VLNZ}"                                                       "${__CDFS}/LiveOS"
	cp --preserve=timestamps "${__UEFI}"                                                       "${__CDFS}"/boot/grub
	cp --preserve=timestamps --recursive "${__OUTD}/${__OUTP}"/usr/lib/grub/x86_64-efi/.       "${__CDFS}"/boot/grub/x86_64-efi
	cp --preserve=timestamps --recursive "${__OUTD}/${__OUTP}"/usr/lib/grub/i386-pc/.          "${__CDFS}"/boot/grub/i386-pc
	cp --preserve=timestamps --recursive "${__OUTD}/${__OUTP}"/usr/lib/syslinux/modules/bios/. "${__CDFS}"/isolinux
	cp --preserve=timestamps  "${__ETRI}"                                                      "${__CDFS}"/isolinux
	cp --preserve=timestamps  /usr/lib/syslinux/mbr/gptmbr.bin                                 "${__BIOS}"

	touch "${__CDFS}/.disk/info"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CDFS}"/EFI/BOOT/grub.cfg || true
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CDFS}"/boot/grub/grub.cfg || true
		set default=0

		if [ x\$feature_default_font_path = xy ] ; then
		  font=unicode
		else
		  font=\$prefix/unicode.pf2
		fi

		if loadfont \$font ; then
		  set gfxmode=800x600
		  set gfxpayload=keep
		  insmod efi_gop
		  insmod efi_uga
		  insmod video_bochs
		  insmod video_cirrus
		else
		  set gfxmode=auto
		  insmod all_video
		fi

		insmod gfxterm
		insmod png

		source /boot/grub/theme.cfg

		terminal_output gfxterm

		insmod play
		play 960 440 1 0 4 440 1

		menuentry "Live system (amd64)" --hotkey=l {
		  linux  /LiveOS/${__VLNZ##*/} root=live:CDLABEL=${__VLID} rd.live.image security=apparmor apparmor=1
		  initrd /LiveOS/${__IRAM##*/}
		}
_EOT_
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CDFS}"/boot/grub/theme.cfg || true
		set color_normal=light-gray/black
		set color_highlight=white/dark-gray

		if [ -e /boot/grub/splash.png ]; then
		  set theme=/boot/grub/live-theme/theme.txt
		else
		  set menu_color_normal=cyan/blue
		  set menu_color_highlight=white/blue
		fi
_EOT_
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__CDFS}"/isolinux/isolinux.cfg || true
		default vesamenu.c32
		prompt 0
		timeout 0

		menu hshift 0
		menu width 82

		menu title Boot menu

		menu background splash.png
		menu color title        * #FFFFFFFF *
		menu color border       * #00000000 #00000000 none
		menu color sel          * #ffffffff #76a1d0ff *
		menu color hotsel       1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg       * #ffffffff #00000000 *
		menu color help         37;40 #ffdddd00 #00000000 none
		menu vshift 12
		menu rows 10
		menu helpmsgrow 15
		# The command line must be at least one line from the bottom.
		menu cmdlinerow 16
		menu timeoutrow 16
		menu tabmsgrow 18
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		label live-amd64
		  menu label ^Live system (amd64)
		  menu default
		  linux  /LiveOS/${__VLNZ##*/}
		  initrd /LiveOS/${__IRAM##*/}
		  append root=live:CDLABEL=${__VLID} rd.live.image security=apparmor apparmor=1

		menu clear
_EOT_
}

# --- xorrisofs ---------------------------------------------------------------
function fnMk_xorrisofs() {
	__COMD=(
		-rational-rock
		${__VLID:+-volid "${__VLID// /-}"}
		-joliet -joliet-long
		-full-iso9660-filenames -iso-level 3
		-partition_offset 16
		--grub2-mbr "${__BIOS}"
		--mbr-force-bootable
		-append_partition 2 0xEF "boot/grub/${__UEFI##*/}"
		-appended_part_as_gpt
		${__BCAT:+-eltorito-catalog "isolinux/${__BCAT##*/}"}
		${__ETRI:+-eltorito-boot "isolinux/${__ETRI##*/}"}
		-no-emul-boot
		-boot-load-size 4 -boot-info-table
		--grub2-boot-info
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::'
		-no-emul-boot
		-output "${__ISOS:?}"
		.
	)

	pushd "${__CDFS:?}" > /dev/null 2>&1
	if ! xorrisofs "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "xorrisofs ${__COMD[*]}"
		exit "${__RTCD}"
	fi
	popd > /dev/null 2>&1
}

fnMk_mkosi
fnMk_mksquashfs
fnMk_uefi
fnMk_cdfs
fnMk_xorrisofs

rm -rf "${__TEMP:?}"

exit 0