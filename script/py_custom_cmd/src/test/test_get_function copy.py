#!/usr/bin/env python3

# --- Python library ----------------------------------------------------------
import os
import re
import sys
from pathlib import Path

# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
path_outp = Path("./Readme_function.md").resolve()
dirs_libs = Path("./").resolve()
from common.utils.my_colors import Color
from common.utils.my_fileio import file_read, file_write


# -----------------------------------------------------------------------------
def build_perfect_tree(file_name: str, list_data_str: str) -> list[str]:
    func_pattern = re.compile(
        r"^\s*(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([^\s:]+))?\s*:"
        r"|"
        r"^\s*class\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:"
    )
    # -------------------------------------------------------------------------
    raw_nodes = []
    for line in list_data_str.splitlines():
        stripped_line = line.rstrip()
        content = stripped_line.lstrip()
        if not content:
            continue
        # ---------------------------------------------------------------------
        # インデントレベルの計算（4スペース＝1レベル）
        indent_level = (len(stripped_line) - len(content)) // 4
        # ---------------------------------------------------------------------
        if match := func_pattern.match(stripped_line):
            is_class = "class" in stripped_line
            if is_class:
                node_type = "class"
                name = match.group(4)
                details = [f"({match.group(5)})"] if match.group(5) else []
            else:
                node_type = "func"
                name = match.group(1)
                # -------------------------------------------------------------
                details = []
                args_str = match.group(2).strip()
                return_type = match.group(3)
                # -------------------------------------------------------------
                if args_str:
                    clean_args = args_str.replace("\n", " ").strip()
                    details.append(f"arg: {clean_args}")
                if return_type:
                    details.append(f"ret: {return_type}")
            # -----------------------------------------------------------------
            raw_nodes.append(
                {
                    "type": node_type,
                    "name": name,
                    "level": indent_level,
                    "details": details,
                }
            )
    # -------------------------------------------------------------------------
    pick_data = [f"{file_name}:"]  # ルート（ファイル名）
    # -------------------------------------------------------------------------
    num_nodes = len(raw_nodes)
    for i, node in enumerate(raw_nodes):
        # 同じ階層レベル（またはそれより浅いレベル）に、この後まだ後続のノードがあるかチェック
        # これによって、縦棒「|」を引くべきか、それとも最後の枝「`」にするかを決定します
        has_next_sibling = any(
            raw_nodes[j]["level"] <= node["level"] for j in range(i + 1, num_nodes)
        )
        #  --------------------------------------------------------------------
        # 枝の記号を決定
        branch = "+-- " if has_next_sibling else "`-- "
        # ---------------------------------------------------------------------
        # クラスや関数の見出し行を作成
        line_text = f"{branch}{node['type']}: {node['name']}"
        pick_data.append(line_text)
        # ---------------------------------------------------------------------
        # 引数や戻り値（details）がある場合、さらにその下の階層へ繋ぐ
        num_details = len(node["details"])
        for d_idx, detail in enumerate(node["details"]):
            # 引数・戻り値の最後の要素かどうか
            is_last_detail = d_idx == num_details - 1
            d_branch = "`-- " if is_last_detail else "+-- "
            # ---------------------------------------------------------------------
            # 親ノードの縦棒を引き継ぐかどうかのプレフィックスを計算
            # ※今回は提示いただいたイメージ通り、関数の1つ奥（4スペース）に綺麗にネストさせます
            prefix = "|   " if has_next_sibling else "    "
            # ---------------------------------------------------------------------
            pick_data.append(f"{prefix}{d_branch}{detail}")
    # -------------------------------------------------------------------------
    return pick_data


# Arg
# Ret


# -----------------------------------------------------------------------------
def function():
    IGNORE_NAMES = {"__init__.py", "__main__.py"}
    print(f"{Color.green}{'*' * 80}{Color.reset}")
    for path_file in dirs_libs.rglob("my_*.py"):
        if not path_file.is_file():
            continue
        if path_file.name in IGNORE_NAMES or any(
            part in IGNORE_NAMES for part in path_file.parts
        ):
            continue
        list_data = file_read(path_file)
        result_tree = build_perfect_tree(path_file.stem, list_data)
        for tree_line in result_tree:
            print(tree_line)
        print(f"{Color.green}{'-' * 80}{Color.reset}")
    print(f"{Color.green}{'*' * 80}{Color.reset}")


def main():
    function()


if __name__ == "__main__":
    sys.exit(main())
