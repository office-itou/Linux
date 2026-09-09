#!/usr/bin/env python3

"""Template"""

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from pathlib import Path

# --- my library --------------------------------------------------------------
# execusr = os.getenv("SUDO_USER", os.getenv("USER"))
# homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
# libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
# if str(libsdir) not in sys.path:
#    sys.path.append(str(libsdir))
from common.shared.my_common_cfg import InfoConfiguration
from common.shared.my_distribution_dat import (
    InfoDistribution,
    sort_distribution_data,
    sort_distribution_name,
)
from common.shared.my_media_dat import InfoMedia
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_fileio import file_read, file_write
from common.utils.my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)


@debug_logger
def initialize() -> tuple[InfoConfiguration, InfoDistribution, InfoMedia]:
    """Initialize

    Returns:
        tuple[InfoConfiguration, InfoDistribution, InfoMedia]: info_conf, info_dist, info_mdia
    """
    if infosystem.debug == True:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout == True:
        message_info(get_caller_name(), "Debugout mode on")
    # -------------------------------------------------------------------------
    info_conf = InfoConfiguration()
    path_dist = info_conf.get_path(key="PATH_DIST")
    path_mdia = info_conf.get_path(key="PATH_MDIA")
    info_dist = InfoDistribution(path_dist.with_name(path_dist.name + ".json"))
    info_mdia = InfoMedia(path_mdia.with_name(path_mdia.name + ".json"))
    # -------------------------------------------------------------------------
    return info_conf, info_dist, info_mdia


def generate_ipxe_menu_file(
    path_src: Path,
    path_dest: Path,
    info_conf: InfoConfiguration,
    info_dist: InfoDistribution,
):
    target_distribution = re.sub(r"^[^_]+_([^.]+)\.ipxe", r"\1", path_src.name)
    if target_distribution == "windows":
        query_version = r"^(windows-|winpe-|ati[0-9]{4}|memtest86plus-).+$"
    else:
        query_version = rf"^{target_distribution}-.+$"
    queries = [{"version": query_version}, {"life": r"^(?!EOL).*$"}]
    find_results = info_dist.findregexp(queries)
    sort_results = sort_distribution_data(find_results, "", reverse=True)
    # -------------------------------------------------------------------------
    pattern = r":_([A-Z0-9_]+)_:"
    match = re.compile(pattern)
    read_data = file_read(path_src)
    conv_dist = match.sub(
        lambda m: str(info_conf.find(key=m.group(1)).value), read_data
    )
    # -------------------------------------------------------------------------
    item_width = 47
    item_data = []
    for read_line in conv_dist.splitlines():
        if r"<items>" in read_line:  # --- items -------------------------------
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = f"{f'item -- {goto_name}':<{item_width}} - {data_dist.name} ${{edition}} {data_dist.version_id}"
                if data_dist.code_name != "-":
                    item_text += rf" ({data_dist.code_name})"
                item_data.append(item_text)
        elif r"<goto selection>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf"{f'iseq ${{selected}} {goto_name}':<{item_width}} && goto {data_dist.name}-{data_dist.version_id}"
                item_data.append(item_text)
        elif r"<goto target>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf":{goto_name}"
                item_data.append(item_text)
        elif r"<code selection>" in read_line:
            for data_dist in sort_results:
                goto_name = re.sub(
                    r" ", "_", f"{data_dist.name}-{data_dist.version_id}"
                )
                item_text = rf"{f'iseq ${{selected}} {goto_name}':<{item_width}} && set vers {data_dist.version_id} ||"
                item_data.append(item_text)
        else:
            item_data.append(read_line)
    # -------------------------------------------------------------------------
    write_data = "\n".join(item_data) + "\n"
    file_write(path_dest, write_data, text=True, backup=True)


@debug_logger
def generate_ipxe_menu(
    info_conf: InfoConfiguration, info_dist: InfoDistribution, info_mdia: InfoMedia
) -> None:
    # -------------------------------------------------------------------------
    path_autexec = Path(str(info_conf.find(key="PATH_IPXE").value))
    path_ipxe_dir = path_autexec.parent
    path_tplt_ipxe_dir = Path(str(info_conf.find(key="DIRS_TMPL").value)) / "ipxe"
    list_tplt_files = sort_distribution_name(
        [file for file in path_tplt_ipxe_dir.glob(r"*.ipxe") if file.is_file()]
    )
    # -------------------------------------------------------------------------
    for path_src in list_tplt_files:
        if path_src.name == path_autexec.name:
            path_dest = path_ipxe_dir / path_src.name
        else:
            path_dest = path_ipxe_dir / "menu" / path_src.name
        message_info(get_caller_name(), str(path_dest))
        generate_ipxe_menu_file(path_src, path_dest, info_conf, info_dist)


@debug_logger
def main():
    """Main"""
    # --- check the executing user --------------------------------------------
    if os.geteuid() != 0:
        message_warn(
            get_caller_name(),
            "You have standard user privileges.",
        )
        message_warn(
            get_caller_name(),
            f"{Color.underline}Please run this with sudo.",
        )
        sys.exit(1)
    # --- elapsed start--------------------------------------------------------
    start = time.perf_counter()
    # --- startup process -----------------------------------------------------
    message_start(get_caller_name())
    # --- processing block ----------------------------------------------------
    arg_manager = Argument()
    #   arg_manager.add('--add', type=str, help='add args')
    arg_manager.add("--md", help="Generate markdown sheet", default="", type=str)
    args = arg_manager.parse()
    if args:
        info_conf, info_dist, info_mdia = initialize()
        generate_ipxe_menu(info_conf, info_dist, info_mdia)
    # --- termination process -------------------------------------------------
    message_end(get_caller_name())
    # --- elapsed end ---------------------------------------------------------
    end = time.perf_counter()
    elapsed = end - start
    message_elapsed(get_caller_name(), elapsed)
    # --- exit ----------------------------------------------------------------
    sys.exit(0)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    main()

# --- eof ---------------------------------------------------------------------
