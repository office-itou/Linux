# === <pxeboot> ===============================================================

# --- file copy ---------------------------------------------------------------
function funcPxeboot_copy() {
	declare -r    __PATH_TGET="${1:?}"	# target file
	declare -r    __DIRS_DEST="${2:?}"	# destination directory
	declare       __MNTP=""				# mount point
	declare       __PATH=""				# full path
	              __PATH="$(mktemp -qd "${TMPDIR:-/tmp}/${__DIRS_DEST##*/}.XXXXXX")"
	readonly      __PATH

	if [[ ! -s "${__PATH_TGET}" ]]; then
		return
	fi
	printf "%20.20s: %s\n" "copy" "${__PATH_TGET}" 1>&2
	__MNTP="${__PATH}/mnt"
	rm -rf "${__MNTP:?}"
	mkdir -p "${__MNTP}" "${__DIRS_DEST}"
	mount -o ro,loop "${__PATH_TGET}" "${__MNTP}"
	nice -n "${_NICE_VALU:-19}" rsync "${_OPTN_RSYC[@]}" "${__MNTP}/." "${__DIRS_DEST}/" 2>/dev/null || true
	umount "${__MNTP}"
	chmod -R +r "${__DIRS_DEST}/" 2>/dev/null || true
	rm -rf "${__MNTP:?}"
}

# --- create boot options for preseed -----------------------------------------
function funcPxeboot_preseed() {
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
		__WORK="${__CONF:+"${__WORK/file=\/cdrom/url=${__CONF}}"}"
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
	__WORK=""
	case "${__TGET_LIST[2]}" in
#		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for nocloud -----------------------------------------
function funcPxeboot_nocloud() {
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
		__WORK="${__CONF:+"${__WORK/\/cdrom/${__CONF}}"}"
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
	__WORK=""
	case "${__TGET_LIST[2]}" in
#		debian-mini-*       ) ;;
		ubuntu-mini-*       ) __WORK+="${__WORK:+" "}initrd=${__IMGS}/${__TGET_LIST[21]#"${_DIRS_LOAD}"} iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-desktop-18.* | \
		ubuntu-desktop-20.* | \
		ubuntu-desktop-22.* | \
		ubuntu-live-18.*    | \
		ubuntu-live-20.*    | \
		ubuntu-live-22.*    | \
		ubuntu-server-*     | \
		ubuntu-legacy-*     ) __WORK+="${__WORK:+" "}boot=casper url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		ubuntu-*            ) __WORK+="${__WORK:+" "}boot=casper iso-url=${__ISOS}/${__TGET_LIST[13]##*/}";;
		*                   ) __WORK+="${__WORK:+" "}fetch=${__ISOS}/${__TGET_LIST[13]##*/}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for kickstart ---------------------------------------
function funcPxeboot_kickstart() {
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
		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
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
	__WORK=""
	__WORK+="${__WORK:+" "}inst.repo=${__IMGS}/${__TGET_LIST[2]}"
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
}

