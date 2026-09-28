#!/usr/bin/env python3
# --- Python library ----------------------------------------------------------
import re
import sys
from collections import defaultdict
from pathlib import Path

# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    Argument,
    TimeElapsed,
    debug_logger,
    file_read,
    file_write,
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
    sort_distribution_data,
    sort_distribution_name,
)


# ruff: isort: on
# -----------------------------------------------------------------------------
LIFE_LABELS = {
    "TBA": "To Be Announced",
    "DEV": "Development",
    "CURRENT": "Current (supported)",
    "LTS": "Long Term Support",
    "ELTS": "Extended LTS",
    "ESM": "Expanded Security Maintenance",
    "EOL": "End of life (unsupported)",
}


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
    _list_args = []
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
def generate_ipxe_menu_file(
    info_comm: InfoCommon, _path_src: Path, _path_dest: Path, _dist_name: str
) -> None:
    caller = get_caller_name()
    message_info(caller, f"Generate ipxe menu ({_dist_name})", omit=True)
    # -------------------------------------------------------------------------
    _query_version = ""
    match _dist_name:
        case "autoexec":
            pass
        case "booting":
            pass
        case "menu":
            pass
        case (
            "debian"
            | "ubuntu"
            | "fedora"
            | "centos"
            | "almalinux"
            | "rockylinux"
            | "miraclelinux"
            | "opensuse"
        ):
            _query_version = rf"{_dist_name}-"
        case "custom_live":
            pass
        case "live":
            pass
        case "windows":
            _query_version = r"(windows-|winpe-|ati[0-9]{4}|memtest86plus-)"
        case _:
            pass
    _sort_results = ""
    if _query_version:
        _find_results = info_comm.dist.finds(
            version=_query_version, life="^(?!.*EOL).*$"
        )
        _sort_results = sort_distribution_data(_find_results, "", reverse=True)
    # -------------------------------------------------------------------------
    _read_data = file_read(_path_src)
    _var_pattern = re.compile(r":_([A-Z0-9_]+)_:")
    _conv_dist = _var_pattern.sub(
        lambda m: str(info_comm.conf.find(key=m.group(1)).value), _read_data
    )
    # -------------------------------------------------------------------------
    _item_width = 47
    _item_data = []
    _items_by_life = defaultdict(list)
    _goto_selection_lines = []
    _goto_target_lines = []
    _code_selection_lines = []
    # -------------------------------------------------------------------------
    for _data_dist in _sort_results:
        _goto_name = re.sub(r"\s+", "_", f"{_data_dist.name}-{_data_dist.version_id}")
        _item_text = f"{f'item -- {_goto_name}':<{_item_width}} - {_data_dist.name} ${{edition}} {_data_dist.version_id}"
        if _data_dist.code_name:
            _item_text += f" ({_data_dist.code_name})"
        life_key = _data_dist.life if _data_dist.life else "CURRENT"
        _items_by_life[life_key].append(_item_text)
        _goto_selection_lines.append(
            f"{f'iseq ${{selected}} {_goto_name}':<{_item_width}} && goto {_data_dist.name}-{_data_dist.version_id} ||"
        )
        _goto_target_lines.append(f":{_goto_name}")
        _code_selection_lines.append(
            f"{f'iseq ${{selected}} {_goto_name}':<{_item_width}} && set vers {_data_dist.version_id} ||"
        )
    # -------------------------------------------------------------------------
    for _read_line in _conv_dist.splitlines():
        _stripped = _read_line.strip()
        if _stripped.startswith("# <items>"):
            for _life in LIFE_LABELS:
                if _life in _items_by_life:
                    _gap_label = LIFE_LABELS.get(_life, "Unknown")
                    _gap_text = f"{'item --gap --':<{_item_width}} [ {_gap_label} ]"
                    _item_data.append(_gap_text)
                    _item_data.extend(_items_by_life[_life])
        elif _stripped.startswith("# <goto selection>"):
            _item_data.extend(_goto_selection_lines)
        elif _stripped.startswith("# <goto target>"):
            _item_data.extend(_goto_target_lines)
        elif _stripped.startswith("# <code selection>"):
            _item_data.extend(_code_selection_lines)
        else:
            _item_data.append(_read_line)
    # -------------------------------------------------------------------------
    write_data = "\n".join(_item_data) + "\n"
    file_write(_path_dest, write_data, text=True, backup=True)


@debug_logger
def generate_ipxe_menu(info_comm: InfoCommon) -> None:
    caller = get_caller_name()
    message_info(caller, "Generate ipxe menu", omit=True)
    # -------------------------------------------------------------------------
    _path_autoexec_ipxe = info_comm.conf.get_path(key="PATH_IPXE")
    _path_tmpl_ipxe_dir = info_comm.conf.get_path(key="DIRS_TMPL") / "ipxe"
    _list_tmpl_files = sort_distribution_name(
        sorted(
            [_file for _file in _path_tmpl_ipxe_dir.glob("*.ipxe") if _file.is_file()]
        )
    )
    _path_ipxe_dir = _path_autoexec_ipxe.parent
    # -------------------------------------------------------------------------
    _dist_pattern = re.compile(r"^menu_([^.]+)\.ipxe$")
    for _path_src in _list_tmpl_files:
        _filename = _path_src.name
        _match = _dist_pattern.match(_filename)
        _dist_name = _match.group(1) if _match else Path(_filename).stem
        _menu_dir = "" if _filename == _path_autoexec_ipxe.name else "menu"
        _path_dest = _path_ipxe_dir / _menu_dir / _filename
        generate_ipxe_menu_file(info_comm, _path_src, _path_dest, _dist_name)


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
            generate_ipxe_menu(info_comm=info_comm)
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
