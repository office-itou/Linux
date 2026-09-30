#!/usr/bin/env python3
"""Test text output"""

# --- Python library ----------------------------------------------------------
import argparse
import os
import re
import shutil
import traceback
from datetime import datetime
from pathlib import Path
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# =============================================================================
prj_top_dir_path = Path(
    "/srv/user/private/src/git/linux/script/py_custom_cmd"
).resolve()
bin_dir_path = prj_top_dir_path / "bin"
doc_dir_path = prj_top_dir_path / "doc"
src_dir_path = prj_top_dir_path / "src"
lib_dir_path = src_dir_path / "common"
# 固定パスの定義
utils_dir_path = lib_dir_path / "utils"
shared_dir_path = lib_dir_path / "shared"
import_fast = ["check_root"]
import_pkgs = ["infosystem"]
file_pattern = re.compile(r"^[^_][a-z_]+.py")
func_pattern = re.compile(
    r"^(?:async\s+def|def)\s+([^_][a-zA-Z_][a-zA-Z0-9_]*)"
    r"|"
    r"^(?:class)\s+([^_][a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE,
)


# -----------------------------------------------------------------------------
def get_data(target_dir: Path) -> list[dict[str, Any]]:
    _list_datas: list[dict[str, Any]] = []
    for _target_path in target_dir.glob("*.py"):
        _target_path = _target_path.resolve()
        match = file_pattern.search(str(_target_path.name))
        if match:
            with open(_target_path, mode="r", encoding="utf-8", newline=None) as f:
                _target_data: str = str(f.read())
            _dict_data = {"path": _target_path, "function": ""}
            _list_datas.append(_dict_data)
            for _line in _target_data.splitlines():
                _dict_data = ""
                _func = ""
                match = func_pattern.search(_line)
                if match:
                    if match.group(1):
                        _func = match.group(1)
                    elif match.group(2):
                        _func = match.group(2)
                else:
                    match = pkgs_pattern.search(_line)
                    if match:
                        _func = match.group(1)
                if _func and _func not in ("main", "initialize"):
                    _dict_data = {
                        "path": _target_path,
                        "function": _func,
                    }
                    _list_datas.append(_dict_data)
    return _list_datas


# -----------------------------------------------------------------------------
def generate_data(target_dir: Path, list_datas: list[dict[str, Any]]) -> list[str]:
    list_texts = []
    if list_datas:
        list_datas.sort(key=lambda d: d["function"])
        _date_time = datetime.now().astimezone().strftime("%Y/%m/%d %H:%M:%S %Z (%z)")
        list_texts.append(
            f'"""Common Function Package: {target_dir.name} '
            f'[generated: {_date_time}]"""'
        )
        list_texts.append("")
        import_texts: list[dict[str, str]] = []
        for dict_data in list_datas:
            _module = dict_data["path"].stem
            if _module in import_fast:
                import_dict = {
                    "from": f"from . import {_module}",
                    "del": f"del {_module}",
                }
                import_texts.append(import_dict)
        if import_texts:
            list_texts.append("# ruff: isort: off")
            for d in import_texts:
                list_texts.append(d["from"])
            list_texts.append("")
            for d in import_texts:
                list_texts.append(d["del"])
            list_texts.append("# ruff: isort: on")
            list_texts.append("")
        title = "# --- Python library "
        list_texts.append(f"{title}{'-' * (79 - len(title))}")
        list_texts.append("import importlib  # noqa: E402")
        list_texts.append("")
        list_texts.append("")
        title = "# --- my library "
        list_texts.append(f"{title}{'-' * (79 - len(title))}")
        found_funcs = set()
        pkg_module_paths = {}
        for dict_data in list_datas:
            _func = dict_data["function"]
            if not _func:
                continue
            if _func in import_pkgs:
                _dir_name = dict_data["path"].parent.name
                _stem_name = dict_data["path"].stem
                if _dir_name == target_dir.name:
                    pkg_module_paths[_func] = f".{_stem_name}"
                else:
                    pkg_module_paths[_func] = f"..{_dir_name}.{_stem_name}"
            else:
                found_funcs.add(_func)
        missing_pkgs = [pkg for pkg in import_pkgs if pkg not in pkg_module_paths]
        # -----------------------------------------------------------------
        list_texts.append("__all__ = [")
        for pkg in pkg_module_paths:
            list_texts.append(f'    "{pkg}",')
        if target_dir in (utils_dir_path, shared_dir_path):
            for pkg in missing_pkgs:
                list_texts.append(f'    "{pkg}",')
        for dict_data in list_datas:
            _func = dict_data["function"]
            if _func and _func not in import_pkgs:
                list_texts.append(f'    "{_func}",')
        list_texts.append("]")
        list_texts.append("")
        # -----------------------------------------------------------------
        list_texts.append("_MODULE_MAP = {")
        for pkg, path in pkg_module_paths.items():
            list_texts.append(f'    "{pkg}": "{path}",')
        if target_dir in (utils_dir_path, shared_dir_path):
            for pkg in missing_pkgs:
                list_texts.append(f'    "{pkg}": "..utils.my_config",')
        for dict_data in list_datas:
            _func = dict_data["function"]
            if _func and _func not in import_pkgs:
                _module = dict_data["path"].stem
                list_texts.append(f'    "{_func}": ".{_module}",')
        list_texts.append("}")
        list_texts.append("")
        list_texts.append("")
        # -----------------------------------------------------------------
        list_texts.append("def __getattr__(name):")
        list_texts.append("    if name in _MODULE_MAP:")
        list_texts.append(
            "        module = importlib.import_module(_MODULE_MAP[name], __name__)"
        )
        list_texts.append("        return getattr(module, name)")
        list_texts.append(
            '    raise AttributeError(f"module {__name__} has no attribute {name}")'
        )
    return list_texts


