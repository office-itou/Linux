# === <pxeboot> ===============================================================

# --- get pxeboot server directory --------------------------------------------
function funcPxeboot_directory() {
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file
	declare -a    __LIST=()				# work variables

	# --- pxeboot server directory --------------------------------------------
	case "${_SRVR_PROT:?}" in
		http|https)
			__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"
			__CONF="${__SRVR}/${_DIRS_CONF##*/}"
			__IMGS="${__SRVR}/${_DIRS_IMGS##*/}"
			__ISOS="${__SRVR}/${_DIRS_ISOS##*/}"
			__LOAD="${__SRVR}/${_DIRS_LOAD##*/}"
			__RMAK="${__SRVR}/${_DIRS_RMAK##*/}"
			;;
		tftp)
			__SRVR="${_SRVR_HTTP:-http}://${_SRVR_ADDR:?}"	# http/https
			__CONF="${__SRVR}/${_DIRS_CONF##*/}"
			__SRVR="${_SRVR_PROT}://${_SRVR_ADDR:?}"		# tftp
			__IMGS="${__SRVR}/${_DIRS_IMGS##*/}"
			__ISOS="${__SRVR}/${_DIRS_ISOS##*/}"
			__LOAD="${__SRVR}/${_DIRS_LOAD##*/}"
			;;
		*);;
	esac
	__LIST=("${__SRVR:-}" "${__CONF:-}" "${__IMGS:-}" "${__ISOS:-}" "${__LOAD:-}" "${__RMAK:-}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__LIST[@]}"
}

