# --- Python library ----------------------------------------------------------
import argparse

# --- my library --------------------------------------------------------------
from py_common.my_config import infosystem


class Argument:
    def __init__(self):
        self.parser = argparse.ArgumentParser(allow_abbrev=False)
        self.parser.add_argument("--debug", help="Debug mode", action="store_true")
        self.parser.add_argument(
            "--debugout", help="Debug mode for display only", action="store_true"
        )
        self.args = None

    def add(self, *args, **kwargs):
        self.parser.add_argument(*args, **kwargs)

    def parse(self):
        self.args = self.parser.parse_args()
        if self.args:
            infosystem.args = self.args
            if self.args.debug:
                self.args.debugout = True
                infosystem.debug = self.args.debug
                infosystem.debugout = self.args.debugout
        return self.args
