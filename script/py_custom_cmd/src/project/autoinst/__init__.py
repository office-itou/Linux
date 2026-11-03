"""Common Function Package: autoinst [generated: 2026/11/03 22:43:51 JST (+0900)]"""

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
    "func",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSystem": ".autoinst_fn_sysinfo",
    "SystemData": ".autoinst_def_sysinfo",
    "aaaa": ".test_networ",
    "ffff": ".test_networ",
    "func": ".test_networ",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
