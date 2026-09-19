"""Memory usage"""

# --- Python library ----------------------------------------------------------
import resource
import sys

# --- my library --------------------------------------------------------------
from common.utils.my_colors import Color
from common.utils.my_message import get_caller_name, message_debug


def print_peak_memory():
    """Get maximum memory usage (in KB on Linux, in bytes on macOS)"""
    caller = get_caller_name()
    usage = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    if sys.platform == "darwin":  # For macOS
        peak_mb = usage / 1024 / 1024
    else:  # for Linux
        peak_mb = usage / 1024
    _time_text = f"{peak_mb:.2f} MB (Peak memory usage)"
    message_debug(Color.br_yellow, caller, "MemUsage", _time_text, omit=True)
