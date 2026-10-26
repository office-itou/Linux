"""Common Function Package: autoinst [generated: 2026/10/26 21:56:00 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "ConfigurationData",
    "InfoConfiguration",
    "InfoSystem",
    "SystemData",
    "conv_ipv4_reverse",
    "conv_ipv6_full",
    "conv_ipv6_omit",
    "conv_ipv6_reverse",
    "network_param",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSystem": ".autoinst_fn_syspara",
    "SystemData": ".autoinst_fn_syspara",
    "conv_ipv4_reverse": ".autoinst_fn_network",
    "conv_ipv6_full": ".autoinst_fn_network",
    "conv_ipv6_omit": ".autoinst_fn_network",
    "conv_ipv6_reverse": ".autoinst_fn_network",
    "network_param": ".autoinst_fn_network",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
