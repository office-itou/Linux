# --- python library ----------------------------------------------------------
import os
import shutil
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    get_caller_name,
    handle_fatal_error,
    message_warn,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def package_update(info_syst) -> None:
    _caller = get_caller_name()
    # --- check network -------------------------------------------------------
    if not info_syst.data.nics_stat:
        message_warn(_caller, f"{'skip':<10}:network is down", omit=True)
        return
    # --- check command -------------------------------------------------------
    try:
        message_warn(_caller, f"{'info':<10}:package update", omit=True)
        _shel_comd: str = ""
        if shutil.which("apt-get"):
            message_warn(_caller, f"{'info':<10}:apt-get", omit=True)
            _tget_path: Path = getattr(info_syst.data, "tget_path", None)
            _conf_path: Path = addpath(
                base=_tget_path, path=Path("/etc/apt/sources.list")
            )
            if _conf_path.exists():
                file_backup(info_syst=info_syst, orig_path=_conf_path)
                file_origin(info_syst=info_syst, orig_path=_conf_path)
                _envs_list: dict[str, str] = os.environ.copy()
                _envs_list["_CONF_PATH"] = str(_conf_path)
                _shel_comd: str = r"""
                    sed -e '/^[ \t]*deb[ \t]\+cdrom:/ s/^/#/g' \
                        -i "${_CONF_PATH:?}"
                """
                _result: CompletedProcess = run_subprocess(
                    _shel_comd, env=_envs_list, capture_output=False
                )
                if _result.returncode != 0 and _result.stderr:
                    print(_result.stderr)
                file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
            _shel_comd: str = r"""
                apt-get --quiet              update       && \
                apt-get --quiet --assume-yes upgrade      && \
                apt-get --quiet --assume-yes dist-upgrade && \
                apt-get --quiet --assume-yes autoremove   && \
                apt-get --quiet --assume-yes autoclean    && \
                apt-get --quiet --assume-yes clean        && \
                command -v apt > /dev/null 2>&1           && \
                apt --assume-yes modernize-sources
            """
        elif shutil.which("dnf"):
            message_warn(_caller, f"{'info':<10}:dnf", omit=True)
            _shel_comd: str = r"dnf --quiet --assumeyes update"
        elif shutil.which("yum"):
            message_warn(_caller, f"{'info':<10}:yum", omit=True)
            _shel_comd: str = r"yum --quiet --assumeyes update"
        elif shutil.which("zypper"):
            message_warn(_caller, f"{'info':<10}:zypper", omit=True)
            _shel_comd: str = r"""
                _WORK_TEXT="$(LANG=C zypper repos | awk -F '|' '$1==1&&$2~/http/ {gsub(/^[ \t]+/,"",$2); gsub(/[ \t]+$/,"",$2); print $2;}' || true)"
                [ -n "${_WORK_TEXT:-}" ] && zypper modifyrepo --disable "${_WORK_TEXT}"
                zypper --quiet --non-interactive refresh && \
                zypper --quiet --non-interactive update
            """  # noqa: E501
        if _shel_comd:
            _result: CompletedProcess = run_subprocess(_shel_comd, capture_output=False)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)
