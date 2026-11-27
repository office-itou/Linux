# --- python library ----------------------------------------------------------
import os
import re
import shutil
from pathlib import Path
from re import Pattern
from subprocess import CompletedProcess

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    delpath,
    fread,
    get_caller_name,
    handle_fatal_error,
    message_alert,
    message_info,
    run_subprocess,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup, file_origin


# --- class and function ------------------------------------------------------
@debug_logger
def setup_grub_menu(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    try:
        message_info(_caller, f"{'setup':<10}:grub menu", omit=True)
        # --- /etc/default/grub -----------------------------------------------
        _conf_path: Path = addpath(base=_tget_path, path=Path("/etc/default/grub"))
        _slnx_flag: bool = bool(shutil.which("semanage"))  # selinux
        _apar_flag: bool = bool(shutil.which("aa-enabled"))  # apparmor
        _slnx_text: str = "security=selinux selinux=1"
        _apar_text: str = "security=apparmor apparmor=1"
        _scrt_text: str = ""
        match _data.dist_name:
            case "debian" | "ubuntu":
                if _apar_flag:
                    _scrt_text: str = _apar_text
                elif _slnx_flag:
                    _scrt_text: str = _slnx_text
            case "fedora" | "centos" | "almalinux" | "rocky" | "miraclelinux":
                if _slnx_flag:
                    _scrt_text: str = _slnx_text
                elif _apar_flag:
                    _scrt_text: str = _apar_text
            case "opensuse-leap":
                if _data.dist_vers < 16:
                    if _apar_flag:
                        _scrt_text: str = _apar_text
                    elif _slnx_flag:
                        _scrt_text: str = _slnx_text
                else:
                    if _slnx_flag:
                        _scrt_text: str = _slnx_text
                    elif _apar_flag:
                        _scrt_text: str = _apar_text
            case "opensuse-tumbleweed":
                if _slnx_flag:
                    _scrt_text: str = _slnx_text
                elif _apar_flag:
                    _scrt_text: str = _apar_text
        # --- create /etc/default/grub.d/grub.cfg -----------------------------
        # https://www.gnu.org/software/grub/manual/grub/html_node/Simple-configuration.html
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        file_origin(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = (
            fread(src_path=_conf_path, text=True) + "\n" if _conf_path.exists() else ""
        )

        # --- GRUB_TIMEOUT ----------------------------------------------------
        # __WORK="$(sed -ne 's/^#*GRUB_TIMEOUT=\(.*\)$/\1/p' "${__CONF}")"
        # [ -z "${__WORK:-}" ] && echo "GRUB_TIMEOUT=\"\"" >> "${__CONF}"
        # --- GRUB_GFXMODE ----------------------------------------------------
        # __WORK="$(sed -ne 's/^#*GRUB_GFXMODE=\(.*\)$/\1/p' "${__CONF}")"
        # [ -z "${__WORK:-}" ] && echo "GRUB_GFXMODE=\"\"" >> "${__CONF}"
        # --- GRUB_INIT_TUNE --------------------------------------------------
        # __WORK="$(sed -ne 's/^#*GRUB_INIT_TUNE=\(.*\)$/\1/p' "${__CONF}")"
        # [ -z "${__WORK:-}" ] && echo "GRUB_INIT_TUNE=\"\"" >> "${__CONF}"
        # --- GRUB_CMDLINE_LINUX_DEFAULT --------------------------------------
        def _grub_cmdline_parser(text: str) -> list[str]:
            _retn_list: list[str] = []
            for _splt_text in text.split(" "):
                match _splt_text:
                    case (
                        "security="
                        | "apparmor="
                        | "hostname="
                        | "ifcfg="
                        | "language="
                        | "netsetup="
                        | "security="
                        | "selinux="
                        | "vga="
                    ):
                        pass
                    case _:
                        _retn_list.append(_splt_text)
            return _retn_list

        _ptrn_dflt: Pattern = re.compile(r"^#*GRUB_CMDLINE_LINUX_DEFAULT=(.*)$")
        _ptrn_comd: Pattern = re.compile(r"^#*GRUB_CMDLINE_LINUX=(.*)$")
        _parm_dflt: list[str] = []
        _parm_comd: list[str] = []
        for _read_line in _read_text.splitlines():
            if _match := _ptrn_dflt.match(_read_line):
                _parm_dflt = _grub_cmdline_parser(_match.group(1))
            elif _match := _ptrn_comd.match(_read_line):
                _parm_comd = _grub_cmdline_parser(_match.group(1))
        if shutil.which("netplan") and shutil.which("nmcli"):
            _parm_comd.append("ip=off")
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'setup':<10}:dist_name={_data.dist_name}", omit=True)
        message_info(_caller, f"{'setup':<10}:dist_vers={_data.dist_vers}", omit=True)
        message_info(_caller, f"{'setup':<10}:dist_code={_data.dist_code}", omit=True)
        message_info(
            _caller, f"{'setup':<10}:parm_comd={' '.join(_parm_comd)}", omit=True
        )
        message_info(
            _caller, f"{'setup':<10}:parm_dflt={' '.join(_parm_dflt)}", omit=True
        )
        message_info(_caller, f"{'setup':<10}:slnx_flag={str(_slnx_flag)}", omit=True)
        message_info(_caller, f"{'setup':<10}:apar_flag={str(_apar_flag)}", omit=True)
        # --- grub.cfg --------------------------------------------------------
        _grub_file: str = "grub.cfg"
        _rule_list: list[str] = [
            rf"boot/grub/{_grub_file}",
            rf"boot/grub2/{_grub_file}",
            rf"EFI/BOOT/{_grub_file}",
        ]
        _grub_path: Path = None
        _find_tget: Path = addpath(base=_tget_path, path=Path("/srv/user/share/imgs"))
        for _find_dist in _find_tget.glob(r"*"):
            for _find_rule in _rule_list:
                _find_path = _find_dist / _find_rule
                if _find_path.exists():
                    _grub_path = _find_path
                    break
        if not _grub_path:
            message_alert(_caller, f"file not found:{_grub_file}")
        else:
            message_info(_caller, f"{'create':<10}:{_data.dist_name}", omit=True)
            if shutil.which("grubby") and shutil.which("nmcli"):
                message_info(_caller, f"{'info':<10}:grubby", omit=True)
                _envs_list: dict[str, str] = os.environ.copy()
                _envs_list["_SCRT_TEXT"] = str(_scrt_text)
                _shel_comd: str = r"""
                    grubby --update-kernel=ALL --remove-args="security apparmor selinux quiet vga" --args="${_SCRT_TEXT:?}"  2>&1 || true
                    grubby --info=ALL 2>&1 || true
                """  # noqa: E501
                _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
                if _result.returncode != 0 and _result.stderr:
                    print(_result.stderr)
            else:
                _envs_list: dict[str, str] = os.environ.copy()
                _envs_list["_ORIG_PATH"] = str(
                    _data.orig_path / delpath(base=_tget_path, path=_conf_path)
                )
                _envs_list["_CONF_PATH"] = str(_conf_path)
                _envs_list["_PARM_DFLT"] = str(_parm_dflt).replace(r"/", r"\\/")
                _envs_list["_PARM_COMD"] = str(_parm_comd).replace(r"/", r"\\/")
                _shel_comd: str = r"""
                    sed -e '/^#*GRUB_TIMEOUT_STYLE.*$/          {s/^#//; h; s/^/#/; p; g; s/=.*$/="menu"/}' \
                        -e '/^#*GRUB_RECORDFAIL_TIMEOUT=.*$/    {s/^#//; h; s/^/#/; p; g; s/[0-9]\+$/10/}' \
                        -e '/^#*GRUB_TIMEOUT=.*$/               {s/^#//; h; s/^/#/; p; g; s/[0-9]\+$/3/ }' \
                        -e '/^#*GRUB_GFXMODE=.*$/               {s/^#//; h; s/^/#/; p; g; s/=.*$/="1920x1080,800x600,auto"/}' \
                        -e '/^#*GRUB_INIT_TUNE=.*$/             {s/^#//; h; s/^/#/; p; g; s/=.*$/="960 440 1 0 4 440 1"/}' \
                        -e '/^#*GRUB_CMDLINE_LINUX_DEFAULT=.*$/ {s/^#//; h; s/^/#/; p; g; s/=.*$/="'"${_PARM_DFLT:-}"'"/}' \
                        -e '/^#*GRUB_CMDLINE_LINUX=.*$/         {s/^#//; h; s/^/#/; p; g; s/=.*$/="'"${_PARM_COMD:-}"'"/}' \
                        -i "${_CONF_PATH:?}"
                    diff --suppress-common-lines --expand-tabs "${_ORIG_PATH:?}" "${_CONF_PATH:?}" || true
                """  # noqa: E501
                _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
                if _result.returncode != 0 and _result.stderr:
                    print(_result.stderr)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
            _shel_comd: str = ""
            if shutil.which("grub-mkconfig"):
                message_info(_caller, f"{'info':<10}:grub-mkconfig", omit=True)
                _shel_comd: str = (
                    r'grub-mkconfig --output="${_GRUB_PATH:?}" 2>&1 || true'
                )
            elif shutil.which("grub2-mkconfig"):
                message_info(_caller, f"{'info':<10}:grub2-mkconfig", omit=True)
                _shel_comd: str = (
                    r'grub2-mkconfig --output="${_GRUB_PATH:?}" 2>&1 || true'
                )
            if _shel_comd:
                _envs_list["_GRUB_PATH"] = str(_grub_path)
                _result: CompletedProcess = run_subprocess(_shel_comd, env=_envs_list)
                if _result.returncode != 0 and _result.stderr:
                    print(_result.stderr)
        file_backup(info_syst=info_syst, orig_path=_grub_path, mode="init")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(_caller, e)


# --- eof ---------------------------------------------------------------------
# --- memo --------------------------------------------------------------------
# https://documentation.suse.com/ja-jp/sles/12-SP5/html/SLES-all/cha-grub2.html
# GRUB_BACKGROUND
# GRUB_BADRAM
# GRUB_BUTTON_CMOS_ADDRESS
# GRUB_BUTTON_CMOS_CLEAN
# GRUB_CMDLINE_GNUMACH
# GRUB_CMDLINE_LINUX
# GRUB_CMDLINE_LINUX_DEFAULT
# GRUB_CMDLINE_LINUX_RECOVERY
# GRUB_CMDLINE_LINUX_XEN_REPLACE
# GRUB_CMDLINE_LINUX_XEN_REPLACE_DEFAULT
# GRUB_CMDLINE_NETBSD
# GRUB_CMDLINE_NETBSD_DEFAULT
# GRUB_CMDLINE_XEN
# GRUB_CMDLINE_XEN_DEFAULT
# GRUB_DEFAULT_BUTTON
# GRUB_DEFAULT_DTB - grub2
# GRUB_DISABLE_LINUX_PARTUUID
# GRUB_DISABLE_LINUX_UUID
# GRUB_DISABLE_OS_PROBER - grub2
# GRUB_DISABLE_RECOVERY
# GRUB_DISABLE_SUBMENU
# GRUB_DISABLE_UUID
# GRUB_DISTRIBUTOR
# GRUB_EARLY_INITRD_LINUX_CUSTOM
# GRUB_EARLY_INITRD_LINUX_STOCK
# GRUB_ENABLE_BLSCFG - grub2
# GRUB_ENABLE_CRYPTODISK
# GRUB_GFXMODE
# GRUB_GFXPAYLOAD_LINUX
# GRUB_HIDDEN_TIMEOUT
# GRUB_HIDDEN_TIMEOUT_BUTTON
# GRUB_HIDDEN_TIMEOUT_QUIET
# GRUB_INIT_TUNE
# GRUB_OS_PROBER_SKIP_LIST
# GRUB_RECORDFAIL_TIMEOUT - grub
# GRUB_RECOVERY_TITLE - grub
# GRUB_SAVEDEFAULT
# GRUB_SERIAL_COMMAND
# GRUB_TERMINAL_INPUT
# GRUB_TERMINAL_OUTPUT
# GRUB_THEME
# GRUB_TIMEOUT
# GRUB_TIMEOUT_BUTTON
# GRUB_TIMEOUT_STYLE
# GRUB_TIMEOUT_STYLE_BUTTON
# GRUB_TOP_LEVEL
# GRUB_TOP_LEVEL_OS_PROBER
# GRUB_TOP_LEVEL_XEN
# GRUB_VIDEO_BACKEND
