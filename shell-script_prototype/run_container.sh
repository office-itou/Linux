#!/bin/bash

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

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
#	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
#	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
#	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
#	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
#	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
#	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	# --- open-vm-tools -------------------------------------------------------
#	declare -r    HGFS_DIRS="${DIRS_HGFS}/workspace/image"	# vmware shared directory

	# --- configuration file template -----------------------------------------
#	declare -r    CONF_DIRS="${DIRS_CONF}/_template"
#	declare -r    CONF_KICK="${CONF_DIRS}/kickstart_common.cfg"
#	declare -r    CONF_CLUD="${CONF_DIRS}/nocloud-ubuntu-user-data"
#	declare -r    CONF_SEDD="${CONF_DIRS}/preseed_debian.cfg"
#	declare -r    CONF_SEDU="${CONF_DIRS}/preseed_ubuntu.cfg"
#	declare -r    CONF_YAST="${CONF_DIRS}/yast_opensuse.xml"

	# --- chgroot -------------------------------------------------------------
	declare       FLAG_CHRT=""			# not empty: already running in chroot
	declare -r    DIRS_CHRT="${1%/}"
	shift

#	mkdir -p "${DIRS_CHRT}"/srv/{hgfs,http,samba,tftp,user}

# --- trap --------------------------------------------------------------------
	declare -a    _LIST_RMOV=()			# list remove directory / file
	              _LIST_RMOV+=("${DIRS_TEMP:?}")

# shellcheck disable=SC2317,SC2329
function funcTrap() {
	declare       _PATH=""
	declare -i    I=0
	for I in $(printf "%s\n" "${!_LIST_RMOV[@]}" | sort -Vr)
	do
		_PATH="${_LIST_RMOV[I]}"
		if [[ -e "${_PATH}" ]] && mountpoint --quiet "${_PATH}"; then
			printf "[%s]: umount \"%s\"\n" "${I}" "${_PATH}"
			umount --quiet         --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --force --recursive "${_PATH}" > /dev/null 2>&1 || \
			umount --quiet --lazy  --recursive "${_PATH}" || true
		fi
	done
	if [[ -e "${DIRS_TEMP:?}" ]]; then
		printf "%s: \"%s\"\n" "remove" "${DIRS_TEMP:?}"
		rm -rf "${DIRS_TEMP:?}"
	fi
}

	trap funcTrap EXIT

# --- overlay -----------------------------------------------------------------
	declare -r    DIRS_OLAY="${PWD:?}/overlay/${DIRS_CHRT##*/}"

function funcMount_overlay() {
	# shellcheck disable=SC2140
	mount -t overlay overlay -o lowerdir="${1:?}/",upperdir="${2:?}",workdir="${3:?}" "${4:?}" && _LIST_RMOV+=("${4:?}")
}

# --- nsswitch ----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_nsswitch() {
	declare       FILE_PATH=""
	FILE_PATH="${DIRS_OLAY}/merged/etc/nsswitch.conf"
	if [[ -e "${FILE_PATH}" ]] && [[ ! -e "${FILE_PATH}.orig" ]]; then
#		WORK_TEXT='mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns/n'
		WORK_TEXT='files wins mdns4_minimal [NOTFOUND=return] mymachines resolve [!UNAVAIL=return] dns mdns4 mdns6'
		cp -a "${FILE_PATH}" "${FILE_PATH}.orig"
		sed -e '/hosts:/ {'                                                       \
		    -e 's/^/#/'                                                           \
		    -e "a hosts:                                          ${WORK_TEXT}/n" \
		    -e '}'                                                                \
			-e '/^\(passwd\|group\|shadow\|gshadow\):[ \t]\+/ s/[ \t]\+winbind//' \
			"${FILE_PATH}.orig"                                                   \
		>	"${FILE_PATH}"
	fi
}

# --- network -----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_network() {
	declare       FILE_PATH=""
	declare       COMD_NAME=""
	FILE_PATH="${DIRS_OLAY}/merged/etc/hosts"
	if ! grep -q "${HOST_NAME}" "${FILE_PATH}"; then
			cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
				127.0.1.1       ${HOST_NAME}
_EOT_
	fi
	COMD_NAME="resolvectl"
	FILE_PATH="$(find "${DIRS_OLAY}/merged"{/,/usr}/{bin,sbin}/ -type f -name "${COMD_NAME}" 2> /dev/null || true)"
	if [[ -n "${FILE_PATH}" ]]; then
		if [[ -e "${DIRS_OLAY}/merged/etc/NetworkManager/NetworkManager.conf" ]]; then
			FILE_PATH="${DIRS_OLAY}/merged/etc/NetworkManager/conf.d/dns.conf"
			if [[ ! -e "${FILE_PATH}" ]]; then
				mkdir -p "${FILE_PATH%/*}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
					[main]
					dns=systemd-resolved
