"""argparse wrapper (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import argparse


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    infosystem,
)

# ruff: isort: on
# =============================================================================
_ARGS_LIST = [
    {"arg": "--force-cui", "help": "Forced CUI mode", "action": "store_true"},
    {"arg": "--debug", "help": "Debug mode", "action": "store_true"},
    {"arg": "--debugout", "help": "Debug out", "action": "store_true"},
]


class Argument:
    """argparse wrapper class."""

    # -------------------------------------------------------------------------
    class DefaultListAction(argparse.Action):
        def __call__(self, parser, namespace, values, option_string=None):
            values = values if values else []
            setattr(namespace, self.dest, values)

    # -------------------------------------------------------------------------
    # @debug_chk_cui
    def __init__(self, description: str = "", list_args: list[dict[str, str]] = []):
        """Method for initializing the Argument class."""
        self.parser = argparse.ArgumentParser(f"{description}\n", allow_abbrev=False)
        for _line_arg in (*_ARGS_LIST, *list_args):
            if _line_arg:
                _arg_name = _line_arg.pop("arg")
                if isinstance(_arg_name, tuple):
                    self.add(*_arg_name, **_line_arg)
                else:
                    self.add(_arg_name, **_line_arg)
        infosystem.args = self.parse()

    # -------------------------------------------------------------------------
    def add(self, *args, **kwargs):
        """Method for adding command-line arguments.
        Args:
            *args: Arguments for `add_argument` (e.g., "-p", "--pattern")
            **kwargs: Arguments for `add_argument`
        """
        if kwargs.get("type") == "str":
            kwargs["type"] = str
        self.parser.add_argument(*args, **kwargs)

    # -------------------------------------------------------------------------
    def parse(self):
        """Method for returning the analysis results.
        Returns:
            obj: Save the object resulting from the parse.
        """
        self.args = self.parser.parse_args()
        if self.args:
            infosystem.args = self.args
            infosystem.debug = getattr(self.args, "debug", False)
            infosystem.debugout = (
                getattr(self.args, "debugout", False) or infosystem.debug
            )
        return self.args


# --- eof ---------------------------------------------------------------------
