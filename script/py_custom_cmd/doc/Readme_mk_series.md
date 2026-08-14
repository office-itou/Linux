# mk series

## files

* <details><summary>program files</summary>

  |     file name     |              detail              |
  | :---------------- | :------------------------------- |
  | mk_conf_edit.sh   | editing the configuration file   |
  | mk_downloader.sh  | downloading the iso file         |
  | mk_ipxe_menu.sh   | creating ipxe menu script files  |
  | mk_custom_iso.sh  | creating custom iso files        |
  | mk_custom_live.sh | creating custom live media       |

</details>

* <details><summary>data files</summary>

  |     file name     |              detail              |
  | :---------------- | :------------------------------- |
  | common.cfg        | common configuration file        |
  | distribution.dat  | distribution data file           |
  | media.dat         | media data file                  |

</details>

## data sheet / data base layout

* <details><summary>common configuration file(common.cfg)</summary>

  * <details><summary>for server environments</summary>

    * <details><summary>shared directory parameter</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | DIRS_TOPS  | top of shared directory                        | "/srv"                                                                |
      | DIRS_EXPO  | exports                                        | ":\_DIRS_TOPS_:/exports"                                              |
      | DIRS_HGFS  | vmware shared                                  | ":\_DIRS_TOPS_:/hgfs"                                                 |
      | DIRS_HTML  | html contents                                  | ":\_DIRS_TOPS_:/http/html"                                            |
      | DIRS_SAMB  | samba shared                                   | ":\_DIRS_TOPS_:/samba"                                                |
      | DIRS_TFTP  | tftp contents                                  | ":\_DIRS_TOPS_:/tftp"                                                 |
      | DIRS_USER  | user file                                      | ":\_DIRS_TOPS_:/user"                                                 |

      </details>
    * <details><summary>shared of user file</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | DIRS_SHAR  | shared of user file                            | ":\_DIRS_USER_:/share"                                                |
      | DIRS_PVAT  | private contents directory                     | ":\_DIRS_USER_:/private"                                              |
      | DIRS_CONF  | configuration file                             | ":\_DIRS_SHAR_:/conf"                                                 |
      | DIRS_DATA  | data file                                      | ":\_DIRS_CONF_:/_data"                                                |
      | DIRS_KEYS  | keyring file                                   | ":\_DIRS_CONF_:/_keyring"                                             |
      | DIRS_MKOS  | mkosi configuration files                      | ":\_DIRS_CONF_:/_mkosi"                                               |
      | DIRS_TMPL  | templates for various configuration files      | ":\_DIRS_CONF_:/_template"                                            |
      | DIRS_SHEL  | shell script file                              | ":\_DIRS_CONF_:/script"                                               |
      | DIRS_IMGS  | iso file extraction destination                | ":\_DIRS_SHAR_:/imgs"                                                 |
      | DIRS_ISOS  | iso file                                       | ":\_DIRS_SHAR_:/isos"                                                 |
      | DIRS_LOAD  | load module                                    | ":\_DIRS_SHAR_:/load"                                                 |
      | DIRS_RMAK  | remake file                                    | ":\_DIRS_SHAR_:/rmak"                                                 |
      | DIRS_CACH  | cache file                                     | ":\_DIRS_SHAR_:/cache"                                                |
      | DIRS_CTNR  | container file                                 | ":\_DIRS_SHAR_:/containers"                                           |
      | DIRS_CHRT  | container file (chroot)                        | ":\_DIRS_SHAR_:/chroot"                                               |
      | DIRS_XNBD  | exports (network block device)                 | ":\_DIRS_EXPO_:/nbd"                                                  |
      | DIRS_XNFS  | exports (network file system)                  | ":\_DIRS_EXPO_:/nfs"                                                  |
      | DIRS_XSMB  | exports (samba)                                | ":\_DIRS_EXPO_:/smb"                                                  |

      </details>
    * <details><summary>common data file(prefer non-empty current file)</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_CONF  | common configuration file                      | "common.cfg"                                                          |
      | FILE_DIST  | distribution data file                         | "distribution.dat"                                                    |
      | FILE_MDIA  | media data file                                | "media.dat"                                                           |
      | FILE_DSTP  | debstrap data file                             | "debstrap.dat"                                                        |
      | PATH_CONF  | common configuration file                      | ":\_DIRS_DATA_:/:\_FILE_CONF_:"                                       |
      | PATH_DIST  | distribution data file                         | ":\_DIRS_DATA_:/:\_FILE_DIST_:"                                       |
      | PATH_MDIA  | media data file                                | ":\_DIRS_DATA_:/:\_FILE_MDIA_:"                                       |
      | PATH_DSTP  | debstrap data file                             | ":\_DIRS_DATA_:/:\_FILE_DSTP_:"                                       |

      </details>
    * <details><summary>pre-configuration file templates</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_KICK  | for rhel                                       | "kickstart_rhel.cfg"                                                  |
      | FILE_CLUD  | for ubuntu cloud-init                          | "user-data_ubuntu"                                                    |
      | FILE_SEDD  | for debian                                     | "preseed_debian.cfg"                                                  |
      | FILE_SEDU  | for ubuntu                                     | "preseed_ubuntu.cfg"                                                  |
      | FILE_YAST  | for opensuse                                   | "yast_opensuse.xml"                                                   |
      | FILE_AGMA  | for opensuse                                   | "agama_opensuse.json"                                                 |
      | PATH_KICK  | for rhel                                       | ":\_DIRS_TMPL_:/:\_FILE_KICK_:"                                       |
      | PATH_CLUD  | for ubuntu cloud-init                          | ":\_DIRS_TMPL_:/:\_FILE_CLUD_:"                                       |
      | PATH_SEDD  | for debian                                     | ":\_DIRS_TMPL_:/:\_FILE_SEDD_:"                                       |
      | PATH_SEDU  | for ubuntu                                     | ":\_DIRS_TMPL_:/:\_FILE_SEDU_:"                                       |
      | PATH_YAST  | for opensuse                                   | ":\_DIRS_TMPL_:/:\_FILE_YAST_:"                                       |
      | PATH_AGMA  | for opensuse                                   | ":\_DIRS_TMPL_:/:\_FILE_AGMA_:"                                       |

      </details>
    * <details><summary>shell script</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_ERLY  | shell commands to run early                    | "autoinst_cmd_early.sh"                                               |
      | FILE_LATE  | shell commands to run late                     | "autoinst_cmd_late.sh"                                                |
      | FILE_PART  | shell commands to run after partition          | "autoinst_cmd_part.sh"                                                |
      | FILE_RUNS  | shell commands to run preseed/run              | "autoinst_cmd_run.sh"                                                 |
      | PATH_ERLY  | shell commands to run early                    | ":\_DIRS_SHEL_:/:\_FILE_ERLY_:"                                       |
      | PATH_LATE  | shell commands to run late                     | ":\_DIRS_SHEL_:/:\_FILE_LATE_:"                                       |
      | PATH_PART  | shell commands to run after partition          | ":\_DIRS_SHEL_:/:\_FILE_PART_:"                                       |
      | PATH_RUNS  | shell commands to run preseed/run              | ":\_DIRS_SHEL_:/:\_FILE_RUNS_:"                                       |

      </details>
    * <details><summary>tftp menu</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_IPXE  | ipxe                                           | "ipxe/autoexec.ipxe"                                                  |
      | FILE_GRUB  | grub                                           | "boot/grub/grub.cfg"                                                  |
      | FILE_SLNX  | syslinux (bios)                                | "menu-bios/syslinux.cfg"                                              |
      | FILE_EF64  | syslinux (efi64)                               | "menu-efi64/syslinux.cfg"                                             |
      | PATH_IPXE  | ipxe                                           | ":\_DIRS_TFTP_:/:\_FILE_IPXE_:"                                       |
      | PATH_GRUB  | grub                                           | ":\_DIRS_TFTP_:/:\_FILE_GRUB_:"                                       |
      | PATH_SLNX  | syslinux (bios)                                | ":\_DIRS_TFTP_:/:\_FILE_SLNX_:"                                       |
      | PATH_EF64  | syslinux (efi64)                               | ":\_DIRS_TFTP_:/:\_FILE_EF64_:"                                       |

      </details>
    * <details><summary>tftp / nbd</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_NBDS  | nbd exports                                    | "exports.conf"                                                        |
      | DIRS_NBDS  | nbd exports                                    | "/etc/nbd-server/conf.d"                                              |
      | PATH_NBDS  | nbd exports                                    | ":\_DIRS_TFTP_:/:\_FILE_NBDS_:"                                       |

      </details>
    * <details><summary>tftp / web server network parameter</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | SRVR_HTTP  | server connection protocol (http or https)     | "http"                                                                |
      | SRVR_PROT  | server connection protocol (http or tftp)      | "http"                                                                |
      | SRVR_NICS  | network device name                            | "ens160"                                                              |
      | SRVR_MADR  | network device mac                             | "00:00:00:00:00:00"                                                   |
      | SRVR_ADDR  | IPv4 address                                   | "192.168.1.11"                                                        |
      | SRVR_CIDR  | IPv4 cidr                                      | "24"                                                                  |
      | SRVR_MASK  | IPv4 subnetmask                                | "255.255.255.0"                                                       |
      | SRVR_GWAY  | IPv4 gateway                                   | "192.168.1.254"                                                       |
      | SRVR_NSVR  | IPv4 nameserver                                | "192.168.1.254"                                                       |
      | SRVR_UADR  | IPv4 address up                                | "192.168.1"                                                           |

      </details>
    </details>
  * <details><summary>for creations</summary>

    * <details><summary>network parameter</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | NWRK_HOST  | hostname                                       | "sv-:\_DISTRO_:"                                                      |
      | NWRK_WGRP  | domain                                         | "workgroup"                                                           |
      | NICS_NAME  | network device name                            | "ens160"                                                              |
      | NICS_MADR  | network device mac                             | ""                                                                    |
      | IPV4_ADDR  | IPv4 address                                   | "192.168.1.1"                                                         |
      | IPV4_CIDR  | IPv4 cidr                                      | "24"                                                                  |
      | IPV4_MASK  | IPv4 subnetmask                                | "255.255.255.0"                                                       |
      | IPV4_GWAY  | IPv4 gateway                                   | "192.168.1.254"                                                       |
      | IPV4_NSVR  | IPv4 nameserver                                | "192.168.1.254"                                                       |
      | IPV4_UADR  | IPv4 address up                                | ""                                                                    |
      | NMAN_NAME  | network manager name                           | ""                                                                    |
      | NTPS_ADDR  | ntp server address                             | "ntp.nict.jp"                                                         |
      | NTPS_IPV4  | ntp server ipv4 addr                           | "61.205.120.130"                                                      |

      </details>
    * <details><summary>menu parameter</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | MENU_TOUT  | timeout (sec)                                  | "5"                                                                   |
      | MENU_RESO  | resolution (widht x hight)                     | "800x600"                                                             |
      | MENU_DPTH  | colors                                         | "16"                                                                  |
      | MENU_MODE  | screen mode (vga=nnn)                          | "788"                                                                 |
      | MENU_SPLS  | splash file                                    | "splash.png"                                                          |
      | #MENU_RESO | resolution (widht x hight)                     | "854x480"                                                             |
      | #MENU_RESO | resolution (widht x hight)                     | "854x480"                                                             |
      | #MENU_RESO | resolution (widht x hight)                     | "854x480"                                                             |
      | #MENU_DPTH | colors                                         | "16"                                                                  |
      | #MENU_MODE | screen mode (vga=nnn)                          | "864"                                                                 |

      </details>
    * <details><summary>auto install</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | AUTO_INST  | autoinstall configuration file                 | "autoinst.cfg"                                                        |
      | MINI_IRAM  | initial ram disk of mini.iso including preseed | "initps.gz"                                                           |

      </details>
    </details>
  * <details><summary>for mkosi</summary>

    * <details><summary>mkosi output image format type</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | #MKOS_BOOT | --bootable= (yes, no)                          | "yes"                                                                 |
      | MKOS_OUTP  | --output=                                      | "root_img"                                                            |
      | MKOS_FMAT  | --format= ...                                  | "directory"                                                           |
      |            | ... (directory, tar, cpio, disk, uki, esp, oci,|                                                                       |
      |            | .... sysext, confext, portable, addon, none)   |                                                                       |
      | #MKOS_NWRK | --with-network= (yes, no)                      | "yes"                                                                 |
      | MKOS_RECM  | --with-recommends (yes, no)                    | "yes"                                                                 |
      | #MKOS_DIST | --distribution= ...                            | ""                                                                    |
      |            | ... (fedora, debian, kali, ubuntu, arch,       |                                                                       |
      |            | .... opensuse, mageia, centos, rhel, rhel-ubi, |                                                                       |
      |            | .... openmandriva, rocky, alma, azure, custom) |                                                                       |
      | #MKOS_VERS | --release=                                     | ""                                                                    |
      | MKOS_ARCH  | --architecture= ...                            | "x86-64"                                                              |
      |            | ... (alpha, arc, arm, arm64, ia64, loongarch64,|                                                                       |
      |            | .... mips64-le, mips-le, parisc, ppc, ppc64,   |                                                                       |
      |            | .... ppc64-le, riscv32, riscv64, s390, s390x,  |                                                                       |
      |            | .... tilegx, x86, x86-64)                      |                                                                       |

      </details>
    * <details><summary>live media parameter</summary>

      |    name    |                     detail                     |                                example                                |
      | :--------- | :--------------------------------------------- | :-------------------------------------------------------------------- |
      | FILE_RTIM  | root image                                     | ":\_MKOS_OUTP_:.raw"                                                  |
      | FILE_SQFS  | squashfs / filesystem.squashfs                 | "squashfs.img"                                                        |
      | FILE_MBRF  | mbr image                                      | "bios.img"                                                            |
      | FILE_UEFI  | uefi image                                     | "uefi.img"                                                            |
      | FILE_BCAT  | eltorito catalog                               | "boot.cat"                                                            |
      | #FILE_ETRI |                                                | ""                                                                    |
      | #FILE_BIOS |                                                | ""                                                                    |
      | FILE_ICFG  | isolinux.cfg                                   | "isolinux.cfg"                                                        |
      | FILE_GCFG  | grub.cfg                                       | "grub.cfg"                                                            |
      | FILE_MENU  | menu.cfg                                       | "menu.cfg"                                                            |
      | FILE_THME  | theme.cfg                                      | "theme.cfg"                                                           |
      | DIRS_LIVE  | LiveOS / live                                  | "LiveOS"                                                              |
      | DIRS_MNTP  | mount point                                    | "mntp"                                                                |
      | DIRS_RTFS  | root image                                     | "rtfs"                                                                |
      | DIRS_CDFS  | cdfs image                                     | "cdfs"                                                                |
      | PATH_VLNZ  | kernel                                         | ""                                                                    |
      | PATH_IRAM  | initramfs                                      | ""                                                                    |
      | PATH_SPLS  | splash.png                                     | "/boot/grub/:\_MENU_SPLS_:"                                           |
      | SECU_OPTN  | security option                                | ""                                                                    |
      | SECU_APPA  | security apparmor                              | "security=apparmor apparmor=1"                                        |
      | SECU_SLNX  | security selinux                               | "security=selinux selinux=1 enforcing=0"                              |

      </details>
    </details>

