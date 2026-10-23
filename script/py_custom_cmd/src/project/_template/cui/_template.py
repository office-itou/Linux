#!/usr/bin/env python3

"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import asyncio
import inspect
import os
import sys
import time
from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
from my_shared import InfoCommon
from my_argument import Argument
from my_colors import Color
from my_config import infosystem
from my_debug import debug_logger
from my_error import handle_fatal_error
from my_markdown import list2markdown
from my_mem_usage import print_peak_memory
from my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)


@debug_logger
def initialize():
    """Initialize"""
    caller = get_caller_name()
    if infosystem.debug == True:
        message_info(caller, "Debug mode on")
    if infosystem.debugout == True:
        message_info(caller, "Debugout mode on")
    message_info(caller, f"exec user:{infosystem.data.exec_user}")
    message_info(caller, f"home dir :{infosystem.data.home_dir}")
    # -------------------------------------------------------------------------
    return InfoCommon()


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "Get web information\n"
    arg_manager = Argument(description)
    list_args = [
        {
            "arg": "--md",
            "help": "json -> Markdown generate",
            "default": "",
            "type": "str",
        },
    ]
    if list_args:
        for line_arg in list_args:
            arg_name = line_arg.pop("arg")
            if isinstance(arg_name, tuple):
                arg_manager.add(*arg_name, **line_arg)
            else:
                arg_manager.add(arg_name, **line_arg)

    infosystem.args = arg_manager.parse()


def generate_md(dst_dir: str, info_comm: InfoCommon) -> None:
    """Generate markdown

    Args:
        dst_dir (str): Destination path
        info_comm (InfoCommon): InfoCommon interface class
    """
    caller = get_caller_name()
    message_info(caller, "Generate markdown")
    # -------------------------------------------------------------------------
    dest_path = Path(dst_dir) / "Readme_tbl_distribution.md"
    md_title = f"Distribution data({dest_path.name})"
    list_data = []
    for distribution in ORDERED_DISTRIBUTIONS:
        list_sort = info_comm.dist.sort(distribution, reverse=True)
        dict_list = [distribution]
        dict_list += [d.__dict__ if hasattr(d, "__dict__") else d for d in list_sort]
        list_data.append(dict_list)
    list2markdown(dest_path, md_title, list_data)
    # -------------------------------------------------------------------------
    info_comm.conf.markdown(
        Path(dst_dir) / "Readme_Configuration.md",
        f"Configuration data({info_comm.conf_path.name})",
    )
    # -------------------------------------------------------------------------
    info_comm.dist.markdown(
        Path(dst_dir) / "Readme_Distribution.md",
        f"Distribution data({info_comm.dist_path.name})",
    )
    # -------------------------------------------------------------------------
    info_comm.mdia.markdown(
        Path(dst_dir) / "Readme_Media.md",
        f"Media data({info_comm.mdia_path.name})",
    )


@debug_logger
def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if os.geteuid() != 0:
            print(
                f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
                f"{Color.br_yellow} You have standard user privileges. "
                f"{Color.underline}Please run this with sudo.{Color.reset}"
            )
            return 1
        # --- elapsed start----------------------------------------------------
        start = time.perf_counter()
        # --- startup process -------------------------------------------------
        caller = get_caller_name()
        message_start(caller)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            info_comm = initialize()
            if dirs := infosystem.args.md:
                generate_md(dirs, info_comm)
        # --- termination process ---------------------------------------------
        message_end(get_caller_name())
        # --- elapsed end -----------------------------------------------------
        end = time.perf_counter()
        elapsed = end - start
        message_elapsed(caller, elapsed)
        # --- exit ------------------------------------------------------------
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    return_code = main()
    sys.exit(print_peak_memory() or return_code)

# --- eof ---------------------------------------------------------------------