_EOT_
			fi
			FILE_PATH="${DIRS_OLAY}/merged/etc/NetworkManager/conf.d/mdns.conf"
			if [[ ! -e "${FILE_PATH}" ]]; then
				mkdir -p "${FILE_PATH%/*}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
					[connection]
					connection.mdns=2
_EOT_
			fi
		fi
	fi
}

# --- dnsmasq -----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_dnsmasq() {
	declare       FILE_PATH=""
	FILE_PATH="${DIRS_OLAY}/merged/etc/dnsmasq.d/default.conf"
	if [[ -e "${DIRS_OLAY}/merged/etc/dnsmasq.conf" ]] && [[ ! -e "${FILE_PATH}" ]]; then
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			# --- log ---------------------------------------------------------------------
			#log-queries                                                # dns query log output
			#log-dhcp                                                   # dhcp transaction log output
			#log-facility=                                              # log output file name

			# --- dns ---------------------------------------------------------------------
			#port=0                                                     # listening port
			#bogus-priv                                                 # do not perform reverse lookup of private ip address on upstream server
			#domain-needed                                              # do not forward plain names
			#domain=workgroup                                           # local domain name
			#expand-hosts                                               # add domain name to host
			#filterwin2k                                                # filter for windows
			interface=ens160                                            # listen to interface
			#listen-address=127.0.0.1                                   # listen to ip address
			#listen-address=::1                                         # listen to ip address
			#listen-address=192.168.1.1                                 # listen to ip address
			#listen-address=fe80::20c:29ff:fe57:5edc                    # listen to ip address
			#server=192.168.1.254                                       # directly specify upstream server
			#server=8.8.8.8                                             # directly specify upstream server
			#server=8.8.4.4                                             # directly specify upstream server
			#no-hosts                                                   # don't read the hostnames in /etc/hosts
			#no-poll                                                    # don't poll /etc/resolv.conf for changes
			#no-resolv                                                  # don't read /etc/resolv.conf
			#strict-order                                               # try in the registration order of /etc/resolv.conf
			#bind-dynamic                                               # enable bind-interfaces and the default hybrid network mode
			bind-interfaces                                             # enable multiple instances of dnsmasq
			#conf-file=/usr/share/dnsmasq-base/trust-anchors.conf       # enable dnssec validation and caching
			#dnssec                                                     # "

			# --- dhcp --------------------------------------------------------------------
			dhcp-range=192.168.1.0,proxy,24                             # proxy dhcp
			#dhcp-range=192.168.1.64,192.168.1.79,12h                   # dhcp range
			#dhcp-option=option:netmask,255.255.255.0                   #  1 netmask
			#dhcp-option=option:router,192.168.1.254                    #  3 router
			#dhcp-option=option:dns-server,192.168.1.1,192.168.1.254    #  6 dns-server
			#dhcp-option=option:domain-name,workgroup                   # 15 domain-name
			#dhcp-option=option:28,192.168.1.255                        # 28 broadcast
			#dhcp-option=option:ntp-server,61.205.120.130               # 42 ntp-server
			#dhcp-option=option:tftp-server,192.168.1.1                 # 66 tftp-server
			#dhcp-option=option:bootfile-name,                          # 67 bootfile-name
			dhcp-no-override                                            # disable re-use of the dhcp servername and filename fields as extra option space

			# --- dnsmasq manual page -----------------------------------------------------
			# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html

			# --- eof ---------------------------------------------------------------------
_EOT_
	fi
}

# --- sshd --------------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_sshd() {
	declare       FILE_PATH=""
	FILE_PATH="${DIRS_OLAY}/merged/etc/ssh/sshd_config.d/default.conf"
	if [[ -e "${DIRS_OLAY}/merged/etc/ssh/sshd_config" ]] && [[ ! -e "${FILE_PATH}" ]]; then
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			# --- user settings ---

			# port number to listen to ssh
			#Port 2222

			# ip address to accept connections
			#ListenAddress 0.0.0.0
			#ListenAddress ::

			# ssh protocol
			Protocol 2

			# whether to allow root login
			PermitRootLogin no

			# configuring public key authentication
			#PubkeyAuthentication no

			# public key file location
			#AuthorizedKeysFile

			# setting password authentication
			PasswordAuthentication yes

			# configuring challenge-response authentication
			#ChallengeResponseAuthentication no

			# sshd log is output to /var/log/secure
			#SyslogFacility AUTHPRIV

			# specify log output level
			#LogLevel INFO
