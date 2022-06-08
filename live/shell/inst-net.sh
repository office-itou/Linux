#!/bin/bash
# =============================================================================
#	set -n								# 構文エラーのチェック
#	set -x								# コマンドと引数の展開を表示
	set -o ignoreeof					# Ctrl+Dで終了しない
	set +m								# ジョブ制御を無効にする
	set -e								# ステータス0以外で終了
	set -u								# 未定義変数の参照で終了
	trap 'exit 1' 1 2 3 15
# -- initialize ---------------------------------------------------------------
	ROW_SIZE=25
	COL_SIZE=80
	if [ "`which tput 2> /dev/null`" != "" ]; then
		ROW_SIZE=`tput lines`
		COL_SIZE=`tput cols`
	fi
	if [ ${COL_SIZE} -lt 80 ]; then
		COL_SIZE=80
	fi
	if [ ${COL_SIZE} -gt 100 ]; then
		COL_SIZE=100
	fi
# -- string -------------------------------------------------------------------
fncString () {
	if [ "$2" = " " ]; then
		echo $1      | awk '{s=sprintf("%"$1"."$1"s"," "); print s;}'
	else
		echo $1 "$2" | awk '{s=sprintf("%"$1"."$1"s"," "); gsub(" ",$2,s); print s;}'
	fi
}
# -- print --------------------------------------------------------------------
fncPrint () {
	local RET_STR=""
	MAX_COLS=$((COL_SIZE-1))
	RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	if [ $? -ne 0 ]; then
		MAX_COLS=$((COL_SIZE-2))
		RET_STR=`echo -n "$1" | iconv -f UTF-8 -t SHIFT-JIS | cut -b -${MAX_COLS} | iconv -f SHIFT-JIS -t UTF-8 2> /dev/null`
	fi
	echo "${RET_STR}"
}
# -- systemctl ----------------------------------------------------------------
fncSystemctl () {
	echo "systemctl $@"
	case "$1" in
		"disable" | "mask" )
			shift
			systemctl --quiet --no-reload disable $@
			systemctl --quiet --no-reload mask $@
			;;
		"enable" | "unmask" )
			shift
			systemctl --quiet --no-reload unmask $@
			systemctl --quiet --no-reload enable $@
			;;
		* )
			systemctl --quiet --no-reload $@
			;;
	esac
}
# -- terminate ----------------------------------------------------------------
fncEnd() {
	fncPrint "--- termination $(fncString ${COL_SIZE} '-')"
	RET_STS=$1
	history -c
	fncPrint "$(fncString ${COL_SIZE} '=')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]: ${OS_NAME} ${VERSION}"
	fncPrint "$(fncString ${COL_SIZE} '=')"
	exit ${RET_STS}
}
# == main =====================================================================
	OS_NAME=`sed -n 's/^NAME="\(.*\)"$/\1/p' /etc/os-release`
	VERSION=`sed -n 's/^VERSION="\(.*\)"$/\1/p' /etc/os-release`
	fncPrint "$(fncString ${COL_SIZE} '=')"
	fncPrint "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]: ${OS_NAME} ${VERSION}"
	fncPrint "$(fncString ${COL_SIZE} '=')"
	fncPrint "--- initialize $(fncString ${COL_SIZE} '-')"
	fncPrint "---- os name  : ${OS_NAME} $(fncString ${COL_SIZE} '-')"
	fncPrint "---- version  : ${VERSION} $(fncString ${COL_SIZE} '-')"
	fncPrint "---- hostname : live-debian $(fncString ${COL_SIZE} '-')"
	fncPrint "---- workgroup: workgroup $(fncString ${COL_SIZE} '-')"
	export PS1="(chroot) "
	echo "live-debian" > /etc/hostname
	hostname -b -F /etc/hostname
	if [ -d "/usr/lib/systemd/" ]; then
		DIR_SYSD="/usr/lib/systemd/"
	elif [ -d "/lib/systemd/" ]; then
		DIR_SYSD="/lib/systemd"
	else
		DIR_SYSD=""
	fi
