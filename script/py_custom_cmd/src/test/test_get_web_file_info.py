#!/usr/bin/env python3

"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import asyncio
import os
import sys
import time
from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))
from common.shared.my_shared import InfoCommon
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_error import handle_fatal_error
from common.utils.my_infofile import InfoFile
from common.utils.my_infoweb import InfoWeb
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)


@debug_logger
def initialize() -> InfoCommon:
    """Initialize

    Returns:
        InfoCommon: InfoCommon interface class
    """
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")
    # -------------------------------------------------------------------------
    info_comm = InfoCommon()
    # -------------------------------------------------------------------------
    return info_comm


@debug_logger
def generate_md(dst_dir: str, info_comm: InfoCommon) -> None:
    """Generate markdown

    Args:
        dst_dir (str): Destination path
        info_comm (InfoCommon): InfoCommon interface class
    """
    info_comm.conf.info.markdown(
        Path(dst_dir) / "Readme_Configuration.md",
        f"Configuration data({info_comm.conf.path.name})",
    )
    info_comm.dist.info.markdown(
        Path(dst_dir) / "Readme_Distribution.md",
        f"Distribution data({info_comm.dist.path.name})",
    )
    info_comm.mdia.info.markdown(
        Path(dst_dir) / "Readme_Media.md",
        f"Media data({info_comm.mdia.path.name})",
    )


@debug_logger
def data_save(info_comm: InfoCommon) -> None:
    """Data save

    Args:
        info_comm (InfoCommon): InfoCommon interface class
    """
    # -------------------------------------------------------------------------
    info_comm.dist.info.save(info_comm.dist.json)
    info_comm.mdia.info.save(info_comm.mdia.json)
    # -------------------------------------------------------------------------
    info_comm.dist.info.put_list2text(info_comm.dist.path, info_comm.text_fmat.dist)
    info_comm.mdia.info.put_list2text(info_comm.mdia.path, info_comm.text_fmat.mdia)


# -----------------------------------------------------------------------------
@debug_logger
async def get_web_file_info(info_comm: InfoCommon) -> InfoCommon:
    """Get web/file information data

    Args:
        info_comm (InfoCommon): InfoCommon interface class

    Returns:
        InfoCommon: InfoCommon interface class
    """
    info_web = InfoWeb()
    info_file = InfoFile()
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        for tget_mdia in info_comm.mdia.info.data:
            if (
                tget_mdia.entry_flag == ""
                or not tget_mdia.web_regexp
                or not tget_mdia.iso_path
            ):
                continue
            message_info(get_caller_name(), tget_mdia.web_regexp, True)
            await info_web.get_info(session, tget_mdia.web_regexp, tget_mdia.iso_path)
            tget_mdia.web_path = info_web.data.url
            tget_mdia.web_tstamp = info_web.data.tmstamp
            tget_mdia.web_size = info_web.data.size
            tget_mdia.web_check = info_web.data.check
            tget_mdia.web_status = info_web.data.status
            if info_web.data.status != 200:
                continue
            if Path(info_web.data.output).exists():
                info_file.get_info(info_web.data.output)
                tget_mdia.iso_path = info_file.data.path
                tget_mdia.iso_tstamp = info_file.data.tmstamp
                tget_mdia.iso_size = info_file.data.size
                tget_mdia.iso_volume = info_file.data.volume
            else:
                tget_mdia.iso_path = info_web.data.output
                tget_mdia.iso_tstamp = "-"
                tget_mdia.iso_size = "-"
                tget_mdia.iso_volume = "-"
    return info_comm.mdia.info.data


