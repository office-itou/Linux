###############################################################################
#
# 	common.cfg I/O
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
import re
import sys
from dataclasses import asdict, dataclass, fields
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from py_common.my_colors import color
from py_common.my_config import infosystem
from py_common.my_debug import debug_logger
from py_common.my_markdown import list2markdown
from py_common.my_message import message_alert
from py_common.my_string import eprint


# -----------------------------------------------------------------------------
@dataclass
class ConfigurationData:
    key: str = ""
    value: str = ""
    comment: str = ""


class InfoConfiguration:
    def __init__(self):
        self.data: list[ConfigurationData] = []
        self._valid_fields = {f.name for f in fields(ConfigurationData)}
        self.load()

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def find(self, **kwargs) -> ConfigurationData | None:
        for item in self.data:
            match = True
            for key, value in kwargs.items():
                if getattr(item, key, None) != value:
                    match = False
                    break
            if match:
                return item

    @debug_logger
    def load(self) -> None:
        raw_list = load()
        self.data = [ConfigurationData(**item) for item in raw_list]

    def markdown(self, path: str, title: str) -> None:
        dict_list = [asdict(item) for item in self.data]
        list2markdown(path, title, dict_list)

    def dump(self) -> None:
        for line in self.data:
            text = f"{line!s:.{infosystem.columns}s}"
            eprint(f"{color.yellow}{text}{color.reset}")

    def conv2data(self, data: list) -> list:
        dict_list = [asdict(item) for item in self.data]
        return conv2data(dict_list, data)

    def conv2variable(self, data: list) -> list:
        dict_list = [asdict(item) for item in self.data]
        return conv2variable(dict_list, data)

    def get(self, key: str, default: str = "-") -> str:
        result = next((item for item in self.data if item.key == key), None)
        return result.value if result else default


# -----------------------------------------------------------------------------
# descript: load data in common.cfg
#   input :                       : unused
#   output:                       : unused
#   return: list_conf             : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def load() -> list[dict[str, str]]:
    dirs_data = "/srv/user/share/conf/_data"
    file_conf = "common.cfg"
    path_conf = None
    # --- file search ---------------------------------------------------------
    for dirs in (".", dirs_data):
        path = Path(dirs) / file_conf
        if path.exists():
            path_conf = path
            break
    if not path_conf:
        message_alert(f"file not found: {file_conf}")
        sys.exit(1)
    # --- get setting items ---------------------------------------------------
    list_conf = []
    with open(path_conf, "r", encoding="utf-8") as f:
        for line in f:
            if not re.match("^[A-Z]", line):
                continue
            # --- get comment block -------------------------------------------
            line_raw = line.rstrip("\r\n")
            if "#" in line_raw:
                line_content, comnt = line_raw.split("#", 1)
                comnt = f"# {comnt.strip()}"
            else:
                line_content, comnt = line_raw, ""
            line_clean = line_content.rstrip()
            if "=" not in line_clean:
                continue
            # --- get key and  value ------------------------------------------
            key, value = line_clean.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"')
            # --- convert setting items -----------------------------------------------
            list_conf.append({"key": key, "value": value, "comment": comnt})
    # --- convert setting items -----------------------------------------------
    dict_conf = {}
    pattern = re.compile(r":_([A-Z0-9_]+)_:")
    for i, item in enumerate(list_conf):
        key = item["key"]
        value = item["value"]
        dict_conf[key] = value

        for _ in range(10):
            match = pattern.search(value)
            if not match:
                break
            match_text = match.group(0)
            match_key = match.group(1)
            if match_key in dict_conf:
                value = value.replace(match_text, dict_conf[match_key])
            else:
                break
        # --- generate output data --------------------------------------------
        list_conf[i] = {"key": key, "value": value, "comment": item["comment"]}
    # --- return --------------------------------------------------------------
    return list_conf


# -----------------------------------------------------------------------------
# descript: convert to data format
#   input : list_conf             : input
#   input : list_orig             : input
#   output:                       : unused
#   return: list_conv             : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def conv2data(list_conf: list, list_orig: list) -> list:
    dict_conf = {item["key"]: item["value"] for item in list_conf}
    list_conv = []
    pattern = re.compile(r":_([A-Z0-9_]+)_:")
    # --- convert -------------------------------------------------------------
    for item in list_orig:
        dict_orig = {}
        for key, value in item.items():
            if isinstance(value, str):
                for _ in range(10):
                    match = pattern.search(value)
                    if not match:
                        break
                    match_text = match.group(0)
                    match_key = match.group(1)
                    if match_key in dict_conf:
                        value = value.replace(match_text, dict_conf[match_key])
                    else:
                        break
            dict_orig[key] = value
        list_conv.append(dict_orig)
    # --- return --------------------------------------------------------------
    return list_conv


# -----------------------------------------------------------------------------
# descript: convert to variable format
#   input : list_conf             : input
#   input : list_orig             : input
#   output:                       : unused
#   return: list_conv             : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def conv2variable(list_conf: list, list_orig: list) -> list:
    reverse_conf = {}
    for item in list_conf:
        key, value = item["key"], item["value"]
        if key.startswith("DIRS_") and isinstance(value, str) and value.startswith("/"):
            reverse_conf[value] = f":_{key}_:"
    sorted_paths = sorted(reverse_conf.keys(), key=len, reverse=True)
    list_conv = []
    # --- convert -------------------------------------------------------------
    for item in list_orig:
        dict_orig = {}
        for key, value in item.items():
            if isinstance(value, str):
                for path in sorted_paths:
                    if path in value:
                        value = value.replace(path, reverse_conf[path])
            dict_orig[key] = value
        list_conv.append(dict_orig)
    # --- return --------------------------------------------------------------
    return list_conv


# --- eof ---------------------------------------------------------------------
