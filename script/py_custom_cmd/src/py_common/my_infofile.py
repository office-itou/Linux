# --- Python library ----------------------------------------------------------
from typing                             import Any, Callable
from dataclasses                        import dataclass, asdict
from datetime                           import datetime, timezone
from pathlib                            import Path
import inspect
import magic                            # sudo apt-get install python3-magic

# --- my library --------------------------------------------------------------
from py_common.my_config                import infosystem
from py_common.my_debug                 import debug_logger
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_message               import message_alert, get_caller_name
from py_common.my_debug                 import debugout
from py_common.my_process               import run_subprocess

# -----------------------------------------------------------------------------
@dataclass
class FileData:
    path:           str = ""
    tmstamp:        str = ""
    size:           int = 0
    volume:         str = ""

class InfoFile:
    def __init__(self, data: FileData = None):
        self.data: FileData = data if data is not None else FileData()

    def get_data(self) -> FileData:
        return self.data

    def get_info(self, target_path: str) -> FileData:
        self.data = get_info(target_path)
        return self.data

    def get_volume_uuid(device: str) -> str:
        return get_volume_uuid(device)

    def get_volume_label(device: str) -> str:
        return get_volume_label(device)

# -----------------------------------------------------------------------------
# descript: get volume uuid
#   input : device                : input 
#   output:                       : unused
#   return: uuid                  : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def get_volume_uuid(device):
    parameter = ['blkid', '-s', 'UUID', '-o', 'value', device]
    return run_subprocess(parameter)

# -----------------------------------------------------------------------------
# descript: get volume label
#   input : device                : input 
#   output:                       : unused
#   return: label                 : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def get_volume_label(device):
    parameter = ['blkid', '-s', 'LABEL', '-o', 'value', device]
    return run_subprocess(parameter)

# -----------------------------------------------------------------------------
# descript: get web information data
#   input : target_path           : input 
#   output:                       : unused
#   return: InfoFile              : output
#   global:                       : unused
# -----------------------------------------------------------------------------
@debug_logger
def get_info(target_path):
    data = FileData()
    path = Path(target_path)
    data.path = str(path.resolve())
    if path.exists():
        kind = magic.from_file(data.path, mime=True)
        if kind:
            if kind == "application/x-iso9660-image":
                data.volume  = get_volume_label(data.path)
        data.tmstamp = datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).isoformat()
        data.size    = path.stat().st_size
#   else:
#       message_alert(get_caller_name(), f"File not exist: {target_path}")
    # --- return --------------------------------------------------------------
    return data

# --- eof ---------------------------------------------------------------------
