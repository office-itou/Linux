"""distribution.dat I/O"""

# --- Python library ----------------------------------------------------------
import json
from dataclasses import asdict, dataclass, fields
from typing import Any

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


# --- eof ---------------------------------------------------------------------
