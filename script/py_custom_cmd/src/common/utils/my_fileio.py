"""File I/O"""

# --- Python library ----------------------------------------------------------
import csv
import glob
import os
import re
import shutil
from datetime import datetime
from pathlib import Path

# --- my library --------------------------------------------------------------
from .my_debug import debug_logger
from .my_message import get_caller_name, message_alert

# from .my_string import spc_encode


@debug_logger
def file_copy(path_src: Path, path_dest: Path, backup: bool = False) -> None:
    """File copy

    Args:
        path_src (Path): Source path
        path_dest (Path): Destination path
        backup (bool, optional): Backup. Defaults to False.
    """
    os.makedirs(path_dest.parent, exist_ok=True)
    if bool == True:
        file_backup(path_dest)
    shutil.copy2(path_src, path_dest)


@debug_logger
def file_backup(src_path: str) -> None:
    """File backup

    Args:
        src_path (str): Source path
    """
    file_path = Path(src_path)
    if file_path.exists() and file_path.is_file():
        # --- backup ------------------------------------------------------
        timestamp = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
        base_name = file_path.stem
        ext = file_path.suffix
        backup_path = file_path.with_name(f"{base_name}_{timestamp}{ext}")
        shutil.copy2(src_path, backup_path)
        # --- history -----------------------------------------------------
        search_pattern = str(file_path.with_name(f"{base_name}_*{ext}"))
        backups = glob.glob(search_pattern)
        backups = [b for b in backups if b != str(src_path)]
        backups.sort(key=os.path.getmtime)
        # --- cleanup -----------------------------------------------------
        while len(backups) > 3:
            oldest_backup = backups.pop(0)
            try:
                os.remove(oldest_backup)
            except OSError as e:
                message_alert(
                    get_caller_name(),
                    f"Backup deletion failed: {oldest_backup} ({e})",
                )


@debug_logger
def get_text2list(src_path: str) -> list[dict[str, str]]:
    """Text file to list

    Args:
        src_path (str): Source path

    Returns:
        list[dict[str, str]]: Conversion data
    """
    with open(src_path, "r", encoding="utf-8", newline="") as f:
        lines = (line.strip() for line in f if line.strip())
        sanitized_lines = (re.sub(r"[ \t]+", ",", line) for line in lines)
        return list(csv.DictReader(sanitized_lines))


# def clean_value(val):
#    if val is None or val == "":
#        return "-"
#    s = str(val)
#    return s.replace(" ", "%20").replace("`", "")


@debug_logger
def put_list2text(dst_path: str, src_data: list, format_str: str) -> None:
    """list to text file

    Args:
        dst_path (str): Destination path
        src_data (list): Source data
        format_str (str): Output format
    """
    if not src_data:
        return
    header_dict = {k: k for d in src_data for k in d}
    #    cleaned_data_list = [{k: clean_value(v) for k, v in d.items()} for d in src_data]
    cleaned_data_list = [
        {k: str(v).replace(" ", "%20").replace("`", "") for k, v in d.items()}
        for d in src_data
    ]
    text_list = [format_str.format(**header_dict)] + [
        format_str.format(**d) for d in cleaned_data_list
    ]
    file_backup(dst_path)
    with open(dst_path, "w", encoding="utf-8") as f:
        f.write("\n".join(text_list) + "\n")


# --- eof ---------------------------------------------------------------------
