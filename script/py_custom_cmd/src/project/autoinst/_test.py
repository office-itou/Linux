#!/usr/bin/env python3

import os
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path
from subprocess import CompletedProcess

from common.utils import (
    debug_logger,
    find_serivce,
    get_caller_name,
    handle_fatal_error,
    run_subprocess,
)


_tget_path: Path | None = None
_srvc_name: str = "nbdkit.service"
_srvc_name: str = "nfs-server.service"
print(_srvc_name)
_srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
print(type(_srvc_path), _srvc_path)
_sock_path: Path = _srvc_path.with_suffix(".socket")
print(type(_sock_path), _sock_path)
