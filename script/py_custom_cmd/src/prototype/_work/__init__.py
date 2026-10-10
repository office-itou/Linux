"""Common Function Package: _work [generated: 2026/10/11 00:55:14 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "AsyncDownload",
    "AsyncRsync",
    "AsyncWebInfo",
    "BaseAsyncProcessHandler",
    "CustomIsoWindow",
    "CustomLiveWindow",
    "DownloadWindow",
    "EditWindow",
    "MainWindow",
    "MainWindowButtons",
    "MainWindowEvents",
    "MainWindowStatus",
    "MainWindowTables",
    "main_cui",
    "main_gui",
    "pre_authenticate_sudo",
    "process_rsync",
]

_MODULE_MAP = {
    "AsyncDownload": ".async_download_handler",
    "AsyncRsync": ".async_rsync_handler",
    "AsyncWebInfo": ".async_web_info_handler",
    "BaseAsyncProcessHandler": ".async_base_handler",
    "CustomIsoWindow": ".gui_custom_iso",
    "CustomLiveWindow": ".gui_custom_live",
    "DownloadWindow": ".gui_download",
    "EditWindow": ".gui_edit",
    "MainWindow": ".gui_main_build",
    "MainWindowButtons": ".gui_main_buttons",
    "MainWindowEvents": ".gui_main_events",
    "MainWindowStatus": ".gui_main_status",
    "MainWindowTables": ".gui_main_tables",
    "main_cui": ".my_tools",
    "main_gui": ".my_tools",
    "pre_authenticate_sudo": ".test_rsync",
    "process_rsync": ".test_rsync",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
