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
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_debug import debug_logger
from ..utils.my_json import json_load, json_save
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint
from .my_convert import get_text2list, put_list2text, spc_decode, spc_encode

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
    def __init__(self, path_src: Path) -> None:
        """Method for initializing the DistributionData class.
        Args:
            path_src (Path, optional): Source path. Defaults to None.
        """
        self._valid_fields = {f.name for f in fields(DistributionData)}
        self.load(path_src)

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
    def load(self, path_src: Path) -> None:
        """Load file

        Args:
            path_src (Path): Source path
        """
        raw_data = json_load(path_src)
        decoded_data = spc_decode(raw_data)
        self.data: list[DistributionData] = [
            DistributionData(**d) if isinstance(d, dict) else d for d in decoded_data
        ]

    @debug_logger
    def save(self, path_dest: Path) -> None:
        """Save file
        Args:
            path_dest (Path): Destination path
        """
        data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        encoded_data = spc_encode(data_dicts)
        json_save(path_dest, encoded_data)

    @debug_logger
    def findregexp(
        self, queries: list[dict[str, str]]
    ) -> list[DistributionData] | None:
        """Search for the data class within self.data. (Supports regular expressions)

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
    def finds(self, **kwargs) -> list[DistributionData] | None:
        """Search for the data class within self.data.

        Returns:
            list[DistributionData] | None: Search results for the key
        """
        return [
            item
            for item in self.data
            if all(getattr(item, key, None) == value for key, value in kwargs.items())
        ]

    @debug_logger
    def find(self, **kwargs) -> list[DistributionData] | None:
        """Search for the data class within self.data. (The first one)

        Returns:
            list[DistributionData] | None: Search results for the key (The first one)
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
        data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        list2markdown(path_dest, md_title, data_dicts)

    @debug_logger
    def dump(self, wrap: bool = False) -> None:
        """Data dump output

        Args:
            wrap (bool, optional): Toggle text wrapping. Defaults to False.
        """
        for line in self.data:
            text = line if wrap else f"{line!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{text}{Color.reset}")

    @debug_logger
    def get_text2list(self, path_src: Path) -> None:
        """Text file to list
        Args:
            path_src (Path): Source path
        """
        raw_data = get_text2list(path_src)
        decoded_data = spc_decode(raw_data)
        self.data: list[DistributionData] = [
            DistributionData(**d) if isinstance(d, dict) else d for d in decoded_data
        ]

    @debug_logger
    def put_list2text(self, path_dest: Path, format_str: str) -> None:
        """list to text file
        Args:
            path_dest (Path): Destination path
            format_str (str): Output format
        """
        data_dicts = [d.__dict__ if hasattr(d, "__dict__") else d for d in self.data]
        encoded_data = spc_encode(data_dicts)
        put_list2text(path_dest, encoded_data, format_str)
        # put_list2text(path_dest, [asdict(item) for item in self.data], format_str)

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