# --- create boot options for autoyast ----------------------------------------
function funcPxeboot_autoyast() {
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
		__WORK="${__CONF:+"${__WORK/_dvd/_web}"}"
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
	__WORK=""
	case "${__TGET_LIST[2]}" in
		opensuse-leap*netinst*      ) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/distribution/leap/${__TGET_LIST[2]##*-}/repo/oss/";;
		opensuse-tumbleweed*netinst*) __WORK+="${__WORK:+" "}install=https://download.opensuse.org/tumbleweed/repo/oss/";;
		*                           ) __WORK+="${__WORK:+" "}install=${__IMGS}/${__TGET_LIST[2]}";;
	esac
	__BOPT+=("${__WORK}")
	# --- finish --------------------------------------------------------------
	printf "%s\n" "${__BOPT[@]:-}"
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
function funcPxeboot_ipxe() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file

	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${__PATH_TGET:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			#!ipxe
			
			cpuid --ext 29 && set arch amd64 || set arch x86
			
			dhcp
			
			set optn-timeout 3000
			set menu-timeout 0
			isset \${menu-default} || set menu-default exit
			
			:start
			
			:menu
			menu Select the OS type you want to boot
			item --gap --                           --------------------------------------------------------------------------
			item --gap --                           [ System command ]
			item -- shell                           - iPXE shell
			#item -- shutdown                       - System shutdown
			item -- restart                         - System reboot
			item --gap --                           --------------------------------------------------------------------------
			choose --timeout \${menu-timeout} --default \${menu-default} selected || goto menu
			goto \${selected}
			
			:shell
			echo "Booting iPXE shell ..."
			shell
			goto start
			
			:shutdown
			echo "System shutting down ..."
			poweroff
			exit
			
			:restart
			echo "System rebooting ..."
			reboot
			exit
			
			:error
			prompt Press any key to continue
			exit
			
			:exit
			exit
_EOT_
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
				return
			fi
			__WORK="$(printf "%-40.40s[ %s ]" "item --gap --" "${__TGET_LIST[3]//%20/ }")"
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="${__TGET_LIST[2]}"
			case "${__TGET_LIST[0]}" in
				tool          ) ;;							# tools
				system        ) ;;							# system command
				custom_live   ) ;;							# custom media live mode
				custom_netinst) ;;							# custom media install mode
				live          ) __ENTR="live-${__ENTR}";;	# original media live mode
				*             ) ;;							# original media install mode
			esac
			__WORK="$(printf "%-40.40s%-55.55s%19.19s" "item -- ${__ENTR}" "- ${__TGET_LIST[3]//%20/ } ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							set cfgaddr \${srvraddr}/${_DIRS_CONF##*/}/windows
							echo Loading boot files ...
							kernel ipxe/wimboot
							initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
							initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
							initrd -n install.cmd \${cfgaddr}/inst_w${__TGET_LIST[2]##*-}.cmd  install.cmd  || goto error
							initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
							initrd \${knladdr}/boot/bcd                     BCD          || goto error
							initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim     || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							echo Loading boot files ...
							kernel ipxe/wimboot
							initrd \${knladdr}/boot/bcd                     BCD          || goto error
							initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
							initrd -n boot.wim \${knladdr}/sources/boot.wim boot.wim     || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				memtest86* )			# (memtest86)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							:${__ENTR}
							echo Loading ${__TGET_LIST[3]//%20/ } ...
							set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
							isset \${next-server} && set srvraddr \${next-server} ||
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							iseq \${platform} efi && set knlfile \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/} || set knlfile \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
							echo Loading boot files ...
							kernel \${knlfile} || goto error
							boot || goto error
							exit
							
_EOT_
					)"
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								:${__ENTR}
								echo Loading ${__TGET_LIST[3]//%20/ } ...
								set hostname ${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
								set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
								set ethrname ${_NICS_NAME:-ens160}
								set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
								set ipv4mask ${_IPV4_MASK:-}
								set ipv4gway ${_IPV4_GWAY:-}
								set ipv4nsvr ${_IPV4_NSVR:-}
								set autoinst ${__BOPT[1]:-}
								set networks ${__BOPT[2]:-}
								set language ${__BOPT[3]:-}
								set ramsdisk ${__BOPT[4]:-}
								set isosfile ${__BOPT[5]:-}
								
_EOT_
						)"
					else
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								:${__ENTR}
								echo Loading ${__TGET_LIST[3]//%20/ } ...
								set hostname ${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}
								set srvraddr ${_SRVR_PROT}://${_SRVR_ADDR:?}
								form                                    Configure Boot Options
								item hostname                           Hostname
								item srvraddr                           Server ip address
								present ||
								set ethrname ${_NICS_NAME:-ens160}
								set ipv4addr ${_IPV4_ADDR:-}/${_IPV4_CIDR:-}
								set ipv4mask ${_IPV4_MASK:-}
								set ipv4gway ${_IPV4_GWAY:-}
								set ipv4nsvr ${_IPV4_NSVR:-}
								form                                    Configure Boot Options
								item ethrname                           Interface
								item ipv4addr                           IPv4 address
								item ipv4mask                           IPv4 netmask
								item ipv4gway                           IPv4 gateway
								item ipv4nsvr                           IPv4 nameservers
								present ||
								set autoinst ${__BOPT[1]:-}
								set networks ${__BOPT[2]:-}
								set language ${__BOPT[3]:-}
								set ramsdisk ${__BOPT[4]:-}
								set isosfile ${__BOPT[5]:-}
								form                                    Configure Boot Options
								item autoinst                           Auto install
								item networks                           Network
								item language                           Language
								item ramsdisk                           RAM disk
								item isosfile                           ISO file
								present ||
								
_EOT_
						)"
					fi
					__WORK+="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
							set knladdr \${srvraddr}/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}
							set options \${autoinst} \${networks} \${language} \${ramsdisk} \${isosfile} ${__BOPT[@]:6}
							echo Loading kernel and initrd ...
							kernel \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/} \${options} --- || goto error
							initrd \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/} || goto error
							boot || goto error
							exit

