# **Variables and directory structure**

``` bash:
_DIRS_TOPS  /srv/
_DIRS_HGFS  |-- hgfs -------------------------- vmware shared directory
            |-- http -------------------------- web contents file
_DIRS_HTML  |   `-- html
            |       |-- boot -> /srv/tftp/boot/
            |       |-- conf -> /srv/user/pub/conf
            |       |-- imgs -> /srv/user/pub/imgs
            |       |-- isos -> /srv/user/pub/isos
            |       |-- load -> /srv/user/pub/load
            |       `-- rmak -> /srv/user/pub/rmak
_DIRS_SAMB  |-- samba ------------------------- samba shared directory
            |   |-- adm ----------------------- administrator files
            |   |   |-- commands
            |   |   `-- profiles
            |   |-- pub ----------------------- public area
            |   |   |-- contents
            |   |   |   |-- disc
            |   |   |   `-- dlna
            |   |   |       |-- movies
            |   |   |       |-- others
            |   |   |       |-- photos
            |   |   |       `-- sounds
            |   |   |-- resource
            |   |   |   |-- image
            |   |   |   |   |-- linux
            |   |   |   |   `-- windows
            |   |   |   `-- source
            |   |   |       `-- git
            |   |   |-- software
            |   |   |-- hardware
            |   |   `-- _license
            |   `-- usr ----------------------- user file area
_DIRS_TFTP  |-- tftp -------------------------- tftp contents
            |   |-- boot
            |   |   `-- grub
            |   |       |-- fonts
            |   |       |-- i386-efi
            |   |       |-- i386-pc
            |   |       |-- locale
            |   |       `-- x86_64-efi
            |   |-- conf -> /srv/user/pub/conf
            |   |-- imgs -> /srv/user/pub/imgs
            |   |-- ipxe
            |   |-- isos -> /srv/user/pub/isos
            |   |-- load -> /srv/user/pub/load
            |   |-- menu-bios
            |   |   |-- conf -> ../conf
            |   |   |-- imgs -> ../imgs
            |   |   |-- isos -> ../isos
            |   |   |-- load -> ../load
            |   |   |-- pxelinux.cfg
            |   |   `-- rmak -> ../rmak
            |   |-- menu-efi64
            |   |   |-- conf -> ../conf
            |   |   |-- imgs -> ../imgs
            |   |   |-- isos -> ../isos
            |   |   |-- load -> ../load
            |   |   |-- pxelinux.cfg
            |   |   `-- rmak -> ../rmak
            |   `-- rmak -> /srv/user/pub/rmak
_DIRS_USER  |-- user -------------------------- user file
            |   |-- private ------------------- personal use
_DIRS_SHAR  |   `-- share --------------------- shared
            |       |-- chrt ------------------ change route directory
_DIRS_CONF  |       |-- conf ------------------ configuration file
_DIRS_DATA  |       |   |-- _data
_PATH_MDIA  |       |   |   `-- media.dat ----- media data file
_DIRS_KEYS  |       |   |-- _keyring
_DIRS_TMPL  |       |   |-- _template
_CONF_KICK  |       |   |   |-- kickstart_rhel.cfg ---- for rhel
_CONF_CLUD  |       |   |   |-- user-data_ubuntu ------ for ubuntu cloud-init
_CONF_SEDD  |       |   |   |-- preseed_debian.cfg ---- for debian
_CONF_SEDU  |       |   |   |-- preseed_ubuntu.cfg ---- for ubuntu
_CONF_YAST  |       |   |   |-- yast_opensuse.xml ----- for opensuse autoyast
_CONF_AGMA  |       |   |   `-- agama_opensuse.json --- for opensuse agama
_DIRS_SHEL  |       |   `-- script
_SHEL_ERLY  |       |       |-- autoinst_cmd_early.sh - run early
_SHEL_LATE  |       |       |-- autoinst_cmd_late.sh -- run late
_SHEL_PART  |       |       |-- autoinst_cmd_part.sh -- run after partition
_SHEL_RUNS  |       |       `-- autoinst_cmd_run.sh --- run preseed/run
_DIRS_IMGS  |       |-- imgs ------------------ iso file extraction destination
_DIRS_ISOS  |       |-- isos ------------------ iso file
_DIRS_LOAD  |       |-- load ------------------ load module
_DIRS_RMAK  |       `-- rmak ------------------ remake file
            `-- vmware ------------------------ virtual machine
```
