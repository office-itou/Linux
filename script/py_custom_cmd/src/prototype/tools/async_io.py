# --- Python library ----------------------------------------------------------
import asyncio

from pathlib import Path

import aiohttp  # sudo apt-get install python3-aiohttp

from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from my_debug import debug_logger
from my_message import (
    get_caller_name,
    message_info,
)
from my_shared import InfoCommon

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


# -----------------------------------------------------------------------------
async def _process_single_media(
    session: aiohttp.ClientSession,
    tget_mdia,
    info_comm: InfoCommon,
    semaphore: asyncio.Semaphore,
    caller: str,
) -> None:
    # 💡 【追加】画面上でチェックが入っていないオブジェクトは即座にスキップ
    if not getattr(tget_mdia, "is_target", False):
        return
    if tget_mdia.entry_name == "menu-entry":
        return
    # 💡 更新チェック用に古い値を保持しておく
    old_tstamp = tget_mdia.web_tstamp
    local_file_path = Path(tget_mdia.iso_path) if tget_mdia.iso_path else ""
    if not local_file_path:
        for name, key in BASE_DIR_MAP.items():
            if name in tget_mdia.entry_name:
                local_file_path = info_comm.conf.get_path(key) / "_dummy.iso"
                break
    if not tget_mdia.web_regexp:
        return
    async with semaphore:
        message_info(caller, f"[Queue] Fetching: {tget_mdia.web_regexp}", omit=True)
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
            # 💡 【重要】値が更新されたかチェックし、オブジェクトに印をつける
            if old_tstamp != tget_mdia.web_tstamp:
                tget_mdia.is_updated_data = True  # 動的なフラグ保持
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
