# **global variables**

* ## **shell common**

  * ### **for system sharing**

    * #### **debug parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _DBGS_FLAG | debug flag (empty: normal, else: debug)                          | [],[true]                                             |
      | _DBGS_FAIL | for detecting errors                                             | []                                                      |
      | _DBGS_PARM |                                                                  | []                                                      |

    * #### **working directory (executable file information)**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _PROG_PATH | &#x24;0                                                          | []                                                    |
      | _PROG_PARM | &#x24;@                                                          | []                                                    |
      | _PROG_DIRS | &#x24;\\{\\_PROG\\_PATH%/*\\}                                    | []                                                    |
      | _PROG_NAME | &#x24;\\{\\_PROG\\_PATH##*/\\}                                   | []                                                    |
      | _PROG_PROC | &#x24;\\{\\_PROG\\_NAME\\}.&#x24;&#x24;                          | []                                                    |
      | _DIRS_TEMP | temporary directory                                              | []                                                    |
      | _LIST_RMOV | list remove directory / file                                     | []                                                    |

    * #### **list data**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _LIST_CONF | common configuration data                                        | []                                                    |
      | _LIST_DIST | distribution information                                         | []                                                    |
      | _LIST_MDIA | media information                                                | []                                                    |
      | _LIST_DSTP | debstrap information                                             | []                                                    |

    * #### **command line parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _COMD_LINE | command line parameter                                           | [BOOT_IMAGE=/vmlinuz-6.12.48+deb13-amd64 root=/dev/mapper/sv--developer--vg-root ro quiet security=apparmor apparmor=1] |
      | _NICS_NAME | nic if name (dual use)                                           | [ens160]                                              |
      | _NICS_MADR | nic if mac  (dual use)                                           | [00:00:00:00:00:00]                                   |
      | _NICS_AUTO | ipv4 dhcp                                                        | [],[dhcp]                                             |
      | _NICS_IPV4 | ipv4 address                                                     | [192.168.1.1]                                         |
      | _NICS_MASK | ipv4 netmask                                                     | [255.255.255.0]                                       |
      | _NICS_BIT4 | ipv4 cidr                                                        | [24]                                                  |
      | _NICS_DNS4 | ipv4 dns                                                         | [192.168.1.254]                                       |
      | _NICS_GATE | ipv4 gateway                                                     | [192.168.1.254]                                       |
      | _NICS_FQDN | hostname fqdn                                                    | [sv-server.workgroup]                                 |
      | _NICS_HOST | hostname                                                         | [sv-server]                                           |
      | _NICS_WGRP | domain                                                           | [workgroup]                                           |
      | _NMAN_FLAG | network manager                                                  | [nm_config],[ifupdown],[loopback]                     |
      | _DIRS_TGET | target directory                                                 | [/target],[/mnt/sysimage],[/mnt/]                     |
      | _FILE_ISOS | iso file name                                                    | []                                                    |
      | _FILE_SEED | preseed file name                                                | []                                                    |

    * #### **target**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _TGET_VIRT | virtualization                                                   | [vmware]                                              |
      | _TGET_CNTR | is container (empty: none, else: container)                      | [],[true]                                             |

    * #### **set system parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _DIST_NAME | distribution name                                                | [debian]                                              |
      | _DIST_VERS | release version                                                  | [13]                                                  |
      | _DIST_CODE | code name                                                        | [trixie]                                              |
      | _ROWS_SIZE | screen size: rows                                                | [25]                                                  |
      | _COLS_SIZE | screen size: columns                                             | [120]                                                 |
      | _TEXT_GAP1 | gap1                                                             | [---]                                                 |
      | _TEXT_GAP2 | gap2                                                             | [===]                                                 |
      | _COMD_BBOX | busybox (empty: inactive, else: active )                         | [],[true]                                             |
      | _OPTN_COPY | copy option                                                      | [--preserve=timestamps]                               |

    * #### **network parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _NTPS_ADDR | ntp server address      (dual use)                               | [ntp.nict.jp]                                         |
      | _NTPS_IPV4 | ntp server ipv4 address (dual use)                               | [61.205.120.130]                                      |
      | _NTPS_FBAK | ntp server fallback list                                         | [ntp1.jst.mfeed.ad.jp ntp2.jst.mfeed.ad.jp ntp3.jst.mfeed.ad.jp] |
      | _IPV6_LHST | ipv6 local host address                                          | [::1]                                                 |
      | _IPV4_LHST | ipv4 local host address                                          | [127.0.0.1]                                           |
      | _IPV4_DUMY | ipv4 dummy address                                               | [127.0.1.1]                                           |
      | _IPV4_UADR | IPv4 address up                                                  | [192.168.1]                                           |
      | _IPV4_LADR | IPv4 address low                                                 | [1]                                                   |
      | _IPV6_ADDR | IPv6 address                                                     | [2000::1]                                             |
      | _IPV6_CIDR | IPv6 cidr                                                        | [64]                                                  |
      | _IPV6_FADR | IPv6 full address                                                | [2000:0000:0000:0000:0000:0000:0000:0001]             |
      | _IPV6_UADR | IPv6 address up                                                  | [2000:0000:0000:0000]                                 |
      | _IPV6_LADR | IPv6 address low                                                 | [0000:0000:0000:0001]                                 |
      | _IPV6_RADR | IPv6 reverse addr                                                | [1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.2] |
      | _LINK_ADDR | LINK address                                                     | [fe80::1]                                             |
      | _LINK_CIDR | LINK cidr                                                        | [64]                                                  |
      | _LINK_FADR | LINK full address                                                | [fe80:0000:0000:0000:0000:0000:0000:0001]             |
      | _LINK_UADR | LINK address up                                                  | [fe80:0000:0000:0000]                                 |
      | _LINK_LADR | LINK address low                                                 | [0000:0000:0000:0001]                                 |
      | _LINK_RADR | LINK reverse addr                                                | [1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.8.e.f] |

    * #### **firewalld**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _FWAL_ZONE | firewalld default zone                                           | [home_use]                                            |
      | _FWAL_NAME | firewalld service name                                           | [dhcp dhcpv6 dhcpv6-client dns http https mdns nfs proxy-dhcp samba samba-client ssh tftp] |
      | _FWAL_PORT | firewalld port                                                   | [0-65535/tcp 0-65535/udp]                             |

    * #### **samba parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _SAMB_USER | force user                                                       | [sambauser]                                           |
      | _SAMB_GRUP | force group                                                      | [sambashare]                                          |
      | _SAMB_GADM | admin group                                                      | [sambaadmin]                                          |
      | _SAMB_NSSW | nsswitch.conf                                                    | [wins mdns4_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] dns mdns4 mdns6] |
      | _SHEL_NLIN | login shell (disallow system login to samba user)                | [/usr/sbin/nologin]                                   |

  * ### **for server environments (common.cfg)**

    * #### **shared directory parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _DIRS_TOPS | top of shared directory                                          | [/srv]                                                |
      | _DIRS_HGFS | vmware shared                                                    | [/srv/hgfs]                                           |
      | _DIRS_HTML | html contents#                                                   | [/srv/http/html]                                      |
      | _DIRS_SAMB | samba shared                                                     | [/srv/samba]                                          |
      | _DIRS_TFTP | tftp contents                                                    | [/srv/tftp]                                           |
      | _DIRS_USER | user file                                                        | [/srv/user]                                           |

    * #### **shared of user file**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _DIRS_PVAT | private contents directory                                       | []                                                    |
      | _DIRS_SHAR | shared contents directory                                        | [/srv/user/share]                                     |
      | _DIRS_CONF | configuration file                                               | [/srv/user/share/conf]                                |
      | _DIRS_DATA | data file                                                        | [/srv/user/share/conf/_data]                          |
      | _DIRS_KEYS | keyring file                                                     | [/srv/user/share/conf/_keyring]                       |
      | _DIRS_MKOS | mkosi configuration files                                        | [/srv/user/share/conf/_mkosi]                         |
      | _DIRS_TMPL | templates for various configuration files                        | [/srv/user/share/conf/_template]                      |
      | _DIRS_SHEL | shell script file                                                | [/srv/user/share/conf/script]                         |
      | _DIRS_IMGS | iso file extraction destination                                  | [/srv/user/share/imgs]                                |
      | _DIRS_ISOS | iso file                                                         | [/srv/user/share/isos]                                |
      | _DIRS_LOAD | load module                                                      | [/srv/user/share/load]                                |
      | _DIRS_RMAK | remake file                                                      | [/srv/user/share/rmak]                                |
      | _DIRS_CACH | cache file                                                       | [/srv/user/share/cache]                               |
      | _DIRS_CTNR | container file                                                   | [/srv/user/share/containers]                          |
      | _DIRS_CHRT | container file (chroot)                                          | [/srv/user/share/chroot]                              |

    * #### **shell script**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _FILE_ERLY | to run early                                                     | [autoinst_cmd_early.sh]                               |
      | _FILE_LATE | to run late                                                      | [autoinst_cmd_late.sh]                                |
      | _FILE_PART | to run after partition                                           | [autoinst_cmd_part.sh]                                |
      | _FILE_RUNS | to run preseed/run                                               | [autoinst_cmd_run.sh]                                 |
      | _PATH_ERLY | to run early                                                     | [/srv/user/share/conf/script/autoinst_cmd_early.sh]   |
      | _PATH_LATE | to run late                                                      | [/srv/user/share/conf/script/autoinst_cmd_late.sh]    |
      | _PATH_PART | to run after partition                                           | [/srv/user/share/conf/script/autoinst_cmd_part.sh]    |
      | _PATH_RUNS | to run preseed/run                                               | [/srv/user/share/conf/script/autoinst_cmd_run.sh]     |

    * #### **common data file (prefer non-empty current file)**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _FILE_CONF | common configuration file                                        | [common.cfg]                                          |
      | _FILE_DIST | distribution data file                                           | [distribution.dat]                                    |
      | _FILE_MDIA | media data file                                                  | [media.dat]                                           |
      | _FILE_DSTP | debstrap data file                                               | [debstrap.dat]                                        |
      | _PATH_CONF | common configuration file                                        | [/srv/user/share/conf/_data/common.cfg]               |
      | _PATH_DIST | distribution data file                                           | [/srv/user/share/conf/_data/distribution.dat]         |
      | _PATH_MDIA | media data file                                                  | [/srv/user/share/conf/_data/media.dat]                |
      | _PATH_DSTP | debstrap data file                                               | [/srv/user/share/conf/_data/debstrap.dat]             |

    * #### **pre-configuration file templates**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _FILE_KICK | for rhel                                                         | [kickstart_rhel.cfg]                                  |
      | _FILE_CLUD | for ubuntu cloud-init                                            | [user-data_ubuntu]                                    |
      | _FILE_SEDD | for debian                                                       | [preseed_debian.cfg]                                  |
      | _FILE_SEDU | for ubuntu                                                       | [preseed_ubuntu.cfg]                                  |
      | _FILE_YAST | for opensuse                                                     | [yast_opensuse.xml]                                   |
      | _FILE_AGMA | for opensuse                                                     | [agama_opensuse.json]                                 |
      | _PATH_KICK | for rhel                                                         | [/srv/user/share/conf/_template/kickstart_rhel.cfg]   |
      | _PATH_CLUD | for ubuntu cloud-init                                            | [/srv/user/share/conf/_template/user-data_ubuntu]     |
      | _PATH_SEDD | for debian                                                       | [/srv/user/share/conf/_template/preseed_debian.cfg]   |
      | _PATH_SEDU | for ubuntu                                                       | [/srv/user/share/conf/_template/preseed_ubuntu.cfg]   |
      | _PATH_YAST | for opensuse                                                     | [/srv/user/share/conf/_template/yast_opensuse.xml]    |
      | _PATH_AGMA | for opensuse                                                     | [/srv/user/share/conf/_template/agama_opensuse.json]  |

    * #### **tftp / web server network parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _SRVR_HTTP | server connection protocol (http or https)                       | [http]                                                |
      | _SRVR_PROT | server connection protocol (http or tftp)                        | [http]                                                |
      | _SRVR_NICS | network device name                                              | [ens160]                                              |
      | _SRVR_MADR | network device mac                                               | [00:00:00:00:00:00]                                   |
      | _SRVR_ADDR | IPv4 address                                                     | [192.168.1.11]                                        |
      | _SRVR_CIDR | IPv4 cidr                                                        | [24]                                                  |
      | _SRVR_MASK | IPv4 subnetmask                                                  | [255.255.255.0]                                       |
      | _SRVR_GWAY | IPv4 gateway                                                     | [192.168.1.254]                                       |
      | _SRVR_NSVR | IPv4 nameserver                                                  | [192.168.1.254]                                       |
      | _SRVR_UADR | IPv4 address up                                                  | [192.168.1]                                           |

  * ### **for creations (common.cfg)**

    * #### **menu parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _MENU_TOUT | timeout (sec)                                                    | [5]                                                   |
      | _MENU_RESO | resolution (widht x hight)                                       | [854x480]                                             |
      | _MENU_DPTH | colors                                                           | [16]                                                  |
      | _MENU_MODE | screen mode (vga=nnn)                                            | [864]                                                 |
      | _MENU_SPLS | splash file                                                      | [splash.png]                                          |

  * ### **for mkosi (common.cfg)**

    * #### **mkosi output image format type**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _MKOS_TGET | format type (directory, tar, cpio, disk, uki, esp, oci, sysext, confext, portable, addon, none) | [directory]            |

    * #### **live media parameter**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _LIVE_DIRS | live / LiveOS                                                    | [LiveOS]                                              |
      | _LIVE_SQFS | filesystem.squashfs / squashfs.img                               | [squashfs.img]                                        |

  * ### **other variables**

    * #### **working directory (shared use)**

      |    name    |                             descript                             |                        example                        |
      | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
      | _DIRS_VADM | top of admin working directory                                   | [/var/admin]                                          |
      | _DIRS_INST | auto-install working directory                                   | []                                                    |
      | _DIRS_BACK | top of backup directory                                          | []                                                    |
      | _DIRS_ORIG | original file directory                                          | []                                                    |
      | _DIRS_INIT | initial file directory                                           | []                                                    |
      | _DIRS_SAMP | sample file directory                                            | []                                                    |
      | _DIRS_LOGS | log file directory                                               | []                                                    |

