# === <remastering> ===========================================================

# --- create boot options for preseed -----------------------------------------
function funcRemastering_preseed() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare       __BOPT=""				# boot options
	declare       __HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	__BOPT=""
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK="auto=true preseed/file=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		case "${__TGET_LIST[2]}" in
			ubuntu-desktop-* | \
			ubuntu-legacy-*  ) __BOPT+="${__BOPT:+" "}automatic-ubiquity noprompt ${__WORK}";;
			*-mini-*         ) __BOPT+="${__BOPT:+" "}${__WORK/\/cdrom/}";;
			*                ) __BOPT+="${__BOPT:+" "}${__WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${__TGET_LIST[2]}" in
		ubuntu-*         ) __BOPT+="${__BOPT:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	__BOPT+="${__BOPT:+" "}netcfg/disable_autoconfig=true"
	__BOPT+="${_NICS_NAME:+"${__BOPT:+" "}netcfg/choose_interface=${_NICS_NAME}"}"
	__BOPT+="${_NWRK_HOST:+"${__BOPT:+" "}netcfg/get_hostname=${__HOST}.${_NWRK_WGRP}"}"
	__BOPT+="${_IPV4_ADDR:+"${__BOPT:+" "}netcfg/get_ipaddress=${_IPV4_ADDR}"}"
	__BOPT+="${_IPV4_MASK:+"${__BOPT:+" "}netcfg/get_netmask=${_IPV4_MASK}"}"
	__BOPT+="${_IPV4_GWAY:+"${__BOPT:+" "}netcfg/get_gateway=${_IPV4_GWAY}"}"
	__BOPT+="${_IPV4_NSVR:+"${__BOPT:+" "}netcfg/get_nameservers=${_IPV4_NSVR}"}"
	# --- locale --------------------------------------------------------------
	case "${__TGET_LIST[2]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) __BOPT+="${__BOPT:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                ) __BOPT+="${__BOPT:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	# --- finish --------------------------------------------------------------
	echo -n "${__BOPT}"
}

# --- create boot options for nocloud -----------------------------------------
function funcRemastering_nocloud() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare       __BOPT=""				# boot options
	declare       __HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for nocloud" 1>&2
	__BOPT=""
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__WORK="automatic-ubiquity noprompt autoinstall ds='nocloud;s=/cdrom${__TGET_LIST[23]#"${_DIRS_CONF}"}'"
		case "${__TGET_LIST[2]}" in
			ubuntu-live-18.* ) __BOPT+="${__BOPT:+" "}boot=casper ${__WORK}";;
			*                ) __BOPT+="${__BOPT:+" "}${__WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${__TGET_LIST[2]}" in
		ubuntu-live-18.04) __BOPT+="${__BOPT:+" "}ip=${_NICS_NAME},${_IPV4_ADDR},${_IPV4_MASK},${_IPV4_GWAY} hostname=${__HOST}.${_NWRK_WGRP}";;
		*                ) __BOPT+="${__BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}::${_NICS_NAME}:${_IPV4_ADDR:+static}:${_IPV4_NSVR} hostname=${__HOST}.${_NWRK_WGRP}";;
	esac
	# --- locale --------------------------------------------------------------
	__BOPT+="${__BOPT:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${__BOPT}"
}

# --- create boot options for kickstart ---------------------------------------
function funcRemastering_kickstart() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare       __BOPT=""				# boot options
	declare       __HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for kickstart" 1>&2
	__BOPT=""
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__BOPT+="${__BOPT:+" "}inst.ks=hd:sr0:${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__BOPT+="${__TGET_LIST[16]:+"${__BOPT:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	__BOPT+="${__BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}:${__HOST}.${_NWRK_WGRP}:${_NICS_NAME}:none,auto6 nameserver=${_IPV4_NSVR}"
	# --- locale --------------------------------------------------------------
	__BOPT+="${__BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${__BOPT}"
}

# --- create boot options for autoyast ----------------------------------------
function funcRemastering_autoyast() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables
	declare       __BOPT=""				# boot options
	declare       __HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for autoyast" 1>&2
	__BOPT=""
	__HOST="${_NWRK_HOST/:_DISTRO_:/"${__TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${__TGET_LIST[23]##-}" ]]; then
		__BOPT+="${__BOPT:+" "}inst.ks=hd:sr0:${__TGET_LIST[23]#"${_DIRS_CONF}"}"
		__BOPT+="${__TGET_LIST[16]:+"${__BOPT:+" "}${__TGET_LIST[16]:+inst.stage2=hd:LABEL="${__TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	case "${__TGET_LIST[2]}" in
		opensuse-*-15* ) __WORK="eth0";;
		*              ) __WORK="${_NICS_NAME}";;
	esac
	__BOPT+="${__BOPT:+" "}hostname=${__HOST}.${_NWRK_WGRP} ifcfg=${__WORK}=${_IPV4_ADDR}/${_IPV4_CIDR},${_IPV4_GWAY},${_IPV4_NSVR},${_NWRK_WGRP}"
	# --- locale --------------------------------------------------------------
	__BOPT+="${__BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${__BOPT}"
}

