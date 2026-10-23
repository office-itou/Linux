"""Common Function Package: _work [generated: 2026/10/17 11:39:05 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "AsyncDownload",
    "AsyncRsync",
    "AsyncWebInfo",
    "CustomLiveWindow",
    "EditWindow",
    "GenerateBootMenu",
    "GenerateBootOption",
    "GenerateIsoFile",
    "MainWindow",
    "MainWindowButtons",
    "MainWindowEvents",
    "MainWindowStatus",
    "MainWindowTables",
    "generate_boot_option_agama",
    "generate_boot_option_autoyast",
    "generate_boot_option_kickstart",
    "generate_boot_option_nocloud",
    "generate_boot_option_preseed",
    "main_cui",
    "main_gui",
]

_MODULE_MAP = {
    "AsyncDownload": ".async_download_handler",
    "AsyncRsync": ".async_rsync_handler",
    "AsyncWebInfo": ".async_web_info_handler",
    "CustomLiveWindow": ".gui_custom_live",
    "EditWindow": ".gui_edit",
    "GenerateBootMenu": ".generate_boot_menu",
    "GenerateBootOption": ".generate_boot_option",
    "GenerateIsoFile": ".generate_isofile_autoinst",
    "MainWindow": ".gui_main_build",
    "MainWindowButtons": ".gui_main_buttons",
    "MainWindowEvents": ".gui_main_events",
    "MainWindowStatus": ".gui_main_status",
    "MainWindowTables": ".gui_main_tables",
    "generate_boot_option_agama": ".generate_boot_option_agama",
    "generate_boot_option_autoyast": ".generate_boot_option_autoyast",
    "generate_boot_option_kickstart": ".generate_boot_option_kickstart",
    "generate_boot_option_nocloud": ".generate_boot_option_nocloud",
    "generate_boot_option_preseed": ".generate_boot_option_preseed",
    "main_cui": ".my_tools",
    "main_gui": ".my_tools",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