# -- module update, upgrade, tasksel, install ---------------------------------
	fncPrint "--- module update, install, clean $(fncString ${COL_SIZE} '-')"
	if [ `getconf LONG_BIT` -eq 32 ]; then
		APP_CHROME=""
	else
		fncPrint "---- google-chrome signing key install $(fncString ${COL_SIZE} '-')"
		APP_CHROME="google-chrome-stable"
		KEY_CHROME="https://dl-ssl.google.com/linux/linux_signing_key.pub"
		pushd /tmp/ > /dev/null
			if [ ! -f ./linux_signing_key.pub ]; then
				set +e
				curl -L -s -R -S -f --connect-timeout 3 --retry 3 -O "${KEY_CHROME} " || \
				if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
					echo "URL: ${KEY_CHROME}"
					fncEnd 1;
				fi
				set -e
			fi
			if [ ! -d /etc/apt/trusted.gpg.d/ ]; then
				mkdir -p /etc/apt/trusted.gpg.d
			fi
			gpg --dearmor < ./linux_signing_key.pub > /etc/apt/trusted.gpg.d/google-chrome.gpg
			rm -f ./linux_signing_key.pub
			echo 'deb http://dl.google.com/linux/chrome/deb/ stable main'     \
			    > /etc/apt/sources.list.d/google-chrome.list
		popd > /dev/null
	fi
	# ----------------------------------------------------------------------- #
	fncPrint "---- update sources.list $(fncString ${COL_SIZE} '-')"
	sed -i /etc/apt/sources.list \
	    -e 's/\(deb\) \[.*\] \(.*\)$/\1 \2/g'
	# -------------------------------------------------------------------------
	if [ -d /var/lib/apt/lists ]; then
		fncPrint "---- remove /var/lib/apt/lists $(fncString ${COL_SIZE} '-')"
		rm -rf /var/lib/apt/lists
	fi
	# -------------------------------------------------------------------------
	export DEBIAN_FRONTEND=noninteractive
	APT_OPTIONS="-o Dpkg::Options::=--force-confdef    \
	             -o Dpkg::Options::=--force-confnew    \
	             -o Dpkg::Options::=--force-overwrite"
	# ----------------------------------------------------------------------- #
	fncPrint "---- module dpkg $(fncString ${COL_SIZE} '-')"
	dpkg --audit                                                           || fncEnd $?
	dpkg --configure -a                                                    || fncEnd $?
	# ----------------------------------------------------------------------- #
	fncPrint "---- module apt-get update $(fncString ${COL_SIZE} '-')"
	apt-get update       -qq                                   > /dev/null || fncEnd $?
	fncPrint "---- module apt-get upgrade $(fncString ${COL_SIZE} '-')"
	apt-get upgrade      -qq  -y ${APT_OPTIONS}                > /dev/null || fncEnd $?
	fncPrint "---- module apt-get dist-upgrade $(fncString ${COL_SIZE} '-')"
	apt-get dist-upgrade -qq  -y ${APT_OPTIONS}                > /dev/null || fncEnd $?
	fncPrint "---- module apt-get install $(fncString ${COL_SIZE} '-')"
	apt-get install      -qq  -y ${APT_OPTIONS} --auto-remove               \
	    ${APP_CHROME}                                                       \
	                                                           > /dev/null || fncEnd $?
#	fncPrint "---- tasksel $(fncString ${COL_SIZE} '-')"
#	tasksel install                                                         \
#	    _LST_TASK_                                                          \
#	                                                           > /dev/null || fncEnd $?
	fncPrint "---- module autoremove, autoclean, clean $(fncString ${COL_SIZE} '-')"
	apt-get autoremove   -qq -y                                > /dev/null || fncEnd $?
	apt-get autoclean    -qq                                   > /dev/null || fncEnd $?
	apt-get clean        -qq                                   > /dev/null || fncEnd $?
