"""Common Function Package: autoinst [generated: 2026/11/12 01:01:26 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "ConfigurationData",
    "InfoConfiguration",
    "InfoSystem",
    "SystemData",
    "aaaa",
    "ffff",
    "file_backup",
    "file_origin",
    "func",
    "get_conf_file",
    "setup_wireplumber",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSystem": ".autoinst_fn_sysinfo",
    "SystemData": ".autoinst_def_sysinfo",
    "aaaa": ".test_networ",
    "ffff": ".test_networ",
    "file_backup": ".autoinst_fn_file_backup",
    "file_origin": ".autoinst_fn_file_backup",
    "func": ".test_networ",
    "get_conf_file": ".autoinst_fn_get_conf_file",
    "setup_wireplumber": ".autoinst_fn_setup_wireplumber",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
