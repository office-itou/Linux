#!/usr/bin/env python3

# --- python library ----------------------------------------------------------
from ipaddress import IPv4Interface


ipv4_addr="192.168.1.2"
ipv4_prfx="24"
ipv4_mask="255.255.0.0"

_interface = IPv4Interface(f"{ipv4_addr}/{ipv4_prfx}")
print(_interface.ip)
print(_interface.netmask)
print(_interface.network.prefixlen)

_interface = IPv4Interface(f"{ipv4_addr}/{ipv4_mask}")
print(_interface.ip)
print(_interface.netmask)
print(_interface.network.prefixlen)
