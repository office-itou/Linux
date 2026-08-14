filename = "autoexec.ipxe"
script = r"""#!ipxe

# --- Configure graphical console ---------------------------------------------

console --x 1024 --y 768 ||
# --- Define colour pair ------------------------------------------------------
# Reset the default colour pair
cpair 0 ||
# Redefine the editable text pair as black on white
cpair --foreground 7 --background 0 4 ||

# --- Check x86 CPU feature ---------------------------------------------------
# Check if CPU supports 64-bit operation ("long mode")
clear arch
cpuid --ext 29 && set arch x86_64 || set arch i386

# --- Automatically configure interfaces --------------------------------------
# Automatically configure the first available interface using DHCP
ifconf --configurator dhcp ||
# Automatically configure the first available interface using IPv6
ifconf --configurator ipv6 ||

# --- Set the IP address of the PXE boot server -------------------------------
clear srvraddr
isset ${66} && set srvraddr ${66} || set srvraddr :_SRVR_ADDR_:

# --- Set the parameters. -----------------------------------------------------
set srvrhttp http://${srvraddr}
set ipxebase ${srvrhttp}/tftp/ipxe
set optn-timeout 1000
set menu-timeout 0
set esc:hex 1b

# --- Preventing multiple instances -------------------------------------------
isset ${menu-default} || set menu-default exit

# --- chain -------------------------------------------------------------------
chain ${ipxebase}/menu/menu.ipxe

"""
