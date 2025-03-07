#!/bin/bash
###############################################################################
##
##	chroot environment creation shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/03/05
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/03/05 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# *** initialization **********************************************************

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# -------------------------------------------------------------------------
	CODE_NAME="$(sed -ne '/VERSION_CODENAME/ s/^.*=//p' /etc/os-release)"
	readonly      CODE_NAME

#	if command -v apt-get > /dev/null 2>&1; then
#		if ! ls /var/lib/apt/lists/*_"${CODE_NAME:-}"_InRelease > /dev/null 2>&1; then
#			echo "please execute apt-get update:"
#			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
#				echo -n "sudo "
#			fi
#			echo "apt-get update"
#			exit 1
#		fi
#		# ---------------------------------------------------------------------
#		MAIN_ARHC="$(dpkg --print-architecture)"
#		readonly      MAIN_ARHC
#		OTHR_ARCH="$(dpkg --print-foreign-architectures)"
#		readonly      OTHR_ARCH
#		declare -r -a PAKG_LIST=(\
#			mmdebstrap \
#		)
#		PAKG_FIND="$(LANG=C apt list "${PAKG_LIST[@]}" 2> /dev/null | sed -ne '/[ \t]'"${OTHR_ARCH:-"i386"}"'[ \t]*/!{' -e '/\[.*\(WARNING\|Listing\|installed\|upgradable\).*\]/! s%/.*%%gp}' | sed -z 's/[\r\n]\+/ /g')"
#		readonly      PAKG_FIND
#		if [[ -n "${PAKG_FIND% *}" ]]; then
#			echo "please install these:"
#			if [[ "${0:-}" = "${SUDO_COMMAND:-}" ]]; then
#				echo -n "sudo "
#			fi
#			echo "apt-get install ${PAKG_FIND% *}"
#			exit 1
#		fi
#	fi

# *** data section ************************************************************

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
	declare -r -a PROG_PARM=("${@:-}")
	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/Image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- directory list ------------------------------------------------------
	declare -r -a LIST_DIRS=(                                                                                           \
		"${DIRS_TOPS}"                                                                                                  \
		"${DIRS_HGFS}"                                                                                                  \
		"${DIRS_HTML}"                                                                                                  \
		"${DIRS_SAMB}"/{cifs,data/{adm/{netlogon,profiles},arc,bak,pub,usr},dlna/{movies,others,photos,sounds}}         \
		"${DIRS_TFTP}"/{boot/grub/{fonts,i386-{efi,pc},locale,x86_64-efi},ipxe,load,menu-{bios,efi64}/pxelinux.cfg}     \
		"${DIRS_USER}"                                                                                                  \
		"${DIRS_SHAR}"/{conf,imgs,isos,load,rmak}                                                                       \
		"${DIRS_CONF}"/{_keyring,_template,autoyast,kickstart,nocloud,preseed,script,windows}                           \
		"${DIRS_KEYS}"                                                                                                  \
		"${DIRS_TMPL}"                                                                                                  \
		"${DIRS_IMGS}"                                                                                                  \
		"${DIRS_ISOS}"                                                                                                  \
		"${DIRS_LOAD}"                                                                                                  \
		"${DIRS_RMAK}"                                                                                                  \
	)

	# --- symbolic link list --------------------------------------------------
	declare -r -a LIST_LINK=(                                                                                           \
		"a  ${DIRS_CONF}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_IMGS}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_ISOS}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_LOAD}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_RMAK}                                    ${DIRS_HTML}/"                                              \
		"a  ${DIRS_IMGS}                                    ${DIRS_TFTP}/"                                              \
		"a  ${DIRS_ISOS}                                    ${DIRS_TFTP}/"                                              \
		"a  ${DIRS_LOAD}                                    ${DIRS_TFTP}/"                                              \
		"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-bios/"                                    \
		"r  ${DIRS_TFTP}/menu-bios/syslinux.cfg             ${DIRS_TFTP}/menu-bios/pxelinux.cfg/default"                \
		"r  ${DIRS_TFTP}/${DIRS_IMGS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/${DIRS_ISOS##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/${DIRS_LOAD##*/}                   ${DIRS_TFTP}/menu-efi64/"                                   \
		"r  ${DIRS_TFTP}/menu-efi64/syslinux.cfg            ${DIRS_TFTP}/menu-efi64/pxelinux.cfg/default"               \
		"a  ${HGFS_DIRS}/linux/bin/conf                     ${DIRS_CONF}"                                               \
		"a  ${HGFS_DIRS}/linux/bin/rmak                     ${DIRS_RMAK}"                                               \
	) #	0:r	1:target										2:symlink

	# --- set minimum display size --------------------------------------------
	declare -i    ROWS_SIZE=80
	declare -i    COLS_SIZE=25
	declare       TEXT_GAP1=""
	declare       TEXT_GAP2=""

	# --- niceness values -----------------------------------------------------
	declare -r -i NICE_VALU=19								# -20: favorable to the process
															#  19: least favorable to the process
	declare -r -i IONICE_CLAS=3								#   1: Realtime
															#   2: Best-effort
															#   3: Idle
