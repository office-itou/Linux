# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make header and footer for ipxe menu in pxeboot
#   input :            : unused
#   output:   stdout   : output
#   return:            : unused
#   g-var :            : unused
function fnMk_pxeboot_ipxe_hdrftr() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
		#!ipxe

		# --- Define colour pair ------------------------------------------------------
		# Reset the default colour pair
		cpair 0 ||
		# Redefine the editable text pair as black on white
		cpair --foreground 7 --background 0 4 ||

		# --- Check x86 CPU feature ---------------------------------------------------
		# Check if CPU supports 64-bit operation ("long mode")
		cpuid --ext 29 && set arch x86_64 || set arch i386

		# --- Automatically configure interfaces --------------------------------------
		# Automatically configure the first available interface using DHCP
		ifconf --configurator dhcp ||
		# Automatically configure the first available interface using IPv6
		ifconf --configurator ipv6 ||

		# --- Set the IP address of the PXE boot server -------------------------------
		isset \${66} && set srvraddr \${66} || set srvraddr 192.168.1.11

		# --- Set the parameters. -----------------------------------------------------
		set srvrhttp http://\${srvraddr}
		set optn-timeout 1000
		set menu-timeout 0

		# --- Preventing multiple instances -------------------------------------------
		isset \${menu-default} || set menu-default exit

		# --- Start block -------------------------------------------------------------
		:start

		# --- Menu block --------------------------------------------------------------
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"    "--- first ----------------------------------------------------------------")
		$(printf "%-47s %s" "item --gap --"    "[ System command ]")
		$(printf "%-47s %s" "item -- shell"    "- iPXE shell")
		$(printf "%-47s %s" "item -- shutdown" "- System shutdown")
		$(printf "%-47s %s" "item -- restart"  "- System reboot")
		$(printf "%-47s %s" "item --gap --"    "--- last -----------------------------------------------------------------")
		choose --timeout \${menu-timeout} --default \${menu-default} selected || goto menu
		goto \${selected}

		# --- Interactive form block --------------------------------------------------

		:shell
		echo "Booting iPXE shell ..."
		shell
		goto start

		:shutdown
		echo "System shutting down ..."
		poweroff
		exit

		:restart
		echo "System rebooting ..."
		reboot
		exit

		:error
		prompt Press any key to continue
		exit

		:exit
		exit
_EOT_
}