@debug_logger
def debugdump(targets: list, info_comm: InfoCommon) -> None:
    """information interface class dump

    Args:
        targets (list): Target information interface class
        info_comm (InfoCommon): InfoCommon interface class
    """
    if not targets:
        targets = ["conf", "dist", "mdia"]
    print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
    for target in targets:
        print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
        match target:
            case "conf":
                info_comm.conf.dump(wrap=True)
            case "dist":
                info_comm.dist.dump(wrap=True)
            case "mdia":
                info_comm.mdia.dump(wrap=True)
            case _:
                pass
        print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
    print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    arg_manager = Argument()
    list_args = [
        {
            "arg": "--debugdump",
            "help": "Debug dump mode for common datas",
            "default": None,
            "nargs": "*",
            "action": Argument.DefaultListAction,
            "type": "str",
        },
        {
            "arg": "--t2j",
            "help": "Text -> json convert",
            "action": "store_true",
        },
        {
            "arg": "--j2t",
            "help": "Text -> json convert",
            "action": "store_true",
        },
        {
            "arg": "--md",
            "help": "json -> Markdown generate",
            "default": "",
            "type": "str",
        },
        {
            "arg": "--info",
            "help": "Get ISO file information for web",
            "default": "",
            "type": "str",
        },
        {
            "arg": "--save",
            "help": "Save data",
            "action": "store_true",
        },
    ]
    for line_arg in list_args:
        arg_name = line_arg.pop("arg")
        arg_manager.add(arg_name, **line_arg)
    infosystem.args = arg_manager.parse()


@debug_logger
async def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user --------------------------------------------
        if os.geteuid() != 0:
            print(
                f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n{Color.br_yellow} You have standard user privileges. {Color.underline}Please run this with sudo.{Color.reset}"
            )
            return 1
        # --- elapsed start--------------------------------------------------------
        start = time.perf_counter()
        # --- startup process -----------------------------------------------------
        message_start(get_caller_name())
        # --- processing block ----------------------------------------------------
        initarg()
        if infosystem.args:
            info_comm = initialize()
            if (targets := infosystem.args.debugdump) is not None:
                debugdump(targets, info_comm)
            if infosystem.args.t2j == True:
                info_comm.dist.info.get_text2list(info_comm.dist.path)
                info_comm.mdia.info.get_text2list(info_comm.mdia.path)
                info_comm.dist.info.save(info_comm.dist.json)
                info_comm.mdia.info.save(info_comm.mdia.json)
            if infosystem.args.j2t == True:
                info_comm.dist.info.load(info_comm.dist.json)
                info_comm.mdia.info.load(info_comm.mdia.json)
                info_comm.dist.info.put_list2text(
                    info_comm.dist.path, info_comm.text_fmat.dist
                )
                info_comm.mdia.info.put_list2text(
                    info_comm.mdia.path, info_comm.text_fmat.mdia
                )
            if target := infosystem.args.info:
                if target == "a":
                    pass
                await get_web_file_info(info_comm)
                # -------------------------------------------------------------
                dirs_rmak = info_comm.conf.info.get_path("DIRS_RMAK")
                for data_mdia in info_comm.mdia.info.data:
                    if data_mdia.cfg_path:
                        path_psed = Path(data_mdia.cfg_path)
                        preseed = (
                            ""
                            if data_mdia.cfg_path.endswith("/")
                            else path_psed.parent.name
                        )
                        if preseed and data_mdia.iso_path:
                            path_isos = Path(data_mdia.iso_path).resolve()
                            path_file = (
                                dirs_rmak
                                / f"{path_isos.stem}_{preseed}{path_isos.suffix}"
                            )
                            data_mdia.rmk_path = str(path_file.resolve())
                # -------------------------------------------------------------
                generate_md("./", info_comm)
                data_save(info_comm)
            if dirs := infosystem.args.md:
                generate_md(dirs, info_comm)
            if infosystem.args.save == True:
                data_save(info_comm)
        # --- termination process -------------------------------------------------
        message_end(get_caller_name())
        # --- elapsed end ---------------------------------------------------------
        end = time.perf_counter()
        elapsed = end - start
        message_elapsed(get_caller_name(), elapsed)
        # --- exit ----------------------------------------------------------------
        return 0
        # -------------------------------------------------------------------------
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))

# --- eof ---------------------------------------------------------------------
