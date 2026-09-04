# --- Python library ----------------------------------------------------------
import csv
import re

from py_common.my_common_cfg import InfoConfiguration

# --- my library --------------------------------------------------------------
from py_common.my_debug import debug_logger
from py_common.my_distribution_dat import InfoDistribution
from py_common.my_json import load_json, save_json
from py_common.my_media_dat import InfoMedia


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
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(text_list) + "\n")


# -----------------------------------------------------------------------------
@debug_logger
def conv_text2json(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
):
    path_dist = info_conf.get("PATH_DIST")
    path_mdia = info_conf.get("PATH_MDIA")
    # -------------------------------------------------------------------------
    list_dist = get_text2list(path_dist)
    list_mdia = get_text2list(path_mdia)
    # -------------------------------------------------------------------------
    save_json(path_dist + ".json", list_dist)
    save_json(path_mdia + ".json", list_mdia)


# -----------------------------------------------------------------------------
@debug_logger
def conv_json2text(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
):
    path_dist = info_conf.get("PATH_DIST")
    path_mdia = info_conf.get("PATH_MDIA")
    fmat_dist = r"{version:<23} {name:<23} {version_id:<23} {code_name:<39} {life:<15} {release:<15} {support:<15} {long_term:<15} {rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} {create_flag:<11} {sort_flag:<11} "
    fmat_mdia = r"{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} "
    # -------------------------------------------------------------------------
    list_dist = load_json(path_dist + ".json")
    list_mdia = load_json(path_mdia + ".json")
    # -------------------------------------------------------------------------
    put_list2text(path_dist, list_dist, fmat_dist)
    put_list2text(path_mdia, list_mdia, fmat_mdia)


# --- eof ---------------------------------------------------------------------
