#!/usr/bin/env python3

import os

# import shutil
# import subprocess
# import tempfile
# from dataclasses import dataclass
from subprocess import CompletedProcess

from common.utils import (
    #    addpath,
    #    debug_logger,
    #    delpath,
    #    find_serivce,
    get_caller_name,
    handle_fatal_error,
    run_subprocess,
)

from autoinst_fn_initialize import initialize


_info_syst = initialize()
_data = _info_syst.data

print(_data.shar_path)
print(_data.expo_path)
print(_data.hgfs_path)
print(_data.html_path)
print(_data.samb_path)
print(_data.tftp_path)
print(_data.user_path)
print(_data.pvat_path)


def main():
    _caller = get_caller_name()
    try:
        _envs_list: dict[str, str] = os.environ.copy()
        _envs_list["_DIRS_SHAR"] = str(_data.shar_path)
        _envs_list["_DIRS_EXPO"] = str(_data.expo_path)
        _envs_list["_DIRS_HGFS"] = str(_data.hgfs_path)
        _envs_list["_DIRS_HTML"] = str(_data.html_path)
        _envs_list["_DIRS_SAMB"] = str(_data.samb_path)
        _envs_list["_DIRS_TFTP"] = str(_data.tftp_path)
        _envs_list["_DIRS_USER"] = str(_data.user_path)
        _envs_list["_DIRS_PVAT"] = str(_data.pvat_path)

        _shel_comd: str = r"""
            semanage fcontext -a -t var_t                "${_DIRS_SHAR:?}(/.*)?"            || true	# root of shared directory
        #	semanage fcontext -a -t nfs_t                "${_DIRS_EXPO:?}/nbd(/.*)?"        || true	# root of nbd exports shared directory
        #	semanage fcontext -a -t nfs_t                "${_DIRS_EXPO:?}/nfs(/.*)?"        || true	# root of nfs exports shared directory
            semanage fcontext -a -t fusefs_t             "${_DIRS_HGFS:?}(/.*)?"            || true	# root of hgfs shared directory
            semanage fcontext -a -t httpd_user_content_t "${_DIRS_HTML:?}(/.*)?"            || true	# root of html shared directory
            semanage fcontext -a -t samba_share_t        "${_DIRS_SAMB:?}(/.*)?"            || true	# root of samba shared directory
            semanage fcontext -a -t tftpdir_t            "${_DIRS_TFTP:?}(/.*)?"            || true	# root of tftp shared directory
            semanage fcontext -a -t var_t                "${_DIRS_USER:?}(/.*)?"            || true	# root of user shared directory
            # --- user share ----------------------------------------------------------
            semanage fcontext -a -t var_t                "${_DIRS_PVAT:?}(/.*)?"            || true	# root of private contents directory
            semanage fcontext -a -t public_content_t     "${_DIRS_SHAR:?}(/.*)?"            || true	# root of public contents directory
            # --- container -----------------------------------------------------------
            semanage fcontext -a -t public_content_t     "${_DIRS_SHAR:?}/cache(/.*)?"      || true
            semanage fcontext -a -t container_file_t     "${_DIRS_SHAR:?}/containers(/.*)?" || true
            # --- flag ----------------------------------------------------------------
            setsebool -P samba_export_all_rw=on   || true			# Determine whether samba can share any content readable and writable.
            setsebool -P httpd_enable_homedirs=on || true			# Determine whether httpd can traverse user home directories.
        #	setsebool -P global_ssp=on            || true			# Enable reading of urandom for all domains.
        """  # noqa: E501
        _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
        if _result.returncode != 0 and _result.stderr:
            print(_result.stderr)
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


main()
