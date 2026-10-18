"""Subprocess wrapper"""

# --- python library ----------------------------------------------------------
import asyncio
import subprocess
from asyncio.subprocess import Process

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
def run_subprocess(*args, **kwargs) -> str:
    """Subprocess wrapper
    Raises:
        SystemExit: subprocess.CalledProcessError
        SystemExit: FileNotFoundError
    Returns:
        str: stdout
    """
    _caller = get_caller_name()
    kwargs["check"] = True
    kwargs["capture_output"] = True
    kwargs["text"] = True
    try:
        _res = subprocess.run(*args, **kwargs)  # noqa: PLW1510
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    else:
        return str(_res.stdout.strip())
    return ""


@debug_logger
async def async_subprocess(*args, **kwargs) -> bool:
    _caller = get_caller_name()
    _status:bool = False

    # --- message out ---------------------------------------------------------
    def _message_out(caller, status, stdout, stderr) -> None:
        if not status:
            if stdout:
                message_alert(caller, f"stdout: {stdout.decode()}", omit=True)
            if stderr:
                message_alert(caller, f"stderr: {stderr.decode()}", omit=True)

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
        _status:bool = False
    return _status
# --- eof ---------------------------------------------------------------------