# -- Change system control ----------------------------------------------------
# 	Set disable to mask because systemd-sysv-generator will recreate the symbolic link.
	fncPrint "--- change system control $(fncString ${COL_SIZE} '-')"
	fncSystemctl  enable clamav-freshclam
	fncSystemctl  enable ssh
	if [ "`systemctl is-enabled named 2> /dev/null || :`" != "" ]; then
		fncSystemctl enable named
	else
		fncSystemctl enable bind9
	fi
	fncSystemctl  enable smbd
	fncSystemctl  enable nmbd
	fncSystemctl disable isc-dhcp-server
	if [ "`systemctl is-enabled isc-dhcp-server6 2> /dev/null || :`" != "" ]; then
		fncSystemctl disable isc-dhcp-server6
	fi
	fncSystemctl disable minidlna
	if [ "`systemctl is-enabled unattended-upgrades 2> /dev/null || :`" != "" ]; then
		fncSystemctl disable unattended-upgrades
	fi
	if [ "`systemctl is-enabled brltty 2> /dev/null || :`" != "" ]; then
		fncSystemctl disable brltty-udev
		fncSystemctl disable brltty
	fi
	case "`sed -n '/^UBUNTU_CODENAME=/ s/.*=\(.*\)/\1/p' /etc/os-release`" in
		"focal"   | \
		"impish"  | \
		"jammy"   | \
		"kinetic" )
			if [ "`systemctl is-enabled systemd-udev-settle 2> /dev/null || :`" != "" ]; then
				fncSystemctl disable systemd-udev-settle
			fi
			;;
		* )
			;;
	esac
# -- Change service configure -------------------------------------------------
#	if [ -f /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service ]; then
#		fncPrint "--- change cups-browsed configure $(fncString ${COL_SIZE} '-')"
#		cat <<- _EOT_ > /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service.override
#			[Service]
#			TimeoutStopSec=3
#_EOT_
#	fi
# -- Change resolv configure --------------------------------------------------
	if [ -d /etc/NetworkManager/ ]; then
		fncPrint "--- change NetworkManager configure $(fncString ${COL_SIZE} '-')"
		touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
		cat <<- _EOT_ > /etc/NetworkManager/conf.d/NetworkManager.conf.override
			[main]
			dns=default
_EOT_
		fncPrint "--- change resolv.conf configure $(fncString ${COL_SIZE} '-')"
		cat <<- _EOT_ > /etc/systemd/resolved.conf.override
			[Resolve]
			DNSStubListener=no
_EOT_
		ln -sf /run/systemd/resolve/resolv.conf etc/resolv.conf
	fi
# -- Change avahi-daemon configure --------------------------------------------
	if [ -f /etc/nsswitch.conf ]; then
		fncPrint "--- change avahi-daemon configure $(fncString ${COL_SIZE} '-')"
		OLD_IFS=${IFS}
		IFS=$'\n'
		INS_ROW=$((`sed -n '/^hosts:/ =' /etc/nsswitch.conf | head -n 1`))
		INS_TXT=`sed -n '/^hosts:/ s/\(hosts:[ \t]*\).*$/\1mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns mdns/p' /etc/nsswitch.conf`
		sed -e '/^hosts:/ s/^/#/' /etc/nsswitch.conf | \
		sed -e "${INS_ROW}a ${INS_TXT}"                \
		> nsswitch.conf
		cat nsswitch.conf > /etc/nsswitch.conf
		rm nsswitch.conf
		IFS=${OLD_IFS}
	fi
# -- Change clamav configure --------------------------------------------------
	if [ "`which freshclam 2> /dev/null`" != "" ]; then
		fncPrint "---- change freshclam.conf $(fncString ${COL_SIZE} '-')"
		sed -i /etc/clamav/freshclam.conf     \
		    -e 's/^Example/#&/'               \
		    -e 's/^CompressLocalDatabase/#&/' \
		    -e 's/^SafeBrowsing/#&/'          \
		    -e 's/^NotifyClamd/#&/'
		fncPrint "---- run freshclam $(fncString ${COL_SIZE} '-')"
		set +e
		freshclam --quiet
		set -e
	fi
# -- Change sshd configure ----------------------------------------------------
	if [ -d /etc/ssh/ ]; then
		fncPrint "--- change sshd configure $(fncString ${COL_SIZE} '-')"
		if [ ! -d /etc/ssh/sshd_config.d/ ]; then
			cat <<- _EOT_ >> /etc/ssh/sshd_config
				
				# --- user settings ---
				PermitRootLogin no
				PubkeyAuthentication yes
				PasswordAuthentication yes
