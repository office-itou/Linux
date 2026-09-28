#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import sys
from pathlib import Path

# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    Argument,
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
)


# ruff: isort: on
# --- initialize -------------------------------------------------------------
@debug_logger
def initialize():
    """Initialize"""
    caller = get_caller_name()
    if infosystem.debug:
        message_info(caller, "Debug mode on", omit=True)
    if infosystem.debugout:
        message_info(caller, "Debugout mode on", omit=True)
    if infosystem.data.exec_user:
        message_info(caller, f"exec user:{infosystem.data.exec_user}", omit=True)
    if infosystem.data.home_dir:
        message_info(caller, f"home dir :{infosystem.data.home_dir}", omit=True)
    # -------------------------------------------------------------------------
    return InfoCommon()

@debug_logger
def initarg() -> None:
    _description = "Common data manager\n"
    _arg_manager = Argument(_description)
    _list_args = [
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
    ]
    # -------------------------------------------------------------------------
    if _list_args:
        for _line_arg in _list_args:
            _arg_name = _line_arg.pop("arg")
            if isinstance(_arg_name, tuple):
                _arg_manager.add(*_arg_name, **_line_arg)
            else:
                _arg_manager.add(_arg_name, **_line_arg)
    infosystem.args = _arg_manager.parse()

@debug_logger
def debugdump(targets: list, info_comm: InfoCommon) -> None:
    if not targets:
        targets = ["conf", "dist", "mdia"]
    for target in targets:
        match target:
            case "conf":
                info_comm.conf.dump(wrap=True)
            case "dist":
                info_comm.dist.dump(wrap=True)
            case "mdia":
                info_comm.mdia.dump(wrap=True)
            case _:
                pass

def generate_markdown(dest_dir_path: Path, info_comm: InfoCommon)->None:
    caller = get_caller_name()
    message_info(caller, "Generate markdown", omit=True)
    info_comm.conf.markdown(
        dest_dir_path / "Readme_Configuration.md",
        f"Configuration data({info_comm.conf_path.name})",
    )
    info_comm.dist.markdown(
        dest_dir_path / "Readme_Distribution.md",
        f"Distribution data({info_comm.dist_path.name})",
    )
    info_comm.mdia.markdown(
        dest_dir_path / "Readme_Media.md",
        f"Media data({info_comm.mdia_path.name})",
    )


# --- main -------------------------------------------------------------------
def main():
    caller = get_caller_name()
    try:
        # --- startup process -------------------------------------------------
        time_elapsed = TimeElapsed()
        message_start(caller, omit=False)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            info_comm = initialize()
            # --- dump --------------------------------------------------------
            if (targets := infosystem.args.debugdump) is not None:
                debugdump(targets, info_comm)
            # --- text -> json ------------------------------------------------
            if infosystem.args.t2j:
                info_comm.dist.get_text2list(info_comm.dist_path)
                info_comm.mdia.get_text2list(info_comm.mdia_path)
                info_comm.dist.save(info_comm.dist_json)
                info_comm.mdia.save(info_comm.mdia_json)
            # --- json -> text ------------------------------------------------
            if infosystem.args.j2t:
                info_comm.dist.load(info_comm.dist_json)
                info_comm.mdia.load(info_comm.mdia_json)
                info_comm.dist.put_list2text(
                    info_comm.dist_path, info_comm.text_fmat.dist
                )
                info_comm.mdia.put_list2text(
                    info_comm.mdia_path, info_comm.text_fmat.mdia
                )
            # --- markdown ----------------------------------------------------
            if dirs := infosystem.args.md:
                generate_markdown(dest_dir_path=Path(dirs), info_comm=info_comm)
        # --- termination process ---------------------------------------------
        message_end(get_caller_name(), omit=True)
        message_elapsed(caller, time_elapsed.elapsed(), omit=True)
        # --- exit ------------------------------------------------------------
        print_peak_memory()
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e, omit=False)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    infosystem.initialize(is_gui=False)
    sys.exit(main())
# --- eof ---------------------------------------------------------------------
