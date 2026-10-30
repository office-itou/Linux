# --- python library ----------------------------------------------------------
import shutil
import subprocess
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def download_wget(
    tget_urls: str, dest_path: Path, sudo: bool = False, debug: bool = False
) -> str | None:
    _caller = get_caller_name()
    try:
        _sudo_comd: list[str] = ["sudo", "-n"] if sudo else []
        _comd_list: list[str] = [
            *_sudo_comd,
            "wget",
            "--tries=3",
            "--timeout=10",
            "--quiet",
            "--continue",
            "--show-progress",
            "--progress=bar",
            "--output-document",
            str(dest_path),
            str(tget_urls),
        ]
        if debug:
            _message: str = " ".join(_comd_list)
            message_info(_caller, _message, omit=True)
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        return subprocess.check_output(_comd_list, text=True, stderr=subprocess.DEVNULL)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def download_curl(
    tget_urls: str, dest_path: Path, sudo: bool = False, debug: bool = False
) -> str | None:
    _caller = get_caller_name()
    try:
        _sudo_comd: list[str] = ["sudo", "-n"] if sudo else []
        _comd_list: list[str] = [
            *_sudo_comd,
            "curl",
            "--location",
            "--http1.1",
            "--no-progress-bar",
            "--remote-time",
            "--show-error",
            "--fail",
            "--retry-max-time",
            "3",
            "--retry",
            "3",
            "--connect-timeout",
            "60",
            "--progress-bar",
            "--continue-at",
            "-",
            "--create-dirs",
            "--output-dir",
            str(dest_path.parent),
            "--output",
            str(dest_path.name),
            str(tget_urls),
        ]
        if debug:
            _message: str = " ".join(_comd_list)
            message_info(_caller, _message, omit=True)
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        return subprocess.check_output(_comd_list, text=True, stderr=subprocess.DEVNULL)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def download(tget_urls: str, dest_path: Path) -> str | None:
    if shutil.which("wget"):
        return download_wget(tget_urls=tget_urls, dest_path=dest_path, sudo=False)
    if shutil.which("curl"):
        return download_curl(tget_urls=tget_urls, dest_path=dest_path, sudo=False)
    return None