_EOT_
					)"
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/^:shell$/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create grub.cfg ---------------------------------------------------------
function funcPxeboot_grub() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file
	declare       __SPCS=""				# tabs string (space)

	# --- tab string ----------------------------------------------------------
	if [[ "${__CONT_TABS}" -gt 0 ]]; then
		__SPCS="$(funcString $(("${__CONT_TABS}" * 2)) ' ')"
	else
		__SPCS=""
	fi
	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${_MENU_GRUB:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			set default="0"
			set timeout="-1"
			
			if [ "x\${feature_default_font_path}" = "xy" ] ; then
			  font="unicode"
			else
			  font="\${prefix}/fonts/font.pf2"
			fi
			
			if loadfont "\$font" ; then
			# set lang="ja_JP"
			  set gfxmode=${_MENU_RESO:+"${_MENU_RESO}x${_MENU_DPTH},"}auto
			  set gfxpayload="keep"
			  if [ "\${grub_platform}" = "efi" ]; then
			    insmod efi_gop
			    insmod efi_uga
			  else
			    insmod vbe
			    insmod vga
			  fi
			  insmod gfxterm
			  insmod gettext
			  terminal_output gfxterm
			fi
			
			set menu_color_normal="cyan/blue"
			set menu_color_highlight="white/blue"
			
			#export lang
			export gfxmode
			export gfxpayload
			export menu_color_normal
			export menu_color_highlight
			
			insmod play
			play 960 440 1 0 4 440 1
			
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
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
#			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
#				return
#			fi
			__WORK="[ ${__TGET_LIST[3]//%20/ } ... ]"
			case "${__TGET_LIST[3]}" in
				System%20command) return;;
				-               ) __WORK="}\n"                  ;;
				*               ) __WORK="submenu '${__WORK}' {";;
			esac
			sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="$(printf "%-55.55s%19.19s" "- ${__TGET_LIST[3]//%20/ }  ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							if [ "\${grub_platform}" = "pc" ]; then
							  menuentry '${__ENTR}' {
							    echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							    set isofile="(${_SRVR_PROT},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}"
							    export isofile
							    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							    insmod net
							    insmod http
							    insmod progress
							    echo 'Loading linux ...'
							    linux  memdisk iso raw
							    echo 'Loading initrd ...'
							    initrd \$isofile
							  }
							fi
_EOT_
					)"
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							if [ "\${grub_platform}" = "pc" ]; then
							  menuentry '${__ENTR}' {
							    echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							    set isofile="(${_SRVR_PROT},${_SRVR_ADDR:?})/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}"
							    export isofile
							    if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							    insmod net
							    insmod http
							    insmod progress
							    echo 'Loading linux ...'
							    linux  memdisk iso raw
							    echo 'Loading initrd ...'
							    initrd \$isofile
							  }
							fi
_EOT_
					)"
					;;
				memtest86* )			# (memtest86)
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							menuentry '${__ENTR}' {
							  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
							  set knladdr="(tftp,${_SRVR_ADDR:?})/${_DIRS_IMGS##*/}/${__TGET_LIST[2]}"
							  if [ "\${grub_platform}" = "efi" ]; then rmmod tpm; fi
							  insmod net
							  insmod http
							  insmod progress
							  echo 'Loading linux ...'
							  if [ "\${grub_platform}" = "pc" ]; then
							    linux \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
							  else
							    linux \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
							  fi
							}
_EOT_
					)"
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					__WORK="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true
							menuentry '${__ENTR}' {
							  echo 'Loading ${__TGET_LIST[3]//%20/ } ...'
							  set srvraddr="${_SRVR_PROT}://${_SRVR_ADDR:?}"
_EOT_
					)"
					if [[ -n "${__TGET_LIST[23]##-}" ]] && [[ -n "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK+="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true

								  set hostname="${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"
								  set ethrname="${_NICS_NAME:-ens160}"
								  set ipv4addr="${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"
								  set ipv4mask="${_IPV4_MASK:-}"
								  set ipv4gway="${_IPV4_GWAY:-}"
								  set ipv4nsvr="${_IPV4_NSVR:-}"
								  set autoinst="${__BOPT[1]:-}"
_EOT_
						)"
					fi
					__WORK+="$(
						cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' -e "s/^/${__SPCS}/g" | sed -e ':l; N; s/\n/\\n/; b l;' || true

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
							  linux  \${knladdr}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/} \${options} ---
							  echo 'Loading initrd ...'
							  initrd \${knladdr}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
							}
