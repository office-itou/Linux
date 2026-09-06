"""distribution.dat I/O"""

# --- Python library ----------------------------------------------------------
import json
import re
from dataclasses import asdict, dataclass, fields
from operator import attrgetter
from typing import Any

from packaging.version import InvalidVersion
from packaging.version import parse as parse_version

# from packaging.version import InvalidVersion
# from packaging.version import parse as parse_version
# --- my library --------------------------------------------------------------
from ..utils.my_colors import Color
from ..utils.my_config import infosystem
from ..utils.my_fileio import get_text2list, put_list2text
from ..utils.my_markdown import list2markdown
from ..utils.my_string import eprint, spc_decode, spc_encode


# -----------------------------------------------------------------------------
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

    def __init__(self, src_path: str | None = None):
        """Method for initializing the DistributionData class.

        Args:
            src_path (str | None, optional): Source path. Defaults to None.
        """
        self._valid_fields = {f.name for f in fields(DistributionData)}
        self.data: list[DistributionData] = []
        if src_path:
            self.load(src_path)

    def __getattr__(self, name: str) -> Any:
        if name in self._valid_fields:
            if self.data:
                return getattr(self.data[0], name)
            return ""
        raise AttributeError(
            f"'{self.__class__.__name__}' object has no attribute '{name}'"
        )

    def find(self, **kwargs) -> DistributionData | None:
        """Data search in distribution.dat

        Returns:
            DistributionData | None: Search results for the key
        """
        for item in self.data:
            if all(getattr(item, key, None) == value for key, value in kwargs.items()):
                return item
        return None

    def load(self, src_path: str) -> None:
        """Load file

        Args:
            src_path (str): Source path
        """
        with open(src_path, "r", encoding="utf-8") as f:
            raw_data = json.load(f)
        decoded_data = spc_decode(raw_data)
        self.data = [
            DistributionData(**item) if isinstance(item, dict) else item
            for item in decoded_data
        ]

    def save(self, dst_path: str):
        """Save file

        Args:
            dst_path (str): Destination path
        """
        dict_list = [asdict(item) for item in self.data]
        encoded_data = spc_encode(dict_list)
        with open(dst_path, "w", encoding="utf-8") as f:
            json.dump(encoded_data, f, ensure_ascii=False, indent=4)

    def markdown(self, dst_path: str, md_title: str) -> None:
        """Generating Markdown

        Args:
            dst_path (str): Destination path
            md_title (str): Markdown title
        """
        dict_list = [asdict(item) for item in self.data]
        list2markdown(dst_path, md_title, dict_list)

    def dump(self) -> None:
        """Data dump output"""
        for line in self.data:
            text = f"{line!s:.{infosystem.columns}s}"
            eprint(f"{Color.yellow}{text}{Color.reset}")

    def get_text2list(self, src_path: str) -> None:
        """Text file to list

        Args:
            src_path (str): Source path
        """
        list_data = get_text2list(src_path)
        decoded_data = spc_decode(list_data)
        self.data = [
            DistributionData(**item) if isinstance(item, dict) else item
            for item in decoded_data
        ]

    def put_list2text(self, dst_path: str, format_str: str) -> None:
        """list to text file

        Args:
            dst_path (str): Destination path
            format_str (str): Output format
        """
        put_list2text(dst_path, [asdict(item) for item in self.data], format_str)

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


# --- eof ---------------------------------------------------------------------
