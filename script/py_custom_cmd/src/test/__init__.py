"""Test module route"""

import os
import sys
from pathlib import Path

from ..common import shared, utils

__all__ = [
    "shared",
    "utils",
]

execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
# --- eof ---------------------------------------------------------------------
