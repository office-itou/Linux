"""Memory usage"""

# --- Python library ----------------------------------------------------------
import resource
import sys

# --- my library --------------------------------------------------------------
from my_colors import Color
from my_message import get_caller_name, message_out


def get_peak_memory() -> str:
    """Get maximum memory usage (in KB on Linux, in bytes on macOS)"""
    peek_usage = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    if sys.platform == "darwin":  # For macOS
        peak_mb = peek_usage / 1024 / 1024
    else:  # for Linux
        peak_mb = peek_usage / 1024
    return f"{peak_mb:.2f} MB (Peak memory usage)"

def print_peak_memory() -> None:
    """Get maximum memory usage (in KB on Linux, in bytes on macOS)"""
    caller = get_caller_name()
    message_out(Color.yellow, caller, "MemUsage", get_peak_memory())
