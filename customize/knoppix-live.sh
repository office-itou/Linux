#!/bin/bash
# *****************************************************************************
# LiveCDCustomization [KNOPPIX_V8.6.1-2019-10-14-EN.iso]                      *
# *****************************************************************************
	LIVE_FILE="KNOPPIX_V8.6.1-2019-10-14-EN.iso"
	LIVE_DEST=`echo "${LIVE_FILE}" | sed -e 's/-EN/-JP/g'`
# == initialize ===============================================================
#	set -m								# ジョブ制御を有効にする
#	set -eu								# ステータス0以外と未定義変数の参照で終了
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
	echo "*******************************************************************************"
	trap 'exit 1' 1 2 3 15
# == tools install ============================================================
	apt -y install debootstrap squashfs-tools xorriso isolinux
# == initial processing =======================================================
	rm -rf   ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg ./knoppix-live/_work
	mkdir -p ./knoppix-live/media ./knoppix-live/cdimg ./knoppix-live/fsimg ./knoppix-live/_work
	# -------------------------------------------------------------------------
	cat <<- '_EOT_SH_' > ./knoppix-live/fsimg/knoppix-setup.sh
		#!/bin/bash
		# -----------------------------------------------------------------------------
			set -m								# ジョブ制御を有効にする
			set -eu								# ステータス0以外と未定義変数の参照で終了
			echo "*******************************************************************************"
			echo "`date +"%Y/%m/%d %H:%M:%S"` : start [$0]"
			echo "*******************************************************************************"
		# -- terminate ----------------------------------------------------------------
		fncEnd() {
			echo "--- terminate -----------------------------------------------------------------"
			RET_STS=$1

			history -c

			echo "*******************************************************************************"
			echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
			echo "*******************************************************************************"
			exit ${RET_STS}
		}
		# -- initialize ---------------------------------------------------------------
			echo "--- initialize ----------------------------------------------------------------"
			trap 'fncEnd 1' 1 2 3 15
			export PS1="(chroot) "
		# -- localize -----------------------------------------------------------------
			echo "--- localize ------------------------------------------------------------------"
			sed -i /etc/locale.gen                  \
			    -e 's/^[A-Za-z]/# &/g'              \
			    -e 's/# \(ja_JP.UTF-8 UTF-8\)/\1/g' \
			    -e 's/# \(en_US.UTF-8 UTF-8\)/\1/g'
			locale-gen
			update-locale LANG=ja_JP.UTF-8
			sed -i /etc/xdg/lxsession/LXDE/autostart               \
			    -e '$a@setxkbmap -layout jp -option ctrl:swapcase'
		# -- module install -----------------------------------------------------------
			echo "--- module install ------------------------------------------------------------"
		# -----------------------------------------------------------------------------
			dpkg --audit
			dpkg --configure -a
		# -----------------------------------------------------------------------------
			apt update                                                                \
			                                                                       && \
			apt install      -y -o Dpkg::Options::=--force-confdef                    \
			                    -o Dpkg::Options::=--force-overwrite                  \
			    task-japanese task-japanese-desktop ibus-mozc ntpdate                 \
			    open-vm-tools open-vm-tools-desktop                                   \
			                                                                       && \
			apt autoremove   -y                                                       \
			                                                                       && \
			apt autoclean    -y                                                       \
			                                                                       && \
			apt clean        -y                                                    || \
			fncEnd $?
		# -- open vm tools ------------------------------------------------------------
			echo "--- open vm tools -------------------------------------------------------------"
			# mkdir -p /media/hgfs
			echo -e '# Added by User\n' \
			        '.host:/ /media/hgfs fuse.vmhgfs-fuse allow_other,auto_unmount,noauto,users,defaults 0 0' \
			>> /etc/fstab
		# -- clamav -------------------------------------------------------------------
			echo "--- clamav --------------------------------------------------------------------"
			sed -i /etc/clamav/freshclam.conf \
			    -e 's/^NotifyClamd/#&/'
		# -- bind9 --------------------------------------------------------------------
			touch /etc/bind/named.conf.options
		# -- sshd ---------------------------------------------------------------------
			echo "--- sshd ----------------------------------------------------------------------"
			sed -i /etc/ssh/sshd_config                                        \
			    -e 's/^PermitRootLogin .*/PermitRootLogin yes/'                \
			    -e 's/#PasswordAuthentication yes/PasswordAuthentication yes/' \
			    -e '/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/d'                 \
			    -e '/HostKey \/etc\/ssh\/ssh_host_ed25519_key/d'               \
			    -e '$aUseDNS no\nIgnoreUserKnownHosts no'                      \
			    -e 's/^UsePrivilegeSeparation/#&/'                             \
			    -e 's/^KeyRegenerationInterval/#&/'                            \
			    -e 's/^ServerKeyBits/#&/'                                      \
			    -e 's/^RSAAuthentication/#&/'                                  \
			    -e 's/^RhostsRSAAuthentication/#&/'
		# -- samba --------------------------------------------------------------------
			echo "--- samba ---------------------------------------------------------------------"
			CMD_UADD=`which useradd`
			CMD_UDEL=`which userdel`
			CMD_GADD=`which groupadd`
			CMD_GDEL=`which groupdel`
			CMD_GPWD=`which gpasswd`
			CMD_FALS=`which false`
			testparm -s -v |                                                                        \
			sed -e 's/\(dos charset\) =.*$/\1 = CP932/'                                             \
			    -e 's/\(security\) =.*$/\1 = USER/'                                                 \
			    -e 's/\(server role\) =.*$/\1 = standalone server/'                                 \
			    -e 's/\(pam password change\) =.*$/\1 = Yes/'                                       \
			    -e 's/\(load printers\) =.*$/\1 = No/'                                              \
			    -e 's~\(log file\) =.*$~\1 = /var/log/samba/log.%m~'                                \
			    -e 's/\(max log size\) =.*$/\1 = 1000/'                                             \
			    -e 's/\(min protocol\) =.*$/\1 = NT1/'                                              \
			    -e 's/\(server min protocol\) =.*$/\1 = NT1/'                                       \
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
			    -e 's/\(os level\) =.*$/\1 = 35/'                                                   \
			    -e 's/\(preferred master\) =.*$/\1 = Yes/'                                          \
			    -e 's/\(domain master\) =.*$/\1 = Yes/'                                             \
			    -e 's/\(wins support\) =.*$/\1 = Yes/'                                              \
			    -e 's/\(unix password sync\) =.*$/\1 = No/'                                         \
			    -e '/idmap config \* : backend =/i \\tidmap config \* : range = 1000-10000'         \
			    -e 's/\(admin users\) =.*$/\1 = administrator/'                                     \
			    -e 's/\(printing\) =.*$/\1 = bsd/'                                                  \
			    -e '/map to guest =.*$/d'                                                           \
			    -e '/null passwords =.*$/d'                                                         \
			    -e '/obey pam restrictions =.*$/d'                                                  \
			    -e '/enable privileges =.*$/d'                                                      \
			    -e '/password level =.*$/d'                                                         \
			    -e '/client use spnego principal =.*$/d'                                            \
			    -e '/syslog =.*$/d'                                                                 \
			    -e '/syslog only =.*$/d'                                                            \
			    -e '/use spnego =.*$/d'                                                             \
			    -e '/paranoid server security =.*$/d'                                               \
			    -e '/dns proxy =.*$/d'                                                              \
			    -e '/time offset =.*$/d'                                                            \
			    -e '/usershare allow guests =.*$/d'                                                 \
			    -e '/idmap backend =.*$/d'                                                          \
			    -e '/idmap uid =.*$/d'                                                              \
			    -e '/idmap gid =.*$/d'                                                              \
			    -e '/winbind separator =.*$/d'                                                      \
			    -e '/acl check permissions =.*$/d'                                                  \
			    -e '/only user =.*$/d'                                                              \
			    -e '/share modes =.*$/d'                                                            \
			    -e '/nbt client socket address =.*$/d'                                              \
			    -e '/lsa over netlogon =.*$/d'                                                      \
			    -e '/.* = $/d'                                                                      \
			> ./smb.conf
			testparm -s ./smb.conf > /etc/samba/smb.conf
			rm -f ./smb.conf
		# -- root and user's setting --------------------------------------------------
			echo "--- root and user's setting ---------------------------------------------------"
			smbpasswd -a knoppix -n
			echo -e "knoppix\nknoppix\n" | passwd knoppix
			echo -e "knoppix\nknoppix\n" | smbpasswd knoppix
			# -------------------------------------------------------------------------
			for USER_NAME in "skel" "root" "knoppix"
			do
				if [ "${USER_NAME}" == "skel" ]; then
					USER_HOME="/etc/skel"
				else
					USER_HOME=`awk -F ':' '$1=="'${USER_NAME}'" {print $6;}' /etc/passwd`
				fi
				pushd ${USER_HOME} > /dev/null
					echo "--- .bashrc -------------------------------------------------------------------"
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
					echo "--- .vimrc --------------------------------------------------------------------"
					cat <<- _EOT_ > .vimrc
						set number              " Print the line number in front of each line.
						set tabstop=4           " Number of spaces that a <Tab> in the file counts for.
						set list                " List mode: Show tabs as CTRL-I is displayed, display $ after end of line.
						set listchars=tab:\>_   " Strings to use in 'list' mode and for the |:list| command.
						set nowrap              " This option changes how text is displayed.
						set showmode            " If in Insert, Replace or Visual mode put a message on the last line.
						set laststatus=2        " The value of this option influences when the last window will have a status line always.
						syntax on               " Vim5 and later versions support syntax highlighting.
		_EOT_
					echo "--- .curlrc -------------------------------------------------------------------"
					cat <<- _EOT_ > .curlrc
						location
						progress-bar
						remote-time
						show-error
		_EOT_
					if [ "${USER_NAME}" != "skel" ]; then
						echo "--- xinput.d ------------------------------------------------------------------"
						mkdir .xinput.d
						ln -s /etc/X11/xinit/xinput.d/ja_JP .xinput.d/ja_JP
						chown -R ${USER_NAME}:${USER_NAME} .xinput.d .bashrc .vimrc .curlrc
					fi
				popd > /dev/null
			done
		# -- cleaning -----------------------------------------------------------------
			echo "--- cleaning ------------------------------------------------------------------"
			fncEnd 0
		# -- EOF ----------------------------------------------------------------------
