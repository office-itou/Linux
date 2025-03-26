#!/bin/bash

	case "${1:-}" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
#	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
#	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
#	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	mkdir -p "${DIRS_CONF}/_fixed_address"

	# --- preseed -------------------------------------------------------------
	sed -e '\%debian-installer/locale[ \t]\+string%              s/^#./  /' \
	    -e '\%debian-installer/language[ \t]\+string%            s/^#./  /' \
	    -e '\%debian-installer/country[ \t]\+string%             s/^#./  /' \
	    -e '\%localechooser/supported-locales[ \t]\+multiselect% s/^#./  /' \
	    -e '\%keyboard-configuration/xkb-keymap[ \t]\+select%    s/^#./  /' \
	    -e '\%keyboard-configuration/toggle[ \t]\+select%        s/^#./  /' \
	    -e '\%netcfg/enable[ \t]\+boolean%                       s/^#./  /' \
	    -e '\%netcfg/disable_autoconfig[ \t]\+boolean%           s/^#./  /' \
	    -e '\%netcfg/dhcp_options[ \t]\+select%                  s/^#./  /' \
	    -e '\%IPv4 example%,\%IPv6 example% {                             ' \
	    -e '\%netcfg/get_ipaddress[ \t]\+string%                 s/^#./  /' \
	    -e '\%netcfg/get_netmask[ \t]\+string%                   s/^#./  /' \
	    -e '\%netcfg/get_gateway[ \t]\+string%                   s/^#./  /' \
	    -e '\%netcfg/get_nameservers[ \t]\+string%               s/^#./  /' \
	    -e '\%netcfg/confirm_static[ \t]\+boolean%               s/^#./  /' \
	    -e '}'                                                              \
	    -e '\%netcfg/get_hostname[ \t]\+string%                  s/^#./  /' \
	    -e '\%netcfg/get_domain[ \t]\+string%                    s/^#./  /' \
	    -e '\%apt-setup/services-select[ \t]\+multiselect%       s/^#./  /' \
	    -e '\%preseed/run[ \t]\+string%,\%[^\\]$%                s/^#./  /' \
	    "${DIRS_CONF}/preseed/ps_debian_server.cfg"                         \
	>   "${DIRS_CONF}/_fixed_address/preseed.cfg"

	# --- cloud-init ----------------------------------------------------------
	sed -e '/^#[ \t]\+[-=]\+[ \t]\+ipv4:[ \t]\+static[ \t]\+[-=]\+$/,/^\# [-=]\+\(\|[ \t]\+ipv4:[ \t]\+.*\)[-=]\+\(\|.*\)$/{' \
	    -e '/^\# [-=]\+\(\|[ \t]\+ipv4:[ \t]\+.*\)[-=]\+\(\|.*\)$/! s/^#/ /g}' \
	    "${DIRS_CONF}/nocloud/ubuntu_server/user-data" \
	>   "${DIRS_CONF}/_fixed_address/user-data"

	# --- kickstart -----------------------------------------------------------
	sed -e '/Network information/,/^$/ {' \
	    -e '/network/ s/^#//           }' \
	    "${DIRS_CONF}/kickstart/ks_almalinux-9_net.cfg" \
	>   "${DIRS_CONF}/_fixed_address/kickstart.cfg"

	# --- autoyast ------------------------------------------------------------
	sed -e '\%<networking .*>%,\%</networking>% { ' \
	    -e '/<!-- fixed address$/ s/$/ -->/g      ' \
	    -e '/^fixed address -->/  s/^/<!-- /g   } ' \
	    "${DIRS_CONF}/autoyast/autoinst_leap-15.6_net.xml" \
	>   "${DIRS_CONF}/_fixed_address/autoinst.xml"

	# --- shell ---------------------------------------------------------------
	cp -a "${DIRS_CONF}/preseed/preseed_kill_dhcp.sh"         "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/preseed/preseed_late_command.sh"      "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/nocloud/nocloud_late_command.sh"      "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/nocloud/ubuntu_server/meta-data"      "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/nocloud/ubuntu_server/network-config" "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/nocloud/ubuntu_server/vendor-data"    "${DIRS_CONF}/_fixed_address/"
	cp -a "${DIRS_CONF}/script/late_command.sh"               "${DIRS_CONF}/_fixed_address/"

	exit 0
