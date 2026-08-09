# **tree diagram**

<details><summary>sudo tree --charset C --filesfirst -n -x /srv/</summary>

  ``` bash:
  $ sudo tree --charset C --filesfirst -n -x /srv/
  /srv/
  |-- exports
  |   |-- nbd
  |   |-- nfs
  |   |   |-- conf (mount bind -> /srv/user/share/conf)
  |   |   `-- imgs (mount bind -> /srv/user/share/imgs)
  |   `-- smb
  |       |-- conf (mount bind -> /srv/user/share/conf)
  |       |-- imgs (mount bind -> /srv/user/share/imgs)
  |       |-- isos (mount bind -> /srv/user/share/isos)
  |       |-- load (mount bind -> /srv/user/share/load)
  |       `-- rmak (mount bind -> /srv/user/share/rmak)
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
  |   |   |   |-- image
  |   |   |   |   |-- isos
  |   |   |   |   |   |-- linux
  |   |   |   |   |   |   |-- almalinux
  |   |   |   |   |   |   |-- centos
  |   |   |   |   |   |   |-- debian
  |   |   |   |   |   |   |-- fedora
  |   |   |   |   |   |   |-- memtest86plus
  |   |   |   |   |   |   |-- miraclelinux
  |   |   |   |   |   |   |-- opensuse
  |   |   |   |   |   |   |-- rockylinux
  |   |   |   |   |   |   `-- ubuntu
  |   |   |   |   |   `-- windows
  |   |   |   |   |       |-- aomei
  |   |   |   |   |       |-- ati
  |   |   |   |   |       |-- windows-10
  |   |   |   |   |       |-- windows-11
  |   |   |   |   |       `-- winpe
  |   |   |   |   `-- rmak
  |   |   |   `-- source
  |   |   |       `-- git
  |   |   `-- software
  |   `-- usr
  |-- tftp
  |   |-- boot
  |   |   `-- grub
  |   |       |-- fonts
  |   |       |-- i386-efi
  |   |       |-- i386-pc
  |   |       |-- locale
  |   |       `-- x86_64-efi
  |   |-- exports
  |   |   |-- conf -> /srv/user/share/conf
  |   |   |-- imgs -> /srv/user/share/imgs
  |   |   |-- isos -> /srv/user/share/isos
  |   |   |-- load -> /srv/user/share/load
  |   |   `-- rmak -> /srv/user/share/rmak
  |   |-- ipxe
  |   |   |-- autoexec.ipxe
  |   |   `-- menu
  |   |       `-- menu.ipxe
  |   |-- menu-bios
  |   |   |-- syslinux.cfg
  |   |   |-- conf -> ../exports/conf
  |   |   |-- imgs -> ../exports/imgs
  |   |   |-- isos -> ../exports/isos
  |   |   |-- load -> ../exports/load
  |   |   |-- pxelinux.cfg
  |   |   |   `-- default -> ../syslinux.cfg
  |   |   `-- rmak -> ../exports/rmak
  |   `-- menu-efi64
  |       |-- syslinux.cfg
  |       |-- conf -> ../exports/conf
  |       |-- imgs -> ../exports/imgs
  |       |-- isos -> ../exports/isos
  |       |-- load -> ../exports/load
  |       |-- pxelinux.cfg
  |       |   `-- default -> ../syslinux.cfg
  |       `-- rmak -> ../exports/rmak
  `-- user
      |-- private
      |   |-- bin
      |   |-- src
      |   |   `-- git
      |   `-- wrk
      `-- share
          |-- cache
          |-- chroot
          |-- conf
          |   |-- _data
          |   |-- _keyring
          |   |-- _mkosi
          |   |   |-- _template
          |   |   |-- mkosi.build.d
          |   |   |-- mkosi.clean.d
          |   |   |-- mkosi.conf.d
          |   |   |-- mkosi.extra
          |   |   |-- mkosi.finalize.d
          |   |   |-- mkosi.postinst.d
          |   |   |-- mkosi.postoutput.d
          |   |   |-- mkosi.prepare.d
          |   |   |-- mkosi.repart
          |   |   |-- mkosi.sync.d
          |   |   |-- repository
          |   |   `-- script (mount bind -> /srv/user/share/conf/script)
          |   |-- _repository
          |   |   `-- opensuse
          |   |-- _template
          |   |-- agama
          |   |-- autoyast
          |   |-- kickstart
          |   |-- nocloud
          |   |   |-- ubuntu_desktop
          |   |   `-- ubuntu_server
          |   |-- preseed
          |   |-- script
          |   `-- windows
          |-- containers
          |-- imgs
          |-- isos
          |   |-- linux
          |   |   |-- almalinux
          |   |   |-- centos
          |   |   |-- debian
          |   |   |-- fedora
          |   |   |-- memtest86plus
          |   |   |-- miraclelinux
          |   |   |-- opensuse
          |   |   |-- rockylinux
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
