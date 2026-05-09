# **tree diagram**

<details><summary>sudo tree --charset C --filesfirst -n /srv/</summary>

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
|   |   |   `-- git
|   |   `-- software
|   `-- usr
|-- tftp
|   |-- autoexec.ipxe
|   |-- boot
|   |   `-- grub
|   |       |-- grub.cfg
|   |       |-- fonts
|   |       |-- i386-efi
|   |       |-- i386-pc
|   |       |-- locale
|   |       `-- x86_64-efi
|   |-- conf -> /srv/user/share/conf
|   |-- imgs -> /srv/user/share/imgs
|   |-- ipxe
|   |   |-- ipxe.efi
|   |   |-- ipxe.lkrn
|   |   |-- ipxe.pxe
|   |   |-- snponly.efi
|   |   |-- undionly.kpxe
|   |   `-- wimboot
|   |-- ipxe.back
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
|   |   |   `-- default -> ../syslinux.cfg
|   |   `-- rmak -> ../rmak
|   |-- menu-efi64
|   |   |-- syslinux.cfg
|   |   |-- conf -> ../conf
|   |   |-- imgs -> ../imgs
|   |   |-- isos -> ../isos
|   |   |-- load -> ../load
|   |   |-- pxelinux.cfg
|   |   |   `-- default -> ../syslinux.cfg
|   |   `-- rmak -> ../rmak
|   `-- rmak -> /srv/user/share/rmak
`-- user
    |-- private
    |   |-- bin
    |   |-- src
    |   |   `-- git
    |   |       `-- mkosi
    |   `-- wrk
    `-- share
        |-- cache
        |-- chroot
        |-- conf
        |   |-- _data
        |   |   |-- common.cfg
        |   |   |-- distribution.dat
        |   |   `-- media.dat
        |   |-- _mkosi
        |   |-- _template
        |   |   |-- agama_opensuse.json
        |   |   |-- kickstart_rhel.cfg
        |   |   |-- preseed_debian.cfg
        |   |   |-- preseed_ubuntu.cfg
        |   |   |-- user-data_ubuntu
        |   |   `-- yast_opensuse.xml
        |   |-- agama
        |   |-- autoyast
        |   |-- kickstart
        |   |-- nocloud
        |   |-- preseed
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

</details>

* [details of mkosi](./Readme_develop_mkosi_tree_diagram.md)