_EOT_
	fi
}

# --- avahi -------------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_avahi() {
	declare       FILE_PATH=""
	FILE_PATH="${DIRS_OLAY}/merged/etc/avahi/avahi-daemon.conf"
	if [[ -e "${FILE_PATH}" ]] && [[ ! -e "${FILE_PATH}.orig" ]]; then
		cp -a "${FILE_PATH}" "${FILE_PATH}.orig"
		sed -e '/use-ipv4=/             {s/^#//; s/=.*$/=yes/}' \
		    -e '/use-ipv6=/             {s/^#//; s/=.*$/=no/ }' \
		    -e '/publish-aaaa-on-ipv4=/ {s/^#//; s/=.*$/=no/ }' \
		    -e '/publish-a-on-ipv6=/    {s/^#//; s/=.*$/=no/ }' \
			"${FILE_PATH}.orig"                                 \
		>	"${FILE_PATH}"
	fi
}

# -- loop device --------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_loop() {
	declare       FILE_PATH=""
	# [ loop device: shell ]
	FILE_PATH="${DIRS_OLAY}/merged/usr/local/bin/loop.sh"
	if [[ ! -e "${FILE_PATH}" ]]; then
		mkdir -p "${FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			#!/bin/sh

			set -eu

			_PATH="/dev/loop-control"
			if [ ! -e "${_PATH:?}" ]; then
			 	mknod "${_PATH}" c 10 237
				sleep 1
			fi

			I=0
			while [ "${I}" -lt 10 ]
			do
			 	_PATH="/dev/loop${I}"
			 	if [ ! -e "${_PATH}" ]; then
			 		mknod "${_PATH}" b 7 "${I}"
			 	fi
			 	I=$((I+1))
			done

			exit 0
_EOT_
		chmod +x "${DIRS_OLAY}/merged/usr/local/bin/loop.sh"
	fi
	# [ loop device: service ]
	FILE_PATH="${DIRS_OLAY}/merged/etc/systemd/system/loop_create.service"
	if [[ ! -e "${FILE_PATH}" ]]; then
		mkdir -p "${FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			[Unit]
			Description=Create Loop Device

			[Service]
			ExecStart=/usr/local/bin/loop.sh
			Type=oneshot

			[Install]
			WantedBy=default.target
_EOT_
#		chroot "${DIRS_OLAY}/merged/" systemctl enable loop_create.service
	fi
}

# --- firewall ----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_firewall() {
	declare -r -a SRVC_LIST=(\
		"-  enable  dhcp                        " \
		"-  enable  dhcpv6                      " \
		"o  enable  dhcpv6-client               " \
		"-  enable  dns                         " \
		"-  enable  http                        " \
		"-  enable  https                       " \
		"o  enable  mdns                        " \
		"-  enable  nfs                         " \
		"-  enable  proxy-dhcp                  " \
		"-  enable  samba                       " \
		"-  enable  samba-client                " \
		"o  enable  ssh                         " \
		"-  enable  tftp                        " \
	)
	declare -a    SRVC_LINE=()
	declare       COMD_NAME=""
	declare       FILE_PATH=""
	declare -i    I=0
	COMD_NAME="firewall-offline-cmd"
	FILE_PATH="$(find "${DIRS_OLAY}/merged"{/,/usr}/{bin,sbin}/ -type f -name "${COMD_NAME}" 2> /dev/null || true)"
	if [[ -n "${FILE_PATH}" ]]; then
		for I in "${!SRVC_LIST[@]}"
		do
			read -r -a SRVC_LINE < <(echo "${SRVC_LIST[I]}")
			if [[ "${SRVC_LINE[0]}" != "o" ]]; then
				printf "%-10.10s: %s\n" "skip" "${SRVC_LINE[2]}"
				continue
			fi
			printf "%-10.10s: %s\n" "${SRVC_LINE[1]}" "${SRVC_LINE[2]}"
			case "${SRVC_LINE[1]}" in
				enable ) chroot "${DIRS_OLAY}/merged/" firewall-offline-cmd --add-service="${SRVC_LINE[2]}" || true;;
				disable) chroot "${DIRS_OLAY}/merged/" firewall-offline-cmd --remove-service="${SRVC_LINE[2]}" || true;;
				*      ) ;;
			esac
		done
	fi
}

