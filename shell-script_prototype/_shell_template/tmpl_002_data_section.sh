	# --- shared directory parameter ------------------------------------------
	declare       _DIRS_TOPS=""			# top of shared directory
	declare       _DIRS_HGFS=""			# vmware shared
	declare       _DIRS_HTML=""			# html contents
	declare       _DIRS_SAMB=""			# samba shared
	declare       _DIRS_TFTP=""			# tftp contents
	declare       _DIRS_USER=""			# user file

	# --- shared of user file -------------------------------------------------
	declare       _DIRS_SHAR=""			# shared of user file
	declare       _DIRS_CONF=""			# configuration file
	declare       _DIRS_DATA=""			# data file
	declare       _DIRS_KEYS=""			# keyring file
	declare       _DIRS_TMPL=""			# templates for various configuration files
	declare       _DIRS_SHEL=""			# shell script file
	declare       _DIRS_IMGS=""			# iso file extraction destination
	declare       _DIRS_ISOS=""			# iso file
	declare       _DIRS_LOAD=""			# load module
	declare       _DIRS_RMAK=""			# remake file

	# --- common data file ----------------------------------------------------
	declare       _PATH_CONF=""			# common configuration file (thie file)
	declare       _PATH_MDIA=""			# media data file

	# --- pre-configuration file templates ------------------------------------
	declare       _CONF_KICK=""			# for rhel
	declare       _CONF_CLUD=""			# for ubuntu cloud-init
	declare       _CONF_SEDD=""			# for debian
	declare       _CONF_SEDU=""			# for ubuntu
	declare       _CONF_YAST=""			# for opensuse

	# --- shell script --------------------------------------------------------
	declare       _SHEL_ERLY=""			# shell commands to run early
	declare       _SHEL_LATE=""			# shell commands to run late
	declare       _SHEL_PART=""			# shell commands to run after partition
	declare       _SHEL_RUNS=""			# shell commands to run preseed/run

	# --- tftp / web server address -------------------------------------------
	declare       _SRVR_PROT=""			# server connection protocol (http or tftp)
	declare       _SRVR_ADDR=""			# tftp / web server address (empty to execution server address)
	declare       _IPV4_UADR=""			# IPv4 address up (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
	declare       _HOST_NAME=""			# hostname
	declare       _WGRP_NAME=""			# domain
	declare       _ETHR_NAME=""			# network device name
	declare       _IPV4_ADDR=""			# IPv4 address
	declare       _IPV4_CIDR=""			# IPv4 cidr (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK=""			# IPv4 subnetmask (empty to ipv4 cidr)
	declare       _IPV4_GWAY=""			# IPv4 gateway
	declare       _IPV4_NSVR=""			# IPv4 nameserver

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT=""			# timeout
	declare       _MENU_RESO=""			# resolution
	declare       _MENU_DPTH=""			# colors
	declare       _SCRN_MODE=""			# screen mode (vga=nnn)
