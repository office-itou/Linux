"""Common Function Package: shared"""

# --- Python library ----------------------------------------------------------
import importlib

# --- my library --------------------------------------------------------------
from ..utils.my_config import infosystem


__all__ = [
    "infosystem",
    "ConfigurationData",
    "InfoConfiguration",
    "load",
    "conv2data",
    "conv2variable",
    "spc_encode",
    "spc_decode",
    "get_text2list",
    "put_list2text",
    "DistributionData",
    "InfoDistribution",
    "parse_version_to_tuple",
    "sort_distribution_data",
    "sort_distribution_name",
    "MediaData",
    "InfoMedia",
    "Text_fmat",
    "CommonData",
    "InfoCommon",
]

_MODULE_MAP = {
    "ConfigurationData": ".my_common_cfg",
    "InfoConfiguration": ".my_common_cfg",
    "load": ".my_common_cfg",
    "conv2data": ".my_common_cfg",
    "conv2variable": ".my_common_cfg",
    "spc_encode": ".my_convert",
    "spc_decode": ".my_convert",
    "get_text2list": ".my_convert",
    "put_list2text": ".my_convert",
    "DistributionData": ".my_distribution_dat",
    "InfoDistribution": ".my_distribution_dat",
    "parse_version_to_tuple": ".my_distribution_dat",
    "sort_distribution_data": ".my_distribution_dat",
    "sort_distribution_name": ".my_distribution_dat",
    "MediaData": ".my_media_dat",
    "InfoMedia": ".my_media_dat",
    "Text_fmat": ".my_shared",
    "CommonData": ".my_shared",
    "InfoCommon": ".my_shared",
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