_EOT_
			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
				cat <<- _EOT_ >> /etc/ssh/sshd_config
					PubkeyAcceptedAlgorithms +ssh-rsa
					HostkeyAlgorithms +ssh-rsa
_EOT_
			fi
		else
			cat <<- _EOT_ > /etc/ssh/sshd_config.d/sshd_config.override
				PermitRootLogin no
				PubkeyAuthentication yes
				PasswordAuthentication yes
_EOT_
			if [ "`ssh -V 2>&1 | awk -F '[^0-9]+' '{print $2;}'`" -ge 9 ]; then
				cat <<- _EOT_ >> /etc/ssh/sshd_config.d/sshd_config.override
					PubkeyAcceptedAlgorithms +ssh-rsa
					HostkeyAlgorithms +ssh-rsa
_EOT_
			fi
		fi
	fi
# -- Change samba configure ---------------------------------------------------
if [ -f /etc/samba/smb.conf ]; then
		fncPrint "--- change samba configure $(fncString ${COL_SIZE} '-')"
		SVR_NAME="live-debian"						# 本機のホスト名
		WGP_NAME="workgroup"						# 本機のワークグループ名
		CMD_UADD=`which useradd`
		CMD_UDEL=`which userdel`
		CMD_GADD=`which groupadd`
		CMD_GDEL=`which groupdel`
		CMD_GPWD=`which gpasswd`
		CMD_FALS=`which false`
		# ---------------------------------------------------------------------
		testparm -s -v |                                                                        \
		sed -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
		    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
		    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
		    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
		    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
		    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
		    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
		    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
		    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
		    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
		    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
		    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
		    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
		    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
		    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
		    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
		    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
		    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
		    -e 's/\(min protocol\) =.*$/\1 = NT1/g'                                             \
		    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
		    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
		    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
		    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
		    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
		    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
		    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
		    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
		    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
		    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
		    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
		    -e '/[ \t]*.* = $/d'                                                                \
		    -e '/[ \t]*\(client ipc\|client\|server\) min protocol = .*$/d'                     \
		    -e '/[ \t]*acl check permissions =.*$/d'                                            \
		    -e '/[ \t]*allocation roundup size =.*$/d'                                          \
		    -e '/[ \t]*blocking locks =.*$/d'                                                   \
		    -e '/[ \t]*client NTLMv2 auth =.*$/d'                                               \
		    -e '/[ \t]*client lanman auth =.*$/d'                                               \
		    -e '/[ \t]*client plaintext auth =.*$/d'                                            \
		    -e '/[ \t]*client schannel =.*$/d'                                                  \
		    -e '/[ \t]*client use spnego =.*$/d'                                                \
		    -e '/[ \t]*client use spnego principal =.*$/d'                                      \
		    -e '/[ \t]*copy =.*$/d'                                                             \
		    -e '/[ \t]*dns proxy =.*$/d'                                                        \
		    -e '/[ \t]*domain logons =.*$/d'                                                    \
		    -e '/[ \t]*domain master =.*$/d'                                                    \
		    -e '/[ \t]*enable privileges =.*$/d'                                                \
		    -e '/[ \t]*encrypt passwords =.*$/d'                                                \
		    -e '/[ \t]*idmap backend =.*$/d'                                                    \
		    -e '/[ \t]*idmap gid =.*$/d'                                                        \
		    -e '/[ \t]*idmap uid =.*$/d'                                                        \
		    -e '/[ \t]*lanman auth =.*$/d'                                                      \
		    -e '/[ \t]*logon path =.*$/d'                                                       \
		    -e '/[ \t]*logon script =.*$/d'                                                     \
		    -e '/[ \t]*lsa over netlogon =.*$/d'                                                \
		    -e '/[ \t]*map to guest =.*$/d'                                                     \
		    -e '/[ \t]*nbt client socket address =.*$/d'                                        \
		    -e '/[ \t]*null passwords =.*$/d'                                                   \
		    -e '/[ \t]*obey pam restrictions =.*$/d'                                            \
		    -e '/[ \t]*only user =.*$/d'                                                        \
		    -e '/[ \t]*pam password change =.*$/d'                                              \
		    -e '/[ \t]*paranoid server security =.*$/d'                                         \
		    -e '/[ \t]*password level =.*$/d'                                                   \
		    -e '/[ \t]*preferred master =.*$/d'                                                 \
		    -e '/[ \t]*raw NTLMv2 auth =.*$/d'                                                  \
		    -e '/[ \t]*realm =.*$/d'                                                            \
		    -e '/[ \t]*security =.*$/d'                                                         \
		    -e '/[ \t]*server role =.*$/d'                                                      \
		    -e '/[ \t]*server schannel =.*$/d'                                                  \
		    -e '/[ \t]*server services =.*$/d'                                                  \
		    -e '/[ \t]*server string =.*$/d'                                                    \
		    -e '/[ \t]*share modes =.*$/d'                                                      \
		    -e '/[ \t]*syslog =.*$/d'                                                           \
		    -e '/[ \t]*syslog only =.*$/d'                                                      \
		    -e '/[ \t]*time offset =.*$/d'                                                      \
		    -e '/[ \t]*unicode =.*$/d'                                                          \
		    -e '/[ \t]*unix password sync =.*$/d'                                               \
		    -e '/[ \t]*use spnego =.*$/d'                                                       \
		    -e '/[ \t]*usershare allow guests =.*$/d'                                           \
		    -e '/[ \t]*winbind separator =.*$/d'                                                \
		    -e '/[ \t]*wins support =.*$/d'                                                     \
		> ./smb.conf
		# ---------------------------------------------------------------------
		testparm -s ./smb.conf > /etc/samba/smb.conf
		rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
