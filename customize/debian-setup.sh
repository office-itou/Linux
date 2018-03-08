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
# -- module install -----------------------------------------------------------
	apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade
	apt-get -y install task-japanese task-japanese-desktop \
	                   fcitx-mozc                          \
	                   clamav                              \
	                   ntpdate                             \
	                   openssh-server                      \
	                   proftpd                             \
	                   smbclient cifs-utils                \
	                   chromium
# -- im-config ----------------------------------------------------------------
	im-config -n fcitx
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
