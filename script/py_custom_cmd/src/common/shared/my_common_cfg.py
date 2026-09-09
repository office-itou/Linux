"""common.cfg I/O"""

# --- Python library ----------------------------------------------------------
import re
import sys
from dataclasses import asdict, dataclass, fields
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_error import handle_fatal_error
from ..utils.my_fileio import file_read
from ..utils.my_markdown import list2markdown
from ..utils.my_message import get_caller_name, message_alert
from ..utils.my_string import eprint


# -----------------------------------------------------------------------------
@dataclass
class ConfigurationData:
    """common.cfg data class"""

    key: str = ""
    value: str = ""
    comment: str = ""


class InfoConfiguration:
    """common.cfg interface class"""

    @debug_logger
    def __init__(self):
        """Method for initializing the ConfigurationData class."""
        self._valid_fields = {f.name for f in fields(ConfigurationData)}
        self.data: list[ConfigurationData] = []
        self.load()

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def finds(self, **kwargs) -> list[ConfigurationData] | None:
        """Data search in common.cfg
        Returns:
            list[ConfigurationData] | None: Search results for the key
        """
        results = []
        for item in self.data:
            if all(getattr(item, key, None) == value for key, value in kwargs.items()):
                results.append(item)
        return results

    def find(self, **kwargs) -> ConfigurationData | None:
        """Data search in distribution.dat
        Returns:
            ConfigurationData | None: Search results for the key(The first one)
        """
        results = self.finds(**kwargs)
        return results[0]

    @debug_logger
    def load(self) -> None:
        """Load file"""
        raw_list = load()
        self.data = [
            ConfigurationData(**item) if isinstance(item, dict) else item
            for item in raw_list
        ]

    @debug_logger
    def markdown(self, path_dest: str, md_title: str) -> None:
        """Generating Markdown
        Args:
            path_dest (str): Destination path
            md_title (str): Markdown title
        """
        dict_list = [asdict(item) for item in self.data]
        list2markdown(path_dest, md_title, dict_list)

    @debug_logger
    def dump(self, cut: bool = True) -> None:
        """Data dump output"""
        for line in self.data:
            text = f"{line!s:.{infosystem.columns}s}" if cut else line
            eprint(f"{Color.yellow}{text}{Color.reset}")

    @debug_logger
    def conv2data(self, data: list) -> list:
        """Convert actual data to variable names
        Args:
            data (list): Source
        Returns:
            list: Result
        """
        dict_list = [asdict(item) for item in self.data]
        return conv2data(dict_list, data)

    @debug_logger
    def conv2variable(self, data: list) -> list:
        """Convert variable names to actual data
        Args:
            data (list): Source
        Returns:
            list: Conversion data
        """
        dict_list = [asdict(item) for item in self.data]
        return conv2variable(dict_list, data)

    @debug_logger
    def get_path(self, key: str) -> Path:
        """Gets the key path.
        Args:
            key (str): Key
        Returns:
            Path: Path
        """
        return Path(self.find(key=key).value)


@debug_logger
def load() -> list[dict[str, str]]:
    """load data in common.cfg

    Returns:
        list[dict[str, str]]: list_conf
    """
    caller = get_caller_name()
    try:
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
            message_alert(caller, f"file not found: {file_conf}")
            sys.exit(1)
        # --- get setting items ---------------------------------------------------
        data_dist = file_read(path_conf)
        pattern = re.compile(r'^(\w+)="([^"]*)"\s*(?:#\s*(.*))?$')
        list_conf = []
        for line in data_dist.splitlines():
            line_raw = line.strip()
            if not re.match("^[A-Z]", line_raw):
                continue
            # --- convert ---------------------------------------------------------
            match = pattern.match(line_raw)
            if match:
                var_name = match.group(1)  # Variable Name
                value = match.group(2)  # Setting Value
                comment = match.group(3)  # Comment (None if not applicable)
                list_conf.append({"key": var_name, "value": value, "comment": comment})
        # --- convert setting items -----------------------------------------------
        pattern = re.compile(r":_([A-Z0-9_]+)_:")
        dict_conf = {}
        for i, item in enumerate(list_conf):
            key = item["key"]
            value = item["value"]
            comment = item["comment"]
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
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


@debug_logger
def conv2data(list_conf: list[ConfigurationData], list_orig: list) -> list:
    """convert to data format

    Args:
        list_conf (list[ConfigurationData]): list_orig
        list_orig (list): list_orig

    Returns:
        list: list_conv
    """
    dict_conf = {item["key"]: item["value"] for item in list_conf}
    pattern = re.compile(r":_([A-Z0-9_]+)_:")
    list_conv = []
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


@debug_logger
def conv2variable(list_conf: list[ConfigurationData], list_orig: list) -> list:
    """convert to variable format

    Args:
        list_conf (list[ConfigurationData]): list_conf
        list_orig (list): list_orig

    Returns:
        list: list_conv
    """
    reverse_conf = {}
    for item in list_conf:
        key, value = item["key"], item["value"]
        if key.startswith("DIRS_") and isinstance(value, str) and value.startswith("/"):
            reverse_conf[value] = f":_{key}_:"
    sorted_paths = sorted(reverse_conf.keys(), key=len, reverse=True)
    # --- convert -------------------------------------------------------------
    list_conv = []
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
