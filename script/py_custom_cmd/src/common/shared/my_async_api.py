# --- Python library ----------------------------------------------------------
import asyncio
from pathlib import Path
from typing import Callable  # 💡 型定義用に追加

import aiohttp  # sudo apt-get install python3-aiohttp
from aiohttp import ClientTimeout


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    get_caller_name,
    message_info,
)
from common.shared import (
    InfoCommon,
)

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
async def _process_single_media(
    session: aiohttp.ClientSession,
    tget_mdia,
    info_comm: InfoCommon,
    semaphore: asyncio.Semaphore,
    caller: str,
    on_progress_callback: Callable[[str], None]
    | None = None,  # 💡 コールバック引数を追加
) -> None:
    """1件のメディアデータを処理する非同期タスク (セマフォによる流量制限付き)"""
    if tget_mdia.entry_name == "menu-entry":
        return
    # 💡 🌟 もしこのアイテムが処理対象(is_target)でなければ通信をスキップする
    # ※CUIで全件処理したい場合を考慮し、
    # 属性が存在してかつFalseの時だけ弾くディフェンシブ設計
    if getattr(tget_mdia, "is_target", True) is False:
        return
    local_file_path = Path()
    if tget_mdia.iso_path:
        local_file_path = Path(tget_mdia.iso_path)
    else:
        for name, key in BASE_DIR_MAP.items():
            if name in tget_mdia.entry_name:
                local_file_path = info_comm.conf.get_path(key) / "_dummy.iso"
                break
    async with semaphore:
        from common.utils import InfoFile, InfoWeb

        disp_name = getattr(tget_mdia, "entry_disp", tget_mdia.entry_name)
        # 💡 通信開始時のログ通知 (コールバック関数が渡されていれば実行)
        if on_progress_callback:
            on_progress_callback(f"➔ 通信中: {disp_name} ...")
        if tget_mdia.web_regexp:
            message_info(caller, f"[Queue] Fetching: {tget_mdia.web_regexp}", omit=True)
            info_web = InfoWeb()
            _web_datas = await info_web.get_info(
                session, tget_mdia.web_regexp, str(local_file_path)
            )
            for _web_data in _web_datas:
                tget_mdia.web_path = str(_web_data.request_url)
                tget_mdia.web_tstamp = str(_web_data.time_stamp)
                tget_mdia.web_size = str(_web_data.file_size)
                tget_mdia.web_check = str(_web_data.check_date)
                tget_mdia.web_status = str(_web_data.status)
                local_file_path = Path(_web_data.local_file)
        if local_file_path.exists():
            info_file = InfoFile()
            await asyncio.to_thread(info_file.get_info, str(local_file_path))
            tget_mdia.iso_path = str(info_file.data.path)
            tget_mdia.iso_tstamp = str(info_file.data.tmstamp)
            tget_mdia.iso_size = str(info_file.data.size)
            tget_mdia.iso_volume = str(info_file.data.volume)
        else:
            tget_mdia.iso_path = str(local_file_path)
            tget_mdia.iso_tstamp = ""
            tget_mdia.iso_size = ""
            tget_mdia.iso_volume = ""
        # 💡 1件完了時のログ通知
        if on_progress_callback:
            on_progress_callback(f"  ✓ 完了: {disp_name}")


@debug_logger
async def get_web_file_info(
    info_comm: InfoCommon, on_progress_callback: Callable[[str], None] | None = None
) -> None:
    """Get web/file information data (Parallelized & Rate-limited)"""
    _caller = get_caller_name()
    message_info(_caller, "Data get", omit=True)
    timeout = ClientTimeout(total=60, sock_connect=10, sock_read=30)
    semaphore = asyncio.Semaphore(MAX_CONCURRENT_REQUESTS)

    async with aiohttp.ClientSession(
        timeout=timeout, raise_for_status=False
    ) as session:
        # 💡 🌟 【重要】タスクを作成する段階で、チェックが入っている(is_target == True)
        # データのみに厳選します
        # これにより、画面上のチェックと100%一致した通信のみが発生するようになります
        tasks = [
            _process_single_media(
                session, tget_mdia, info_comm, semaphore, _caller, on_progress_callback
            )
            for tget_mdia in info_comm.mdia.data
            if getattr(tget_mdia, "is_target", False)
            and getattr(tget_mdia, "entry_name", "") != "menu-entry"
        ]

        # 対象タスクがある場合のみ実行
        if tasks:
            await asyncio.gather(*tasks)
