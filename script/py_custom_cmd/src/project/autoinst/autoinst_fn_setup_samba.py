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
def setup_samba(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _smbd_list: list[str] = ["smbd.service", "smb.service"]
    _smbd_path: Path = find_serivce(tget_path=_tget_path, srvc_list=_smbd_list)
    _nmbd_list: list[str] = ["nmbd.service", "nmb.service"]
    _nmbd_path: Path = find_serivce(tget_path=_tget_path, srvc_list=_nmbd_list)
    if not _smbd_path or not _smbd_path.exists():
        message_info(_caller, f"{'skip':<10}:samba(smbd)", omit=True)
        return
    if not _nmbd_path or not _nmbd_path.exists():
        message_info(_caller, f"{'skip':<10}:samba(nmbd)", omit=True)
        return
    try:
        _smbd_name = _smbd_path.name
        _smbd_type: str = _smbd_name.split(".")[0]
        _nmbd_name = _nmbd_path.name
        _nmbd_type: str = _nmbd_name.split(".")[0]
        message_info(_caller, f"{'setup':<10}:{_smbd_type}", omit=True)
        message_info(_caller, f"{'setup':<10}:{_nmbd_type}", omit=True)
        # --- create passdb.tdb -----------------------------------------------
        _shel_comd: str = r"""
            pdbedit -L > /dev/null 2>&1 || true
        """
        _result: CompletedProcess = run_subprocess(_shel_comd)
        if _result.returncode != 0:
            print(_result.stderr)
        # --- nsswitch.conf ---------------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/nsswitch.conf"))
        if _conf_path.exists():
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            _envs_list: dict[str, str] = os.environ.copy()
            _envs_list["_CONF_PATH"] = str(_conf_path)
            _shel_comd: str = r"""
                sed -e '/^hosts:[ \t]\+/       {' \
                    -e 's/\(files\).*$/\1/'       \
                    -e 's/$/ '"${_SAMB_NSSW}"'/}' \
                    -e '/^\(passwd\|group\|shadow\|gshadow\):[ \t]\+/ s/[ \t]\+winbind//' \
                    -i "${__PATH}"
            """  # noqa: E501
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0:
                print(_result.stderr)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- smb.conf --------------------------------------------------------
        message_info(_caller, f"{'setup':<10}:smb.conf", omit=True)
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/samba/smb.conf"))
        _conf_temp: Path = info_syst.data.temp_path / _conf_path.name
        if _conf_path.exists():
            message_info(_caller, f"{'info':<10}:global settings section", omit=True)
            file_backup(info_syst=info_syst, orig_path=_conf_path)
            file_origin(info_syst=info_syst, orig_path=_conf_path)
            # <-- global settings section ------------------------------------>
            # allow insecure wide links = Yes
            _envs_list["_CONF_TEMP"] = str(_conf_temp)
            _envs_list["_NICS_HOST"] = _data.nwrk_host.upper()
            _envs_list["_NICS_WGRP"] = _data.nwrk_wgrp.upper()
            _envs_list["_NICS_NAME"] = _data.nwrk_devs
            _envs_list["_HOST_ALOW"] = (
                f"{_data.ipv4_uadr}.0/{_data.ipv4_prfx} fe80::/10"
            )
            _shel_comd: str = r"""
                testparm -s -v                                                                   | \
                sed -ne '/^\[global\]$/,/^[ \t]*$/                                              {' \
                    -e  '/^[ \t]*map to guest[ \t]*=/d'                                            \
                    -e  '/^[ \t]*acl check permissions[ \t]*=/        s/^/#/'                      \
                    -e  '/^[ \t]*allocation roundup size[ \t]*=/      s/^/#/'                      \
                    -e  '/^[ \t]*allow nt4 crypto[ \t]*=/             s/^/#/'                      \
                    -e  '/^[ \t]*blocking locks[ \t]*=/               s/^/#/'                      \
                    -e  '/^[ \t]*client NTLMv2 auth[ \t]*=/           s/^/#/'                      \
                    -e  '/^[ \t]*client lanman auth[ \t]*=/           s/^/#/'                      \
                    -e  '/^[ \t]*client plaintext auth[ \t]*=/        s/^/#/'                      \
                    -e  '/^[ \t]*client schannel[ \t]*=/              s/^/#/'                      \
                    -e  '/^[ \t]*client use spnego principal[ \t]*=/  s/^/#/'                      \
                    -e  '/^[ \t]*client use spnego[ \t]*=/            s/^/#/'                      \
                    -e  '/^[ \t]*copy[ \t]*=/                         s/^/#/'                      \
                    -e  '/^[ \t]*domain logons[ \t]*=/                s/^/#/'                      \
                    -e  '/^[ \t]*enable privileges[ \t]*=/            s/^/#/'                      \
                    -e  '/^[ \t]*encrypt passwords[ \t]*=/            s/^/#/'                      \
                    -e  '/^[ \t]*idmap backend[ \t]*=/                s/^/#/'                      \
                    -e  '/^[ \t]*idmap gid[ \t]*=/                    s/^/#/'                      \
                    -e  '/^[ \t]*idmap uid[ \t]*=/                    s/^/#/'                      \
                    -e  '/^[ \t]*lanman auth[ \t]*=/                  s/^/#/'                      \
                    -e  '/^[ \t]*lsa over netlogon[ \t]*=/            s/^/#/'                      \
                    -e  '/^[ \t]*nbt client socket address[ \t]*=/    s/^/#/'                      \
                    -e  '/^[ \t]*null passwords[ \t]*=/               s/^/#/'                      \
                    -e  '/^[ \t]*raw NTLMv2 auth[ \t]*=/              s/^/#/'                      \
                    -e  '/^[ \t]*reject md5 clients[ \t]*=/           s/^/#/'                      \
                    -e  '/^[ \t]*server schannel require seal[ \t]*=/ s/^/#/'                      \
                    -e  '/^[ \t]*server schannel[ \t]*=/              s/^/#/'                      \
                    -e  '/^[ \t]*syslog only[ \t]*=/                  s/^/#/'                      \
                    -e  '/^[ \t]*syslog[ \t]*=/                       s/^/#/'                      \
                    -e  '/^[ \t]*unicode[ \t]*=/                      s/^/#/'                      \
                    -e  '/^[ \t]*winbind separator[ \t]*=/            s/^/#/'                      \
                    -e  '/^[ \t]*allow insecure wide links[ \t]*=/    s/=.*$/= Yes/'               \
                    -e  '/^[ \t]*dos charset[ \t]*=/                  s/=.*$/= CP932/'             \
                    -e  '/^[ \t]*unix password sync[ \t]*=/           s/=.*$/= No/'                \
                    -e  '/^[ \t]*disable netbios[ \t]*=/              s/=.*$/= Yes/'               \
                    -e  '/^[ \t]*smb ports[ \t]*=/                    s/=.*$/= 445/'               \
                    -e  '/^[ \t]*server smb transports[ \t]*=/        s/=.*$/= 445/'               \
                    -e  '/^[ \t]*netbios name[ \t]*=/                 s/=.*$/= '"${_NICS_HOST}"'/' \
                    -e  '/^[ \t]*workgroup[ \t]*=/                    s/=.*$/= '"${_NICS_WGRP}"'/' \
                    -e  '/^[ \t]*log level =/                         s/=.*$/= 0/'                 \
                    -e  '/^[ \t]*bind interfaces only[ \t]*=/                                   {' \
                    -e  '                                             s/^/#/'                      \
                    -e  '                                             s/=.*$/= yes/'               \
                    -e  '                                                                       }' \
                    -e  '/^[ \t]*interfaces[ \t]*=/                                             {' \
                    -e  '                                             s/^/#/'                      \
                    -e  '                                             s/=.*$/= '"${_NICS_NAME}"'/' \
                    -e  '                                                                       }' \
                    -e  '/^[ \t]*hosts allow[ \t]*=/                                            {' \
                    -e  '                                             s/^/#/'                      \
                    -e  '                                             s/=.*$/= '"${_HOST_ALOW}"'/' \
                    -e  '                                                                       }' \
                    -e  '/^[ \t]*hosts deny[ \t]*=/                                             {' \
                    -e  '                                             s/^/#/'                      \
                    -e  '                                             s/=.*$/= ALL/'               \
                    -e  '                                                                       }' \
                    -e  'p                                                                      }' \
                > "${_CONF_TEMP}" 2> /dev/null || true
                [ -z "${_NICS_HOST##-}" ] && sed -i "${_CONF_TEMP}" -e '/^[ \t]*netbios name[ \t]*=/d'
                [ -z "${_NICS_WGRP##-}" ] && sed -i "${_CONF_TEMP}" -e '/^[ \t]*workgroup[ \t]*=/d'
                [ -z "${_NICS_NAME##-}" ] && sed -i "${_CONF_TEMP}" -e '/^[ \t]*interfaces[ \t]*=/d'
            """  # noqa: E501
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
            # <-- shared settings section ------------------------------------>
            message_info(_caller, f"{'info':<10}:shared settings section", omit=True)
            _writ_text: str = cat(rf"""
				[homes]
				    browseable = No
				    comment = Home Directories
				    create mask = 0700
				    directory mask = 2700
				    valid users = %S
				    write list = @{_data.samb_grup}
				[printers]
				    browseable = No
				    comment = All Printers
				    create mask = 0700
				    path = /var/tmp
				    printable = Yes
				[print$]
				    comment = Printer Drivers
				    path = /var/lib/samba/printers
				[adm]
				    browseable = No
				    comment = Administrator directories
				    create mask = 0660
				    directory mask = 2770
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.samb_path)}/adm
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[pub]
				    browseable = Yes
				    comment = Public directories
				    create mask = 0660
				    directory mask = 2770
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.samb_path)}/pub
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[usr]
				    browseable = No
				    comment = User directories
				    create mask = 0660
				    directory mask = 2770
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.samb_path)}/usr
				    valid users = @{_data.samb_gadm}
				    write list = @{_data.samb_gadm}
				[share]
				    browseable = No
				    comment = Shared directories
				    create mask = 0660
				    directory mask = 2770
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.samb_path)}
				    valid users = @{_data.samb_gadm}
				    write list = @{_data.samb_gadm}
				[dlna]
				    browseable = No
				    comment = DLNA directories
				    create mask = 0660
				    directory mask = 2770
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.samb_path)}/pub/contents/dlna
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[share-conf]
				    browseable = No
				    comment = Shared directory for configuration files
				    create mask = 0664
				    directory mask = 2775
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.xsmb_path)}/{_data.conf_path.name}
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[share-imgs]
				    browseable = No
				    comment = Shared directory for iso file extraction destination
				    create mask = 0664
				    directory mask = 2775
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.xsmb_path)}/{_data.imgs_path.name}
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[share-isos]
				    browseable = No
				    comment = Shared directory for iso image files
				    create mask = 0664
				    directory mask = 2775
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.xsmb_path)}/{_data.isos_path.name}
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[share-load]
				    browseable = No
				    comment = Shared directory for load module
				    create mask = 0664
				    directory mask = 2775
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.xsmb_path)}/{_data.load_path.name}
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[share-rmak]
				    browseable = No
				    comment = Shared directory for remake files
				    create mask = 0664
				    directory mask = 2775
				    force group = {_data.samb_grup}
				    force user = {_data.samb_user}
				    path = {str(_data.xsmb_path)}/{_data.rmak_path.name}
				    valid users = @{_data.samb_grup}
				    write list = @{_data.samb_gadm}
				[public-imgs]
				    browseable = No
				    comment = Public shared directory for iso file extraction destination
				    guest ok = Yes
				    path = {str(_data.xsmb_path)}/{_data.imgs_path.name}
				    wide links = Yes
			""")  # noqa: E101, E501
            fwrite(
                dest_path=_conf_temp,
                data=_writ_text,
                text=True,
                backup=False,
                append=True,
            )
            file_backup(info_syst=info_syst, orig_path=_conf_temp, mode="init")
            # --- output ----------------------------------------------------------
            message_info(_caller, f"{'info':<10}:output", omit=True)
            _envs_list["_CONF_TEMP"] = str(_conf_temp)
            _envs_list["_CONF_PATH"] = str(_conf_path)
            _shel_comd: str = r"""
                testparm -s "${_CONF_TEMP}" > "${_CONF_PATH}" || true
            """  # noqa: E501
            _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
            if _result.returncode != 0 and _result.stderr:
                print(_result.stderr)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- service restart -------------------------------------------------
        if not info_syst.data.tget_chrt:
            restart_service(srvc_name=_smbd_name)
            restart_service(srvc_name=_nmbd_name)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
