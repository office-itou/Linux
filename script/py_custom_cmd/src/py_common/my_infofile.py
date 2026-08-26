#!/usr/bin/env python3
# encoding: utf-8

# -----------------------------------------------------------------------------
import inspect

from pathlib import Path
from datetime import datetime, timezone
import magic                            # sudo apt-get install python3-magic

# -----------------------------------------------------------------------------
from .my_config import debug_flag, debugout_flag
from .my_colors import color
from .my_debug  import debugout

#from .my_infoweb  import Infoweb, get_webinfo
#from .my_infofile import Infofile, get_fileinfo

from .my_process import run_subprocess

# -----------------------------------------------------------------------------
import dataclasses
@dataclasses.dataclass
class Infofile:
    path:     str = ""
    tmstamp:  str = ""
    size:     int = 0
    volume:   str = ""

# -----------------------------------------------------------------------------
def get_volume_uuid(device):
    parameter = ['blkid', '-s', 'UUID', '-o', 'value', device]
    return run_subprocess(parameter)

def get_volume_label(device):
    parameter = ['blkid', '-s', 'LABEL', '-o', 'value', device]
    return run_subprocess(parameter)

# -----------------------------------------------------------------------------
def get_fileinfo(target_path):
    func_name = inspect.currentframe().f_code.co_name
    debugout(debugout_flag, color.yellow, func_name, "Start", f"({target_path})")
    # -------------------------------------------------------------------------
    info = Infofile()
    path = Path(target_path)
    info.path = str(path.resolve())
    if path.exists():
        kind = magic.from_file(info.path, mime=True)
        if kind:
            if kind == "application/x-iso9660-image":
                info.volume  = get_volume_label(info.path)
        info.tmstamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        info.size    = path.stat().st_size
    else:
        debugout(debugout_flag, color.bg_red, func_name, "Error", f"File not exist: {target_path}")
    # -------------------------------------------------------------------------
    debugout(debugout_flag, color.yellow, func_name, "Complete", f"({target_path})")
#    print(f"{color.white}{func_name}({target_path}) END{color.reset}")
    return info
