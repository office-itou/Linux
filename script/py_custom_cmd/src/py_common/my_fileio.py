# --- Python library ----------------------------------------------------------
from pathlib import Path
import csv
import inspect
#import json
import re

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_debug                 import debugout
from py_common.my_json                  import load_json, save_json

from py_common.my_common_cfg            import InfoConfiguration
from py_common.my_distribution_dat      import InfoDistribution
from py_common.my_media_dat             import InfoMedia

# -----------------------------------------------------------------------------
# descript: text file to list
#   input : path             : input
#   output:                  : unused
#   return: data             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def get_text2list(path: str) -> list:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{path}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    list_data = list()
    list_data = list(csv.DictReader(re.sub(r"[ \t]+", ",", line.strip()) for line in open(path, 'r', encoding='utf-8', newline='')))
#    json_data = json.dumps(list_data, ensure_ascii=False)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return list_data

# -----------------------------------------------------------------------------
# descript: list to text file
#   input : path             : input
#   input : data             : input
#   input : format           : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def put_list2text(path: str, list_data: list, format: str):
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{path}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    dict_keys = dict()
    for key, value in list_data[0].items():
        dict_keys[key] = key
    text = [format.format(**dict_keys)]
    for line in list_data:
        text.append(format.format(**line))
    with open(path, 'w', encoding='utf-8') as f:
        f.write(f"\n".join(text) + f"\n")
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
def conv_text2json(info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, '')
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    # -------------------------------------------------------------------------
    list_dist = get_text2list(path_dist)
    list_mdia = get_text2list(path_mdia)
    # -------------------------------------------------------------------------
    save_json(path_dist + '.json', list_dist)
    save_json(path_mdia + '.json', list_mdia)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# -----------------------------------------------------------------------------
def conv_json2text(info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia):
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, '')
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    path_dist = info_conf.get('PATH_DIST')
    path_mdia = info_conf.get('PATH_MDIA')
    fmat_dist = r"{version:<23} {name:<23} {version_id:<23} {code_name:<39} {life:<15} {release:<15} {support:<15} {long_term:<15} {rhel:<15} {kerne:<27} {note:<27} {wallpaper:<87} {create_flag:<11} {sort_flag:<11} "
    fmat_mdia = r"{type:<11} {entry_flag:<11} {entry_name:<39} {entry_disp:<39} {version:<23} {latest:<23} {release:<15} {support:<15} {web_regexp:<143} {web_path:<143} {web_tstamp:<47} {web_size:<15} {web_check:<47} {web_status:<15} {iso_path:<87} {iso_tstamp:<47} {iso_size:<15} {iso_volume:<43} {rmk_path:<87} {rmk_tstamp:<47} {rmk_size:<15} {rmk_volume:<43} {ldr_initrd:<87} {ldr_kernel:<87} {cfg_path:<87} {cfg_tstamp:<47} {lnk_path:<87} {options:<59} {create_flag:<11} "
    # -------------------------------------------------------------------------
    list_dist = load_json(path_dist + '.json')
    list_mdia = load_json(path_mdia + '.json')
    # -------------------------------------------------------------------------
    put_list2text(path_dist, list_dist, fmat_dist)
    put_list2text(path_mdia, list_mdia, fmat_mdia)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# --- eof ---------------------------------------------------------------------