</details>

* <details><summary>distribution information (distribution.dat)</summary>

  | index |       name       | size |           attribute           |    null    |                  detail                  |                                example                                |
  | :---: | :--------------- | :--: | :---------------------------- | :--------- | :--------------------------------------- | :-------------------------------------------------------------------- |
  |     0 | version          |   23 | TEXT                          | NOT NULL   |                                          | debian-testing                                                        |
  |     1 | name             |   23 | TEXT                          | NOT NULL   |                                          | Debian                                                                |
  |     2 | version_id       |   23 | TEXT                          | NOT NULL   |                                          | testing                                                               |
  |     3 | code_name        |   39 | TEXT                          |            |                                          | Testing                                                               |
  |     4 | life             |   15 | TEXT                          |            |                                          | -                                                                     |
  |     5 | release          |   15 | TEXT                          |            |                                          | 20xx-xx-xx                                                            |
  |     6 | support          |   15 | TEXT                          |            |                                          | 20xx-xx-xx                                                            |
  |     7 | long_term        |   15 | TEXT                          |            |                                          | -                                                                     |
  |     8 | rhel             |   15 | TEXT                          |            |                                          | -                                                                     |
  |     9 | kerne            |   27 | TEXT                          |            |                                          | testing                                                               |
  |    10 | note             |   27 | TEXT                          |            |                                          | -                                                                     |
  |    11 | wallpaper        |   87 | TEXT                          |            |                                          | -                                                                     |
  |    12 | create_flag      |   11 | TEXT                          |            |                                          | -                                                                     |