* ## **for installation setup**

  * ### **network parameter (shared use)**

    |    name    |                             descript                             |                        example                        |
    | :--------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
    | _NWRK_HOST | hostname                                                         | [sv-:_DISTRO_:]                                       |
    | _NWRK_WGRP | domain                                                           | [workgroup]                                           |
    | _NICS_NAME | network device name                                              | [ens160]                                              |
    | _NICS_MADR | network device mac                                               | [00:00:00:00:00:00]                                   |
    | _IPV4_ADDR | IPv4 address                                                     | [192.168.1.1]                                         |
    | _IPV4_CIDR | IPv4 cidr                                                        | [24]                                                  |
    | _IPV4_MASK | IPv4 subnetmask                                                  | [255.255.255.0]                                       |
    | _IPV4_GWAY | IPv4 gateway                                                     | [192.168.1.254]                                       |
    | _IPV4_NSVR | IPv4 nameserver                                                  | [192.168.1.254]                                       |
    | _IPV4_UADR | IPv4 address up                                                  | [192.168.1]                                           |
    | _NMAN_NAME | network manager name                                             | [nm_config],[ifupdown],[loopback]                     |
    | _NTPS_ADDR | ntp server address   (dual use)                                  | [ntp.nict.jp]                                         |
    | _NTPS_IPV4 | ntp server ipv4 addr (dual use)                                  | [61.205.120.130]                                      |

