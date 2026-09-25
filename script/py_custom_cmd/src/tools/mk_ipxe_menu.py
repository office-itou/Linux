#!/usr/bin/env python3

"""Make IPXE menu"""

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
from my_distribution_dat import (
    sort_distribution_data,
    sort_distribution_name,
)
from my_shared import InfoCommon
from my_argument import Argument
from my_colors import Color
from my_config import infosystem
from my_debug import debug_logger
from my_error import handle_fatal_error
from my_file_api import file_read, file_write
from my_mem_usage import print_peak_memory
from my_message import (
    get_caller_name,
    message_elapsed,
    message_end,
    message_info,
    message_start,
    message_warn,
)

# 各ライフサイクルの表示名マッピング
LIFE_LABELS = {
    "TBA": "To Be Announced",
    "DEV": "Development",
    "CURRENT": "Current (supported)",
    "LTS": "Long Term Support",
    "ELTS": "Extended LTS",
    "ESM": "Expanded Security Maintenance",
    "EOL": "End of life (unsupported)",
}


@debug_logger
def initialize():
    """Initialize"""
    caller = get_caller_name()
    if infosystem.debug == True:
        message_info(caller, "Debug mode on")
    if infosystem.debugout == True:
        message_info(caller, "Debugout mode on")
    message_info(caller, f"exec user:{infosystem.data.exec_user}")
    message_info(caller, f"home dir :{infosystem.data.home_dir}")
    # -------------------------------------------------------------------------
    return InfoCommon()


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "Make IPXE menu file\n"
    arg_manager = Argument(description)
    list_args = []
    if list_args:
        for line_arg in list_args:
            arg_name = line_arg.pop("arg")
            if isinstance(arg_name, tuple):
                arg_manager.add(*arg_name, **line_arg)
            else:
                arg_manager.add(arg_name, **line_arg)

    infosystem.args = arg_manager.parse()


def generate_ipxe_menu_file(
    info_comm: InfoCommon, path_src: Path, path_dest: Path, target_distribution: str
) -> None:
    # 1. 検索クエリの決定
    if target_distribution == "windows":
        query_version = r"(windows-|winpe-|ati[0-9]{4}|memtest86plus-)"
    elif target_distribution == "live":
        # print("skip: live mode")
        return
    elif target_distribution == "custom_live":
        # print("skip: custom live mode")
        return
    else:
        query_version = rf"{target_distribution}-"

    find_results = info_comm.dist.finds(version=query_version, life="^(?!.*EOL).*$")
    sort_results = sort_distribution_data(find_results, "", reverse=True)

    # 2. テンプレート内の共通設定値置換 (:_KEY_:)
    pattern = r":_([A-Z0-9_]+)_:"
    match_compiled = re.compile(pattern)
    read_data = file_read(path_src)
    conv_dist = match_compiled.sub(
        lambda m: str(info_comm.conf.find(key=m.group(1)).value), read_data
    )

    item_width = 47
    item_data = []

    # 3. プレースホルダーの事前生成（二重ループの解消）
    # ライフサイクルごとにアイテムリストをグルーピング (O(N) で処理)
    items_by_life = defaultdict(list)
    goto_selection_lines = []
    goto_target_lines = []
    code_selection_lines = []

    for data_dist in sort_results:
        # 空白や特殊文字を安全にアンダースコアに変換
        goto_name = re.sub(r"\s+", "_", f"{data_dist.name}-{data_dist.version_id}")

        # --- <items> 用のデータ生成 ---
        item_text = f"{f'item -- {goto_name}':<{item_width}} - {data_dist.name} ${{edition}} {data_dist.version_id}"
        if data_dist.code_name:
            item_text += f" ({data_dist.code_name})"

        life_key = data_dist.life if data_dist.life else "CURRENT"
        items_by_life[life_key].append(item_text)

        # --- 各種プレースホルダー用のデータ生成 ---
        goto_selection_lines.append(
            f"{f'iseq ${{selected}} {goto_name}':<{item_width}} && goto {data_dist.name}-{data_dist.version_id} ||"
        )
        goto_target_lines.append(f":{goto_name}")
        code_selection_lines.append(
            f"{f'iseq ${{selected}} {goto_name}':<{item_width}} && set vers {data_dist.version_id} ||"
        )

    # 4. 行単位の置換処理
    for read_line in conv_dist.splitlines():
        stripped = read_line.strip()

        # 完全一致、または前後の空白を除いた行頭チェックで誤判定を防ぐ
        if stripped.startswith("# <items>"):
            for life in LIFE_LABELS:
                if life in items_by_life:
                    gap_label = LIFE_LABELS.get(life, "Unknown")
                    # 必要に応じて元のハイフン数 'item -- --gap --' に戻してください
                    gap_text = f"{'item --gap --':<{item_width}} [ {gap_label} ]"
                    item_data.append(gap_text)
                    item_data.extend(items_by_life[life])

        elif stripped.startswith("# <goto selection>"):
            item_data.extend(goto_selection_lines)

        elif stripped.startswith("# <goto target>"):
            item_data.extend(goto_target_lines)

        elif stripped.startswith("# <code selection>"):
            item_data.extend(code_selection_lines)

        else:
            item_data.append(read_line)

    # 5. 書き込み
    write_data = "\n".join(item_data) + "\n"
    file_write(path_dest, write_data, text=True, backup=True)


@debug_logger
def generate_ipxe_menu(info_comm: InfoCommon) -> None:
    caller = get_caller_name()
    path_autexec = Path(str(info_comm.conf.find(key="PATH_IPXE").value))
    path_ipxe_dir = path_autexec.parent
    path_tplt_ipxe_dir = Path(str(info_comm.conf.find(key="DIRS_TMPL").value)) / "ipxe"
    list_tplt_files = sort_distribution_name(
        [file for file in path_tplt_ipxe_dir.glob("*.ipxe") if file.is_file()]
    )

    distribution_pattern = re.compile(r"^[^_]+_([^.]+)\.ipxe")
    for path_src in list_tplt_files:
        if path_src.name == path_autexec.name:
            path_dest = path_ipxe_dir / path_src.name
        else:
            path_dest = path_ipxe_dir / "menu" / path_src.name

        match = distribution_pattern.match(path_src.name)
        if not match:
            message_warn(caller, f"Skipped invalid template filename: {path_src.name}")
            continue

        target_distribution = match.group(1)
        # message_info(caller, f"Destination: {path_dest}")
        message_info(caller, f"Target Dist: {target_distribution}")

        generate_ipxe_menu_file(info_comm, path_src, path_dest, target_distribution)


@debug_logger
def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- check the executing user ----------------------------------------
        if os.geteuid() != 0:
            print(
                f"{Color.reset}{Color.br_green}{infosystem.program_name}:\n"
                f"{Color.br_yellow} You have standard user privileges. "
                f"{Color.underline}Please run this with sudo.{Color.reset}"
            )
            return 1
        # --- elapsed start----------------------------------------------------
        start = time.perf_counter()
        # --- startup process -------------------------------------------------
        message_start(caller)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            info_comm = initialize()
            generate_ipxe_menu(info_comm)
        # --- termination process ---------------------------------------------
        message_end(caller)
        # --- elapsed end -----------------------------------------------------
        end = time.perf_counter()
        elapsed = end - start
        message_elapsed(caller, elapsed)
        # --- exit ------------------------------------------------------------
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)
    # -------------------------------------------------------------------------


if __name__ == "__main__":
    return_code = main()
    sys.exit(print_peak_memory() or return_code)

# --- eof ---------------------------------------------------------------------
