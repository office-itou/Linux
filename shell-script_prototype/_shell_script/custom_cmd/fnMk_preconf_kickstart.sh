# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make kickstart.cfg
#   input :     $1     : input value
#   output:   stdout   : message
#   return:            : unused
#   g-var : _PROG_NAME : read
#   g-var : _PATH_KICK : read
# shellcheck disable=SC2317,SC2329
function fnMk_preconf_kickstart() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __NAME=""				# "            name
	declare       __SECT=""				# "            section
	declare -r    __ARCH="x86_64"		# base architecture
	declare -r    __ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"
	declare       __WORK=""				# work

	fnMsgout "${_PROG_NAME:-}" "create" "${__TGET_PATH}"
	mkdir -p "${__TGET_PATH%/*}"
	cp --backup "${_PATH_KICK}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__WORK="${__TGET_PATH##*/}"			# file name
	__VERS="${__WORK#*_}"				# ks_(name)-(nums)_ ...: (ex: ks_fedora-42_dvd_desktop.cfg)
	__VERS="${__VERS%%_*}"				# vers="(name)-(nums)"
	__NUMS="${__VERS##*-}"
	__NAME="${__VERS%-*}"
	__SECT="${__NAME/-/ }"
	# --- initializing the settings -------------------------------------------
	sed -i "${__TGET_PATH}"                     \
	    -e "/^cdrom$/      s/^/#/             " \
	    -e "/^url[ \t]\+/  s/^/#/g            " \
	    -e "/^repo[ \t]\+/ s/^/#/g            " \
	    -e "s/:_HOST_NAME_:/${__NAME}/        " \
	    -e "s%:_WEBS_ADDR_:%${__ADDR}%g       " \
	    -e "s%:_DISTRO_:%${__NAME}-${__NUMS}%g"
	# --- cdrom, repository ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_dvd*)		# --- cdrom install ---------------------------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#cdrom$/ s/^#//             " \
			    -e "/^#.*(${__SECT}).*$/,/^$/   { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
		*_net*)		# --- network install -------------------------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^cdrom$/ s/^/#/              " \
			    -e "/^#.*(${__SECT}).*$/,/^$/   { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g    } "
			;;
		*_web*)		# --- network install [ for pxeboot ] ---------------------
			sed -i "${__TGET_PATH}"                 \
			    -e "/^cdrom$/ s/^/#/              " \
			    -e "/^#.*(web address).*$/,/^$/ { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_fedora*)
			sed -i "${__TGET_PATH}"                 \
			    -e "/%packages/,/%end/          { " \
			    -e "/^epel-release/ s/^/#/      } "
			;;
		*)
			sed -i "${__TGET_PATH}"                 \
			    -e "/^#.*(EPEL).*$/,/^$/        { " \
			    -e "/^#url[ \t]\+/  s/^#//g       " \
			    -e "/^#repo[ \t]\+/ s/^#//g       " \
			    -e "s/\$releasever/${__NUMS}/g    " \
			    -e "s/\$basearch/${__ARCH}/g      " \
			    -e "s/\$stream/${__NUMS}/g      } "
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e "/%packages/,/%end/                      {" \
	    -e "/#@.*-desktop/,/^[^#]/ s/^#//g          }" \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	case "${__NUMS}" in
		[1-9]) ;;
		*    )
			sed -i "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}" \
			    -e "/%packages/,/%end/                         {" \
			    -e "/^kpipewire$/ s/^/#/g                      }"
			;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}" "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
}
