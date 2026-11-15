"""Common Function Package: autoinst [generated: 2026/11/15 10:37:00 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "ConfigurationData",
    "InfoConfiguration",
    "InfoSystem",
    "SystemData",
    "file_backup",
    "file_origin",
    "get_conf_file",
    "get_packages_nocloud",
    "get_packages_preseed",
    "package_install",
    "package_update",
    "setup_wireplumber",
]

_MODULE_MAP = {
    "ConfigurationData": ".autoinst_fn_common_cfg",
    "InfoConfiguration": ".autoinst_fn_common_cfg",
    "InfoSystem": ".autoinst_fn_sysinfo",
    "SystemData": ".autoinst_def_sysinfo",
    "file_backup": ".autoinst_fn_file_backup",
    "file_origin": ".autoinst_fn_file_backup",
    "get_conf_file": ".autoinst_fn_get_conf_file",
    "get_packages_nocloud": ".autoinst_fn_package_install",
    "get_packages_preseed": ".autoinst_fn_package_install",
    "package_install": ".autoinst_fn_package_install",
    "package_update": ".autoinst_fn_package_update",
    "setup_wireplumber": ".autoinst_fn_setup_wireplumber",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
