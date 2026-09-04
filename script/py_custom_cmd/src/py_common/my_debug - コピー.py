###############################################################################
#
#	debug processing
#
#	developer   : J.Itou
#	release     : 2026/09/03
#
#	history     :
#	   data    version    developer    point
#	---------- -------- -------------- ----------------------------------------
#	2026/09/03 000.0000 J.Itou         first release
#
###############################################################################

# --- Python library ----------------------------------------------------------
from typing                             import Any, Callable
from datetime                           import datetime
from pathlib                            import Path
import inspect

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_string                import generate_comment
#from py_common.my_debug                 import debug_logger
from py_common.my_colors                import color
from py_common.my_message               import message_debug

def debug_logger(func: Callable):
    def wrapper(*args, **kwargs):
        # --- get the caller's frame ------------------------------------------
        frame = inspect.currentframe().f_back
        caller_name = frame.f_code.co_name
        module_name = frame.f_globals.get('__name__')
        # --- generation of function information and comments -----------------
        function_name = f"{Path(__file__).stem}({func.__name__})"
        comment = generate_comment(module_name, caller_name, '')
        # --- start log -------------------------------------------------------
        debugout(function_name, 'Start', color.yellow, comment)
        # --- execute the original function processing ------------------------
        result = func(*args, **kwargs)
        # --- completion log --------------------------------------------------
        debugout(function_name, 'Complete', color.yellow, '')
        return result
    return wrapper

# -----------------------------------------------------------------------------
# descript: debug output for scale
#   input : size             : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def debugout_scale(size: int):
    eprint = lambda *args, **kwargs: print(*args, file=sys.stderr, **kwargs)
    scale_u = "".join(str(i // 100)[-1] if i % 10 == 0 else " " for i in range(1, size + 1))
    scale_m = "".join(str((i // 10) % 10) if i % 10 == 0 else " " for i in range(1, size + 1))
    scale_l = "".join(str(i % 10) for i in range(1, size + 1))
    eprint(scale_m)
    eprint(scale_l)

# -----------------------------------------------------------------------------
# descript:  debug output
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: debugout_flag    : read
# -----------------------------------------------------------------------------
def debugout(function_name: str, mode: str, message_color:str, message: str):
    if infosystem.data.debugout == False: return
    message_debug(function_name, mode, message_color, message)

# --- eof ---------------------------------------------------------------------
