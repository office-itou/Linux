"""media.dat I/O"""

# --- Python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_json import json_load, json_save
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint
from .my_common_cfg import InfoConfiguration
from .my_convert import get_text2list, put_list2text, spc_decode, spc_encode


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
    def __init__(self, path_src: Path, info_conf: InfoConfiguration) -> None:
        """Method for initializing the MediaData class.
        Args:
            path_src (Path, optional): Source path. Defaults to None.
            info_conf (Any, optional): common.cfg interface class. Defaults to None.
        """
        self._valid_fields = {f.name for f in fields(MediaData)}
        self.load(path_src, info_conf)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            return getattr(self.data[0], name) if self.data else ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    @debug_logger
    def load(self, path_src: Path, info_conf: InfoConfiguration) -> None:
        """Load file"""
        self.data: list[MediaData] = [
            MediaData(**d) if isinstance(d, dict) else d
            for d in info_conf.conv2data(spc_decode(json_load(path_src)))
        ]

    @debug_logger
    def save(self, path_dest: Path, info_conf: InfoConfiguration) -> None:
        """Save file
        Args:
            path_dest (str): Destination path
            info_conf (InfoConfiguration): common.cfg interface class
        """
        json_save(path_dest, spc_encode(info_conf.conv2variable(self.data)))

    @debug_logger
    def findregexp(self, queries: list[dict[str, str]]) -> list[MediaData] | None:
        """Data search in common.cfg (Supports regular expressions)

        Args:
            queries (list[dict[str, str]]): Query

        Returns:
            list[DistributionData] | None: Search results for the query
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
    def finds(self, **kwargs) -> list[MediaData] | None:
        """Data search in common.cfg

        Returns:
            list[DistributionData] | None: Search results for the key
        """
        return [
            item
            for item in self.data
            if all(getattr(item, key, None) == value for key, value in kwargs.items())
        ]

    @debug_logger
    def find(self, **kwargs) -> list[MediaData] | None:
        """_summary_

        Returns:
            list[DistributionData] | None: Search results for the key(The first one)
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
    def get_text2list(self, path_src: Path, info_conf: InfoConfiguration) -> None:
        """Text file to list
        Args:
            path_src (str): Source path
            info_conf (InfoConfiguration): common.cfg interface class
        """
        list_data = get_text2list(path_src)
        decoded_data = spc_decode(list_data)
        self.data = info_conf.conv2data(decoded_data)

    @debug_logger
    def put_list2text(
        self, path_dest: Path, format_str: str, info_conf: InfoConfiguration
    ) -> None:
        """list to text file
        Args:
            path_dest (str): Destination path
            format_str (str): Output format
            info_conf (InfoConfiguration): common.cfg interface class
        """
        # [asdict(item) for item in self.conv2variable(info_conf)],
        put_list2text(
            path_dest,
            self.conv2variable(info_conf),
            format_str,
        )

    @debug_logger
    def conv2data(self, info_conf: InfoConfiguration) -> None:
        """Convert actual data to variable names
        Args:
            info_conf (InfoConfiguration): common.cfg interface class
        """
        return info_conf.conv2data(self.data)

    @debug_logger
    def conv2variable(self, info_conf: InfoConfiguration) -> list[dict[str, Any]]:
        """Convert variable names to actual data
        Args:
            info_conf (InfoConfiguration): common.cfg interface class
        Returns:
            list[dict[str, Any]]: Conversion data
        """
        # dict_list = [asdict(item) for item in self.data]
        converted_data = info_conf.conv2variable(self.data)
        if hasattr(self, "_to_mediadata_list"):
            list_data = self._to_mediadata_list(converted_data)
        else:
            list_data = [
                MediaData(**item) if isinstance(item, dict) else item
                for item in converted_data
            ]
        return list_data


# --- eof ---------------------------------------------------------------------
