###############################################################################
#
# 	json processing
#
# 	developer   : J.Itou
# 	release     : 2026/09/03
#
# 	history     :
# 	   data    version    developer    point
# 	---------- -------- -------------- ----------------------------------------
# 	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
import json
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from py_common.my_debug import debug_logger


# -----------------------------------------------------------------------------
# descript: load data in json format
#   input : path             : input
#   output:                  : unused
#   return: obj              : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def load_json(path: str) -> Any:
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


# -----------------------------------------------------------------------------
# descript: save distridata in json format
#   input : path             : input
#   input : obj              : input
#   output:                  : unused
#   return:                  : output
#   global:                  : unused
# -----------------------------------------------------------------------------
@debug_logger
def save_json(path: str, obj: Any) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=4)


# --- eof ---------------------------------------------------------------------
