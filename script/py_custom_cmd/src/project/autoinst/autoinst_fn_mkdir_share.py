# --- python library ----------------------------------------------------------
import grp
import os
import pwd
import subprocess
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    daemon_reload,
    debug_logger,
    delpath,
    fread,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    message_info,
    message_warn,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_def_mkdir_share import InfoSrvDir
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def mkdir_share_create_system_user(info_dirs) -> None:
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    try:
        message_info(_caller, f"{'info':<10}:create system user id", omit=True)
        _sudo_list: list[str] = ["sudo", "-n"]
        if not grp.getgrnam(_data.samb_grup):
            run_subprocess([*_sudo_list, "groupadd", "--system", _data.samb_grup])
        if not grp.getgrnam(_data.samb_gadm):
            run_subprocess([*_sudo_list, "groupadd", "--system", _data.samb_gadm])
        if not pwd.getpwnam(_data.samb_user):
            run_subprocess(
                [
                    *_sudo_list,
                    "useradd",
                    "--system",
                    "--shell",
                    str(_data.nlin_path),
                    "--groups",
                    _data.samb_grup,
                    _data.samb_gadm,
                ]
            )
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_create_directory(info_dirs) -> None:
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'info':<10}:create directory", omit=True)
        for _dirs_line in info_dirs.data.dirs:
            _dirs_path: Path = addpath(base=_tget_path, path=Path(_dirs_line))
            _dirs_path.mkdir(parents=True, exist_ok=True)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_change_file_mode(info_dirs) -> None:
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    try:
        message_info(_caller, f"{'info':<10}:change file mode", omit=True)
        if _data.samb_grup and _data.samb_user:
            for _attr_dict in info_dirs.data.attr:
                _dirs_path: Path = _attr_dict["path"]
                _dirs_attr: str = _attr_dict["attr"]
                if _dirs_path.exists():
                    _envs_list = os.environ.copy()
                    _envs_list["_SAMB_USER"] = _data.samb_user
                    _envs_list["_SAMB_GRUP"] = _data.samb_grup
                    _envs_list["_DIRS_SAMB"] = _dirs_path
                    _envs_list["_DIRS_ATTR"] = _dirs_attr
                    _shel_comd = r"""
                        chown -Rf "${_SAMB_USER:?}":"${_SAMB_GRUP:?}" "${_DIRS_SAMB:?}/"
                        chmod -Rf "${_DIRS_ATTR:?}" "${_DIRS_SAMB:?}/"
                    """
                    if _shel_comd:
                        _result: CompletedProcess = subprocess.run(
                            _shel_comd, shell=True, executable="/bin/bash"
                        )
                        if _result.returncode != 0:
                            print(_result.stderr)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_create_fstab(info_dirs):
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'info':<10}:create fstab", omit=True)
        _ftab_path: Path = addpath(base=_tget_path, path=Path("/etc/fstab"))
        _read_text = fread(src_path=_ftab_path, text=True)
        if "/srv/" in _read_text:
            file_backup(info_syst=info_dirs.syst, orig_path=_ftab_path)
            file_origin(info_syst=info_dirs.syst, orig_path=_ftab_path)
            _fmat_parm = "{:<27} {:<35} {:<7} {:<27} {:<7} {}\n"
            _fmat_list = [
                _fmat_parm.format(
                    "# <file system>",
                    "<mount point>",
                    "<type>",
                    "<options>",
                    "<dump>",
                    "<pass>",
                ),
            ]
            for _line in info_dirs.data.mntp:
                _fmat_list.append(
                    _fmat_parm.format(
                        _line["fsys"], _line["mntp"], "none", "bind,ro", "0", "0"
                    ),
                )
            _writ_text = "\n".join(s for s in _read_text + _fmat_list)
            fwrite(dest_path=_ftab_path, data=_writ_text, text=True, backup=False)
            # --- check mount -------------------------------------------------
            message_info(_caller, f"{'info':<10}:check mount", omit=True)
            if not _data.tget_chrt:
                daemon_reload()
                for _line in info_dirs.data.mntp:
                    _mntp_path = _line["mntp"]
                    _result = run_subprocess(["mount", str(_mntp_path)])
                    if _result.returncode == 0:
                        message_info(
                            _caller, f"{'success':<10}:mounted:{_mntp_path}", omit=True
                        )
                    else:
                        message_info(
                            _caller,
                            f"{'failed':<10}:not mounted:{_mntp_path}",
                            omit=True,
                        )
            file_backup(info_syst=info_dirs.syst, orig_path=_ftab_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_create_symlink(info_dirs):
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'info':<10}:create symbolic link", omit=True)
        for _line in info_dirs.data.slnk:
            _srcs_path: Path = addpath(base=_tget_path, path=_line["tget"])
            _dest_path: Path = addpath(base=_tget_path, path=_line["dest"])
            if _line["dest"].endswith("/"):
                _dest_path = _dest_path / Path(_line["tget"]).name
            if not _srcs_path.exists():
                message_warn(_caller, f"create: [{_srcs_path}]", omit=True)
                if str(_srcs_path).endswith("syslinux.cfg"):
                    _srcs_path.write_text("", encoding="utf-8")
                    file_backup(
                        info_syst=info_dirs.syst, orig_path=_srcs_path, mode="init"
                    )
                else:
                    _srcs_path.mkdir(parents=True, exist_ok=True)
            if not _dest_path.exists():
                message_info(_caller, f"{'info':<10}:link: [{_dest_path}]", omit=True)
                _srcs_path = delpath(base=_tget_path, path=_srcs_path)
                _dest_path.symlink_to(
                    target=_srcs_path,
                    target_is_directory=bool(_line["dest"].endswith("/")),
                )
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_create_index_html(info_dirs):
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'info':<10}:create index.html", omit=True)
        _indx_path: Path = addpath(base=_tget_path, path=_data.html_path) / "index.html"
        _indx_path.write_text(
            f'"Hello, world!" from {_data.nics_fqdn}', encoding="utf-8"
        )
        file_backup(info_syst=info_dirs.syst, orig_path=_indx_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share_create_ipxe_menu(info_dirs):
    _caller = get_caller_name()
    _data = info_dirs.syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'info':<10}:create index.html", omit=True)
        _ipxe_path: Path = addpath(base=_tget_path, path=_data.tftpl_path) / "ipxe"
        # --- autoexec.ipxe ---------------------------------------------------
        _auto_path: Path = _ipxe_path / "autoexec.ipxe"
        _writ_text: str = info_dirs.data.ipxe["autoexec.ipxe"]
        fwrite(dest_path=_auto_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_dirs.syst, orig_path=_auto_path, mode="init")
        # --- menu.ipxe -------------------------------------------------------
        _menu_path: Path = _ipxe_path / "menu/menu.ipxe"
        _writ_text: str = info_dirs.data.ipxe["menu.ipxe"]
        fwrite(dest_path=_menu_path, data=_writ_text, text=True, backup=False)
        file_backup(info_syst=info_dirs.syst, orig_path=_menu_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)


@debug_logger
def mkdir_share(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    try:
        _info_dirs: InfoSrvDir = InfoSrvDir(info_syst)
        mkdir_share_create_system_user(_info_dirs)
        mkdir_share_create_directory(_info_dirs)
        mkdir_share_change_file_mode(_info_dirs)
        mkdir_share_create_fstab(_info_dirs)
        mkdir_share_create_symlink(_info_dirs)
        mkdir_share_create_index_html(_info_dirs)
        mkdir_share_create_ipxe_menu(_info_dirs)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e, omit=False, raise_exit=False)