#	declare -r -i IONICE_VALU=7								#   0: favorable to the process
															#   7: least favorable to the process

	# === system ==============================================================

	# --- media information ---------------------------------------------------
	#  0: [m] menu / [o] output / [else] hidden
	#  1: Distribution-Version.
	#  2: Entry Name.
	#  3: Code Name
	#  4: Life
	#  5: Release date
	#  6: End of support
	#  7: Long term
	#  8: RHEL release
	#  9: Kernel
	# 10: Note

	declare -r -a DATA_LIST=(                                                                                                                                                       \
		"x  debian-1.1              Debian%201.1            buzz                    EOL     1996-06-17  -           -           -           -                   -               "   \
		"x  debian-1.2              Debian%201.2            rex                     EOL     1996-12-12  -           -           -           -                   -               "   \
		"x  debian-1.3              Debian%201.3            bo                      EOL     1997-06-05  -           -           -           -                   -               "   \
		"x  debian-2.0              Debian%202.0            hamm                    EOL     1998-07-24  -           -           -           -                   -               "   \
		"x  debian-2.1              Debian%202.1            slink                   EOL     1999-03-09  2000-10-30  -           -           -                   -               "   \
		"x  debian-2.2              Debian%202.2            potato                  EOL     2000-08-15  2003-06-30  -           -           -                   -               "   \
		"x  debian-3.0              Debian%203.0            woody                   EOL     2002-07-19  2006-06-30  -           -           -                   -               "   \
		"x  debian-3.1              Debian%203.1            sarge                   EOL     2005-06-06  2008-03-31  -           -           -                   -               "   \
		"x  debian-4.0              Debian%204.0            etch                    EOL     2007-04-08  2010-02-15  -           -           -                   -               "   \
		"x  debian-5.0              Debian%205.0            lenny                   EOL     2009-02-14  2012-02-06  -           -           -                   -               "   \
		"x  debian-6.0              Debian%206.0            squeeze                 EOL     2011-02-06  2014-05-31  2016-02-29  -           -                   -               "   \
		"x  debian-7.0              Debian%207.0            wheezy                  EOL     2013-05-04  2016-04-25  2018-05-31  -           -                   -               "   \
		"x  debian-8.0              Debian%208.0            jessie                  EOL     2015-04-25  2018-06-17  2020-06-30  -           -                   -               "   \
		"x  debian-9.0              Debian%209.0            stretch                 EOL     2017-06-17  2020-07-18  2022-06-30  -           -                   -               "   \
		"x  debian-10.0             Debian%2010.0           buster                  EOL     2019-07-06  2022-09-10  2024-06-30  -           -                   oldoldstable    "   \
		"o  debian-11.0             Debian%2011.0           bullseye                LTS     2021-08-14  2024-08-15  2026-08-31  -           5.10                oldstable       "   \
		"o  debian-12.0             Debian%2012.0           bookworm                -       2023-06-10  2026-06-xx  2028-06-xx  -           6.1                 stable          "   \
		"o  debian-13.0             Debian%2013.0           trixie                  -       2025-xx-xx  20xx-xx-xx  20xx-xx-xx  -           -                   testing         "   \
		"-  debian-14.0             Debian%2014.0           forky                   -       2027-xx-xx  20xx-xx-xx  20xx-xx-xx  -           -                   -               "   \
		"-  debian-15.0             Debian%2015.0           duke                    -       20xx-xx-xx  20xx-xx-xx  20xx-xx-xx  -           -                   -               "   \
		"o  debian-testing          Debian%20testing        testing                 -       20xx-xx-xx  20xx-xx-xx  20xx-xx-xx  -           -                   -               "   \
		"x  ubuntu-4.10             Ubuntu%204.10           Warty%20Warthog         EOL     2004-10-20  2006-04-30  -           -           2.6.8               -               "   \
		"x  ubuntu-5.04             Ubuntu%205.04           Hoary%20Hedgehog        EOL     2005-04-08  2006-10-31  -           -           2.6.10              -               "   \
		"x  ubuntu-5.10             Ubuntu%205.10           Breezy%20Badger         EOL     2005-10-12  2007-04-13  -           -           2.6.12              -               "   \
		"x  ubuntu-6.06             Ubuntu%206.06           Dapper%20Drake          EOL     2006-06-01  2009-07-14  2011-06-01  -           2.6.15              -               "   \
		"x  ubuntu-6.10             Ubuntu%206.10           Edgy%20Eft              EOL     2006-10-26  2008-04-25  -           -           2.6.17              -               "   \
		"x  ubuntu-7.04             Ubuntu%207.04           Feisty%20Fawn           EOL     2007-04-19  2008-10-19  -           -           2.6.20              -               "   \
		"x  ubuntu-7.10             Ubuntu%207.10           Gutsy%20Gibbon          EOL     2007-10-18  2009-04-18  -           -           2.6.22              -               "   \
		"x  ubuntu-8.04             Ubuntu%208.04           Hardy%20Heron           EOL     2008-04-24  2011-05-12  2013-05-09  -           2.6.24              -               "   \
		"x  ubuntu-8.10             Ubuntu%208.10           Intrepid%20Ibex         EOL     2008-10-30  2010-04-30  -           -           2.6.27              -               "   \
		"x  ubuntu-9.04             Ubuntu%209.04           Jaunty%20Jackalope      EOL     2009-04-23  2010-10-23  -           -           2.6.28              -               "   \
		"x  ubuntu-9.10             Ubuntu%209.10           Karmic%20Koala          EOL     2009-10-29  2011-04-30  -           -           2.6.31              -               "   \
		"x  ubuntu-10.04            Ubuntu%2010.04          Lucid%20Lynx            EOL     2010-04-29  2013-05-09  2015-04-30  -           2.6.32              -               "   \
		"x  ubuntu-10.10            Ubuntu%2010.10          Maverick%20Meerkat      EOL     2010-10-10  2012-04-10  -           -           2.6.35              -               "   \
		"x  ubuntu-11.04            Ubuntu%2011.04          Natty%20Narwhal         EOL     2011-04-28  2012-10-28  -           -           2.6.38              -               "   \
		"x  ubuntu-11.10            Ubuntu%2011.10          Oneiric%20Ocelot        EOL     2011-10-13  2013-05-09  -           -           3.0                 -               "   \
		"x  ubuntu-12.04            Ubuntu%2012.04          Precise%20Pangolin      EOL     2012-04-26  2017-04-28  2019-04-26  -           3.2                 -               "   \
		"x  ubuntu-12.10            Ubuntu%2012.10          Quantal%20Quetzal       EOL     2012-10-18  2014-05-16  -           -           3.5                 -               "   \
		"x  ubuntu-13.04            Ubuntu%2013.04          Raring%20Ringtail       EOL     2013-04-25  2014-01-27  -           -           3.8                 -               "   \
		"x  ubuntu-13.10            Ubuntu%2013.10          Saucy%20Salamander      EOL     2013-10-17  2014-07-17  -           -           3.11                -               "   \
		"x  ubuntu-14.04            Ubuntu%2014.04          Trusty%20Tahr           EOL     2014-04-17  2019-04-25  2024-04-25  -           3.13                -               "   \
		"x  ubuntu-14.10            Ubuntu%2014.10          Utopic%20Unicorn        EOL     2014-10-23  2015-07-23  -           -           3.16                -               "   \
		"x  ubuntu-15.04            Ubuntu%2015.04          Vivid%20Vervet          EOL     2015-04-23  2016-02-04  -           -           3.19                -               "   \
		"x  ubuntu-15.10            Ubuntu%2015.10          Wily%20Werewolf         EOL     2015-10-22  2016-07-28  -           -           4.2                 -               "   \
		"-  ubuntu-16.04            Ubuntu%2016.04          Xenial%20Xerus          LTS     2016-04-21  2021-04-30  2026-04-23  -           4.4                 -               "   \
		"x  ubuntu-16.10            Ubuntu%2016.10          Yakkety%20Yak           EOL     2016-10-13  2017-07-20  -           -           4.8                 -               "   \
		"x  ubuntu-17.04            Ubuntu%2017.04          Zesty%20Zapus           EOL     2017-04-13  2018-01-13  -           -           4.10                -               "   \
		"x  ubuntu-17.10            Ubuntu%2017.10          Artful%20Aardvark       EOL     2017-10-19  2018-07-19  -           -           4.13                -               "   \
		"-  ubuntu-18.04            Ubuntu%2018.04          Bionic%20Beaver         LTS     2018-04-26  2023-05-31  2028-04-26  -           4.15                -               "   \
		"x  ubuntu-18.10            Ubuntu%2018.10          Cosmic%20Cuttlefish     EOL     2018-10-18  2019-07-18  -           -           4.18                -               "   \
		"x  ubuntu-19.04            Ubuntu%2019.04          Disco%20Dingo           EOL     2019-04-18  2020-01-23  -           -           5.0                 -               "   \
		"x  ubuntu-19.10            Ubuntu%2019.10          Eoan%20Ermine           EOL     2019-10-17  2020-07-17  -           -           5.3                 -               "   \
		"o  ubuntu-20.04            Ubuntu%2020.04          Focal%20Fossa           -       2020-04-23  2025-05-29  2030-04-23  -           5.4                 -               "   \
		"x  ubuntu-20.10            Ubuntu%2020.10          Groovy%20Gorilla        EOL     2020-10-22  2021-07-22  -           -           5.8                 -               "   \
		"x  ubuntu-21.04            Ubuntu%2021.04          Hirsute%20Hippo         EOL     2021-04-22  2022-01-20  -           -           5.11                -               "   \
		"x  ubuntu-21.10            Ubuntu%2021.10          Impish%20Indri          EOL     2021-10-14  2022-07-14  -           -           5.13                -               "   \
		"o  ubuntu-22.04            Ubuntu%2022.04          Jammy%20Jellyfish       -       2022-04-21  2027-06-01  2032-04-21  -           5.15/5.17           -               "   \
		"x  ubuntu-22.10            Ubuntu%2022.10          Kinetic%20Kudu          EOL     2022-10-20  2023-07-20  -           -           5.19                -               "   \
		"x  ubuntu-23.04            Ubuntu%2023.04          Lunar%20Lobster         EOL     2023-04-20  2024-01-25  -           -           6.2                 -               "   \
		"x  ubuntu-23.10            Ubuntu%2023.10          Mantic%20Minotaur       EOL     2023-10-12  2024-07-11  -           -           6.5                 -               "   \
		"o  ubuntu-24.04            Ubuntu%2024.04          Noble%20Numbat          -       2024-04-25  2029-05-31  2034-04-25  -           6.8                 -               "   \
		"o  ubuntu-24.10            Ubuntu%2024.10          Oracular%20Oriole       -       2024-10-10  2025-07-xx  -           -           6.11                -               "   \
		"o  ubuntu-25.04            Ubuntu%2025.04          Plucky%20Puffin         -       2025-04-17  2026-01-xx  -           -           -                   -               "   \
		"x  fedora-27               Fedora%2027             -                       EOL     2017-11-14  2018-11-30  -           -           4.13                -               "   \
		"x  fedora-28               Fedora%2028             -                       EOL     2018-05-01  2019-05-28  -           -           4.16                -               "   \
		"x  fedora-29               Fedora%2029             -                       EOL     2018-10-30  2019-11-26  -           -           4.18                -               "   \
		"x  fedora-30               Fedora%2030             -                       EOL     2019-04-30  2020-05-26  -           -           5.0                 -               "   \
		"x  fedora-31               Fedora%2031             -                       EOL     2019-10-29  2020-11-24  -           -           5.3                 -               "   \
		"x  fedora-32               Fedora%2032             -                       EOL     2020-04-28  2021-05-25  -           -           5.6                 -               "   \
		"x  fedora-33               Fedora%2033             -                       EOL     2020-10-27  2021-11-30  -           -           5.8                 -               "   \
		"x  fedora-34               Fedora%2034             -                       EOL     2021-04-27  2022-06-07  -           -           5.11                -               "   \
		"x  fedora-35               Fedora%2035             -                       EOL     2021-11-02  2022-12-13  -           -           5.14                -               "   \
		"x  fedora-36               Fedora%2036             -                       EOL     2022-05-10  2023-05-16  -           -           5.17                -               "   \
		"x  fedora-37               Fedora%2037             -                       EOL     2022-11-15  2023-12-05  -           -           6.0                 -               "   \
		"x  fedora-38               Fedora%2038             -                       EOL     2023-04-18  2024-05-21  -           -           6.2                 -               "   \
		"x  fedora-39               Fedora%2039             -                       EOL     2023-11-07  2024-11-26  -           -           6.5                 -               "   \
		"o  fedora-40               Fedora%2040             -                       -       2024-04-23  2025-05-28  -           -           6.8                 -               "   \
		"o  fedora-41               Fedora%2041             -                       -       2024-10-29  2025-11-19  -           -           6.11                -               "   \
		"o  fedora-42               Fedora%2042             -                       -       2025-04-22  2026-05-13  -           -           -                   -               "   \
		"-  fedora-43               Fedora%2043             -                       -       2025-11-11  2026-12-02  -           -           -                   -               "   \
		"x  centos-stream-8         Centos%20stream%208     -                       EOL     2019-09-24  2024-05-31  -           -           4.18.0              -               "   \
		"o  centos-stream-9         Centos%20stream%209     -                       -       2021-12-03  2027-05-31  -           -           5.14.0              -               "   \
		"o  centos-stream-10        Centos%20stream%2010    -                       -       2024-12-12  2030-01-01  -           -           6.12.0              -               "   \
		"x  almalinux-8.3           Almalinux%208.3         -                       EOL     2021-03-30  -           -           2020-11-03  4.18.0-240          -               "   \
		"x  almalinux-8.4           Almalinux%208.4         -                       EOL     2021-05-26  -           -           2021-05-18  4.18.0-305          -               "   \
		"x  almalinux-8.5           Almalinux%208.5         -                       EOL     2021-11-12  -           -           2021-11-09  4.18.0-348          -               "   \
		"x  almalinux-8.6           Almalinux%208.6         -                       EOL     2022-05-12  -           -           2022-05-10  4.18.0-372          -               "   \
		"x  almalinux-8.7           Almalinux%208.7         -                       EOL     2022-11-10  -           -           2022-11-09  4.18.0-425          -               "   \
		"x  almalinux-8.8           Almalinux%208.8         -                       EOL     2023-05-18  -           -           2023-05-16  4.18.0-477          -               "   \
		"x  almalinux-8.9           Almalinux%208.9         -                       EOL     2023-11-21  -           -           2023-11-14  4.18.0-513.5.1      -               "   \
		"o  almalinux-8.10          Almalinux%208.10        -                       -       2024-05-28  -           -           2024-05-22  4.18.0-553          -               "   \
		"x  almalinux-9.0           Almalinux%209.0         -                       EOL     2022-05-26  -           -           2022-05-17  5.14.0-70.13.1      -               "   \
		"x  almalinux-9.1           Almalinux%209.1         -                       EOL     2022-11-17  -           -           2022-11-15  5.14.0-162.6.1      -               "   \
		"x  almalinux-9.2           Almalinux%209.2         -                       EOL     2023-05-10  -           -           2023-05-10  5.14.0-284.11.1     -               "   \
		"x  almalinux-9.3           Almalinux%209.3         -                       EOL     2023-11-13  -           -           2023-11-07  5.14.0-362.8.1      -               "   \
		"x  almalinux-9.4           Almalinux%209.4         -                       EOL     2024-05-06  -           -           2024-04-30  5.14.0-427.13.1     -               "   \
		"o  almalinux-9.5           Almalinux%209.5         -                       -       2024-11-18  -           -           2024-11-13  5.14.0-503.11.1     -               "   \
		"x  rockylinux-8.3          Rockylinux%208.3        -                       EOL     2021-05-01  -           -           2020-11-03  4.18.0-240          -               "   \
		"x  rockylinux-8.4          Rockylinux%208.4        -                       EOL     2021-06-21  -           -           2021-05-18  4.18.0-305          -               "   \
		"x  rockylinux-8.5          Rockylinux%208.5        -                       EOL     2021-11-15  -           -           2021-11-09  4.18.0-348          -               "   \
		"x  rockylinux-8.6          Rockylinux%208.6        -                       EOL     2022-05-16  -           -           2022-05-10  4.18.0-372.9.1      -               "   \
		"x  rockylinux-8.7          Rockylinux%208.7        -                       EOL     2022-11-14  -           -           2022-11-09  4.18.0-425.3.1      -               "   \
		"x  rockylinux-8.8          Rockylinux%208.8        -                       EOL     2023-05-20  -           -           2023-05-16  4.18.0-477.10.1     -               "   \
		"x  rockylinux-8.9          Rockylinux%208.9        -                       EOL     2023-11-22  -           -           2023-11-14  4.18.0-513.5.1      -               "   \
		"o  rockylinux-8.10         Rockylinux%208.10       -                       -       2024-05-30  -           -           2024-05-22  4.18.0-553          -               "   \
		"x  rockylinux-9.0          Rockylinux%209.0        -                       EOL     2022-07-14  -           -           2022-05-17  5.14.0-70.13.1      -               "   \
		"x  rockylinux-9.1          Rockylinux%209.1        -                       EOL     2022-11-26  -           -           2022-11-15  5.14.0-162.6.1      -               "   \
		"x  rockylinux-9.2          Rockylinux%209.2        -                       EOL     2023-05-16  -           -           2023-05-10  5.14.0-284.11.1     -               "   \
		"x  rockylinux-9.3          Rockylinux%209.3        -                       EOL     2023-11-20  -           -           2023-11-07  5.14.0-362.8.1      -               "   \
		"x  rockylinux-9.4          Rockylinux%209.4        -                       EOL     2024-05-09  -           -           2024-04-30  5.14.0-427.13.1     -               "   \
		"o  rockylinux-9.5          Rockylinux%209.5        -                       -       2024-11-19  -           -           2024-11-12  5.14.0-503.14.1     -               "   \
		"x  miraclelinux-8.4        Miraclelinux%208.4      -                       EOL     2021-10-04  -           -           2021-05-18  4.18.0-305.el8      -               "   \
		"x  miraclelinux-8.6        Miraclelinux%208.6      -                       EOL     2022-11-01  -           -           2022-05-10  4.18.0-372.el8      -               "   \
		"o  miraclelinux-8.8        Miraclelinux%208.8      -                       -       2023-10-05  -           -           2023-05-16  4.18.0-477.el8      -               "   \
		"x  miraclelinux-9.0        Miraclelinux%209.0      -                       EOL     2022-11-01  -           -           2022-05-17  5.14.0-70.el9       -               "   \
		"o  miraclelinux-9.2        Miraclelinux%209.2      -                       -       2023-10-05  -           -           2023-05-10  5.14.0-284.el9      -               "   \
		"x  opensuse-leap-15.0      Opensuse%20leap%2015.0  -                       EOL     2018-05-25  2019-12-03  -           -           4.12                -               "   \
		"x  opensuse-leap-15.1      Opensuse%20leap%2015.1  -                       EOL     2019-05-22  2021-01-31  -           -           4.12                -               "   \
		"x  opensuse-leap-15.2      Opensuse%20leap%2015.2  -                       EOL     2020-07-02  2021-12-31  -           -           5.3.18              -               "   \
		"x  opensuse-leap-15.3      Opensuse%20leap%2015.3  -                       EOL     2021-06-02  2022-12-31  -           -           5.3.18              -               "   \
		"x  opensuse-leap-15.4      Opensuse%20leap%2015.4  -                       EOL     2022-06-08  2023-12-31  -           -           5.14.21             -               "   \
		"x  opensuse-leap-15.5      Opensuse%20leap%2015.5  -                       EOL     2023-06-07  2024-12-31  -           -           5.14.21             -               "   \
		"o  opensuse-leap-15.6      Opensuse%20leap%2015.6  -                       -       2024-06-12  2025-12-31  -           -           6.4                 -               "   \
		"-  opensuse-leap-16.0      Opensuse%20leap%2016.0  -                       -       2025-11-xx  20xx-xx-xx  -           -           -                   -               "   \
		"o  opensuse-tumbleweed     Opensuse%20tumbleweed   -                       -       2014-11-xx  20xx-xx-xx  -           -           -                   -               "   \
	)	#0: 1:Version.              2:EntryName.            3:CodeName              4:Life  5:Release   6:EOS       7:LTS       8:RHEL      9:Kernel            10:Note         