_EOT_
					)"
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/\[ System command \]/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create syslinux.cfg for bios mode ---------------------------------------
function funcPxeboot_slnx() {
	declare -r    __PATH_TGET="${1:?}"	# target file (menu)
	declare -r -i __CONT_TABS="${2:?}"	# tabs count
	declare -r -a __TGET_LIST=("${@:3}") # target data (list)
	declare       __PATH=""				# full path
	declare -a    __LIST=()				# work variables
	declare       __WORK=""				# work variables
	declare -a    __BOPT=()				# boot options
	declare       __ENTR=""				# meny entry
	declare       __HOST=""				# host name
	declare       __CONF=""				# configuration file
	declare       __IMGS=""				# iso file extraction destination
	declare       __ISOS=""				# iso file
	declare       __LOAD=""				# load module
	declare       __RMAK=""				# remake file
	declare -i    I=0					# work variables

	# --- header/footer -------------------------------------------------------
	if [[ ! -s "${__PATH_TGET}" ]]; then
#		rm -f "${__PATH_TGET:?}"
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__PATH_TGET}" || true
			path ./
			prompt 0
			timeout 0
			default vesamenu.c32
			
			menu resolution ${_MENU_RESO/x/ }
			
			menu color screen       * #ffffffff #ee000080 *
			menu color title        * #ffffffff #ee000080 *
			menu color border       * #ffffffff #ee000080 *
			menu color sel          * #ffffffff #76a1d0ff *
			menu color hotsel       * #ffffffff #76a1d0ff *
			menu color unsel        * #ffffffff #ee000080 *
			menu color hotkey       * #ffffffff #ee000080 *
			menu color tabmsg       * #ffffffff #ee000080 *
			menu color timeout_msg  * #ffffffff #ee000080 *
			menu color timeout      * #ffffffff #ee000080 *
			menu color disabled     * #ffffffff #ee000080 *
			menu color cmdmark      * #ffffffff #ee000080 *
			menu color cmdline      * #ffffffff #ee000080 *
			menu color scrollbar    * #ffffffff #ee000080 *
			menu color help         * #ffffffff #ee000080 *
			
			menu margin             4
			menu vshift             5
			menu rows               25
			menu tabmsgrow          31
			menu cmdlinerow         33
			menu timeoutrow         33
			menu helpmsgrow         37
			menu hekomsgendrow      39
			
			menu title - Boot Menu -
			menu tabmsg Press ENTER to boot or TAB to edit a menu entry
			
			label System-command
			  menu label ^[ System command ... ]
			