fi
# -- Change gdm3 configure ----------------------------------------------------
#	if [ -f /etc/gdm3/custom.conf ] && [ ! -f /etc/gdm3/daemon.conf ]; then
#		fncPrint "--- create gdm3 daemon.conf $(fncString ${COL_SIZE} '-')"
#		cp -p /etc/gdm3/custom.conf /etc/gdm3/daemon.conf
#		: > /etc/gdm3/daemon.conf
#	fi
# -- Change xdg configure -----------------------------------------------------
	if [  -f /etc/xdg/autostart/gnome-initial-setup-first-login.desktop ]; then
		fncPrint "--- change xdg configure $(fncString ${COL_SIZE} '-')"
		mkdir -p /etc/skel/.config
		touch /etc/skel/.config/gnome-initial-setup-done
	fi
# -- Change dconf configure ---------------------------------------------------
	if [ "`which dconf 2> /dev/null`" != "" ]; then
		fncPrint "--- change dconf configure $(fncString ${COL_SIZE} '-')"
		# -- create dconf profile ---------------------------------------------
		fncPrint "--- create dconf profile $(fncString ${COL_SIZE} '-')"
		if [ ! -d /etc/dconf/db/local.d/ ]; then
			mkdir -p /etc/dconf/db/local.d
		fi
		if [ ! -d /etc/dconf/profile/ ]; then
			mkdir -p /etc/dconf/profile
		fi
		cat <<- _EOT_ > /etc/dconf/profile/user
			user-db:user
			system-db:local
_EOT_
		# -- dconf org/gnome/desktop/screensaver ------------------------------
		fncPrint "---- dconf org/gnome/desktop/screensaver $(fncString ${COL_SIZE} '-')"
		cat <<- _EOT_ > /etc/dconf/db/local.d/01-screensaver
			[org/gnome/desktop/screensaver]
			idle-activation-enabled=false
			lock-enabled=false
_EOT_
		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		fncPrint "---- dconf org/gnome/shell/extensions/dash-to-dock $(fncString ${COL_SIZE} '-')"
		cat <<- _EOT_ > /etc/dconf/db/local.d/01-dash-to-dock
			[org/gnome/shell/extensions/dash-to-dock]
			hot-keys=false
			hotkeys-overlay=false
			hotkeys-show-dock=false
_EOT_
		# -- dconf org/gnome/shell/extensions/dash-to-dock --------------------
		fncPrint "---- dconf apps/update-manager $(fncString ${COL_SIZE} '-')"
		cat <<- _EOT_ > /etc/dconf/db/local.d/01-update-manager
			[apps/update-manager]
			check-dist-upgrades=false
			first-run=false