# *** function section (common functions) *************************************

# --- set color ---------------------------------------------------------------
#	declare -r    ESC="$(printf '\033')"
	declare -r    ESC=$'\033'
	declare -r    TXT_RESET="${ESC}[m"						# reset all attributes
	declare -r    TXT_ULINE="${ESC}[4m"						# set underline
	declare -r    TXT_ULINERST="${ESC}[24m"					# reset underline
	declare -r    TXT_REV="${ESC}[7m"						# set reverse display
	declare -r    TXT_REVRST="${ESC}[27m"					# reset reverse display
	declare -r    TXT_BLACK="${ESC}[90m"					# text black
	declare -r    TXT_RED="${ESC}[91m"						# text red
	declare -r    TXT_GREEN="${ESC}[92m"					# text green
	declare -r    TXT_YELLOW="${ESC}[93m"					# text yellow
	declare -r    TXT_BLUE="${ESC}[94m"						# text blue
	declare -r    TXT_MAGENTA="${ESC}[95m"					# text purple
	declare -r    TXT_CYAN="${ESC}[96m"						# text light blue
	declare -r    TXT_WHITE="${ESC}[97m"					# text white
	declare -r    TXT_BBLACK="${ESC}[40m"					# text reverse black
	declare -r    TXT_BRED="${ESC}[41m"						# text reverse red
	declare -r    TXT_BGREEN="${ESC}[42m"					# text reverse green
	declare -r    TXT_BYELLOW="${ESC}[43m"					# text reverse yellow
	declare -r    TXT_BBLUE="${ESC}[44m"					# text reverse blue
	declare -r    TXT_BMAGENTA="${ESC}[45m"					# text reverse purple
	declare -r    TXT_BCYAN="${ESC}[46m"					# text reverse light blue
	declare -r    TXT_BWHITE="${ESC}[47m"					# text reverse white
	declare -r    TXT_DBLACK="${ESC}[30m"					# text dark black
	declare -r    TXT_DRED="${ESC}[31m"						# text dark red
	declare -r    TXT_DGREEN="${ESC}[32m"					# text dark green
	declare -r    TXT_DYELLOW="${ESC}[33m"					# text dark yellow
	declare -r    TXT_DBLUE="${ESC}[34m"					# text dark blue
	declare -r    TXT_DMAGENTA="${ESC}[35m"					# text dark purple
	declare -r    TXT_DCYAN="${ESC}[36m"					# text dark light blue
	declare -r    TXT_DWHITE="${ESC}[37m"					# text dark white