# --- create boot options -----------------------------------------------------
function funcRemastering_boot_options() {
	declare -r -a __TGET_LIST=("$@")	# target data
	declare       __WORK=""				# work variables

	# --- create boot options -------------------------------------------------
	case "${__TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${__TGET_LIST[23]}" in
				*/preseed/* ) __WORK="$(set -e; funcRemastering_preseed "${__TGET_LIST[@]}")";;
				*/nocloud/* ) __WORK="$(set -e; funcRemastering_nocloud "${__TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) __WORK="$(set -e; funcRemastering_kickstart "${__TGET_LIST[@]}")";;
		opensuse     ) __WORK="$(set -e; funcRemastering_autoyast "${__TGET_LIST[@]}")";;
		*            ) ;;
	esac
	__WORK+="${_MENU_MODE:+"${__WORK:+" "}vga=${_MENU_MODE}"}"
	__WORK+="${__WORK:+" "}fsck.mode=skip"
	echo -n "${__WORK}"
}

# --- create path for configuration file --------------------------------------
function funcRemastering_path() {
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

# --- create autoinstall configuration file for isolinux ----------------------
function funcRemastering_isolinux_autoinst_cfg() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    __BOOT_OPTN="${3}"	# boot options
	declare -r -a __TGET_LIST=("${@:4}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FTHM=""				# theme.txt
	declare       __FKNL=""				# kernel
	declare       __FIRD=""				# initrd

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
		menu helpmsgrow 34
		menu cmdlinerow 36
		menu timeoutrow 36
		menu tabmsgrow 38
		menu tabmsg Press ENTER to boot or TAB to edit a menu entry
		timeout ${_MENU_TOUT:-5}0
		default auto_install

_EOT_
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
		  kernel ${__FKNL}
		  append${__FIRD:+" initrd=${__FIRD}"}${__BOOT_OPTN:+" "}${__BOOT_OPTN} ---
		
_EOT_
		# --- graphical installation mode -------------------------------------
		while read -r __DIRS
		do
			__FKNL="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[22]##*/}"	# kernel
			__FIRD="${__DIRS:+/"${__DIRS}"}/${__TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH}" || true
				label auto_install_gui
				  menu label ^Automatic installation of gui
				  kernel ${__FKNL}
				  append${__FIRD:+" initrd=${__FIRD}"}${__BOOT_OPTN:+" "}${__BOOT_OPTN} ---
			
