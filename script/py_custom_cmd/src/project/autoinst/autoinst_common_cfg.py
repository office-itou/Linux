"""common.cfg I/O"""

# --- Python library ----------------------------------------------------------
import os
import re
from dataclasses import dataclass, fields
from pathlib import Path
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
    file_read,
    get_caller_name,
    infosystem,
    message_info,
)

# ruff: isort: on
# --- import module -----------------------------------------------------------
from autoinst_syspara import InfoSystem


# =============================================================================
@dataclass
class ConfigurationData:
    """common.cfg data class"""

    key: str = ""
    value: str = ""
    comment: str = ""


class InfoConfiguration:
    @debug_logger
    def __init__(self, conf_path: Path, info_syst: InfoSystem) -> None:
        self._valid_fields: set[str] = {f.name for f in fields(ConfigurationData)}
        self.data: ConfigurationData = ConfigurationData()
        self.load(conf_path=conf_path)
        self.debug(info_syst)

    @debug_logger
    def debug(self, info_syst: InfoSystem) -> None:
        if info_syst.data.dout_flag or getattr(infosystem, "debugout", False):
            _caller = get_caller_name()
            message_info(_caller, "*** start: ConfigurationData ***", omit=True)
            for _clas_data in self.data:
                message_info(
                    _caller, f"{_clas_data.key}={_clas_data.value or ''}", omit=True
                )
            message_info(_caller, "*** end  : ConfigurationData ***", omit=True)

    @debug_logger
    def load(self, conf_path: Path) -> None:
        _caller = get_caller_name()
        message_info(_caller, f"loading :{conf_path}", omit=True)
        # --- get setting items ---------------------------------------------------
        _line_pattern: re.Pattern[str] = re.compile(
            r'^(\w+)="([^"]*)"\s*(?:(#\s*.*))?$'
        )
        _vars_pattern: re.Pattern[str] = re.compile(r":_([A-Z0-9_]+)_:")
        _dict_conf: dict[str, str] = {}
        _list_conf: list[ConfigurationData] = []
        _data_dist: str = str(file_read(conf_path))
        for _line in _data_dist.splitlines():
            _line_raw: str = _line.strip()
            if not _line_raw or not _line_raw[0].isupper():
                continue
            if _match := _line_pattern.match(_line_raw):
                _key: str | Any = _match.group(1)
                _value: str | Any = _match.group(2)
                _comment: str | Any = _match.group(3) or ""
                for _ in range(10):
                    if _vars_match := _vars_pattern.search(_value):
                        _match_text: str = _vars_match.group(0)
                        _match_key: str | Any = _vars_match.group(1)
                        if _match_key in _dict_conf:
                            _value: str | Any = _value.replace(
                                _match_text, _dict_conf[_match_key]
                            )
                        else:
                            break
                    else:
                        break
                _dict_conf[_key] = _value
                _list_conf.append(
                    ConfigurationData(key=_key, value=_value, comment=_comment)
                )
        self.data: list[ConfigurationData] = _list_conf
        message_info(_caller, f"complete:{conf_path}", omit=True)

    @debug_logger
    def findregexp(self, queries: list[dict[str, str]]) -> list[ConfigurationData]:
        _results: list[ConfigurationData] = []
        _compiled_queries: list[tuple[str, re.Pattern[str]]] = [
            (_q_key, re.compile(_q_pattern))
            for _query in queries
            for _q_key, _q_pattern in _query.items()
        ]
        for _class_data in self.data:
            for _q_key, _pattern in _compiled_queries:
                _target_str: Any | None = getattr(_class_data, _q_key, None)
                if _target_str and _pattern.search(_target_str):
                    _results.append(_class_data)
                    break
        return _results

    @debug_logger
    def finds(self, **kwargs) -> list[ConfigurationData]:
        MISSING = object()
        result = []
        for _class_data in self.data:
            match = True
            for _key, _value in kwargs.items():
                attr_val: Any | object = getattr(_class_data, _key, MISSING)
                if attr_val is MISSING:
                    match = False
                    break
                if isinstance(_value, str) and isinstance(attr_val, str):
                    if not re.search(_value, attr_val):
                        match = False
                        break
                else:
                    if attr_val != _value:
                        match = False
                        break
            if match:
                result.append(_class_data)
        return result

    @debug_logger
    def find(self, **kwargs) -> ConfigurationData:
        MISSING = object()
        return next(
            _class_data
            for _class_data in self.data
            if all(
                getattr(_class_data, _key, MISSING) == _value
                for _key, _value in kwargs.items()
            )
        )

    @debug_logger
    def get_path(self, key: str) -> Path:
        _path_str: str = self.find(key=key).value
        if not _path_str:
            raise ValueError(f"No such key '{key}'")
        _path_str: str = os.path.expanduser(os.path.expandvars(_path_str))
        return Path(_path_str).resolve()


# --- eof ---------------------------------------------------------------------
