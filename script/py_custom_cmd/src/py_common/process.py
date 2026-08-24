#!/usr/bin/env python3
# encoding: utf-8

## -----------------------------------------------------------------------------
import inspect
import subprocess

from . import config
from .colors import color
from .debug  import debugout

# -----------------------------------------------------------------------------
def run_subprocess(parameter):
    func_name = inspect.currentframe().f_code.co_name
    debugout(config.debugout, color.yellow, func_name, "Start", f"({parameter})")
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
    debugout(config.debugout, color.yellow, func_name, "Complete", f"({parameter})")
    return str(res.stdout.strip())