def generate_file(dest_path: Path, list_texts: list[str]) -> None:
    if dest_path.exists() and dest_path.is_file():
        # --- backup --------------------------------------------------
        _timestamp = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
        _base_name = dest_path.stem
        _ext = dest_path.suffix
        _backup_path = dest_path.with_name(f"{_base_name}_{_timestamp}{_ext}")
        shutil.copy2(dest_path, _backup_path)
        # --- history & cleanup ---------------------------------------
        _all_files = dest_path.parent.glob(f"{_base_name}_*{_ext}")
        _pattern = re.compile(
            rf"^{re.escape(_base_name)}_\d{{14}}_\d{{6}}{re.escape(_ext)}$"
        )
        backups = []
        for f in _all_files:
            if _pattern.match(f.name):
                backups.append(str(f))
        backups.sort(key=os.path.getmtime)
        # --- cleanup -----------------------------------------------------
        while len(backups) > 3:
            oldest_backup = backups.pop(0)
            os.remove(oldest_backup)
    # -----------------------------------------------------------------
    with open(dest_path, mode="w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(list_texts) + "\n")


def process_directory(target_dir: Path) -> None:
    """指定されたディレクトリの__init__.pyを自動生成する"""
    if not target_dir or not target_dir.exists():
        print(f"Warning: Directory does not exist: {target_dir}")
        return
    print(f"Processing: {target_dir}")
    list_datas = get_data(target_dir=target_dir)
    list_texts = generate_data(target_dir=target_dir, list_datas=list_datas)
    dest_path = Path(target_dir / "__init__.py").resolve()
    generate_file(dest_path=dest_path, list_texts=list_texts)


# -----------------------------------------------------------------------------
if __name__ == "__main__":
    # コマンドライン引数の解析定義
    parser = argparse.ArgumentParser(
        description="Generate __init__.py for specific directories."
    )
    parser.format_help
    parser.add_argument(
        "-p",
        "--project-dir",
        type=str,
        default=str(src_dir_path / "tools"),
        help="Path to the custom project directory (default: src/tools)",
    )
    args = parser.parse_args()
    # 引数からproject_dirパスを生成
    project_dir = Path(args.project_dir).resolve()
    try:
        pattern_str = rf"^({'|'.join(import_pkgs)})[ ]*=.+$"
        pkgs_pattern = re.compile(pattern_str)
        # 1. 共通ライブラリ(utils, shared)の実行
        print("--- Step 1: Processing Common Libraries ---")
        for common_dir in (utils_dir_path, shared_dir_path):
            process_directory(common_dir)
        # 2. プロジェクトディレクトリの実行（完全に分離して実行）
        print("\n--- Step 2: Processing Project Directory ---")
        process_directory(project_dir)
    except (OSError, Exception) as e:
        _summary = traceback.extract_tb(e.__traceback__)[-1]
        print(f"Fatal error: {e}")
        if not isinstance(e, OSError):
            print(f"file name  : {_summary.filename}")
        print(f"line number: {_summary.lineno}")
        raise SystemExit from e
# --- eof ---------------------------------------------------------------------
