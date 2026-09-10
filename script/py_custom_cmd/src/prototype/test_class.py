#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import sys
import time
from datetime import timedelta
from pathlib import Path

# import re
# from dataclasses import asdict, dataclass, fields
# from typing import Any

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))

from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import InfoDistribution
from common.shared.my_media_dat import InfoMedia
from common.utils.my_colors import Color

# from common.utils.my_config import infosystem
# from common.utils.my_debug import debug_logger
# from common.utils.my_error import handle_fatal_error
# from common.utils.my_fileio import file_read
# from common.utils.my_markdown import list2markdown
# from common.utils.my_message import get_caller_name, message_alert
# from common.utils.my_string import eprint


# -----------------------------------------------------------------------------
print(f"{Color.br_green}{'*' * 80}{Color.reset}")
start = time.perf_counter()
# -----------------------------------------------------------------------------
info_conf = InfoConfiguration()
path_conf = Path(info_conf.find(key="PATH_CONF").value)
path_dist = Path(info_conf.find(key="PATH_DIST").value)
path_mdia = Path(info_conf.find(key="PATH_MDIA").value)
info_dist = InfoDistribution(path_dist.with_name(path_dist.name + ".json"))
info_mdia = InfoMedia(path_mdia.with_name(path_mdia.name + ".json"), info_conf)
# -----------------------------------------------------------------------------
# results = info_conf.findregexp([{"value": r".+/http/*"}])
# print([asdict(r) for r in results])
# print(f"{Color.br_green}{'-' * 80}{Color.reset}")
# results = info_conf.findregexp([{"key": r"DIRS_T.*"}])
# print([asdict(r) for r in results])
# print(f"{Color.br_green}{'-' * 80}{Color.reset}")
# info_conf.dump(wrap=True)
print(f"{Color.br_green}{'-' * 80}{Color.reset}")
info_conf.markdown(
    Path("./Readme_Configuration.md"), f"Configuration data({path_conf.name})"
)
info_dist.markdown(
    Path("./Readme_Distribution.md"), f"Distribution data({path_dist.name})"
)
info_mdia.markdown(Path("./Readme_Media.md"), f"Media data({path_mdia.name})")
# -----------------------------------------------------------------------------
end = time.perf_counter()
elapsed = end - start
print(timedelta(seconds=elapsed))
print(f"{Color.br_green}{'*' * 80}{Color.reset}")
raise SystemExit(0)
# --- eof ---------------------------------------------------------------------
