#!/bin/bash

	export LANG=C
	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM
#	trap 'exit 1' 1 2 3 15

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	# --- working directory ---------------------------------------------------
	declare -r    _PROG_PATH="$0"
	declare -r    _PROG_PARM="${*:-}"
	declare -r    _PROG_DIRS="${_PROG_PATH%/*}"
	declare -r    _PROG_NAME="${_PROG_PATH##*/}"
#	declare -r    _PROG_PROC="${_PROG_NAME}.$$"

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
              __DIST="${__DIST,,}"		# --distribution=
readonly      __DIST
declare       __VERS="${2:-}"			# version
              __VERS="${__VERS,,}"		# --release=
readonly      __VERS
declare       __EDTN="${3:-}"			# EDITION
              __EDTN="${__EDTN,,}"		# --environment=EDITION=
readonly      __EDTN
declare       __OPRT="${4:-}"			# operation
              __OPRT="${__OPRT,,}"
readonly      __OPRT
# ---
declare       __CODE=""
case "${__DIST}-${__VERS}" in
#	debian-11.0         | \
	debian-12.0         | \
	debian-13.0         | \
	debian-14.0         | \
	debian-15.0         | \
	debian-testing      | \
	debian-sid          ) ;;
#	debian-experimental ) ;;
#	ubuntu-16.04        | \
#	ubuntu-18.04        | \
#	ubuntu-20.04        | \
#	ubuntu-22.04        | \
	ubuntu-24.04        | \
	ubuntu-25.04        | \
	ubuntu-25.10        | \
	ubuntu-26.04        ) ;;
#	rhel-*              ) ;;
	fedora-43           | \
	fedora-44           ) ;;
#	centos-8            | \
	centos-9            | \
	centos-10           ) ;;
#	alma-8              | \
	alma-9              | \
	alma-10             ) ;;
#	rocky-8             | \
	rocky-9             | \
	rocky-10            ) ;;
	opensuse-*          ) ;;
	*) echo "not supported: ${__DIST,,}-${__VERS}"; exit 1;;
