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


# -----------------------------------------------------------------------------
# descript: file backup
#   input : path             : input
#   output:                  : unused
#   return: data             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def file_backup(path: str) -> None:
    file_path = Path(path)
    if file_path.exists() and file_path.is_file():
        # --- backup ------------------------------------------------------
        timestamp = datetime.now().astimezone().strftime("%Y%m%d%H%M%S_%f")
        base_name = file_path.stem
        ext = file_path.suffix
        backup_path = file_path.with_name(f"{base_name}_{timestamp}{ext}")
        shutil.copy2(path, backup_path)
        # --- history -----------------------------------------------------
        search_pattern = str(file_path.with_name(f"{base_name}_*{ext}"))
        backups = glob.glob(search_pattern)
        backups = [b for b in backups if b != str(path)]
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


# -----------------------------------------------------------------------------
# descript: text file to list
#   input : path             : input
#   output:                  : unused
#   return: data             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def get_text2list(path: str) -> list[dict[str, str]]:
    with open(path, "r", encoding="utf-8", newline="") as f:
        lines = (line.strip() for line in f if line.strip())
        sanitized_lines = (re.sub(r"[ \t]+", ",", line) for line in lines)
        return list(csv.DictReader(sanitized_lines))


# -----------------------------------------------------------------------------
# descript: list to text file
#   input : path             : input
#   input : data             : input
#   input : format           : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def clean_value(val):
    if val is None or val == "":
        return "-"
    s = str(val)
    return s.replace(" ", "%20").replace("`", "")


@debug_logger
def put_list2text(path: str, data: list, format_str: str) -> None:
    if not data:
        return
    header_dict = {k: k for d in data for k in d}
    cleaned_data_list = [{k: clean_value(v) for k, v in d.items()} for d in data]
    text_list = [format_str.format(**header_dict)] + [
        format_str.format(**d) for d in cleaned_data_list
    ]
    file_backup(path)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(text_list) + "\n")


# --- eof ---------------------------------------------------------------------
