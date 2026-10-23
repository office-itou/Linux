#!/usr/bin/env python3
"""Test web/file information"""

# --- Python library ----------------------------------------------------------
import asyncio
import sys
from pathlib import Path


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.shared import (
    InfoCommon,
    InfoWebFile,
    check_root,
    generate_markdown,
    initarg,
)
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


# ruff: isort: on
# --- my module ---------------------------------------------------------------
# --- gui window module -------------------------------------------------------
# =============================================================================
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
            info_webfile = InfoWebFile(info_comm)
            for _data in info_webfile.data:
                _data.is_target = _data.mdia_data.entry_flag == "o"
            await info_webfile.get_web_file_info()
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
