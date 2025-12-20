# **main server tree diagram (developed for debian)**

* ## **tree**

  ``` bash:
  tree --charset C -n --filesfirst -d /srv/
  ```

* ## **/boot/**

  ``` bash:
  /boot/
  `-- grub
      `-- grub.cfg
  ```

* ## **/etc/**

  ``` bash:
  /etc/
  |-- fstab
  |-- hostname
  |-- hosts
  |-- nsswitch.conf
  |-- resolv.conf -> ../run/systemd/resolve/stub-resolv.conf
  |-- sudoers
  |-- apache2
  |   `-- sites-available
  |       `-- 999-site.conf ------------ virtual host configuration file for users
  |-- apt
  |   |-- sources.list
  |   `-- sources.list.d
  |       `-- pgdg.list
  |-- connman
  |   `-- main.conf
  |-- default
  |   |-- dnsmasq
  |   `-- grub
  |-- dnsmasq.d
  |   |-- default.conf ----------------- dnsmasq configuration file
  |   `-- pxeboot.conf ----------------- pxeboot configuration file
  |-- firewalld
  |   `-- zones
  |       `-- home_use.xml
  |-- postgresql ----------------------- postgresql
  |   `-- 18
  |       `-- main
  |           |-- pg_hba.conf     ------ client authentication configuration file
  |           `-- postgresql.conf ------ postgresql configuration file
  |-- samba
  |   `-- smb.conf --------------------- samba configuration file
  |-- skel
  |   |-- .bash_history
  |   |-- .bashrc
  |   |-- .curlrc
  |   `-- .vimrc
  |-- ssh
  |   `-- sshd_config.d
  |       `-- default.conf ------------- ssh configuration file
  `-- systemd
      |-- resolved.conf.d
      |   `-- default.conf
      |-- system
      |   `-- connman.service.d
      |       `-- disable_dns_proxy.conf
      `-- timesyncd.conf.d
          `-- local.conf
  ```

* ## **/home/**

  ``` bash:
  /home/
  `-- master
      |-- .bash_history
      |-- .bashrc
      |-- .curlrc
      |-- .pgpass
      |-- .vimrc
      `-- .workdirs
  ```

* ## **/lib/**

  ``` bash:
  /lib/
  `-- systemd
      `-- system
          |-- dnsmasq.service
          `-- firewalld.service
  ```

* ## **/root/**

  ``` bash:
  /root/
  |-- .bash_history
  |-- .bashrc
  |-- .curlrc
  |-- .pgpass
  `-- .vimrc
  ```