# --- service -----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_service() {
	declare -r -a SRVC_LIST=(\
		"o  enable  systemd-networkd.service    " \
		"o  enable  systemd-resolved.service    " \
		"o  enable  avahi-daemon.service        " \
		"o  enable  firewalld.service           " \
		"o  enable  sshd.service                " \
		"o  enable  loop_create.service         " \
	)
	declare -a    SRVC_LINE=()
	declare       FILE_PATH=""
	declare -i    I=0
	for I in "${!SRVC_LIST[@]}"
	do
		read -r -a SRVC_LINE < <(echo "${SRVC_LIST[I]}")
		if [[ "${SRVC_LINE[0]}" != "o" ]]; then
			printf "%-10.10s: %s\n" "skip" "${SRVC_LINE[2]}"
			continue
		fi
		FILE_PATH="$(find "${DIRS_OLAY}/merged"{/usr/lib/systemd/,/etc/systemd/} -type f -name "${SRVC_LINE[2]}" 2> /dev/null || true)"
		if [[ -z "${FILE_PATH}" ]]; then
			printf "%-10.10s: %s\n" "not exist" "${SRVC_LINE[2]}"
			continue
		fi
		printf "%-10.10s: %s\n" "${SRVC_LINE[1]}" "${SRVC_LINE[2]}"
		chroot "${DIRS_OLAY}/merged/" systemctl --quiet "${SRVC_LINE[1]}" "${SRVC_LINE[2]}" || true
	done
}

# --- skeleton ----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_skeleton() {
	declare       FILE_PATH=""
	# --- .bashrc -------------------------------------------------------------
	FILE_PATH="${DIRS_OLAY}/merged/etc/skel/.bashrc"
	if ! grep -q "# --- user custom ---" "${FILE_PATH}"; then
		mkdir -p "${FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${FILE_PATH}"
			# --- measures against garbled characters ---
			case "${TERM}" in
			 	linux ) export LANG=C;;
			 	*     )              ;;
			esac
			# --- user custom ---
			alias vi='vim'
			alias view='vim'
			alias diff='diff --color=auto'
			alias ip='ip -color=auto'
			alias ls='ls --color=auto'
_EOT_
	fi
	# --- .curlrc -------------------------------------------------------------
	FILE_PATH="${DIRS_OLAY}/merged/etc/skel/.curlrc"
	if [[ ! -e "${FILE_PATH}" ]]; then
		mkdir -p "${FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			location
			progress-bar
			remote-time
			show-error
_EOT_
	fi
	# --- .vimrc --------------------------------------------------------------
	FILE_PATH="${DIRS_OLAY}/merged/etc/skel/.vimrc"
	if [[ ! -e "${FILE_PATH}" ]]; then
		mkdir -p "${FILE_PATH%/*}"
		cat <<- '_EOT_' | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${FILE_PATH}"
			set number              " Print the line number in front of each line.
			set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
			set list                " List mode: Show tabs as CTRL-I is displayed, display \$ after end of line.
			set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
			set nowrap              " This option changes how text is displayed.
			set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
			set laststatus=2        " The value of this option influences when the last window will have a status line always.
			set mouse-=a            " Disable mouse usage
			syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
	fi
}

# --- add user ----------------------------------------------------------------
# shellcheck disable=SC2317,SC2329
function fnSetup_user() {
	declare -r    USER_NAME="master"
	declare       USER_UIDS=""
	declare       USER_GIDS=""
	declare       USER_CRPT=""
	declare       USER_SHEL=""
	declare       GRUP_SUDO=""
	if ! grep -q "${USER_NAME}" "${DIRS_OLAY}/merged/etc/passwd"; then
#		USER_PSWD="master"
		USER_UIDS="$(id -u "${USER_NAME:?}")"
		USER_GIDS="$(id -g "${USER_NAME:?}")"
		USER_CRPT="$(grep "${USER_NAME:?}" /etc/shadow | cut -d : -f 2)"
		USER_SHEL="$(grep "${USER_NAME:?}" /etc/passwd | cut -d : -f 7)"
		if grep -q sudo "${DIRS_OLAY}/merged/etc/group"; then
			GRUP_SUDO="sudo"
		else
			GRUP_SUDO="wheel"
		fi
		chroot "${DIRS_OLAY}/merged/" groupadd -g "${USER_GIDS:?}" "${USER_NAME:?}"
		chroot "${DIRS_OLAY}/merged/" useradd -u "${USER_UIDS:?}" -g "${USER_GIDS:?}" -G "${GRUP_SUDO}" -p "${USER_CRPT}" -s "${USER_SHEL:?}" "${USER_NAME:?}"
#		chroot "${DIRS_OLAY}/merged/" useradd -u "${USER_UIDS:?}" -g "${USER_GIDS:?}" -G "${GRUP_SUDO}" -p "${USER_CRPT}" -s "${USER_SHEL:?}" -m "${USER_NAME:?}"
#		cp -a /etc/passwd "${DIRS_OLAY}/merged/etc/"
#		cp -a /etc/shadow "${DIRS_OLAY}/merged/etc/"
#		cp -a /etc/group  "${DIRS_OLAY}/merged/etc/"
	fi
}

