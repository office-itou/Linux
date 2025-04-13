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
	declare       _PATH_CONF=""			# common configuration file
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

# --- tftp / web server network parameter -------------------------------------
	declare       _SRVR_PROT="http"		# server connection protocol (http or tftp)
	declare       _SRVR_NICS=""			# network device name   (ex. ens160)            (Set execution server setting to empty variable.)
	declare       _SRVR_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
	declare       _SRVR_ADDR=""			# IPv4 address          (ex. 192.168.1.11)
	declare       _SRVR_CIDR=""			# IPv4 cidr             (ex. 24)
	declare       _SRVR_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0)
	declare       _SRVR_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
	declare       _SRVR_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
	declare       _SRVR_UADR=""			# IPv4 address up       (ex. 192.168.1)

	# --- network parameter ---------------------------------------------------
	declare       _NWRK_HOST=""			# hostname              (ex. sv-server)
	declare       _NWRK_WGRP=""			# domain                (ex. workgroup)
	declare       _NICS_NAME=""			# network device name   (ex. ens160)
	declare       _NICS_MADR=""			#                mac    (ex. 00:00:00:00:00:00)
	declare       _IPV4_ADDR=""			# IPv4 address          (ex. 192.168.1.1)   (empty to dhcp)
	declare       _IPV4_CIDR=""			# IPv4 cidr             (ex. 24)            (empty to ipv4 subnetmask, if both to 24)
	declare       _IPV4_MASK=""			# IPv4 subnetmask       (ex. 255.255.255.0) (empty to ipv4 cidr)
	declare       _IPV4_GWAY=""			# IPv4 gateway          (ex. 192.168.1.254)
	declare       _IPV4_NSVR=""			# IPv4 nameserver       (ex. 192.168.1.254)
#	declare       _IPV4_UADR=""			# IPv4 address up       (ex. 192.168.1)
#	declare       _NMAN_NAME=""			# network manager name  (nm_config, ifupdown, loopback)

	# --- menu parameter ------------------------------------------------------
	declare       _MENU_TOUT=""			# timeout
	declare       _MENU_RESO=""			# resolution
	declare       _MENU_DPTH=""			# colors
	declare       _MENU_MODE=""			# screen mode (vga=nnn)
