#!/bin/bash
set -eum
# -- terminate ----------------------------------------------------------------
fncEnd() {
	RET_STS=$1

	history -c
	/etc/init.d/dbus stop
	umount /dev/pts || umount -fl /dev/pts
	umount /dev     || umount -fl /dev
	umount /sys     || umount -fl /sys
	umount /proc    || umount -fl /proc

	exit ${RET_STS}
}
# -- initialize ---------------------------------------------------------------
	trap 'fncEnd 1' 1 2 3 15
	export PS1="(chroot) "
	mount -t proc     proc     /proc
	mount -t sysfs    sysfs    /sys
	mount -t devtmpfs /dev     /dev
	mount -t devpts   /dev/pts /dev/pts
	/etc/init.d/dbus start
# -- localize -----------------------------------------------------------------
	sed -i /etc/locale.gen                  \
	    -e 's/^[A-Za-z]/# &/g'              \
	    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
	    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
	locale-gen
	update-locale LANG=ja_JP.UTF-8
	cat <<- _EOT_ >> /etc/xdg/lxsession/LXDE/autostart
		@setxkbmap -layout jp -option ctrl:swapcase
_EOT_
# -- module install -----------------------------------------------------------
# <memo>
#   https://lists.debian.org/debian-user/2011/04/msg01168.html
#   https://manpages.debian.org/stretch/apt/sources.list.5.ja.html
#       Dpkg::Options::= --force-confdef or --force-confnew or --force-confold
#       Acquire::Check-Valid-Until=no
#   http://linux-memo.sakura.ne.jp/knoppix/knoppix_customjp080100_cust.html
#       dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' | sort -nr | less
	sed -i /etc/apt/sources.list                     \
	    -e 's/ftp.de.debian.org/ftp.debian.org/g'
	APT_REL="-t stable -t testing -t unstable -t experimental"
#	APT_REL=""
	APT_UPD="${APT_REL} -o Acquire::Check-Valid-Until=no"
	APT_UPG="${APT_REL} -o Dpkg::Options::=--force-confdef"
	APT_INS="${APT_REL} -o Dpkg::Options::=--force-confdef"
	APT_RMV=""
	dpkg --configure -a                                                    && \
	aptitude -q -y -f         install                                      && \
	aptitude -q -y ${APT_RMV} purge                                           \
	    wine3.1                                                               \
	    gcompris gcompris-data gcompris-sound-de                              \
	    etoys etoys-doc                                                       \
	    gnome-games                                                           \
	    neverball neverball-common neverball-data                             \
	    scilab scilab-cli scilab-data scilab-doc scilab-full-bin              \
	    scilab-include scilab-minimal-bin                                     \
	    linux-source-4.16.5                                                && \
	aptitude -q    ${APT_UPD} update                                       && \
	aptitude -q -y ${APT_INS} install                                         \
	    ca-certificates                                                       \
	    man-db                                                                \
	    x11-apps                                                              \
	    task-japanese task-japanese-desktop                                   \
	    im-config ibus-mozc                                                   \
	    manpages-ja manpages-ja-dev                                           \
	    libreoffice-help-ja libreoffice-l10n-ja                            && \
	aptitude -q               autoclean                                    && \
	aptitude -q               clean                                        || \
	fncEnd $?
# -- root user's setting ------------------------------------------------------
	for USER_NAME in "knoppix" "root"
	do
		USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
		pushd ${USER_HOME} > /dev/null
			echo --- .vimrc --------------------------------------------------------------------
			cat <<- _EOT_ >> .vimrc
				set number				" Print the line number in front of each line.
				set tabstop=4			" Number of spaces that a <Tab> in the file counts for.
				set list				" List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
				set listchars=tab:\>_	" Strings to use in 'list' mode and for the |:list| command.
				set nowrap				" This option changes how text is displayed.
				set showmode			" If in Insert, Replace or Visual mode put a message on the last line.
				set laststatus=2		" The value of this option influences when the last window will have a status line always.
_EOT_
			echo --- .curlrc -------------------------------------------------------------------
			cat <<- _EOT_ >> .curlrc
				location
				progress-bar
				remote-time
				show-error
_EOT_
			echo --- .bashrc -------------------------------------------------------------------
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
			echo --- im-config -----------------------------------------------------------------
			im-config -n ibus
			mkdir .xinput.d
			ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
			chown -R ${USER_NAME}:${USER_NAME} .xinput.d
		popd > /dev/null
	done
# -- cleaning -----------------------------------------------------------------
	fncEnd 0
# -- EOF ----------------------------------------------------------------------
# *****************************************************************************
# <memo>
#   [im-config]
#     Change Kanji mode:[Windows key]+[Space key]->[Zenkaku/Hankaku key]
# *****************************************************************************
