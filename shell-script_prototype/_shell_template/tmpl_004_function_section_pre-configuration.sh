# shellcheck disable=SC2148
# *** function section (sub functions) ****************************************

# === <pre-configuration> =====================================================

# -----------------------------------------------------------------------------
# descript: create preseed.cfg
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_preseed() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_SEDD}" "${__TGET_PATH}"
	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e '/packages:/a \    usrmerge '\\
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"               \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"               \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                             \
			    -e '\%^[ \t]*d-i[ \t]\+pkgsel/include[ \t]\+%,\%^#.*[^\\]$% { ' \
			    -e '/^[^#].*[^\\]$/ s/$/ \\/g'                                  \
			    -e 's/^#/ /g'                                                   \
			    -e 's/connman/network-manager/                              } '
#			sed -e 's/task-lxde-desktop/task-gnome-desktop/'                    \
#			  "${__TGET_PATH}"                                                  \
#			> "${__TGET_PATH%.*}_gnome.${__TGET_PATH##*.}"
			;;
		*)	;;
	esac
	# --- for ubiquity --------------------------------------------------------
	case "${__TGET_PATH}" in
		*_ubiquity_*)
			IFS= __WORK=$(
				sed -n '\%^[^#].*preseed/late_command%,\%[^\\]$%p' "${__TGET_PATH}" | \
				sed -e 's/\\/\\\\/g'                                                  \
				    -e 's/d-i/ubiquity/'                                              \
				    -e 's%preseed\/late_command%ubiquity\/success_command%'         | \
				sed -e ':l; N; s/\n/\\n/; b l;' || true
			)
			if [[ -n "${__WORK}" ]]; then
				sed -i "${__TGET_PATH}"                                  \
				    -e '\%^[^#].*preseed/late_command%,\%[^\\]$%     { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } ' \
				    -e '\%^[^#].*ubiquity/success_command%,\%[^\\]$% { ' \
				    -e 's/^/#/g                                        ' \
				    -e 's/^#  /# /g                                  } '
				sed -i "${__TGET_PATH}"                                  \
				    -e "\%ubiquity/success_command%i \\${__WORK}"
			fi
			sed -i "${__TGET_PATH}"                       \
			    -e "\%ubiquity/download_updates% s/^#/ /" \
			    -e "\%ubiquity/use_nonfree%      s/^#/ /" \
			    -e "\%ubiquity/reboot%           s/^#/ /"
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# -----------------------------------------------------------------------------
# descript: create nocloud
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_nocloud() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_CLUD}" "${__TGET_PATH}"
	# --- by generation -------------------------------------------------------
	case "${__TGET_PATH}" in
		*_debian_*.*         | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e '/packages:/a \    usrmerge '
			;;
		*)	;;
	esac
	case "${__TGET_PATH}" in
		*_debian_*_oldold.*  | *_ubuntu_*_oldold.*  | *_ubiquity_*_oldold.*)
			sed -i "${__TGET_PATH}"              \
			    -e 's/bind9-utils/bind9utils/'   \
			    -e 's/bind9-dnsutils/dnsutils/'  \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*_debian_*_old.*     | *_ubuntu_*_old.*     | *_ubiquity_*_old.*   )
			sed -i "${__TGET_PATH}"              \
			    -e 's/systemd-resolved/systemd/' \
			    -e 's/fcitx5-mozc/fcitx-mozc/'
			;;
		*)	;;
	esac
	# --- server or desktop ---------------------------------------------------
	case "${__TGET_PATH}" in
		*_desktop*)
			sed -i "${__TGET_PATH}"                                            \
			    -e '/^[ \t]*packages:$/,/\([[:graph:]]\+:$\|^#[ \t]*--\+\)/ {' \
			    -e '/^#[ \t]*--\+/! s/^#/ /g                                }'
			;;
		*)	;;
	esac
	# -------------------------------------------------------------------------
	touch -m "${__DIRS}/meta-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/network-config" --reference "${__TGET_PATH}"
#	touch -m "${__DIRS}/user-data"      --reference "${__TGET_PATH}"
	touch -m "${__DIRS}/vendor-data"    --reference "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	chmod --recursive ugo-x "${__DIRS}"
}