* ## **constant definitions**

  * ### **color code**

    |           name           |                             descript                             |                        example                        |
    | :----------------------- | :--------------------------------------------------------------- | :---------------------------------------------------- |
    | _CODE_ESCP               | escape codes                                                     | (\033)                                                |
    | _TEXT_RESET              | reset all attributes                                             | (\033[0m)                                             |
    | _TEXT_BOLD               |                                                                  | (\033[1m)                                             |
    | _TEXT_FAINT              |                                                                  | (\033[2m)                                             |
    | _TEXT_ITALIC             |                                                                  | (\033[3m)                                             |
    | _TEXT_UNDERLINE          | set underline                                                    | (\033[4m)                                             |
    | _TEXT_BLINK              |                                                                  | (\033[5m)                                             |
    | _TEXT_FAST_BLINK         |                                                                  | (\033[6m)                                             |
    | _TEXT_REVERSE            | set reverse display                                              | (\033[7m)                                             |
    | _TEXT_CONCEAL            |                                                                  | (\033[8m)                                             |
    | _TEXT_STRIKE             |                                                                  | (\033[9m)                                             |
    | _TEXT_GOTHIC             |                                                                  | (\033[20m)                                            |
    | _TEXT_DOUBLE_UNDERLINE   |                                                                  | (\033[21m)                                            |
    | _TEXT_NORMAL             |                                                                  | (\033[22m)                                            |
    | _TEXT_NO_ITALIC          |                                                                  | (\033[23m)                                            |
    | _TEXT_NO_UNDERLINE       | reset underline                                                  | (\033[24m)                                            |
    | _TEXT_NO_BLINK           |                                                                  | (\033[25m)                                            |
    | _TEXT_NO_REVERSE         | reset reverse display                                            | (\033[27m)                                            |
    | _TEXT_NO_CONCEAL         |                                                                  | (\033[28m)                                            |
    | _TEXT_NO_STRIKE          |                                                                  | (\033[29m)                                            |
    | _TEXT_BLACK              | text dark black                                                  | (\033[30m)                                            |
    | _TEXT_RED                | text dark red                                                    | (\033[31m)                                            |
    | _TEXT_GREEN              | text dark green                                                  | (\033[32m)                                            |
    | _TEXT_YELLOW             | text dark yellow                                                 | (\033[33m)                                            |
    | _TEXT_BLUE               | text dark blue                                                   | (\033[34m)                                            |
    | _TEXT_MAGENTA            | text dark purple                                                 | (\033[35m)                                            |
    | _TEXT_CYAN               | text dark light blue                                             | (\033[36m)                                            |
    | _TEXT_WHITE              | text dark white                                                  | (\033[37m)                                            |
    | _TEXT_DEFAULT            |                                                                  | (\033[39m)                                            |
    | _TEXT_BG_BLACK           | text reverse black                                               | (\033[40m)                                            |
    | _TEXT_BG_RED             | text reverse red                                                 | (\033[41m)                                            |
    | _TEXT_BG_GREEN           | text reverse green                                               | (\033[42m)                                            |
    | _TEXT_BG_YELLOW          | text reverse yellow                                              | (\033[43m)                                            |
    | _TEXT_BG_BLUE            | text reverse blue                                                | (\033[44m)                                            |
    | _TEXT_BG_MAGENTA         | text reverse purple                                              | (\033[45m)                                            |
    | _TEXT_BG_CYAN            | text reverse light blue                                          | (\033[46m)                                            |
    | _TEXT_BG_WHITE           | text reverse white                                               | (\033[47m)                                            |
    | _TEXT_BG_DEFAULT         |                                                                  | (\033[49m)                                            |
    | _TEXT_BR_BLACK           | text black                                                       | (\033[90m)                                            |
    | _TEXT_BR_RED             | text red                                                         | (\033[91m)                                            |
    | _TEXT_BR_GREEN           | text green                                                       | (\033[92m)                                            |
    | _TEXT_BR_YELLOW          | text yellow                                                      | (\033[93m)                                            |
    | _TEXT_BR_BLUE            | text blue                                                        | (\033[94m)                                            |
    | _TEXT_BR_MAGENTA         | text purple                                                      | (\033[95m)                                            |
    | _TEXT_BR_CYAN            | text light blue                                                  | (\033[96m)                                            |
    | _TEXT_BR_WHITE           | text white                                                       | (\033[97m)                                            |
    | _TEXT_BR_DEFAULT         |                                                                  | (\033[99m)                                            |
