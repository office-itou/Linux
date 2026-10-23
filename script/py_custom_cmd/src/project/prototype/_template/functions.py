# --- Python library ----------------------------------------------------------
# ruff: isort: off
# --- my library --------------------------------------------------------------
from my_colors import Color
from my_config import infosystem
from my_debug import debug_logger
from my_string import eprint


# ruff: isort: on
# ruff: isort: off
# --- my modules --------------------------------------------------------------
# ruff: isort: on
# -----------------------------------------------------------------------------
@debug_logger
def test():
    """Test"""
    strhalf = "1234567890123456798012345678901234567980"
    strwide = "１２３４５６７８９０１２３４５６７８９０"
    strmixd = f"12345678901234567980{Color.underline}１２３４５６７８９０"
    strslid = f"12345678901234567980 {Color.underline}１２３４５６７８９０"
    list_text = [
        f"{strhalf}{Color.green}{strhalf}{Color.yellow}{strhalf}{Color.red}{strhalf}{Color.magenta}{strhalf}",
        f"{strwide}{Color.green}{strwide}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
        f"{strhalf}{Color.green}{strmixd}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
        f"{strhalf}{Color.green}{strslid}{Color.yellow}{strwide}{Color.red}{strwide}{Color.magenta}{strwide}",
    ]
    for text in list_text:
        eprint(f"{Color.reset}{text}{text}{Color.reset}", infosystem.columns)
    for text in list_text:
        eprint(f"{Color.reset}{text}{text}{Color.reset}", infosystem.columns, wrap=True)
