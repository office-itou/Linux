#!/bin/bash

	export PS1="(chroot) "
	mount -t proc     proc     /proc
	mount -t sysfs    sysfs    /sys
	mount -t devtmpfs /dev     /dev
	mount -t devpts   /dev/pts /dev/pts
	/etc/init.d/dbus start
# -- root user's setting ------------------------------------------------------
	cd /root

	if [ ! -f .vimrc ]; then
		echo -e "set number\nset tabstop=4\nset list\nset listchars=tab:>_" > .vimrc
	fi

	if [ ! -f .bashrc.orig ]; then
		sed -i.orig .bashrc                                                                                                       \
		    -e '$a#\ncase "\${TERM}" in\n\t"linux" )\n\t\tLANG=C\n\t\t;;\n\t* )\n\t\tLANG=ja_JP.UTF-8\n\t\t;;\nesac\nexport LANG'
	fi
# -- setup locales ------------------------------------------------------------
#	timedatectl set-timezone "Asia/Tokyo"
	ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
	localectl set-locale LANG="ja_JP.utf8" LANGUAGE="ja:en"
	localectl set-x11-keymap "jp" "jp106" "" "terminate:ctrl_alt_bksp"
	locale | sed -e 's/LANG=C/LANG=ja_JP.UTF-8/'                \
	             -e 's/LANGUAGE=$/LANGUAGE=ja:en/'              \
	             -e 's/"C"/"ja_JP.UTF-8"/' > /etc/locale.conf
# -- module install -----------------------------------------------------------
	if [ ! -f /etc/apt/sources.list.orig ]; then
		cp -p  /etc/apt/sources.list /etc/apt/sources.list.orig
		cat <<- _EOT_ > /etc/apt/sources.list
			deb http://jp.archive.ubuntu.com/ubuntu/ artful main restricted
			deb http://jp.archive.ubuntu.com/ubuntu/ artful multiverse
			deb http://jp.archive.ubuntu.com/ubuntu/ artful universe
			deb http://jp.archive.ubuntu.com/ubuntu/ artful-backports main restricted universe multiverse
			deb http://jp.archive.ubuntu.com/ubuntu/ artful-updates main restricted
			deb http://jp.archive.ubuntu.com/ubuntu/ artful-updates multiverse
			deb http://jp.archive.ubuntu.com/ubuntu/ artful-updates universe
			deb http://security.ubuntu.com/ubuntu artful-security main restricted
			deb http://security.ubuntu.com/ubuntu artful-security multiverse
			deb http://security.ubuntu.com/ubuntu artful-security universe
_EOT_
	fi
	apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
	apt-get -y install gnome-getting-started-docs-ja gnome-user-docs-ja                                          \
	                   mythes-es hyphen-es                                                                       \
	                   ibus-mozc                                                                                 \
	                   clamav                                                                                    \
	                   ntpdate                                                                                   \
	                   openssh-server                                                                            \
	                   proftpd                                                                                   \
	                   smbclient cifs-utils                                                                      \
	                   apache2                                                                                   \
	                   bind9                                                                                     \
	                   anthy anthy-common                                                                        \
	                   libreoffice-help-ja libreoffice-l10n-ja                                                   \
	                   firefox-locale-ja thunderbird-locale-ja                                                   \
	                   fonts-takao-mincho fonts-takao-gothic fonts-takao-pgothic fonts-noto-cjk-extra            \
	                   language-pack-gnome-ja language-pack-gnome-ja-base language-pack-ja language-pack-ja-base \
	                   chromium-browser
# -- clamav -------------------------------------------------------------------
	if [ ! -f /etc/clamav/freshclam.conf.orig ]; then
		sed -i.orig /etc/clamav/freshclam.conf                                                     \
		    -e 's/# Check for new database 24 times a day/# Check for new database 4 times a day/' \
		    -e 's/Checks 24/Checks 4/'                                                             \
		    -e 's/^NotifyClamd/#&/'
	fi
# -- sshd ---------------------------------------------------------------------
	if [ ! -f /etc/ssh/sshd_config.orig ]; then
		sed -i.orig /etc/ssh/sshd_config                                   \
		    -e 's/^PermitRootLogin .*/PermitRootLogin yes/'                \
		    -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \
		    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'                 \
		    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d'               \
		    -e '$aUseDNS no\nIgnoreUserKnownHosts no'
	fi
# -- ftpd ---------------------------------------------------------------------
	if [ ! -f /etc/ftpusers.orig ]; then
		sed -i.orig /etc/ftpusers \
		    -e 's/root/# &/'
	fi

	if [ ! -f /etc/proftpd/proftpd.conf.orig ]; then
		sed -i.orig /etc/proftpd/proftpd.conf                                          \
		    -e '$aTimesGMT off\n<Global>\n\tRootLogin on\n\tUseFtpUsers on\n</Global>'
	fi
# -- cleaning -----------------------------------------------------------------
	apt-get -y autoremove
	apt-get autoclean
	apt-get clean
	/etc/init.d/dbus stop
	umount -fl /dev/pts /dev /sys /proc
	history -c

	exit
