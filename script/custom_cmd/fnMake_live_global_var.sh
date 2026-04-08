# shellcheck disable=SC2148

	# --- mkosi command line parameter ----------------------------------------
#	declare -r    _MKOS_BOOT="yes"		# --bootable=
	declare -r    _MKOS_OUTP="root_img"	# --output=
#	declare -r    _MKOS_FMAT="directory" # --format=
#	declare -r    _MKOS_FMAT="tar"		# "
#	declare -r    _MKOS_FMAT="cpio"		# "
	declare -r    _MKOS_FMAT="disk"		# "
#	declare -r    _MKOS_FMAT="uki"		# "
#	declare -r    _MKOS_FMAT="esp"		# "
#	declare -r    _MKOS_FMAT="oci"		# "
#	declare -r    _MKOS_FMAT="sysext"	# "
#	declare -r    _MKOS_FMAT="confext"	# "
#	declare -r    _MKOS_FMAT="portable"	# "
#	declare -r    _MKOS_FMAT="addon"	# "
#	declare -r    _MKOS_FMAT="none"		# "
#	declare -r    _MKOS_NWRK="yes"		# --with-network=
	declare -r    _MKOS_RECM="yes"		# --with-recommends
#	declare -r    _MKOS_DIST="fedora"	# --distribution=
#	declare -r    _MKOS_DIST="debian"	# "
#	declare -r    _MKOS_DIST="kali"		# "
#	declare -r    _MKOS_DIST="ubuntu"	# "
#	declare -r    _MKOS_DIST="arch"		# "
#	declare -r    _MKOS_DIST="opensuse"	# "
#	declare -r    _MKOS_DIST="mageia"	# "
#	declare -r    _MKOS_DIST="centos"	# "
#	declare -r    _MKOS_DIST="rhel"		# "
#	declare -r    _MKOS_DIST="rhel-ubi"	# "
#	declare -r    _MKOS_DIST="openmandriva" # "
#	declare -r    _MKOS_DIST="rocky"	# "
#	declare -r    _MKOS_DIST="alma"		# "
#	declare -r    _MKOS_DIST="azure"	# "
#	declare -r    _MKOS_DIST="custom"	# "
#	declare -r    _MKOS_VERS=""			# --release=
#	declare -r    _MKOS_ARCH="alpha"	# --architecture=
#	declare -r    _MKOS_ARCH="arc"		# "
#	declare -r    _MKOS_ARCH="arm"		# "
#	declare -r    _MKOS_ARCH="arm64"	# "
#	declare -r    _MKOS_ARCH="ia64"		# "
#	declare -r    _MKOS_ARCH="loongarch64" # "
#	declare -r    _MKOS_ARCH="mips64-le" # "
#	declare -r    _MKOS_ARCH="mips-le"	# "
#	declare -r    _MKOS_ARCH="parisc"	# "
#	declare -r    _MKOS_ARCH="ppc"		# "
#	declare -r    _MKOS_ARCH="ppc64"	# "
#	declare -r    _MKOS_ARCH="ppc64-le"	# "
#	declare -r    _MKOS_ARCH="riscv32"	# "
#	declare -r    _MKOS_ARCH="riscv64"	# "
#	declare -r    _MKOS_ARCH="s390"		# "
#	declare -r    _MKOS_ARCH="s390x"	# "
#	declare -r    _MKOS_ARCH="tilegx"	# "
#	declare -r    _MKOS_ARCH="x86"		# "
	declare -r    _MKOS_ARCH="x86-64"	# "

	# --- live files ----------------------------------------------------------
	declare -r    _FILE_RTIM="${_MKOS_OUTP:?}.raw"			# root image
	declare -r    _FILE_SQFS="squashfs.img"					# squashfs
	declare -r    _FILE_MBRF="bios.img"						# mbr image
	declare -r    _FILE_UEFI="uefi.img"						# uefi image
	declare -r    _FILE_BCAT="boot.cat"						# eltorito catalog
#	declare -r    _FILE_ETRI=""								# 
#	declare -r    _FILE_BIOS=""								# 

	declare -r    _FILE_ICFG="isolinux.cfg"					# isolinux.cfg
	declare -r    _FILE_GCFG="grub.cfg"						# grub.cfg
	declare -r    _FILE_MENU="menu.cfg"						# menu.cfg
	declare -r    _FILE_THME="theme.cfg"					# theme.cfg

	declare -r    _DIRS_MNTP="mntp"							# mount point
	declare -r    _DIRS_RTFS="rtfs"							# root image
	declare -r    _DIRS_CDFS="cdfs"							# cdfs image

#	declare       _PATH_VLNZ=""								# kernel
#	declare       _PATH_IRAM=""								# initramfs
	declare -r    _PATH_SPLS="/boot/grub/${_MENU_SPLS:?}"	# splash.png

	declare       _SECU_OPTN=""								# security option
	declare -r    _SECU_APPA="security=apparmor apparmor=1"
	declare -r    _SECU_SLNX="security=selinux selinux=1 enforcing=0"
