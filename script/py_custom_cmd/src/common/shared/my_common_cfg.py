from __future__ import annotations

"""common.cfg I/O"""

# --- Python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
from pathlib import Path
from typing import TYPE_CHECKING, Any

# --- my library --------------------------------------------------------------
if TYPE_CHECKING:
    from ..shared.my_media_dat import MediaData
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
        """Special methods

        Args:
            name (str): Attribute name

        Raises:
            AttributeError: AttributeError

        Returns:
            Any: Attribute value [(self.data[0], name) or ""]
        """
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
    def findregexp(self, queries: list[dict[str, str]]) -> list[ConfigurationData]:
        """Search for the data class within self.data. (Supports regular expressions)

        Args:
            queries (list[dict[str, str]]): Query

        Returns:
            list[ConfigurationData]: Search results for the query
        """
        _results: list[ConfigurationData] = []
        _compiled_queries = [
            (_q_key, re.compile(_q_pattern))
            for _query in queries
            for _q_key, _q_pattern in _query.items()
        ]
        for _class_data in self.data:
            for _q_key, _pattern in _compiled_queries:
                _target_str = getattr(_class_data, _q_key, None)
                if _target_str and _pattern.search(_target_str):
                    _results.append(_class_data)
                    break
        return _results

    @debug_logger
    def finds(self, **kwargs) -> list[ConfigurationData]:
        """Search for the data class within self.data.

        Returns:
            list[ConfigurationData]: Search results for the key
        """
        MISSING = object()
        return [
            _class_data
            for _class_data in self.data
            if all(
                getattr(_class_data, _key, MISSING) == _value
                for _key, _value in kwargs.items()
            )
        ]

    @debug_logger
    def find(self, **kwargs) -> ConfigurationData:
        """Search for the data class within self.data. (The first one)

        Returns:
            list: Search results for the key (The first one)
        """
        MISSING = object()
        return next(
            _class_data
            for _class_data in self.data
            if all(
                getattr(_class_data, _key, MISSING) == _value
                for _key, _value in kwargs.items()
            )
        )

    @debug_logger
    def markdown(self, dest_path: str, md_title: str) -> None:
        """Generating Markdown
        Args:
            dest_path (str): Destination path
            md_title (str): Markdown title
        """
        list2markdown(
            dest_path, md_title, [_class_data.__dict__ for _class_data in self.data]
        )

    @debug_logger
    def dump(self, wrap: bool = False) -> None:
        """Data dump output

        Args:
            wrap (bool, optional): Toggle text wrapping. Defaults to False.
        """
        for _class_data in self.data:
            _text = _class_data if wrap else f"{_class_data!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{_text}{Color.reset}")

    @debug_logger
    def conv2data(self, src_data: list[MediaData]) -> list[MediaData]:
        """Convert actual data to variable names
        Args:
            src_data (list): Source data
        Returns:
            list: Result
        """
        return conv2data([_class_data.__dict__ for _class_data in self.data], src_data)

    @debug_logger
    def conv2variable(self, src_data: list[MediaData]) -> list[MediaData]:
        """Convert variable names to actual data
        Args:
            src_data (list): Source data
        Returns:
            list: Conversion data
        """
        return conv2variable(
            [_class_data.__dict__ for _class_data in self.data], src_data
        )

    @debug_logger
    def get_path(self, key: str) -> Path:
        """Gets the key path.
        Args:
            key (str): Key
        Returns:
            Path: Path
        """
        _path_str = self.find(key=key).value
        if not _path_str:
            raise ValueError(f"No such key '{key}'")
        return Path(_path_str).resolve()


# -----------------------------------------------------------------------------
def load() -> list[ConfigurationData]:
    """load data in common.cfg

    Raises:
        SystemExit: raise SystemExit from e

    Returns:
        list[ConfigurationData]: list[ConfigurationData]
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
