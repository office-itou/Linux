# --- main server tree diagram (developed for debian) ---------------------
#
#   [tree --charset C -n --filesfirst -d /srv/]
#
#   /srv/
#   |-- hgfs ------------------------------------------- vmware shared directory
#   |-- http
#   |   `-- html---------------------------------------- html contents
#   |       |-- index.html
#   |       |-- conf -> /srv/user/share/conf
#   |       |-- imgs -> /srv/user/share/imgs
#   |       |-- isos -> /srv/user/share/isos
#   |       |-- load -> /srv/user/share/load
#   |       `-- rmak -> /srv/user/share/rmak
#   |-- samba ------------------------------------------ samba shared directory
#   |   |-- cifs
#   |   |-- data
#   |   |   |-- adm
#   |   |   |   |-- netlogon
#   |   |   |   |   `-- logon.bat
#   |   |   |   `-- profiles
#   |   |   |-- arc
#   |   |   |-- bak
#   |   |   |-- pub
#   |   |   `-- usr
#   |   `-- dlna
#   |       |-- movies
#   |       |-- others
#   |       |-- photos
#   |       `-- sounds
#   |-- tftp ------------------------------------------- tftp contents
#   |   |-- autoexec.ipxe ------------------------------ ipxe script file (menu file)
#   |   |-- boot
#   |   |   `-- grub
#   |   |       |-- bootnetx64.efi --------------------- bootloader (x86_64-efi)
#   |   |       |-- grub.cfg --------------------------- menu base
#   |   |       |-- pxelinux.0 ------------------------- bootloader (i386-pc-pxe)
#   |   |       |-- fonts
#   |   |       |   `-- unicode.pf2
#   |   |       |-- i386-efi
#   |   |       |-- i386-pc
#   |   |       |-- locale
#   |   |       `-- x86_64-efi
#   |   |-- conf -> /srv/user/share/conf
#   |   |-- imgs -> /srv/user/share/imgs
#   |   |-- ipxe --------------------------------------- ipxe module
#   |   |   |-- ipxe.efi ------------------------------- "           for efi boot mode
#   |   |   |-- undionly.kpxe -------------------------- "           for mbr "
#   |   |   `-- wimboot -------------------------------- "           for windows media
#   |   |-- isos -> /srv/user/share/isos
#   |   |-- load -> /srv/user/share/load
#   |   |-- menu-bios
#   |   |   |-- lpxelinux.0 ---------------------------- bootloader (i386-pc)
#   |   |   |-- syslinux.cfg --------------------------- syslinux configuration for mbr environment
#   |   |   |-- conf -> ../conf
#   |   |   |-- imgs -> ../imgs
#   |   |   |-- isos -> ../isos
#   |   |   |-- load -> ../load
#   |   |   |-- pxelinux.cfg
#   |   |   |   `-- default -> ../syslinux.cfg
#   |   |   `-- rmak -> ../rmak
#   |   |-- menu-efi64
#   |   |   |-- syslinux.cfg --------------------------- syslinux configuration for uefi(x86_64) environment
#   |   |   |-- syslinux.efi --------------------------- bootloader (x86_64-efi)
#   |   |   |-- conf -> ../conf
#   |   |   |-- imgs -> ../imgs
#   |   |   |-- isos -> ../isos
#   |   |   |-- load -> ../load
#   |   |   |-- pxelinux.cfg
#   |   |   |   `-- default -> ../syslinux.cfg
#   |   |   `-- rmak -> ../rmak
#   |   `-- rmak -> /srv/user/share/rmak
#   `-- user ------------------------------------------- user file
#       |-- private ------------------------------------ personal use
#       `-- share -------------------------------------- shared
#           |-- chroot --------------------------------- change route directory
#           |   |-- debian12 --------------------------- "            debian 12    (some examples)
#           |   `-- ubuntu2504 ------------------------- "            ubuntu 25.04 ("            )
#           |-- conf ----------------------------------- configuration file
#           |   |-- _data ------------------------------ common data files
#           |   |   |-- common.cfg --------------------- configuration file of common
#           |   |   |-- common.cfg.template
#           |   |   |-- media.dat ---------------------- data file of media
#           |   |   `-- readme_tree_diagram.txt -------- this file
#           |   |-- _fixed_address
#           |   |   |-- autoinst.xml
#           |   |   |-- kickstart.cfg
#           |   |   |-- preseed.cfg
#           |   |   `-- user-data
#           |   |-- _keyring --------------------------- keyring file
#           |   |   |-- debian-keyring.gpg ------------- "            for debian (some examples)
#           |   |   `-- ubuntu-archive-keyring.gpg ----- "            for ubuntu ("            )
#           |   |-- _template -------------------------- templates for various configuration files
#           |   |   |-- kickstart_common.cfg ----------- template for auto-installation configuration file for rhel
#           |   |   |-- nocloud-ubuntu-user-data ------- "                                                 for ubuntu cloud-init
#           |   |   |-- preseed_debian.cfg ------------- "                                                 for debian
#           |   |   |-- preseed_ubuntu.cfg ------------- "                                                 for ubuntu
#           |   |   `-- yast_opensuse.xml -------------- "                                                 for opensuse
#           |   |-- autoinst --------------------------- script files for auto install
#           |   |   |-- cmd_early.sh ------------------- "            for early command
#           |   |   |-- cmd_late.sh -------------------- "            for late command
#           |   |   |-- cmd_partition.sh --------------- "            for early command after partman
#           |   |   `-- cmd_run.sh --------------------- "            for preseed/run
#           |   |-- autoyast --------------------------- configuration files for opensuse
#           |   |-- kickstart -------------------------- "                   for rhel
#           |   |-- nocloud ---------------------------- "                   for ubuntu cloud-init
#           |   |-- preseed ---------------------------- "                   for debian/ubuntu preseed
#           |   |-- script ----------------------------- script files
#           |   |   |-- late_command.sh ---------------- post-installation automatic configuration script file for linux (debian/ubuntu/rhel/opensuse)
#           |   |   `-- live_0000-user-conf-hook.sh ---- live media script files
#           |   `-- windows ---------------------------- configuration files for windows
#           |       |-- WinREexpand.cmd ---------------- hotfix for windows 10
#           |       |-- WinREexpand_bios.sub ----------- "
#           |       |-- WinREexpand_uefi.sub ----------- "
#           |       |-- bypass.cmd --------------------- installation restriction bypass command for windows 11
#           |       |-- inst_w10.cmd ------------------- installation batch file for windows 10
#           |       |-- inst_w11.cmd ------------------- "                       for windows 11
#           |       |-- shutdown.cmd ------------------- shutdown command for winpe
#           |       |-- startnet.cmd ------------------- startup command for winpe
#           |       |-- unattend.xml ------------------- auto-installation configuration file for windows 10/11
#           |       `-- winpeshl.ini
#           |-- imgs ----------------------------------- iso file extraction destination
#           |-- isos ----------------------------------- iso file
#           |-- load ----------------------------------- load module
#           `-- rmak ----------------------------------- remake file
#
#   /etc/
#   |-- fstab
#   |-- hostname
#   |-- hosts
#   |-- nsswitch.conf
#   |-- resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
#   |-- sudoers
#   |-- apache2
#   |   `-- sites-available
#   |       `-- 999-site.conf -------------------------- virtual host configuration file for users
#   |-- connman
#   |   `-- main.conf
#   |-- default
#   |   |-- dnsmasq
#   |   `-- grub
#   |-- dnsmasq.d
#   |   |-- default.conf ------------------------------- dnsmasq configuration file
#   |   `-- pxeboot.conf ------------------------------- pxeboot configuration file
#   |-- firewalld
#   |   `-- zones
#   |       `-- home_use.xml
#   |-- samba
#   |   `-- smb.conf ----------------------------------- samba configuration file
#   |-- skel
#   |   |-- .bash_history
#   |   |-- .bashrc
#   |   |-- .curlrc
#   |   `-- .vimrc
#   |-- ssh
#   |   `-- sshd_config.d
#   |       `-- default.conf --------------------------- ssh configuration file
#   `-- systemd
#       |-- resolved.conf.d
#       |   `-- default.conf
#       |-- system
#       |   `-- connman.service.d
#       |       `-- disable_dns_proxy.conf
#       `-- timesyncd.conf.d
#           `-- local.conf
#   
