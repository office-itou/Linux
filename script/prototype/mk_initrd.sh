#!/bin/bash

	set -eu

	declare -a    __PKGS=()				# packages
	declare -a    __OPTN=()				# options
	declare       __KVER=""				# --kver [VERSION]
	declare       __FORC=""				# --force
	declare -a    __ADDS=()				# --add [LIST]
	declare -a    __OMIT=()				# --omit [LIST]
	declare -a    __DRVA=()				# --add-drivers [LIST]
	declare -a    __DRVO=()				# --omit-drivers [LIST]
	declare -a    __FSTM=()				# --filesystems [LIST]
	declare -a    __INCL=()				# --include [SOURCE] [TARGET]
	declare -a    __INST=()				# --install [LIST]

	__PKGS=(
		kexec-tools
		dracut
		dracut-network
		dracut-live
		bash
		networkmanager
		btrfs-progs
		cryptsetup
		dmraid
		multipath-tools
		lvm2
		mdadm
		multipath-tools
		cifs-utils
		open-iscsi
		nbd
		nfs-utils
		nvme-cli
		jq
		biosdevname
		rsyslog
		memstrack
		bluetooth
		isc-dhcp-client
	)
	__KVER="$(uname -r)"
	__FORC="--force"
	__ADDS=(
		bash
		systemd
		i18n
		network-manager
		url-lib
		btrfs
		crypt
		dmsquash-live
		kernel-modules
		kernel-modules-extra
		livenet
		lvm
		mdraid
		multipath
		qemu-net
		cifs
		iscsi
		lunmask
		nbd
		nfs
		nvmf
		resume
		rootfs-block
		terminfo
		udev-rules
		virtiofs
		dracut-systemd
		pollcdrom
		syslog
		usrmount
		base
		fs-lib
		shutdown
	)
	__ADDS=(
		bash
		systemd
		systemd-ask-password
		systemd-battery-check
		systemd-cryptsetup
		systemd-initrd
		systemd-journald
		systemd-modules-load
		systemd-pcrphase
		systemd-sysctl
		systemd-tmpfiles
		systemd-udevd
		modsign
		dbus-broker
		console-setup
		dbus
		i18n
		network-manager
		network
		net-lib
		systemd-sysusers
	)
	__ADDS+=(
		btrfs
		crypt
		dm
		kernel-modules
		kernel-modules-extra
		kernel-network-modules
		lvm
		mdraid
		nvdimm
		overlay-root
		qemu
		qemu-net
		fido2
		pkcs11
		cifs
		hwdb
		iscsi
		lunmask
		nbd
		nfs
		resume
		rootfs-block
		terminfo
		udev-rules
		virtiofs
		dracut-systemd
		usrmount
		base
		fs-lib
		shell-interpreter
		shutdown
	)
