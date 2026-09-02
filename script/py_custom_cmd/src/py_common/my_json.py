# --- Python library ----------------------------------------------------------
from pathlib import Path
import csv
import inspect
import json
import re

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
# descript: load data in json format
#   input : path             : input
#   output:                  : unused
#   return: obj              : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def load_json(path: str) -> str:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{path}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    obj = None
    with open(path, 'r', encoding='utf-8') as f:
        obj = json.load(f)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return obj

# -----------------------------------------------------------------------------
# descript: save distridata in json format
#   input : path             : input
#   input : obj              : input
#   output:                  : unused
#   return:                  : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def save_json(path: str, obj: str) -> str:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{path}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# --- eof ---------------------------------------------------------------------
