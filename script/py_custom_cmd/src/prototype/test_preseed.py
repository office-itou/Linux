#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
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
            info_conf, info_dist, info_mdia = initialize()  # noqa: RUF059
            # path_dist = info_conf.get_path(key="PATH_DIST")
            # path_mdia = info_conf.get_path(key="PATH_MDIA")
            dirs_rmak = info_conf.get_path("DIRS_RMAK")
            for data_mdia in info_mdia.data:
                if data_mdia.cfg_path:
                    path_psed = Path(data_mdia.cfg_path)
                    # print(f"path_psed:{path_psed}")
                    preseed = (
                        ""
                        if data_mdia.cfg_path.endswith("/")
                        else path_psed.parent.name
                    )
                    if preseed and data_mdia.iso_path:
                        path_isos = Path(data_mdia.iso_path).resolve()
                        # print(f"path_isos:{path_isos}")
                        # path_rmak = Path(data_mdia.rmk_path).resolve()
                        path_file = (
                            dirs_rmak / f"{path_isos.stem}_{preseed}{path_isos.suffix}"
                        )
                        # print(f"path_file:{path_file}")
                        data_mdia.rmk_path = str(path_file.resolve())
                        print(f"rmak_path:{data_mdia.rmk_path}")

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
