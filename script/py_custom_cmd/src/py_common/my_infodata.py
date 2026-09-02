# --- Python library ----------------------------------------------------------
from dataclasses                        import dataclass, asdict
from pathlib                            import Path
import asyncio
import inspect
import re

# --- my library --------------------------------------------------------------
from py_common.my_colors                import color
from py_common.my_string                import omit_middle, generate_comment
from py_common.my_debug                 import debugout
from py_common.my_infoweb               import InfoWeb, WebData
from py_common.my_infofile              import InfoFile, FileData

# -----------------------------------------------------------------------------
@dataclass
class WebFileData:
    web:            WebData  = WebData
    file:           FileData = FileData

class InfoData(InfoWeb, InfoFile):
    def __init__(self):
        self.data: WebFileData = WebFileData()

    def get_data(self) -> WebFileData:
        return self.data

    def get_info(self, session, target_regexp: str, target_path: str) -> WebFileData:
        self.data = get_info(session, target_regexp, target_path)
        return self.data
 
    def debug(self):
        debug(self)

# -----------------------------------------------------------------------------
def debug(info: WebFileData):
    eprint("# --------------------------------------------------------------------------- #")
    data = info
    eprint(f"type(data): {type(data)}")
    if hasattr(data, "web"):
        eprint("info data for web")
        data_infoweb = data.web
        if hasattr(data_infoweb, "regexp"  ): eprint(f"web.regexp  : [{data_infoweb.regexp}]")
        if hasattr(data_infoweb, "url"     ): eprint(f"web.urlh    : [{data_infoweb.url}]")
        if hasattr(data_infoweb, "tmstamp" ): eprint(f"web.tmstamp : [{data_infoweb.tmstamp}]")
        if hasattr(data_infoweb, "size"    ): eprint(f"web.size    : [{data_infoweb.size}]")
        if hasattr(data_infoweb, "check"   ): eprint(f"web.check   : [{data_infoweb.check}]")
        if hasattr(data_infoweb, "status"  ): eprint(f"web.status  : [{data_infoweb.status}]")
        if hasattr(data_infoweb, "reason"  ): eprint(f"web.reason  : [{data_infoweb.reason}]")
        if hasattr(data_infoweb, "contents"): eprint(f"web.contents: [{data_infoweb.contents}]")
        if hasattr(data_infoweb, "output"  ): eprint(f"web.output  : [{data_infoweb.output}]")
    if hasattr(data, "file"):
        eprint("info data for file")
        data_infofile = data.file
        if hasattr(data_infofile, "path"   ): eprint(f"file.path   : [{data_infofile.path}]")
        if hasattr(data_infofile, "tmstamp"): eprint(f"file.tmstamp: [{data_infofile.tmstamp}]")
        if hasattr(data_infofile, "size"   ): eprint(f"file.size   : [{data_infofile.size}]")
        if hasattr(data_infofile, "volume" ): eprint(f"file.volume : [{data_infofile.volume}]")
    eprint("# --------------------------------------------------------------------------- #")

# -----------------------------------------------------------------------------
# descript: get web/file information data
#   input : session               : input 
#   input : target_regexp         : input 
#   input : target_regexp         : input 
#   output:                       : unused
#   return: WebFileData           : output
#   global:                       : unused
# -----------------------------------------------------------------------------
async def get_info(session, target_regexp: str, target_path: str) -> InfoData:
    frame = inspect.currentframe()
    function_name = f"{Path(__file__).stem}({frame.f_code.co_name})"
    comment = generate_comment(frame.f_globals.get('__name__'), frame.f_back.f_code.co_name, f"{target_regexp}")
    debugout(function_name, 'Start', color.yellow, comment)
    # -------------------------------------------------------------------------
    infoweb  = InfoWeb()
    infofile = InfoFile()
    data     = WebFileData()
    data.web  = await infoweb.get_info(session, target_regexp, target_path)
    data.file = infofile.get_info(target_path)
    # --- return --------------------------------------------------------------
    debugout(function_name, 'Complete', color.yellow, '')
    return data

# --- eof ---------------------------------------------------------------------
