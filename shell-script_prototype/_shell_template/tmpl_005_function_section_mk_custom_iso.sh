# === <remastering> ===========================================================

# --- create boot options for preseed -----------------------------------------
function funcRemastering_preseed() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for preseed" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="auto=true preseed/file=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		case "${_TGET_LIST[2]}" in
			ubuntu-desktop-* | \
			ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}automatic-ubiquity noprompt ${_WORK}";;
			*-mini-*         ) _BOPT+="${_BOPT:+" "}${_WORK/\/cdrom/}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-*         ) _BOPT+="${_BOPT:+" "}netcfg/target_network_config=NetworkManager";;
		*                ) ;;
	esac
	_BOPT+="${_BOPT:+" "}netcfg/disable_autoconfig=true"
	_BOPT+="${_NICS_NAME:+"${_BOPT:+" "}netcfg/choose_interface=${_NICS_NAME}"}"
	_BOPT+="${_NWRK_HOST:+"${_BOPT:+" "}netcfg/get_hostname=${_HOST}.${_NWRK_WGRP}"}"
	_BOPT+="${_IPV4_ADDR:+"${_BOPT:+" "}netcfg/get_ipaddress=${_IPV4_ADDR}"}"
	_BOPT+="${_IPV4_MASK:+"${_BOPT:+" "}netcfg/get_netmask=${_IPV4_MASK}"}"
	_BOPT+="${_IPV4_GWAY:+"${_BOPT:+" "}netcfg/get_gateway=${_IPV4_GWAY}"}"
	_BOPT+="${_IPV4_NSVR:+"${_BOPT:+" "}netcfg/get_nameservers=${_IPV4_NSVR}"}"
	# --- locale --------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-desktop-* | \
		ubuntu-legacy-*  ) _BOPT+="${_BOPT:+" "}debian-installer/locale=ja_JP.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106";;
		*                ) _BOPT+="${_BOPT:+" "}language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese";;
	esac
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for nocloud -----------------------------------------
function funcRemastering_nocloud() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for nocloud" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_WORK="automatic-ubiquity noprompt autoinstall ds='nocloud;s=/cdrom${_TGET_LIST[23]#"${_DIRS_CONF}"}'"
		case "${_TGET_LIST[2]}" in
			ubuntu-live-18.* ) _BOPT+="${_BOPT:+" "}boot=casper ${_WORK}";;
			*                ) _BOPT+="${_BOPT:+" "}${_WORK}";;
		esac
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		ubuntu-live-18.04) _BOPT+="${_BOPT:+" "}ip=${_NICS_NAME},${_IPV4_ADDR},${_IPV4_MASK},${_IPV4_GWAY} hostname=${_HOST}.${_NWRK_WGRP}";;
		*                ) _BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}::${_NICS_NAME}:${_IPV4_ADDR:+static}:${_IPV4_NSVR} hostname=${_HOST}.${_NWRK_WGRP}";;
	esac
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}debian-installer/locale=en_US.UTF-8 keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for kickstart ---------------------------------------
function funcRemastering_kickstart() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for kickstart" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}ip=${_IPV4_ADDR}::${_IPV4_GWAY}:${_IPV4_MASK}:${_HOST}.${_NWRK_WGRP}:${_NICS_NAME}:none,auto6 nameserver=${_IPV4_NSVR}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options for autoyast ----------------------------------------
function funcRemastering_autoyast() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _BOPT=""				# boot options
	declare       _HOST=""				# host name

	# --- boot option ---------------------------------------------------------
	printf "%20.20s: %s\n" "create" "boot options for autoyast" 1>&2
	_BOPT=""
	_HOST="${_NWRK_HOST/:_DISTRO_:/"${_TGET_LIST[2]%%-*}"}"
	# --- autoinstall ---------------------------------------------------------
	if [[ -n "${_TGET_LIST[23]##-}" ]]; then
		_BOPT+="${_BOPT:+" "}inst.ks=hd:sr0:${_TGET_LIST[23]#"${_DIRS_CONF}"}"
		_BOPT+="${_TGET_LIST[16]:+"${_BOPT:+" "}${_TGET_LIST[16]:+inst.stage2=hd:LABEL="${_TGET_LIST[16]}"}"}"
	fi
	# --- network -------------------------------------------------------------
	case "${_TGET_LIST[2]}" in
		opensuse-*-15* ) _WORK="eth0";;
		*              ) _WORK="${_NICS_NAME}";;
	esac
	_BOPT+="${_BOPT:+" "}hostname=${_HOST}.${_NWRK_WGRP} ifcfg=${_WORK}=${_IPV4_ADDR}/${_IPV4_CIDR},${_IPV4_GWAY},${_IPV4_NSVR},${_NWRK_WGRP}"
	# --- locale --------------------------------------------------------------
	_BOPT+="${_BOPT:+" "}locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106"
	# --- finish --------------------------------------------------------------
	echo -n "${_BOPT}"
}

