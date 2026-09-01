# --- Python library ----------------------------------------------------------
from datetime                           import datetime, timedelta
from pathlib                            import Path

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_colors                import color
from py_common.my_string                import eprint, count_width, omit_middle

#colsize_func = 30 if infosystem.data.columns < 80 else 40 if infosystem.data.columns < 100 else 50
colsize_func = infosystem.data.columns // 2 if infosystem.data.columns < 100 else 50
colsize_mode = 10

# -----------------------------------------------------------------------------
# descript: message output for datetime
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : date_time        : input
#   output: stdout           : output
#   return:                  : unused
#   global: col_size         : read
# -----------------------------------------------------------------------------
def message_date(function_name: str, mode: str, message_color: str, date_time: str):
    message = f"--- {date_time} " + '-' * (infosystem.data.columns - (colsize_func + colsize_mode + 5 +2))
    eprint(f"{color.reset}{message_color}{function_name:<{colsize_func}}:{mode:^{colsize_mode}}:{message}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for startup
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_start(function_name: str):
    date_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    message_date(text_prog, 'Start', color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for termination
#   input : function_name    : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_end(function_name: str):
    date_time = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    message_date(text_prog, 'Complete', color.green, date_time)

# -----------------------------------------------------------------------------
# descript: message output for elapsed time
#   input : function_name    : input
#   input : elapsed          : input
#   output: stdout           : output
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def message_elapsed(function_name: str, elapsed: str):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    text_time = timedelta(seconds=elapsed)
    eprint(f"{color.reset}{color.yellow}{text_prog:<{colsize_func}}:{'Elapsed':^{colsize_mode}}:{text_time}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : mode             : input
#   input : message_color    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_debug(function_name: str, mode: str, message_color: str, message: str):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    text_mesg = omit_middle(f"{message}", infosystem.data.columns - (colsize_func + colsize_mode + 2))
    eprint(f"{color.reset}{message_color}{text_prog:<{colsize_func}}:{mode:^{colsize_mode}}:{text_mesg}{color.reset}", infosystem.data.columns)

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_info(function_name: str, message: str):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    eprint(f"{color.reset}{color.br_green}{text_prog:<{colsize_func}}:{'info':^{colsize_mode}}:{message}{color.reset}")

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_warn(function_name: str, message: str):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    eprint(f"{color.reset}{color.br_yellow}{text_prog:<{colsize_func}}:{'warn':^{colsize_mode}}:{message}{color.reset}")

# -----------------------------------------------------------------------------
# descript: message output for debug
#   input : function_name    : input
#   input : message          : input
#   output: stdout           : output
#   return:                  : unused
#   global: program_name     : read
# -----------------------------------------------------------------------------
def message_alert(function_name: str, message: str):
    text_prog = omit_middle(f"{infosystem.data.program_name}({function_name})", colsize_func)
    eprint(f"{color.reset}{color.br_red}{text_prog:<{colsize_func}}:{'alert':^{colsize_mode}}:{message}{color.reset}")

# --- eof ---------------------------------------------------------------------
