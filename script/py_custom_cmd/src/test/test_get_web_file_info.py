#!/usr/bin/env python3
"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import asyncio
import os
import sys

from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp

from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
from my_argument import Argument
from my_colors import Color
from my_config import infosystem
from my_debug import debug_logger
from my_error import handle_fatal_error
from my_mem_usage import print_peak_memory
from my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
)
from my_shared import InfoCommon
from my_time import TimeElapsed

# --- 設定項目（後から簡単に件数を変更可能） ----------------------------------
MAX_CONCURRENT_REQUESTS = 3  # 同時アクセスする上限件数
# --- マッピングリスト --------------------------------------------------------
BASE_DIR_MAP = {
    "debian": "BASE_DEBI",
    "ubuntu": "BASE_UBUN",
    "fedora": "BASE_FEDO",
    "centos": "BASE_CENT",
    "almalinux": "BASE_ALMA",
    "rockylinux": "BASE_ROCK",
    "miraclelinux": "BASE_MIRA",
    "opensuse": "BASE_SUSE",
    "memtest86plus": "BASE_TEST",
    "windows-10": "BASE_WI10",
    "windows-11": "BASE_WI11",
    "winpe": "BASE_WINP",
    "ati": "BASE_ATIW",
    "aomei": "BASE_AOME",
}


@debug_logger
def initialize():
    """Initialize"""
    caller = get_caller_name()
    if infosystem.debug == True:
        message_info(caller, "Debug mode on", omit=True)
    if infosystem.debugout == True:
        message_info(caller, "Debugout mode on", omit=True)
    message_info(caller, f"exec user:{infosystem.data.exec_user}", omit=True)
    message_info(caller, f"home dir :{infosystem.data.home_dir}", omit=True)
    # -------------------------------------------------------------------------
    return InfoCommon()


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "Get web information\n"
    arg_manager = Argument(description)
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
    if list_args:
        for line_arg in list_args:
            arg_name = line_arg.pop("arg")
            if isinstance(arg_name, tuple):
                arg_manager.add(*arg_name, **line_arg)
            else:
                arg_manager.add(arg_name, **line_arg)
    infosystem.args = arg_manager.parse()


@debug_logger
def generate_md(dst_dir: str, info_comm: InfoCommon) -> None:
    """Generate markdown
    Args:
        dst_dir (str): Destination path
        info_comm (InfoCommon): InfoCommon interface class
    """
    caller = get_caller_name()
    message_info(caller, "Generate markdown", omit=True)
    info_comm.conf.markdown(
        Path(dst_dir) / "Readme_Configuration.md",
        f"Configuration data({info_comm.conf_path.name})",
    )
    info_comm.dist.markdown(
        Path(dst_dir) / "Readme_Distribution.md",
        f"Distribution data({info_comm.dist_path.name})",
    )
    info_comm.mdia.markdown(
        Path(dst_dir) / "Readme_Media.md",
        f"Media data({info_comm.mdia_path.name})",
    )


@debug_logger
def data_save(info_comm: InfoCommon) -> None:
    """Data save
    Args:
        info_comm (InfoCommon): InfoCommon interface class
    """
    caller = get_caller_name()
    message_info(caller, "Data save", omit=True)
    # -------------------------------------------------------------------------
    info_comm.dist.save(info_comm.dist_json)
    info_comm.mdia.save(info_comm.mdia_json)
    # -------------------------------------------------------------------------
    info_comm.dist.put_list2text(info_comm.dist_path, info_comm.text_fmat.dist)
    info_comm.mdia.put_list2text(info_comm.mdia_path, info_comm.text_fmat.mdia)


# -----------------------------------------------------------------------------
async def _process_single_media(
    session: aiohttp.ClientSession,
    tget_mdia,
    info_comm: InfoCommon,
    semaphore: asyncio.Semaphore,
    caller: str,
) -> None:
    """1件のメディアデータを処理する非同期タスク (セマフォによる流量制限付き)"""
    if tget_mdia.entry_name == "menu-entry":
        return
    # ダミーISOのパス決定
    local_file_path = ""
    if tget_mdia.iso_path:
        local_file_path = Path(tget_mdia.iso_path)
    else:
        for name, key in BASE_DIR_MAP.items():
            if name in tget_mdia.entry_name:
                local_file_path = info_comm.conf.get_path(key) / "_dummy.iso"
                break
    if not tget_mdia.web_regexp:
        return
    # セマフォを使って同時に指定件数（3件）までしか以下のブロックに入れないように制御
    async with semaphore:
        message_info(caller, f"[Queue] Fetching: {tget_mdia.web_regexp}", omit=True)
        # 並行実行時のデータ競合を防ぐため、Web/Fileモジュールはタスク内で個別に生成
        from my_infofile import InfoFile
        from my_infoweb import InfoWeb

        info_web = InfoWeb()
        info_file = InfoFile()
        _web_datas = await info_web.get_info(
            session, tget_mdia.web_regexp, local_file_path
        )
        if not _web_datas:
            return
        for _web_data in _web_datas:
            tget_mdia.web_path = str(_web_data.request_url)
            tget_mdia.web_tstamp = str(_web_data.time_stamp)
            tget_mdia.web_size = str(_web_data.file_size)
            tget_mdia.web_check = str(_web_data.check_date)
            tget_mdia.web_status = str(_web_data.status)
            local_file_path = Path(_web_data.local_file)
            if local_file_path.exists():
                # ディスクI/Oを伴う重い同期処理は別スレッドで実行
                await asyncio.to_thread(info_file.get_info, local_file_path)
                tget_mdia.iso_path = str(info_file.data.path)
                tget_mdia.iso_tstamp = str(info_file.data.tmstamp)
                tget_mdia.iso_size = str(info_file.data.size)
                tget_mdia.iso_volume = str(info_file.data.volume)
            else:
                tget_mdia.iso_path = str(local_file_path)
                tget_mdia.iso_tstamp = "-"
                tget_mdia.iso_size = "-"
                tget_mdia.iso_volume = "-"