esac
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
# debian: https://packages.debian.org/
# ubuntu: https://packages.ubuntu.com/
# mkosi : https://github.com/systemd/mkosi/blob/main/mkosi/resources/man/mkosi.1.md
# dracut: https://github.com/zfsonlinux/dracut
# --- shared directory parameter ----------------------------------------------
declare -r    _DIRS_TOPS="/srv"								# top of shared directory
declare -r    _DIRS_HGFS="${_DIRS_TOPS}/hgfs"				# vmware shared
declare -r    _DIRS_HTML="${_DIRS_TOPS}/http/html"			# html contents
declare -r    _DIRS_SAMB="${_DIRS_TOPS}/samba"				# samba shared
declare -r    _DIRS_TFTP="${_DIRS_TOPS}/tftp"				# tftp contents
declare -r    _DIRS_USER="${_DIRS_TOPS}/user"				# user file
# --- shared of user file -----------------------------------------------------
declare -r    _DIRS_PVAT="${_DIRS_USER}/private"			# private contents directory
declare -r    _DIRS_SHAR="${_DIRS_USER}/share"				# shared of user file
declare -r    _DIRS_CONF="${_DIRS_SHAR}/conf"				# configuration file
declare -r    _DIRS_DATA="${_DIRS_CONF}/_data"				# data file
declare -r    _DIRS_KEYS="${_DIRS_CONF}/_keyring"			# keyring file
declare -r    _DIRS_MKOS="${_DIRS_CONF}/_mkosi"				# mkosi configuration files
declare -r    _DIRS_TMPL="${_DIRS_CONF}/_template"			# templates for various configuration files
declare -r    _DIRS_SHEL="${_DIRS_CONF}/script"				# shell script file
declare -r    _DIRS_IMGS="${_DIRS_SHAR}/imgs"				# iso file extraction destination
declare -r    _DIRS_ISOS="${_DIRS_SHAR}/isos"				# iso file
declare -r    _DIRS_LOAD="${_DIRS_SHAR}/load"				# load module
declare -r    _DIRS_RMAK="${_DIRS_SHAR}/rmak"				# remake file
declare -r    _DIRS_CACH="${_DIRS_SHAR}/cache"				# cache file
declare -r    _DIRS_CTNR="${_DIRS_SHAR}/containers"			# container file
declare -r    _DIRS_CHRT="${_DIRS_SHAR}/chroot"				# container file (chroot)
# --- common data file (prefer non-empty current file) ------------------------
declare -r    _FILE_CONF="common.cfg"						# common configuration file
declare -r    _FILE_DIST="distribution.dat"					# distribution data file
declare -r    _FILE_MDIA="media.dat"						# media data file
declare -r    _FILE_DSTP="debstrap.dat"						# debstrap data file
declare -r    _PATH_CONF="${_DIRS_DATA}/${_FILE_CONF}"		# common configuration file
declare -r    _PATH_DIST="${_DIRS_DATA}/${_FILE_DIST}"		# distribution data file
declare -r    _PATH_MDIA="${_DIRS_DATA}/${_FILE_MDIA}"		# media data file
declare -r    _PATH_DSTP="${_DIRS_DATA}/${_FILE_DSTP}"		# debstrap data file
# --- pre-configuration file templates ----------------------------------------
declare -r    _FILE_KICK="kickstart_rhel.cfg"				# for rhel
declare -r    _FILE_CLUD="user-data_ubuntu"					# for ubuntu cloud-init
declare -r    _FILE_SEDD="preseed_debian.cfg"				# for debian
declare -r    _FILE_SEDU="preseed_ubuntu.cfg"				# for ubuntu
declare -r    _FILE_YAST="yast_opensuse.xml"				# for opensuse
declare -r    _FILE_AGMA="agama_opensuse.json"				# for opensuse
declare -r    _PATH_KICK="${_DIRS_TMPL}/${_FILE_KICK}"		# for rhel
declare -r    _PATH_CLUD="${_DIRS_TMPL}/${_FILE_CLUD}"		# for ubuntu cloud-init
declare -r    _PATH_SEDD="${_DIRS_TMPL}/${_FILE_SEDD}"		# for debian
declare -r    _PATH_SEDU="${_DIRS_TMPL}/${_FILE_SEDU}"		# for ubuntu
declare -r    _PATH_YAST="${_DIRS_TMPL}/${_FILE_YAST}"		# for opensuse
declare -r    _PATH_AGMA="${_DIRS_TMPL}/${_FILE_AGMA}"		# for opensuse
# --- shell script ------------------------------------------------------------
declare -r    _FILE_ERLY="autoinst_cmd_early.sh"			# shell commands to run early
declare -r    _FILE_LATE="autoinst_cmd_late.sh"				# "              to run late
declare -r    _FILE_PART="autoinst_cmd_part.sh"				# "              to run after partition
declare -r    _FILE_RUNS="autoinst_cmd_run.sh"				# "              to run preseed/run
declare -r    _PATH_ERLY="${_DIRS_SHEL}/${_FILE_ERLY}"		# shell commands to run early
declare -r    _PATH_LATE="${_DIRS_SHEL}/${_FILE_LATE}"		# "              to run late
declare -r    _PATH_PART="${_DIRS_SHEL}/${_FILE_PART}"		# "              to run after partition
declare -r    _PATH_RUNS="${_DIRS_SHEL}/${_FILE_RUNS}"		# "              to run preseed/run
# --- tftp menu ---------------------------------------------------------------
declare -r    _FILE_IPXE="autoexec.ipxe"					# ipxe
declare -r    _FILE_GRUB="boot/grub/grub.cfg"				# grub
declare -r    _FILE_SLNX="menu-bios/syslinux.cfg"			# syslinux (bios)
declare -r    _FILE_UEFI="menu-efi64/syslinux.cfg"			# syslinux (efi64)
declare -r    _PATH_IPXE="${_DIRS_TFTP}/${_FILE_IPXE}"		# ipxe
declare -r    _PATH_GRUB="${_DIRS_TFTP}/${_FILE_GRUB}"		# grub
declare -r    _PATH_SLNX="${_DIRS_TFTP}/${_FILE_SLNX}"		# syslinux (bios)
declare -r    _PATH_UEFI="${_DIRS_TFTP}/${_FILE_UEFI}"		# syslinux (efi64)
# --- working directory parameter ---------------------------------------------
declare -r    _DIRS_VADM="/var/admin"						# top of admin working directory
declare -r    _DIRS_INST=""									# auto-install working directory
declare -r    _DIRS_BACK=""									# top of backup directory
declare -r    _DIRS_ORIG=""									# original file directory
declare -r    _DIRS_INIT=""									# initial file directory
declare -r    _DIRS_SAMP=""									# sample file directory
declare -r    _DIRS_LOGS=""									# log file directory
# -----------------------------------------------------------------------------
declare       __DATE=""
              __DATE="$(date +"%Y/%m/%d %H:%M:%S")"
readonly      __DATE
declare -r    __HOME="${SUDO_HOME:-"${HOME:?}"}"
declare -r    __WTOP="${__HOME:-"${TMPDIR:-"/tmp"}"}/.workdirs"
mkdir -p   "${__WTOP}"
[[ -n "${UDO_USE:-}" ]] && chown "${SUDO_USER:?}": "${__WTOP}"
declare       __TEMP=""					# local
              __TEMP="$(mktemp -qd "${__WTOP}/mkosi.XXXXXX")"
readonly      __TEMP
declare       __RTMP=""					# remote
              __RTMP="$(mktemp -qd "${_DIRS_PVAT}/wrk/mkosi.XXXXXX")"
