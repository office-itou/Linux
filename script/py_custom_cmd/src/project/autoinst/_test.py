#!/usr/bin/env python3
import os
import re
import shutil

# import subprocess
# import tempfile
from dataclasses import dataclass
from pathlib import Path
from subprocess import CompletedProcess

# from subprocess import CompletedProcess
from common.utils import (
    InfoNetworkIF,
    addpath,
    debug_logger,
    #    delpath,
    #    find_serivce,
    fread,
    fwrite,
    get_caller_name,
    handle_fatal_error,
    ipv4_lower,
    ipv4_mask,
    ipv4_reverse,
    ipv4_upper,
    ipv6_full,
    ipv6_lower,
    ipv6_mask,
    ipv6_reverse,
    ipv6_upper,
    run_subprocess,
)

from autoinst_fn_initialize import initialize


_info_syst = initialize()
_data = _info_syst.data


# print(_data.shar_path)
# print(_data.expo_path)
# print(_data.hgfs_path)
# print(_data.html_path)
# print(_data.samb_path)
# print(_data.tftp_path)
# print(_data.user_path)
# print(_data.pvat_path)
# print(_data.orig_path)


def main(info_syst):
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        _envs_list: dict[str, str] = os.environ.copy()
        _envs_list["_CONF_TEMP"] = str("/var/admin/smb.conf.work")
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
                -e  '                                             s%=.*$%= '"${_HOST_ALOW}"'%' \
                -e  '                                                                       }' \
                -e  '/^[ \t]*hosts deny[ \t]*=/                                             {' \
                -e  '                                             s/^/#/'                      \
                -e  '                                             s/=.*$/= ALL/'               \
                -e  '                                                                       }' \
                -e  'p                                                                      }' \
            > "${_CONF_TEMP:?}"
        """  # noqa: E501
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# boot/grub/grub.cfg
# boot/grub2/grub.cfg
# EFI/BOOT/grub.cfg
main(info_syst=_info_syst)