_EOT_
		done < <(find "${__DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing isolinux for autoinstall ----------------------------------------
function funcRemastering_isolinux() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __BOOT_OPTN="${2}"	# boot options
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
		__FNAM="$(set -e; funcRemastering_path "${__PATH}" "${__DIRS_TGET}")"	# isolinux.cfg
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
		funcRemastering_isolinux_autoinst_cfg "${__DIRS_TGET}" "${__PAUT}" "${__BOOT_OPTN}" "${__TGET_LIST[@]}"
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

# --- create autoinstall configuration file for grub --------------------------
function funcRemastering_grub_autoinst_cfg() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    __BOOT_OPTN="${3}"	# boot options
	declare -r -a __TGET_LIST=("${@:4}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# full path
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __FKNL=""				# kernel
	declare       __FIRD=""				# initrd
	declare       __FTHM=""				# theme.txt
	declare       __FPNG=""				# splash.png

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
			  set gfxpayload=keep
			  set background_color=black
			  echo 'Loading kernel ...'
			  linux  ${__FKNL}${__BOOT_OPTN:+" ${__BOOT_OPTN}"} ---
			  echo 'Loading initial ramdisk ...'
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
				  set gfxpayload=keep
				  set background_color=black
				  echo 'Loading kernel ...'
				  linux  ${__FKNL}${__BOOT_OPTN:+" ${__BOOT_OPTN}"} ---
				  echo 'Loading initial ramdisk ...'
				  initrd ${__FIRD}
				}
				
_EOT_
		done < <(find "${__DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing grub for autoinstall --------------------------------------------
function funcRemastering_grub() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r    __BOOT_OPTN="${2}"	# boot options
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
		__FNAM="$(set -e; funcRemastering_path "${__PATH}" "${__DIRS_TGET}")"	# grub.cfg
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
		funcRemastering_grub_autoinst_cfg "${__DIRS_TGET}" "${__PAUT}" "${__BOOT_OPTN}" "${__TGET_LIST[@]}"
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

# --- copy auto-install files -------------------------------------------------
function funcRemastering_copy() {
	declare -r    __DIRS_TGET="${1:?}"	# target directory
	declare -r -a __TGET_LIST=("${@:2}") # target data
	declare       __WORK=""				# work variables
	declare       __PATH=""				# file name
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

# --- remastering for initrd --------------------------------------------------
function funcRemastering_initrd() {
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
	funcSplit_initramfs "${__DIRS_TGET}${__FIRD}" "${__DTMP}"
	__DTOP="${__DTMP}"
	if [[ -d "${__DTOP}/main/." ]]; then
		__DTOP+="/main"
	fi
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${__DTOP}" "${__TGET_LIST[@]}"
#	ln -s "${__TGET_LIST[23]#"${_DIRS_CONF}"}" "${__DTOP}/preseed.cfg"
	# --- repackaging ---------------------------------------------------------
	pushd "${__DTOP}" > /dev/null || exit
		find . | cpio --format=newc --create --quiet | gzip > "${__DIRS_TGET}${__FIRD%/*}/${_MINI_IRAM}" || true
	popd > /dev/null || exit

	rm -rf "${__DTMP:?}"
}

# --- remastering for media ---------------------------------------------------
function funcRemastering_media() {
	declare -r    __DIRS_TGET="${1:?}"						# target directory
	declare -r -a __TGET_LIST=("${@:2}")					# target data
	declare -r    __DWRK="${_DIRS_TEMP}/${__TGET_LIST[2]}"	# work directory
#	declare       __PATH=""									# file name
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
#	__VLID="$(funcGetVolID "${__TGET_LIST[13]}")"
	__FEFI="$(funcDistro2efi "${__TGET_LIST[2]%%-*}")"
	# --- create iso image file -----------------------------------------------
	if [[ -e "${__DIRS_TGET}/${__FEFI}" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "info" "xorriso (hybrid)" 1>&2
		__FHBR="$(find /usr/lib  -iname 'isohdpfx.bin' -type f || true)"
		funcCreate_iso "${__DIRS_TGET}" "${__TGET_LIST[17]}" \
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
		funcCreate_iso "${__DIRS_TGET}" "${__TGET_LIST[17]}" \
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

# --- remastering -------------------------------------------------------------
function funcRemastering() {
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
	declare       __PATH=""									# file name
	declare       __FEFI=""									# "         (efiboot.img)
	declare       __BOPT=""									# boot options
	
	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[92m"}%20.20s: %-20.20s: %s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" "${__TGET_LIST[13]##*/}" 1>&2

	# --- pre-check -----------------------------------------------------------
	__FEFI="$(funcDistro2efi "${__TGET_LIST[2]%%-*}")"
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
	__BOPT="$(set -e; funcRemastering_boot_options "${__TGET_LIST[@]}")"
	# --- create autoinstall configuration file for isolinux ------------------
	funcRemastering_isolinux "${__DMRG}" "${__BOPT}" "${__TGET_LIST[@]}"
	# --- create autoinstall configuration file for grub ----------------------
	funcRemastering_grub "${__DMRG}" "${__BOPT}" "${__TGET_LIST[@]}"
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${__DMRG}" "${__TGET_LIST[@]}"
	# --- remastering for initrd ----------------------------------------------
	case "${__TGET_LIST[2]}" in
		*-mini-*         ) funcRemastering_initrd "${__DMRG}" "${__TGET_LIST[@]}";;
		*                ) ;;
	esac
	# --- create iso image file -----------------------------------------------
	funcRemastering_media "${__DMRG}" "${__TGET_LIST[@]}"
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

## --- remastering -------------------------------------------------------------
#function funcRemastering() {
#	declare -r    __COMD_TYPE="$1"		# command type
#	shift
#	declare -a    __TGET_LIST=("$@")		# target data
#	declare -i    __IDNO=0				# id number (1..)
#	declare       _COLR=""				# message color
#	declare       __MESG=""				# message text
#	declare       __WORK=""				# work variables
#	declare -a    _LIST=()				# work variables
#	declare -i    I=0					# work variables
#
#	for I in "${!__TGET_LIST[@]}"
#	do
#		read -r -a _LIST < <(echo "${__TGET_LIST[I]}")
#		# --- remastering -----------------------------------------------------
#		case "${__COMD_TYPE}" in
#			create|update)
#				if [[ -n "${_LIST[23]##-}" ]] && [[ -n "${_LIST[24]##-}" ]]; then
#					case "${__COMD_TYPE}" in
#						create)			# --- force create --------------------
#							;;
#						update)			# --- update --------------------------
#							;;
#					esac
#					funcRemastering "${_LIST[@]}"
#					# --- new local remaster iso files ------------------------
#					__WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
#					read -r -a _ARRY < <(echo "${__WORK}")
##					_LIST[17]="${_ARRY[0]:--}"		# rmk_path
#					_LIST[18]="${_ARRY[1]:--}"		# rmk_tstamp
#					_LIST[19]="${_ARRY[2]:--}"		# rmk_size
#					_LIST[20]="${_ARRY[3]:--}"		# rmk_volume
#				fi
#				;;
#			*) ;;
#		esac
#		# --- update media data record ----------------
#		__TGET_LIST[I]="${_LIST[*]}"
#	done
#	funcPut_media_data
#}
#
# --- print out of menu -------------------------------------------------------
function funcPrint_menu() {
	declare -n    _RETN_VALU="$1"		# return value
	declare -r    __COMD_TYPE="$2"		# command type
	declare -a    __TGET_LIST=("${@:3}") # target data
	declare -i    __IDNO=0				# id number (1..)
	declare       __CLR0=""				# message color (line)
	declare       __CLR1=""				# message color (word)
	declare       __MESG=""				# message text
	declare       __RETN=""				# return value
	declare       __WORK=""				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    J=0					# work variables

	for I in "${!__TGET_LIST[@]}"
	do
		read -r -a __LIST < <(echo "${__TGET_LIST[I]}")
		__LIST=("${__LIST[@]##-}")
		case "${__COMD_TYPE}" in
			list)
				case "${__LIST[1]:--}" in
					m) continue;;
					*) ;;
				esac
				;;
			*)
				case "${__LIST[1]:--}" in
					o) ;;
					m)
						printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "# ${_TEXT_GAP1:1:((${#_TEXT_GAP1}-4))} #" 1>&2
						case "${__LIST[3]:--}" in
							-) ;;
							*)
								__IDNO=1
								printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}#%-2.2s:%-42.42s:%-10.10s:%-10.10s:%-$((${_SIZE_COLS:-80}-70)).$((${_SIZE_COLS:-80}-70))s${_CODE_ESCP:+"${_CODE_ESCP}[m"}#\n" "ID" "Version" "ReleaseDay" "SupportEnd" "Memo" 1>&2
								;;
						esac
						continue
						;;
					*) continue;;
				esac
				if [[ -z "${__LIST[3]}" ]]; then
					continue
				fi
				if [[ -z "${__LIST[13]}" ]]; then
					continue
				fi
				;;
		esac
		# --- web original iso file -------------------------------------------
		__RETN=""
		__MESG=""											# contents
		if [[ -n "${__LIST[8]}" ]]; then
			funcGetWeb_info __RETN "${__LIST[8]}"				# web_regexp
			read -r -a _ARRY < <(echo "${__RETN:-"- - - -"}")
			_ARRY=("${_ARRY[@]##-}")
			if [[ -n "${_ARRY[0]}" ]]; then
				__LIST[9]="${_ARRY[0]:-}"					# web_path
				__LIST[10]="${_ARRY[1]:-}"					# web_tstamp
				__LIST[11]="${_ARRY[2]:-}"					# web_size
				__LIST[12]="${_ARRY[3]:-}"					# web_status
			fi
			__MESG="${_ARRY[4]:--}"		# contents
		fi
		# --- local original iso file -----------------------------------------
		if [[ -n "${__LIST[13]}" ]]; then
			funcGetFileinfo __RETN "${__LIST[13]}"			# iso_path
			read -r -a _ARRY < <(echo "${__RETN:-"- - - -"}")
			_ARRY=("${_ARRY[@]##-}")
			if [[ -n "${_ARRY[0]}" ]]; then
