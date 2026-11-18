#!/usr/bin/env python3

import os

#import shutil
import subprocess
from pathlib import Path
from subprocess import CompletedProcess

from common.utils import addpath


_envs_list = os.environ.copy()
_dirs_path: Path = addpath(base="", path=Path("/etc/dnsmasq.d"))
_envs_list["_DIRS_PATH"] = str(_dirs_path)
_shel_comd = r"""
    cat "${_DIRS_PATH:?}"/*          | \
    sed -ne '/^[^#]/              {'   \
        -e  's/#.*$//g             '   \
        -e  's/^\([^=]\+=\).*$/\1/g'   \
        -e  's/ \+$//g             '   \
        -e  'p                    }' | \
    sed -e ':l; N; s/[\r\n]\+/\\|/; b l' || true \
"""
_result: CompletedProcess = subprocess.run(
    _shel_comd,
    shell=True,
    env=_envs_list,
    executable="/bin/bash",
    capture_output=True,
    text=True,
)
if _result.returncode != 0:
    print(_result.stderr)
_find_parm: str = ""
if _result.stdout:
    _find_parm: str = str(_result.stdout).strip("\n").strip() + r"\|"
_find_parm += r"bind-dynamic\|bind-interfaces"
_envs_list["_FIND_PARM"] = _find_parm
_envs_list["_CONF_PATH"] = "./dnsmasq.conf"
_shel_comd = r"""
    sed -e '/^\('"${_FIND_PARM:?}"'\)/ s/^/#/g' \
        "${_CONF_PATH:?}"
"""
_result: CompletedProcess = subprocess.run(
    _shel_comd, shell=True, env=_envs_list, executable="/bin/bash"
)
if _result.returncode != 0:
    print(_result.stderr)
