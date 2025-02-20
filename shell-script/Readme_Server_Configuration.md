# **Server Configuration**  
  
## System configuration  
  
### Software  
  
| Intended use      | Module         | Detail                           |
| ----------------- | -------------- | -------------------------------- |
| Host PC           | Windows        | Windows 10 Pro 22H2              |
|                   | Virtual system | VMware Workstation 16 Pro        |
| Guest PC (Server) | Linux          | Debian 12 (stable)               |
|                   | DNS/DHCP       | dnsmasq 2.89                     |
|                   | TFTP           | tftpd-hpa 5.2                    |
|                   | HTTP           | apache2 2.4.59                   |
|                   | SMB/CIFS       | samba 4.17.12                    |
|                   | iPXE           | undionly.kpxe 3.70 or newer      |
|                   |                | ipxe.efi                         |
|                   |                | wimboot 2.8.0                    |
  
### Hardware  
  
| Intended use      | Module         | Detail                           |
| ----------------- | -------------- | -------------------------------- |
| Host PC           | Processor      | Intel Core i7-6700 CPU @ 3.40GHz |
|                   | Memory         | 32GiB                            |
|                   | Storage        |                                  |
|                   | Network        |                                  |
| Guest PC (Client) | Processor      | 1 processor / 2 cores (i7-6700)  |
|                   | Memory         | 4GiB (Live mode is 8GiB)         |
|                   | Storage        | NVMe 64 GiB / SATA -             |
|                   | Network        | NIC1 e1000e / NIC2 -             |
| Guest PC (Server) | Processor      | 1 processor / 2 cores (i7-6700)  |
|                   | Memory         | 4GiB                             |
|                   | Storage        | NVMe 500 GiB / SATA -            |
|                   | Network        | NIC1 e1000e / NIC2 -             |
| Guest PC (Server) | Processor      | 1 processor / 2 cores (i7-6700)  |
| Application Test  | Memory         | 4GiB                             |
|                   | Storage        | NVMe 64 GiB / SATA -             |
|                   | Network        | NIC1 e1000e / NIC2 -             |
  
### Network  
  
| Intended use      | Item           | Detail                           |
| ----------------- | -------------- | -------------------------------- |
| Guest PC (Server) | Interface      | ens160                           |
|                   | IP address     | 192.168.1.12                     |
|                   | Netmask        | 24 (255.255.255.0)               |
|                   | Router         | 192.168.1.254                    |
|                   | DNS server     | 192.168.1.12,192.168.1.254       |
|                   | Domain name    | workgroup                        |
| Guest PC (Server) | Interface      | ens160                           |
| Application Test  | IP address     | 192.168.1.12                     |
|                   | Netmask        | 24 (255.255.255.0)               |
|                   | Router         | 192.168.1.254                    |
|                   | DNS server     | 192.168.1.12,192.168.1.254       |
|                   | Domain name    | workgroup                        |
  
Note:  
* Test Applications: DNS / DHCP Proxy / TFTP / WEB / Samba  
  
### Storage  
  
Required working space:
20GiB+(iso files×3)
  
* Estimated work area size
  
| Item | Size   |
| ---- | -----: |
| Min  |  20GiB |
| Max  | 600GiB |
  
* Estimated maximum size by directory
  
| Dir  | Size   | Intended use                      |
| ---- | -----: | --------------------------------- |
| back |   1GiB | backup directory                  |
| bldr |   1GiB | custom boot loader                |
| chrt |   1GiB | change root directory             |
| conf |   1GiB | configuration file                |
| html |   1GiB | html contents                     |
| imgs | 200GiB | iso file extraction destination   |
| isos | 200GiB | iso file                          |
| keys |   1GiB | keyring file                      |
| live |  20GiB | live media file                   |
| orig |   1GiB | backup directory (original file)  |
| pkgs |   --   | package file's directory          |
| rmak | 200GiB | remake file                       |
| temp |   1GiB | temporary directory               |
| tftp |  10GiB | tftp contents                     |
  
## Tree diagram (developed for debian)
  
``` bash:
tree --charset C -n --filesfirst -d share/
```
  
### ${HOME}/share/ 
  