# --- create boot options -----------------------------------------------------
function funcRemastering_boot_options() {
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables

	# --- create boot options -------------------------------------------------
	case "${_TGET_LIST[2]%%-*}" in
		debian       | \
		ubuntu       )
			case "${_TGET_LIST[23]}" in
				*/preseed/* ) _WORK="$(funcRemastering_preseed "${_TGET_LIST[@]}")";;
				*/nocloud/* ) _WORK="$(funcRemastering_nocloud "${_TGET_LIST[@]}")";;
				*           ) ;;
			esac
			;;
		fedora       | \
		centos       | \
		almalinux    | \
		rockylinux   | \
		miraclelinux ) _WORK="$(funcRemastering_kickstart "${_TGET_LIST[@]}")";;
		opensuse     ) _WORK="$(funcRemastering_autoyast "${_TGET_LIST[@]}")";;
		*            ) ;;
	esac
	_WORK+="${_MENU_MODE:+"${_WORK:+" "}vga=${_MENU_MODE}"}"
	_WORK+="${_WORK:+" "}fsck.mode=skip"
	echo -n "${_WORK}"
}

# --- create path for configuration file --------------------------------------
function funcRemastering_path() {
	declare -r    _PATH_TGET="${1:?}"	# target path
	declare -r    _DIRS_TGET="${2:?}"	# directory
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name

	_FNAM="${_PATH_TGET##*/}"
	_DIRS="${_PATH_TGET%"${_FNAM}"}"
	_DIRS="${_DIRS#"${_DIRS_TGET}"}"
	_DIRS="${_DIRS%%/}"
	_DIRS="${_DIRS##/}"
	echo -n "${_DIRS:+/"${_DIRS}"}/${_FNAM}"
}

# --- create autoinstall configuration file for isolinux ----------------------
function funcRemastering_isolinux_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd

	# --- header section ------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_MENU}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_FTHM}" || true
		menu resolution ${_MENU_RESO/x/ }
		menu title Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}
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
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
		label auto_install
		  menu label ^Automatic installation
		  menu default
		  kernel ${_FKNL}
		  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
		
_EOT_
		# --- graphical installation mode -------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
				label auto_install_gui
				  menu label ^Automatic installation of gui
				  kernel ${_FKNL}
				  append${_FIRD:+" initrd=${_FIRD}"}${_BOOT_OPTN:+" "}${_BOOT_OPTN} ---
			
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing isolinux for autoinstall ----------------------------------------
function funcRemastering_isolinux() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FTHM=""				# theme.txt
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# isolinux.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTHM="${_FNAM%/*}/theme.txt"
		_FTMP="${_PATH}.tmp"
		if grep -qEi '^include[ \t]+menu.cfg[ \t]*.*$' "${_PATH}"; then
			sed -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/i include '"${_PAUT}"'' \
			    -e '/^\([Ii]nclude\|INCLUDE\)[ \t]\+menu.cfg[ \t]*.*$/a include '"${_FTHM}"'' \
				"${_PATH}"                                                                    \
			>	"${_FTMP}"
		else
			sed -e '0,/\([Ll]abel\|LABEL\)/ {'                     \
				-e '/\([Ll]abel\|LABEL\)/i include '"${_PAUT}"'\n' \
				-e '}'                                             \
				"${_PATH}"                                         \
			>	"${_FTMP}"
		fi
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for isolinux --------------
		funcRemastering_isolinux_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'isolinux.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
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
			"${_PATH}"                                                                   \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- create autoinstall configuration file for grub --------------------------