_EOT_
		case "${__PATH_TGET}" in
			*/menu-bios/*)
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${__PATH_TGET}" || true
					label Hardware-info
					  menu label ^- Hardware info
					  com32 hdt.c32

					label System-shutdown
					  menu label ^- System shutdown
					  com32 poweroff.c32

					label System-restart
					  menu label ^- System restart
					  com32 reboot.c32

_EOT_
			;;
			*) ;;
		esac
	fi
	# --- menu list -----------------------------------------------------------
	case "${__TGET_LIST[1]}" in
		m)								# (menu)
			if [[ -z "${__TGET_LIST[3]##-}" ]]; then
				return
			fi
			__WORK="$(
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
					label ${__TGET_LIST[3]//%20/-}
					  menu label ^[ ${__TGET_LIST[3]//%20/ } ... ]
					
_EOT_
			)"
			sed -i "${__PATH_TGET}" -e "/^label[ \t]\+System-command$/i \\${__WORK}"
			;;
		o)								# (output)
			if [[ ! -e "${_DIRS_IMGS}/${__TGET_LIST[2]}" ]]; then
				return
			fi
			if [[ ! -s "${__TGET_LIST[13]}" ]]; then
				return
			fi
			__ENTR="$(printf "%-55.55s%19.19s" "- ${__TGET_LIST[3]//%20/ }  ${_TEXT_SPCE// /.}" "${__TGET_LIST[14]//%20/ }")"
			__WORK=""
			case "${__TGET_LIST[2]}" in
				windows-* )				# (windows)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux  memdisk
									  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}
									  append iso raw

_EOT_
							)"
							;;
						*) ;;
					esac
					;;
				winpe-* | \
				ati*x64 | \
				ati*x86 )				# (winpe/ati)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux  memdisk
									  initrd ${_SRVR_PROT}://${_SRVR_ADDR:?}/${_DIRS_ISOS##*/}/${__TGET_LIST[13]#*${_DIRS_ISOS##*/}/}
									  append iso raw

_EOT_
							)"
							;;
						*) ;;
					esac
					;;
				memtest86* )			# (memtest86)
					case "${__PATH_TGET}" in
						*/menu-bios/*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
									
_EOT_
							)"
							;;
						*)
							__WORK="$(
								cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
									label ${__TGET_LIST[2]}
									  menu label ^${__ENTR}
									  linux /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
									
_EOT_
							)"
							;;
					esac
					;;
				*          )			# (linux)
					__WORK="$(set -e; funcPxeboot_boot_options "${__TGET_LIST[@]}")"
					__WORK="${__WORK//\$\{hostname\}/"${_NWRK_HOST/:_DISTRO_:/${__TGET_LIST[2]%%-*}}${_NWRK_WGRP:+.${_NWRK_WGRP}}"}"
					__WORK="${__WORK//\$\{srvraddr\}/"${_SRVR_PROT}://${_SRVR_ADDR:?}"}"
					__WORK="${__WORK//\$\{ethrname\}/"${_NICS_NAME:-ens160}"}"
					__WORK="${__WORK//\$\{ipv4addr\}/"${_IPV4_ADDR:-}/${_IPV4_CIDR:-}"}"
					__WORK="${__WORK//\$\{ipv4mask\}/"${_IPV4_MASK:-}"}"
					__WORK="${__WORK//\$\{ipv4gway\}/"${_IPV4_GWAY:-}"}"
					__WORK="${__WORK//\$\{ipv4nsvr\}/"${_IPV4_NSVR:-}"}"
					IFS= mapfile -d $'\n' -t __BOPT < <(echo -n "${__WORK}")
					if [[ -z "${__TGET_LIST[23]##-}" ]] || [[ -z "${__TGET_LIST[23]##*/-}" ]]; then
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								label ${__TGET_LIST[2]}
								  menu label ^${__ENTR}
								  linux  /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
								  initrd /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
								  append ${__BOPT[@]:3}
								
_EOT_
						)"
					else
						__WORK="$(
							cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | sed -e ':l; N; s/\n/\\n/; b l;' || true
								label ${__TGET_LIST[2]}
								  menu label ^${__ENTR}
								  linux  /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[22]#*/${__TGET_LIST[2]}/}
								  initrd /${_DIRS_IMGS##*/}/${__TGET_LIST[2]}/${__TGET_LIST[21]#*/${__TGET_LIST[2]}/}
								  append ${__BOPT[@]}
								
_EOT_
						)"
					fi
					case "${__TGET_LIST[2]}" in
						opensuse-*-15* ) __WORK="${__WORK//ens160/eth0}";;
						*              ) ;;
					esac
					;;
			esac
			if [[ -n "${__WORK:-}" ]]; then
				sed -i "${__PATH_TGET}" -e "/^label[ \t]\+System-command$/i \\${__WORK}"
			fi
			;;
		*)								# (hidden)
			;;
	esac
}

# --- create pxeboot menu -----------------------------------------------------
function funcPxeboot() {
	declare -i    __TABS=0				# tabs count
	declare       __LIST=()				# work variable
	declare -i    I=0					# work variables

	rm -f "${_MENU_IPXE:?}" \
	      "${_MENU_GRUB:?}" \
		  "${_MENU_SLNX:?}" \
		  "${_MENU_UEFI:?}"
	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
		printf "%20.20s: %s\n" "start" "${__LIST[2]}" 1>&2
		# --- update ----------------------------------------------------------
		case "${1:-}" in
			update  ) ;;
			*       ) funcPxeboot_copy "${__LIST[13]}" "${_DIRS_IMGS}/${__LIST[2]}";;
		esac
		# --- create pxeboot menu ---------------------------------------------
		case "${1:-}" in
			download) ;;
			*       )
				funcPxeboot_ipxe "${_MENU_IPXE}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_grub "${_MENU_GRUB}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_slnx "${_MENU_SLNX}" "${__TABS:-"0"}" "${__LIST[@]}"
				funcPxeboot_slnx "${_MENU_UEFI}" "${__TABS:-"0"}" "${__LIST[@]}"
				;;
		esac
		case "${__LIST[1]}" in
			m)							# (menu)
				if [[ "${__TABS:-"0"}" -eq 0 ]]; then
					__TABS=1
				else
					__TABS=0
				fi
				;;
			o) ;;						# (output)
			*) ;;						# (hidden)
		esac
	done
}