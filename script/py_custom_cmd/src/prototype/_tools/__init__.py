"""Common Function Package: _tools [generated: 2026/09/30 00:00:38 JST (+0900)]"""

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
    "MainWindowBuildTables",
    "MainWindowEvent",
    "MarkdownWindow",
    "__getattr__",
    "analyze_script",
    "generate_data",
    "generate_file",
    "generate_target_block",
    "get_data",
    "load_module_map",
    "main",
    "parse_actual_imports",
    "resolve_dependencies_recursive",
    "scan_resource_files",
]

_MODULE_MAP = {
    "AsyncProcessHandler": ".async_io",
    "CustomIsoWindow": ".gui_custom_iso",
    "CustomLiveWindow": ".gui_custom_live",
    "DownloadWindow": ".gui_download",
    "EditWindow": ".gui_edit",
    "IpxeWindow": ".gui_ipxe",
    "MainWindow": ".gui_main",
    "MainWindowBuild": ".gui_main_build",
    "MainWindowBuildButtons": ".gui_main_build_buttons",
    "MainWindowBuildTables": ".gui_main_build_tables",
    "MainWindowEvent": ".gui_main_event",
    "MarkdownWindow": ".gui_markdown",
    "__getattr__": ".__init__",
    "analyze_script": ".generate_hidden_imports",
    "generate_data": ".creation_of_functions_init_file",
    "generate_file": ".creation_of_functions_init_file",
    "generate_target_block": ".generate_hidden_imports",
    "get_data": ".creation_of_functions_init_file",
    "load_module_map": ".generate_hidden_imports",
    "main": ".generate_hidden_imports",
    "parse_actual_imports": ".generate_hidden_imports",
    "resolve_dependencies_recursive": ".generate_hidden_imports",
    "scan_resource_files": ".generate_hidden_imports",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