_EOT_
		# -- dconf update -----------------------------------------------------
		fncPrint "---- dconf update $(fncString ${COL_SIZE} '-')"
		dconf update
	fi
# -- Change release-upgrades configure ----------------------------------------
#	if [ -f /etc/update-manager/release-upgrades ]; then
#		fncPrint "--- change release-upgrades configure $(fncString ${COL_SIZE} '-')"
#		sed -i /etc/update-manager/release-upgrades \
#		    -e 's/^\(Prompt\)=.*$/\1=never/'
#	fi
#	if [ -f /usr/lib/ubuntu-release-upgrader/check-new-release-gtk ]; then
#	fi
# -- Copy pulse configure -----------------------------------------------------
	if [ -f /usr/share/gdm/default.pa ]; then
		fncPrint "--- copy pulse configure $(fncString ${COL_SIZE} '-')"
		mkdir -p /etc/skel/.config/pulse
		cp -p /usr/share/gdm/default.pa /etc/skel/.config/pulse/
	fi
# -- root and user's setting --------------------------------------------------
	fncPrint "--- root and user's setting $(fncString ${COL_SIZE} '-')"
	LST_SHELL="`sed -n '/^#/! s~/~\\\\/~gp' /etc/shells |  sed -z 's/\n/|/g' | sed -e 's/|$//'`"
	for USER_NAME in "skel" `awk -F ':' '$7~/'"${LST_SHELL}"'/ {print $1;}' /etc/passwd`
	do
		fncPrint "---- ${USER_NAME}'s setting $(fncString ${COL_SIZE} '-')"
		if [ "${USER_NAME}" == "skel" ]; then
			USER_HOME="/etc/skel"
		else
			USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		fi
		if [ "${USER_HOME}" != "" ]; then
			pushd ${USER_HOME} > /dev/null
				# --- .bashrc -------------------------------------------------
				cat <<- _EOT_ >> .bashrc
					# --- 日本語文字化け対策 ---
					case "\${TERM}" in
					    "linux" ) export LANG=C;;
					    * )                    ;;
					esac
					export GTK_IM_MODULE=ibus
					export XMODIFIERS=@im=ibus
					export QT_IM_MODULE=ibus
_EOT_
				# --- .vimrc --------------------------------------------------
				cat <<- _EOT_ > .vimrc
					set number              " Print the line number in front of each line.
					set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
					set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
					set listchars=tab:>_    " Strings to use in 'list' mode and for the |:list| command.
					set nowrap              " This option changes how text is displayed.
					set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
					set laststatus=2        " The value of this option influences when the last window will have a status line always.
					syntax on               " Vim5 and later versions support syntax highlighting.
_EOT_
				if [ "${USER_NAME}" != "skel" ]; then
					chown ${USER_NAME}. .vimrc
				fi
				# --- .curlrc -------------------------------------------------
				cat <<- _EOT_ > .curlrc
					location
					progress-bar
					remote-time
					show-error
_EOT_
				if [ "${USER_NAME}" != "skel" ]; then
					chown ${USER_NAME}. .curlrc
				fi
				# --- xinput.d ------------------------------------------------
				if [ "${USER_NAME}" != "skel" ]; then
					mkdir .xinput.d
					ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
					chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
				fi
				# --- .credentials --------------------------------------------
				cat <<- _EOT_ > .credentials
					username=value
					password=value
					domain=value
_EOT_
				if [ "${USER_NAME}" != "skel" ]; then
					chown ${USER_NAME}. .credentials
					chmod 0600 .credentials
				fi
				# --- libfm.conf ----------------------------------------------
				if [   -f .config/libfm/libfm.conf      ] \
				&& [ ! -f .config/libfm/libfm.conf.orig ]; then
					sed -i.orig .config/libfm/libfm.conf   \
					    -e 's/^\(single_click\)=.*$/\1=0/'
				fi
			popd > /dev/null
		fi
	done
# -----------------------------------------------------------------------------
	fncPrint "--- cleaning and exit $(fncString ${COL_SIZE} '-')"
	fncEnd 0
# == EOF ======================================================================