* ## **/run/**

  ``` bash:
  /run/
  `-- systemd
      `-- resolve
          `-- stub-resolv.conf
  ```

* ## **/srv/**

  ``` bash:
  /srv/
  |-- hgfs ----------------------------- vmware shared directory
  |-- http
  |   `-- html ------------------------- html contents
  |       |-- index.html
  |       |-- conf -> /srv/user/share/conf
  |       |-- imgs -> /srv/user/share/imgs
  |       |-- isos -> /srv/user/share/isos
  |       |-- load -> /srv/user/share/load
  |       |-- rmak -> /srv/user/share/rmak
  |       `-- tftp -> /srv/tftp
  |-- samba ---------------------------- samba shared directory
  |   |-- adm
  |   |   |-- commands
  |   |   `-- profiles
  |   |-- pub
  |   |   |-- _license
  |   |   |-- contents
  |   |   |   |-- disc
  |   |   |   `-- dlna
  |   |   |       |-- movies
  |   |   |       |-- others
  |   |   |       |-- photos
  |   |   |       `-- sounds
  |   |   |-- hardware
  |   |   |-- resource
  |   |   |   |-- image ---------------- image file
  |   |   |   |   |-- creations
  |   |   |   |   |   `-- rmak --------- remake file
  |   |   |   |   |-- linux
  |   |   |   |   |   |-- almalinux
  |   |   |   |   |   |-- centos
  |   |   |   |   |   |-- debian
  |   |   |   |   |   |-- fedora
  |   |   |   |   |   |-- memtest86plus
  |   |   |   |   |   |-- miraclelinux
  |   |   |   |   |   |-- opensuse
  |   |   |   |   |   |-- rockylinux
  |   |   |   |   |   `-- ubuntu
  |   |   |   |   `-- windows
  |   |   |   |       |-- aomei
  |   |   |   |       |-- ati
  |   |   |   |       |-- windows-10
  |   |   |   |       |-- windows-11
  |   |   |   |       `-- winpe
  |   |   |   `-- source
  |   |   |       `-- git
  |   |   `-- software
  |   `-- usr
  |       `-- administrator
  |           |-- .bash_history
  |           |-- .bash_logout
  |           |-- .bashrc
  |           |-- .curlrc
  |           |-- .profile
  |           |-- .vimrc
  |           |-- app
  |           |-- dat
  |           `-- web
  |               `-- public_html
  |                   `-- index.html
  |-- tftp ----------------------------- tftp contents
  |   |-- autoexec.ipxe ---------------- ipxe script file (menu file)
  |   |-- boot
  |   |   `-- grub
  |   |       |-- bootx64.efi ---------- bootloader (x86_64-efi)
  |   |       |-- grub.cfg ------------- menu base
  |   |       |-- pxegrub.0 ------------ bootloader (i386-pc-pxe)
  |   |       |-- fonts
  |   |       |-- i386-efi
  |   |       |-- i386-pc
  |   |       |-- locale
  |   |       `-- x86_64-efi
  |   |-- conf -> /srv/user/share/conf
  |   |-- imgs -> /srv/user/share/imgs
  |   |-- ipxe ------------------------- ipxe module
  |   |   |-- ipxe.efi --------------------- for efi boot mode
  |   |   |-- undionly.kpxe ---------------- for mbr boot mode
  |   |   `-- wimboot ---------------------- for windows media
  |   |-- isos -> /srv/user/share/isos
  |   |-- load -> /srv/user/share/load
  |   |-- menu-bios
  |   |   |-- lpxelinux.0 -------------- bootloader (i386-pc)
  |   |   |-- syslinux.cfg ------------- syslinux configuration for mbr environment
  |   |   |-- conf -> ../conf
  |   |   |-- imgs -> ../imgs
  |   |   |-- isos -> ../isos
  |   |   |-- load -> ../load
  |   |   |-- pxelinux.cfg
  |   |   |   `-- default -> ../syslinux.cfg
  |   |   `-- rmak -> ../rmak
  |   |-- menu-efi64
  |   |   |-- syslinux.cfg ------------- syslinux configuration for uefi(x86_64) environment
  |   |   |-- syslinux.efi ------------- bootloader (x86_64-efi)
  |   |   |-- conf -> ../conf
  |   |   |-- imgs -> ../imgs
  |   |   |-- isos -> ../isos
  |   |   |-- load -> ../load
  |   |   |-- pxelinux.cfg
  |   |   |   `-- default -> ../syslinux.cfg
  |   |   `-- rmak -> ../rmak
  |   `-- rmak -> /srv/user/share/rmak
  `-- user ----------------------------- user file
      |-- private ---------------------- personal use
      `-- share ------------------------ shared
          |-- cache
          |-- chroot ------------------- change route directory
          |-- conf ------------------------- configuration file
          |   |-- _data ------------------------ common data files
          |   |   |-- common.cfg ------------------- configuration file of common
          |   |   |-- distribution.dat ------------- data file of distribution
          |   |   `-- media.dat -------------------- data file of media
          |   |-- _keyring
          |   |-- _mkosi
          |   |   |-- mkosi.build.d
          |   |   |-- mkosi.clean.d
          |   |   |-- mkosi.conf.d
          |   |   |-- mkosi.extra
          |   |   |-- mkosi.finalize.d
          |   |   |-- mkosi.postinst.d
          |   |   |-- mkosi.postoutput.d
          |   |   |-- mkosi.prepare.d
          |   |   |-- mkosi.repart
          |   |   `-- mkosi.sync.d
          |   |-- _repository
          |   |   `-- opensuse
          |   |-- _template -------------------- templates for various configuration files
          |   |   |-- agama_opensuse.json ---------- for opensuse agama installer
          |   |   |-- kickstart_rhel.cfg ----------- for rhel
          |   |   |-- preseed_debian.cfg ----------- for debian
          |   |   |-- preseed_ubuntu.cfg ----------- for ubuntu
          |   |   |-- user-data_ubuntu ------------- for ubuntu cloud-init
          |   |   `-- yast_opensuse.xml ------------ for opensuse
          |   |-- agama ------------------------ configuration files for opensuse agama installer
          |   |-- autoyast --------------------- "                   for opensuse
          |   |-- kickstart -------------------- "                   for rhel
          |   |-- nocloud ---------------------- "                   for ubuntu cloud-init
          |   |   |-- ubuntu_desktop
          |   |   `-- ubuntu_server
          |   |-- preseed ---------------------- "                   for debian/ubuntu preseed
          |   |-- script ----------------------- script files
          |   |   |-- autoinst_cmd_early.sh -------- for auto install early command
          |   |   |-- autoinst_cmd_late.sh --------- "                late command
          |   |   |-- autoinst_cmd_part.sh --------- "                early command after partman
          |   |   `-- autoinst_cmd_run.sh ---------- "                preseed/run
          |   `-- windows ----------------------configuration files for windows
          |       |-- WinREexpand.cmd -------------- hotfix for windows 10
          |       |-- WinREexpand_bios.sub --------- "
          |       |-- WinREexpand_uefi.sub --------- "
          |       |-- bypass.cmd ------------------- installation restriction bypass command for windows 11
          |       |-- inst_w10.cmd ----------------- installation batch file for windows 10
          |       |-- inst_w11.cmd ----------------- "                       for windows 11
          |       |-- shutdown.cmd ----------------- shutdown command for winpe
          |       |-- startnet.cmd ----------------- startup command for winpe
          |       |-- unattend.xml ----------------- auto-installation configuration file for windows 10/11
          |       `-- winpeshl.ini -----------------
          |-- containers
          |-- imgs --------------------- iso file extraction destination
          |-- isos --------------------- iso file
          |   |-- linux -> /srv/samba/pub/resource/image/linux
          |   `-- windows -> /srv/samba/pub/resource/image/windows
          |-- load --------------------- load module
          |-- rmak -> /srv/samba/pub/resource/image/creations/rmak
          `-- rmak.orig
  ```

* ## **/var/**

  ``` bash:
  /var/
  |-- admin
  |   `-- autoinst
  |       |-- autoinst_cmd_early.sh
  |       |-- autoinst_cmd_early.sh.log
  |       |-- autoinst_cmd_late.sh
  |       |-- autoinst_cmd_late.sh.log
  |       |-- autoinst_cmd_part.sh
  |       |-- autoinst_cmd_part.sh.log
  |       |-- autoinst_cmd_run.sh
  |       `-- ps_debian_server.cfg
  `-- lib
      `-- connman
          `-- ethernet_[mac address]_cable
              `-- settings
  ```
