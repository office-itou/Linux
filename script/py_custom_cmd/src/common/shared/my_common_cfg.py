"""common.cfg I/O"""

# --- Python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
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


@debug_logger
class InfoConfiguration:
    """common.cfg interface class"""

    @debug_logger
    def __init__(self) -> None:
        """Method for initializing the ConfigurationData class."""
        self._valid_fields = {f.name for f in fields(ConfigurationData)}
        self.load()

    @debug_logger
    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            return getattr(self.data[0], name) if self.data else ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    @debug_logger
    def load(self) -> None:
        """Load file"""
        self.data: list[ConfigurationData] = [
            ConfigurationData(**d) if isinstance(d, dict) else d for d in load()
        ]

    @debug_logger
    def findregexp(
        self, queries: list[dict[str, str]]
    ) -> list[ConfigurationData] | None:
        """Data search in common.cfg (Supports regular expressions)

        Args:
            queries (list[dict[str, str]]): Query

        Returns:
            list[ConfigurationData] | None: Search results for the query
        """
        list_results = []
        compiled_queries = [
            (q_key, re.compile(q_pattern))
            for query in queries
            for q_key, q_pattern in query.items()
        ]
        for class_data in self.data:
            for q_key, pattern in compiled_queries:
                target_str = getattr(class_data, q_key, None)
                if target_str and pattern.search(target_str):
                    list_results.append(class_data)
                    break
        return list_results

    @debug_logger
    def finds(self, **kwargs) -> list[ConfigurationData] | None:
        """Data search in common.cfg

        Returns:
            list[ConfigurationData] | None: Search results for the key
        """
        return [
            item
            for item in self.data
            if all(getattr(item, key, None) == value for key, value in kwargs.items())
        ]

    @debug_logger
    def find(self, **kwargs) -> list[ConfigurationData] | None:
        """_summary_

        Returns:
            list[ConfigurationData] | None: Search results for the key(The first one)
        """
        results = self.finds(**kwargs)
        return results[0] if results else None

    @debug_logger
    def markdown(self, path_dest: str, md_title: str) -> None:
        """Generating Markdown
        Args:
            path_dest (str): Destination path
            md_title (str): Markdown title
        """
        list2markdown(path_dest, md_title, [item.__dict__ for item in self.data])

    @debug_logger
    def dump(self, wrap: bool = False) -> None:
        """Data dump output"""
        for line in self.data:
            text = line if wrap else f"{line!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{text}{Color.reset}")

    @debug_logger
    def conv2data(self, data: list) -> list:
        """Convert actual data to variable names
        Args:
            data (list): Source
        Returns:
            list: Result
        """
        return conv2data([item.__dict__ for item in self.data], data)

    @debug_logger
    def conv2variable(self, data: list) -> list:
        """Convert variable names to actual data
        Args:
            data (list): Source
        Returns:
            list: Conversion data
        """
        return conv2variable([item.__dict__ for item in self.data], data)


# -----------------------------------------------------------------------------
def load() -> list[ConfigurationData] | None:
    """load data in common.cfg

    Raises:
        SystemExit: raise SystemExit from e

    Returns:
        list[ConfigurationData] | None: list[ConfigurationData]
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
            raise SystemExit(1)
        # --- get setting items ---------------------------------------------------
        data_dist = file_read(path_conf)
        line_pattern = re.compile(r'^(\w+)="([^"]*)"\s*(?:(#\s*.*))?$')
        var_pattern = re.compile(r":_([A-Z0-9_]+)_:")
        dict_conf: dict[str, str] = {}
        list_conf: list[ConfigurationData] = []
        for line in data_dist.splitlines():
            line_raw = line.strip()
            if not line_raw or not line_raw[0].isupper():
                continue
            if match := line_pattern.match(line_raw):
                key = match.group(1)
                value = match.group(2)
                comment = match.group(3) or ""
                for _ in range(10):
                    if var_match := var_pattern.search(value):
                        match_text = var_match.group(0)
                        match_key = var_match.group(1)
                        if match_key in dict_conf:
                            value = value.replace(match_text, dict_conf[match_key])
                        else:
                            break
                    else:
                        break
                dict_conf[key] = value
                list_conf.append(
                    ConfigurationData(key=key, value=value, comment=comment)
                )
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
