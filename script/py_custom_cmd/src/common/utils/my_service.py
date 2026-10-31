# --- python library ----------------------------------------------------------
import subprocess
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_info,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def find_serivce(tget_path: Path, srvc_name: str) -> Path | None:
    for _find_dir in ["/lib/systemd", "/usr/lib/systemd"]:
        _find_path: Path = addpath(base=tget_path, path=f"{_find_dir}/{srvc_name}")
        if _find_path.exists():
            return _find_path
    return None


@debug_logger
def daemon_reload() -> bool:
    _caller = get_caller_name()
    try:
        # --- systemctl daemon-reload -----------------------------------------
        subprocess.run(
            ["systemctl", "daemon-reload"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        return True
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return False


@debug_logger
def is_service_active(srvc_name: str) -> bool | None:
    _caller = get_caller_name()
    try:
        _proc_name = srvc_name.split(".")[0]
        # --- is active -------------------------------------------------------
        _is_active_cmd = ["systemctl", "is-active", srvc_name]
        _res_active = subprocess.run(
            _is_active_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        return bool(_res_active.returncode == 0)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return None


@debug_logger
def restart_service(srvc_name: str) -> bool | None:
    _caller = get_caller_name()
    try:
        _proc_name = srvc_name.split(".")[0]
        # --- is active -------------------------------------------------------
        _res_active = is_service_active(srvc_name)
        if not _res_active:
            message_info(_caller, f"{'not active':<10}:{srvc_name}", omit=True)
            return None
        # --- systemctl daemon-reload -------------------------------------
        message_info(_caller, f"{'reload':<10}:daemon", omit=True)
        daemon_reload()
        # --- systemctl restart service -----------------------------------
        message_info(_caller, f"{'restart':<10}:{srvc_name}", omit=True)
        restart_cmd = ["systemctl", "restart", srvc_name]
        res_restart = subprocess.run(
            restart_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
        )
        if res_restart.returncode == 0:
            message_info(_caller, f"{'success':<10}:{srvc_name}", omit=True)
        else:
            message_info(_caller, f"{'failed':<10}:{srvc_name}", omit=True)
        return True
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return False


@debug_logger
def restart_user_service(srvc_name: str) -> bool | None:
    _caller = get_caller_name()
    try:
        _proc_name = srvc_name.split(".")[0]
        # --- is active -------------------------------------------------------
        _res_active = is_service_active(srvc_name)
        if not _res_active:
            message_info(_caller, f"{'not active':<10}:{srvc_name}", omit=True)
            return None
        # --- restart ---------------------------------------------------------
        message_info(_caller, f"{'restart':<10}:{srvc_name}", omit=True)
        # --- systemctl daemon-reload -----------------------------------------
        subprocess.run(
            ["systemctl", "daemon-reload"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        # --- ps --no-headers -C wireplumber -o user --------------------------
        _ps_cmd = ["ps", "--no-headers", "-C", _proc_name, "-o", "user"]
        _res_ps = subprocess.run(
            _ps_cmd, text=True, capture_output=True, stderr=subprocess.DEVNULL
        )
        if _res_ps.returncode == 0:
            _users = set(_res_ps.stdout.splitlines())
            for _user in _users:
                _user = _user.strip()
                if not _user:
                    continue
                # --- systemctl --user --machine=user@ restart service --------
                restart_cmd = [
                    "systemctl",
                    "--user",
                    f"--machine={_user}@",
                    "restart",
                    srvc_name,
                ]
                res_restart = subprocess.run(
                    restart_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                if res_restart.returncode == 0:
                    message_info(
                        _caller, f"{'success':<10}:{_user}@ {srvc_name}", omit=True
                    )
                else:
                    message_info(
                        _caller, f"{'failed':<10}:{_user}@ {srvc_name}", omit=True
                    )
        return True
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)
    return False
