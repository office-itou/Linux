"""Subprocess wrapper"""

# --- python library ----------------------------------------------------------
import asyncio
import shutil
import subprocess
from asyncio.subprocess import Process
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
)


# =============================================================================
@debug_logger
def run_subprocess(*args, **kwargs) -> CompletedProcess:
    """Subprocess wrapper
    Returns:
        CompletedProcess: _description_
    """
    _caller = get_caller_name()
    _result = None
    try:
        # args_list: list[str] = (
        #    [s for arg in args for s in arg]
        #    if not isinstance(*args, str)
        #    else [s for arg in args for s in arg.split()]
        # )
        args_text: str = (
            " ".join(s for arg in args for s in arg)
            if isinstance(*args, list)
            else " ".join(str(s).rstrip(r"\\") for arg in args for s in arg.split())
        )
        # print(f"args_text:{args_text}")
        if _shel_file := shutil.which("bash"):
            kwargs.setdefault("executable", _shel_file)
        elif _shel_file := shutil.which("sh"):
            kwargs.setdefault("executable", _shel_file)
        kwargs.setdefault("shell", True)
        if not isinstance(kwargs.get("env"), dict) or "LANG" not in kwargs["env"]:
            kwargs["env"] = {"LANG": "C"}
        if not isinstance(kwargs.get("capture_output"), bool):
            kwargs.setdefault("capture_output", True)
        kwargs.setdefault("check", False)
        kwargs.setdefault("text", True)
        # print(f"kwargs:{kwargs}")
        _result: CompletedProcess = subprocess.run(args_text, **kwargs)
        # if _result.returncode != 0 and _result.stderr:
        #    print(_result.stderr)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return _result


def run_subprocess_stdout(*args, **kwargs) -> str | None:
    _result: CompletedProcess = run_subprocess(*args, **kwargs)
    return (
        str("\n".join(_result.stdout.splitlines())) if _result.returncode == 0 else None
    )


@debug_logger
async def async_subprocess(*args, **kwargs) -> bool:
    _caller = get_caller_name()
    _status: bool = False

    # --- message out ---------------------------------------------------------
    def _message_out(caller, status, stdout, stderr) -> None:
        if not status:
            if stdout:
                message_alert(caller, f"stdout:{stdout.decode()}", omit=True)
            if stderr:
                message_alert(caller, f"stderr:{stderr.decode()}", omit=True)

    try:
        _proc: Process = await asyncio.create_subprocess_exec(*args, **kwargs)
        assert _proc.stdout is not None
        try:
            while True:
                _line_bytes = await _proc.stdout.readline()
                if not _line_bytes:
                    break
                _message = _line_bytes.decode().strip()
                if _message:
                    message_info(_caller, _message, omit=True)
        except asyncio.CancelledError:
            try:
                _proc.terminate()
                await _proc.wait()
            except ProcessLookupError:
                pass
            raise
        _stdout, _stderr = await _proc.communicate()
        _status: bool = _proc.returncode == 0
        if not _status:
            _message_out(caller=_caller, status=_status, stdout=_stdout, stderr=_stderr)
    except Exception as e:
        handle_fatal_error(_caller, e, raise_exit=False)
        _status: bool = False
    return _status


# --- eof ---------------------------------------------------------------------
