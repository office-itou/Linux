"""Common Function Package: src [generated: 2026/09/30 12:04:10 JST (+0900)]"""

# --- Python library ----------------------------------------------------------
import importlib

# --- my library --------------------------------------------------------------
__all__ = [
]

_MODULE_MAP = {
}


def __getattr__(name):
    if name in _MODULE_MAP:
        module = importlib.import_module(_MODULE_MAP[name], __name__)
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
