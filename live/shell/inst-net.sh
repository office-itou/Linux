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
# -- terminate ----------------------------------------------------------------
fncEnd() {
	fncPrint "--- terminate $(fncString ${COL_SIZE} '-')"
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
	export PS1="(chroot) "
#	hostname -b -F /etc/hostname
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
			set +e
			curl -L -s -R -S -f --connect-timeout 3 -O "${KEY_CHROME} "    || \
			if [ $? -eq 18 -o $? -eq 22 -o $? -eq 28 -o $? -eq 56 ]; then
				echo "URL: ${PNG_URL}"
				fncEnd 1;
			fi
			set -e
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
	fncPrint "--- Change system control $(fncString ${COL_SIZE} '-')"
	systemctl --quiet  enable clamav-freshclam
	systemctl --quiet  enable ssh
	if [ -f ${DIR_SYSD}/system/bind9.service ]; then
		systemctl --quiet enable bind9
	elif [ -f ${DIR_SYSD}/system/named.service ]; then
		systemctl --quiet enable named
	fi
	systemctl --quiet  enable smbd
	systemctl --quiet  enable nmbd
	systemctl --quiet mask isc-dhcp-server
	systemctl --quiet mask minidlna
#	if [ -f ${DIR_SYSD}/system/unattended-upgrades.service ]; then
#		systemctl --quiet mask unattended-upgrades
#	fi
	if [ -f ${DIR_SYSD}/system/brltty.service ]; then
		systemctl --quiet mask brltty-udev
		systemctl --quiet mask brltty
	fi
# -- Change service configure -------------------------------------------------
#	if [ -f /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service ]; then
#		fncPrint "--- Change cups-browsed configure $(fncString ${COL_SIZE} '-')"
#		cat <<- _EOT_ > /etc/systemd/system/multi-user.IMG_TGET.wants/cups-browsed.service.override
#			[Service]
#			TimeoutStopSec=3
#_EOT_
#	fi
# -- Change resolv configure --------------------------------------------------
	if [ -d /etc/NetworkManager/ ]; then
		fncPrint "--- Change NetworkManager configure $(fncString ${COL_SIZE} '-')"
		touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf
		cat <<- _EOT_ > /etc/NetworkManager/conf.d/NetworkManager.conf.override
			[main]
			dns=default
_EOT_
		fncPrint "--- Change resolv.conf configure $(fncString ${COL_SIZE} '-')"
		cat <<- _EOT_ > /etc/systemd/resolved.conf.override
			[Resolve]
			DNSStubListener=no
_EOT_
		ln -sf /run/systemd/resolve/resolv.conf etc/resolv.conf
	fi
# -- Change avahi-daemon configure --------------------------------------------
	if [ -f /etc/nsswitch.conf ]; then
		fncPrint "--- Change avahi-daemon configure $(fncString ${COL_SIZE} '-')"
		OLD_IFS=${IFS}
		IFS=$'\n'
		INS_ROW=$((`sed -n '/^hosts:/ =' /etc/nsswitch.conf | head -n 1`))
		INS_TXT=`sed -n '/^hosts:/ s/\(hosts:[ |\t]*\).*$/\1mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns mdns/p' /etc/nsswitch.conf`
		sed -e '/^hosts:/ s/^/#/' /etc/nsswitch.conf | \
		sed -e "${INS_ROW}a ${INS_TXT}"                \
		> nsswitch.conf
		cat nsswitch.conf > /etc/nsswitch.conf
		rm nsswitch.conf
		IFS=${OLD_IFS}
	fi
# -- Change clamav configure --------------------------------------------------
	if [ "`which freshclam 2> /dev/null`" != "" ]; then
		fncPrint "---- Change freshclam.conf $(fncString ${COL_SIZE} '-')"
		sed -i /etc/clamav/freshclam.conf     \
		    -e 's/^Example/#&/'               \
		    -e 's/^CompressLocalDatabase/#&/' \
		    -e 's/^SafeBrowsing/#&/'          \
		    -e 's/^NotifyClamd/#&/'
		fncPrint "---- Run freshclam $(fncString ${COL_SIZE} '-')"
		set +e
		freshclam --quiet
		set -e
	fi
# -- Change sshd configure ----------------------------------------------------
	if [ -d /etc/ssh/ ]; then
		fncPrint "--- Change sshd configure $(fncString ${COL_SIZE} '-')"
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
		fncPrint "--- Change samba configure $(fncString ${COL_SIZE} '-')"
		SVR_NAME="live-ubuntu"						# 本機のホスト名
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
		    -e "s/\(workgroup\) =.*$/\1 = ${WGP_NAME}/"                                         \
		    -e "s/\(netbios name\) =.*$/\1 = ${SVR_NAME}/"                                      \
		    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
		    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
		    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
		    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
		    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
		    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
		    -e 's/\(min protocol\) =.*$/\1 = NT1/g'                                             \
		    -e 's~\(printcap name\) =.*$~\1 = /dev/null~'                                       \
		    -e "s~\(add user script\) =.*$~\1 = ${CMD_UADD} %u~"                                \
		    -e "s~\(delete user script\) =.*$~\1 = ${CMD_UDEL} %u~"                             \
		    -e "s~\(add group script\) =.*$~\1 = ${CMD_GADD} %g~"                               \
		    -e "s~\(delete group script\) =.*$~\1 = ${CMD_GDEL} %g~"                            \
		    -e "s~\(add user to group script\) =.*$~\1 = ${CMD_GPWD} -a %u %g~"                 \
		    -e "s~\(delete user from group script\) =.*$~\1 = ${CMD_GPWD} -d %u %g~"            \
		    -e "s~\(add machine script\) =.*$~\1 = ${CMD_UADD} -d /dev/null -s ${CMD_FALS} %u~" \
		    -e 's/\(logon script\) =.*$/\1 = logon.bat/'                                        \
		    -e 's/\(logon path\) =.*$/\1 = \\\\%L\\profiles\\%U/'                               \
		    -e 's/\(domain logons\) =.*$/\1 = Yes/'                                             \
		    -e 's/\(os level\) =.*$/# \1 = 35/'                                                 \
		    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
		    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
		    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
		    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
		    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
		    -e 's/\(admin users\) =.*$/# \1 = administrator/'                                   \
		    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
		    -e 's/\(multicast dns register\) =.*$/\1 = No/'                                     \
		    -e '/[ |\t]*map to guest =.*$/d'                                                    \
		    -e '/[ |\t]*null passwords =.*$/d'                                                  \
		    -e '/[ |\t]*obey pam restrictions =.*$/d'                                           \
		    -e '/[ |\t]*enable privileges =.*$/d'                                               \
		    -e '/[ |\t]*password level =.*$/d'                                                  \
		    -e '/[ |\t]*client use spnego principal =.*$/d'                                     \
		    -e '/[ |\t]*syslog =.*$/d'                                                          \
		    -e '/[ |\t]*syslog only =.*$/d'                                                     \
		    -e '/[ |\t]*use spnego =.*$/d'                                                      \
		    -e '/[ |\t]*paranoid server security =.*$/d'                                        \
		    -e '/[ |\t]*dns proxy =.*$/d'                                                       \
		    -e '/[ |\t]*time offset =.*$/d'                                                     \
		    -e '/[ |\t]*usershare allow guests =.*$/d'                                          \
		    -e '/[ |\t]*idmap backend =.*$/d'                                                   \
		    -e '/[ |\t]*idmap uid =.*$/d'                                                       \
		    -e '/[ |\t]*idmap gid =.*$/d'                                                       \
		    -e '/[ |\t]*winbind separator =.*$/d'                                               \
		    -e '/[ |\t]*acl check permissions =.*$/d'                                           \
		    -e '/[ |\t]*only user =.*$/d'                                                       \
		    -e '/[ |\t]*share modes =.*$/d'                                                     \
		    -e '/[ |\t]*nbt client socket address =.*$/d'                                       \
		    -e '/[ |\t]*lsa over netlogon =.*$/d'                                               \
		    -e '/[ |\t]*.* = $/d'                                                               \
		    -e '/[ |\t]*client lanman auth =.*$/d'                                              \
		    -e '/[ |\t]*client NTLMv2 auth =.*$/d'                                              \
		    -e '/[ |\t]*client plaintext auth =.*$/d'                                           \
		    -e '/[ |\t]*client schannel =.*$/d'                                                 \
		    -e '/[ |\t]*client use spnego principal =.*$/d'                                     \
		    -e '/[ |\t]*client use spnego =.*$/d'                                               \
		    -e '/[ |\t]*domain logons =.*$/d'                                                   \
		    -e '/[ |\t]*enable privileges =.*$/d'                                               \
		    -e '/[ |\t]*encrypt passwords =.*$/d'                                               \
		    -e '/[ |\t]*idmap backend =.*$/d'                                                   \
		    -e '/[ |\t]*idmap gid =.*$/d'                                                       \
		    -e '/[ |\t]*idmap uid =.*$/d'                                                       \
		    -e '/[ |\t]*lanman auth =.*$/d'                                                     \
		    -e '/[ |\t]*lsa over netlogon =.*$/d'                                               \
		    -e '/[ |\t]*nbt client socket address =.*$/d'                                       \
		    -e '/[ |\t]*null passwords =.*$/d'                                                  \
		    -e '/[ |\t]*raw NTLMv2 auth =.*$/d'                                                 \
		    -e '/[ |\t]*server schannel =.*$/d'                                                 \
		    -e '/[ |\t]*syslog =.*$/d'                                                          \
		    -e '/[ |\t]*syslog only =.*$/d'                                                     \
		    -e '/[ |\t]*unicode =.*$/d'                                                         \
		    -e '/[ |\t]*acl check permissions =.*$/d'                                           \
		    -e '/[ |\t]*allocation roundup size =.*$/d'                                         \
		    -e '/[ |\t]*blocking locks =.*$/d'                                                  \
		    -e '/[ |\t]*copy =.*$/d'                                                            \
		    -e '/[ |\t]*winbind separator =.*$/d'                                               \
		    -e '/[ |\t]*domain master =.*$/d'                                                   \
		    -e '/[ |\t]*logon path =.*$/d'                                                      \
		    -e '/[ |\t]*logon script =.*$/d'                                                    \
		    -e '/[ |\t]*pam password change =.*$/d'                                             \
		    -e '/[ |\t]*preferred master =.*$/d'                                                \
		    -e '/[ |\t]*server role =.*$/d'                                                     \
		    -e '/[ |\t]*wins support =.*$/d'                                                    \
		    -e '/[ |\t]*dns proxy =.*$/d'                                                       \
		    -e '/[ |\t]*map to guest =.*$/d'                                                    \
		    -e '/[ |\t]*obey pam restrictions =.*$/d'                                           \
		    -e '/[ |\t]*pam password change =.*$/d'                                             \
		    -e '/[ |\t]*realm =.*$/d'                                                           \
		    -e '/[ |\t]*server role =.*$/d'                                                     \
		    -e '/[ |\t]*server services =.*$/d'                                                 \
		    -e '/[ |\t]*server string =.*$/d'                                                   \
		    -e '/[ |\t]*syslog =.*$/d'                                                          \
		    -e '/[ |\t]*unix password sync =.*$/d'                                              \
		    -e '/[ |\t]*usershare allow guests =.*$/d'                                          \
		    -e '/[ |\t]*\(client ipc\|client\|server\) min protocol = .*$/d'                    \
		    -e '/[ |\t]*security =.*$/d'                                                        \
		> ./smb.conf
		# ---------------------------------------------------------------------
		testparm -s ./smb.conf > /etc/samba/smb.conf
		rm -f ./smb.conf /etc/samba/smb.conf.ucf-dist
fi
# -- Change xdg configure -----------------------------------------------------
	if [  -f /etc/xdg/autostart/gnome-initial-setup-first-login.desktop ]; then
		fncPrint "--- Change xdg configure $(fncString ${COL_SIZE} '-')"
		mkdir -p /etc/skel/.config
		touch /etc/skel/.config/gnome-initial-setup-done
	fi
# -- Change gsettings configure -----------------------------------------------
#	if [ "`which gsettings 2> /dev/null`" != "" ]; then
#		fncPrint "--- Change gsettings configure $(fncString ${COL_SIZE} '-')"
#		gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
#		gsettings set org.gnome.desktop.screensaver lock-enabled false
#	fi
# -- Change dconf configure ---------------------------------------------------
	if [ "`which dconf 2> /dev/null`" != "" ]; then
		fncPrint "--- Change dconf configure $(fncString ${COL_SIZE} '-')"
		# -- create dconf profile ---------------------------------------------
		fncPrint "--- Create dconf profile $(fncString ${COL_SIZE} '-')"
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
		# -- dconf update -----------------------------------------------------
		fncPrint "---- dconf update $(fncString ${COL_SIZE} '-')"
		dconf update
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