readonly      __RTMP
declare -r    __MKOS="${_DIRS_MKOS:?}"	# --directory=
#declare -r    __ARCH="alpha"			# --architecture=
#declare -r    __ARCH="arc"				# "
#declare -r    __ARCH="arm"				# "
#declare -r    __ARCH="arm64"			# "
#declare -r    __ARCH="ia64"			# "
#declare -r    __ARCH="loongarch64"		# "
#declare -r    __ARCH="mips64-le"		# "
#declare -r    __ARCH="mips-le"			# "
#declare -r    __ARCH="parisc"			# "
#declare -r    __ARCH="ppc"				# "
#declare -r    __ARCH="ppc64"			# "
#declare -r    __ARCH="ppc64-le"		# "
#declare -r    __ARCH="riscv32"			# "
#declare -r    __ARCH="riscv64"			# "
#declare -r    __ARCH="s390"			# "
#declare -r    __ARCH="s390x"			# "
#declare -r    __ARCH="tilegx"			# "
#declare -r    __ARCH="x86"				# "
declare -r    __ARCH="x86-64"			# "
declare -r    __SUBD="${__DIST}-${__CODE:-"${__VERS}"}${__ARCH:+-"${__ARCH//_/-}"}${__EDTN+-"${__EDTN}"}"
declare -r    __WRKD="${__TEMP:?}/${__SUBD:?}" # --workspace-directory=
declare -r    __OUTD="${__RTMP:?}/${__SUBD:?}" # --output-directory=
declare       __VLID=""
case "${__DIST}" in
	debian  ) __VLID="Debian";;
	ubuntu  ) __VLID="Ubuntu";;
	fedora  ) __VLID="Fedora";;
	centos  ) __VLID="CentOS-Stream";;
	alma    ) __VLID="AlmaLinux";;
	rocky   ) __VLID="Rocky";;
	opensuse) __VLID="openSUSE";;
#	miracle ) __VLID="MIRACLE-LINUX";;
	*       ) __VLID="${__DIST^}";;
esac
              __VLID="${__VLID}${__VERS:+" ${__VERS^}"}${__ARCH:+" ${__ARCH}"}${__EDTN:+" ${__EDTN^}"}"
              __VLID="${__VLID// /-}"
#             __VLID="${__VLID// /$'\x20'}"
readonly      __VLID
declare -r    __ISOS="${_DIRS_RMAK:?}/live-${__VLID,,}.iso"
declare       __HOST=""					# --hostname=
              __HOST="sv-${__VLID%%-*}.workgroup"
              __HOST="${__HOST,,}"
readonly      __HOST
#declare -r    __BOOT="yes"				# --bootable=
declare -r    __OUTP="root_img"			# --output=
#declare -r    __FMAT="directory"		# --format=
#declare -r    __FMAT="tar"				# "
#declare -r    __FMAT="cpio"			# "
declare -r    __FMAT="disk"				# "
#declare -r    __FMAT="uki"				# "
#declare -r    __FMAT="esp"				# "
#declare -r    __FMAT="oci"				# "
#declare -r    __FMAT="sysext"			# "
#declare -r    __FMAT="confext"			# "
#declare -r    __FMAT="portable"		# "
#declare -r    __FMAT="addon"			# "
#declare -r    __FMAT="none"			# "
#declare -r    __NWRK="yes"				# --with-network=
declare -r    __RECM="yes"				# --with-recommends

declare       __LOOP=""
#declare -r    __HBRD="/usr/lib/ISOLINUX/isohdpfx.bin"
declare -r    __CDFS="${__OUTD:?}/cdfs"
declare -r    __RTFS="${__OUTD:?}/rtfs"
declare -r    __MNTP="${__OUTD:?}/mntp"
declare -r    __UEFI="${__OUTD:?}/uefi.img"
declare -r    __MBRF="${__OUTD:?}/bios.img"
declare -r    __RAWF="${__OUTD:?}/${__OUTP}.raw"
declare -r    __SQFS="${__OUTD:?}/squashfs.img"
declare -r    __STRG="${__OUTD:?}/vm_uefi_${__VLID,,}.raw"
declare -r    __BCAT="boot.cat"
declare       __ETRI=""					# eltorito
declare       __BIOS=""					# bios or uefi imga file path
declare       __RTLP=""					# root image loop device name
declare       __VLNZ=""					# kernel
declare       __IRAM=""					# initramfs

#	* mount point
#		__CDFS: cdfs: cdfs image
#		__RTFS: rtfs: root image
#		__MNTP: mntp: work space
#	* image file
#		__UEFI: uefi.img    : uefi
#		__MBRF: bios.img    : bios
#		__RAWF: root_img.raw: root
#		__SQFS: squashfs.img: squashfs
#		__STRG: vm_uefi*.raw: storage
#	* work file
#		fstab           :
#		grub.cfg        :
#		run-once.service:
#		run-once.sh     :

