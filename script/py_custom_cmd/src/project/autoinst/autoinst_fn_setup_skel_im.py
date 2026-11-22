# --- python library ----------------------------------------------------------
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_info,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_setup_skel_im_fcitx5 import setup_skel_im_fcitx5
from autoinst_fn_setup_skel_im_ibus import setup_skel_im_ibus


# --- class and function ------------------------------------------------------
@debug_logger
def setup_skel_im(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'setup':<10}:skeleton im", omit=True)
        if not shutil.which("fcitx5"):
            setup_skel_im_fcitx5(info_syst=info_syst)
        elif not shutil.which("ibus"):
            setup_skel_im_ibus(info_syst=info_syst)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
