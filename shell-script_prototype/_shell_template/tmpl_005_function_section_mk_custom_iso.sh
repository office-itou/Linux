# === <remastering> ===========================================================

# -----------------------------------------------------------------------------
# descript: create a boot option for preseed of the remaster
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
function fnRemastering_preseed() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file
	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK="${__WORK:+" "}auto=true preseed/file=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
#		__WORK="${__CONF:+"${__WORK/file=\/cdrom/url=${__CONF}}"}"
		case "${__TGET_LIST[2]}" in
			ubuntu-desktop-*    | \
			ubuntu-legacy-*     ) __WORK="automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*            ) __WORK="${__WORK/\/cdrom/}";;
			*                   ) ;;
		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		case "${__TGET_LIST[2]}" in
			ubuntu-*            ) __WORK+="${__WORK:+" "}netcfg/target_network_config=NetworkManager";;
			*                   ) ;;
		esac
		__WORK+="${__WORK:+" "}netcfg/disable_autoconfig=true"
		__WORK+="${__WORK:+" "}netcfg/choose_interface=\${ethrname}"
		__WORK+="${__WORK:+" "}netcfg/get_hostname=\${hostname}"
		__WORK+="${__WORK:+" "}netcfg/get_ipaddress=\${ipv4addr}"
		__WORK+="${__WORK:+" "}netcfg/get_netmask=\${ipv4mask}"
		__WORK+="${__WORK:+" "}netcfg/get_gateway=\${ipv4gway}"
		__WORK+="${__WORK:+" "}netcfg/get_nameservers=\${ipv4nsvr}"
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		live-debian-*       | \
		live-ubuntu-*       | \
		debian-live-*       ) __WORK+="${__WORK:+" "}utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*    | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                   ) __WORK+="${__WORK:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]}"
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
#	__WORK=""
#	case "${__TGET_LIST[2]}" in
##		debian-mini-*       ) ;;
#		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		ubuntu-desktop-18.* | \
#		ubuntu-desktop-20.* | \
#		ubuntu-desktop-22.* | \
#		ubuntu-live-18.*    | \
#		ubuntu-live-20.*    | \
#		ubuntu-live-22.*    | \
#		ubuntu-server-*     | \
#		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
#	esac
#	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# -----------------------------------------------------------------------------
# descript: create a boot option for nocloud of the remaster
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
function fnRemastering_nocloud() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file
	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK="${__WORK:+" "}automatic-ubiquity noprompt autoinstall ds=nocloud\;s=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
#		__WORK="${__CONF:+"${__WORK/\/cdrom/${__CONF}}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		case "${__TGET_LIST[2]}" in
			ubuntu-live-18.04   ) __WORK+="${__WORK:+" "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
			*                   ) __WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]}"
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
#	__WORK=""
#	case "${__TGET_LIST[2]}" in
##		debian-mini-*       ) ;;
#		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		ubuntu-desktop-18.* | \
#		ubuntu-desktop-20.* | \
#		ubuntu-desktop-22.* | \
#		ubuntu-live-18.*    | \
#		ubuntu-live-20.*    | \
#		ubuntu-live-22.*    | \
#		ubuntu-server-*     | \
#		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
#		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
#	esac
#	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# -----------------------------------------------------------------------------
# descript: create a boot option for kickstart of the remaster
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
function fnRemastering_kickstart() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
#	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file
	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