function fnMsgout() {
	case "${2:-}" in
		start    | complete)
			case "${3:-}" in
				*/*/*) printf "\033[m${1:-}\033[m: \033[45m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # date
				*    ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n" "${2:-}" "${3:-}";; # info
			esac
			;;
		skip               ) printf "\033[m${1:-}\033[m: \033[92m--- %-8.8s: %s ---\033[m\n"    "${2:-}" "${3:-}";; # info
		remove   | umount  ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		archive            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		success            ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		failed             ) printf "\033[m${1:-}\033[m:     \033[41m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # alert
		active             ) printf "\033[m${1:-}\033[m:     \033[92m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # info
		inactive           ) printf "\033[m${1:-}\033[m:     \033[93m%-8.8s: %s\033[m\n"        "${2:-}" "${3:-}";; # warn
		caution            ) printf "\033[m${1:-}\033[m:     \033[93m\033[7m%-8.8s: %s\033[m\n" "${2:-}" "${3:-}";; # warn
		-*                 ) printf "\033[m${1:-}\033[m:     \033[36m%-8.8s: %s\033[m\n"        "${2#-}" "${3:-}";; # gap
		info               ) printf "\033[m${1:-}\033[m: \033[92m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # info
		warn               ) printf "\033[m${1:-}\033[m: \033[93m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # warn
		alert              ) printf "\033[m${1:-}\033[m: \033[91m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # alert
		*                  ) printf "\033[m${1:-}\033[m: \033[37m%12.12s: %s\033[m\n"           "${2:-}" "${3:-}";; # normal
	esac
}

# --- mkosi -------------------------------------------------------------------
declare -a    __COMD=(
	${__BOOT:+--bootable="${__BOOT}"}
	${__OUTP:+--output="${__OUTP}"}
	${__FMAT:+--format="${__FMAT}"}
	${__NWRK:+--with-network="${__NWRK}"}
	${__RECM:+--with-recommends="${__RECM}"}
	${__DIST:+--distribution="${__DIST}"}
	${__VERS:+--release="${__CODE:-"${__VERS}"}"}
	${__ARCH:+--architecture="${__ARCH//_/-}"}
	${__MKOS:+--directory="${__MKOS}"}
	${__WRKD:+--workspace-directory="${__WRKD}"}
	${__CACH:+--package-cache-dir="${__CACH}"}
	${__OUTD:+--output-directory="${__OUTD}"}
	${__EDTN:+--environment=EDITION="${__EDTN}"}
	${__HOST:+--hostname="${__HOST}"}
)

function fnMk_mkosi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=("${@:-}")
	declare -i    __RTCD=0
	if ! /usr/local/bin/mkosi "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "mkosi ${__COMD[*]}"
	fi
	[[ "${__RTCD}" -ne 0 ]] && exit "${__RTCD}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

function fnMk_mkosi_summary() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	__COMD+=(
		--no-pager
		summary
	)
	fnMk_mkosi "${__COMD[@]:-}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

function fnMk_mkosi_build() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	__COMD+=(
		--force
		--wipe-build-dir
		build
	)
	fnMk_mkosi "${__COMD[@]:-}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- mount -------------------------------------------------------------------
function fnMk_mount_fs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if [[ "${__FMAT:-}" != "disk" ]]; then
		return
	fi
	mkdir -p "${__RTFS:?}"
	__RTLP="$(losetup --find --show "${__RAWF:?}")"
	partprobe "${__RTLP}"
	mount -r "${__RTLP}"p1 "${__RTFS}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- umount ------------------------------------------------------------------
function fnMk_umount_fs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	if [[ "${__FMAT:-}" != "disk" ]]; then
		return
	fi
	umount "${__RTFS:?}"
	losetup --detach "${__RTLP:?}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- find kernel -------------------------------------------------------------
function fnMk_find_kernel() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	           __VLNZ="$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'vmlinuz-*'    -o -name 'linux-*'         \) -print -quit)"
	__VLNZ="${__VLNZ:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'vmlinuz'      -o -name 'linux'           \) -print -quit)"}"
	           __IRAM="$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"
	__IRAM="${__IRAM:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd-*.img' -o -name 'initramfs-*.img' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd.img-*' -o -name 'initramfs.img-*' \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd.img'   -o -name 'initramfs.img'   \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd-*'     -o -name 'initramfs-*'     \) -print -quit)"}"
	__IRAM="${__IRAM:-"$(find "${__RTFS:-}"/{boot,} -maxdepth 1 \( -name 'initrd'       -o -name 'initramfs'       \) -print -quit)"}"
	__VLNZ="${__VLNZ#"${__RTFS}"}"
	__IRAM="${__IRAM#"${__RTFS}"}"
	readonly __VLNZ
	readonly __IRAM
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- vm setup loopXp1 --------------------------------------------------------
function fnMk_vm_setup_loopXp1() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __LOOP="${1:?}"		# loop device name
	declare -r    __UUID="${2:?}"		# loopXp2 uuid
	mkdir -p "${__MNTP:?}"
	mount "${__LOOP}"p1 "${__MNTP}"
	# --- install grub module -------------------------------------------------
	if command -v grub-install > /dev/null 2>&1; then
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
	elif command -v grub2-install > /dev/null 2>&1; then
		grub2-install \
			--target=x86_64-efi \
			--efi-directory="${__MNTP}" \
			--boot-directory="${__MNTP}/boot" \
			--bootloader-id="${__DIST}" \
			--removable
		grub2-install \
			--target=i386-pc \
			--boot-directory="${__MNTP}/boot" \
			"${__LOOP}"
	else
		fnMsgout "${_PROG_NAME:-}" "abnormal termination" "[${__FUNC_NAME}]"
		exit 1
	fi
	# --- create grub.cfg -----------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}"/grub.cfg
		set default="0"
		set timeout="5"

		if [ "x\${font}" = "x" ] ; then
		  if [ "x\${feature_default_font_path}" = "xy" ] ; then
		    font="unicode"
		  else
		    font="\${prefix}/fonts/font.pf2"
		  fi
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=auto
		  set gfxpayload="keep"
		  export gfxmode
		  export gfxpayload
		  if [ "\${grub_platform}" = "efi" ]; then
		    insmod efi_gop
		    insmod efi_uga
		  else
		    insmod vbe
		    insmod vga
		  fi
		  insmod video_bochs
		  insmod video_cirrus
		  insmod gfxterm
		  insmod gettext
		  insmod png
		  terminal_output gfxterm
		fi

		set timeout_style=menu
		set color_normal=light-gray/black
		set color_highlight=white/dark-gray
		export color_normal
		export color_highlight

		#set theme=/boot/grub/theme.cfg
		#export theme

		#insmod play
		#play 960 440 1 0 4 440 1

		menuentry "Live system (amd64)" --hotkey=l {
		  set gfxpayload="keep"
		  set background_color="black"
		  set uuid="${__UUID:?}"
		  search --no-floppy --fs-uuid --set=root \${uuid}
		  echo root=\${root}
		  set devs=/dev/sda2
		  set ttys=console=ttyS0
		  set options="\${ttys} root=\${devs} security=selinux selinux=1 enforcing=0"
		# set options="\${ttys} root=\${devs} security=apparmor apparmor=1"
		# if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  echo 'Loading vmlinuz ...'
		  linux  ${__VLNZ:?} \${options} ---
		  echo 'Loading initramfs ...'
		  initrd ${__IRAM:?}
		}
_EOT_
	cp --preserve=timestamps "${__OUTD}"/grub.cfg "${__MNTP}"/boot/grub/
	# -------------------------------------------------------------------------
	umount "${__MNTP}"
}

# --- vm setup loopXp1 --------------------------------------------------------
function fnMk_vm_setup_loopXp2() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __LOOP="${1:?}"		# loop device name
	declare -r    __UUID="${2:?}"		# loopXp2 uuid
	mkdir -p "${__MNTP:?}"
	mount "${__LOOP}"p2 "${__MNTP}"
	# --- root files ----------------------------------------------------------
	cp --preserve=mode,ownership,timestamps,links --recursive "${__RTFS}"/. "${__MNTP}"
	# --- /etc/fstab ----------------------------------------------------------
	__PATH="${__MNTP}"/etc/fstab
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__PATH##*/}"
		UUID=${__UUID:?} / ext4 defaults 0 0
