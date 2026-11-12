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
from autoinst_fn_initialize import initialize


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
    # setup_wireplumber(info_syst=_info_syst)
    # get_conf_file(info_syst=_info_syst)
    # --- initial setup -------------------------------------------------------
    #fnInitialize						# initialize
    #fnDbgparam							# parameter debug output
    #fnPackage_update					# package updates
    #fnPackage_install					# package install
    #fnMkdir_share						# creating a shared directory
    # --- network manager -----------------------------------------------------
    #fnSetup_connman						# connman
    #fnSetup_netplan						# netplan
    #fnSetup_netman						# network manager
    # --- application setup ---------------------------------------------------
    #fnSetup_hostname					# hostname
    #fnSetup_hosts						# hosts
    #fnSetup_tcp_wrapper					# tcp wrapper
    #fnSetup_firewalld					# firewalld
    #fnSetup_dnsmasq						# dnsmasq
    #fnSetup_resolv						# resolv.conf
    #	#fnSetup_clamav						# clamav
    #fnSetup_apache						# apache
    #fnSetup_samba						# samba
    #fnSetup_timesyncd					# timesyncd
    #fnSetup_chronyd						# chronyd
    #fnSetup_ssh							# openssh-server
    #fnSetup_nfs							# nfs
    #fnSetup_nbd							# nbd
    #fnSetup_vmware						# vmware shared directory
    #fnSetup_wireplumber					# wireplumber
    #fnSetup_input_method				# input method
    #fnSetup_locale						# locale
    #fnSetup_desktop						# desktop
    #fnSetup_skel_user					# skeleton for user environment
    #fnSetup_skel_im						# input method skeleton
    #fnSetup_skel_copy					# copy skeleton to user
    #fnSetup_dconf						# dconf
    #fnSetup_sudo						# sudoers
    #fnSetup_blacklist					# blacklist
    #fnSetup_module_ipxe					# ipxe module
    #fnSetup_apparmor					# apparmor
    #fnSetup_selinux						# selinux
    #fnSetup_ipfilter					# ipfilter
    #fnSetup_service						# service
    # --- booting setup -------------------------------------------------------
    #fnSetup_grub_menu					# grub menu settings
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
