# **tree diagram**

``` bash:
$ sudo tree --charset C --filesfirst -n /srv/
/srv/
|-- hgfs
|-- http
|   `-- html
|       |-- index.html
|       |-- conf -> /srv/user/share/conf
|       |-- imgs -> /srv/user/share/imgs
|       |-- isos -> /srv/user/share/isos
|       |-- load -> /srv/user/share/load
|       |-- rmak -> /srv/user/share/rmak
|       `-- tftp -> /srv/tftp
|-- nfs
|   |-- hgfs
|   |-- http
|   |-- samba
|   |-- tftp
|   `-- user
|-- samba
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
|   |   |   |-- image
|   |   |   |   |-- creations
|   |   |   |   |   `-- rmak
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
|           |-- app
|           |-- dat
|           `-- web
|               `-- public_html
|                   `-- index.html
|-- tftp
|   |-- autoexec.ipxe
|   |-- boot
|   |   `-- grub
|   |       |-- fonts
|   |       |-- i386-efi
|   |       |-- i386-pc
|   |       |-- locale
|   |       `-- x86_64-efi
|   |-- conf -> /srv/user/share/conf
|   |-- imgs -> /srv/user/share/imgs
|   |-- ipxe
|   |   |-- ipxe.efi
|   |   |-- undionly.kpxe
|   |   `-- wimboot
|   |-- isos -> /srv/user/share/isos
|   |-- load -> /srv/user/share/load
|   |-- menu-bios
|   |   |-- syslinux.cfg
|   |   |-- conf -> ../conf
|   |   |-- imgs -> ../imgs
|   |   |-- isos -> ../isos
|   |   |-- load -> ../load
|   |   |-- pxelinux.cfg
|   |   `-- rmak -> ../rmak
|   |-- menu-efi64
|   |   |-- syslinux.cfg
|   |   |-- conf -> ../conf
|   |   |-- imgs -> ../imgs
|   |   |-- isos -> ../isos
|   |   |-- load -> ../load
|   |   |-- pxelinux.cfg
|   |   `-- rmak -> ../rmak
|   `-- rmak -> /srv/user/share/rmak
`-- user
    |-- private
    `-- share
        |-- cache
        |-- chroot
        |-- conf
        |   |-- _data
        |   |   |-- common.cfg
        |   |   |-- distribution.dat
        |   |   `-- media.dat
        |   |-- _keyring
        |   |-- _mkosi
        |   |   |-- mkosi.build.d
        |   |   |-- mkosi.clean.d
        |   |   |-- mkosi.conf.d
        |   |   |   |-- mkosi.debian.conf
        |   |   |   |-- mkosi.opensuse.conf
        |   |   |   |-- mkosi.rhel-series.conf
        |   |   |   `-- mkosi.ubuntu.conf
        |   |   |-- mkosi.extra
        |   |   |-- mkosi.finalize.d
        |   |   |   `-- mkosi.finalize.sh.chroot
        |   |   |-- mkosi.postinst.d
        |   |   |   `-- mkosi.postinst.sh.chroot
        |   |   |-- mkosi.postoutput.d
        |   |   |-- mkosi.prepare.d
        |   |   |-- mkosi.repart
        |   |   |   |-- 00-esp.conf
        |   |   |   `-- 10-root.conf
        |   |   `-- mkosi.sync.d
        |   |-- _repository
        |   |   |-- almalinux.repo
        |   |   |-- centos-stream.repo
        |   |   |-- fedora.repo
        |   |   |-- miraclelinux.repo
        |   |   |-- rockylinux.repo
        |   |   `-- opensuse
        |   |       `-- opensuse.repo
        |   |-- _template
        |   |   |-- agama_opensuse.json
        |   |   |-- kickstart_rhel.cfg
        |   |   |-- preseed_debian.cfg
        |   |   |-- preseed_ubuntu.cfg
        |   |   |-- user-data_ubuntu
        |   |   `-- yast_opensuse.xml
        |   |-- agama
        |   |   |-- autoinst_leap-16.0.json
        |   |   |-- autoinst_leap-16.0_desktop.json
        |   |   |-- autoinst_tumbleweed.json
        |   |   `-- autoinst_tumbleweed_desktop.json
        |   |-- autoyast
        |   |   |-- autoinst_tumbleweed_dvd.xml
        |   |   |-- autoinst_tumbleweed_dvd_desktop.xml
        |   |   |-- autoinst_tumbleweed_net.xml
        |   |   `-- autoinst_tumbleweed_net_desktop.xml
        |   |-- kickstart
        |   |   |-- ks_almalinux-10_dvd.cfg
        |   |   |-- ks_almalinux-10_dvd_desktop.cfg
        |   |   |-- ks_almalinux-10_net.cfg
        |   |   |-- ks_almalinux-10_net_desktop.cfg
        |   |   |-- ks_almalinux-10_web.cfg
        |   |   |-- ks_almalinux-10_web_desktop.cfg
        |   |   |-- ks_almalinux-9_dvd.cfg
        |   |   |-- ks_almalinux-9_dvd_desktop.cfg
        |   |   |-- ks_almalinux-9_net.cfg
        |   |   |-- ks_almalinux-9_net_desktop.cfg
        |   |   |-- ks_almalinux-9_web.cfg
        |   |   |-- ks_almalinux-9_web_desktop.cfg
        |   |   |-- ks_centos-stream-10_dvd.cfg
        |   |   |-- ks_centos-stream-10_dvd_desktop.cfg
        |   |   |-- ks_centos-stream-10_net.cfg
        |   |   |-- ks_centos-stream-10_net_desktop.cfg
        |   |   |-- ks_centos-stream-10_web.cfg
        |   |   |-- ks_centos-stream-10_web_desktop.cfg
        |   |   |-- ks_centos-stream-9_dvd.cfg
        |   |   |-- ks_centos-stream-9_dvd_desktop.cfg
        |   |   |-- ks_centos-stream-9_net.cfg
        |   |   |-- ks_centos-stream-9_net_desktop.cfg
        |   |   |-- ks_centos-stream-9_web.cfg
        |   |   |-- ks_centos-stream-9_web_desktop.cfg
        |   |   |-- ks_fedora-42_dvd.cfg
        |   |   |-- ks_fedora-42_dvd_desktop.cfg
        |   |   |-- ks_fedora-42_net.cfg
        |   |   |-- ks_fedora-42_net_desktop.cfg
        |   |   |-- ks_fedora-42_web.cfg
        |   |   |-- ks_fedora-42_web_desktop.cfg
        |   |   |-- ks_fedora-43_dvd.cfg
        |   |   |-- ks_fedora-43_dvd_desktop.cfg
        |   |   |-- ks_fedora-43_net.cfg
        |   |   |-- ks_fedora-43_net_desktop.cfg
        |   |   |-- ks_fedora-43_web.cfg
        |   |   |-- ks_fedora-43_web_desktop.cfg
        |   |   |-- ks_miraclelinux-9_dvd.cfg
        |   |   |-- ks_miraclelinux-9_dvd_desktop.cfg
        |   |   |-- ks_miraclelinux-9_net.cfg
        |   |   |-- ks_miraclelinux-9_net_desktop.cfg
        |   |   |-- ks_miraclelinux-9_web.cfg
        |   |   |-- ks_miraclelinux-9_web_desktop.cfg
        |   |   |-- ks_rockylinux-10_dvd.cfg
        |   |   |-- ks_rockylinux-10_dvd_desktop.cfg
        |   |   |-- ks_rockylinux-10_net.cfg
        |   |   |-- ks_rockylinux-10_net_desktop.cfg
        |   |   |-- ks_rockylinux-10_web.cfg
        |   |   |-- ks_rockylinux-10_web_desktop.cfg
        |   |   |-- ks_rockylinux-9_dvd.cfg
        |   |   |-- ks_rockylinux-9_dvd_desktop.cfg
        |   |   |-- ks_rockylinux-9_net.cfg
        |   |   |-- ks_rockylinux-9_net_desktop.cfg
        |   |   |-- ks_rockylinux-9_web.cfg
        |   |   `-- ks_rockylinux-9_web_desktop.cfg
        |   |-- nocloud
        |   |   |-- ubuntu_desktop
        |   |   |   |-- meta-data
        |   |   |   |-- network-config
        |   |   |   |-- user-data
        |   |   |   `-- vendor-data
        |   |   `-- ubuntu_server
        |   |       |-- meta-data
        |   |       |-- network-config
        |   |       |-- user-data
        |   |       `-- vendor-data
        |   |-- preseed
        |   |   |-- ps_debian_desktop.cfg
        |   |   `-- ps_debian_server.cfg
        |   |-- script
        |   |   |-- autoinst_cmd_early.sh
        |   |   |-- autoinst_cmd_late.sh
        |   |   |-- autoinst_cmd_part.sh
        |   |   `-- autoinst_cmd_run.sh
        |   `-- windows
        |       |-- WinREexpand.cmd
        |       |-- WinREexpand_bios.sub
        |       |-- WinREexpand_uefi.sub
        |       |-- bypass.cmd
        |       |-- inst_w10.cmd
        |       |-- inst_w11.cmd
        |       |-- shutdown.cmd
        |       |-- startnet.cmd
        |       |-- unattend.xml
        |       `-- winpeshl.ini
        |-- containers
        |-- imgs
        |-- isos
        |   |-- linux
        |   |   |-- almalinux
        |   |   |-- centos
        |   |   |-- debian
        |   |   |-- emmabuntus
        |   |   |-- fedora
        |   |   |-- knoppix
        |   |   |-- memtest86plus
        |   |   |-- miraclelinux
        |   |   |-- opensuse
        |   |   |-- rockylinux
        |   |   |-- ubcd
        |   |   `-- ubuntu
        |   `-- windows
        |       |-- aomei
        |       |-- ati
        |       |-- windows-10
        |       |-- windows-11
        |       `-- winpe
        |-- load
        `-- rmak
```
