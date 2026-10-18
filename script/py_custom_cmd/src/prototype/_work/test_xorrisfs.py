#!/usr/bin/env python3

import asyncio
import subprocess
import sys

from common.shared import (
    InfoCommon,
    proc_comp,
    proc_init,
)
from common.utils import (
    debug_logger,
    get_caller_name,
    infosystem,
)

# --- gui window module -------------------------------------------------------
from async_xorrisofs_handler import process_xorrisofs


# --- definition --------------------------------------------------------------
_ARGS_LIST: list[dict[str, str]] = [
    {"arg": "--t2j", "help": "Text -> json convert", "action": "store_true"},
    {"arg": "--j2t", "help": "json -> Text convert", "action": "store_true"},
    {"arg": "--md", "help": "json -> Markdown generate", "default": "", "type": "str"},
]


# --- initialize --------------------------------------------------------------
@debug_logger
def initialize() -> None:
    """Initialize"""

def pre_authenticate_sudo() -> bool:
    """親スクリプト（非root）の起動時に、事前に一度だけパスワードを入力させておく"""
    print(
        "特権コマンド実行のため、sudo権限を確認しています。パスワードを求められた場合は入力してください。"
    )
    try:
        subprocess.run(["sudo", "-v"], check=True)
        return True
    except subprocess.CalledProcessError:
        print("エラー: sudo認証に失敗しました。", file=sys.stderr)
        return False

@debug_logger
async def main():
    if not pre_authenticate_sudo():
        sys.exit(1)

    semaphore = asyncio.Semaphore(3)
    info_comm = InfoCommon()
    for mdia_data in info_comm.mdia.data:
        if mdia_data.entry_name != "debian-mini-13":
            continue
        _status = await process_xorrisofs(
            semaphore=semaphore, info_comm=info_comm, mdia_data=mdia_data
        )
        break

if __name__ == "__main__":
    #    try:
    # --- initialization --------------------------------------------------
    _caller = get_caller_name()
    proc_init(description="My tools", list_args=_ARGS_LIST, caller=_caller)
    # --- processing block ------------------------------------------------
    initialize()
    if infosystem.args:
        sys.exit(asyncio.run(main()))

    # --- complete --------------------------------------------------------
    proc_comp(caller=_caller)
#    except (OSError, Exception) as e:
#        raise SystemExit from e
# --- eof ---------------------------------------------------------------------
