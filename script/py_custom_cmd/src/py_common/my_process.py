# --- Python library ----------------------------------------------------------
from pathlib                            import Path
import inspect
import subprocess

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
def run_subprocess(parameter: str):
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, 'Start', color.yellow, '')
    # -------------------------------------------------------------------------
    try:
        res = subprocess.run(parameter, check=True, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        eprint(f"{color.bg_red}Subprocess error status {e.returncode}: {e.stderr}{color.reset}")
        raise SystemExit
    except FileNotFoundError as e:
        eprint(f"{color.bg_red}Subprocess file not found error: {e.filename}{color.reset}")
        raise SystemExit
    # -------------------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return str(res.stdout.strip())

# --- eof ---------------------------------------------------------------------