@debug_logger
async def get_web_file_info(info_comm: InfoCommon) -> None:
    """Get web/file information data (Parallelized & Rate-limited)"""
    caller = get_caller_name()
    message_info(caller, "Data get", omit=True)
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    # 定数で指定された上限数でセマフォを初期化
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        # すべてのメディアデータをタスクとして登録（この時点ではまだ待機状態）
        tasks = [
            _process_single_media(session, tget_mdia, info_comm, semaphore, caller)
            for tget_mdia in info_comm.mdia.data
        ]
        # 一斉に実行を開始するが、内部のセマフォにより同時に動くのは指定件数（3件）のみ
        await asyncio.gather(*tasks)


@debug_logger
def debugdump(targets: list, info_comm: InfoCommon) -> None:
    """information interface class dump
    Args:
        targets (list): Target information interface class
        info_comm (InfoCommon): InfoCommon interface class
    """
    if not targets:
        targets = ["conf", "dist", "mdia"]
    # print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")
    for target in targets:
        # print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
        match target:
            case "conf":
                info_comm.conf.dump(wrap=True)
            case "dist":
                info_comm.dist.dump(wrap=True)
            case "mdia":
                info_comm.mdia.dump(wrap=True)
            case _:
                pass
        # print(f"{Color.br_yellow}{'-' * 80}{Color.reset}")
    # print(f"{Color.br_yellow}{'=' * 80}{Color.reset}")


@debug_logger
def check_root(bypass: bool = False) -> bool:
    if bypass or os.geteuid() == 0:
        return True
    print(
        f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
        f"{Color.br_yellow} You have standard user privileges. "
        f"{Color.underline}Please run this with sudo.{Color.reset}"
    )
    return False


@debug_logger
async def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(True):
            return 1
        # --- elapsed start----------------------------------------------------
        time_elapsed = TimeElapsed
        # --- startup process -------------------------------------------------
        caller = get_caller_name()
        message_start(caller, omit=True)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            info_comm = initialize()
            if (targets := infosystem.args.debugdump) is not None:
                debugdump(targets, info_comm)
            if infosystem.args.t2j:
                info_comm.dist.get_text2list(info_comm.dist_path)
                info_comm.mdia.get_text2list(info_comm.mdia_path)
                info_comm.dist.save(info_comm.dist_json)
                info_comm.mdia.save(info_comm.mdia_json)
            if infosystem.args.j2t:
                info_comm.dist.load(info_comm.dist_json)
                info_comm.mdia.load(info_comm.mdia_json)
                info_comm.dist.put_list2text(
                    info_comm.dist_path, info_comm.text_fmat.dist
                )
                info_comm.mdia.put_list2text(
                    info_comm.mdia_path, info_comm.text_fmat.mdia
                )
            if target := infosystem.args.info:
                if target == "a":
                    pass
                await get_web_file_info(info_comm)
                dirs_rmak = info_comm.conf.get_path("DIRS_RMAK")
                for info_mdia_data in info_comm.mdia.data:
                    if info_mdia_data.cfg_path:
                        path_psed = Path(info_mdia_data.cfg_path)
                        preseed = (
                            ""
                            if info_mdia_data.cfg_path.endswith("/")
                            else path_psed.parent.name
                        )
                        if preseed and info_mdia_data.iso_path:
                            path_isos = Path(info_mdia_data.iso_path).resolve()
                            path_file = (
                                dirs_rmak
                                / f"{path_isos.stem}_{preseed}{path_isos.suffix}"
                            )
                            info_mdia_data.rmk_path = str(path_file.resolve())
                generate_md("./", info_comm)
                data_save(info_comm)
            if dirs := infosystem.args.md:
                generate_md(dirs, info_comm)
            if infosystem.args.save:
                data_save(info_comm)
        # --- termination process ---------------------------------------------
        message_end(get_caller_name(), omit=True)
        # --- elapsed end -----------------------------------------------------
        message_elapsed(caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e, omit=True)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
# --- eof ---------------------------------------------------------------------