_EOT_SH_
	# -------------------------------------------------------------------------
	if [ ! -f ./${LIVE_FILE} ]; then
		wget "http://ftp.riken.jp/Linux/knoppix/knoppix-dvd/${LIVE_FILE}"
#		wget "http://ftp.kddilabs.jp/.017/Linux/packages/knoppix/knoppix-dvd/${LIVE_FILE}"
	fi
	# -------------------------------------------------------------------------
	OS_ARCH=`dpkg --print-architecture`
	# -------------------------------------------------------------------------
	ISO2_START=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $2; }'`
	ISO2_COUNT=`fdisk -l ./${LIVE_FILE} | awk '$1=="'./${LIVE_FILE}2'" { print $4; }'`
	# -------------------------------------------------------------------------
	dd if=./${LIVE_FILE} of=./knoppix-live/efiboot.img bs=512 skip=${ISO2_START} count=${ISO2_COUNT}
	# -------------------------------------------------------------------------
	echo "--- DVD -> HDD ----------------------------------------------------------------"
	mount -r -o loop ./${LIVE_FILE} ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/cdimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	echo "--- Change minirt.gz ----------------------------------------------------------"
	pushd ./knoppix-live/_work > /dev/null
		zcat ../cdimg/boot/isolinux/minirt.gz | cpio -idm
		mkdir -p media/hgfs
		chown knoppix.knoppix media/hgfs
		find . | cpio -H newc -o | gzip -9 > ../cdimg/boot/isolinux/minirt.gz
	popd > /dev/null
	# -------------------------------------------------------------------------
	if [ ! -f ./knoppix-live/KNOPPIX_FS.iso ]; then
		echo "--- Extract KNOPPIX -----------------------------------------------------------"
		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX ./knoppix-live/KNOPPIX_FS.iso
	fi
	# -------------------------------------------------------------------------