``` bash:
${HOME}/share/
|-- back ------------------------------------------ backup directory
|-- bldr ------------------------------------------ custom boot loader
|-- conf ------------------------------------------ configuration file
|   |-- _template
|   |   |-- initrd_debian.yaml
|   |   |-- initrd_ubuntu.yaml
|   |   |-- kickstart_common.cfg
|   |   |-- live_debian.yaml
|   |   |-- live_ubuntu.yaml
|   |   |-- nocloud-ubuntu-user-data
|   |   |-- preseed_debian.cfg
|   |   |-- preseed_ubuntu.cfg
|   |   `-- yast_opensuse.xml
|   |-- autoyast
|   |-- kickstart
|   |-- nocloud
|   |-- preseed
|   |-- script
|   |   |-- late_command.sh
|   |   `-- live_0000-user-conf-hook.sh
|   `-- windows
|       |-- bypass.cmd
|       |-- inst_w10.cmd
|       |-- inst_w11.cmd
|       |-- shutdown.cmd
|       |-- startnet.cmd
|       |-- unattend.xml
|       `-- winpeshl.ini
|-- html <- /var/www/html ------------------------- html contents
|   |-- memdisk
|   |-- conf -> ../conf
|   |-- imgs -> ../imgs
|   |-- isos -> ../isos
|   |-- load -> ../tftp/load
|   `-- rmak -> ../rmak
|-- imgs ------------------------------------------ iso file extraction destination
|-- isos ------------------------------------------ iso file
|-- keys ------------------------------------------ keyring file
|-- live ------------------------------------------ live media file
|-- orig ------------------------------------------ backup directory (original file)
|-- pkgs ------------------------------------------ package file's directory
|   |-- debian
|   `-- ubuntu
|-- rmak ------------------------------------------ remake file
|-- temp ------------------------------------------ temporary directory
`-- tftp <- /var/lib/tftpboot --------------------- tftp contents
    |-- autoexec.ipxe ----------------------------- ipxe script file (menu file)
    |-- memdisk ----------------------------------- memdisk of syslinux
    |-- boot
    |   `-- grub
    |       |-- bootx64.efi ----------------------- bootloader (i386-pc-pxe)
    |       |-- grub.cfg -------------------------- menu base
    |       |-- menu.cfg -------------------------- menu file
    |       |-- pxelinux.0 ------------------------ bootloader (x86_64-efi)
    |       |-- fonts
    |       |   `-- unicode.pf2
    |       |-- i386-efi
    |       |-- i386-pc
    |       |-- locale
    |       `-- x86_64-efi
    |-- imgs -> ../imgs
    |-- ipxe -------------------------------------- ipxe module
    |   |-- ipxe.efi
    |   |-- undionly.kpxe
    |   `-- wimboot
    |-- isos -> ../isos
    |-- load -------------------------------------- load module
    |-- menu-bios
    |   |-- syslinux.cfg -------------------------- syslinux configuration for mbr environment
    |   |-- imgs -> ../../imgs
    |   |-- isos -> ../../isos
    |   |-- load -> ../load
    |   `-- pxelinux.cfg
    |       `-- default -> ../syslinux.cfg
    `-- menu-efi64
        |-- syslinux.cfg -------------------------- syslinux configuration for uefi(x86_64) environment
        |-- imgs -> ../../imgs
        |-- isos -> ../../isos
        |-- load -> ../load
        `-- pxelinux.cfg
            `-- default -> ../syslinux.cfg
```
  
### /var/lib/tftpboot/ 
  
``` bash:
/var/lib/tftpboot/
`-- tftpboot -> ${HOME}/share/tftp
```
  
### /var/www/ 
  
``` bash:
/var/www/
`-- html -> ${HOME}/share/html
```
  
### /etc/dnsmasq.d/ 
  
``` bash:
/etc/dnsmasq.d/
`-- pxe.conf -------------------------------------- pxeboot dnsmasq configuration file
```
  
### ${HOME}/share_chrt/ 
  
``` bash:
${HOME}/share_chrt/
|-- mnt
|   `-- hgfs
`-- srv
    `-- user
        |-- install.sh ---------------------------- initial configuration shell
        |-- mk_custom_iso.sh ---------------------- custom iso image creation shell
        |-- mk_pxeboot_conf.sh -------------------- pxeboot configuration shell
        |-- mk_live_media.sh ---------------------- custom live iso image creation shell
        `-- share <- ${HOME}/share
```
  
## Reference  
  
| Application | URL                                                |
| ----------- | -------------------------------------------------- |
| Markdown    | https://qiita.com/Qiita/items/c686397e4a0f4f11683d |
| Dnsmasq     | https://man.archlinux.org/man/dnsmasq.8            |
| iPXE(WinPE) | https://ipxe.org/howto/winpe                       |
  
