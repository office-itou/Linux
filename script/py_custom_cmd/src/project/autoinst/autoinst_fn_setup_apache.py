# --- python library ----------------------------------------------------------
import os
from pathlib import Path
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    cat,
    debug_logger,
    find_serivce,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    message_info,
    restart_service,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def setup_apache(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _srvc_list: list[str] = ["apache2.service", "httpd.service"]
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_list=_srvc_list)
    if not _srvc_path or not _srvc_path.exists():
        message_info(_caller, f"{'skip':<10}:apache2", omit=True)
        return
    try:
        _srvc_name = _srvc_path.name
        _srvc_type: str = _srvc_name.split(".")[0]
        message_info(_caller, f"{'setup':<10}:{_srvc_type}", omit=True)
        # --- apache2.conf / httpd.conf ---------------------------------------
        _conf_file: Path = Path(f"/etc/{_srvc_type}/sites-available/999-site.conf")
        _conf_path: Path = addpath(base=_tget_path, path=_conf_file)
        if _conf_path.exists():
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            _envs_list = os.environ.copy()
            _envs_list["_DIRS_HTML"] = str(_data.html_path)
            _envs_list["_CONF_PATH"] = str(_conf_path)
            _shel_comd: str = r"""
                sed -e 's%^\([ \t]\+DocumentRoot[ \t]\+\).*$%\1'"${_DIRS_HTML}"'%' \
                    "${_CONF_PATH%/*}/000-default.conf"                            \
                > "${_CONF_PATH:?}"
            """
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            _writ_text: str = cat(rf"""
				<Directory {_data.html_path}/>
				 	Options Indexes FollowSymLinks
				 	AllowOverride None
				 	Require all granted
				</Directory>
			""")  # noqa: E101
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
            # --- registration ------------------------------------------------
            _envs_list["_CONF_FILE"] = str(_conf_file)
            _shel_comd: str = r"""
                a2dissite 000-default
                a2ensite "${_CONF_FILE##*/}"
            """
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
        else:
            _conf_file: Path = Path("/etc/{_srvc_type}/conf.d/site.conf")
            _conf_path: Path = addpath(base=_tget_path, path=_conf_file)
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            _writ_text: str = cat(rf"""
				<VirtualHost *:80>
				 	ServerAdmin webmaster@localhost
				 	DocumentRoot {_data.html_path}
				#	ErrorLog /var/log/{_srvc_type}/error.log
				#	CustomLog /var/log/{_srvc_type}/access.log combined
				</VirtualHost>
				
				<Directory {_data.html_path}/>
				 	Options Indexes FollowSymLinks
				 	AllowOverride None
				 	Require all granted
				</Directory>
			""")  # noqa: E101
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_srvc_path, mode="init")
        # --- service restart -------------------------------------------------
        if not info_syst.data.tget_chrt:
            restart_service(srvc_name=_srvc_name)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
