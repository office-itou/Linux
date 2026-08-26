#!/usr/bin/env python3
# encoding: utf-8

# -----------------------------------------------------------------------------
import inspect
import subprocess

# -----------------------------------------------------------------------------
from .my_config import debug_flag, debugout_flag
from .my_colors import color
from .my_debug  import debugout

# -----------------------------------------------------------------------------
def run_subprocess(parameter):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", f"({parameter})")
    # -------------------------------------------------------------------------
    try:
        res = subprocess.run(parameter, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f"{color.bg_red}Subprocess error status {e.returncode}: {e.stderr}{color.reset}")
        raise SystemExit
    except FileNotFoundError as e:
        print(f"{color.bg_red}Subprocess file not found error: {e.filename}{color.reset}")
        raise SystemExit
    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", f"({parameter})")
    return str(res.stdout.strip())
