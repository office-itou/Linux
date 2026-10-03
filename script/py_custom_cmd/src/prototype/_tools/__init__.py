"""Common Function Package: _tools [generated: 2026/10/03 12:16:39 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "AsyncProcessHandler",
    "CustomIsoWindow",
    "CustomLiveWindow",
    "DownloadWindow",
    "EditWindow",
    "IpxeWindow",
    "MainWindow",
    "MainWindowBuild",
    "MainWindowBuildButtons",
    "MainWindowBuildStatus",
    "MainWindowBuildTables",
    "MainWindowEvent",
    "MarkdownWindow",
]

_MODULE_MAP = {
    "AsyncProcessHandler": ".gui_async_handler",
    "CustomIsoWindow": ".gui_custom_iso",
    "CustomLiveWindow": ".gui_custom_live",
    "DownloadWindow": ".gui_download",
    "EditWindow": ".gui_edit",
    "IpxeWindow": ".gui_ipxe",
    "MainWindow": ".gui_main",
    "MainWindowBuild": ".gui_main_build",
    "MainWindowBuildButtons": ".gui_main_build_buttons",
    "MainWindowBuildStatus": ".gui_main_build_status",
    "MainWindowBuildTables": ".gui_main_build_tables",
    "MainWindowEvent": ".gui_main_event",
    "MarkdownWindow": ".gui_markdown",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
