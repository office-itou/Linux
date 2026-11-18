"""Common Function Package: autoinst [generated: 2026/11/19 02:24:04 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "ConfigurationData",
    "InfoConfiguration",
    "InfoSrvDir",
    "InfoSystem",
    "SrvDirData",
    "SystemData",
    "file_backup",
    "file_origin",
    "get_conf_file",
    "get_packages_nocloud",
    "get_packages_preseed",
    "mkdir_share",
    "mkdir_share_change_file_mode",
    "mkdir_share_create_directory",
    "mkdir_share_create_fstab",
    "mkdir_share_create_index_html",
    "mkdir_share_create_ipxe_menu",
    "mkdir_share_create_symlink",
    "mkdir_share_create_system_user",
    "package_install",
    "package_update",
    "setup_connman",
    "setup_dnsmasq",
    "setup_firewalld",
    "setup_firewalld_active",
    "setup_firewalld_inactive",
    "setup_hostname",
    "setup_hosts",
    "setup_netman",
    "setup_netplan",
    "setup_tcp_wrapper",
    "setup_wireplumber",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSrvDir": ".autoinst_def_mkdir_share",
    "InfoSystem": ".autoinst_fn_sysinfo",
    "SrvDirData": ".autoinst_def_mkdir_share",
    "SystemData": ".autoinst_def_sysinfo",
    "file_backup": ".autoinst_fn_file_backup",
    "file_origin": ".autoinst_fn_file_backup",
    "get_conf_file": ".autoinst_fn_get_conf_file",
    "get_packages_nocloud": ".autoinst_fn_package_install",
    "get_packages_preseed": ".autoinst_fn_package_install",
    "mkdir_share": ".autoinst_fn_mkdir_share",
    "mkdir_share_change_file_mode": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_directory": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_fstab": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_index_html": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_ipxe_menu": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_symlink": ".autoinst_fn_mkdir_share",
    "mkdir_share_create_system_user": ".autoinst_fn_mkdir_share",
    "package_install": ".autoinst_fn_package_install",
    "package_update": ".autoinst_fn_package_update",
    "setup_connman": ".autoinst_fn_setup_connman",
    "setup_dnsmasq": ".autoinst_fn_setup_dnsmasq",
    "setup_firewalld": ".autoinst_fn_setup_firewalld",
    "setup_firewalld_active": ".autoinst_fn_setup_firewalld",
    "setup_firewalld_inactive": ".autoinst_fn_setup_firewalld",
    "setup_hostname": ".autoinst_fn_setup_hostname",
    "setup_hosts": ".autoinst_fn_setup_hosts",
    "setup_netman": ".autoinst_fn_setup_netman",
    "setup_netplan": ".autoinst_fn_setup_netplan",
    "setup_tcp_wrapper": ".autoinst_fn_setup_tcp_wrapper",
    "setup_wireplumber": ".autoinst_fn_setup_wireplumber",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
