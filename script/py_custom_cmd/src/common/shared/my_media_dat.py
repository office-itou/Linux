from __future__ import annotations

"""media.dat I/O"""

# --- Python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
from pathlib import Path
from typing import TYPE_CHECKING, Any

# --- my library --------------------------------------------------------------
if TYPE_CHECKING:
    from ..shared.my_common_cfg import InfoConfiguration
from ..shared.my_convert import get_text2list, put_list2text, spc_decode, spc_encode
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_json import json_load, json_save
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint


# -----------------------------------------------------------------------------
@dataclass
class MediaData:
    """media.dat data class"""

    type: str = ""
    entry_flag: str = ""
    entry_name: str = ""
    entry_disp: str = ""
    version: str = ""
    latest: str = ""
    release: str = ""
    support: str = ""
    web_regexp: str = ""
    web_path: str = ""
    web_tstamp: str = ""
    web_size: str = ""
    web_check: str = ""
    web_status: str = ""
    iso_path: str = ""
    iso_tstamp: str = ""
    iso_size: str = ""
    iso_volume: str = ""
    rmk_path: str = ""
    rmk_tstamp: str = ""
    rmk_size: str = ""
    rmk_volume: str = ""
    ldr_initrd: str = ""
    ldr_kernel: str = ""
    cfg_path: str = ""
    cfg_tstamp: str = ""
    lnk_path: str = ""
    options: str = ""
    create_flag: str = ""


class InfoMedia:
    """media.dat interface class"""

    @debug_logger
    def __init__(self, src_path: Path, info_conf: InfoConfiguration) -> None:
        """Method for initializing the MediaData class.
        Args:
            src_path (Path, optional): Source path. Defaults to None.
            info_conf (Any, optional): common.cfg interface class. Defaults to None.
        """
        self._valid_fields = {f.name for f in fields(MediaData)}
        self.info_conf = info_conf
        self.load(src_path)

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
    def load(self, src_path: Path) -> None:
        """Load file

        Args:
            src_path (Path): Source path
        """
        _raw_data = json_load(src_path) if src_path.exists() else [{None}]
        _decoded_data = spc_decode(_raw_data)
        _converted_data = self.info_conf.conv2data(_decoded_data)
        self.data: list[MediaData] = [
            MediaData(**d) if isinstance(d, dict) else d for d in _converted_data
        ]

    @debug_logger
    def save(self, dest_path: Path) -> None:
        """Save file

        Args:
            dest_path (str): Destination path
        """
        _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        _converted_data = self.info_conf.conv2variable(_data_dicts)
        _encoded_data = spc_encode(_converted_data)
        json_save(dest_path, _encoded_data)

    @debug_logger
    def findregexp(self, queries: list[dict[str, str]]) -> list[MediaData]:
        """Search for the data class within self.data. (Supports regular expressions)

        Args:
            queries (list[dict[str, str]]): Query

        Returns:
            list[DistributionData]: Search results for the query
        """
        _results: list[MediaData] = []
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
    def finds(self, **kwargs) -> list[MediaData]:
        """Search for the data class within self.data.Data search in common.cfg

        Returns:
            list[DistributionData]: Search results for the key
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
    def find(self, **kwargs) -> list[MediaData]:
        """Search for the data class within self.data. (The first one)

        Returns:
            list[DistributionData]: Search results for the key (The first one)
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
    def get_text2list(self, src_path: Path) -> None:
        """Text file to list
        Args:
            src_path (str): Source path
        """
        _raw_data = get_text2list(src_path)
        _decoded_data = spc_decode(_raw_data)
        _converted_data = self.info_conf.conv2data(_decoded_data)
        self.data: list[MediaData] = [
            MediaData(**d) if isinstance(d, dict) else d for d in _converted_data
        ]

    @debug_logger
    def put_list2text(self, dest_path: Path, format_str: str) -> None:
        """list to text file
        Args:
            dest_path (str): Destination path
            format_str (str): Output format
        """
        _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        _converted_data = self.info_conf.conv2variable(_data_dicts)
        _encoded_data = spc_encode(_converted_data)
        put_list2text(dest_path, _encoded_data, format_str)

    @debug_logger
    def conv2data(self) -> None:
        """Convert actual data to variable names"""
        return self.info_conf.conv2data(self.data)

    @debug_logger
    def conv2variable(self) -> list[dict[str, Any]]:
        """Convert variable names to actual data
        Returns:
            list[dict[str, Any]]: Conversion data
        """
        _converted_data = self.info_conf.conv2variable(self.data)
        if hasattr(self, "_to_mediadata_list"):
            return self._to_mediadata_list(_converted_data)
        else:
            return [
                MediaData(**item) if isinstance(item, dict) else item
                for item in _converted_data
            ]


# --- eof ---------------------------------------------------------------------
