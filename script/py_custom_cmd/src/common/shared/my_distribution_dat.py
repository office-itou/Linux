"""distribution.dat I/O"""

# --- Python library ----------------------------------------------------------
import re
from dataclasses import dataclass, fields
from operator import attrgetter
from pathlib import Path
from typing import Any

from packaging.version import InvalidVersion
from packaging.version import parse as parse_version

# --- my library --------------------------------------------------------------
from ..shared.my_convert import (
    get_text2list,
    put_list2text,
    spc_decode,
    spc_encode,
)
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_json import json_load, json_save
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint

# -----------------------------------------------------------------------------
LIFE_MAP = {
    "-": "Current (supported)",
    "elts": "Extended Long-Term Support",
    "lts": "Long-Term Support",
    "eol": "End Of Life (unsupported)",
    "esm": "Expanded Security Maintenance",
    "esu": "Extended Security Updates",
}
ORDERED_DISTRIBUTIONS = [
    "debian",
    "ubuntu",
    "fedora",
    "centos-stream",
    "centos",
    "almalinux",
    "rockylinux",
    "miraclelinux",
    "opensuse",
    "windows",
    "winpe",
    "ati",
    "memtest86plus",
]
ORDERED_KEYS = [
    "Development",
    "Current (supported)",
    "Long-Term Support",
    "Extended Long-Term Support",
    "Extended Security Updates",
    "Expanded Security Maintenance",
    "End Of Life (unsupported)",
]


@dataclass
class DistributionData:
    """distribution.dat data class"""

    version: str = ""
    name: str = ""
    version_id: str = ""
    code_name: str = ""
    life: str = ""
    release: str = ""
    support: str = ""
    long_term: str = ""
    rhel: str = ""
    kerne: str = ""
    note: str = ""
    wallpaper: str = ""
    create_flag: str = ""
    sort_flag: str = ""


class InfoDistribution:
    """distribution.dat interface class"""

    @debug_logger
    def __init__(self, src_path: Path) -> None:
        """Method for initializing the DistributionData class.
        Args:
            src_path (Path, optional): Source path. Defaults to None.
        """
        self._valid_fields = {f.name for f in fields(DistributionData)}
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
        self.data: list[DistributionData] = [
            DistributionData(**d) if isinstance(d, dict) else d for d in _decoded_data
        ]

    @debug_logger
    def save(self, dest_path: Path) -> None:
        """Save file
        Args:
            dest_path (Path): Destination path
        """
        _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        _encoded_data = spc_encode(_data_dicts)
        json_save(dest_path, _encoded_data)

    @debug_logger
    def findregexp(self, queries: list[dict[str, str]]) -> list[DistributionData]:
        """Search for the data class within self.data. (Supports regular expressions)

        Args:
            queries (list[dict[str, str]]): Query

        Returns:
            list[DistributionData]: Search results for the query
        """
        _results: list[DistributionData] = []
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
    def finds(self, **kwargs) -> list[DistributionData]:
        """Search for the data class within self.data.

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
    def find(self, **kwargs) -> list[DistributionData]:
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
            src_path (Path): Source path
        """
        _raw_data = get_text2list(src_path)
        _decoded_data = spc_decode(_raw_data)
        self.data: list[DistributionData] = [
            DistributionData(**d) if isinstance(d, dict) else d for d in _decoded_data
        ]

    @debug_logger
    def put_list2text(self, dest_path: Path, format_str: str) -> None:
        """list to text file
        Args:
            dest_path (Path): Destination path
            format_str (str): Output format
        """
        _data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        _encoded_data = spc_encode(_data_dicts)
        put_list2text(dest_path, _encoded_data, format_str)

    @debug_logger
    def sort(
        self, distribution: str = "", reverse: bool = False
    ) -> list[DistributionData]:
        """A wrapper that sorts and outputs the DistributionData class.
        Args:
            distribution (str, optional): Target distribution. Defaults to "".
            reverse (bool, optional): Reverse off/on. Defaults to False.
        Returns:
            list[DistributionData]: DistributionData class
        """
        return sort_distribution_data(self.data, distribution, reverse)


@debug_logger
def sort_distribution_data(
    data: DistributionData, distribution: str = "", reverse: bool = False
) -> list[DistributionData]:
    """Sort and output the DistributionData class.
    Args:
        data (DistributionData): Source data
        distribution (str, optional): Target distribution. Defaults to "".
        reverse (bool, optional): Reverse off/on. Defaults to False.
    Returns:
        list[DistributionData]: DistributionData class
    """
    match = re.compile(rf"^{re.escape(distribution)}(|-).+$")
    selected_data = [item for item in data if match.match(item.version)]

    def make_universal_sort_key(item):
        v_str = item.version
        if distribution and v_str.startswith(f"{distribution}-"):
            v_str = v_str[len(distribution) + 1 :]
        base_match = re.match(
            r"^([a-zA-Z0-9_-]+?)-(?=\d|testing|sid|tumbleweed|x86|x64)", v_str
        )
        if base_match:
            base_name = base_match.group(1)
            version_part = v_str[len(base_name) + 1 :]
        else:
            base_name = ""
            version_part = v_str
        version_part = re.sub(
            r"(\d+)h(\d+)", r"\1.\2", version_part, flags=re.IGNORECASE
        )
        num_match = re.search(r"(\d+(?:\.\d+)*\S*)", version_part)
        if num_match:
            try:
                return (base_name, 2, parse_version(num_match.group(1)))
            except InvalidVersion:
                pass
        if version_part:
            return (base_name, 3, version_part)
        return (base_name, 0, parse_version("0.0.0"))

    step1 = sorted(selected_data, key=make_universal_sort_key, reverse=reverse)
    sorted_datas = sorted(step1, key=attrgetter("sort_flag"), reverse=reverse)
    return sorted_datas


@debug_logger
def sort_distribution_name(data: list) -> list:
    """Sort and output the DistributionData class.
    Args:
        data (list): Source data
    Returns:
        list: Result
    """
    max_index = len(ORDERED_DISTRIBUTIONS)

    def get_sort_key(key):
        for index, pattern in enumerate(ORDERED_DISTRIBUTIONS):
            if re.search(pattern, str(key)):
                return index
        return max_index

    return [item for item in sorted(data, key=get_sort_key)]


# --- eof ---------------------------------------------------------------------