function funcRemastering_grub_autoinst_cfg() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _PATH_MENU="${2:?}"	# file name (autoinst.cfg)
	declare -r    _BOOT_OPTN="${3}"		# boot options
	shift 3
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _FTHM=""				# theme.txt
	declare       _FPNG=""				# splash.png

	# --- theme section -------------------------------------------------------
	_PATH="${_DIRS_TGET}${_PATH_MENU}"
	_FTHM="${_PATH%/*}/theme.txt"
	_WORK="$(date -d "${_TGET_LIST[18]//%20/ }" +"%Y/%m/%d %H:%M:%S")"
	for _DIRS in / /isolinux /boot/grub /boot/grub/theme
	do
		_FPNG="${_DIRS}/splash.png"
		if [[ -e "${_DIRS_TGET}/${_FPNG}" ]]; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}" || true
				desktop-image: "${_FPNG}"
_EOT_
			break
		fi
	done
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_FTHM}" || true
		desktop-color: "#000000"
		title-color: "#ffffff"
		title-font: "Unifont Regular 16"
		title-text: "Boot Menu: ${_TGET_LIST[17]##*/} ${_WORK}"
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
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${_PATH}" || true
		#set gfxmode=${_MENU_RESO:+"${_MENU_RESO}${_MENU_DPTH:+x"${_MENU_DPTH}"},"}auto
		#set default=0
		set timeout=${_MENU_TOUT:-5}
		set timeout_style=menu
		set theme=${_FTHM#"${_DIRS_TGET}"}
		export theme
		
_EOT_
	# --- standard installation mode ------------------------------------------
	if [[ -n "${_TGET_LIST[22]#-}" ]]; then
		_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
		_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"				# kernel
		_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"				# initrd
		case "${_TGET_LIST[2]}" in
			*-mini-*         ) _FIRD="${_FIRD%/*}/${_MINI_IRAM}";;
			*                ) ;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
			menuentry 'Automatic installation' {
			  set gfxpayload=keep
			  set background_color=black
			  echo 'Loading kernel ...'
			  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
			  echo 'Loading initial ramdisk ...'
			  initrd ${_FIRD}
			}

_EOT_
	# --- graphical installation mode -----------------------------------------
		while read -r _DIRS
		do
			_FKNL="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[22]##*/}"	# kernel
			_FIRD="${_DIRS:+/"${_DIRS}"}/${_TGET_LIST[21]##*/}"	# initrd
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${_PATH}" || true
				menuentry 'Automatic installation of gui' {
				  set gfxpayload=keep
				  set background_color=black
				  echo 'Loading kernel ...'
				  linux  ${_FKNL}${_BOOT_OPTN:+" ${_BOOT_OPTN}"} ---
				  echo 'Loading initial ramdisk ...'
				  initrd ${_FIRD}
				}
				
_EOT_
		done < <(find "${_DIRS_TGET}" -name 'gtk' -type d -printf '%P\n' || true)
	fi
}

# --- editing grub for autoinstall --------------------------------------------
function funcRemastering_grub() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	declare -r    _BOOT_OPTN="${2}"		# boot options
	shift 2
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# full path
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _FTMP=""				# file name (.tmp)
	declare       _PAUT=""				# full path (autoinst.cfg)

	# --- insert "autoinst.cfg" -----------------------------------------------
	_PAUT=""
	while read -r _PATH
	do
		_FNAM="$(funcRemastering_path "${_PATH}" "${_DIRS_TGET}")"				# grub.cfg
		_PAUT="${_FNAM%/*}/${_AUTO_INST}"
		_FTMP="${_PATH}.tmp"
		if ! grep -qEi '^menuentry[ \t]+.*$' "${_PATH}"; then
			continue
		fi
		sed -e '0,/^menuentry/ {'                    \
			-e '/^menuentry/i source '"${_PAUT}"'\n' \
			-e '}'                                   \
				"${_PATH}"                           \
			>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
		# --- create autoinstall configuration file for grub ------------------
		funcRemastering_grub_autoinst_cfg "${_DIRS_TGET}" "${_PAUT}" "${_BOOT_OPTN}" "${_TGET_LIST[@]}"
	done < <(find "${_DIRS_TGET}" -name 'grub.cfg' -type f || true)
	# --- comment out ---------------------------------------------------------
	if [[ -z "${_PAUT}" ]]; then
		return
	fi
	while read -r _PATH
	do
		_FTMP="${_PATH}.tmp"
		sed -e '/^[ \t]*\(\|set[ \t]\+\)default=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)timeout=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)gfxmode=/ d' \
			-e '/^[ \t]*\(\|set[ \t]\+\)theme=/   d' \
			"${_PATH}"                               \
		>	"${_FTMP}"
		if ! cmp --quiet "${_PATH}" "${_FTMP}"; then
			cp -a "${_FTMP}" "${_PATH}"
		fi
		rm -f "${_FTMP:?}"
	done < <(find "${_DIRS_TGET}" \( -name '*.cfg' -a ! -name "${_AUTO_INST##*/}" \) -type f || true)
}

