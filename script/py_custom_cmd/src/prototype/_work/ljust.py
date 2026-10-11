#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import asyncio
import threading
from datetime import datetime

import aiohttp
from aiohttp import ClientTimeout

# --- my library --------------------------------------------------------------
from common.utils import (
    FileData,
    WebData,
    get_caller_name,
    get_contents,
    get_infofile,
    get_infoweb,
    ljust,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
_caller = get_caller_name()
_disp_name = "entry_disp"
_mdia_type = "mdia_type"
_message = f"{ljust('スキップ', 20)}: {_disp_name} ({_mdia_type})..."
message_info(_caller, _message, omit=True)
_message = f"{ljust('➔ ダウンロード中', 20)}: {_disp_name} ({_mdia_type})..."
message_info(_caller, _message, omit=True)