# --- create boot options for preseed -----------------------------------------
function funcPxeboot_preseed() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- server address ------------------------------------------------------
	IFS= mapfile -d $'\n' -t __LIST < <(funcPxeboot_directory)
	__SRVR="${_LIST[0]:-}"
	__CONF="${_LIST[1]:-}"
	__IMGS="${_LIST[2]:-}"
	__ISOS="${_LIST[3]:-}"
	__LOAD="${_LIST[4]:-}"
	__RMAK="${_LIST[5]:-}"
	# ---  0: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK="${__WORK:+" "}auto=true preseed/file=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK="${__CONF:+"${__WORK/file=\/cdrom/url=${__CONF}}"}"
		case "${__TGET_LIST[2]}" in
			ubuntu-desktop-*    | \
			ubuntu-legacy-*     ) __WORK="automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*            ) __WORK="${__WORK/\/cdrom/}";;
			*                   ) ;;
		esac
	fi
	__BOPT+=("${__WORK}");;
	# ---  1: network ---------------------------------------------------------
	__WORK=""
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
	__BOPT+=("${__WORK}");;
	# ---  2: locale ----------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		live-debian-*       | \
		live-ubuntu-*       | \
		debian-live-*       ) __WORK+="${__WORK:+" "}"utc=yes locales=ja_JP.UTF-8 timezone=Asia/Tokyo key-model=pc105 key-layouts=jp key-variants=OADG109A";;
		ubuntu-desktop-*    | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                   ) __WORK+="${__WORK:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  3: ramdisk ---------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		*-mini-*            ) ;;
		*                   ) __WORK+="${__WORK:+" "}${_OPTN_RDSK}";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  4: isosfile --------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=\${isosfile}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=\${isosfile}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=\${isosfile}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=\${isosfile}";;
	esac
	__BOPT+=("${__WORK}");;
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create boot options for nocloud -----------------------------------------
function funcPxeboot_nocloud() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- server address ------------------------------------------------------
	IFS= mapfile -d $'\n' -t __LIST < <(funcPxeboot_directory)
	__SRVR="${_LIST[0]:-}"
	__CONF="${_LIST[1]:-}"
	__IMGS="${_LIST[2]:-}"
	__ISOS="${_LIST[3]:-}"
	__LOAD="${_LIST[4]:-}"
	__RMAK="${_LIST[5]:-}"
	# ---  0: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK="${__WORK:+" "}automatic-ubiquity noprompt autoinstall ds='nocloud;s=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}'"
		__WORK="${__CONF:+"${__WORK/\/cdrom/${__CONF}}"}"
	fi
	__BOPT+=("${__WORK}");;
	# ---  1: network ---------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		ubuntu-live-18.04   ) __WORK+="${__WORK:+" "}ip=\${ethrname},\${ipv4addr},\${ipv4mask},\${ipv4gway} hostname=\${hostname}";;
		*                   ) __WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}::\${ethrname}:${_IPV4_ADDR:+static}:\${ipv4nsvr} hostname=\${hostname}";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  2: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}");;
	# ---  3: ramdisk ---------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		*-mini-*            ) ;;
		*                   ) __WORK+="${__WORK:+" "}${_OPTN_RDSK}";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  4: isosfile --------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=\${isosfile}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=\${isosfile}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=\${isosfile}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=\${isosfile}";;
	esac
	__BOPT+=("${__WORK}");;
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create boot options for kickstart ---------------------------------------
function funcPxeboot_kickstart() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- server address ------------------------------------------------------
	IFS= mapfile -d $'\n' -t __LIST < <(funcPxeboot_directory)
	__SRVR="${_LIST[0]:-}"
	__CONF="${_LIST[1]:-}"
	__IMGS="${_LIST[2]:-}"
	__ISOS="${_LIST[3]:-}"
	__LOAD="${_LIST[4]:-}"
	__RMAK="${_LIST[5]:-}"
	# ---  0: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK+="${__WORK:+" "}inst.ks=hd:sr0:${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK+="${__TGET_LIST[16]:+"${__WORK:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
		__WORK="${__CONF:+"${__WORK/hd:sr0:/${__CONF}}"}"
	fi
	__BOPT+=("${__WORK}");;
	# ---  1: network ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}ip=\${ipv4addr}::\${ipv4gway}:\${ipv4mask}:\${hostname}:\${ethrname}:none,auto6 nameserver=\${ipv4nsvr}"
	__BOPT+=("${__WORK}");;
	# ---  2: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}");;
	# ---  3: ramdisk ---------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		*-mini-*            ) ;;
		*                   ) __WORK+="${__WORK:+" "}${_OPTN_RDSK}";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  4: isosfile --------------------------------------------------------
	__WORK=""
	__BOPT+=("${__WORK}");;
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create boot options for autoyast ----------------------------------------
function funcPxeboot_autoyast() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __HOST=""				# host name
	declare       __SRVR="" 			# server address
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=()
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- server address ------------------------------------------------------
	IFS= mapfile -d $'\n' -t __LIST < <(funcPxeboot_directory)
	__SRVR="${_LIST[0]:-}"
	__CONF="${_LIST[1]:-}"
	__IMGS="${_LIST[2]:-}"
	__ISOS="${_LIST[3]:-}"
	__LOAD="${_LIST[4]:-}"
	__RMAK="${_LIST[5]:-}"
	# ---  0: autoinstall -----------------------------------------------------
	__WORK=""
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK+="${__WORK:+" "}inst.ks=hd:sr0:${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__WORK+="${__TGET_LIST[16]:+"${__WORK:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
		__WORK="${__CONF:+"${__WORK/hd:sr0:/${__CONF}}"}"
	fi
	__BOPT+=("${__WORK}");;
	# ---  1: network ---------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}hostname=\${hostname} ifcfg=${__WORK}=\${ipv4addr},\${ipv4gway},\${ipv4nsvr},${_NWRK_WGRP}"
	case "${__TGET_LIST[2]}" in
		opensuse-*-15* ) __WORK="${__WORK//"${_NICS_NAME:-ens160}"/"eth0"};;
		*              ) ;;
	esac
	__BOPT+=("${__WORK}");;
	# ---  2: locale ----------------------------------------------------------
	__WORK=""
	__WORK+="${__WORK:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	__BOPT+=("${__WORK}");;
	# ---  3: ramdisk ---------------------------------------------------------
	__WORK=""
	case "${__TGET_LIST[2]}" in
		*-mini-*            ) ;;
		*                   ) __WORK+="${__WORK:+" "}${_OPTN_RDSK}";;
	esac
	__BOPT+=("${__WORK}");;
	# ---  4: isosfile --------------------------------------------------------
	__WORK=""
	__BOPT+=("${__WORK}");;
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create boot options -----------------------------------------------------
function funcPxeboot_boot_options() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options

	# --- create boot options -------------------------------------------------
	case "${__TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${__TGET_LIST[23]}" in
				*/preseed/* ) __WORK="$(set -e; funcPxeboot_preseed "${__TGET_LIST[@]}")";;
				*/nocloud/* ) __WORK="$(set -e; funcPxeboot_nocloud "${__TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) __WORK="$(set -e; funcPxeboot_kickstart "${__TGET_LIST[@]}")";;
		opensuse     ) __WORK="$(set -e; funcPxeboot_autoyast "${__TGET_LIST[@]}")";;
		*            ) ;;
	esac
	IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
	__BOPT+=("fsck.mode=skip raid=noautodetect${_MENU_MODE:+" vga=${_MENU_MODE}"}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]}"
}

# --- create autoexec.ipxe ----------------------------------------------------
function funcPxeboot_autoexec_ipxe() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options

	__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
	IFS= mapfile -d $'\n' -t __LIST < <(echo -n "${__WORK}")

set srvraddr ${SRVR_ADDR:?}
isset \${next-server} && set srvraddr \${next-server} ||
set autoinst ${_CONF_PATH:-}
set language ${_LANG_CONF:-}
set ramsdisk ${_RAMS_DISK:-}

:${__TGET_LIST[2]:?}
echo Loading ${__TGET_LIST[3]:?} ...
set hostname ${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
set ethrname ${_NICS_NAME:-ens160}
set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
set ipv4mask ${_IPV4_MASK:-}
set ipv4gway ${_IPV4_GWAY:-}
set ipv4nsvr ${_IPV4_NSVR:-}
set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
isset ${next-server} && set srvraddr ${next-server} ||
set autoinst ${_LIST[0]:-}
set language ${_LIST[2]:-}
set ramsdisk ${_LIST[3]:-}
set isosfile ${_LIST[4]:-}
form                                    Configure Boot Options
item hostname                           Hostname
item ethrname                           Interface
item ipv4addr                           IPv4 address
item ipv4mask                           IPv4 netmask
item ipv4gway                           IPv4 gateway
item ipv4nsvr                           IPv4 nameservers
present ||
form                                    Configure Boot Options
item srvraddr                           Server ip address
item autoinst                           Auto install
item language                           Language
item ramsdisk                           RAM disk
item isosfile                           ISO file
present ||
set knladdr http://${srvraddr}/imgs/debian-mini-11
set options vga=791 ${autoinst} netcfg/disable_autoconfig=true netcfg/choose_interface=${ethrname} netcfg/get_hostname=${hostname} netcfg/get_ipaddress=${ipv4addr} netcfg/get_netmask=${ipv4mask} netcfg/get_gateway=${ipv4gway} netcfg/get_nameservers=${ipv4nsvr} ${language} fsck.mode=skip ${isosfile} raid=noautodetect
echo Loading kernel and initrd ...
kernel ${knladdr}/linux ${options} --- || goto error
initrd ${knladdr}/initrd.gz || goto error
boot || goto error
exit