# --- text color test ---------------------------------------------------------
function funcColorTest() {
	printf "%s : %-12.12s : %s\n" "${TXT_RESET}"    "TXT_RESET"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINE}"    "TXT_ULINE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_ULINERST}" "TXT_ULINERST" "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINK}"    "TXT_BLINK"    "${TXT_RESET}"
#	printf "%s : %-12.12s : %s\n" "${TXT_BLINKRST}" "TXT_BLINKRST" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REV}"      "TXT_REV"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_REVRST}"   "TXT_REVRST"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLACK}"    "TXT_BLACK"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_RED}"      "TXT_RED"      "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_GREEN}"    "TXT_GREEN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_YELLOW}"   "TXT_YELLOW"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BLUE}"     "TXT_BLUE"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_MAGENTA}"  "TXT_MAGENTA"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_CYAN}"     "TXT_CYAN"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_WHITE}"    "TXT_WHITE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLACK}"   "TXT_BBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BRED}"     "TXT_BRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BGREEN}"   "TXT_BGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BYELLOW}"  "TXT_BYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BBLUE}"    "TXT_BBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BMAGENTA}" "TXT_BMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BCYAN}"    "TXT_BCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_BWHITE}"   "TXT_BWHITE"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DBLACK}"   "TXT_DBLACK"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DRED}"     "TXT_DRED"     "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DGREEN}"   "TXT_DGREEN"   "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DYELLOW}"  "TXT_DYELLOW"  "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DBLUE}"    "TXT_DBLUE"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DMAGENTA}" "TXT_DMAGENTA" "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DCYAN}"    "TXT_DCYAN"    "${TXT_RESET}"
	printf "%s : %-12.12s : %s\n" "${TXT_DWHITE}"   "TXT_DWHITE"   "${TXT_RESET}"
}

