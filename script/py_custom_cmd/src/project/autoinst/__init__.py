"""Common Function Package: autoinst [generated: 2026/10/23 22:20:20 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "CmdLine",
    "CmdlineData",
    "ConfigurationData",
    "InfoConfiguration",
    "InfoSystem",
    "SystemData",
]

_MODULE_MAP = {
    "CmdLine": ".autoinst_cmdline",
    "CmdlineData": ".autoinst_cmdline",
    "ConfigurationData": ".autoinst_common_cfg",
    "InfoConfiguration": ".autoinst_common_cfg",
    "InfoSystem": ".autoinst_syspara",
    "SystemData": ".autoinst_syspara",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
