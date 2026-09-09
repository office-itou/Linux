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
from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import InfoDistribution
from common.shared.my_media_dat import InfoMedia
from common.shared.my_shared import Text_fmat
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
def generate_md(
    dst_dir: str,
    info_conf: InfoConfiguration,
    info_dist: InfoDistribution,
    info_mdia: InfoMedia,
):
    """Generate markdown

    Args:
        dst_dir (str): Destination path
        info_conf (InfoConfiguration): common.cfg interface class
        info_dist (InfoDistribution): distribution.dat interface class
        info_mdia (InfoMedia): media.dat interface class
    """
    path_conf = info_conf.get_path(key="PATH_CONF")
    path_dist = info_conf.get_path(key="PATH_DIST")
    path_mdia = info_conf.get_path(key="PATH_MDIA")
    info_conf.markdown(
        Path(dst_dir) / "Readme_Configuration.md",
        f"Configuration data({path_conf.name})",
    )
    info_dist.markdown(
        Path(dst_dir) / "Readme_Distribution.md",
        f"Distribution data({path_dist.name})",
    )
    info_mdia.markdown(
        Path(dst_dir) / "Readme_Media.md",
        f"Media data({path_mdia.name})",
    )


@debug_logger
def data_save(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
):
    """Data save

    Args:
        info_conf (InfoConfiguration): common.cfg interface class
        info_dist (InfoDistribution): distribution.dat interface class
        info_mdia (InfoMedia): media.dat interface class
    """
    path_dist = info_conf.get_path(key="PATH_DIST")
    path_mdia = info_conf.get_path(key="PATH_MDIA")
    # -------------------------------------------------------------------------
    info_dist.save(path_dist.with_name(path_dist.name + ".json"))
    info_mdia.save(path_mdia.with_name(path_mdia.name + ".json"), info_conf)
    # -------------------------------------------------------------------------
    info_dist.put_list2text(path_dist, Text_fmat.dist)
    info_mdia.put_list2text(
        path_mdia,
        Text_fmat.mdia,
        info_conf,
    )


# -----------------------------------------------------------------------------
@debug_logger
async def get_web_file_info(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
) -> InfoMedia:
    """Get web/file information data

    Args:
        info_conf (InfoConfiguration): common.cfg interface class
        info_dist (InfoDistribution): distribution.dat interface class
        info_mdia (InfoMedia): media.dat interface class

    Returns:
        InfoMedia: media.dat interface class
    """
    info_web = InfoWeb()
    info_file = InfoFile()
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        for tget_mdia in info_mdia.data:
            if (
                tget_mdia.entry_flag != "o"
                or tget_mdia.web_regexp == "-"
                or tget_mdia.iso_path == "-"
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
    return info_mdia.data


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
            sys.exit(1)
        # --- elapsed start--------------------------------------------------------
        start = time.perf_counter()
        # --- startup process -----------------------------------------------------
        message_start(get_caller_name())
        # --- processing block ----------------------------------------------------
        arg_manager = Argument()
        arg_manager.add(
            "--debugdump",
            help="Debug dump mode for common datas",
            default=["conf", "dist", "mdia"],
            nargs="*",
            type=str,
        )
        arg_manager.add(
            "--t2j", help="Text -> json convert", default=False, action="store_true"
        )
        arg_manager.add(
            "--j2t", help="json -> Text convert", default=False, action="store_true"
        )
        arg_manager.add("--md", help="json -> Markdown generate", default="", type=str)
        arg_manager.add(
            "--info", help="Get ISO file information for web", default="", type=str
        )
        arg_manager.add("--save", help="Save data", default=False, action="store_true")
        args = arg_manager.parse()
        if args:
            info_conf, info_dist, info_mdia = initialize()
            path_dist = info_conf.get_path(key="PATH_DIST")
            path_mdia = info_conf.get_path(key="PATH_MDIA")
            if (targets := infosystem.args.debugdump) is not None:
                if not targets:
                    targets = ["conf", "dist", "mdia"]
                print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
                for target in targets:
                    print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
                    match target:
                        case "conf":
                            info_conf.dump(cut=False)
                        case "dist":
                            info_dist.dump(cut=False)
                        case "mdia":
                            info_mdia.dump(cut=False)
                        case _:
                            pass
                    print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
                print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
                sys.exit(0)
                # -----------------------------------------------------------------
                info_dist.get_text2list(path_dist)
                info_mdia.get_text2list(path_mdia, info_conf)
                print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
                info_dist.dump(cut=False)
                print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
                info_mdia.dump(cut=False)
                print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
                # -----------------------------------------------------------------
            if infosystem.args.t2j == True:
                info_dist.get_text2list(path_dist)
                info_mdia.get_text2list(path_mdia, info_conf)
                info_dist.save(path_dist.with_name(path_dist.name + ".json"))
                info_mdia.save(path_mdia.with_name(path_mdia.name + ".json"), info_conf)
            if infosystem.args.j2t == True:
                info_dist.get_text2list(path_dist.with_name(path_dist.name + ".json"))
                info_mdia.get_text2list(
                    path_mdia.with_name(path_mdia.name + ".json"), info_conf
                )
                info_dist.put_list2text(path_dist, Text_fmat.dist)
                info_mdia.put_list2text(
                    path_mdia,
                    Text_fmat.mdia,
                    info_conf,
                )
            if target := infosystem.args.info:
                if target == "a":
                    pass
                await get_web_file_info(info_conf, info_dist, info_mdia)
                generate_md("./", info_conf, info_dist, info_mdia)
                data_save(info_conf, info_dist, info_mdia)
            if dirs := infosystem.args.md:
                generate_md(dirs, info_conf, info_dist, info_mdia)
            if infosystem.args.save == True:
                data_save(info_conf, info_dist, info_mdia)
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
    asyncio.run(main())

# --- eof ---------------------------------------------------------------------