#				__LIST[13]="${_ARRY[0]:-}"					# iso_path
				__LIST[14]="${_ARRY[1]:-}"					# iso_tstamp
				__LIST[15]="${_ARRY[2]:-}"					# iso_size
				__LIST[16]="${_ARRY[3]:-}"					# iso_volume
			fi
		fi
		# --- local remastering iso file --------------------------------------
		if [[ -n "${__LIST[17]}" ]]; then
			funcGetFileinfo __RETN "${__LIST[17]}"			# rmk_path
			read -r -a _ARRY < <(echo "${__RETN:-"- - - -"}")
			_ARRY=("${_ARRY[@]##-}")
			if [[ -n "${_ARRY[0]}" ]]; then
#				__LIST[17]="${_ARRY[0]:-}"					# rmk_path
				__LIST[18]="${_ARRY[1]:-}"					# rmk_tstamp
				__LIST[19]="${_ARRY[2]:-}"					# rmk_size
				__LIST[20]="${_ARRY[3]:-}"					# rmk_volume
			fi
		fi
		# --- config file  ----------------------------------------------------
		if [[ -n "${__LIST[23]}" ]]; then
			if [[ -d "${__LIST[23]}" ]]; then				# cfg_path: cloud-init
				funcGetFileinfo __RETN "${__LIST[23]}/user-data"
			else											# cfg_path
				funcGetFileinfo __RETN "${__LIST[23]}"
			fi
			read -r -a _ARRY < <(echo "${__RETN:-"- - - -"}")
			_ARRY=("${_ARRY[@]##-}")
			if [[ -n "${_ARRY[0]}" ]]; then
