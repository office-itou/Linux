# **iPXE**  

## System configuration  
  
### DNS / DHCP Proxy / TFTP / WEB / Samba server  
  
| Item        | Detail                    |
| ----------- | ------------------------- |
| Interface   | ens160                    |
| IP address  | 192.168.1.12              |
| Netmask     | 24 (255.255.255.0)        |
| Router      | 192.168.1.254             |
| DNS server  | 192.168.1.1,192.168.1.254 |
| Domain name | workgroup                 |
  
## Tree diagram
  
```bash:
/var/lib/tftpboot/
|-- imgs ---------------------- iso file extraction destination
|-- isos ---------------------- iso file
|-- load ---------------------- load module
|-- ipxe ---------------------- iPXE module
|   |-- ipxe.efi
|   |-- undionly.kpxe
|   `-- wimboot
`-- autoexec.ipxe
```
  
```bash:/etc/dnsmasq.d/pxe.conf
# --- log ---------------------------------------------------------------------
#log-queries												# dns query log output
#log-dhcp													# dhcp transaction log output

# --- dns ---------------------------------------------------------------------
bogus-priv													# do not perform reverse lookup of private ip address on upstream server
domain-needed												# do not forward plain names
domain=workgroup											# local domain name
expand-hosts												# add domain name to host
filterwin2k													# filter for windows
interface=lo,ens160											# listen to interface
listen-address=::1,127.0.0.1,192.168.1.12					# listen to ip address
strict-order												# try in the registration order of /etc/resolv.conf
bind-dynamic												# enable bind-interfaces and the default hybrid network mode

# --- dhcp --------------------------------------------------------------------
dhcp-range=192.168.1.0,proxy,24								# proxy dhcp
dhcp-option=option:router,192.168.1.254						#  3 router
dhcp-option=option:dns-server,192.168.1.12,192.168.1.254	#  6 dns-server
dhcp-option=option:domain-name,workgroup					# 15 domain-name
dhcp-match=set:iPXE,175

# --- pxe boot ----------------------------------------------------------------
pxe-prompt="Press F8 for boot menu", 0						# pxe boot prompt
pxe-service=tag:iPXE ,x86PC     ,"PXEBoot-x86PC"     ,/autoexec.ipxe
pxe-service=tag:!iPXE,x86PC     ,"PXEBoot-x86PC"     ,ipxe/undionly.kpxe
pxe-service=tag:!iPXE,BC_EFI    ,"PXEBoot-BC_EFI"    ,ipxe/ipxe.efi
pxe-service=tag:!iPXE,x86-64_EFI,"PXEBoot-x86-64_EFI",ipxe/ipxe.efi

# --- eof ---------------------------------------------------------------------
```
  
## Download link  
  
| Application | URL                                                               |
| ----------- | ---------------------------------------------------------------- |
| iPXE        | https://boot.ipxe.org/ipxe.efi                                   |
| "           | https://boot.ipxe.org/undionly.kpxe                              |
| wimboot     | https://github.com/ipxe/wimboot/releases/latest/download/wimboot |
  
