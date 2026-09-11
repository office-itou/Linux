#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))
from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import InfoDistribution
from common.shared.my_media_dat import InfoMedia
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_error import handle_fatal_error
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)


@debug_logger
def initialize() -> tuple[InfoConfiguration, InfoDistribution, InfoMedia]:
    """Initialize

    Returns:
        tuple[InfoConfiguration, InfoDistribution, InfoMedia]: info_conf, info_dist, info_mdia
    """
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.get_path(key="PATH_DIST")
    path_mdia = info_conf.get_path(key="PATH_MDIA")
    info_dist = InfoDistribution(path_dist.with_name(path_dist.name + ".json"))
    info_mdia = InfoMedia(path_mdia.with_name(path_mdia.name + ".json"), info_conf)
    # -------------------------------------------------------------------------
    return info_conf, info_dist, info_mdia


@debug_logger
def initarg() -> None:
    arg_manager = Argument()
    list_args = []
    for line_arg in list_args:
        arg_name = line_arg.pop("arg")
        arg_manager.add(arg_name, **line_arg)
    infosystem.args = arg_manager.parse()


@debug_logger
def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user --------------------------------------------
        if os.geteuid() != 0:
            print(
                f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n{Color.br_yellow} You have standard user privileges. {Color.underline}Please run this with sudo.{Color.reset}"
            )
            sys.exit(1)
        # --- elapsed start--------------------------------------------------------
        start = time.perf_counter()
        # --- startup process -----------------------------------------------------
        message_start(get_caller_name())
        # --- processing block ----------------------------------------------------
        initarg()
        if infosystem.args:
            info_conf, info_dist, info_mdia = initialize()
            path_dist = info_conf.get_path(key="PATH_DIST")
            path_mdia = info_conf.get_path(key="PATH_MDIA")

            # for data_mdia in info_mdia.data:
            #    preseed = re.sub(r"^.+/(.+)/.*$", r"\1", data_mdia.cfg_path)
            #    print(
            #        data_mdia.cfg_path,
            #        preseed,
            #    )

            for cfg_path in [
                "/srv/user/share/conf/agama/autoinst_leap-16.0.json",
                "/srv/user/share/conf/agama/autoinst_leap-16.1.json",
                "/srv/user/share/conf/autoyast/autoinst_leap-15.6_dvd.xml",
                "/srv/user/share/conf/autoyast/autoinst_leap-15.6_net.xml",
                "/srv/user/share/conf/autoyast/autoinst_tumbleweed_dvd.xml",
                "/srv/user/share/conf/autoyast/autoinst_tumbleweed_net.xml",
                "/srv/user/share/conf/kickstart/ks_almalinux-9_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_almalinux-9_net.cfg",
                "/srv/user/share/conf/kickstart/ks_almalinux-10_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_almalinux-10_net.cfg",
                "/srv/user/share/conf/kickstart/ks_centos-stream-9_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_centos-stream-9_net.cfg",
                "/srv/user/share/conf/kickstart/ks_centos-stream-10_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_centos-stream-10_net.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-40_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-40_net.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-41_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-41_net.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-42_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-42_net.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-43_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-43_net.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-44_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_fedora-44_net.cfg",
                "/srv/user/share/conf/kickstart/ks_miraclelinux-9_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_miraclelinux-9_net.cfg",
                "/srv/user/share/conf/kickstart/ks_rockylinux-9_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_rockylinux-9_net.cfg",
                "/srv/user/share/conf/kickstart/ks_rockylinux-10_dvd.cfg",
                "/srv/user/share/conf/kickstart/ks_rockylinux-10_net.cfg",
                "/srv/user/share/conf/kickstart/",
                "/srv/user/share/conf/nocloud/ubuntu_desktop",
                "/srv/user/share/conf/nocloud/ubuntu_desktop_old",
                "/srv/user/share/conf/nocloud/ubuntu_server",
                "/srv/user/share/conf/nocloud/ubuntu_server_oldold",
                "/srv/user/share/conf/nocloud/ubuntu_server_old",
                "/srv/user/share/conf/nocloud/",
                "/srv/user/share/conf/preseed/ps_debian_desktop.cfg",
                "/srv/user/share/conf/preseed/ps_debian_desktop_oldold.cfg",
                "/srv/user/share/conf/preseed/ps_debian_desktop_old.cfg",
                "/srv/user/share/conf/preseed/ps_debian_server.cfg",
                "/srv/user/share/conf/preseed/ps_debian_server_oldold.cfg",
                "/srv/user/share/conf/preseed/ps_debian_server_old.cfg",
                "/srv/user/share/conf/preseed/ps_ubiquity_desktop_old.cfg",
                "/srv/user/share/conf/preseed/ps_ubuntu_server_old.cfg",
                "/srv/user/share/conf/preseed/",
            ]:
                preseed = re.sub(r"^.+/(.+)/.*$", r"\1", cfg_path)
                print(preseed)

        # --- termination process -------------------------------------------------
        message_end(get_caller_name())
        # --- elapsed end ---------------------------------------------------------
        end = time.perf_counter()
        elapsed = end - start
        message_elapsed(get_caller_name(), elapsed)
        # --- exit ----------------------------------------------------------------
        sys.exit(0)
        # -------------------------------------------------------------------------
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