#	if [ ! -f ./knoppix-live/KNOPPIX1_FS.iso ]; then
#		echo "--- Extract KNOPPIX1 ----------------------------------------------------------"
#		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 ./knoppix-live/KNOPPIX1_FS.iso
#	fi
	# -------------------------------------------------------------------------
#	if [ ! -f ./knoppix-live/KNOPPIX2_FS.iso ]; then
#		echo "--- Extract KNOPPIX2 ----------------------------------------------------------"
#		extract_compressed_fs ./knoppix-live/cdimg/KNOPPIX/KNOPPIX2 ./knoppix-live/KNOPPIX2_FS.iso
#	fi
	# -------------------------------------------------------------------------
	rm -f ./knoppix-live/cdimg/KNOPPIX/KNOPPIX
#	      ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1
#	      ./knoppix-live/cdimg/KNOPPIX/KNOPPIX2
	# -------------------------------------------------------------------------
	echo "--- KNOPPIX_FS.iso -> HDD -----------------------------------------------------"
	mount -r -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media
	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
#	echo "--- KNOPPIX1_FS.iso -> HDD ----------------------------------------------------"
#	mount -r -o loop ./knoppix-live/KNOPPIX1_FS.iso ./knoppix-live/media
#	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
#	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
#	echo "--- KNOPPIX2_FS.iso -> HDD ----------------------------------------------------"
#	mount -r -o loop ./knoppix-live/KNOPPIX2_FS.iso ./knoppix-live/media
#	cp -rp ./knoppix-live/media/* ./knoppix-live/fsimg/
#	umount ./knoppix-live/media
# --- memo --------------------------------------------------------------------
#	KNOPPIX : base system incl. Firefox, Gimp, Libreoffice
#	KNOPPIX1: openscad, slic3r, scribus, inkscape, blender, freecad, texlive, kdenlive, openshot, meshlab
#	KNOPPIX2: docker 64bit (knocker)
# =============================================================================
	echo "--- Customize HDD [chroot] ----------------------------------------------------"
	# -------------------------------------------------------------------------
	ln -fs /usr/share/zoneinfo/Asia/Tokyo ./knoppix-live/fsimg/etc/localtime
	sed -i ./knoppix-live/fsimg/etc/adjtime  \
	    -e 's/LOCAL/UTC/g'
	sed -i ./knoppix-live/fsimg/etc/ntp.conf      \
	    -e 's/^\(pool\)/#\1/g'                    \
	    -e '/^# pool:/ a pool ntp.nict.jp iburst'
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/fsimg/etc/rc.local                                      \
	    -e 's/^SERVICES="\([a-z]*\)"/SERVICES="\1 rsyslog bind9 ssh smbd nmbd"/g'
	# -------------------------------------------------------------------------
	sed -i.orig ./knoppix-live/fsimg/etc/resolv.conf  \
	    -e '$anameserver 1.1.1.1\nnameserver 1.0.0.1'
	sed -i.orig ./knoppix-live/fsimg/etc/apt/sources.list            \
	    -e 's/ftp.de.debian.org/ftp.debian.org/g'                    \
	    -e 's~\(deb http://debian-knoppix.alioth.debian.org\)~#\1~g'
	# -------------------------------------------------------------------------
	mount --bind /dev     ./knoppix-live/fsimg/dev
	mount --bind /dev/pts ./knoppix-live/fsimg/dev/pts
	mount --bind /proc    ./knoppix-live/fsimg/proc
	mount --bind /sys     ./knoppix-live/fsimg/sys
	# -------------------------------------------------------------------------
	chroot ./knoppix-live/fsimg /bin/bash /knoppix-setup.sh $1 $2
	RET_STS=$?
	# -------------------------------------------------------------------------
	umount ./knoppix-live/fsimg/sys     || umount -lf ./knoppix-live/fsimg/sys
	umount ./knoppix-live/fsimg/proc    || umount -lf ./knoppix-live/fsimg/proc
	umount ./knoppix-live/fsimg/dev/pts || umount -lf ./knoppix-live/fsimg/dev/pts
	umount ./knoppix-live/fsimg/dev     || umount -lf ./knoppix-live/fsimg/dev
	# -------------------------------------------------------------------------
	if [ ${RET_STS} -ne 0 ]; then
		exit ${RET_STS}
	fi
	# -------------------------------------------------------------------------
	mv ./knoppix-live/fsimg/etc/resolv.conf.orig ./knoppix-live/fsimg/etc/resolv.conf
	find   ./knoppix-live/fsimg/var/log/ -type f -name \* -exec cp -f /dev/null {} \;
	rm -rf ./knoppix-live/fsimg/root/.bash_history           \
	       ./knoppix-live/fsimg/root/.viminfo                \
	       ./knoppix-live/fsimg/tmp/*                        \
	       ./knoppix-live/fsimg/var/cache/apt/*.bin          \
	       ./knoppix-live/fsimg/var/cache/apt/archives/*.deb \
	       ./knoppix-live/fsimg/knoppix-setup.sh
# =============================================================================
	echo "--- Remaster HDD -> Compress --------------------------------------------------"
	# -------------------------------------------------------------------------
	if [ "${OS_ARCH}" = "i386" ]; then
		LIVE_VOLID="KNOPPIX_8"
		LIVE_VOLID_FS="KNOPPIX_FS"
#		LIVE_VOLID_FS1="KNOPPIX_ADDONS1"
#		LIVE_VOLID_FS2="KNOPPIX_ADDONS2"
	else
		LIVE_VOLID=`volname ./${LIVE_FILE}`
		LIVE_VOLID_FS=`volname ./knoppix-live/KNOPPIX_FS.iso`
#		LIVE_VOLID_FS1=`volname ./knoppix-live/KNOPPIX1_FS.iso`
#		LIVE_VOLID_FS2=`volname ./knoppix-live/KNOPPIX2_FS.iso`
	fi
	# -------------------------------------------------------------------------
	rm -f ./knoppix-live/KNOPPIX_FS.txt
#	      ./knoppix-live/KNOPPIX1_FS.txt
#	      ./knoppix-live/KNOPPIX2_FS.txt
	# -------------------------------------------------------------------------
#	mount -r -o loop ./knoppix-live/KNOPPIX_FS.iso ./knoppix-live/media/
#	find ./knoppix-live/media/ -type f -print > ./knoppix-live/KNOPPIX_FS.txt
#	umount ./knoppix-live/media/
	# -------------------------------------------------------------------------
#	mount -r -o loop ./knoppix-live/KNOPPIX1_FS.iso ./knoppix-live/media/
#	find ./knoppix-live/media/ -type f -print > ./knoppix-live/KNOPPIX1_FS.txt
#	umount ./knoppix-live/media/
	# -------------------------------------------------------------------------
#	mount -r -o loop ./knoppix-live/KNOPPIX2_FS.iso ./knoppix-live/media/
#	find ./knoppix-live/media/ -type f -print > ./knoppix-live/KNOPPIX2_FS.txt
#	umount ./knoppix-live/media/
	# -------------------------------------------------------------------------
#	rm -f ./knoppix-live/filelist.txt  \
#	      ./knoppix-live/filelist$.txt \
#	      ./knoppix-live/filelist0.txt \
#	      ./knoppix-live/filelist1.txt
	# -------------------------------------------------------------------------
#	cat ./knoppix-live/KNOPPIX_FS.txt                                 | sort -u | sed -e 's~./knoppix-live/media~~g' > ./knoppix-live/filelist0.txt
#	cat ./knoppix-live/KNOPPIX1_FS.txt ./knoppix-live/KNOPPIX2_FS.txt | sort -u | sed -e 's~./knoppix-live/media~~g' > ./knoppix-live/filelist1.txt
#	cat ./knoppix-live/filelist1.txt | grep -v -F -f ./knoppix-live/filelist0.txt > ./knoppix-live/filelist$.txt
	# -------------------------------------------------------------------------
#	rm -f ./knoppix-live/package-list.txt \
#	      ./knoppix-live/package-list.tmp
#	for m in openscad slic3r scribus inkscape blender freecad texlive kdenlive openshot meshlab
#	do
#		dpkg -L $m >> ./knoppix-live/package-list.tmp
#	done
#	for f in `sort -u ./knoppix-live/package-list.tmp | grep "openscad\|slic3r\|scribus\|inkscape\|blender\|freecad\|texlive\|kdenlive\|openshot\|meshlab"`
#	do
#		if [ -f $f ] || [ -d $f ]; then
#	        echo $f >> ./knoppix-live/package-list.txt
#		fi
#	done
	pushd ./knoppix-live/fsimg > /dev/null
		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS}" -o ../KNOPPIX_FS.tmp .
#		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS}"  -o ../KNOPPIX_FS.tmp  -exclude-list ../package-list.txt .
#		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS1}" -o ../KNOPPIX1_FS.tmp -path-list    ../package-list.txt .
#		xorriso -as mkisofs -D -R -U -V "${LIVE_VOLID_FS2}" -o ../KNOPPIX2_FS.tmp -path-list    ../KNOPPIX2_FS.txt  .
	popd > /dev/null
	# -------------------------------------------------------------------------
	create_compressed_fs         -f ./knoppix-live/isotemp -q -L  9 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX  < ./knoppix-live/KNOPPIX_FS.tmp
#	create_compressed_fs -B 512K -f ./knoppix-live/isotemp -q -L -2 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX1 < ./knoppix-live/KNOPPIX1_FS.tmp
#	create_compressed_fs -B 512K -f ./knoppix-live/isotemp -q -L -2 - ./knoppix-live/cdimg/KNOPPIX/KNOPPIX2 < ./knoppix-live/KNOPPIX2_FS.tmp
	ls -lh ./knoppix-live/cdimg/KNOPPIX/KNOPPIX*
	# -------------------------------------------------------------------------
	cp ./knoppix-live/efiboot.img ./knoppix-live/cdimg/
	# -------------------------------------------------------------------------
	sed -i ./knoppix-live/cdimg/boot/isolinux/isolinux.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/cdimg/boot/isolinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	# -------------------------------------------------------------------------
	mount -o loop ./knoppix-live/cdimg/efiboot.img ./knoppix-live/media
	sed -i ./knoppix-live/media/boot/syslinux/syslnx32.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	sed -i ./knoppix-live/media/boot/syslinux/syslnx64.cfg -e 's/lang=en/lang=ja xkeyboard=jp/' -e 's/^APPEND.*/\0 tz=Asia\/Tokyo/g'
	umount ./knoppix-live/media
	# -------------------------------------------------------------------------
	echo "--- Remaster HDD -> ISO Image -------------------------------------------------"
	# -------------------------------------------------------------------------
	pushd ./knoppix-live/cdimg > /dev/null
		find KNOPPIX -name "KNOPPIX*" -type f -exec sha1sum -b {} \; > KNOPPIX/sha1sums
		xorriso -as mkisofs \
		    -quiet \
		    -iso-level 3 \
		    -full-iso9660-filenames \
		    -volid "${LIVE_VOLID}" \
		    -eltorito-boot boot/isolinux/isolinux.bin \
		    -eltorito-catalog boot/isolinux/boot.cat \
		    -no-emul-boot -boot-load-size 4 -boot-info-table \
		    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
		    -eltorito-alt-boot \
		    -e efiboot.img \
		    -no-emul-boot -isohybrid-gpt-basdat \
		    -output "../../${LIVE_DEST}" \
		    "."
	popd > /dev/null
	ls -lh KNOPPIX*
# =============================================================================
	echo "*******************************************************************************"
	echo "`date +"%Y/%m/%d %H:%M:%S"` : end [$0]"
	echo "*******************************************************************************"
	exit 0
# == EOF ======================================================================