# --- copy auto-install files -------------------------------------------------
function funcRemastering_copy() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _WORK=""				# work variables
	declare       _PATH=""				# file name
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _BASE=""				# base name
	declare       _EXTN=""				# extension

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "copy" "auto-install files" 1>&2

	# -------------------------------------------------------------------------
	for _PATH in        \
		"${_SHEL_ERLY}" \
		"${_SHEL_LATE}" \
		"${_SHEL_PART}" \
		"${_SHEL_RUNS}" \
		"${_TGET_LIST[23]}"
	do
		if [[ ! -e "${_PATH}" ]]; then
			continue
		fi
		_DIRS="${_DIRS_TGET}${_PATH#"${_DIRS_CONF}"}"
		_DIRS="${_DIRS%/*}"
		mkdir -p "${_DIRS}"
		case "${_PATH}" in
			*/script/*   )
				printf "%20.20s: %s\n" "copy" "${_PATH#"${_DIRS_CONF}"/}" 1>&2
				cp -a "${_PATH}" "${_DIRS}"
				chmod ugo+xr-w "${_DIRS}/${_PATH##*/}"
				;;
			*/autoyast/* | \
			*/kickstart/*| \
			*/nocloud/*  | \
			*/preseed/*  )
#				_SEED="${_PATH%/*}"
#				_SEED="${_SEED##*/}"
				_FNAM="${_PATH##*/}"
				_WORK="${_FNAM%.*}"
				_EXTN="${_FNAM#"${_WORK}"}"
				_BASE="${_FNAM%"${_EXTN}"}"
				_WORK="${_BASE#*_*_}"
				_WORK="${_BASE%"${_WORK}"}"
				_WORK="${_PATH#*"${_WORK:-${_BASE%%_*}}"}"
				_WORK="${_PATH%"${_WORK}"*}"
				printf "%20.20s: %s\n" "copy" "${_WORK#"${_DIRS_CONF}"/}*${_EXTN}" 1>&2
				find "${_WORK%/*}" -name "${_WORK##*/}*${_EXTN}" -exec cp -a '{}' "${_DIRS}" \;
				find "${_DIRS}" -exec chmod ugo+r-xw '{}' \;
				;;
			*/windows/*  ) ;;
			*            ) ;;
		esac
	done
}

# --- remastering for initrd --------------------------------------------------
function funcRemastering_initrd() {
	declare -r    _DIRS_TGET="${1:?}"	# target directory
	shift
	declare -r -a _TGET_LIST=("$@")		# target data
	declare       _FKNL=""				# kernel
	declare       _FIRD=""				# initrd
	declare       _DTMP=""				# directory (extract)
	declare       _DTOP=""				# directory (main)
	declare       _DIRS=""				# directory

	# -------------------------------------------------------------------------
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "remake" "initrd" 1>&2

	# -------------------------------------------------------------------------
	_DIRS="${_DIRS_LOAD}/${_TGET_LIST[2]}"
	_FKNL="${_TGET_LIST[22]#"${_DIRS}"}"					# kernel
	_FIRD="${_TGET_LIST[21]#"${_DIRS}"}"					# initrd
	_DTMP="$(mktemp -qd "${TMPDIR:-/tmp}/${_FIRD##*/}.XXXXXX")"

	# --- extract -------------------------------------------------------------
	funcSplit_initramfs "${_DIRS_TGET}${_FIRD}" "${_DTMP}"
	_DTOP="${_DTMP}"
	if [[ -d "${_DTOP}/main/." ]]; then
		_DTOP+="/main"
	fi
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DTOP}" "${_TGET_LIST[@]}"
#	ln -s "${_TGET_LIST[23]#"${_DIRS_CONF}"}" "${_DTOP}/preseed.cfg"
	# --- repackaging ---------------------------------------------------------
	pushd "${_DTOP}" > /dev/null || exit
		find . | cpio --format=newc --create --quiet | gzip > "${_DIRS_TGET}${_FIRD%/*}/${_MINI_IRAM}" || true
	popd > /dev/null || exit

	rm -rf "${_DTMP:?}"
}

