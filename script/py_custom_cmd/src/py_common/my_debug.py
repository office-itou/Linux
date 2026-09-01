# --- Python library ----------------------------------------------------------
from datetime                           import datetime
from pathlib                            import Path

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_message               import message_debug

# -----------------------------------------------------------------------------
# descript: debug output for scale
#   input : size             : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def debugout_scale(size: int):
        gap = '-' * size
        scale_u = ''
        scale_m = ''
        scale_l = ''
        for i in range(1, size + 1):
            u, m = divmod(i, 100)
            m, l = divmod(i, 10)
            scale_u += str(u)[-1] if l == 0 else ' '
            scale_m += str(m)[-1] if l == 0 else ' '
            scale_l += str(l)
#       eprint(gap)
#       eprint(scale_u)
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
