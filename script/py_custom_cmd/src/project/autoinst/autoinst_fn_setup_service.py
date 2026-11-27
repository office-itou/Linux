# --- python library ----------------------------------------------------------
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    daemon_reload,
    debug_logger,
    find_serivce,
    get_caller_name,
    handle_fatal_error,
    message_info,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def setup_service(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check change root ---------------------------------------------------
    if info_syst.data.tget_chrt:
        message_info(_caller, f"{'skip':<10}:service", omit=True)
        return
    try:
        message_info(_caller, f"{'setup':<10}:service", omit=True)
        _mask_list: list[str] = [
            r"avahi-daemon.service",
            r"brltty.service",
            r"chronyd.service",
            r"nmb.service",
            r"nmbd.service",
            r"systemd-networkd-wait-online.service",
            r"systemd-networkd.service",
            r"wicked.service",
            r"winbind.service",
        ]
        _enbl_list: list[str] = [
            r"apache2.service",
            r"apparmor.service",
            r"auditd.service",
            r"clamav-daemon.service",
            r"clamav-freshclam.service",
            r"dnsmasq.service",
            r"firewalld.service",
            r"httpd.service",
            r"nbdkit.socket",
            r"NetworkManager.service",
            r"nfs-server.service",
            r"open-vm-tools.service",
            r"smb.service",
            r"smbd.service",
            r"ssh.service",
            r"sshd.service",
            r"systemd-resolved.service",
            r"systemd-timesyncd.service",
            r"vmtoolsd.service",
        ]

        def _find_service(tget_path: Path, srvc_name: str) -> bool | None:
            _shel_comd: str = rf'systemctl is-enabled "{srvc_name}" || true'
            _result: CompletedProcess = run_subprocess(_shel_comd)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
                return None
            if _result.stdout == "alias":
                return False
            return find_serivce(tget_path=tget_path, srvc_name=srvc_name)

        def _proc_service(
            tget_path: Path, srvc_list: list[str], srvc_type: str
        ) -> None:
            _tget_list: list[str] = []
            for _srvc_name in srvc_list:
                if not _find_service(tget_path=tget_path, srvc_name=_srvc_name):
                    message_info(
                        _caller,
                        f"{'info':<10}:{'not found ({srvc_type})':<18}:{_srvc_name}:",
                        omit=True,
                    )
                    continue
                message_info(
                    _caller,
                    f"{'info':<10}:{f'{srvc_type} setting':<18}:{_srvc_name}",
                    omit=True,
                )
                _tget_list.append(_srvc_name)
            if _tget_list:
                _shel_comd: str = rf"systemctl {srvc_type} {' '.join(_tget_list)}"
                _result: CompletedProcess = run_subprocess(_shel_comd)
                if _result.returncode != 0 and _result.stderr:
                    print(_result.stderr)
                daemon_reload()
                # --- service restart -----------------------------------------
                if srvc_type == "enable":
                    for _srvc_name in _tget_list:
                        _shel_comd: str = rf"systemctl restart {_srvc_name}"
                        _result: CompletedProcess = run_subprocess(_shel_comd)
                        if _result.returncode != 0 and _result.stderr:
                            print(_result.stderr)

        _proc_service(tget_path=_tget_path, srvc_list=_mask_list, srvc_type="mask")
        _proc_service(tget_path=_tget_path, srvc_list=_enbl_list, srvc_type="enable")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
