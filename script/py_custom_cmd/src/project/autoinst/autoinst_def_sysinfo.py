# --- python library ----------------------------------------------------------
from dataclasses import dataclass, field
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    IpAddressData,
    infosystem,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@dataclass
class SystemData:
    prog_path: Path = field(
        default_factory=lambda: infosystem.program_path
    )  # program name
    prog_name: str = field(
        default_factory=lambda: infosystem.program_name
    )  # program name
    # --- debug ---------------------------------------------------------------
    dbgs_flag: bool | None = None  # debug flag
    dout_flag: bool | None = None  # debug out flag
    # --- distribution --------------------------------------------------------
    dist_name: str | None = None  # distribution name (ex. debian)
    dist_vers: str | None = None  # version           (ex. testing)
    dist_code: str | None = None  # code name         (ex. testing)
    # --- target machine ------------------------------------------------------
    tget_virt: str | None = None  # virtualization (ex. vmware)
    tget_chrt: str | None = None  # is chgroot     (empty: none, else: chroot)
    tget_cntr: str | None = None  # is container   (empty: none, else: container)
    # --- parameter -----------------------------------------------------------
    parm_root: str | None = None  # environmental variables: root
    parm_secu: str | None = None  # "                      : security
    parm_armo: str | None = None  # "                      : apparmor
    parm_slnx: str | None = None  # "                      : selinux
    # --- directory / file ----------------------------------------------------
    tget_dirs: list[Path] = field(
        default_factory=lambda: [Path("/target"), Path("/mnt/sysimage"), Path("/mnt")]
    )
    tget_path: Path | None = None  # target dir     (ex. /target)
    tget_urls: str | None = None  # target dir     (ex. /target)
    isou_path: Path | None = None  # iso file name
    isou_urls: str | None = None  # iso file name
    # --- samba ---------------------------------------------------------------
    nlin_dirs: list[Path] = field(
        default_factory=lambda: [Path("/usr/sbin/nologin"), Path("/sbin/nologin")]
    )
    nlin_path: Path | None = None
    samb_user: str = "sambauser"  # force user
    samb_grup: str = "sambashare"  # force group
    samb_gadm: str = "sambaadmin"  # admin group
    samb_nssw: list[str] = field(
        default_factory=lambda: [
            "wins",
            "mdns_minimal",
            "mdns4_minimal",
            "[NOTFOUND=return]",
            "resolve",
            "[!UNAVAIL=return]",
            "dns",
            "mdns6",
            "mdns4",
        ]
    )  # nsswitch.conf
    # --- firewalld -----------------------------------------------------------
    fwal_zone: str = "home_use"  # firewalld default zone
    fwal_name: list[str] = field(
        default_factory=lambda: [
            "dhcp",
            "dhcpv6",
            "dhcpv6-client",
            "dns",
            "http",
            "https",
            "mdns",
            "nbd",
            "nfs",
            "proxy-dhcp",
            "samba",
            "samba-client",
            "ssh",
            "tftp",
        ]
    )  # firewalld service name
    fwal_port: list[str] = field(
        default_factory=lambda: ["0-65535/tcp", "0-65535/udp"]
    )  # firewalld port
    # --- preseed -------------------------------------------------------------
    seed_path: Path | None = None  # preseed file name
    seed_urls: str | None = None  # preseed file name
    # --- network: nic configuration settings ---------------------------------
    nics_path: Path | None = None  # path (/sys/devices/**/net/{name})
    nics_name: str | None = None  # nic if name     (ex. ens160)
    nics_madr: str | None = None  # "   if mac      (ex. 00:00:00:00:00:00)
    nics_gway: str | None = None  # "   gateway     (ex. 192.168.1.254)
    nics_nsvr: str | None = None  # "   nameserver  (ex. 192.168.1.254)
    nics_fqdn: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nics_host: str | None = None  # hostname        (ex. sv-server)
    nics_wgrp: str | None = None  # domain          (ex. workgroup)
    nics_stat: str | None = None  # nic if status   (ex. "up" or else)
    nics_ipv4: IpAddressData = field(default_factory=lambda: IpAddressData())
    nics_ipv6: IpAddressData = field(default_factory=lambda: IpAddressData())
    nics_link: IpAddressData = field(default_factory=lambda: IpAddressData())
    # --- network parameter: localhost ----------------------------------------
    ipv6_lhst: str = "::1"  # ipv6 local host address
    ipv4_lhst: str = "127.0.0.1"  # ipv4 local host address
    ipv4_dumy: str = "127.0.1.1"  # ipv4 dummy address
    # --- network parameter: ntp server ---------------------------------------
    ntps_fbak: list[str] = field(
        default_factory=lambda: [
            "ntp1.jst.mfeed.ad.jp",
            "ntp2.jst.mfeed.ad.jp",
            "ntp3.jst.mfeed.ad.jp",
        ]
    )
    # --- network parameter: input value  -------------------------------------
    nwrk_devs: str | None = None  # network device  (ex. ens160)
    nwrk_fqdn: str | None = None  # hostname fqdn   (ex. sv-server.workgroup)
    nwrk_host: str | None = None  # hostname        (ex. sv-server)
    nwrk_wgrp: str | None = None  # domain          (ex. workgroup)
    nman_name: str | None = None  # network manager (ex. nm_config, ifupdown, loopback)
    ntps_addr: str | None = None  # ntp server      (ex. ntp.nict.jp)
    ntps_ipv4: str | None = None  # ntp ipv4 addr   (ex. 61.205.120.130)
    # --- network parameter: ipv4 ---------------------------------------------
    ipv4_auto: str | None = None  # dhcp            (ex. empty or dhcp)
    ipv4_addr: str | None = None  # address         (ex. 192.168.1.1)
    ipv4_prfx: str | None = None  # prefix len      (ex. 24)
    ipv4_cidr: str | None = None  # cidr            (ex. 192.168.1.1/24)
    ipv4_mask: str | None = None  # netmask         (ex. 255.255.255.0)
    ipv4_fadr: str | None = None  # full addr
    ipv4_uadr: str | None = None  # addr up         (ex. 192.168.1)
    ipv4_ladr: str | None = None  # addr low        (ex. 1)
    ipv4_radr: str | None = None  # reverse         (ex. 1.168.192)
    ipv4_gway: str | None = None  # gateway         (ex. 192.168.1.254)
    ipv4_nsvr: str | None = None  # nameserver      (ex. 192.168.1.254)
    # --- network parameter: ipv6 ---------------------------------------------
    ipv6_auto: str | None = None  # dhcp            (ex. empty or dhcp)
    ipv6_addr: str | None = None  # address         (ex. ::1)
    ipv6_prfx: str | None = None  # prefix len      (ex. 64)
    ipv6_cidr: str | None = None  # cidr            (ex. ::1/64)
    ipv6_mask: str | None = None  # netmask         (ex. ...)
    ipv6_fadr: str | None = None  # full addr       (ex. 0000:0000:....:0001)
    ipv6_uadr: str | None = None  # addr up         (ex. 0000:0000:0000:0000)
    ipv6_ladr: str | None = None  # addr low        (ex. 0000:0000:0000:0001)
    ipv6_radr: str | None = None  # reverse         (ex. ...)
    # --- network parameter: link ---------------------------------------------
    link_auto: str | None = None  # dhcp            (ex. empty or dhcp)
    link_addr: str | None = None  # address         (ex. fe80::1)
    link_prfx: str | None = None  # prefix len      (ex. 64)
    link_cidr: str | None = None  # cidr            (ex. fe80::/64)
    link_mask: str | None = None  # netmask         (ex. ...)
    link_fadr: str | None = None  # full addr       (ex. fe80:0000:....:0001)
    link_uadr: str | None = None  # addr up         (ex. fe80:0000:0000:0000)
    link_ladr: str | None = None  # addr low        (ex. 0000:0000:0000:0001)
    link_radr: str | None = None  # reverse         (ex. ...)
    # --- shared directory parameter ------------------------------------------
    tops_path: Path | None = None  # top of shared directory
    expo_path: Path | None = None  # exports
    hgfs_path: Path | None = None  # vmware shared
    html_path: Path | None = None  # html contents#
    samb_path: Path | None = None  # samba shared
    tftp_path: Path | None = None  # tftp contents
    user_path: Path | None = None  # user file
    pvat_path: Path | None = None  # private contents directory
    shar_path: Path | None = None  # shared contents directory
    conf_path: Path | None = None  # configuration file
    data_path: Path | None = None  # data file
    keys_path: Path | None = None  # keyring file
    mkos_path: Path | None = None  # mkosi configuration files
    tmpl_path: Path | None = None  # templates for various configuration files
    shel_path: Path | None = None  # shell script file
    imgs_path: Path | None = None  # iso file extraction destination
    isos_path: Path | None = None  # iso file
    load_path: Path | None = None  # load module
    rmak_path: Path | None = None  # remake file
    cach_path: Path | None = None  # cache file
    ctnr_path: Path | None = None  # container file
    chrt_path: Path | None = None  # container file (chroot)
    xnbd_path: Path | None = None  # exports (network block device)
    xnfs_path: Path | None = None  # exports (network file system)
    xsmb_path: Path | None = None  # exports (samba)
    # --- working directory parameter -----------------------------------------
    time_stmp: str | None = None  # time stamp
    # vadm_dirs: Path = field(
    #    default_factory=lambda: Path("/var/admin")
    # )  # top of admin working directory
    vadm_path: Path | None = None  # top of admin working directory
    acmd_path: Path | None = None  # auto-command working directory
    inst_path: Path | None = None  # auto-install working directory
    back_path: Path | None = None  # top of backup directory
    orig_path: Path | None = None  # original file directory
    init_path: Path | None = None  # initial file directory
    samp_path: Path | None = None  # sample file directory
    logs_path: Path | None = None  # log file directory
