# --- python library ----------------------------------------------------------
import os
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    cat,
    debug_logger,
    delpath,
    find_serivce,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    message_info,
    restart_service,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def setup_dnsmasq(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _srvc_name: str = "dnsmasq.service"
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
    if not _srvc_path or not _srvc_path.exists():
        message_info(_caller, f"{'skip':<10}:dnsmasq", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:dnsmasq", omit=True)
        file_backup(info_syst=info_syst, orig_path=_srvc_path)
        file_origin(info_syst=info_syst, orig_path=_srvc_path)
        _envs_list = os.environ.copy()
        _envs_list["_SRVC_PATH"] = str(_srvc_path)
        _shel_comd = r"""
            sed -e '/^\[Unit\]$/,/^\[.\+\]/                       {' \
                -e '/^Requires=/                            s/^/#/g' \
                -e '/^After=/                               s/^/#/g' \
                -e '/^Description=/a Requires=network-online.target' \
                -e '/^Description=/a After=network-online.target'    \
                -e '                                              }' \
                -i "${_SRVC_PATH:?}"
        """
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
        file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
        # --- dnsmasq ---------------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/default/dnsmasq"))
        if _conf_path.exists():
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            _shel_comd = r"""
                sed -e 's/^#\(IGNORE_RESOLVCONF\)=.*$/\1=yes/' \
                    -e 's/^#\(DNSMASQ_EXCEPT\)=.*$/\1="lo"/'   \
                    -i "${_SRVC_PATH:?}"
            """
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
        # --- default.conf ----------------------------------------------------
        _trst_text: str = ""
        for _dirs in ["/etc/dnsmasq.d", "/usr/share"]:
            _work_path: Path = Path(f"{_dirs}/trust-anchors.conf")
            _find_path: Path = addpath(base=_tget_path, path=_work_path)
            if _find_path.exists():
                _trst_text: str = str(delpath(base=_tget_path, path=_find_path))
                break
        _conf_path: Path = addpath(
            base=_tget_path, path=Path("/etc/dnsmasq.d/default.conf")
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _fmat_parm: str = "{:<60}{}"
        _writ_text: str = cat(rf"""
			# --- log ---------------------------------------------------------------------
			{_fmat_parm.format(r"#log-queries", r"# dns query log output")}
			{_fmat_parm.format(r"#log-dhcp", r"# dhcp transaction log output")}
			{_fmat_parm.format(r"#log-facility=", r"# log output file name")}
			
			# --- dns ---------------------------------------------------------------------
			{_fmat_parm.format(r"#port=0", r"# listening port")}
			{_fmat_parm.format(r"bogus-priv", r"# do not perform reverse lookup of private ip address on upstream server")}
			{_fmat_parm.format(r"domain-needed", r"# do not forward plain names")}
			{_fmat_parm.format(f"domain={_data.nwrk_wgrp}", r"# local domain name")}
			{_fmat_parm.format(r"expand-hosts", r"# add domain name to host")}
			{_fmat_parm.format(r"#filterwin2k", r"# filter for windows")}
			{_fmat_parm.format(f"interface={_data.nwrk_devs}", r"# listen to interface")}
			{_fmat_parm.format(f"listen-address={_data.ipv4_lhst}", r"# listen to ip address")}
			{_fmat_parm.format(f"#listen-address={_data.ipv6_lhst}", r"# listen to ip address")}
			{_fmat_parm.format(f"#listen-address={_data.ipv4_addr}", r"# listen to ip address")}
			{_fmat_parm.format(f"#listen-address={_data.link_addr}", r"# listen to ip address")}
			{_fmat_parm.format(f"server={_data.ipv4_nsvr}", r"# directly specify upstream server")}
			{_fmat_parm.format(r"#server=8.8.8.8", r"# directly specify upstream server")}
			{_fmat_parm.format(r"#server=8.8.4.4", r"# directly specify upstream server")}
			{_fmat_parm.format(r"no-hosts", r"# don't read the hostnames in /etc/hosts")}
			{_fmat_parm.format(r"no-poll", r"# don't poll /etc/resolv.conf for changes")}
			{_fmat_parm.format(r"no-resolv", r"# don't read /etc/resolv.conf")}
			{_fmat_parm.format(r"#strict-order", r"# try in the registration order of /etc/resolv.conf")}
			{_fmat_parm.format(r"bind-dynamic", r"# enable bind-interfaces and the default hybrid network mode")}
			{_fmat_parm.format(r"#bind-interfaces", r"# enable multiple instances of dnsmasq")}
			{_fmat_parm.format(f"#conf-file={_trst_text}", r"# enable dnssec validation and caching")}
			{_fmat_parm.format(r"#dnssec", r'# "')}
			
			# --- dhcp --------------------------------------------------------------------
			{_fmat_parm.format(f"dhcp-range={_data.ipv4_uadr}.0,proxy,24", r"# proxy dhcp")}
			{_fmat_parm.format(f"dhcp-range={_data.ipv4_uadr}.64,{_data.ipv4_uadr}.79,12h", r"# dhcp range")}
			{_fmat_parm.format(r"#dhcp-option=option:netmask,255.255.255.0", r"#  1 netmask")}
			{_fmat_parm.format(f"#dhcp-option=option:router,{_data.ipv4_gway}", r"#  3 router")}
			{_fmat_parm.format(f"#dhcp-option=option:dns-server,{_data.ipv4_addr},{_data.ipv4_gway}", r"#  6 dns-server")}
			{_fmat_parm.format(f"#dhcp-option=option:domain-name,{_data.nwrk_wgrp}", r"# 15 domain-name")}
			{_fmat_parm.format(f"#dhcp-option=option:28,{_data.ipv4_uadr}.255", r"# 28 broadcast")}
			{_fmat_parm.format(f"#dhcp-option=option:ntp-server,{_data.ntps_ipv4}", r"# 42 ntp-server")}
			{_fmat_parm.format(f"#dhcp-option=option:tftp-server,{_data.ipv4_addr}", r"# 66 tftp-server")}
			{_fmat_parm.format(r"#dhcp-option=option:bootfile-name,", r"# 67 bootfile-name")}
			{_fmat_parm.format(r"dhcp-no-override", r"# disable re-use of the dhcp servername and filename fields as extra option space")}
			{_fmat_parm.format(r"dhcp-reply-delay=1", r"# ")}
			
			# --- dnsmasq manual page -----------------------------------------------------
			# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
			
			# --- eof ---------------------------------------------------------------------
		""")  # noqa: E501
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        if _data.ipv4_auto:
            _envs_list["_CONF_PATH"] = str(_conf_path)
            _shel_comd = r"""
                sed -e '/^interface=/ s/^/#/g' \
                    -i "${_CONF_PATH:?}"
            """
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- pxeboot.conf ----------------------------------------------------
        _conf_path: Path = addpath(
            base=_tget_path, path=Path("/etc/dnsmasq.d/pxeboot.conf")
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _fmat_parm: str = "{:<60}{}"
        _writ_text: str = cat(rf"""
			{_fmat_parm.format(r"#log-queries", r"# dns query log output")}
			{_fmat_parm.format(r"#log-dhcp", r"# dhcp transaction log output")}
			{_fmat_parm.format(r"#log-facility=", r"# log output file name")}
			
			# --- tftp --------------------------------------------------------------------
			{_fmat_parm.format(f"#enable-tftp={_data.nwrk_devs}", r"# enable tftp server")}
			{_fmat_parm.format(f"#tftp-root={str(_data.tftp_path)}", r"# tftp root directory")}
			{_fmat_parm.format(r"#tftp-lowercase", r"# convert tftp request path to all lowercase")}
			{_fmat_parm.format(r"#tftp-no-blocksize", r'# stop negotiating "block size" option')}
			{_fmat_parm.format(r"#tftp-no-fail", r"# do not abort startup even if tftp directory is not accessible")}
			{_fmat_parm.format(r"#tftp-secure", r"# enable tftp secure mode")}
			
		""")  # noqa: E501
        _fmat_parm: str = "{:<88}{}"
        _writ_text += cat(rf"""
			# --- syslinux block ----------------------------------------------------------
			{_fmat_parm.format(r'#pxe-prompt="Press F8 for boot menu", 0', r"# pxe boot prompt")}
			{_fmat_parm.format(r'#pxe-service=x86PC            , "PXEBoot-x86PC"            , menu-bios/lpxelinux.0', r"#  0 Intel x86PC")}
			{_fmat_parm.format(r'#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , menu-efi64/syslinux.efi', r"#  7 EFI BC")}
			{_fmat_parm.format(r'#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , menu-efi64/syslinux.efi', r"#  9 EFI x86-64")}
			
			# --- grub block --------------------------------------------------------------
			{_fmat_parm.format(r'#pxe-prompt="Press F8 for boot menu", 0', r"# pxe boot prompt")}
			{_fmat_parm.format(r'#pxe-service=x86PC            , "PXEBoot-x86PC"            , boot/grub/pxelinux.0', r"#  0 Intel x86PC")}
			{_fmat_parm.format(r'#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , boot/grub/bootnetx64.efi', r"#  7 EFI BC")}
			{_fmat_parm.format(r'#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , boot/grub/bootnetx64.efi', r"#  9 EFI x86-64")}
			
			# --- ipxe block --------------------------------------------------------------
			{_fmat_parm.format(r"#dhcp-match=set:iPXE,175", r"#")}
			{_fmat_parm.format(r'#pxe-prompt="Press F8 for boot menu", 0', r"# pxe boot prompt")}
			{_fmat_parm.format(r'#pxe-service=tag:iPXE ,x86PC  , "PXEBoot-x86PC"            , ipxe/autoexec.ipxe', r"#  0 Intel x86PC (iPXE)")}
			{_fmat_parm.format(r'#pxe-service=tag:!iPXE,x86PC  , "PXEBoot-x86PC"            , ipxe/undionly.kpxe', r"#  0 Intel x86PC")}
			{_fmat_parm.format(r'#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , ipxe/ipxe.efi', r"#  7 EFI BC")}
			{_fmat_parm.format(r'#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , ipxe/ipxe.efi', r"#  9 EFI x86-64")}
			{_fmat_parm.format(r'#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           , ipxe/ipxe-legacy.efi', r"#  7 EFI BC     (non usb network driver)")}
			{_fmat_parm.format(r'#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       , ipxe/ipxe-legacy.efi', r"#  9 EFI x86-64 (non usb network driver)")}
			
			# --- pxe boot ----------------------------------------------------------------
			{_fmat_parm.format(r'#pxe-prompt="Press F8 for boot menu", 0', r"# pxe boot prompt")}
			{_fmat_parm.format(r'#pxe-service=x86PC            , "PXEBoot-x86PC"            ,', r"#  0 Intel x86PC")}
			{_fmat_parm.format(r'#pxe-service=PC98             , "PXEBoot-PC98"             ,', r"#  1 NEC/PC98")}
			{_fmat_parm.format(r'#pxe-service=IA64_EFI         , "PXEBoot-IA64_EFI"         ,', r"#  2 EFI Itanium")}
			{_fmat_parm.format(r'#pxe-service=Alpha            , "PXEBoot-Alpha"            ,', r"#  3 DEC Alpha")}
			{_fmat_parm.format(r'#pxe-service=Arc_x86          , "PXEBoot-Arc_x86"          ,', r"#  4 Arc x86")}
			{_fmat_parm.format(r'#pxe-service=Intel_Lean_Client, "PXEBoot-Intel_Lean_Client",', r"#  5 Intel Lean Client")}
			{_fmat_parm.format(r'#pxe-service=IA32_EFI         , "PXEBoot-IA32_EFI"         ,', r"#  6 EFI IA32")}
			{_fmat_parm.format(r'#pxe-service=BC_EFI           , "PXEBoot-BC_EFI"           ,', r"#  7 EFI BC")}
			{_fmat_parm.format(r'#pxe-service=Xscale_EFI       , "PXEBoot-Xscale_EFI"       ,', r"#  8 EFI Xscale")}
			{_fmat_parm.format(r'#pxe-service=x86-64_EFI       , "PXEBoot-x86-64_EFI"       ,', r"#  9 EFI x86-64")}
			{_fmat_parm.format(r'#pxe-service=ARM32_EFI        , "PXEBoot-ARM32_EFI"        ,', r"# 10 ARM 32bit")}
			{_fmat_parm.format(r'#pxe-service=ARM64_EFI        , "PXEBoot-ARM64_EFI"        ,', r"# 11 ARM 64bit")}
			
			# --- dnsmasq manual page -----------------------------------------------------
			# https://thekelleys.org.uk/dnsmasq/docs/dnsmasq-man.html
			
			# --- eof ---------------------------------------------------------------------
		""")  # noqa: E501
        fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- dnsmasq.conf ----------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/dnsmasq.conf"))
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _dirs_path: Path = addpath(base="", path=Path("/etc/dnsmasq.d"))
        _envs_list["_DIRS_PATH"] = str(_dirs_path)
        _shel_comd = r"""
            cat "${_DIRS_PATH:?}"/*          | \
            sed -ne '/^[^#]/              {'   \
                -e  's/#.*$//g             '   \
                -e  's/^\([^=]\+=\).*$/\1/g'   \
                -e  's/ \+$//g             '   \
                -e  'p                    }' | \
            sed -e ':l; N; s/[\r\n]\+/\\|/; b l' || true \
        """
        _find_parm: str = ""
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
        elif _result.stdout:
            _find_parm: str = str(_result.stdout).strip("\n").strip() + r"\|"
        _find_parm += r"bind-dynamic\|bind-interfaces"
        _envs_list["_FIND_PARM"] = _find_parm
        _envs_list["_CONF_PATH"] = _conf_path
        _shel_comd = r"""
            sed -e '/^\('"${_FIND_PARM:?}"'\)/ s/^/#/g' \
                -i "${_CONF_PATH:?}"
        """
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
        file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- service restart -------------------------------------------------
        if not info_syst.data.tget_chrt:
            restart_service(srvc_name=_srvc_name)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