# --- diff --------------------------------------------------------------------
function funcDiff() {
	if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
		return
	fi
	printf "%s\n" "$3"
	diff -y -W "${COLS_SIZE}" --suppress-common-lines "$1" "$2" || true
}

# --- substr ------------------------------------------------------------------
function funcSubstr() {
	echo "$1" | awk '{print substr($0,'"$2"','"$3"');}'
}

# --- IPv6 full address -------------------------------------------------------
function funcIPv6GetFullAddr() {
#	declare -r    _OLD_IFS="${IFS}"
	declare       _INP_ADDR="$1"
	declare -r    _STR_FSEP="${_INP_ADDR//[^:]}"
	declare -r -i _CNT_FSEP=$((7-${#_STR_FSEP}))
	declare -a    _OUT_ARRY=()
	declare       _OUT_TEMP=""
	if [[ "${_CNT_FSEP}" -gt 0 ]]; then
		_OUT_TEMP="$(eval printf ':%.s' "{1..$((_CNT_FSEP+2))}")"
		_INP_ADDR="${_INP_ADDR/::/${_OUT_TEMP}}"
	fi
	IFS= mapfile -d ':' -t _OUT_ARRY < <(echo -n "${_INP_ADDR/%:/::}")
	_OUT_TEMP="$(printf ':%04x' "${_OUT_ARRY[@]/#/0x0}")"
	echo "${_OUT_TEMP:1}"
}

# --- IPv6 reverse address ----------------------------------------------------
function funcIPv6GetRevAddr() {
	declare -r    _INP_ADDR="$1"
	echo "${_INP_ADDR//:/}"                  | \
	    awk '{for(i=length();i>1;i--)          \
	        printf("%c.", substr($0,i,1));     \
	        printf("%c" , substr($0,1,1));}'
}

# --- IPv4 netmask conversion -------------------------------------------------
function funcIPv4GetNetmask() {
	declare -r    _INP_ADDR="$1"
#	declare       _DEC_ADDR="$((0xFFFFFFFF ^ (2**(32-_INP_ADDR)-1)))"
	declare -i    _LOOP=$((32-_INP_ADDR))
	declare -i    _WORK=1
	declare       _DEC_ADDR=""
	while [[ "${_LOOP}" -gt 0 ]]
	do
		_LOOP=$((_LOOP-1))
		_WORK=$((_WORK*2))
	done
	_DEC_ADDR="$((0xFFFFFFFF ^ (_WORK-1)))"
	printf '%d.%d.%d.%d'              \
	    $(( _DEC_ADDR >> 24        )) \
	    $(((_DEC_ADDR >> 16) & 0xFF)) \
	    $(((_DEC_ADDR >>  8) & 0xFF)) \
	    $(( _DEC_ADDR        & 0xFF))
}

# --- IPv4 cidr conversion ----------------------------------------------------
function funcIPv4GetNetCIDR() {
	declare -r    _INP_ADDR="$1"
	declare -a    _OCTETS=()
	declare -i    _MASK=0
	echo "${_INP_ADDR}" | \
	    awk -F '.' '{
	        split($0, _OCTETS);
	        for (I in _OCTETS) {
	            _MASK += 8 - log(2^8 - _OCTETS[I])/log(2);
	        }
	        print _MASK
	    }'
}

# --- is numeric --------------------------------------------------------------
function funcIsNumeric() {
	if [[ ${1:-} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		echo 0
	else
		echo 1
	fi
}

# --- string output -----------------------------------------------------------
function funcString() {
	declare -r    _OLD_IFS="${IFS}"
	IFS=$'\n'
	if [[ "$1" -le 0 ]]; then
		echo ""
	else
		if [[ "$2" = " " ]]; then
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); print s;}'
		else
			echo "" | awk '{s=sprintf("%'"$1"'.'"$1"'s"," "); gsub(" ","'"$2"'",s); print s;}'
		fi
	fi
	IFS="${_OLD_IFS}"
}

# --- print with screen control -----------------------------------------------
function funcPrintf() {
#	declare -r    _SET_ENV_E="$(set -o | awk '$1=="errexit" {print $2;}')"
	declare -r    _SET_ENV_X="$(set -o | awk '$1=="xtrace"  {print $2;}')"
	set +x
	# https://www.tohoho-web.com/ex/dash-tilde.html
	declare -r    _OLD_IFS="${IFS}"
#	declare -i    _RET_CD=0
	declare       _FLAG_CUT=""
	declare       _TEXT_FMAT=""
	declare -r    _CTRL_ESCP=$'\033['
	declare       _PRNT_STR=""
	declare       _SJIS_STR=""
	declare       _TEMP_STR=""
	declare       _WORK_STR=""
	declare -i    _CTRL_CNT=0
	declare -i    _MAX_COLS="${COLS_SIZE:-80}"
	# -------------------------------------------------------------------------
	IFS=$'\n'
	if [[ "$1" = "--no-cutting" ]]; then					# no cutting print
		_FLAG_CUT="true"
		shift
	fi
	if [[ "$1" =~ %[0-9.-]*[diouxXfeEgGcs]+ ]]; then
		# shellcheck disable=SC2001
		_TEXT_FMAT="$(echo "$1" | sed -e 's/%\([0-9.-]*\)s/%\1b/g')"
		shift
	fi
	# shellcheck disable=SC2059
	_PRNT_STR="$(printf "${_TEXT_FMAT:-%b}" "${@:-}")"
	if [[ -z "${_FLAG_CUT}" ]]; then
		_SJIS_STR="$(echo -n "${_PRNT_STR:-}" | iconv -f UTF-8 -t CP932)"
		_TEMP_STR="$(echo -n "${_SJIS_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
		if [[ "${#_TEMP_STR}" -gt "${_MAX_COLS}" ]]; then
			_CTRL_CNT=$((${#_SJIS_STR}-${#_TEMP_STR}))
			_WORK_STR="$(echo -n "${_SJIS_STR}" | cut -b $((_MAX_COLS+_CTRL_CNT))-)"
			_TEMP_STR="$(echo -n "${_WORK_STR}" | sed -e "s/${_CTRL_ESCP}[0-9]*m//g")"
			_MAX_COLS+=$((_CTRL_CNT-(${#_WORK_STR}-${#_TEMP_STR})))
			# shellcheck disable=SC2312
			if ! _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -"${_MAX_COLS}"   | iconv -f CP932 -t UTF-8 2> /dev/null)"; then
				 _PRNT_STR="$(echo -n "${_SJIS_STR:-}" | cut -b -$((_MAX_COLS-1)) | iconv -f CP932 -t UTF-8 2> /dev/null) "
			fi
		fi
	fi
	printf "%b\n" "${_PRNT_STR:-}"
	IFS="${_OLD_IFS}"
	# -------------------------------------------------------------------------
	if [[ "${_SET_ENV_X}" = "on" ]]; then
		set -x
	else
		set +x
	fi
#	if [[ "${_SET_ENV_E}" = "on" ]]; then
#		set -e
#	else
#		set +e
#	fi
}

# --- unit conversion ---------------------------------------------------------
function funcUnit_conversion() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -r -a _TEXT_UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC_UNIT=0
	declare -i    I=0

	if [[ "$1" -lt 1024 ]]; then
		printf "%'d Byte" "$1"
		return
	fi

	if command -v numfmt > /dev/null 2>&1; then
		echo "$1" | numfmt --to=iec-i --suffix=B
		return
	fi

	for ((I=3; I>0; I--))
	do
		_CALC_UNIT=$((1024**I))
		if [[ "$1" -ge "${_CALC_UNIT}" ]]; then
			# shellcheck disable=SC2312
			printf "%s %s" "$(echo "$1" "${_CALC_UNIT}" | awk '{printf("%.1f", $1/$2)}')" "${_TEXT_UNIT[${I}]}"
			return
		fi
	done
	echo -n "$1"
}

# --- download ----------------------------------------------------------------
function funcCurl() {
#	declare -r    _OLD_IFS="${IFS}"
	declare -i    _RET_CD=0
	declare -i    I
	declare       _INP_URL=""
	declare       _OUT_DIR=""
	declare       _OUT_FILE=""
	declare       _MSG_FLG=""
	declare -a    _OPT_PRM=()
	declare -a    _ARY_HED=()
	declare       _ERR_MSG=""
	declare       _WEB_SIZ=""
	declare       _WEB_TIM=""
	declare       _WEB_FIL=""
	declare       _LOC_INF=""
	declare       _LOC_SIZ=""
	declare       _LOC_TIM=""
	declare       _TXT_SIZ=""

	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			http://* | https://* )
				_OPT_PRM+=("${1}")
				_INP_URL="${1}"
				;;
			--output-dir )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_DIR="${1}"
				;;
			--output )
				_OPT_PRM+=("${1}")
				shift
				_OPT_PRM+=("${1}")
				_OUT_FILE="${1}"
				;;
			--quiet )
				_MSG_FLG="true"
				;;
			* )
				_OPT_PRM+=("${1}")
				;;
		esac
		shift
	done
	if [[ -z "${_OUT_FILE}" ]]; then
		_OUT_FILE="${_INP_URL##*/}"
	fi
	if ! _ARY_HED=("$(curl --location --http1.1 --no-progress-bar --head --remote-time --show-error --silent --fail --retry-max-time 3 --retry 3 "${_INP_URL}" 2> /dev/null)"); then
		_RET_CD="$?"
		_ERR_MSG=$(echo "${_ARY_HED[@]}" | sed -ne '/^HTTP/p' | sed -e 's/\r\n*/\n/g' -ze 's/\n//g')
#		echo -e "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "${_ERR_MSG} [${_RET_CD}]: ${_INP_URL}"
		fi
		return "${_RET_CD}"
	fi
	_WEB_SIZ=$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/content-length:/ s/.*: //p')
	# shellcheck disable=SC2312
	_WEB_TIM=$(TZ=UTC date -d "$(echo "${_ARY_HED[@],,}" | sed -ne '\%http/.* 200%,\%^$% s/'$'\r''//gp' | sed -ne '/last-modified:/ s/.*: //p')" "+%Y%m%d%H%M%S")
	_WEB_FIL="${_OUT_DIR:-.}/${_INP_URL##*/}"
	if [[ -n "${_OUT_DIR}" ]] && [[ ! -d "${_OUT_DIR}/." ]]; then
		mkdir -p "${_OUT_DIR}"
	fi
	if [[ -n "${_OUT_FILE}" ]] && [[ -e "${_OUT_FILE}" ]]; then
		_WEB_FIL="${_OUT_FILE}"
	fi
	if [[ -n "${_WEB_FIL}" ]] && [[ -e "${_WEB_FIL}" ]]; then
		_LOC_INF=$(TZ=UTC ls -lL --time-style="+%Y%m%d%H%M%S" "${_WEB_FIL}")
		_LOC_TIM=$(echo "${_LOC_INF}" | awk '{print $6;}')
		_LOC_SIZ=$(echo "${_LOC_INF}" | awk '{print $5;}')
		if [[ "${_WEB_TIM:-0}" -eq "${_LOC_TIM:-0}" ]] && [[ "${_WEB_SIZ:-0}" -eq "${_LOC_SIZ:-0}" ]]; then
			if [[ -z "${_MSG_FLG}" ]]; then
				printf "%s\n" "same    file: ${_WEB_FIL}"
			fi
			return
		fi
	fi

	_TXT_SIZ="$(funcUnit_conversion "${_WEB_SIZ}")"

	if [[ -z "${_MSG_FLG}" ]]; then
		printf "%s\n" "get     file: ${_WEB_FIL} (${_TXT_SIZ})"
	fi
	if curl "${_OPT_PRM[@]}"; then
		return $?
	fi

	for ((I=0; I<3; I++))
	do
		if [[ -z "${_MSG_FLG}" ]]; then
			printf "%s\n" "retry  count: ${I}"
		fi
		if curl --continue-at "${_OPT_PRM[@]}"; then
			return "$?"
		else
			_RET_CD="$?"
		fi
	done
	if [[ "${_RET_CD}" -ne 0 ]]; then
		rm -f "${:?}"
	fi
	return "${_RET_CD}"
}

# --- service status ----------------------------------------------------------
function funcServiceStatus() {
	declare -i    _RET_CD=0
	declare       _SRVC_STAT=""
	_SRVC_STAT="$(systemctl "$@" 2> /dev/null || true)"
	_RET_CD="$?"
	case "${_RET_CD}" in
		4) _SRVC_STAT="not-found";;		# no such unit
		*) _SRVC_STAT="${_SRVC_STAT%-*}";;
	esac
	echo "${_SRVC_STAT:-"undefined"}: ${_RET_CD}"

	# systemctl return codes
	#-------+--------------------------------------------------+-------------------------------------#
	# Value | Description in LSB                               | Use in systemd                      #
	#    0  | "program is running or service is OK"            | unit is active                      #
	#    1  | "program is dead and /var/run pid file exists"   | unit not failed (used by is-failed) #
	#    2  | "program is dead and /var/lock lock file exists" | unused                              #
	#    3  | "program is not running"                         | unit is not active                  #
	#    4  | "program or service status is unknown"           | no such unit                        #
	#-------+--------------------------------------------------+-------------------------------------#
}

# --- function is package -----------------------------------------------------
function funcIsPackage () {
	LANG=C apt list "${1:?}" 2> /dev/null | grep -q 'installed'
}

# *** function section (sub functions) ****************************************

# === create ==================================================================

# === main ====================================================================

function funcMain() {
#	declare -r    OLD_IFS="${IFS}"
	declare -i    _start_time=0
	declare -i    _end_time=0
	declare -i    I=0
	declare -a    _COMD_LINE=("${PROG_PARM[@]}")
	declare -a    _DATA_LINE=()
	declare -a    _TGET_LIST=()
	declare -a    _TGET_LINE=()
	declare       _WORK_TEXT=""

	# ==== start ==============================================================

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "$(whoami)" != "root" ]]; then
		funcPrintf "run as root user."
		exit 1
	fi

	# --- initialization ------------------------------------------------------
	trap 'rm -rf '"${DIRS_TEMP:?}"'' EXIT

	if command -v tput > /dev/null 2>&1; then
		ROWS_SIZE=$(tput lines)
		COLS_SIZE=$(tput cols)
	fi
	if [[ "${ROWS_SIZE}" -lt 25 ]]; then
		ROWS_SIZE=25
	fi
	if [[ "${COLS_SIZE}" -lt 80 ]]; then
		COLS_SIZE=80
	fi

	TEXT_GAP1="$(funcString "${COLS_SIZE}" '-')"
	TEXT_GAP2="$(funcString "${COLS_SIZE}" '=')"

	readonly TEXT_GAP1
	readonly TEXT_GAP2

	# --- main ----------------------------------------------------------------
	_start_time=$(date +%s)
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing start${TXT_RESET}"
	funcPrintf "--- start ${TEXT_GAP1}"
	funcPrintf "--- main ${TEXT_GAP1}"
	# -------------------------------------------------------------------------
	renice -n "${NICE_VALU}"   -p "$$" > /dev/null
	ionice -c "${IONICE_CLAS}" -p "$$"
	# -------------------------------------------------------------------------
	_TGET_LIST=("${DATA_LIST[@]}")
	for I in "${!_TGET_LIST[@]}"
	do
		read -r -a _TGET_LINE < <(echo "${_TGET_LIST[I]}")
		if [[ "${_TGET_LINE[0]}" != "o" ]]; then
			unset "_TGET_LIST[I]"
			continue
		fi
	done
	_TGET_LIST=("${_TGET_LIST[@]}")
	# -------------------------------------------------------------------------
	if [[ -z "${PROG_PARM[*]}" ]]; then
		funcPrintf "sudo ./${PROG_NAME} [ options ]"
		funcPrintf "  create chroot environment"
		funcPrintf "    --create [ options ] [ empty | all | id number ]"
		funcPrintf "${TXT_RESET}      #%2.2s:%-20.20s:%-10.10s:%-10.10s:%-$((COLS_SIZE-54)).$((COLS_SIZE-54))s#${TXT_RESET}" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo"
		for I in "${!_TGET_LIST[@]}"
		do
			read -r -a _TGET_LINE < <(echo "${_TGET_LIST[I]}")
			funcPrintf "${TXT_RESET}      #%2.2s:%-20.20s:%-10.10s:%-10.10s:%-$((COLS_SIZE-54)).$((COLS_SIZE-54))s#${TXT_RESET}" "${I}" "${_TGET_LINE[2]//%20/ }" "${_TGET_LINE[5]#-}" "${_TGET_LINE[6]#-}" "${_TGET_LINE[3]//%20/ }"
		done
	else
		IFS=' =,'
		set -f
		set -- "${_COMD_LINE[@]:-}"
		set +f
		IFS=${OLD_IFS}
		while [[ -n "${1:-}" ]]
		do
			case "${1:-}" in
				* )
					shift
					_COMD_LINE=("${@:-}")
					;;
			esac
			if [[ -z "${_COMD_LINE[*]:-}" ]]; then
				break
			fi
			IFS=' =,'
			set -f
			set -- "${_COMD_LINE[@]:-}"
			set +f
			IFS=${OLD_IFS}
		done
	fi

	rm -rf "${DIRS_TEMP:?}"
	# ==== complete ===========================================================
	funcPrintf "--- complete ${TEXT_GAP1}"
	# shellcheck disable=SC2312
	funcPrintf "${TXT_RESET}${TXT_BMAGENTA}$(date +"%Y/%m/%d %H:%M:%S") processing end${TXT_RESET}"
	_end_time=$(date +%s)
#	funcPrintf "elapsed time: $((_end_time-_start_time)) [sec]"
	funcPrintf "elapsed time: %dd%02dh%02dm%02ds\n" $(((_end_time-_start_time)/86400)) $(((_end_time-_start_time)%86400/3600)) $(((_end_time-_start_time)%3600/60)) $(((_end_time-_start_time)%60))
}

# *** main processing section *************************************************
	funcMain
	exit 0

### eof #######################################################################