_EOT_
	cp --preserve=timestamps "${__OUTD}/${__PATH##*/}" "${__PATH}"
	# --- run-once.sh ---------------------------------------------------------
	__SRVC="${__MNTP}"/etc/systemd/system/run-once.service
	__TGET="${__MNTP}"/var/admin/autoinst/run-once.sh
	mkdir -p "${__TGET%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__TGET##*/}"
		#!/bin/bash
		# touch /.autorelabel
		systemctl disable ${__SRVC##*/}
		rm -f "${__SRVC#"${__MNTP#}"}"
		rm -f "\${0:?}"
		ls -lahZ / > /var/admin/autoinst/"\${0##*/}".success
		shutdown -h now
_EOT_
	cp --preserve=timestamps "${__OUTD}/${__TGET##*/}" "${__TGET}"
	chmod +x "${__TGET}"
	# --- /etc/systemd/system/run-once.service --------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__SRVC##*/}"
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
	cp --preserve=timestamps "${__OUTD}/${__SRVC##*/}" "${__SRVC}"
	chmod +x "${__SRVC}"
	chroot "${__MNTP:?}" bash -c "systemctl enable ${__SRVC##*/}"
	# -------------------------------------------------------------------------
	umount "${__MNTP}"
}

# --- vm setup ----------------------------------------------------------------
function fnMk_vm_setup() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __LOOP=""				# loop device name
	declare       __UUID=""				# loopXp2 uuid
	# --- create dummy storage ------------------------------------------------
#	echo $((($(lsblk --noheadings --output=SIZE --bytes "${__RTLP:?}") + (100 * (1024 ** 2))) / $((1024 ** 3)) + 1))
#	dd if=/dev/zero of="${__STRG:?}" bs=1G count=20
	truncate --size=20G "${__STRG:?}"
	__LOOP="$(losetup --find --show "${__STRG}")"
	partprobe "${__LOOP:?}"
	sfdisk --force --wipe always "${__LOOP}" <<- _EOT_
		,100MiB,U
		,,L
_EOT_
	partprobe "${__LOOP}"
	mkfs.vfat -F 32 "${__LOOP}"p1
	mkfs.ext4 -F "${__LOOP}"p2
	__UUID="$(lsblk --noheadings --output=UUID "${__LOOP}"p2)"
	fnMk_vm_setup_loopXp1 "${__LOOP:?}" "${__UUID:?}"
	fnMk_vm_setup_loopXp2 "${__LOOP:?}" "${__UUID:?}"
	losetup --detach "${__LOOP}"
	# -------------------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- qemu --------------------------------------------------------------------
function fnMk_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=(
		-cpu "host"
		-machine "q35"
		-enable-kvm
		-device "intel-iommu"
		-m "size=4G"
		-boot "order=c"
		-nic "bridge"
		-vga "std"
		-full-screen
		-display "curses,charset=CP932"
		-k "ja"
		-device "ich9-intel-hda"
		-vnc ":0"
		-nographic
		-drive "file=${__STRG},format=raw"
	)
	declare -i    __RTCD=0
	if ! qemu-system-x86_64 "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "qemu-system-x86_64 ${__COMD[*]}"
	fi
#	/usr/share/novnc/utils/novnc_proxy
#	export sshpasswd="master"
#	echo "${sshpasswd}" | sshpass -p "${sshpasswd}" ssh -o StrictHostKeyChecking=no master@sv-debian 'sudo -S bash -c "ls -lahZ /; sudo shutdown -h now"'
#	unset sshpasswd
	[[ "${__RTCD}" -ne 0 ]] && exit "${__RTCD}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- mksquashfs --------------------------------------------------------------
function fnMk_mksquashfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=(
		"${__MNTP}"
		"${__SQFS}"
		-quiet
		-progress
		-noappend
		-no-xattrs
		-ef /.autorelabel /.cache /.viminfo
	)
	declare       __LOOP=""				# loop device name
	declare -i    __RTCD=0
	# --- create dummy storage ------------------------------------------------
	__LOOP="$(losetup --find --show "${__STRG}")"
	partprobe "${__LOOP}"
	mount "${__LOOP}"p2 "${__MNTP}"
	rm -f "${__MNTP}"/{.autorelabel,.cache,.viminfo}
	if ! mksquashfs "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "mksquashfs ${__COMD[*]}"
	fi
	umount "${__MNTP}"
	losetup --detach "${__LOOP}"
	[[ "${__RTCD}" -ne 0 ]] && exit "${__RTCD}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- uefi --------------------------------------------------------------------
function fnMk_uefi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare       __LOOP=""				# loop device name
	declare       __PATH=""				# path to the device node
	declare       __PSEC=""				# physical sector size
	declare       __STRT=""				# partition start offset (in 512-byte sectors)
	declare       __SIZE=""				# size of the device (bytes)
	declare       __CONT=""				# partition sector size (in 512-byte sectors)
	__LOOP="$(losetup --find --show "${__STRG}")"
	partprobe "${__LOOP}"
	# --- create uefi/bios image ----------------------------------------------
	__WORK="$(lsblk -no-header --bytes --output=PATH,PHY-SEC,START,SIZE "${__LOOP}"p1)"
	read -r __PATH __PSEC __STRT __SIZE < <(echo "${__WORK}")
	__CONT="$(("${__SIZE}" / 512))"
	dd if="${__STRG}" of="${__UEFI}" bs="${__PSEC}" skip="${__STRT}" count="${__CONT}"
	dd if="${__STRG}" of="${__MBRF}" bs=1 count=440
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- cdfs --------------------------------------------------------------------
function fnMk_cdfs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create cdfs image ---------------------------------------------------
	mkdir -p "${__CDFS:?}"/{.disk,EFI/BOOT,boot/grub/{live-theme,x86_64-efi,i386-pc},isolinux,LiveOS}
	touch "${__CDFS}/.disk/info"
	[[ -e "${__UEFI:?}"                                 ]] && cp --preserve=timestamps             "${__UEFI:?}"                                 "${__CDFS:?}"/boot/grub
	[[ -e "${__SQFS:?}"                                 ]] && cp --preserve=timestamps             "${__SQFS:?}"                                 "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__IRAM:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__IRAM:?}"                     "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__VLNZ:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__VLNZ:?}"                     "${__CDFS:?}"/LiveOS
	[[ -e "${__RTFS:?}/${__IRAM:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__IRAM:?}"                     "${__CDFS:?}"/LiveOS/initrd.img
	[[ -e "${__RTFS:?}/${__VLNZ:?}"                     ]] && cp --preserve=timestamps             "${__RTFS:?}/${__VLNZ:?}"                     "${__CDFS:?}"/LiveOS/vmlinuz
	[[ -e "${__RTFS:?}"/usr/lib/ISOLINUX/isolinux.bin   ]] && cp --preserve=timestamps             "${__RTFS:?}"/usr/lib/ISOLINUX/isolinux.bin   "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/syslinux/mbr/gptmbr.bin ]] && cp --preserve=timestamps             "${__RTFS:?}"/usr/lib/syslinux/mbr/gptmbr.bin "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/syslinux/modules/bios/. ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/syslinux/modules/bios/. "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/lib/grub/x86_64-efi/.       ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/grub/x86_64-efi/.       "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__RTFS:?}"/usr/lib/grub/i386-pc/.          ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/lib/grub/i386-pc/.          "${__CDFS:?}"/boot/grub/i386-pc
	[[ -e "${__RTFS:?}"/usr/share/syslinux/.            ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/syslinux/.            "${__CDFS:?}"/isolinux
	[[ -e "${__RTFS:?}"/usr/share/grub2/x86_64-efi/.    ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/grub2/x86_64-efi/.    "${__CDFS:?}"/boot/grub/x86_64-efi
	[[ -e "${__RTFS:?}"/usr/share/grub2/i386-pc/.       ]] && cp --preserve=timestamps --recursive "${__RTFS:?}"/usr/share/grub2/i386-pc/.       "${__CDFS:?}"/boot/grub/i386-pc
	           __ETRI="$(find "${__CDFS:?}"/isolinux -name 'eltorito.sys' -print -quit)"
	__ETRI="${__ETRI:-"$(find "${__CDFS:?}"/isolinux -name 'isolinux.bin' -print -quit)"}"
	           __BIOS="$(find "${__CDFS:?}"/isolinux -name 'gptmbr.bin'   -print -quit)"
	__BIOS="${__BIOS:-"${__MBRF}"}"
	__ETRI="${__ETRI#"${__CDFS:-}/"}"
	__BIOS="${__BIOS#"${__CDFS:?}/"}"
	# --- add boot parameter (security) ---------------------------------------
#	  if [[ -e "${__RTFS:?}"/usr/bin/aa-enabled ]];  then __SECR="security=apparmor apparmor=1"
#	elif [[ -e "${__RTFS:?}"/usr/sbin/getenforce ]]; then __SECR="security=selinux selinux=1 enforcing=0"
#	else                                                  __SECR=""
#	fi
	__SECR=""
	[[ -e "${__RTFS:?}"/usr/bin/aa-enabled  ]] && __SECR="${__SECR:+"${__SECR} "}apparmor=1"
	[[ -e "${__RTFS:?}"/usr/sbin/getenforce ]] && __SECR="${__SECR:+"${__SECR} "}selinux=1 enforcing=0"
	# --- splash.png ----------------------------------------------------------
	__SPLS="${__CDFS}/isolinux/splash.png"
	mkdir -p "${__SPLS%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -p -r | gzip -d -k > "${__OUTD}/${__SPLS##*/}"
		1f8b0808462b8d69000373706c6173682e706e6700eb0cf073e7e592e262
		6060e0f5f47009626060566060608ae060028a888a88aa3330b0767bba38
		8654dc7a7b909117287868c177ff5c3ef3050ca360148c8251300ae8051a
		c299ff4c6660bcb6edd00b10d7d3d5cf659d53421300e6198186c4050000
_EOT_
	cp --preserve=timestamps "${__OUTD}/${__SPLS##*/}" "${__SPLS}"
	__SPLS="${__SPLS#"${__CDFS}"}"
	# --- /EFI/BOOT/grub.cfg --------------------------------------------------
	__TITL="$(printf "%s%s" "${__ISOS##*/}" "${__DATE:+" ${__DATE}"}")"
	__PATH="${__CDFS}"/EFI/BOOT/grub.cfg
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__PATH##*/}"
		search --file --set=root /.disk/info
		set prefix=(\$root)/boot/grub
		source \$prefix/grub.cfg
	_EOT_
	cp --preserve=timestamps "${__OUTD}/${__PATH##*/}" "${__PATH}"
	# --- /boot/grub/grub.cfg -------------------------------------------------
	__PATH="${__CDFS}"/boot/grub/grub.cfg
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__PATH##*/}"
		set default="0"
		set timeout="5"

		if [ "x\${font}" = "x" ] ; then
		  if [ "x\${feature_default_font_path}" = "xy" ] ; then
		    font="unicode"
		  else
		    font="\${prefix}/fonts/font.pf2"
		  fi
		fi
		export font

		if loadfont "\$font" ; then
		# set lang="ja_JP"
		# export lang
		  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
		  set gfxpayload="keep"
		  export gfxmode
		  export gfxpayload
		  if [ "\${grub_platform}" = "efi" ]; then
		    insmod efi_gop
		    insmod efi_uga
		  else
		    insmod vbe
		    insmod vga
		  fi
		  insmod video_bochs
		  insmod video_cirrus
		  insmod gfxterm
		  insmod gettext
		  insmod png
		  terminal_output gfxterm
		fi

		#set timeout_style=menu
		#set color_normal=light-gray/black
		#set color_highlight=white/dark-gray
		#export color_normal
		#export color_highlight

		set theme=/boot/grub/theme.cfg
		export theme

		insmod play
		play 960 440 1 0 4 440 1

		menuentry "Live system (amd64)" --hotkey=l {
		  set gfxpayload="keep"
		  set background_color="black"
		  set options="root=live:CDLABEL=${__VLID} rd.live.image rd.live.overlay.overlayfs=1${__SECR:+" ${__SECR}"}"
		  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
		  echo 'Loading boot files ...'
		  linux  /LiveOS/${__VLNZ##*/} \${options} --- quiet
		  initrd /LiveOS/${__IRAM##*/}
		}
_EOT_
	cp --preserve=timestamps "${__OUTD}/${__PATH##*/}" "${__PATH}"
	# --- /boot/grub/theme.cfg ------------------------------------------------
	__PATH="${__CDFS}"/boot/grub/theme.cfg
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__PATH##*/}"
		${__SPLS:+"desktop-image: \"${__SPLS}\""}
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		${__TITL:+"title-text: \"Boot Menu: ${__TITL}"\"}
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
	cp --preserve=timestamps "${__OUTD}/${__PATH##*/}" "${__PATH}"
	# --- /isolinux/isolinux.cfg ----------------------------------------------
	__PATH="${__CDFS}"/isolinux/isolinux.cfg
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__OUTD}/${__PATH##*/}"
		path ./
		prompt 0
		#timeout 0
		default vesamenu.c32

		menu clear
		${__SPLS:+"menu background ${__SPLS}"}
		${__TITL:+"menu title Boot Menu: ${__TITL}"}

		# MENU COLOR <Item>  <ANSI Seq.> <foreground> <background> <shadow type>
		menu color   screen       *       #80ffffff    #00000000         *       # background colour not covered by the splash image
		menu color   border       *       #ffffffff    #ee000000         *       # The wire-frame border
		menu color   title        *       #ffff3f7f    #ee000000         *       # Menu title text
		menu color   sel          *       #ff00dfdf    #ee000000         *       # Selected menu option
		menu color   hotsel       *       #ff7f7fff    #ee000000         *       # The selected hotkey (set with ^ in MENU LABEL)
		menu color   unsel        *       #ffffffff    #ee000000         *       # Unselected menu options
		menu color   hotkey       *       #ff7f7fff    #ee000000         *       # Unselected hotkeys (set with ^ in MENU LABEL)
		menu color   tabmsg       *       #c07f7fff    #00000000         *       # Tab text
		menu color   timeout_msg  *       #8000dfdf    #00000000         *       # Timout text
		menu color   timeout      *       #c0ff3f7f    #00000000         *       # Timout counter
		menu color   disabled     *       #807f7f7f    #ee000000         *       # Disabled menu options, including SEPARATORs
		menu color   cmdmark      *       #c000ffff    #ee000000         *       # Command line marker - The '> ' on the left when editing an option
		menu color   cmdline      *       #c0ffffff    #ee000000         *       # Command line - The text being edited
		menu color   scrollbar    *       #40000000    #00000000         *       # Scroll bar
		menu color   pwdborder    *       #80ffffff    #20ffffff         *       # Password box wire-frame border
		menu color   pwdheader    *       #80ff8080    #20ffffff         *       # Password box header
		menu color   pwdentry     *       #80ffffff    #20ffffff         *       # Password entry field
		menu color   help         *       #c0ffffff    #00000000         *       # Help text, if set via 'TEXT HELP ... ENDTEXT'

		menu margin               2
		menu vshift               3
		menu rows                12
		menu tabmsgrow           28
		menu cmdlinerow          24
		menu timeoutrow          26
		menu helpmsgrow          22
		menu hekomsgendrow       38

		menu tabmsg Press ENTER to boot or TAB to edit a menu entry

		timeout 50
		#default auto-install

		label live-amd64
		  menu label ^Live system (amd64)
		  menu default
		  linux  /LiveOS/vmlinuz
		  initrd /LiveOS/initrd.img
		  append root=live:CDLABEL=${__VLID} rd.live.image rd.live.overlay.overlayfs=1${__SECR:+" ${__SECR}"} --- quiet
_EOT_
	cp --preserve=timestamps "${__OUTD}/${__PATH##*/}" "${__PATH}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# --- xorrisofs ---------------------------------------------------------------
function fnMk_xorrisofs() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r -a __COMD=(
		-rational-rock
		${__VLID:+-volid "${__VLID}"}
		-joliet -joliet-long
		-full-iso9660-filenames -iso-level 3
		-partition_offset 16
		${__BIOS:+--grub2-mbr "${__BIOS}"}
		--mbr-force-bootable
		-append_partition 2 0xEF "boot/grub/${__UEFI##*/}"
		-appended_part_as_gpt
		${__BCAT:+-eltorito-catalog "isolinux/${__BCAT##*/}"}
		${__ETRI:+-eltorito-boot "${__ETRI}"}
		-no-emul-boot
		-boot-load-size 4 -boot-info-table
		--grub2-boot-info
		-eltorito-alt-boot -e '--interval:appended_partition_2:all::'
		-no-emul-boot
		-output "${__ISOS:?}"
		.
	)

	printf "%-10.10s: [%s]\n" "__ISOS" "${__ISOS:-}"
	printf "%-10.10s: [%s]\n" "__VLID" "${__VLID:-}"
	printf "%-10.10s: [%s]\n" "__BIOS" "${__BIOS:-}"
	printf "%-10.10s: [%s]\n" "__ETRI" "${__ETRI:-}"
	printf "%-10.10s: [%s]\n" "__UEFI" "${__UEFI:-}"
	printf "%-10.10s: [%s]\n" "__BCAT" "${__BCAT:-}"
set -x
	pushd "${__CDFS:?}" > /dev/null 2>&1
	if ! xorrisofs "${__COMD[@]}"; then
		__RTCD="$?"
		printf "%s\n" "xorrisofs ${__COMD[*]}"
		exit "${__RTCD}"
	fi
	popd > /dev/null 2>&1
set +x
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

# shellcheck disable=SC2329,SC2317
function fnTrap() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"
	rm -rf "${__TEMP:?}"
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}

trap fnTrap EXIT

case "${__OPRT:-}" in
	build)	fnMk_mkosi_build
			fnMk_mount_fs
			fnMk_find_kernel
			fnMk_vm_setup
			fnMk_qemu
			fnMk_mksquashfs
			fnMk_uefi
			fnMk_cdfs
			fnMk_xorrisofs
			fnMk_umount_fs
			;;
	*)		fnMk_mkosi_summary
			;;
esac

#rm -rf "${__TEMP:?}"

exit 0

# memo
# https://man.archlinux.org/man/mkosi.1.en
# https://wiki.archlinux.jp/index.php/Dracut
#
# sudo find / \( -path '/srv' -o -path '/boot' -o -path '/proc' -o -path '/sys' \) -prune -o -size +10M -printf "%10s %p\n" | sort -r