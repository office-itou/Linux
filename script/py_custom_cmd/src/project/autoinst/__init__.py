"""Common Function Package: autoinst [generated: 2026/10/31 00:10:59 JST (+0900)]"""

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
    "file_backup",
    "file_origin",
    "get_conf_file",
    "get_packages_nocloud",
    "get_packages_preseed",
    "kill_all_dhcp",
    "mkdir_share",
    "network_param",
    "package_update",
    "package_update",
    "setup_connman",
    "setup_netman",
    "setup_netplan",
    "setup_wireplumber",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSystem": ".autoinst_fn_info_syspara",
    "SystemData": ".autoinst_fn_info_syspara",
    "conv_ipv4_reverse": ".autoinst_fn_info_network",
    "conv_ipv6_full": ".autoinst_fn_info_network",
    "conv_ipv6_omit": ".autoinst_fn_info_network",
    "conv_ipv6_reverse": ".autoinst_fn_info_network",
    "file_backup": ".autoinst_fn_file_backup",
    "file_origin": ".autoinst_fn_file_backup",
    "get_conf_file": ".autoinst_fn_get_conf_file",
    "get_packages_nocloud": ".autoinst_fn_package_install",
    "get_packages_preseed": ".autoinst_fn_package_install",
    "kill_all_dhcp": ".autoinst_cmd_run",
    "mkdir_share": ".autoinst_fn_mkdir_share",
    "network_param": ".autoinst_fn_info_network",
    "package_update": ".autoinst_fn_package_install",
    "package_update": ".autoinst_fn_package_update",
    "setup_connman": ".autoinst_fn_setup_connman",
    "setup_netman": ".autoinst_fn_setup_netman",
    "setup_netplan": ".autoinst_fn_setup_netplan",
    "setup_wireplumber": ".autoinst_fn_setup_wireplumber",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
