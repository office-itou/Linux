#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import argparse
import inspect
import os
import sys
import time
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("USER")
execusr = os.getenv("SUDO_USER", execusr)
homedir = os.getenv("HOME")
homedir = os.getenv("SUDO_HOME", homedir)
libsdir = "/linux/script/py_custom_cmd/src/"
libsdir = Path(homedir) / libsdir.strip("/")
sys.path.append(str(libsdir))

from py_common.my_colors import color
from py_common.my_common_cfg import InfoConfiguration
from py_common.my_config import infosystem
from py_common.my_debug import debugout
from py_common.my_distribution_dat import InfoDistribution
from py_common.my_media_dat import InfoMedia
from py_common.my_message import (
    message_elapsed,
    message_end,
    message_info,
    message_start,
)


# -----------------------------------------------------------------------------
# descript: args parser
#   input :                  : unused
#   output:                  : unused
#   return: parse_args       : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def argsparser():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    parser = argparse.ArgumentParser(allow_abbrev=False)
    parser.add_argument("--debug", help="Debug mode", action="store_true")
    parser.add_argument(
        "--debugout", help="Debug mode for display only", action="store_true"
    )
    try:
        args = parser.parse_args()
    except Exception as e:  # noqa: BLE001
        print(f"How exceptional! {e}")
    else:
        infosystem.args = args

    if infosystem.args:
        infosystem.debug = infosystem.args.debug
        infosystem.debugout = (
            infosystem.args.debugout if infosystem.debug != True else True
        )
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")


# -----------------------------------------------------------------------------
# descript: initialize
#   input :                  : unused
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def initialize():
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    if infosystem.debug == True:
        message_info(function_name, "Debug mode on")
    if infosystem.debugout == True:
        message_info(function_name, "Debugout mode on")
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.get("PATH_DIST")
    path_mdia = info_conf.get("PATH_MDIA")
    info_dist = InfoDistribution(path_dist + ".json")
    info_mdia = InfoMedia(path_mdia + ".json", info_conf)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")
    return info_conf, info_dist, info_mdia


# -----------------------------------------------------------------------------
# descript: test
#   input : info_conf        : input
#   output:                  : unused
#   return:                  : unused
#   global:                  : unused
# -----------------------------------------------------------------------------
def test(info_conf, info_dist, info_mdia):
    function_name = f"{Path(__file__).stem}({inspect.currentframe().f_code.co_name})"
    debugout(function_name, "Start", color.yellow, "")
    # -------------------------------------------------------------------------
    #   info_conf.load()
    #   info_conf.dump()
    info_conf.markdown(
        Path(".") / "Readme_Configuration.md",
        f"Configuration data({Path(info_conf.get('PATH_CONF')).name})",
    )
    #   a = info_conf.conv2data(data)
    #   a = info_conf.conv2variable(data)
    #   a = info_conf.get(key)
    # -------------------------------------------------------------------------
    #   info_dist.dump()
    info_dist.markdown(
        Path(".") / "Readme_Distribution.md",
        f"Distribution data({Path(info_conf.get('PATH_DIST')).name})",
    )
    #   info_dist.load(info_conf.get('PATH_DIST') + '.json')
    info_dist.save(info_conf.get("PATH_DIST") + ".test.json")
    # -------------------------------------------------------------------------
    #   info_mdia.dump()
    info_mdia.markdown(
        Path(".") / "Readme_Media.md",
        f"Media data({Path(info_conf.get('PATH_MDIA')).name})",
    )
    #   info_mdia.load(info_conf.get('PATH_MDIA') + '.json', info_conf)
    info_mdia.save(info_conf.get("PATH_MDIA") + ".test.json", info_conf)
    #   info_mdia.conv2data(info_conf)
    #   info_mdia.conv2variable(info_conf)
    # -------------------------------------------------------------------------
    debugout(function_name, "Complete", color.yellow, "")


# -----------------------------------------------------------------------------
# descript: main
#   input :                  : unused
#   output: stdout           : output
#   return: exit             : output
#   global:                  : unused
# -----------------------------------------------------------------------------
def main():
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        print(
            f"{color.reset}{color.br_green}{infosystem.program_name}:\n{color.br_yellow} You have standard user privileges. {color.underline}Please run this with sudo.{color.reset}"
        )
        sys.exit(1)
    # --- system parameters ---------------------------------------------------
    function_name = inspect.currentframe().f_code.co_name
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- global variable -----------------------------------------------------
    #   global debug_flag
    #   global debugout_flag
    #   global program_name
    #   global col_size
    #   global row_size
    # --- startup process -----------------------------------------------------
    message_start(function_name)
    # --- processing block ----------------------------------------------------
    argsparser()
    if infosystem.args:
        info_conf, info_dist, info_mdia = initialize()
        test(info_conf, info_dist, info_mdia)
    # --- termination process -------------------------------------------------
    message_end(function_name)
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(function_name, elapsed)
    # --- exit ----------------------------------------------------------------
    sys.exit(0)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
