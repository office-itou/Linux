# --- python library ----------------------------------------------------------
import re
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    fread,
    fwrite,
    get_caller_name,
    message_alert,
    message_warn,
    run_subprocess_stdout,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def package_update(info_syst) -> None:
    _caller = get_caller_name()
    # --- check network -------------------------------------------------------
    if not info_syst.data.nics_stat:
        message_warn(_caller, f"{'skip':<10}:network is down", omit=True)
        return
    # --- check command -------------------------------------------------------
    _tget_path: Path = getattr(info_syst.data, "tget_path", None)
    if shutil.which("apt-get"):
        _repo_path: Path = addpath(base=_tget_path, path=Path("/etc/apt/sources.list"))
        _read_text = fread(src_path=_repo_path, text=True)
        _rule = re.compile(r"^\s*deb\s+cdrom:")
        for _line in _read_text.splitlines():
            _match = _rule.match(_line)
            if _match:
                _line = re.sub(r"^", r"#", _line)
        fwrite(
            dest_path=_repo_path,
            data=_read_text,
            text=True,
            backup=False,
        )
        _result = run_subprocess_stdout(["apt-get", "--quiet", "update"])
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "upgrade"]
        )
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "dist-upgrade"]
        )
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "autoremove"]
        )
        _result = run_subprocess_stdout(
            ["apt-get", "--quiet", "--assumeyes", "autoclean"]
        )
        _result = run_subprocess_stdout(["apt-get", "--quiet", "--assumeyes", "clean"])
        _result = run_subprocess_stdout(["apt", "--assume-yes", "modernize-sources"])
    elif shutil.which("dnf"):
        _result = run_subprocess_stdout(["dnf", "--quiet", "--assumeyes", "update"])
    elif shutil.which("yum"):
        _result = run_subprocess_stdout(["yum", "--quiet", "--assumeyes", "update"])
    elif shutil.which("zypper"):
        _result = run_subprocess_stdout(["zypper", "repos"])
        for _line in _result.stdout.splitlines():
            _parts = _line.split("|")
            if len(_parts) < 2:
                continue
            _col1 = _parts[0].strip()
            _col2 = _parts[1].strip()
            if _col1 == "1" and "http" in _col2:
                _result = run_subprocess_stdout(
                    ["zypper", "modifyrepo", "--disable", _col2]
                )
        _result = run_subprocess_stdout(
            ["zypper", "--quiet", "--non-interactive", "refresh"]
        )
        _result = run_subprocess_stdout(
            ["zypper", "--quiet", "--non-interactive", "update"]
        )
    else:
        message_alert(_caller, "package update failure (command not found)", omit=True)
