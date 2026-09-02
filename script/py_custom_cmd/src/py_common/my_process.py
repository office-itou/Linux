# --- Python library ----------------------------------------------------------
from pathlib                            import Path
import inspect
import subprocess

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_debug                 import debugout

# -----------------------------------------------------------------------------
def run_subprocess(parameter: str):
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{parameter}")
    debugout(function_name, 'Start', color.yellow, comment)
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
