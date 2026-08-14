# --- shared directory parameter ----------------------------------------------
#   dirs_tops = conf["DIRS_TOPS"]       # top of shared directory   : '/srv'
#   dirs_expo = conf["DIRS_EXPO"]       # exports                   : '/srv/exports'
#   dirs_hgfs = conf["DIRS_HGFS"]       # vmware shared             : '/srv/hgfs'
#   dirs_html = conf["DIRS_HTML"]       # html contents             : '/srv/http/html'
#   dirs_samb = conf["DIRS_SAMB"]       # samba shared              : '/srv/samba'
#   dirs_tftp = conf["DIRS_TFTP"]       # tftp contents             : '/srv/tftp'
#   dirs_user = conf["DIRS_USER"]       # user file                 : '/srv/user'

# --- shared of user file -----------------------------------------------------
#   dirs_pvat = conf["DIRS_PVAT"]       # private contents directory                : '/srv/user/private'
#   dirs_shar = conf["DIRS_SHAR"]       # shared of user file                       : '/srv/user/share'
#   dirs_conf = conf["DIRS_CONF"]       # configuration file                        : '/srv/user/share/conf'
#   dirs_data = conf["DIRS_DATA"]       # data file                                 : '/srv/user/share/conf/_data'
#   dirs_keys = conf["DIRS_KEYS"]       # keyring file                              : '/srv/user/share/conf/_keyring'
#   dirs_mkos = conf["DIRS_MKOS"]       # mkosi configuration files                 : '/srv/user/share/conf/_mkosi'
#   dirs_tmpl = conf["DIRS_TMPL"]       # templates for various configuration files : '/srv/user/share/conf/_template'
#   dirs_shel = conf["DIRS_SHEL"]       # shell script file                         : '/srv/user/share/conf/script'
#   dirs_imgs = conf["DIRS_IMGS"]       # iso file extraction destination           : '/srv/user/share/imgs'
#   dirs_isos = conf["DIRS_ISOS"]       # iso file                                  : '/srv/user/share/isos'
#   dirs_load = conf["DIRS_LOAD"]       # load module                               : '/srv/user/share/load'
#   dirs_rmak = conf["DIRS_RMAK"]       # remake file                               : '/srv/user/share/rmak'
#   dirs_cach = conf["DIRS_CACH"]       # cache file                                : '/srv/user/share/cache'
#   dirs_ctnr = conf["DIRS_CTNR"]       # container file                            : '/srv/user/share/containers'
#   dirs_chrt = conf["DIRS_CHRT"]       # container file (chroot)                   : '/srv/user/share/chroot'
#   dirs_xnbd = conf["DIRS_XNBD"]       # exports (network block device)            : '/srv/exports/nbd'
#   dirs_xnfs = conf["DIRS_XNFS"]       # exports (network file system)             : '/srv/exports/nfs'
#   dirs_xsmb = conf["DIRS_XSMB"]       # exports (samba)                           : '/srv/exports/smb'

# --- common data file (prefer non-empty current file) ------------------------
#   path_conf = conf["PATH_CONF"]       # common configuration file : '/srv/user/share/conf/_data/common.cfg'
#   path_dist = conf["PATH_DIST"]       # distribution data file    : '/srv/user/share/conf/_data/distribution.dat'
#   path_mdia = conf["PATH_MDIA"]       # media data file           : '/srv/user/share/conf/_data/media.dat'
#   path_dstp = conf["PATH_DSTP"]       # debstrap data file        : '/srv/user/share/conf/_data/debstrap.dat'

# --- pre-configuration file templates ----------------------------------------
#   path_sedd = conf["PATH_SEDD"]       # for debian            : '/srv/user/share/conf/_template/preseed_debian.cfg'
#   path_sedu = conf["PATH_SEDU"]       # for ubuntu            : '/srv/user/share/conf/_template/preseed_ubuntu.cfg'
#   path_clud = conf["PATH_CLUD"]       # for ubuntu cloud-init : '/srv/user/share/conf/_template/user-data_ubuntu'
#   path_kick = conf["PATH_KICK"]       # for rhel              : '/srv/user/share/conf/_template/kickstart_rhel.cfg'
#   path_yast = conf["PATH_YAST"]       # for opensuse          : '/srv/user/share/conf/_template/yast_opensuse.xml'
#   path_agma = conf["PATH_AGMA"]       # for opensuse          : '/srv/user/share/conf/_template/agama_opensuse.json'

# --- shell script ------------------------------------------------------------
#   path_erly = conf["PATH_ERLY"]       # shell commands to run early           : '/srv/user/share/conf/script/autoinst_cmd_early.sh'
#   path_late = conf["PATH_LATE"]       # "              to run late            : '/srv/user/share/conf/script/autoinst_cmd_late.sh'
#   path_part = conf["PATH_PART"]       # "              to run after partition : '/srv/user/share/conf/script/autoinst_cmd_part.sh'
#   path_runs = conf["PATH_RUNS"]       # "              to run preseed/run     : '/srv/user/share/conf/script/autoinst_cmd_run.sh'

# --- tftp menu ---------------------------------------------------------------
#   path_ipxe = conf["PATH_IPXE"]       # ipxe              : '/srv/tftp/ipxe/autoexec.ipxe'
#   path_grub = conf["PATH_GRUB"]       # grub              : '/srv/tftp/boot/grub/grub.cfg'
#   path_slnx = conf["PATH_SLNX"]       # syslinux (bios)   : '/srv/tftp/menu-bios/syslinux.cfg'
#   path_ef64 = conf["PATH_EF64"]       # syslinux (efi64)  : '/srv/tftp/menu-efi64/syslinux.cfg'

# --- tftp / nbd --------------------------------------------------------------
#   dirs_nbds = conf["DIRS_NBDS"]       # nbd exports   : '/etc/nbd-server/conf.d'
#   path_nbds = conf["PATH_NBDS"]       # nbd exports   : '/etc/nbd-server/conf.d/exports.conf'

# --- live media parameter ----------------------------------------------------
#   dirs_live = conf["DIRS_LIVE"]       # LiveOS / live : 'LiveOS'
#   dirs_mntp = conf["DIRS_MNTP"]       # mount point   : 'mntp'
#   dirs_rtfs = conf["DIRS_RTFS"]       # root image    : 'rtfs'
#   dirs_cdfs = conf["DIRS_CDFS"]       # cdfs image    : 'cdfs'
#   path_vlnz = conf["PATH_VLNZ"]       # kernel        : ''
#   path_iram = conf["PATH_IRAM"]       # initramfs     : ''
#   path_spls = conf["PATH_SPLS"]       # splash.png    : '/boot/grub/splash.png'
