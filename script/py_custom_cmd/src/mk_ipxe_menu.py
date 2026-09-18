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
from common.shared.my_distribution_dat import (
    sort_distribution_data,
    sort_distribution_name,
)
from common.shared.my_shared import InfoCommon
from common.utils.my_argument import Argument
from common.utils.my_colors import Color
from common.utils.my_config import infosystem
from common.utils.my_debug import debug_logger
from common.utils.my_error import handle_fatal_error
from common.utils.my_file_api import file_read, file_write
from common.utils.my_message import (
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
    if infosystem.debug:
        message_info(get_caller_name(), "Debug mode on")
    if infosystem.debugout:
        message_info(get_caller_name(), "Debugout mode on")
    message_info(get_caller_name(), f"exec user:{infosystem.data.exec_user}")
    message_info(get_caller_name(), f"home dir :{infosystem.data.home_dir}")
    return InfoCommon()


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "template file\n"
    arg_manager = Argument(description)
    # 必要に応じて引数を追加
    infosystem.args = arg_manager.parse()


def generate_ipxe_menu_file(
    info_comm: InfoCommon, path_src: Path, path_dest: Path, target_distribution: str
) -> None:
    # 1. 検索クエリの決定
    if target_distribution == "windows":
        query_version = r"(windows-|winpe-|ati[0-9]{4}|memtest86plus-)"
    elif target_distribution == "live":
        print("skip: live mode")
        return
    elif target_distribution == "custom_live":
        print("skip: custom live mode")
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
        message_info(caller, f"Destination: {path_dest}")
        message_info(caller, f"Target Dist: {target_distribution}")

        generate_ipxe_menu_file(info_comm, path_src, path_dest, target_distribution)


@debug_logger
def main():
    """Main"""
    caller = get_caller_name()
    try:
        if os.geteuid() != 0:
            message_warn(caller, "You have standard user privileges.")
            message_warn(caller, f"{Color.underline}Please run this with sudo.")
            return 1

        start = time.perf_counter()
        message_start(caller)

        initarg()
        if infosystem.args:
            info_comm = initialize()
            generate_ipxe_menu(info_comm)

        message_end(caller)
        elapsed = time.perf_counter() - start
        message_elapsed(caller, elapsed)
        return 0
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


if __name__ == "__main__":
    sys.exit(main())
