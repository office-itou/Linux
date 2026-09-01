# --- Python library ----------------------------------------------------------
from pathlib import Path
import csv
import inspect
import json
import re

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
# descript: load data in json format
#   input : path             : input
#   output:                  : unused
#   return: obj              : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def load_json(path: str) -> str:
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
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
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=4)
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')

# --- eof ---------------------------------------------------------------------
