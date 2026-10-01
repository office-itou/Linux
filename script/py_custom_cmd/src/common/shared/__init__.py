"""Common Function Package: shared [generated: 2026/10/01 19:21:06 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib  # noqa: E402


# --- my library --------------------------------------------------------------
__all__ = [
    "infosystem",
    "gui_log_windows",
    "CommonData",
    "ConfigurationData",
    "DistributionData",
    "InfoCommon",
    "InfoConfiguration",
    "InfoDistribution",
    "InfoMedia",
    "MediaData",
    "Text_fmat",
    "check_root",
    "conv2data",
    "conv2variable",
    "generate_markdown",
    "get_text2list",
    "get_web_file_info",
    "initarg",
    "load",
    "parse_version_to_tuple",
    "put_list2text",
    "sort_distribution_data",
    "sort_distribution_name",
    "spc_decode",
    "spc_encode",
]

_MODULE_MAP = {
    "infosystem": "..utils.my_config",
    "gui_log_windows": "..utils.my_config",
    "CommonData": ".my_shared",
    "ConfigurationData": ".my_common_cfg",
    "DistributionData": ".my_distribution_dat",
    "InfoCommon": ".my_shared",
    "InfoConfiguration": ".my_common_cfg",
    "InfoDistribution": ".my_distribution_dat",
    "InfoMedia": ".my_media_dat",
    "MediaData": ".my_media_dat",
    "Text_fmat": ".my_shared",
    "check_root": ".my_func_check_root",
    "conv2data": ".my_common_cfg",
    "conv2variable": ".my_common_cfg",
    "generate_markdown": ".my_func_generate_markdown",
    "get_text2list": ".my_convert",
    "get_web_file_info": ".my_async_api",
    "initarg": ".my_func_initarg",
    "load": ".my_common_cfg",
    "parse_version_to_tuple": ".my_distribution_dat",
    "put_list2text": ".my_convert",
    "sort_distribution_data": ".my_distribution_dat",
    "sort_distribution_name": ".my_distribution_dat",
    "spc_decode": ".my_convert",
    "spc_encode": ".my_convert",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