# -----------------------------------------------------------------------------
# descript: create kickstart.cfg
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_kickstart() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	declare       __NAME=""				# "            name
	declare       __SECT=""				# "            section
	declare -r    __ARCH="x86_64"		# base architecture
	declare -r    __ADDR="${_SRVR_PROT:+"${_SRVR_PROT}:/"}/${_SRVR_ADDR:?}/${_DIRS_IMGS##*/}"
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_KICK}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
#	__NUMS="\$releasever"
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
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
#	sed -e "/%packages/,/%end/ {"                      \
#	    -e "/desktop/ s/^-//g  }"                      \
#	    "${__TGET_PATH}"                               \
#	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
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

# -----------------------------------------------------------------------------
# descript: create autoyast.xml
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_autoyast() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
#	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_YAST}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__NUMS="${__VERS##*-}"
	# --- by media ------------------------------------------------------------
	case "${__TGET_PATH}" in
		*_web*|\
		*_dvd*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/false/true/'
			;;
		*)
			sed -i "${__TGET_PATH}"                                   \
			    -e '/<image_installation t="boolean">/ s/true/false/'
			;;
	esac
	# --- by version ----------------------------------------------------------
	case "${__TGET_PATH}" in
		*tumbleweed*)
			sed -i "${__TGET_PATH}"                                    \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%  { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e '\%<packages .*>%,\%</packages>%                { ' \
			    -e '/<!-- tumbleweed/,/tumbleweed -->/             { ' \
			    -e '/<!-- tumbleweed$/ s/$/ -->/g                  } ' \
			    -e '/^tumbleweed -->/  s/^/<!-- /g                 } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1openSUSE\2%    '
			;;
		*           )
			sed -i "${__TGET_PATH}"                                          \
			    -e '\%<add_on_products .*>%,\%</add_on_products>%        { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e "/<media_url>/ s%/\(leap\)/[0-9.]\+/%/\1/${__NUMS}/%g   " \
			    -e '/<!-- leap$/ s/$/ -->/g                              } ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e '\%<packages .*>%,\%</packages>%                      { ' \
			    -e '/<!-- leap/,/leap -->/                               { ' \
			    -e '/<!-- leap$/ s/$/ -->/g                              } ' \
			    -e '/^leap -->/  s/^/<!-- /g                             } ' \
			    -e 's%\(<product>\).*\(</product>\)%\1Leap\2%              '
			;;
	esac
	# --- desktop -------------------------------------------------------------
	sed -e '/<!-- desktop$/       s/$/ -->/g '         \
	    -e '/^desktop -->/        s/^/<!-- /g'         \
	    -e '/<!-- desktop gnome$/ s/$/ -->/g '         \
	    -e '/^desktop gnome -->/  s/^/<!-- /g'         \
	    "${__TGET_PATH}"                               \
	>   "${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}"
}

# -----------------------------------------------------------------------------
# descript: create autoinst.json
#   input :   $1   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_agama() {
	declare -r    __TGET_PATH="${1:?}"	# file name
	declare -r    __DIRS="${__TGET_PATH%/*}" # directory name
	declare       __WORK=""				# work variables
	declare       __VERS=""				# distribution version
	declare       __NUMS=""				# "            number
#	declare       __PDCT=""				# product name
	declare       __PDID=""				# "       id
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create file" "${__TGET_PATH}"
	mkdir -p "${__DIRS}"
	cp --backup "${_CONF_AGMA}" "${__TGET_PATH}"
	# -------------------------------------------------------------------------
	__VERS="${__TGET_PATH#*_}"
	__VERS="${__VERS%%_*}"
	__VERS="${__VERS%.*}"
	__VERS="${__VERS,,}"
	__NUMS="${__VERS##*-}"
#	__PDCT="${__VERS%%-*}"
	__PDID="${__VERS//-/_}"
	__PDID="${__PDID^}"
	# --- by media ------------------------------------------------------------
	# --- by version ----------------------------------------------------------
	case "${__TGET_PATH}" in
		*_tumbleweed_*) __WORK="leap";;
		*             ) __WORK="tumbleweed";;
	esac
	sed -i "${__TGET_PATH}"                                   \
	    -e '/"product": {/,/}/                             {' \
	    -e '/"id":/ s/"[^ ]\+"$/"'"${__PDID}"'"/           }' \
	    -e '/"extraRepositories": \[/,/\]/                 {' \
	    -e '\%^// '"${__WORK}"'%,\%^// '"${__WORK}"'%d      ' \
	    -e '\%^//.*$%d                                     }' \
	    -e '\%^// fixed parameter%,\%^// fixed parameter%d  '
	# --- desktop -------------------------------------------------------------
	__WORK="${__TGET_PATH%.*}_desktop.${__TGET_PATH##*.}"
	cp "${__TGET_PATH}" "${__WORK}"
	sed -i "${__TGET_PATH}"                   \
	    -e '/"patterns": \[/,/\]/          {' \
	    -e '\%^// desktop%,\%^// desktop%d }' \
	    -e '/"packages": \[/,/\]/          {' \
	    -e '\%^// desktop%,\%^// desktop%d }'
	sed -i "${__WORK}"                        \
	    -e '/"patterns": \[/,/\]/          {' \
	    -e '\%^//.*$%d                     }' \
	    -e '/"packages": \[/,/\]/          {' \
	    -e '\%^//.*$%d                     }'
	# -------------------------------------------------------------------------
	chmod ugo-x "${__TGET_PATH}" "${__WORK}"
}

