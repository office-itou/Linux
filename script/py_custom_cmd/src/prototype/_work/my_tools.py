#!/usr/bin/env python3
"""main task"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.shared import (
    InfoCommon,
    check_root,
    generate_markdown,
    proc_comp,
    proc_init,
)
from common.shared.my_distribution_dat import ORDERED_DISTRIBUTIONS
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    infosystem,
    list2markdown,
    message_info,
)


# ruff: isort: on
# --- gui window module -------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
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


# --- main --------------------------------------------------------------------
@debug_logger
def main_cui() -> None:
    """main for cui"""
    _caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if not check_root(bypass=True):
            return
        # --- processing block ------------------------------------------------
        info_comm: InfoCommon = InfoCommon()
        # --- dump ------------------------------------------------------------
        # if (targets := infosystem.args.debugdump) is not None:
        #    debugdump(targets, info_comm)
        # --- text -> json ----------------------------------------------------
        if infosystem.args.t2j:
            message_info(_caller, "start   : text -> json", omit=False)
            info_comm.dist.get_text2list(info_comm.dist_path)
            info_comm.mdia.get_text2list(info_comm.mdia_path)
            info_comm.dist.save(info_comm.dist_json)
            info_comm.mdia.save(info_comm.mdia_json)
            message_info(_caller, "complete: text -> json", omit=False)
        # --- json -> text ----------------------------------------------------
        if infosystem.args.j2t:
            message_info(_caller, "start   : json -> text", omit=False)
            info_comm.dist.load(info_comm.dist_json)
            info_comm.mdia.load(info_comm.mdia_json)
            info_comm.dist.put_list2text(info_comm.dist_path, info_comm.text_fmat.dist)
            info_comm.mdia.put_list2text(info_comm.mdia_path, info_comm.text_fmat.mdia)
            message_info(_caller, "complete: json -> text", omit=False)
        # --- markdown --------------------------------------------------------
        if dirs := infosystem.args.md:
            generate_markdown(dest_dir_path=Path(dirs), info_comm=info_comm)
            # -----------------------------------------------------------------
            dest_path: Path = Path(dirs) / "Readme_tbl_distribution.md"
            md_title: str = f"Distribution data({info_comm.dist_path.name})"
            list_data = []
            for distribution in ORDERED_DISTRIBUTIONS:
                list_sort = info_comm.dist.sort(distribution, reverse=True)
                dict_list: list[str] = [distribution]
                dict_list += [
                    d.__dict__ if hasattr(d, "__dict__") else d for d in list_sort
                ]
                list_data.append(dict_list)
            list2markdown(dest_path, md_title, list_data)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False)
    return


@debug_logger
def main_gui() -> None:
    """main for gui"""
    from gui_main_build import MainWindow

    # --- main window creation ------------------------------------------------
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    # --- binding the termination protocol and starting the main loop ---------
    root.protocol("WM_DELETE_WINDOW", app.quit)
    app.build()
    root.mainloop()
    root.destroy()


if __name__ == "__main__":
    #    try:
    # --- initialization --------------------------------------------------
    _caller = get_caller_name()
    proc_init(description="My tools", list_args=_ARGS_LIST, caller=_caller)
    # --- processing block ------------------------------------------------
    initialize()
    if infosystem.args:
        if not infosystem.is_gui:
            main_cui()
        else:
            main_gui()
    # --- complete --------------------------------------------------------
    proc_comp(caller=_caller)
#    except (OSError, Exception) as e:
#        raise SystemExit from e
# --- eof ---------------------------------------------------------------------
