#!/bin/bash
# *****************************************************************************
# debootstrap for testing cdrom
# *****************************************************************************
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	if [ "`LANG=C dpkg -l debootstrap squashfs-tools xorriso isolinux | awk '$1==\"un\" {print $1;}'`" != "" ]; then
		apt -y install debootstrap squashfs-tools xorriso isolinux
	fi
# =============================================================================
	rm -rf   ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg
	mkdir -p ./debootstrap/media ./debootstrap/cdimg ./debootstrap/fsimg
# -----------------------------------------------------------------------------
	mount -o loop ./debian-testing-amd64-DVD-1.iso ./debootstrap/media
	debootstrap --no-check-gpg testing ./debootstrap/fsimg/ file:./debootstrap/media/
	umount ./debootstrap/media
# =============================================================================
	cat <<- _EOT_SH_ > ./debootstrap/fsimg/inst-dvd.sh
		cp -p /etc/apt/sources.list /etc/apt/sources.list.orig
		: > /etc/apt/sources.list
		mkdir -p /media/cdrom
		mount -o loop /debian-testing-amd64-DVD-1.iso /media/cdrom
		apt-cdrom add -m --cdrom /media/cdrom
		apt install      -q -y --allow-unauthenticated                            \\
		    task-desktop task-laptop task-lxde-desktop task-ssh-server            \\
		    task-japanese task-japanese-desktop                                   \\
		    network-manager curl rsync inxi lvm2 gpg                              \\
		    build-essential vim bc                                                \\
		    sudo tasksel                                                          \\
		    openssh-server                                                        \\
		    samba smbclient cifs-utils                                            \\
		    cups cups-common                                                      \\
		    lxde fonts-noto                                                       \\
		    libreoffice-help-ja libreoffice-l10n-ja                               \\
		    firefox-esr-l10n-ja thunderbird thunderbird-l10n-ja
		umount /media/cdrom
		# -----------------------------------------------------------------------------
		cp -p /etc/apt/sources.list /etc/apt/sources.list.cdrom
		cat <<- _EOT_ > /etc/apt/sources.list
			deb http://deb.debian.org/debian testing main non-free contrib
			deb-src http://deb.debian.org/debian testing main non-free contrib
			
			# deb http://security.debian.org/debian-security testing/updates main contrib non-free
			# deb-src http://security.debian.org/debian-security testing/updates main contrib non-free
			
			# testing-updates, previously known as 'volatile'
			deb http://deb.debian.org/debian testing-updates main contrib non-free
			deb-src http://deb.debian.org/debian testing-updates main contrib non-free
		_EOT_
		# echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/ /' | tee /etc/apt/sources.list.d/home:ungoogled_chromium.list
		# curl -fsSL https://download.opensuse.org/repositories/home:ungoogled_chromium/Debian_Sid/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home:ungoogled_chromium.gpg > /dev/null
		# if [ -f Release.key ]; then rm -f Release.key; fi
		apt update       -q                                                    && \\
		apt upgrade      -q -y                                                 && \\
		apt full-upgrade -q -y                                                 && \\
		apt install      -q -y                                                    \\
		    bind9 bind9utils dnsutils                                             \\
		    isc-dhcp-server                                                       \\
		    chrony clamav indent ibus-mozc mozc-utils-gui
		#   ungoogled-chromium
		# diff -y /etc/apt/sources.list /etc/apt/sources.list.orig
		# diff -y /etc/apt/sources.list /etc/apt/sources.list.cdrom
		# -----------------------------------------------------------------------------
		sed -i /etc/locale.gen                  \\
		    -e 's/^[A-Za-z]/# &/g'              \\
		    -e 's/# \\(ja_JP.UTF-8 UTF-8\\)/\\1/g' \\
		    -e 's/# \\(en_US.UTF-8 UTF-8\\)/\\1/g'
		locale-gen
		update-locale LANG=ja_JP.UTF-8
		# -----------------------------------------------------------------------------
		for TARGET in "/etc/skel" "/root"
		do
			pushd \${TARGET} > /dev/null
				cat <<- _EOT_ >> .bashrc
					# --- 日本語文字化け対策 ---
					case "\\\${TERM}" in
					    "linux" ) export LANG=C;;
					    * )                    ;;
					esac
					# export GTK_IM_MODULE=ibus
					# export XMODIFIERS=@im=ibus
					# export QT_IM_MODULE=ibus
				_EOT_
				cat <<- _EOT_ > .vimrc
					set number              " Print the line number in front of each line.
					set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
					set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
					set listchars=tab:\>_   " Strings to use in 'list' mode and for the |:list| command.
					set nowrap              " This option changes how text is displayed.
					set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
					set laststatus=2        " The value of this option influences when the last window will have a status line always.
				_EOT_
				cat <<- _EOT_ > .curlrc
					location
					progress-bar
					remote-time
					show-error
				_EOT_
			popd > /dev/null
		done
		# -----------------------------------------------------------------------------
		apt -q -y autoremove
		apt -q autoclean
		apt -q clean
_EOT_SH_
# =============================================================================
	cp -p ./debian-testing-amd64-DVD-1.iso ./debootstrap/fsimg/
# -----------------------------------------------------------------------------
	mount --bind /dev ./debootstrap/fsimg/dev && mount --bind /dev/pts ./debootstrap/fsimg/dev/pts && mount --bind /proc ./debootstrap/fsimg/proc
	LANG=C chroot ./debootstrap/fsimg/ /bin/bash /inst-dvd.sh
	umount -lf ./debootstrap/fsimg/proc && umount -lf ./debootstrap/fsimg/dev/pts && umount -lf ./debootstrap/fsimg/dev
# -----------------------------------------------------------------------------
	find  ./debootstrap/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./debootstrap/fsimg/debian-testing-amd64-DVD-1.iso \
	       ./debootstrap/fsimg/inst-dvd.sh                    \
	       ./debootstrap/fsimg/root/.bash_history             \
	       ./debootstrap/fsimg/root/.viminfo                  \
	       ./debootstrap/fsimg/tmp/*                          \
	       ./debootstrap/fsimg/var/cache/apt/*.bin            \
	       ./debootstrap/fsimg/var/cache/apt/archives/*.deb
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == memo =====================================================================
#	sudo bash -c 'mount --bind /dev ./debootstrap/fsimg/dev && mount --bind /dev/pts ./debootstrap/fsimg/dev/pts && mount --bind /proc ./debootstrap/fsimg/proc'
#	sudo bash -c 'LANG=C chroot ./debootstrap/fsimg/'
#	sudo bash -c 'umount -lf ./debootstrap/fsimg/proc && umount -lf ./debootstrap/fsimg/dev/pts && umount -lf ./debootstrap/fsimg/dev'
# -----------------------------------------------------------------------------
#	tar -cz ./debootstrap/fsimg/inst-dvd.sh | xxd -ps
#	cat <<- _EOT_ | xxd -r -p | tar -xz
# -----------------------------------------------------------------------------
#	sudo apt -y install squashfs-tools xorriso cloop-utils isolinux
# == EOF ======================================================================
