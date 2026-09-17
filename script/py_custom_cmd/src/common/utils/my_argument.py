"""argparse wrapper"""

# --- Python library ----------------------------------------------------------
import argparse

# --- my library --------------------------------------------------------------
from .my_config import infosystem


# -----------------------------------------------------------------------------
class Argument:
    """argparse wrapper class."""

    # -------------------------------------------------------------------------
    class DefaultListAction(argparse.Action):
        def __call__(self, parser, namespace, values, option_string=None):
            values = values if values else []
            setattr(namespace, self.dest, values)

    # -------------------------------------------------------------------------
    def __init__(self, description: str = ""):
        """Method for initializing the Argument class."""
        self.parser = argparse.ArgumentParser(description, allow_abbrev=False)
        self.parser.add_argument("--debug", help="Debug mode", action="store_true")
        self.parser.add_argument(
            "--debugout", help="Debug mode for display only", action="store_true"
        )
        self.args = None

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
            if self.args.debug:
                self.args.debugout = True
                infosystem.debug = self.args.debug
                infosystem.debugout = self.args.debugout
        return self.args


# --- eof ---------------------------------------------------------------------
