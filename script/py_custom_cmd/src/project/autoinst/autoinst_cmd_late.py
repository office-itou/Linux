#!/usr/bin/env python3
# --- python library ----------------------------------------------------------
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
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

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_fn_network import network_param
from autoinst_fn_setup_apache import setup_apache
from autoinst_fn_setup_apparmor import setup_apparmor
from autoinst_fn_setup_blacklist import setup_blacklist
from autoinst_fn_setup_chronyd import setup_chronyd
from autoinst_fn_setup_clamav import setup_clamav
from autoinst_fn_setup_dconf import setup_dconf
from autoinst_fn_setup_desktop import setup_desktop
from autoinst_fn_setup_dnsmasq import setup_dnsmasq
from autoinst_fn_setup_firewalld import setup_firewalld
from autoinst_fn_setup_grub_menu import setup_grub_menu
from autoinst_fn_setup_hostname import setup_hostname
from autoinst_fn_setup_hosts import setup_hosts
from autoinst_fn_setup_input_method import setup_input_method
from autoinst_fn_setup_ipfilter import setup_ipfilter
from autoinst_fn_setup_locale import setup_locale
from autoinst_fn_setup_module_ipxe import setup_module_ipxe
from autoinst_fn_setup_nbd import setup_nbd
from autoinst_fn_setup_nfs import setup_nfs
from autoinst_fn_setup_resolv import setup_resolv
from autoinst_fn_setup_samba import setup_samba
from autoinst_fn_setup_selinux import setup_selinux
from autoinst_fn_setup_service import setup_service
from autoinst_fn_setup_skel_copy import setup_skel_copy
from autoinst_fn_setup_skel_im import setup_skel_im
from autoinst_fn_setup_skel_user import setup_skel_user
from autoinst_fn_setup_ssh import setup_ssh
from autoinst_fn_setup_sudo import setup_sudo
from autoinst_fn_setup_tcp_wrapper import setup_tcp_wrapper
from autoinst_fn_setup_timesyncd import setup_timesyncd
from autoinst_fn_setup_vmware import setup_vmware

from autoinst_fn_initialize import initialize
from autoinst_fn_mkdir_share import mkdir_share
from autoinst_fn_package_install import package_install
from autoinst_fn_package_update import package_update
from autoinst_fn_setup_connman import setup_connman
from autoinst_fn_setup_netman import setup_netman
from autoinst_fn_setup_netplan import setup_netplan
from autoinst_fn_setup_wireplumber import setup_wireplumber


# --- initialize --------------------------------------------------------------
# --- main --------------------------------------------------------------------
@debug_logger
def main() -> None:
    """Main"""
    _caller = get_caller_name()
    _info_syst = initialize()
    _info_syst = network_param(info_syst=_info_syst)
    _info_syst.debug(debugout=bool(_info_syst.data.dout_flag or infosystem.debugout))
    _info_syst.print_info(
        debugout=not bool(_info_syst.data.dout_flag or infosystem.debugout)
    )
    # --- initial setup -------------------------------------------------------
    package_update(_info_syst)  # package updates
    package_install(_info_syst)  # package install
    mkdir_share(_info_syst)  # creating a shared directory
    # --- network manager -----------------------------------------------------
    setup_connman(_info_syst)  # connman
    setup_netplan(_info_syst)  # netplan
    setup_netman(_info_syst)  # network manager
    # --- application setup ---------------------------------------------------
    setup_hostname(_info_syst)  # hostname
    setup_hosts(_info_syst)  # hosts
    setup_tcp_wrapper(_info_syst)  # tcp wrapper
    setup_firewalld(_info_syst)  # firewalld
    setup_dnsmasq(_info_syst)  # dnsmasq
    setup_resolv(_info_syst)  # resolv.conf
    setup_clamav(_info_syst)  # clamav
    setup_apache(_info_syst)  # apache
    setup_samba(_info_syst)  # samba
    setup_timesyncd(_info_syst)  # timesyncd
    setup_chronyd(_info_syst)  # chronyd
    setup_ssh(_info_syst)  # openssh-server
    setup_nfs(_info_syst)  # nfs
    setup_nbd(_info_syst)  # nbd
    setup_vmware(_info_syst)  # vmware shared directory
    setup_wireplumber(_info_syst)  # wireplumber
    setup_input_method(_info_syst)  # input method
    setup_locale(_info_syst)  # locale
    setup_desktop(_info_syst)  # desktop
    setup_skel_user(_info_syst)  # skeleton for user environment
    setup_skel_im(_info_syst)  # input method skeleton
    setup_skel_copy(_info_syst)  # copy skeleton to user
    setup_dconf(_info_syst)  # dconf
    setup_sudo(_info_syst)  # sudoers
    setup_blacklist(_info_syst)  # blacklist
    setup_module_ipxe(_info_syst)  # ipxe module
    setup_apparmor(_info_syst)  # apparmor
    setup_selinux(_info_syst)  # selinux
    setup_ipfilter(_info_syst)  # ipfilter
    setup_service(_info_syst)  # service
    # --- booting setup -------------------------------------------------------
    setup_grub_menu(_info_syst)  # grub menu settings
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
