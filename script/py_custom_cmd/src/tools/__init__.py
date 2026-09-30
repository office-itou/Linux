"""Common Function Package: tools [generated: 2026/09/30 21:50:40 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "analyze_script",
    "check_is_gui",
    "data_save",
    "debugdump",
    "generate_data",
    "generate_file",
    "generate_ipxe_menu",
    "generate_ipxe_menu_file",
    "generate_target_block",
    "get_data",
    "load_module_map",
    "parse_actual_imports",
    "process_directory",
    "resolve_dependencies_recursive",
    "scan_required_resources",
]

_MODULE_MAP = {
    "analyze_script": ".generate_hidden_imports",
    "check_is_gui": ".generate_hidden_imports",
    "data_save": ".test_get_web_file_info",
    "debugdump": ".management_of_shared_data",
    "generate_data": ".creation_of_functions_init_file",
    "generate_file": ".creation_of_functions_init_file",
    "generate_ipxe_menu": ".creation_of_the_ipxe_menu",
    "generate_ipxe_menu_file": ".creation_of_the_ipxe_menu",
    "generate_target_block": ".generate_hidden_imports",
    "get_data": ".creation_of_functions_init_file",
    "load_module_map": ".generate_hidden_imports",
    "parse_actual_imports": ".generate_hidden_imports",
    "process_directory": ".creation_of_functions_init_file",
    "resolve_dependencies_recursive": ".generate_hidden_imports",
    "scan_required_resources": ".generate_hidden_imports",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