# *00bash                        *01systemd-sysctl        45url-lib                    *90qemu          *95terminfo
#  00dash                         01systemd-sysext       *60systemd-sysusers           *90qemu-net      *95udev-rules
# *00systemd                      01systemd-timedated     62bluetooth                   91crypt-gpg      95virtfs
#  00systemd-network-management   01systemd-timesyncd     80lvmmerge                    91crypt-loop    *95virtiofs
#  00warpclock                   *01systemd-tmpfiles      80lvmthinpool-monitor        *91fido2          96securityfs
#  01fips                        *01systemd-udevd         81cio_ignore                  91pcsc           97biosdevname
#  01fips-crypto-policies         01systemd-veritysetup  *90btrfs                      *91pkcs11         97masterkey
#  01systemd-ac-power             02caps                 *90crypt                       91tpm2-tss       97systemd-emergency
# *01systemd-ask-password        *03modsign              *90dm                          91zipl          *98dracut-systemd
# *01systemd-battery-check        03rescue                90dmraid                     *95cifs           98ecryptfs
#  01systemd-bsod                 04watchdog              90dmsquash-live               95dasd           98integrity
#  01systemd-coredump             04watchdog-modules      90dmsquash-live-autooverlay   95dasd_mod       98pollcdrom
#  01systemd-creds               *06dbus-broker           90dmsquash-live-ntfs          95dcssblk        98selinux
# *01systemd-cryptsetup           06dbus-daemon          *90kernel-modules              95debug          98syslog
#  01systemd-hostnamed            06rngd                 *90kernel-modules-extra        95fcoe          *98usrmount
# *01systemd-initrd              *09console-setup        *90kernel-network-modules      95fcoe-uefi     *99base
#  01systemd-integritysetup      *09dbus                  90livenet                     95fstab-sys      99busybox
# *01systemd-journald            *10i18n                 *90lvm                        *95hwdb          *99fs-lib
#  01systemd-ldconfig             30convertfs            *90mdraid                     *95iscsi          99img-lib
# *01systemd-modules-load         35connman               90multipath                  *95lunmask        99memstrack
#  01systemd-networkd             35network-legacy        90numlock                    *95nbd           *99shell-interpreter
# *01systemd-pcrphase            *35network-manager      *90nvdimm                     *95nfs           *99shutdown
#  01systemd-portabled           *40network              *90overlay-root                95nvmf           99uefi-lib
#  01systemd-pstore               45drm                   90overlayfs                  *95resume
#  01systemd-repart              *45net-lib               90pcmcia                     *95rootfs-block
#  01systemd-resolved             45plymouth              90ppcmac                      95ssh-client
	__ADDS+=(
		systemd-network-management
		systemd-ldconfig
		systemd-networkd
		rescue
		drm
		url-lib
		ssh-client
		pollcdrom
		img-lib
		uefi-lib
	)
	__OMIT=(
	)
	__DRVA=(
		nvme
	)
	__DRVA=(
	)
	__DRVF=(
		vfat
		nls_ascii
		nls_cp437
		nls_iso8859_1
		video
		vgastate
		savagefb
		uvesafb
		radeon
		i915
		nouveau
		mgag200
		bochs
		virtio-gpu
		qxl
		vmwgfx
		cirrus
		vboxvideo
		e1000e
		r8169
	)
	__DRVO=()
	__FSTM=(
		ext4
		fat
		exfat
		vfat
		ntfs3
		isofs
		squashfs
		udf
		xfs
		btrfs
	)
	__INCL=(
		./script /script
	)
	__INCL=(
		/usr/share/vim /usr/share/vim
	)
	__INST=(
		apt-cache
		apt-get
		chroot
		coldreboot
		df
		eject
		fdisk
		file
		find
		ifconfig
		kexec
		kexec-load-kernel
		killall
		ldd
		lsblk
		mkfs
		mkfs.bfs
		mkfs.btrfs
		mkfs.cramfs
		mkfs.ext2
		mkfs.ext3
		mkfs.ext4
		mkfs.fat
		mkfs.minix
		mkfs.msdos
		mkfs.vfat
		mount.cifs
		mount.fuse
		mount.fuse3
		mount.nfs
		mount.nfs4
		mount.smb3
		pager
		pivot_root
		showmount
		switch_root
		tree
		unmkinitramfs
		vim
		vmcore-dmesg
		wget
		xzcat
	)
	__OPTN=(
		${__KVER:+--kver "${__KVER}"}
		${__FORC:+--force}
		${__ADDS[*]:+--add "${__ADDS[*]}"}
		${__OMIT[*]:+--omit "${__OMIT[*]}"}
		${__DRVA[*]:+--add-drivers "${__DRVA[*]}"}
		${__DRVF[*]:+--force-drivers "${__DRVF[*]}"}
		${__DRVO[*]:+--omit-drivers "${__DRVO[*]}"}
		${__FSTM[*]:+--filesystems "${__FSTM[*]}"}
		${__INCL[*]:+--include "${__INCL[@]}"}
		${__INST[*]:+--install "${__INST[*]}"}
		--lvmconf
		--no-hostonly
		--no-hostonly-i18n
		--xz
		./initramfs${__KVER:+"-${__KVER}"}
	)
#		--no-early-microcode
#		--nomdadmconf
#		--nolvmconf
#		--no-hostonly
#		--no-hostonly-i18n

	if command -v dracut > /dev/null 2>&1; then
		rm -f "./initramfs${__KVER:+"-${__KVER}"}" "./vmlinuz${__KVER:+"-${__KVER}"}"
		if dracut "${__OPTN[@]}"; then
			if [[ -e "/usr/lib/modules/${__KVER:?}/vmlinuz" ]]; then
				cp --preserve=timestamps "/usr/lib/modules/${__KVER:?}/vmlinuz" "./vmlinuz${__KVER:+"-${__KVER}"}"
			elif [[ -e "/boot/vmlinuz${__KVER:+"-${__KVER}"}" ]]; then
				cp --preserve=timestamps "/boot/vmlinuz${__KVER:+"-${__KVER}"}" ./
			fi
			cp --preserve=timestamps "./initramfs${__KVER:+"-${__KVER}"}" /srv/user/share/imgs/_loader/
			cp --preserve=timestamps "./vmlinuz${__KVER:+"-${__KVER}"}"   /srv/user/share/imgs/_loader/
			ln -sf "initramfs${__KVER:+"-${__KVER}"}" /srv/user/share/imgs/_loader/initramfs
			ln -sf "vmlinuz${__KVER:+"-${__KVER}"}"   /srv/user/share/imgs/_loader/vmlinuz
			chmod +r /srv/user/share/imgs/_loader/*
			ls -lh /srv/user/share/imgs/_loader/
		fi
	fi

	unset __PKGS __KVER __FORC __ADDS __OMIT __DRVA __DRVO __FSTM __OPTN

#	sudo apt-get install -s \
#	dracut-core cryptsetup-initramfs \
#	dracut-install \
#	dracut-live isomd5sum \
#	dracut-network \
#	dracut-squash \
#	dracut-config-generic \
#	dracut-config-rescue

#	sudo apt-get install -s \
#	bluez \
#	dbus-broker \
#	btrfs-progs \
#	kexec-tools