# --- python library ----------------------------------------------------------
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    debug_logger,
    find_serivce,
    fread,
    fwrite,
    get_caller_name,
    restart_user_service,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_file_backup import file_backup


# --- class and function ------------------------------------------------------
@debug_logger
def setup_wireplumber(info_syst):
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- check service -------------------------------------------------------
    _srvc_name: str = "wireplumber.service"
    _srvc_path: Path = find_serivce(tget_path=_tget_path, srvc_name=_srvc_name)
    if not _srvc_path or not _srvc_path.exists():
        return
    # --- memo ----------------------------------------------------------------
    # https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Troubleshooting

    # --- main.conf -----------------------------------------------------------
    _conf_path: Path = addpath(
        base=_tget_path,
        path=Path("/usr/share/wireplumber/main.lua.d/50-alsa-config.lua"),
    )
    if _conf_path.exists():
        # --- memo ------------------------------------------------------------
        # debian-12
        #   wireplumber: 0.4.13
        #   pipewire   : 0.3.65
        # --- alsa: 51-alsa-config.lua ----------------------------------------
        # stuttering audio (in virtual machine)
        _conf_path: Path = addpath(
            base=_tget_path, path=Path("/etc/wireplumber/main.lua.d/51-alsa-config.lua")
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = fread(src_path=_conf_path, text=True)
        if "alsa_monitor.properties" not in _read_text:
            _writ_text: str = (
                f"{_read_text}"
                "\n"
                "alsa_monitor.properties = {\n"
                '  ["vm.node.defaults"] = {\n'
                '    ["api.alsa.period-size"] = 1024,\n'
                '    ["api.alsa.headroom"] = 16384,\n'
                "  },\n"
                "}\n"
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- bluetooth: 51-bluez-config.lua ----------------------------------
        # headset disabled
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path("/etc/wireplumber/bluetooth.lua.d/51-bluez-config.lua"),
        )
        _read_text: str = fread(src_path=_conf_path, text=True)
        if "bluez_monitor.properties" not in _read_text:
            _writ_text: str = (
                f"{_read_text}"
                "\n"
                "bluez_monitor.properties = {\n"
                '  ["bluez5.headset-roles"] = "[ ]",\n'
                '  ["bluez5.hfphsp-backend"] = "none"\n'
                "}\n"
                "\n"
                "bluez_monitor.rules = {\n"
                "  {\n"
                "    matches = {\n"
                "      {\n"
                "        -- Matches all sources.\n"
                '        { "node.name", "matches", "bluez_input.*" },\n'
                "      },\n"
                "      {\n"
                "        -- Matches all sinks.\n"
                '        { "node.name", "matches", "bluez_output.*" },\n'
                "      },\n"
                "    },\n"
                "    apply_properties = {\n"
                '      ["bluez5.auto-connect"] = "[ a2dp_sink ]",\n'
                '      ["bluez5.hw-volume"]    = "[ a2dp_sink ]",\n'
                "    },\n"
                "  },\n"
                "}\n"
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    else:
        # --- memo ------------------------------------------------------------
        # debian-13
        #   wireplumber: 0.5.8
        #   pipewire   : 1.4.2
        # --- alsa: 50-alsa-suspend.conf --------------------------------------
        # loud pops when starting a sound
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path("/etc/wireplumber/wireplumber.conf.d/50-alsa-suspend.conf"),
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = fread(src_path=_conf_path, text=True)
        if "monitor.alsa.rules" not in _read_text:
            _writ_text: str = (
                f"{_read_text}"
                "\n"
                "monitor.alsa.rules = [\n"
                "  {\n"
                "    matches = [\n"
                "      # This matches the value of the 'node.name' property of the node.\n"  # noqa: E501
                "      {\n"
                '        node.name = "~alsa_output.*"\n'
                "      }\n"
                "    ]\n"
                "    actions = {\n"
                "      update-props = {\n"
                "        session.suspend-timeout-seconds = 0\n"
                "      }\n"
                "    }\n"
                "  }\n"
                "]\n"
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- alsa: 50-alsa-config.conf ---------------------------------------
        # stuttering audio (in virtual machine)
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path("/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf"),
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = fread(src_path=_conf_path, text=True)
        if "monitor.alsa.rules" not in _read_text:
            _writ_text: str = (
                f"{_read_text}"
                "\n"
                "monitor.alsa.rules = [\n"
                "  {\n"
                "    matches = [\n"
                "      # This matches the value of the 'node.name' property of the node.\n"  # noqa: E501
                "      {\n"
                '        node.name = "~alsa_output.*"\n'
                "      }\n"
                "    ]\n"
                "    actions = {\n"
                "      # Apply all the desired node specific settings here.\n"
                "      update-props = {\n"
                "        api.alsa.period-size   = 1024\n"
                "        api.alsa.headroom      = 16384\n"
                "      }\n"
                "    }\n"
                "  }\n"
                "]\n"
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
        # --- bluetooth: 50-bluez.conf ----------------------------------------
        # headset disabled
        _conf_path: Path = addpath(
            base=_tget_path,
            path=Path("/etc/wireplumber/wireplumber.conf.d/50-bluez.conf"),
        )
        file_backup(info_syst=info_syst, orig_path=_conf_path)
        _read_text: str = fread(src_path=_conf_path, text=True)
        if "monitor.bluez.properties" not in _read_text:
            _writ_text: str = (
                f"{_read_text}"
                "\n"
                "monitor.bluez.properties = {\n"
                '  bluez5.headset-roles  = "[ ]"\n'
                '  bluez5.hfphsp-backend = "none"\n'
                "}\n"
                "\n"
                "monitor.bluez.rules = [\n"
                "  {\n"
                "    matches = [\n"
                "      {\n"
                '        node.name = "~bluez_input.*"\n'
                "      }\n"
                "      {\n"
                '        node.name = "~bluez_output.*"\n'
                "      }\n"
                "    ]\n"
                "    actions = {\n"
                "      update-props = {\n"
                '        bluez5.auto-connect = "[ a2dp_sink ]"\n'
                '        bluez5.hw-volume    = "[ a2dp_sink ]"\n'
                "      }\n"
                "    }\n"
                "  }\n"
                "]\n"
            )
            fwrite(dest_path=_conf_path, data=_writ_text, text=True, backup=False)
            file_backup(info_syst=info_syst, orig_path=_conf_path, mode="init")
    # --- service restart -----------------------------------------------------
    if not info_syst.data.tget_chrt:
        restart_user_service(srvc_name=_srvc_name)


# --- eof ---------------------------------------------------------------------