#	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK+="${__WORK:+" "}inst.ks=${__CONF}${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK+="${__TGET_LIST[16]:+"${__WORK:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
#		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		__WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]/root=\/dev\/ram*[0-9]/}"
	__WORK="${__WORK#"${__WORK%%[!"${IFS}"]*}"}"	# ltrim
	__WORK="${__WORK%"${__WORK##*[!"${IFS}"]}"}"	# rtrim
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
#	__WORK=""
#	__WORK+="${__WORK:+" "}inst.repo=${__IMGS}/${__TGET_LIST[2]}"
#	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# -----------------------------------------------------------------------------
# descript: create a boot option for autoyast of the remaster
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
function fnRemastering_autoyast() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
#	declare       __ISOS=""				# iso file
#	declare       __LOAD=""				# load module
#	declare       __RMAK=""				# remake file
	# --- boot option ---------------------------------------------------------
#	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# ---  0: server address --------------------------------------------------
	__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
	__CONF="\${srvraddr}/${_DIRS_CONF##*/}"
	__IMGS="\${srvraddr}/${_DIRS_IMGS##*/}"
#	__ISOS="\${srvraddr}/${_DIRS_ISOS##*/}"
#	__LOAD="\${srvraddr}/${_DIRS_LOAD##*/}"
#	__RMAK="\${srvraddr}/${_DIRS_RMAK##*/}"
	__BOPT+=("server=${__SRVR}")
	# ---  1: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="boot=live"
	else
		__WORK+="${__WORK:+" "}autoyast=${__CONF}${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK+="${__TGET_LIST[16]:+"${__WORK:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
#		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
	fi
	__BOPT+=("${__WORK}")
	# ---  2: network ---------------------------------------------------------
	__WORK=""
	if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
		__WORK="ip=dhcp"
	else
		__WORK+="${__WORK:+" "}hostname=\${hostname} ifcfg=\${ethrname}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
#		case "${__TGET_LIST[2]}" in
#			opensuse-*-15* ) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"}";;
#			*              ) ;;
#		esac
	fi
	__BOPT+=("${__WORK}")
	# ---  3: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}")
	# ---  4: ramdisk ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}${_OPTN_RDSK[*]/root=\/dev\/ram*[0-9]/}"
	__WORK="${__WORK#"${__WORK%%[!"${IFS}"]*}"}"	# ltrim
	__WORK="${__WORK%"${__WORK##*[!"${IFS}"]}"}"	# rtrim
	__BOPT+=("${__WORK}")
	# ---  5: isosfile --------------------------------------------------------
#	__WORK=""
#	case "${__TGET_LIST[2]}" in
#		opensuse-leap*netinst*      ) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/distribution/leap/${__TGET_LIST[2]##*-}/repo/oss/";;
#		opensuse-tumbleweed*netinst*) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
#		*                           ) __WORK+="${__WORK:+" "}install=${__IMGS}/${__TGET_LIST[2]}";;
#	esac
#	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# -----------------------------------------------------------------------------
# descript: create a boot option of the remaster
#   input :   $@   : input value
#   output: stdout : output
#   return:        : unused
function fnRemastering_boot_options() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options

	# --- create boot options -------------------------------------------------
	case "${__TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${__TGET_LIST[23]}" in
				*/preseed/* ) __WORK="$(set -e; fnRemastering_preseed "${__TGET_LIST[@]}")";;
				*/nocloud/* ) __WORK="$(set -e; fnRemastering_nocloud "${__TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) __WORK="$(set -e; fnRemastering_kickstart "${__TGET_LIST[@]}")";;
		opensuse     ) __WORK="$(set -e; fnRemastering_autoyast "${__TGET_LIST[@]}")";;
		*            ) ;;
	esac
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__BOPT+=("fsck.mode=skip raid=noautodetect${_MENU_MODE:+" vga=${_MENU_MODE}"}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# -----------------------------------------------------------------------------
# descript: create path for configuration file
#   input :   $1   : target path
#   input :   $2   : directory
#   output: stdout : output
#   return:        : unused
function fnRemastering_path() {
	declare -r    __PATH_TGET="${1:?}"	# target path
	declare -r    __DIRS_TGET="${2:?}"	# directory
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name

	__FNAM="${__PATH_TGET##*/}"
	__DIRS="${__PATH_TGET%"${__FNAM}"}"
	__DIRS="${__DIRS#"${__DIRS_TGET}"}"
	__DIRS="${__DIRS%%/}"
	__DIRS="${__DIRS##/}"
	echo -n "${__DIRS:+/"${__DIRS}"}/${__FNAM}"
}

# -----------------------------------------------------------------------------
# descript: create autoinstall configuration file for isolinux
#   input :   $1   : target directory
#   input :   $2   : file name : autoinst.cfg
#   input :   $3   : boot options
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_isolinux_autoinst_cfg() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    __BOOT_OPTN="${3:?}"	# boot options
	declare -r -a __TGET_LIST=("${@:4}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FTHM=""				# theme.txt
	declare       __FKNL=""				# kernel
	declare       __FIRD=""				# initrd
	declare -a    __BOPT=()				# boot options

	# --- header section ------------------------------------------------------
	__PATH="${__DIRS_TGET}${__PATH_MENU}"
	__FTHM="${__PATH%/*}/theme.txt"
	__WORK="$(date -d "${__TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__FTHM}" || true
		menu resolution ${_MENU_RESO/x/ }
		menu title Boot Menu: ${__TGET_LIST[17]##*/} ${__WORK}
		menu background splash.png
		menu color title	* #FFFFFFFF *
		menu color border	* #00000000 #00000000 none
		menu color sel		* #ffffffff #76a1d0ff *
		menu color hotsel	1;7;37;40 #ffffffff #76a1d0ff *
		menu color tabmsg	* #ffffffff #00000000 *
		menu color help		37;40 #ffdddd00 #00000000 none
		menu vshift 8
		menu rows 32
		menu helpmsgrow 38
		menu cmdlinerow 32
		menu timeoutrow 38
		menu tabmsgrow 38
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
		timeout ${_MENU_TOUT:-5}0
		default auto_install

_EOT_
	# --- boot options --------------------------------------------------------
	__WORK="${__BOOT_OPTN:-}"
	__WORK="${__WORK//\$\{hostname\}/"${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"}"
	__WORK="${__WORK//\$\{srvraddr\}/"${_SRVR_PROT}://${_SRVR_ADDR:?}"}"
	__WORK="${__WORK//\$\{ethrname\}/"${_NICS_NAME:-ens160}"}"
	__WORK="${__WORK//\$\{ipv4addr\}/"${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"}"
	__WORK="${__WORK//\$\{ipv4mask\}/"${_IPV4_MASK:-}"}"
	__WORK="${__WORK//\$\{ipv4gway\}/"${_IPV4_GWAY:-}"}"
	__WORK="${__WORK//\$\{ipv4nsvr\}/"${_IPV4_NSVR:-}"}"
#	__WORK="${_NICS_NAME:-ens160}"
	case "${__TGET_LIST[2]}" in
		opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
		*              ) ;;
	esac
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	# --- standard installation mode ------------------------------------------
	if [[ -n "${__TGET_LIST[22]#-}" ]]; then
		__DIRS="${_DIRS_LOAD}/${__TGET_LIST[2]}"
		__FKNL="${__TGET_LIST[22]#"${__DIRS}"}"				# kernel
		__FIRD="${__TGET_LIST[21]#"${__DIRS}"}"				# initrd
		case "${__TGET_LIST[2]}" in
			*-mini-*         ) __FIRD="${__FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}" || true
		label auto_install
		  menu label ^Automatic installation
		  menu default
		  linux  ${__FKNL}
		  initrd ${__FIRD}
		  append ${__BOPT[@]:1}

_EOT_
		# --- graphical installation mode -------------------------------------
		while read -r __DIRS
		do
			__FKNL="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[22]##*/}"	# kernel
			__FIRD="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}" || true
				label auto_install_gui
				  menu label ^Automatic installation of gui
				  linux  ${__FKNL}
				  initrd ${__FIRD}
				  append ${__BOPT[@]:1}

_EOT_
		done < <(find "${__DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# -----------------------------------------------------------------------------
# descript: editing isolinux for autoinstall
#   input :   $1   : target directory
#   input :   $2   : boot options
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_isolinux() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __BOOT_OPTN="${2:?}"	# boot options
	declare -r -a __TGET_LIST=("${@:3}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FTHM=""				# theme.txt
	declare       __FNAM=""				# file name
	declare       __FTMP=""				# file name (.tmp)
	declare       __PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	__PAUT=""
	while read -r __PATH
	do
		__FNAM="$(set -e; fnRemastering_path "${__PATH}" "${__DIRS_TGET}")"	# isolinux.cfg
		__PAUT="${__FNAM%/*}/${_AUTO_INST}"
		__FTHM="${__FNAM%/*}/theme.txt"
		__FTMP="${__PATH}.tmp"
		if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${__PATH}"; then
			sed -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${__PAUT}"'' \
			    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${__FTHM}"'' \
				"${__PATH}"                                                                    \
			>	"${__FTMP}"
		else
			sed -e '0,/\([Ll]abel\|LABEL\)/ {'                      \
				-e '/\([Ll]abel\|LABEL\)/i include '"${__PAUT}"'\n' \
				-e '}'                                              \
				"${__PATH}"                                         \
			>	"${__FTMP}"
		fi
		if ! cmp --quiet "${__PATH}" "${__FTMP}"; then
			cp -a "${__FTMP}" "${__PATH}"
		fi
		rm -f "${__FTMP:?}"
		# --- create autoinstall configuration file for isolinux --------------
		fnRemastering_isolinux_autoinst_cfg "${__DIRS_TGET}" "${__PAUT}" "${__BOOT_OPTN}" "${__TGET_LIST[@]}"
	done < <(find "${__DIRS_TGET}" -name 'isolinux.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${__PAUT}" ]]; then
		return
	fi
	while read -r __PATH
	do
		__FTMP="${__PATH}.tmp"
		sed -e '/^[ \t]*\([Dd]efault\|DEFAULT\)[ \t]*/ {/.*\.c32/!                   d}' \
		    -e '/^[ \t]*\([Tt]imeout\|TIMEOUT\)[ \t]*/                               d'  \
		    -e '/^[ \t]*\([Pp]rompt\|PROMPT\)[ \t]*/                                 d'  \
		    -e '/^[ \t]*\([Oo]ntimeout\|ONTIMEOUT\)[ \t]*/                           d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Dd]efault\|DEFAULT\)[ \t]*/       d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Aa]utoboot\|AUTOBOOT\)[ \t]*/     d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Tt]abmsg\|TABMSG\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Rr]esolution\|RESOLUTION\)[ \t]*/ d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Hh]shift\|HSHIFT\)[ \t]*/         d'  \
		    -e '/^[ \t]*\([Mm]enu\|MENU\)[ \t]\+\([Ww]idth\|WIDTH\)[ \t]*/           d'  \
			"${__PATH}"                                                                  \
		>	"${__FTMP}"
		if ! cmp --quiet "${__PATH}" "${__FTMP}"; then
			cp -a "${__FTMP}" "${__PATH}"
		fi
		rm -f "${__FTMP:?}"
	done < <(find "${__DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# -----------------------------------------------------------------------------
# descript: create autoinstall configuration file for grub
#   input :   $1   : target directory
#   input :   $2   : file name : autoinst.cfg
#   input :   $3   : boot options
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_grub_autoinst_cfg() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    __BOOT_OPTN="${3:?}"	# boot options
	declare -r -a __TGET_LIST=("${@:4}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __FKNL=""				# kernel
	declare       __FIRD=""				# initrd
	declare       __FTHM=""				# theme.txt
	declare       __FPNG=""				# splash.png
	declare -a    __BOPT=()				# boot options

	# --- theme section -------------------------------------------------------
	__PATH="${__DIRS_TGET}${__PATH_MENU}"
	__FTHM="${__PATH%/*}/theme.txt"
	__WORK="$(date -d "${__TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	for __DIRS in / /isolinux /boot/grub /boot/grub/theme
	do
		__FPNG="${__DIRS}/splash.png"
		if [[ -e "${__DIRS_TGET}/${__FPNG}" ]]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FTHM}" || true
				desktop-image: "${__FPNG}"
_EOT_
			break
		fi
	done
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__FTHM}" || true
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${__TGET_LIST[17]##*/} ${__WORK}"
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
	# --- header section ------------------------------------------------------
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH}" || true
		#set gfxmode=${_MENU_RESO:+"${_MENU_RESO}${_MENU_DPTH:+x"${_MENU_DPTH}"},"}auto
		#set default=0
		set timeout=${_MENU_TOUT:-5}
		set timeout_style=menu
		set theme=${__FTHM#"${__DIRS_TGET}"}
		export theme

_EOT_
	# --- boot options --------------------------------------------------------
#	__WORK="${__BOOT_OPTN:-}"
#	__WORK="${__WORK//\$\{hostname\}/"${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"}"
#	__WORK="${__WORK//\$\{srvraddr\}/"${_SRVR_PROT}://${_SRVR_ADDR:?}"}"
#	__WORK="${__WORK//\$\{ethrname\}/"${_NICS_NAME:-ens160}"}"
#	__WORK="${__WORK//\$\{ipv4addr\}/"${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"}"
#	__WORK="${__WORK//\$\{ipv4mask\}/"${_IPV4_MASK:-}"}"
#	__WORK="${__WORK//\$\{ipv4gway\}/"${_IPV4_GWAY:-}"}"
#	__WORK="${__WORK//\$\{ipv4nsvr\}/"${_IPV4_NSVR:-}"}"
	__WORK="${_NICS_NAME:-ens160}"
	case "${__TGET_LIST[2]}" in
		opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
		*              ) ;;
	esac
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__BOOT_OPTN:-}")
	# --- standard installation mode ------------------------------------------
	if [[ -n "${__TGET_LIST[22]#-}" ]]; then
		__DIRS="${_DIRS_LOAD}/${__TGET_LIST[2]}"
		__FKNL="${__TGET_LIST[22]#"${__DIRS}"}"				# kernel
		__FIRD="${__TGET_LIST[21]#"${__DIRS}"}"				# initrd
		case "${__TGET_LIST[2]}" in
			*-mini-*         ) __FIRD="${__FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}" || true
			menuentry 'Automatic installation' {
			  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
			  set gfxpayload=keep
			  set background_color=black
			  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
			  set hostname="${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
			  set ethrname="${__WORK}"
			  set ipv4addr="${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"
			  set ipv4mask="${_IPV4_MASK:-}"
			  set ipv4gway="${_IPV4_GWAY:-}"
			  set ipv4nsvr="${_IPV4_NSVR:-}"
			  set autoinst="${__BOPT[1]:-}"
			  set networks="${__BOPT[2]:-}"
			  set language="${__BOPT[3]:-}"
			  set ramsdisk="${__BOPT[4]:-}"
			  set isosfile="${__BOPT[5]:-}"
			  set knladdr="(tftp,${_SRVR_ADDR:?})/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}"
			  set options="\${autoinst} \${networks} \${language} \${ramsdisk} \${isosfile} ${__BOPT[@]:6}"
			  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
			  insmod net
			  insmod http
			  insmod progress
			  echo 'Loading linux ...'
			  linux  ${__FKNL} \${options} ---
			  echo 'Loading initrd ...'
			  initrd ${__FIRD}
			}

_EOT_
	# --- graphical installation mode -----------------------------------------
		while read -r __DIRS
		do
			__FKNL="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[22]##*/}"	# kernel
			__FIRD="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}" || true
				menuentry 'Automatic installation of gui' {
			menuentry 'Automatic installation' {
				  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
				  set gfxpayload=keep
				  set background_color=black
				  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
				  set hostname="${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
				  set ethrname="${__WORK}"
				  set ipv4addr="${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"
				  set ipv4mask="${_IPV4_MASK:-}"
				  set ipv4gway="${_IPV4_GWAY:-}"
				  set ipv4nsvr="${_IPV4_NSVR:-}"
				  set autoinst="${__BOPT[1]:-}"
				  set networks="${__BOPT[2]:-}"
				  set language="${__BOPT[3]:-}"
				  set ramsdisk="${__BOPT[4]:-}"
				  set isosfile="${__BOPT[5]:-}"
				  set knladdr="(tftp,${_SRVR_ADDR:?})/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}"
				  set options="\${autoinst} \${networks} \${language} \${ramsdisk} \${isosfile} ${__BOPT[@]:6}"
				  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
				  insmod net
				  insmod http
				  insmod progress
				  echo 'Loading linux ...'
				  linux  ${__FKNL} \${options} ---
				  echo 'Loading initrd ...'
				  initrd ${__FIRD}
				}

_EOT_
		done < <(find "${__DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# -----------------------------------------------------------------------------
# descript: editing grub for autoinstall
#   input :   $1   : target directory
#   input :   $2   : boot options
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_grub() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __BOOT_OPTN="${2:?}"	# boot options
	declare -r -a __TGET_LIST=("${@:3}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __FTMP=""				# file name (.tmp)
	declare       __PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	__PAUT=""
	while read -r __PATH
	do
		__FNAM="$(set -e; fnRemastering_path "${__PATH}" "${__DIRS_TGET}")"	# grub.cfg
		__PAUT="${__FNAM%/*}/${_AUTO_INST}"
		__FTMP="${__PATH}.tmp"
		if ! grep -qEi '^menuentry[ \t]+.*$' "${__PATH}"; then
			continue
		fi
		sed -e '0,/^menuentry/ {'                     \
			-e '/^menuentry/i source '"${__PAUT}"'\n' \
			-e '}'                                    \
				"${__PATH}"                           \
			>	"${__FTMP}"
		if ! cmp --quiet "${__PATH}" "${__FTMP}"; then
			cp -a "${__FTMP}" "${__PATH}"
		fi
		rm -f "${__FTMP:?}"
		# --- create autoinstall configuration file for grub ------------------
		fnRemastering_grub_autoinst_cfg "${__DIRS_TGET}" "${__PAUT}" "${__BOOT_OPTN}" "${__TGET_LIST[@]}"
	done < <(find "${__DIRS_TGET}" -name 'grub.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${__PAUT}" ]]; then
		return
	fi
	while read -r __PATH
	do
		__FTMP="${__PATH}.tmp"
		sed -e '/^[ \t]*\(\|set[ \t]\+\)default=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)timeout=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)theme=/   d' \
			"${__PATH}"                              \
		>	"${__FTMP}"
		if ! cmp --quiet "${__PATH}" "${__FTMP}"; then
			cp -a "${__FTMP}" "${__PATH}"
		fi
		rm -f "${__FTMP:?}"
	done < <(find "${__DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# -----------------------------------------------------------------------------
# descript: copy auto-install files
#   input :   $1   : target directory
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_copy() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r -a __TGET_LIST=("${@:2}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __BASE=""				# base name
	declare       __EXTN=""				# extension

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "copy" "auto-install files" 1>&2

	# -------------------------------------------------------------------------
	for __PATH in       \
		"${_SHEL_ERLY}" \
		"${_SHEL_LATE}" \
		"${_SHEL_PART}" \
		"${_SHEL_RUNS}" \
		"${__TGET_LIST[23]}"
	do
		if [[ ! -e "${__PATH}" ]]; then
			continue
		fi
		__DIRS="${__DIRS_TGET}${__PATH#"${_DIRS_CONF}"}"
		__DIRS="${__DIRS%/*}"
		mkdir -p "${__DIRS}"
		case "${__PATH}" in
			*/script/*   )
				printf "%20.20s: %s\n" "copy" "${__PATH#"${_DIRS_CONF}"/}" 1>&2
				cp -a "${__PATH}" "${__DIRS}"
				chmod ugo+xr-w "${__DIRS}/${__PATH##*/}"
				;;
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
				__FNAM="${__PATH##*/}"
				__WORK="${__FNAM%.*}"
				__EXTN="${__FNAM#"${__WORK}"}"
				__BASE="${__FNAM%"${__EXTN}"}"
				__WORK="${__BASE#*_*_}"
				__WORK="${__BASE%"${__WORK}"}"
				__WORK="${__PATH#*"${__WORK:-${__BASE%%_*}}"}"
				__WORK="${__PATH%"${__WORK}"*}"
				printf "%20.20s: %s\n" "copy" "${__WORK#"${_DIRS_CONF}"/}*${__EXTN}" 1>&2
				find "${__WORK%/*}" -name "${__WORK##*/}*${__EXTN}" -exec cp -a '{}' "${__DIRS}" \;
				find "${__DIRS}" -exec chmod ugo+r-xw '{}' \;
				;;
			*/windows/*  ) ;;
			*            ) ;;
		esac
	done
}

# -----------------------------------------------------------------------------
# descript: remastering for initrd
#   input :   $1   : target directory
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_initrd() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r -a __TGET_LIST=("${@:2}") # target data
	declare       __FKNL=""				# kernel
	declare       __FIRD=""				# initrd
	declare       __DTMP=""				# directory (extract)
	declare       __DTOP=""				# directory (main)
	declare       __DIRS=""				# directory

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "remake" "initrd" 1>&2

	# -------------------------------------------------------------------------
	__DIRS="${_DIRS_LOAD}/${__TGET_LIST[2]}"
	__FKNL="${__TGET_LIST[22]#"${__DIRS}"}"					# kernel
	__FIRD="${__TGET_LIST[21]#"${__DIRS}"}"					# initrd
	__DTMP="$(mktemp -qd "${TMPDIR:-/tmp}/${__FIRD##*/}.XXXXXX")"

	# --- extract -------------------------------------------------------------
	fnSplit_initramfs "${__DIRS_TGET}${__FIRD}" "${__DTMP}"
	__DTOP="${__DTMP}"
	if [[ -d "${__DTOP}/main/." ]]; then
		__DTOP+="/main"
	fi
	# --- copy auto-install files ---------------------------------------------
	fnRemastering_copy "${__DTOP}" "${__TGET_LIST[@]}"
#	ln -s "${__TGET_LIST[23]#"${_DIRS_CONF}"}" "${__DTOP}/preseed.cfg"
	# --- repackaging ---------------------------------------------------------
	pushd "${__DTOP}" > /dev/null || exit
		find . | cpio --format=newc --create --quiet | gzip > "${__DIRS_TGET}${__FIRD%/*}/${_MINI_IRAM}" || true
	popd > /dev/null || exit

	rm -rf "${__DTMP:?}"
}

# -----------------------------------------------------------------------------
# descript: remastering for media
#   input :   $1   : target directory
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering_media() {
	declare -r    __DIRS_TGET="${1:?}"						# target directory
	declare -r -a __TGET_LIST=("${@:2}")					# target data
	declare -r    __DWRK="${_DIRS_TEMP}/${__TGET_LIST[2]}"	# work directory
#	declare       __PATH=""									# full path
	declare       __FMBR=""									# "         (mbr.img)
	declare       __FEFI=""									# "         (efi.img)
	declare       __FCAT=""									# "         (boot.cat or boot.catalog)
	declare       __FBIN=""									# "         (isolinux.bin or eltorito.img)
	declare       __FHBR=""									# "         (isohdpfx.bin)
#	declare       __VLID=""									#
	declare -i    __SKIP=0									#
	declare -i    __SIZE=0									#

	# --- pre-processing ------------------------------------------------------
#	__PATH="${__DWRK}/${__TGET_LIST[17]##*/}.tmp"				# file path
	__FCAT="$(find "${__DIRS_TGET}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
	__FBIN="$(find "${__DIRS_TGET}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
#	__VLID="$(fnGetVolID "${__TGET_LIST[13]}")"
	__FEFI="$(fnDistro2efi "${__TGET_LIST[2]%%-*}")"
	# --- create iso image file -----------------------------------------------
	if [[ -e "${__DIRS_TGET}/${__FEFI}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "info" "xorriso (hybrid)" 1>&2
		__FHBR="$(find /usr/lib  -iname 'isohdpfx.bin' -type f || true)"
		fnCreate_iso "${__DIRS_TGET}" "${__TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${__TGET_LIST[16]//%20/ }" \
			-joliet -joliet-long \
			-cache-inodes \
			${__FHBR:+-isohybrid-mbr "${__FHBR}"} \
			${__FBIN:+-eltorito-boot "${__FBIN}"} \
			${__FCAT:+-eltorito-catalog "${__FCAT}"} \
			-boot-load-size 4 -boot-info-table \
			-no-emul-boot \
			-eltorito-alt-boot ${__FEFI:+-e "${__FEFI}"} \
			-no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
	else
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "info" "xorriso (grub2-mbr)" 1>&2
		__FMBR="${__DWRK}/mbr.img"
		__FEFI="${__DWRK}/efi.img"
		# --- extract the mbr template ----------------------------------------
		dd if="${__TGET_LIST[13]}" bs=1 count=446 of="${__FMBR}" > /dev/null 2>&1
		# --- extract efi partition image -------------------------------------
		__SKIP=$(fdisk -l "${__TGET_LIST[13]}" | awk '/.iso2/ {print $2;}' || true)
		__SIZE=$(fdisk -l "${__TGET_LIST[13]}" | awk '/.iso2/ {print $4;}' || true)
		dd if="${__TGET_LIST[13]}" bs=512 skip="${__SKIP}" count="${__SIZE}" of="${__FEFI}" > /dev/null 2>&1
		# --- create iso image file -------------------------------------------
		fnCreate_iso "${__DIRS_TGET}" "${__TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${__TGET_LIST[16]//%20/ }" \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			${__FMBR:+--grub2-mbr "${__FMBR}"} \
			--mbr-force-bootable \
			${__FEFI:+-append_partition 2 0xEF "${__FEFI}"} \
			-appended_part_as_gpt \
			${__FCAT:+-eltorito-catalog "${__FCAT}"} \
			${__FBIN:+-eltorito-boot "${__FBIN}"} \
			-no-emul-boot \
			-boot-load-size 4 -boot-info-table \
			--grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
			-no-emul-boot
	fi
}

# -----------------------------------------------------------------------------
# descript: remastering
#   input :   $@   : target data
#   output: stdout : unused
#   return:        : unused
function fnRemastering() {
	declare -i    __time_start=0							# start of elapsed time
	declare -i    __time_end=0								# end of elapsed time
	declare -i    __time_elapsed=0							# result of elapsed time
	declare -r -a __TGET_LIST=("$@")						# target data
	declare -r    __DWRK="${_DIRS_TEMP}/${__TGET_LIST[2]}"	# work directory
	declare -r    __DOVL="${__DWRK}/overlay"				# overlay
	declare -r    __DUPR="${__DOVL}/upper"					# upperdir
	declare -r    __DLOW="${__DOVL}/lower"					# lowerdir
	declare -r    __DWKD="${__DOVL}/work"					# workdir
	declare -r    __DMRG="${__DOVL}/merged"					# merged
	declare       __PATH=""									# full path
	declare       __FEFI=""									# "         (efiboot.img)
	declare       __WORK=""									# work variables

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %-20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" "${__TGET_LIST[13]##*/}" 1>&2

	# --- pre-check -----------------------------------------------------------
	__FEFI="$(fnDistro2efi "${__TGET_LIST[2]%%-*}")"
	if [[ -z "${__FEFI}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[41m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "unknown target" "${__TGET_LIST[2]%%-*} [${__TGET_LIST[13]##*/}]" 1>&2
		return
	fi
	if [[ ! -s "${__TGET_LIST[13]}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[93m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "not exist" "${__TGET_LIST[13]##*/}" 1>&2
		return
	fi
	if mountpoint --quiet "${__DMRG}"; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[41m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "already mounted" "${__DMRG#"${__DWRK}"/}" 1>&2
		return
	fi

	# --- pre-processing ------------------------------------------------------
	printf "%20.20s: %s\n" "start" "${__DMRG#"${__DWRK}"/}" 1>&2
	rm -rf "${__DOVL:?}"
	mkdir -p "${__DUPR}" "${__DLOW}" "${__DWKD}" "${__DMRG}"

	# --- main processing -----------------------------------------------------
	mount -r "${__TGET_LIST[13]}" "${__DLOW}"
	mount -t overlay overlay -o lowerdir="${__DLOW}",upperdir="${__DUPR}",workdir="${__DWKD}" "${__DMRG}"
	# --- create boot options -------------------------------------------------
	printf "%20.20s: %s\n" "start" "create boot options" 1>&2
	__WORK="$(set -e; fnRemastering_boot_options "${__TGET_LIST[@]}")"
	# --- create autoinstall configuration file for isolinux ------------------
	printf "%20.20s: %s\n" "start" "create autoinstall configuration file for isolinux" 1>&2
	fnRemastering_isolinux "${__DMRG}" "${__WORK}" "${__TGET_LIST[@]}"
	# --- create autoinstall configuration file for grub ----------------------
	printf "%20.20s: %s\n" "start" "create autoinstall configuration file for grub" 1>&2
	fnRemastering_grub "${__DMRG}" "${__WORK}" "${__TGET_LIST[@]}"
	# --- copy auto-install files ---------------------------------------------
	printf "%20.20s: %s\n" "start" "copy auto-install files" 1>&2
	fnRemastering_copy "${__DMRG}" "${__TGET_LIST[@]}"
	# --- remastering for initrd ----------------------------------------------
	printf "%20.20s: %s\n" "start" "remastering for initrd" 1>&2
	case "${__TGET_LIST[2]}" in
		*-mini-*         ) fnRemastering_initrd "${__DMRG}" "${__TGET_LIST[@]}";;
		*                ) ;;
	esac
	# --- create iso image file -----------------------------------------------
	printf "%20.20s: %s\n" "start" "create iso image file" 1>&2
	fnRemastering_media "${__DMRG}" "${__TGET_LIST[@]}"
	umount "${__DMRG}"
	umount "${__DLOW}"

	# --- post-processing -----------------------------------------------------
	rm -rf "${__DOVL:?}"
	printf "%20.20s: %s\n" "finish" "${__DMRG#"${__DWRK}"/}" 1>&2

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end-__time_start))
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %-20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)" "finish" "${__TGET_LIST[13]##*/}" 1>&2
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%10dd%02dh%02dm%02ds: %-20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "$((__time_elapsed/86400))" "$((__time_elapsed%86400/3600))" "$((__time_elapsed%3600/60))" "$((__time_elapsed%60))" "elapsed" "${__TGET_LIST[13]##*/}" 1>&2
}

# -----------------------------------------------------------------------------
# descript: executing the download
#   n-ref :   $1   : return value : serialized target data
#   input :   $@   : target data
#   output: stdout : message
#   return:        : unused
function fnExec_download() {
	declare -n    __RETN_VALU="$1"		# return value
	declare -a    __TGET_LIST=("${@:2}") # target data
	declare       __RSLT=""				# result
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# work variables

	if [[ -z "${__TGET_LIST[9]##-}" ]]; then # web_path
		return
	fi
	case "${__TGET_LIST[12]}" in		# web_status
		200) ;;
		*  ) return;;
	esac
	# --- lnk_path ------------------------------------------------------------
	if [[ -n "${__TGET_LIST[25]##-}" ]] && [[ ! -e "${__TGET_LIST[13]}" ]] && [[ ! -h "${__TGET_LIST[13]}" ]]; then
		fnPrintf "%20.20s: %s" "create symlink" "${__TGET_LIST[25]} -> ${__TGET_LIST[13]}"
		ln -s "${__TGET_LIST[25]%%/}/${__TGET_LIST[13]##*/}" "${__TGET_LIST[13]}"
	fi
	# --- comparing web and local file timestamps -----------------------------
	__RSLT="$(fnDateDiff "${__TGET_LIST[10]:-@0}" "${__TGET_LIST[14]:-@0}")"
	if [[ "${__RSLT}" -ge 0 ]]; then
		return
	fi
	# --- executing the download ----------------------------------------------
	fnGetWeb_contents "${__TGET_LIST[13]}" "${__TGET_LIST[9]}"
	# --- get file information ------------------------------------------------
	fnGetFileinfo __RETN "${__TGET_LIST[13]}"
	read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
	__ARRY=("${__ARRY[@]##-}")
#	__TGET_LIST[13]="${__ARRY[0]:-}"	# iso_path
	__TGET_LIST[14]="${__ARRY[1]:-}"	# iso_tstamp
	__TGET_LIST[15]="${__ARRY[2]:-}"	# iso_size
	__TGET_LIST[16]="${__ARRY[3]:-}"	# iso_volume
	# --- finish --------------------------------------------------------------
	__RETN_VALU="$(printf "%s\n" "${__MDIA[@]}")"
}

# -----------------------------------------------------------------------------
# descript: executing the remastering
#   n-ref :   $1   : return value : serialized target data
#   input :   $@   : target data
#   output: stdout : message
#   return:        : unused
function fnExec_remastering() {
	declare -n    __RETN_VALU="$1"		# return value
	declare -r    __COMD_TYPE="$2"		# command type
	declare -a    __TGET_LIST=("${@:3}") # target data
#	declare       __RSLT=""				# result
	declare       __FORC=""				# force parameter
	declare       __RETN=""				# return value
	declare -a    __ARRY=()				# work variables

	case "${__COMD_TYPE}" in
		create  ) __FORC="true";;
		update  ) __FORC="";;
		download) return;;
		*       ) return;;
	esac
	if [[ -n "${__LIST[13]##-}" ]] && [[ -s "${__LIST[13]}" ]]; then
		return
	fi
	# --- comparing remaster and local file timestamps ------------------------
	if [[ -z "${__FORC:-}" ]]; then
		__RSLT="$(fnDateDiff "${__TGET_LIST[18]:-@0}" "${__TGET_LIST[14]:-@0}")"
		if [[ "${__RSLT}" -ge 0 ]]; then
			return
		fi
	fi
	# --- executing the remastering -------------------------------------------
	fnRemastering "${__TGET_LIST[@]}"
	# --- new local remaster iso files ----------------------------------------
	fnGetFileinfo "__RETN" "${__TGET_LIST[17]##-}"
	read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
	__ARRY=("${__ARRY[@]##-}")
#	__TGET_LIST[17]="${__ARRY[0]:--}"	# rmk_path
	__TGET_LIST[18]="${__ARRY[1]:--}"	# rmk_tstamp
	__TGET_LIST[19]="${__ARRY[2]:--}"	# rmk_size
	__TGET_LIST[20]="${__ARRY[3]:--}"	# rmk_volume
	# --- finish --------------------------------------------------------------
	__RETN_VALU="$(printf "%s\n" "${__MDIA[@]}")"
}

# -----------------------------------------------------------------------------
# descript: executing the action
#   n-ref :   $1   : return value : serialized target data
#   input :   $2   : command type
#   input :   $3   : target range
#   input :   $@   : target data
#   output: stdout : message
#   return:        : unused
function fnExec() {
	declare -n    __RETN_VALU="$1"		# return value
	declare -r    __COMD_TYPE="$2"		# command type
	declare -r    __TGET_RANG="$3"		# target range
	declare -a    __TGET_LIST=("${@:4}") # target data
	declare       __RANG=""				# range
	declare -i    __IDNO=0				# id number (1..)
	declare       __RSLT=""				# result
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    J=0					# work variables
	# --- processing by command -----------------------------------------------
	case "${__COMD_TYPE}" in
		list    ) return;;			# (print out media list)
		create  ) ;;				# (force create)
		update  ) ;;				# (create new files only)
		download) ;;				# (download only)
		*       ) return;;
	esac
	# --- select by input value -----------------------------------------------
	__RANG="${__TGET_RANG:-}"
	if [[ -z "${__RANG:-}" ]]; then
		read -r -p "enter the number to create:" __RANG
	fi
	if [[ -z "${__RANG:-}" ]]; then
		return
	fi
	case "${__RANG,,}" in
		a|all) __RANG="$(eval "echo {1..${#__TGET_LIST[@]}}")";;
		*    ) __RANG="$(eval "echo ${__RANG}")";;
	esac
	# ---
	__IDNO=0
	for I in "${!__TGET_LIST[@]}"
	do
		read -r -a __LIST < <(echo "${__TGET_LIST[I]}")
		case "${__LIST[1]}" in
			o) ;;
			*) continue;;
		esac
		if [[ -z "${__LIST[3]##-}"  ]] \
		|| [[ -z "${__LIST[13]##-}" ]] \
		|| [[ -z "${__LIST[23]##-}" ]] || [[ -z "${__LIST[24]##-}" ]]; then
			continue
		fi
		if ! echo "$((++__IDNO))" | grep -qE '^('"${__RANG[*]// /\|}"')$'; then
			continue
		fi
		# --- start -----------------------------------------------------------
		printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "start" "${__LIST[17]##*/}" 1>&2
		# --- conversion ------------------------------------------------------
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]##-}"		# empty
			__LIST[J]="${__LIST[J]//%20/ }"	# space
		done
		# --- download --------------------------------------------------------
		case "${__COMD_TYPE}" in
			create  | \
			update  | \
			download)
				fnExec_download "__RETN" "${__LIST[@]}"
				read -r -a __ARRY < <(echo "${__RETN:-}")
				case "${__ARRY[12]:-}" in
					200) __LIST=("${__ARRY[@]}");;
					*  ) ;;
				esac
				;;
			*       ) ;;
		esac
		# --- remastering -----------------------------------------------------
		case "${__COMD_TYPE}" in
			create  | \
			update  )
				fnExec_remastering "__RETN" "${__COMD_TYPE}" "${__LIST[@]}"
				read -r -a __ARRY < <(echo "${__RETN:-}")
				__LIST=("${__ARRY[@]}")
				;;
			download) ;;
			*       ) ;;
		esac
		# --- conversion ------------------------------------------------------
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]:--}"		# empty
			__LIST[J]="${__LIST[J]// /%20}"	# space
		done
		# --- update media data record ----------------------------------------
		__MDIA[I]="${__LIST[*]}"
		# --- complete --------------------------------------------------------
		printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${__LIST[17]##*/}" 1>&2
	done
	__RETN_VALU="$(printf "%s\n" "${__MDIA[@]}")"
}