#				__LIST[23]="${_ARRY[0]:-}"					# cfg_path
				__LIST[24]="${_ARRY[1]:-}"					# cfg_tstamp
			fi
		fi
		# --- print out -------------------------------------------------------
		# https://httpwg.org/specs/rfc9110.html#overview.of.status.codes
		# 1xx (Informational): The request was received, continuing process
		# 2xx (Successful)   : The request was successfully received, understood, and accepted
		# 3xx (Redirection)  : Further action needs to be taken in order to complete the request
		# 4xx (Client Error) : The request contains bad syntax or cannot be fulfilled
		# 5xx (Server Error) : The server failed to fulfill an apparently valid request
		__MESG=""
		__CLR0=""
		__CLR1=""
		if [[ -n "${__LIST[14]##-}" ]]; then
			if [[ -n "${__LIST[18]##-}" ]]; then
				__WORK="$(funcDateDiff "${__LIST[18]}" "${__LIST[14]}")"
				if [[ "${__WORK}" -gt 0 ]]; then
					__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}"	# remaster < local
				fi
			fi
			if [[ -n "${__LIST[10]##-}" ]]; then
				__WORK="$(funcDateDiff "${__LIST[10]}" "${__LIST[14]}")"
				if [[ "${__WORK}" -lt 0 ]]; then
					__CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[92m"}"	# web > local
				fi
			fi
		fi
		case "${__LIST[12]:--}" in
			-  ) ;;
			200) ;;
			1??) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			2??) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			3??) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR1="${_CODE_ESCP:+"${_CODE_ESCP}[93m"}";;
			4??) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
			5??) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
			*  ) __MESG="$(set -e; funcGetWeb_status "${__LIST[12]}")"; __CLR0="${_CODE_ESCP:+"${_CODE_ESCP}[91m"}";;
		esac
		__MESG="${__MESG//%20/ }"
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}#${__CLR0}%2d:%-42.42s:%-10.10s:%-10.10s:${__CLR1}%-$((_SIZE_COLS-70)).$((_SIZE_COLS-70))s${_CODE_ESCP:+"${_CODE_ESCP}[m"}#\n" "${__IDNO}" "${__LIST[13]##*/}" "${__LIST[10]:+"${__LIST[10]::10}"}${__LIST[14]:-"${__LIST[6]::10}"}" "${__LIST[7]::10}" "${__MESG:-"${__LIST[23]##*/}"}" 1>&2
		((__IDNO+=1))
		# --- update media data record ----------------------------------------
		for J in "${!__LIST[@]}"
		do
			__LIST[J]="${__LIST[J]:--}"		# empty
			__LIST[J]="${__LIST[J]// /%20}"	# space
		done
		__TGET_LIST[I]="$( \
			printf "%-15s %-15s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-85s %-47s %-15s %-43s %-85s %-47s %-15s %-43s %-85s %-85s %-85s %-47s %-85s" \
				"${__LIST[@]}" \
		)"
	done
	_RETN_VALU="$(printf "%s\n" "${__TGET_LIST[@]}")"
}