# --- main --------------------------------------------------------------------
	# --- check the execution user --------------------------------------------
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	declare       HOST_NAME="${DIRS_OLAY##*/}"
	              HOST_NAME="${HOST_NAME//./}"

	# --- mount and daemon reload ---------------------------------------------
	FLAG_CHRT="$(find /tmp/ -type d \( -name "${PROG_NAME}.*" -a -not -name "${DIRS_TEMP##*/}" \) -exec find '{}' -type f -name "${DIRS_CHRT##*/}" \; 2> /dev/null || true)"
	touch "${DIRS_TEMP:?}/${DIRS_CHRT##*/}"
	if [[ -z "${FLAG_CHRT}" ]]; then
		rm -rf   "${DIRS_OLAY:?}"/work
		mkdir -p "${DIRS_OLAY}"/{upper,lower,work,merged}
		mkdir -p "${DIRS_OLAY}"/upper/{root,home,"${DIRS_TOPS##/}","${DIRS_HGFS##/}"}
		mkdir -p "${DIRS_OLAY}"/work/{_rootdir,root,home,"${DIRS_TOPS##/}","${DIRS_TOPS##/}"_"${DIRS_HGFS##*/}"}
		# ---------------------------------------------------------------------
		funcMount_overlay "${DIRS_CHRT:?}" "${DIRS_OLAY}/upper"                 "${DIRS_OLAY}/work/_rootdir"                         "${DIRS_OLAY}/merged"
	fi

	# --- container -----------------------------------------------------------
	fnSetup_nsswitch					# nsswitch
	fnSetup_network						# network
#	fnSetup_dnsmasq						# dnsmasq
	fnSetup_sshd						# sshd
#	fnSetup_avahi						# avahi
	fnSetup_loop						# loop device
	fnSetup_firewall					# firewall
	fnSetup_service						# service
	fnSetup_skeleton					# skeleton
	fnSetup_user						# add user

	# --- options -------------------------------------------------------------
	OPTN_PARM=()
	OPTN_PARM+=("--private-users=no")
	OPTN_PARM+=("--bind=${DIRS_TOPS}:${DIRS_TOPS}:norbind")
	OPTN_PARM+=("--bind=${DIRS_HGFS}:${DIRS_HGFS}:norbind")
	OPTN_PARM+=("--bind=/home:/home:norbind")
#	if [[ -f /run/systemd/resolve/stub-resolv.conf ]]; then
#		OPTN_PARM+=("--resolv-conf=copy-uplink")
#	fi
	if ip link show | grep -q 'br0'; then
		OPTN_PARM+=("--network-bridge=br0")
	fi

	# --- exec ----------------------------------------------------------------
#	mount -t proc /proc/         "${DIRS_OLAY}/merged/proc/"												
#	mount --rbind /sys/          "${DIRS_OLAY}/merged/sys/"  && mount --make-rslave "${DIRS_OLAY}/merged/sys/"
#	DBGS_OUTS="SYSTEMD_LOG_LEVEL=debug"
	${DBGS_OUTS:-} systemd-nspawn --boot -U \
		--directory="${DIRS_OLAY}/merged/" \
		--machine="${HOST_NAME}" \
		--capability=CAP_MKNOD,CAP_NET_RAW \
		--property=DeviceAllow="/dev/console rwm" \
		--property=DeviceAllow="/dev/loop-control rwm" \
		--property=DeviceAllow="block-loop rwm" \
		--property=DeviceAllow="block-blkext rwm" \
		"${OPTN_PARM[@]}"
#	umount --recursive     "${DIRS_OLAY}/merged/sys/"
#	umount                 "${DIRS_OLAY}/merged/proc/"
	# --- umount --------------------------------------------------------------
	FLAG_CHRT="$(find /tmp/ -type d \( -name "${PROG_NAME}.*" -a -not -name "${DIRS_TEMP##*/}" \) -exec find '{}' -type f -name "${DIRS_CHRT##*/}" \; 2> /dev/null || true)"
	if [[ -z "${FLAG_CHRT}" ]]; then
		umount                 "${DIRS_OLAY}/merged/"
	fi
	rm -rf "${DIRS_TEMP:?}/${DIRS_CHRT##*/}"

	# --- exit ----------------------------------------------------------------
	exit 0

### eof #######################################################################