# --- remastering for media ---------------------------------------------------
function funcRemastering_media() {
	declare -r    _DIRS_TGET="${1:?}"						# target directory
	shift
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
#	declare       _PATH=""									# file name
	declare       _FMBR=""									# "         (mbr.img)
	declare       _FEFI=""									# "         (efi.img)
	declare       _FCAT=""									# "         (boot.cat or boot.catalog)
	declare       _FBIN=""									# "         (isolinux.bin or eltorito.img)
	declare       _FHBR=""									# "         (isohdpfx.bin)
	declare       _VLID=""									# 
	declare -i    _SKIP=0									# 
	declare -i    _SIZE=0									# 

	# --- pre-processing ------------------------------------------------------
#	_PATH="${_DWRK}/${_TGET_LIST[17]##*/}.tmp"				# file path
	_FCAT="$(find "${_DIRS_TGET}" \( -iname 'boot.cat'     -o -iname 'boot.catalog' \) -type f -printf "%P" || true)"
	_FBIN="$(find "${_DIRS_TGET}" \( -iname 'isolinux.bin' -o -iname 'eltorito.img' \) -type f -printf "%P" || true)"
	_VLID="$(funcGetVolID "${_TGET_LIST[13]}")"
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	# --- create iso image file -----------------------------------------------
	if [[ -e "${_DIRS_TGET}/${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (hybrid)" 1>&2
		_FHBR="$(find /usr/lib  -iname 'isohdpfx.bin' -type f || true)"
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-cache-inodes \
			${_FHBR:+-isohybrid-mbr "${_FHBR}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			-boot-load-size 4 -boot-info-table \
			-no-emul-boot \
			-eltorito-alt-boot ${_FEFI:+-e "${_FEFI}"} \
			-no-emul-boot \
			-isohybrid-gpt-basdat -isohybrid-apm-hfsplus
	else
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %s${_CODE_ESCP}[m\n" "info" "xorriso (grub2-mbr)" 1>&2
		_FMBR="${_DWRK}/mbr.img"
		_FEFI="${_DWRK}/efi.img"
		# --- extract the mbr template ----------------------------------------
		dd if="${_TGET_LIST[13]}" bs=1 count=446 of="${_FMBR}" > /dev/null 2>&1
		# --- extract efi partition image -------------------------------------
		_SKIP=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $2;}' || true)
		_SIZE=$(fdisk -l "${_TGET_LIST[13]}" | awk '/.iso2/ {print $4;}' || true)
		dd if="${_TGET_LIST[13]}" bs=512 skip="${_SKIP}" count="${_SIZE}" of="${_FEFI}" > /dev/null 2>&1
		# --- create iso image file -------------------------------------------
		funcCreate_iso "${_DIRS_TGET}" "${_TGET_LIST[17]}" \
			-quiet -rational-rock \
			-volid "${_VLID}" \
			-joliet -joliet-long \
			-full-iso9660-filenames -iso-level 3 \
			-partition_offset 16 \
			${_FMBR:+--grub2-mbr "${_FMBR}"} \
			--mbr-force-bootable \
			${_FEFI:+-append_partition 2 0xEF "${_FEFI}"} \
			-appended_part_as_gpt \
			${_FCAT:+-eltorito-catalog "${_FCAT}"} \
			${_FBIN:+-eltorito-boot "${_FBIN}"} \
			-no-emul-boot \
			-boot-load-size 4 -boot-info-table \
			--grub2-boot-info \
			-eltorito-alt-boot -e '--interval:appended_partition_2:all::' \
			-no-emul-boot
	fi
}

# --- remastering -------------------------------------------------------------
function funcRemastering() {
	declare -i    _time_start=0								# start of elapsed time
	declare -i    _time_end=0								# end of elapsed time
	declare -i    _time_elapsed=0							# result of elapsed time
	declare -r -a _TGET_LIST=("$@")							# target data
	declare -r    _DWRK="${_DIRS_TEMP}/${_TGET_LIST[2]}"	# work directory
	declare -r    _DOVL="${_DWRK}/overlay"					# overlay
	declare -r    _DUPR="${_DOVL}/upper"					# upperdir
	declare -r    _DLOW="${_DOVL}/lower"					# lowerdir
	declare -r    _DWKD="${_DOVL}/work"						# workdir
	declare -r    _DMRG="${_DOVL}/merged"					# merged
	declare       _PATH=""									# file name
	declare       _FEFI=""									# "         (efiboot.img)
	declare       _BOPT=""									# boot options
	
	# --- start ---------------------------------------------------------------
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true)" "start" "${_TGET_LIST[13]##*/}" 1>&2

	# --- pre-check -----------------------------------------------------------
	_FEFI="$(funcDistro2efi "${_TGET_LIST[2]%%-*}")"
	if [[ -z "${_FEFI}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "unknown target" "${_TGET_LIST[2]%%-*} [${_TGET_LIST[13]##*/}]" 1>&2
		return
	fi
	if [[ ! -s "${_TGET_LIST[13]}" ]]; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[93m%20.20s: %s${_CODE_ESCP}[m\n" "not exist" "${_TGET_LIST[13]##*/}" 1>&2
		return
	fi
	if mountpoint --quiet "${_DMRG}"; then
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%20.20s: %s${_CODE_ESCP}[m\n" "already mounted" "${_DMRG#"${_DWRK}"/}" 1>&2
		return
	fi

	# --- pre-processing ------------------------------------------------------
	printf "%20.20s: %s\n" "start" "${_DMRG#"${_DWRK}"/}" 1>&2
	rm -rf "${_DOVL:?}"
	mkdir -p "${_DUPR}" "${_DLOW}" "${_DWKD}" "${_DMRG}"

	# --- main processing -----------------------------------------------------
	mount -r "${_TGET_LIST[13]}" "${_DLOW}"
	mount -t overlay overlay -o lowerdir="${_DLOW}",upperdir="${_DUPR}",workdir="${_DWKD}" "${_DMRG}"
	# --- create boot options -------------------------------------------------
	_BOPT="$(funcRemastering_boot_options "${_TGET_LIST[@]}")"
	# --- create autoinstall configuration file for isolinux ------------------
	funcRemastering_isolinux "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- create autoinstall configuration file for grub ----------------------
	funcRemastering_grub "${_DMRG}" "${_BOPT}" "${_TGET_LIST[@]}"
	# --- copy auto-install files ---------------------------------------------
	funcRemastering_copy "${_DMRG}" "${_TGET_LIST[@]}"
	# --- remastering for initrd ----------------------------------------------
	case "${_TGET_LIST[2]}" in
		*-mini-*         ) funcRemastering_initrd "${_DMRG}" "${_TGET_LIST[@]}";;
		*                ) ;;
	esac
	# --- create iso image file -----------------------------------------------
	funcRemastering_media "${_DMRG}" "${_TGET_LIST[@]}"
	umount "${_DMRG}"
	umount "${_DLOW}"

	# --- post-processing -----------------------------------------------------
	rm -rf "${_DOVL:?}"
	printf "%20.20s: %s\n" "finish" "${_DMRG#"${_DWRK}"/}" 1>&2

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%20.20s: %-20.20s: %s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true)" "finish" "${_TGET_LIST[13]##*/}" 1>&2
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%10dd%02dh%02dm%02ds: %-20.20s: %s${_CODE_ESCP}[m\n" "$((_time_elapsed/86400))" "$((_time_elapsed%86400/3600))" "$((_time_elapsed%3600/60))" "$((_time_elapsed%60))" "elapsed" "${_TGET_LIST[13]##*/}" 1>&2
}
