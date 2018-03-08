#!/bin/bash
#set -evx
# -- terminate ----------------------------------------------------------------
fncEnd() {
	/etc/init.d/dbus stop
	umount /dev/pts || umount -fl /dev/pts
	umount /dev     || umount -fl /dev
	umount /sys     || umount -fl /sys
	umount /proc    || umount -fl /proc
}
# -- initialize ---------------------------------------------------------------
	trap 'fncEnd; exit 1' 1 2 3 15
	export PS1="(chroot) "
	mount -t proc     proc     /proc
	mount -t sysfs    sysfs    /sys
	mount -t devtmpfs /dev     /dev
	mount -t devpts   /dev/pts /dev/pts
	/etc/init.d/dbus start
# -- module install -----------------------------------------------------------
# <memo>
#   https://lists.debian.org/debian-user/2011/04/msg01168.html
#   https://manpages.debian.org/stretch/apt/sources.list.5.ja.html
#       Dpkg::Options::= --force-confdef or --force-confnew or --force-confold
#       Acquire::Check-Valid-Until=no
#   http://linux-memo.sakura.ne.jp/knoppix/knoppix_customjp080100_cust.html
#       dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' | sort -nr | less
	sed -i /etc/apt/sources.list                     \
	    -e 's/ftp.de.debian.org/ftp.jp.debian.org/g'
	APT_REL="-t stable -t testing -t unstable -t experimental"
	APT_REL="-t stable -t testing"
	APT_UPD="${APT_REL} -o Acquire::Check-Valid-Until=no"
	APT_UPG="${APT_REL} -o Dpkg::Options::=--force-confdef"
	APT_INS="${APT_REL} -o Dpkg::Options::=--force-confdef"
	APT_RMV=""
	apt-get -q -y ${APT_RMV} purge                                            \
	    linux-source-*                                                        \
	    gcompris*                                                             \
	    etoys*                                                                \
	    gnome-games*                                                          \
	    neverball*                                                            \
	    scilab*                                                            && \
	apt-get -q -y            autoremove                                    && \
	apt-get -q    ${APT_UPD} update                                        && \
	apt-get -q    ${APT_UPD} update                                        && \
	apt-get -q -y ${APT_INS} install                                          \
	    im-config ibus-mozc                                                   \
	    libreoffice-help-ja libreoffice-l10n-ja                               \
	    manpages-ja manpages-ja-dev                                           \
	    proftpd                                                               \
	    fdclone                                                            && \
	apt-get -q -y            autoremove                                    && \
	apt-get -q               autoclean                                     && \
	apt-get -q               clean
	RETCD=$?
	if [ ${RETCD} -ne 0 ]; then
		fncEnd
		exit 1
	fi
# -- localize -----------------------------------------------------------------
	pushd /usr/share/locale/ > /dev/null
		rm -rf be* bg* cs* da* de* es* fi* fr* he* hi* hu* it* nl* pl* ru* sk* sl* tr* zh*
	popd > /dev/null
	localedef --list-archive | grep -v -e ^ja -e ^en_GB -e en_US | xargs localedef --delete-from-archive
	sed -i /etc/xdg/lxsession/LXDE/autostart               \
	    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
# -- root user's setting ------------------------------------------------------
	cat <<- _EOT_ > ~/.vimrc
		set number
		set tabstop=4
		set list
		set listchars=tab:>_
_EOT_
	cat <<- _EOT_ >> ~/.bashrc
		#
		case "\${TERM}" in
		    "linux" )
		        LANG=C
		        ;;
		    * )
		        LANG=ja_JP.UTF-8
		        ;;
		esac
		export LANG
		export GTK_IM_MODULE=ibus
		export XMODIFIERS=@im=ibus
		export QT_IM_MODULE=ibus
_EOT_
# -- knoppix user's setting ---------------------------------------------------
	cp -p ~/.vimrc  /home/knoppix/
	cp -p ~/.bashrc /home/knoppix/
	chown -R knoppix.knoppix /home/knoppix/.vimrc
	chown -R knoppix.knoppix /home/knoppix/.bashrc
# -- im-config ----------------------------------------------------------------
# <memo>
#   Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
	im-config -n ibus
	mkdir /home/knoppix/.xinput.d
	ln -s /etc/X11/xinit/xinput.d/ja_JP /home/knoppix/.xinput.d/ja_JP
	chown -R knoppix.knoppix /home/knoppix/.xinput.d
# -- clamav -------------------------------------------------------------------
	sed -i /etc/clamav/freshclam.conf                                                            \
	    -e 's/# Check for new database 24 times a day/# Check for new database 12 times a day/g' \
	    -e 's/Checks 24/Checks 12/g'                                                             \
	    -e 's/^NotifyClamd/#&/g'
# -- sshd ---------------------------------------------------------------------
	sed -i /etc/ssh/sshd_config                                         \
	    -e 's/^PermitRootLogin .*/PermitRootLogin yes/g'                \
	    -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/g' \
	    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'                  \
	    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d'                \
	    -e '$aUseDNS no\nIgnoreUserKnownHosts no'
# -- proftpd ------------------------------------------------------------------
	sed -i /etc/proftpd/proftpd.conf                                                \
	    -e '$a TimesGMT off\n<Global>\n\tRootLogin on\n\tUseFtpUsers on\n</Global>'
	sed -i /etc/ftpusers      \
	    -e 's/^root/# root/g'
# -- cleaning -----------------------------------------------------------------
	fncEnd
	history -c
	exit 0
# -- EOF ----------------------------------------------------------------------
