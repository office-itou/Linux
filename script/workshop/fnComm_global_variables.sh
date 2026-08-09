# shellcheck disable=SC2148

	# === for server environments =================================================

	# --- shared directory parameter ----------------------------------------------
	declare       _DIRS_TOPS="./_srv"						# top of shared directory
	declare       _DIRS_EXPO=":_DIRS_TOPS_:/exports"		# exports
	declare       _DIRS_HGFS=":_DIRS_TOPS_:/hgfs"			# vmware shared
	declare       _DIRS_HTML=":_DIRS_TOPS_:/http/html"		# html contents
	declare       _DIRS_SAMB=":_DIRS_TOPS_:/samba"			# samba shared
	declare       _DIRS_TFTP=":_DIRS_TOPS_:/tftp"			# tftp contents
	declare       _DIRS_USER=":_DIRS_TOPS_:/user"			# user file

	# --- shared of user file -----------------------------------------------------
	declare       _DIRS_PVAT=":_DIRS_USER_:/private"		# private contents directory
	declare       _DIRS_SHAR=":_DIRS_USER_:/share"			# shared of user file
	declare       _DIRS_CONF=":_DIRS_SHAR_:/conf"			# configuration file
	declare       _DIRS_DATA=":_DIRS_CONF_:/_data"			# data file
	declare       _DIRS_KEYS=":_DIRS_CONF_:/_keyring"		# keyring file
	declare       _DIRS_MKOS=":_DIRS_CONF_:/_mkosi"			# mkosi configuration files
	declare       _DIRS_TMPL=":_DIRS_CONF_:/_template"		# templates for various configuration files
	declare       _DIRS_SHEL=":_DIRS_CONF_:/script"			# shell script file
	declare       _DIRS_IMGS=":_DIRS_SHAR_:/imgs"			# iso file extraction destination
	declare       _DIRS_ISOS=":_DIRS_SHAR_:/isos"			# iso file
	declare       _DIRS_LOAD=":_DIRS_SHAR_:/load"			# load module
	declare       _DIRS_RMAK=":_DIRS_SHAR_:/rmak"			# remake file
	declare       _DIRS_CACH=":_DIRS_SHAR_:/cache"			# cache file
	declare       _DIRS_CTNR=":_DIRS_SHAR_:/containers"		# container file
	declare       _DIRS_CHRT=":_DIRS_SHAR_:/chroot"			# container file (chroot)
	declare       _DIRS_XNBD=":_DIRS_EXPO_:/nbd"			# exports (network block device)
	declare       _DIRS_XNFS=":_DIRS_EXPO_:/nfs"			# exports (network file system)
	declare       _DIRS_XSMB=":_DIRS_EXPO_:/smb"			# exports (samba)

	# --- common data file (prefer non-empty current file) ------------------------
	declare       _FILE_CONF="common.cfg"					# common configuration file
	declare       _FILE_DIST="distribution.dat"				# distribution data file
	declare       _FILE_MDIA="media.dat"					# media data file
	declare       _FILE_DSTP="debstrap.dat"					# debstrap data file
	declare       _PATH_CONF=":_DIRS_DATA_:/:_FILE_CONF_:"	# common configuration file
	declare       _PATH_DIST=":_DIRS_DATA_:/:_FILE_DIST_:"	# distribution data file
	declare       _PATH_MDIA=":_DIRS_DATA_:/:_FILE_MDIA_:"	# media data file
	declare       _PATH_DSTP=":_DIRS_DATA_:/:_FILE_DSTP_:"	# debstrap data file

	# --- pre-configuration file templates ----------------------------------------
	declare       _FILE_KICK="kickstart_rhel.cfg"			# for rhel
	declare       _FILE_CLUD="user-data_ubuntu"				# for ubuntu cloud-init
	declare       _FILE_SEDD="preseed_debian.cfg"			# for debian
	declare       _FILE_SEDU="preseed_ubuntu.cfg"			# for ubuntu
	declare       _FILE_YAST="yast_opensuse.xml"			# for opensuse
	declare       _FILE_AGMA="agama_opensuse.json"			# for opensuse
	declare       _PATH_KICK=":_DIRS_TMPL_:/:_FILE_KICK_:"	# for rhel
	declare       _PATH_CLUD=":_DIRS_TMPL_:/:_FILE_CLUD_:"	# for ubuntu cloud-init
	declare       _PATH_SEDD=":_DIRS_TMPL_:/:_FILE_SEDD_:"	# for debian
	declare       _PATH_SEDU=":_DIRS_TMPL_:/:_FILE_SEDU_:"	# for ubuntu
	declare       _PATH_YAST=":_DIRS_TMPL_:/:_FILE_YAST_:"	# for opensuse
	declare       _PATH_AGMA=":_DIRS_TMPL_:/:_FILE_AGMA_:"	# for opensuse

	# --- shell script ------------------------------------------------------------
	declare       _FILE_ERLY="autoinst_cmd_early.sh"		# shell commands to run early
	declare       _FILE_LATE="autoinst_cmd_late.sh"			# "              to run late
	declare       _FILE_PART="autoinst_cmd_part.sh"			# "              to run after partition
	declare       _FILE_RUNS="autoinst_cmd_run.sh"			# "              to run preseed/run
	declare       _PATH_ERLY=":_DIRS_SHEL_:/:_FILE_ERLY_:"	# shell commands to run early
	declare       _PATH_LATE=":_DIRS_SHEL_:/:_FILE_LATE_:"	# "              to run late
	declare       _PATH_PART=":_DIRS_SHEL_:/:_FILE_PART_:"	# "              to run after partition
	declare       _PATH_RUNS=":_DIRS_SHEL_:/:_FILE_RUNS_:"	# "              to run preseed/run

	# --- tftp menu ---------------------------------------------------------------
	declare       _FILE_IPXE="ipxe/autoexec.ipxe"			# ipxe
	declare       _FILE_GRUB="boot/grub/grub.cfg"			# grub
	declare       _FILE_SLNX="menu-bios/syslinux.cfg"		# syslinux (bios)
	declare       _FILE_EF64="menu-efi64/syslinux.cfg"		# syslinux (efi64)
	declare       _PATH_IPXE=":_DIRS_TFTP_:/:_FILE_IPXE_:"	# ipxe
	declare       _PATH_GRUB=":_DIRS_TFTP_:/:_FILE_GRUB_:"	# grub
	declare       _PATH_SLNX=":_DIRS_TFTP_:/:_FILE_SLNX_:"	# syslinux (bios)
	declare       _PATH_EF64=":_DIRS_TFTP_:/:_FILE_EF64_:"	# syslinux (efi64)

	# --- tftp / nbd --------------------------------------------------------------
	declare       _FILE_NBDS="exports.conf"					# nbd exports
	declare       _DIRS_NBDS="/etc/nbd-server/conf.d"		# nbd exports
	declare       _PATH_NBDS=":_DIRS_TFTP_:/:_FILE_NBDS_:"	# nbd exports

	# --- tftp / web server network parameter -------------------------------------
	declare       _SRVR_HTTP="http"							# server connection protocol (http or https)
	declare       _SRVR_PROT="http"							# server connection protocol (http or tftp)
	declare       _SRVR_NICS="ens160"						# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
	declare       _SRVR_MADR="00:00:00:00:00:00"			#                mac    (ex. 00:00:00:00:00:00)
	declare       _SRVR_ADDR="192.168.1.11"					# IPv4 address          (ex. 192.168.1.11)
	declare       _SRVR_CIDR="24"							# IPv4 cidr             (ex. 24)
	declare       _SRVR_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0)
	declare       _SRVR_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _SRVR_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _SRVR_UADR="192.168.1"					# IPv4 address up       (ex. 192.168.1)

	# === for creations ===========================================================

	# --- network parameter -------------------------------------------------------
	declare       _NWRK_HOST="sv-:_DISTRO_:"				# hostname              (ex. sv-server)
	declare       _NWRK_WGRP="workgroup"					# domain                (ex. workgroup)
	declare       _NICS_NAME="ens160"						# network device name   (ex. ens160)
	declare       _NICS_MADR=""								#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR="192.168.1.1"					# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR="24"							# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK="255.255.255.0"				# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY="192.168.1.254"				# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR="192.168.1.254"				# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _IPV4_UADR=""								# IPv4 address up       (ex. 192.168.1)
	declare       _NMAN_NAME=""								# network manager name  (nm_config, ifupdown, loopback)
	declare       _NTPS_ADDR="ntp.nict.jp"					# ntp server address    (ntp.nict.jp)
	declare       _NTPS_IPV4="61.205.120.130"				# ntp server ipv4 addr  (61.205.120.130)

	# --- menu parameter ----------------------------------------------------------
	declare       _MENU_TOUT="5"							# timeout (sec)
	declare       _MENU_RESO="800x600"						# resolution (widht x hight)
	declare       _MENU_DPTH="16"							# colors
	declare       _MENU_MODE="788"							# screen mode (vga=nnn)
	declare       _MENU_SPLS="splash.png"					# splash file
