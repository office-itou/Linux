# shellcheck disable=SC2148

	# --- mkosi command line parameter ----------------------------------------
	declare       _MKOS_BOOT=""			# --bootable=
	declare       _MKOS_OUTP=""			# --output=
	declare       _MKOS_FMAT=""			# --format=
	declare       _MKOS_NWRK=""			# --with-network=
	declare       _MKOS_RECM=""			# --with-recommends
	declare       _MKOS_DIST=""			# --distribution=
	declare       _MKOS_VERS=""			# --release=
	declare       _MKOS_ARCH=""			# --architecture=

	# --- live files ----------------------------------------------------------
	declare       _FILE_RTIM=""			# root image
	declare       _FILE_SQFS=""			# squashfs
	declare       _FILE_MBRF=""			# mbr image
	declare       _FILE_UEFI=""			# uefi image
	declare       _FILE_BCAT=""			# eltorito catalog
	declare       _FILE_ETRI=""			# 
	declare       _FILE_BIOS=""			# 

	declare       _FILE_ICFG=""			# isolinux.cfg
	declare       _FILE_GCFG=""			# grub.cfg
	declare       _FILE_MENU=""			# menu.cfg
	declare       _FILE_THME=""			# theme.cfg

	declare       _DIRS_LIVE=""			# live directory
	declare       _DIRS_MNTP=""			# mount point
	declare       _DIRS_RTFS=""			# root image
	declare       _DIRS_CDFS=""			# cdfs image

	declare       _PATH_VLNZ=""			# kernel
	declare       _PATH_IRAM=""			# initramfs
	declare       _PATH_SPLS=""			# splash.png

	declare       _SECU_OPTN=""			# security option
	declare       _SECU_APPA=""			# " (apparmor)
	declare       _SECU_SLNX=""			# " (selinux)
