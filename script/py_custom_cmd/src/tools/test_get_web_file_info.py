#!/usr/bin/env python3
"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import asyncio
import sys
from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    TimeElapsed,
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    infosystem,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    print_peak_memory,
)
from common.shared import (
    InfoCommon,
    check_root,
    generate_markdown,
    initarg,
)

# ruff: isort: on
# --- gui window module ------------------------------------------------------
# =============================================================================
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


# --- check -------------------------------------------------------------------
# --- initialize --------------------------------------------------------------
@debug_logger
def initialize():
    """Initialize"""
    _caller = get_caller_name()
    if infosystem.debug:
        message_info(_caller, "Debug mode on", omit=True)
    if infosystem.debugout:
        message_info(_caller, "Debugout mode on", omit=True)
    if infosystem.data.exec_user:
        message_info(_caller, f"exec user:{infosystem.data.exec_user}", omit=True)
    if infosystem.data.home_dir:
        message_info(_caller, f"home dir :{infosystem.data.home_dir}", omit=True)
    # -------------------------------------------------------------------------
    return InfoCommon()
# --- procsee -----------------------------------------------------------------
@debug_logger
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
        from common.utils import InfoFile, InfoWeb

        info_web = InfoWeb()
        info_file = InfoFile()
        _web_datas = await info_web.get_info(
            session, tget_mdia.web_regexp, str(local_file_path)
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
                await asyncio.to_thread(info_file.get_info, str(local_file_path))
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
    _caller = get_caller_name()
    message_info(_caller, "Data get", omit=True)
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    # 定数で指定された上限数でセマフォを初期化
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)
    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        # すべてのメディアデータをタスクとして登録（この時点ではまだ待機状態）
        tasks = [
            _process_single_media(session, tget_mdia, info_comm, semaphore, _caller)
            for tget_mdia in info_comm.mdia.data
        ]
        # 一斉に実行を開始するが、内部のセマフォにより同時に動くのは指定件数（3件）のみ
        await asyncio.gather(*tasks)


@debug_logger
def data_save(info_comm: InfoCommon) -> None:
    """Data save
    Args:
        info_comm (InfoCommon): InfoCommon interface class
    """
    _caller = get_caller_name()
    message_info(_caller, "Data save", omit=True)
    # -------------------------------------------------------------------------
    info_comm.dist.save(info_comm.dist_json)
    info_comm.mdia.save(info_comm.mdia_json)
    # -------------------------------------------------------------------------
    info_comm.dist.put_list2text(info_comm.dist_path, info_comm.text_fmat.dist)
    info_comm.mdia.put_list2text(info_comm.mdia_path, info_comm.text_fmat.mdia)


# --- main --------------------------------------------------------------------
@debug_logger
async def main():
    """Main"""
    _caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(bypass=True):
            return 1
        # --- startup process -------------------------------------------------
        time_elapsed = TimeElapsed()
        message_start(_caller, omit=False)
        # --- processing block ------------------------------------------------
        initarg("Get web information")
        if infosystem.args:
            info_comm = initialize()
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
                            dirs_rmak / f"{path_isos.stem}_{preseed}{path_isos.suffix}"
                        )
                        info_mdia_data.rmk_path = str(path_file.resolve())
            dirs = info_comm.conf.get_path(key="DOCS_TOPS")
            generate_markdown(dest_dir_path=Path(dirs), info_comm=info_comm)
            data_save(info_comm)
        # --- termination process ---------------------------------------------
        message_end(_caller, omit=True)
        message_elapsed(_caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    infosystem.initialize(is_gui=False)
    sys.exit(asyncio.run(main()))
# --- eof ---------------------------------------------------------------------