#	declare       _MENU_RESO="854x480"						# resolution (widht x hight): 16:9
#	declare       _MENU_RESO="854x480"						# "                         : 16:9 (for vmware)
#	declare       _MENU_RESO="854x480"						# "                         :  4:3
#	declare       _MENU_DPTH="16"							# colors
#	declare       _MENU_MODE="864"							# screen mode (vga=nnn)

	# --- auto install --------------------------------------------------------
	declare       _AUTO_INST="autoinst.cfg"					# autoinstall configuration file
	declare       _MINI_IRAM="initps.gz"					# initial ram disk of mini.iso including preseed

	# === for mkosi ===============================================================

	# --- mkosi output image format type ------------------------------------------
#	declare       _MKOS_BOOT="yes"							# --bootable= (yes, no)
	declare       _MKOS_OUTP="root_img"						# --output=
	declare       _MKOS_FMAT="directory"					# --format= (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none)
#	declare       _MKOS_NWRK="yes"							# --with-network= (yes, no)
	declare       _MKOS_RECM="yes"							# --with-recommends (yes, no)
#	declare       _MKOS_DIST=""								# --distribution= (fedora, debian, kali, ubuntu, arch, opensuse, mageia, centos, rhel, rhel-ubi, openmandriva, rocky, alma, azure, custom)
#	declare       _MKOS_VERS=""								# --release=
	declare       _MKOS_ARCH="x86-64"						# --architecture= (alpha, arc, arm, arm64, ia64, loongarch64, mips64-le, mips-le, parisc, ppc, ppc64, ppc64-le, riscv32, riscv64, s390, s390x, tilegx, x86, x86-64)

	# --- live media parameter ----------------------------------------------------
	declare       _FILE_RTIM=":_MKOS_OUTP_:.raw"			# root image
	declare       _FILE_SQFS="squashfs.img"					# squashfs / filesystem.squashfs
	declare       _FILE_MBRF="bios.img"						# mbr image
	declare       _FILE_UEFI="uefi.img"						# uefi image
	declare       _FILE_BCAT="boot.cat"						# eltorito catalog
#	declare       _FILE_ETRI=""								# 
#	declare       _FILE_BIOS=""								# 
	declare       _FILE_ICFG="isolinux.cfg"					# isolinux.cfg
	declare       _FILE_GCFG="grub.cfg"						# grub.cfg
	declare       _FILE_MENU="menu.cfg"						# menu.cfg
	declare       _FILE_THME="theme.cfg"					# theme.cfg
	declare       _DIRS_LIVE="LiveOS"						# LiveOS / live
	declare       _DIRS_MNTP="mntp"							# mount point
	declare       _DIRS_RTFS="rtfs"							# root image
	declare       _DIRS_CDFS="cdfs"							# cdfs image
	declare       _PATH_VLNZ=""								# kernel
	declare       _PATH_IRAM=""								# initramfs
	declare       _PATH_SPLS="/boot/grub/:_MENU_SPLS_:"		# splash.png
	declare       _SECU_OPTN=""								# security option
	declare       _SECU_APPA="security=apparmor apparmor=1"
	declare       _SECU_SLNX="security=selinux selinux=1 enforcing=0"