</details>

* <details><summary>media information (media.dat)</summary>

  | index |       name       | size |           attribute           |    null    |                  detail                  |                                example                                |
  | :---: | :--------------- | :--: | :---------------------------- | :--------- | :--------------------------------------- | :-------------------------------------------------------------------- |
  |     0 | type             |   11 | TEXT                          | NOT NULL   | media type                               | mini                                                                  |
  |     1 | entry_flag       |   11 | TEXT                          | NOT NULL   | \[m] menu, \[o] output, \[else] hidden   | o                                                                     |
  |     2 | entry_name       |   39 | TEXT                          | NOT NULL   | entry name (unique)                      | debian-mini-testing-daily                                             |
  |     3 | entry_disp       |   39 | TEXT                          | NOT NULL   | entry name for display                   | Debian%20testing%20daily                                              |
  |     4 | version          |   23 | TEXT                          |            | version id                               | debian-testing                                                        |
  |     5 | latest           |   23 | TEXT                          |            | latest version                           | debian-testing                                                        |
  |     6 | release          |   15 | TEXT                          |            | release date                             | 20xx-xx-xx                                                            |
  |     7 | support          |   15 | TEXT                          |            | support end date                         | 20xx-xx-xx                                                            |
  |     8 | web_regexp       |  143 | TEXT                          |            | web file  regexp                         | https\://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso     |
  |     9 | web_path         |  143 | TEXT                          |            | web file  path                           | https\://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso     |
  |    10 | web_tstamp       |   47 | TIMESTAMP WITH TIME ZONE      |            | web file  time stamp                     | 2026-07-23%2000:03:23+0000                                            |
  |    11 | web_size         |   15 | BIGINT                        |            | web file  file size                      | 75837440                                                              |
  |    12 | web_check        |   47 | TIMESTAMP WITH TIME ZONE      |            | web file  time stamp                     | 2026-07-25%2002:45:27+0000                                            |
  |    13 | web_status       |   15 | TEXT                          |            | web file  download status                | 200                                                                   |
  |    14 | iso_path         |   87 | TEXT                          |            | iso image file path                      | :\_DIRS_ISOS_:/linux/debian/mini-testing-daily-amd64.iso              |
  |    15 | iso_tstamp       |   47 | TEXT                          |            | iso image time stamp                     | 2026-07-23%2000:03:23+0000                                            |
  |    16 | iso_size         |   15 | BIGINT                        |            | iso image file size                      | 75837440                                                              |
  |    17 | iso_volume       |   43 | TEXT                          |            | iso image volume id                      | ISOIMAGE                                                              |
  |    18 | rmk_path         |   87 | TEXT                          |            | remaster  file path                      | :\_DIRS_RMAK_:/mini-testing-daily-amd64_preseed.iso                   |
  |    19 | rmk_tstamp       |   47 | TIMESTAMP WITH TIME ZONE      |            | remaster  time stamp                     | -                                                                     |
  |    20 | rmk_size         |   15 | BIGINT                        |            | remaster  file size                      | -                                                                     |
  |    21 | rmk_volume       |   43 | TEXT                          |            | remaster  volume id                      | -                                                                     |
  |    22 | ldr_initrd       |   87 | TEXT                          |            | initrd    file path                      | :\_DIRS_LOAD_:/debian-mini-testing-daily/initrd.gz                    |
  |    23 | ldr_kernel       |   87 | TEXT                          |            | kernel    file path                      | :\_DIRS_LOAD_:/debian-mini-testing-daily/linux                        |
  |    24 | cfg_path         |   87 | TEXT                          |            | config    file path                      | :\_DIRS_CONF_:/preseed/ps_debian_server.cfg                           |
  |    25 | cfg_tstamp       |   47 | TIMESTAMP WITH TIME ZONE      |            | config    time stamp                     | 2026-07-18%2004:23:51+0000                                            |
  |    26 | lnk_path         |   87 | TEXT                          |            | symlink   directory or file path         | -                                                                     |
  |    27 | options          |   59 | TEXT                          |            | boot options                             | -                                                                     |
  |    28 | create_flag      |   11 | TEXT                          |            | create flag                              | c                                                                     |

</details>

## memo

* [Markdown記法 チートシート](https://qiita.com/Qiita/items/c686397e4a0f4f11683d)
