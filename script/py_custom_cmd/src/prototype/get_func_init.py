#!/usr/bin/env python3
"""Test text output"""

# --- Python library ----------------------------------------------------------
import re
from pathlib import Path

# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import file_read, file_write
# ruff: isort: on

prj_top_dir_path = Path("/srv/user/private/src/git/linux/script/py_custom_cmd")
bin_dir_path = prj_top_dir_path / "bin"
doc_dir_path = prj_top_dir_path / "doc"
src_dir_path = prj_top_dir_path / "src"
lib_dir_path = src_dir_path / "common"
utils_dir_path = lib_dir_path / "utils"
shared_dir_path = lib_dir_path / "shared"

file_pattern = re.compile(r"^my_[a-z_]+.py")
func_pattern = re.compile(
    r"^(?:async\s+def|def)\s+([a-zA-Z_][a-zA-Z0-9_]*)"
    r"|"
    r"^(?:class)\s+([a-zA-Z_][a-zA-Z0-9_]*)",
    re.MULTILINE,
)
for target_dir in (utils_dir_path, shared_dir_path):
    list_datas = []
    for target_path in target_dir.glob("my_*.py"):
        match = file_pattern.search(str(target_path.name))
        if match:
            # print(target_path)
            target_data: str = str(file_read(target_path, text=True))
            # with open(target_path, mode="r", encoding="utf-8", newline=None) as f:
            #    target_data: str = str( f.read())
            for line in target_data.splitlines():
                match = func_pattern.search(line)
                if match:
                    # print(match.group(1))
                    dict_data = ""
                    if match.group(1):
                        dict_data = {"path": target_path, "function": match.group(1)}
                    elif match.group(2):
                        dict_data = {"path": target_path, "function": match.group(2)}
                    if dict_data:
                        list_datas.append(dict_data)
        if list_datas:
            list_texts = []
            list_texts.append(f'"""Common Function Package: {target_dir.name}"""')
            list_texts.append("")
            list_texts.append(
                "# --- Python library ----------------------------------------------------------"
            )
            list_texts.append("import importlib")
            list_texts.append("")
            list_texts.append(
                "# --- my library --------------------------------------------------------------"
            )
            list_texts.append("from ..utils.my_config import infosystem")
            list_texts.append("")
            list_texts.append("")
            list_texts.append("__all__ = [")
            list_texts.append('    "infosystem",')
            for dict_data in list_datas:
                list_texts.append(f'    "{dict_data["function"]}",')
            list_texts.append("]")
            list_texts.append("")
            # ---------------------------------------------------------------------
            list_texts.append("_MODULE_MAP = {")
            for dict_data in list_datas:
                list_texts.append(
                    f'    "{dict_data["function"]}": ".{dict_data["path"].stem}",'
                )
            list_texts.append("}")
            list_texts.append("")
            list_texts.append("")
            # ---------------------------------------------------------------------
            list_texts.append("def __getattr__(name):")
            list_texts.append("    if name in _MODULE_MAP:")
            list_texts.append(
                "        module = importlib.import_module(_MODULE_MAP[name], __name__)"
            )
            list_texts.append("        return getattr(module, name)")
            list_texts.append(
                '    raise AttributeError(f"module {__name__} has no attribute {name}")'
            )
            # ---------------------------------------------------------------------
            # list_texts.append("def __getattr__(name):")
            # for dict_data in list_datas:
            #    list_texts.append(f'    if name == "{dict_data["function"]}":')
            #    list_texts.append(
            #        f'        module = importlib.import_module(".{dict_data["path"].stem}", __name__)'
            #    )
            #    list_texts.append("        return getattr(module, name)")
            #    list_texts.append("")
            # list_texts.append(
            #    '    raise AttributeError(f"module {__name__} has no attribute {name}")\n'
            # )
            file_write(
                target_dir / "__init__.py",
                "\n".join(list_texts) + "\n",
                text=True,
                backup=True,
            )
            # with open(target_dir / "__init__.py", mode="w", encoding="utf-8", newline="\n") as f:
            #    f.write("\n".join(list_texts) + "\n")