# -----------------------------------------------------------------------------
# descript: create pre-configuration file templates
#   n-ref :   $1   : return value : options
#   input :   $@   : input value
#   output: stdout : message
#   return:        : unused
# shellcheck disable=SC2317,SC2329
function fnCreate_precon() {
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare -a    __OPTN=()				# option parameter
	declare -a    __LIST=()				# data list
	declare       __PATH=""				# full path
	declare       __TYPE=""				# configuration type
#	declare       __WORK=""				# work variables
	declare -a    __LINE=()				# work variable
	declare -i    I=0					# work variables
	# --- option parameter ----------------------------------------------------
	__OPTN=()
	while [[ -n "${1:-}" ]]
	do
		case "${1:-}" in
			all      ) shift; __OPTN+=("preseed" "nocloud" "kickstart" "autoyast" "agama"); break;;
			preseed  | \
			nocloud  | \
			kickstart| \
			autoyast | \
			agama    ) ;;
			*        ) break;;
		esac
		__OPTN+=("$1")
		shift
	done
	__NAME_REFR="${*:-}"
	if [[ -z "${__OPTN[*]}" ]]; then
		return
	fi
	# -------------------------------------------------------------------------
	fnPrintf "%20.20s: %s" "create pre-conf file" ""
	# -------------------------------------------------------------------------
	__LIST=()
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LINE < <(echo "${_LIST_MDIA[I]}")
		case "${__LINE[1]}" in			# entry_flag
			o) ;;
			*) continue;;
		esac
		case "${__LINE[23]##*/}" in		# cfg_path
			-) continue;;
			*) ;;
		esac
		__PATH="${__LINE[23]}"
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		if ! echo "${__OPTN[*]}" | grep -q "${__TYPE}"; then
			continue
		fi
		__LIST+=("${__PATH}")
		case "${__PATH}" in
			*/kickstart/*dvd.*) __LIST+=("${__PATH/_dvd/_web}");;
			*/agama/*) __LIST+=("${__PATH/_leap-*_/_tumbleweed_}");;
			*)	;;
		esac
	done
	IFS= mapfile -d $'\n' -t __LIST < <(IFS=  printf "%s\n" "${__LIST[@]}" | sort -Vu || true)
	# -------------------------------------------------------------------------
	for __PATH in "${__LIST[@]}"
	do
		__TYPE="${__PATH%/*}"
		__TYPE="${__TYPE##*/}"
		case "${__TYPE}" in
			preseed  ) fnCreate_preseed   "${__PATH}";;
			nocloud  ) fnCreate_nocloud   "${__PATH}/user-data";;
			kickstart) fnCreate_kickstart "${__PATH}";;
			autoyast ) fnCreate_autoyast  "${__PATH}";;
			agama    ) fnCreate_agama     "${__PATH}";;
			*)	;;
		esac
	done

	# -------------------------------------------------------------------------
	# debian_*_oldold  : debian-10(buster)
	# debian_*_old     : debian-11(bullseye)
	# debian_*         : debian-12(bookworm)/13(trixie)/14(forky)/testing/sid/~
	# ubuntu_*_oldold  : ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubuntu_*_old     : ubuntu-20.04(focal)/22.04(jammy)
	# ubuntu_*         : ubuntu-23.04(lunar)/~
	# ubiquity_*_oldold: ubuntu-14.04(trusty)/16.04(xenial)/18.04(bionic)
	# ubiquity_*_old   : ubuntu-20.04(focal)/22.04(jammy)
	# ubiquity_*       : ubuntu-23.04(lunar)/~
	# -------------------------------------------------------------------------
}
