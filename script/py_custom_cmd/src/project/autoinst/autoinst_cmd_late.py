#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.shared import (
    proc_comp,
    proc_init,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    infosystem,
)

# --- import module -----------------------------------------------------------
# from autoinst_fn_initialize import initialize
# from autoinst_fn_package_update import package_update
# from autoinst_fn_package_install import package_install
# from autoinst_fn_mkdir_share import mkdir_share
# from autoinst_fn_setup_connman import setup_connman
# from autoinst_fn_setup_netplan import setup_netplan
# from autoinst_fn_setup_netman import setup_netman
# from autoinst_fn_setup_hostname import setup_hostname
# from autoinst_fn_setup_hosts import setup_hosts
# from autoinst_fn_setup_tcp_wrapper import setup_tcp_wrapper
# from autoinst_fn_setup_firewalld import setup_firewalld
# from autoinst_fn_setup_dnsmasq import setup_dnsmasq
# from autoinst_fn_setup_resolv import setup_resolv
# from autoinst_fn_setup_clamav import setup_clamav
# from autoinst_fn_setup_apache import setup_apache
# from autoinst_fn_setup_samba import setup_samba
# from autoinst_fn_setup_timesyncd import setup_timesyncd
# from autoinst_fn_setup_chronyd import setup_chronyd
# from autoinst_fn_setup_ssh import setup_ssh
# from autoinst_fn_setup_nfs import setup_nfs
# from autoinst_fn_setup_nbd import setup_nbd
# from autoinst_fn_setup_vmware import setup_vmware
# from autoinst_fn_setup_wireplumber import setup_wireplumber
# from autoinst_fn_setup_input_method import setup_input_method
# from autoinst_fn_setup_locale import setup_locale
# from autoinst_fn_setup_desktop import setup_desktop
# from autoinst_fn_setup_skel_user import setup_skel_user
# from autoinst_fn_setup_skel_im import setup_skel_im
# from autoinst_fn_setup_skel_copy import setup_skel_copy
# from autoinst_fn_setup_dconf import setup_dconf
# from autoinst_fn_setup_sudo import setup_sudo
# from autoinst_fn_setup_blacklist import setup_blacklist
# from autoinst_fn_setup_module_ipxe import setup_module_ipxe
# from autoinst_fn_setup_apparmor import setup_apparmor
# from autoinst_fn_setup_selinux import setup_selinux
# from  import setup_ipfilter
# from  import setup_service
# from  import setup_grub_menu
from project.autoinst import (
    initialize,
    mkdir_share,
    package_install,
    package_update,
    setup_apache,
    setup_apparmor,
    setup_blacklist,
    setup_chronyd,
    setup_clamav,
    setup_connman,
    setup_dconf,
    setup_desktop,
    setup_dnsmasq,
    setup_firewalld,
    setup_grub_menu,
    setup_hostname,
    setup_hosts,
    setup_input_method,
    setup_ipfilter,
    setup_locale,
    setup_module_ipxe,
    setup_nbd,
    setup_netman,
    setup_netplan,
    setup_nfs,
    setup_resolv,
    setup_samba,
    setup_selinux,
    setup_service,
    setup_skel_copy,
    setup_skel_im,
    setup_skel_user,
    setup_ssh,
    setup_sudo,
    setup_tcp_wrapper,
    setup_timesyncd,
    setup_vmware,
    setup_wireplumber,
)


# --- class and function ------------------------------------------------------
# --- initialize --------------------------------------------------------------
# --- main --------------------------------------------------------------------
@debug_logger
def main() -> None:
    """Main"""
    _caller = get_caller_name()
    _info_syst = initialize()
    # _info_syst = network_param(info_syst=_info_syst)
    _info_syst.debug(debugout=bool(_info_syst.data.dout_flag or infosystem.debugout))
    _info_syst.print_info(
        debugout=not bool(_info_syst.data.dout_flag or infosystem.debugout)
    )
    # --- initial setup -------------------------------------------------------
    package_update(info_syst=_info_syst)  # package updates
    package_install(info_syst=_info_syst)  # package install
    mkdir_share(info_syst=_info_syst)  # creating a shared directory
    # --- network manager -----------------------------------------------------
    setup_connman(info_syst=_info_syst)  # connman
    setup_netplan(info_syst=_info_syst)  # netplan
    setup_netman(info_syst=_info_syst)  # network manager
    # --- application setup ---------------------------------------------------
    setup_hostname(info_syst=_info_syst)  # hostname
    setup_hosts(info_syst=_info_syst)  # hosts
    setup_tcp_wrapper(info_syst=_info_syst)  # tcp wrapper
    setup_firewalld(info_syst=_info_syst)  # firewalld
    setup_dnsmasq(info_syst=_info_syst)  # dnsmasq
    setup_resolv(info_syst=_info_syst)  # resolv.conf
    setup_clamav(info_syst=_info_syst)  # clamav
    setup_apache(info_syst=_info_syst)  # apache
    setup_samba(info_syst=_info_syst)  # samba
    setup_timesyncd(info_syst=_info_syst)  # timesyncd
    setup_chronyd(info_syst=_info_syst)  # chronyd
    setup_ssh(info_syst=_info_syst)  # openssh-server
    setup_nfs(info_syst=_info_syst)  # nfs
    setup_nbd(info_syst=_info_syst)  # nbd
    setup_vmware(info_syst=_info_syst)  # vmware shared directory
    setup_wireplumber(info_syst=_info_syst)  # wireplumber
    setup_input_method(info_syst=_info_syst)  # input method
    setup_locale(info_syst=_info_syst)  # locale
    setup_desktop(info_syst=_info_syst)  # desktop
    setup_skel_user(info_syst=_info_syst)  # skeleton for user environment
    setup_skel_im(info_syst=_info_syst)  # input method skeleton
    setup_skel_copy(info_syst=_info_syst)  # copy skeleton to user
    setup_dconf(info_syst=_info_syst)  # dconf
    setup_sudo(info_syst=_info_syst)  # sudoers
    setup_blacklist(info_syst=_info_syst)  # blacklist
    setup_module_ipxe(info_syst=_info_syst)  # ipxe module
    setup_apparmor(info_syst=_info_syst)  # apparmor
    setup_selinux(info_syst=_info_syst)  # selinux
    setup_ipfilter(info_syst=_info_syst)  # ipfilter
    setup_service(info_syst=_info_syst)  # service
    # --- booting setup -------------------------------------------------------
    setup_grub_menu(info_syst=_info_syst)  # grub menu settings
    # --- success -------------------------------------------------------------
    _stat_name: str = f"{_info_syst.data.prog_name}.success"
    _stat_path: Path = _info_syst.data.acmd_path / _stat_name
    if _stat_path.exists() and _stat_path.is_dir():
        _stat_path.rmdir()
    _stat_path.mkdir(parents=True, exist_ok=True)


if __name__ == "__main__":
    # --- initialization ------------------------------------------------------
    _caller = get_caller_name()
    try:
        proc_init(
            description="autoinst late command",
            list_args=[],
            caller=_caller,
            is_gui=False,
        )
        # --- processing block ------------------------------------------------
        if infosystem.args:
            main()
        # --- complete --------------------------------------------------------
        proc_comp(caller=_caller)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
# --- eof ---------------------------------------------------------------------
