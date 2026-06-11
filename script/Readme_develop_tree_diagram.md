# **tree diagram**

<details><summary>sudo tree --charset C --filesfirst -n -x /srv/</summary>

  ``` bash:
  $ sudo tree --charset C --filesfirst -n -x /srv/
  /srv/
  |-- exports
  |   |-- nbd
  |   `-- nfs
  |       |-- conf
  |       `-- imgs
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
  |   |       |-- fonts
  |   |       |-- i386-efi
  |   |       |-- i386-pc
  |   |       |-- locale
  |   |       `-- x86_64-efi
  |   |-- conf -> /srv/user/share/conf
  |   |-- imgs -> /srv/user/share/imgs
  |   |-- ipxe
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
      `-- share
          |-- cache
          |-- chroot
          |-- conf
          |   |-- _data
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