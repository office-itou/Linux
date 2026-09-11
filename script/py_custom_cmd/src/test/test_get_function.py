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
def build_perfect_tree_with_docs(file_name: str, list_data_str: str) -> list[str]:
    # 1. 基本的な定義行を分解する正規表現
    func_pattern = re.compile(
        r"^(\s*)(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([^\s:]+))?\s*:"
        r"|"
        r"^(\s*)class\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:"
    )

    # 2. docstring内の各項目を抜き出すための正規表現
    doc_summary_pattern = re.compile(r"^\s*\"\"\"([\s\S]*?)(?:Args:|Returns:|\"\"\")")
    doc_args_pattern = re.compile(
        r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\([^)]*\))?\s*:\s*(.*)$"
    )
    doc_returns_pattern = re.compile(
        r"^\s*Returns:\s*(?:\n\s*)?([^\n]+(?:\n\s+[^\n]+)*)"
    )

    lines = list_data_str.splitlines()
    num_lines = len(lines)
    raw_nodes = []

    # --- 【フェーズ1】パース処理とdocstring（説明文）の解析 ---
    for i, line in enumerate(lines):
        stripped_line = line.rstrip()
        content = stripped_line.lstrip()
        if not content:
            continue

        if match := func_pattern.match(stripped_line):
            (
                func_spcs,
                func_name,
                func_args,
                func_return,
                class_spcs,
                class_name,
                class_bases,
            ) = match.groups()

            is_class = bool(class_name)
            name = (
                f"{Color.br_cyan}{class_name}{Color.cyan}"
                if is_class
                else f"{Color.br_green}{func_name}(){Color.green}"
            )
            indent_level = len(class_spcs if is_class else func_spcs) // 4
            node_type = "class" if is_class else "func"

            raw_args = func_args.strip() if func_name else ""
            return_type = func_return if func_name else None

            # docstringの先読み解析
            summary_text = ""
            args_docs = {}
            returns_doc = ""

            next_idx = i + 1
            if next_idx < num_lines and '"""' in lines[next_idx]:
                doc_lines = []
                while next_idx < num_lines:
                    doc_lines.append(lines[next_idx])
                    if lines[next_idx].strip().endswith('"""') and len(doc_lines) > 1:
                        break
                    next_idx += 1

                doc_block = "\n".join(doc_lines)

                if sum_match := doc_summary_pattern.search(doc_block):
                    summary_text = sum_match.group(1).strip().split("\n")[0]

                if "Args:" in doc_block:
                    for d_line in doc_lines:
                        if arg_match := doc_args_pattern.match(d_line.strip()):
                            args_docs[arg_match.group(1)] = arg_match.group(2).strip()

                if ret_match := doc_returns_pattern.search(doc_block):
                    returns_doc = ret_match.group(1).strip().split("\n")[0]

            # --- 【修正】ツリー用の詳細項目（details）を組み立てる ---
            details = []
            if is_class:
                if class_bases:
                    details.append(f"base: {class_bases}")
            else:
                # 💡 引数をカンマで分割して、1つずつ縦に並べる
                if raw_args:
                    # 改行を消して1行にしてから分割
                    clean_args_line = raw_args.replace("\n", " ").strip()
                    # 引数ごとに分ける (例: ['self', 'queries: list[...]'])
                    arg_items = [
                        a.strip() for a in clean_args_line.split(",") if a.strip()
                    ]

                    for arg in arg_items:
                        # self は説明がないのでそのままスキップ、または単体で出す
                        if arg == "self":
                            details.append(
                                f"{Color.white}arg : {Color.br_yellow}self{Color.reset}"
                            )
                            continue

                        # 型ヒントを除いた純粋な変数名を取得
                        arg_pure_name = arg.split(":")[0].strip()
                        if arg_pure_name in args_docs:
                            details.append(
                                f"{Color.white}arg : [{Color.br_yellow}{arg} {Color.br_white}[{Color.yellow}{args_docs[arg_pure_name]}{Color.br_white}]{Color.white}]{Color.reset}"
                            )
                        else:
                            details.append(
                                f"{Color.white}arg : [{Color.br_yellow}{arg}{Color.white}]{Color.reset}"
                            )

                # 戻り値
                if return_type:
                    ret_msg = f"{Color.white}ret : [{Color.br_yellow}{return_type}{Color.white}]{Color.reset}"
                    if returns_doc:
                        ret_msg += f"{Color.white} [{Color.yellow}{returns_doc}{Color.white}]{Color.reset}"
                    details.append(ret_msg)

            raw_nodes.append(
                {
                    "type": node_type,
                    "name": name,
                    "level": indent_level,
                    "details": details,
                    "summary": summary_text,
                }
            )

    # --- 【フェーズ2】ツリー描画処理 ---
    pick_data = [f"{Color.br_magenta}{file_name}{Color.white}:{Color.reset}"]
    num_nodes = len(raw_nodes)

    for i, node in enumerate(raw_nodes):
        level = node["level"]

        # 縦棒（|）の引き継ぎ計算
        active_layers = [
            any(raw_nodes[j]["level"] == l for j in range(i + 1, num_nodes))
            for l in range(level)
        ]
        indent_text = "".join("|   " if active else "    " for active in active_layers)

        has_next_sibling = any(
            raw_nodes[j]["level"] == level for j in range(i + 1, num_nodes)
        )
        branch = "+-- " if has_next_sibling else "`-- "

        summary_suffix = f" # {node['summary']}" if node["summary"] else ""
        pick_data.append(
            f"{Color.white}{indent_text}{branch}{Color.br_blue}{node['type']}{Color.white}: {node['name']}{summary_suffix}{Color.reset}"
        )

        # 各詳細項目（縦並びになった引数・戻り値）を出力
        num_details = len(node["details"])
        for d_idx, detail in enumerate(node["details"]):
            d_branch = "`-- " if d_idx == num_details - 1 else "+-- "
            child_prefix = "|   " if has_next_sibling else "    "
            pick_data.append(
                f"{Color.white}{indent_text}{child_prefix}{d_branch}{Color.reset}{detail}{Color.reset}"
            )

    return pick_data


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
        result_tree = build_perfect_tree_with_docs(path_file.stem, list_data)
        for tree_line in result_tree:
            print(tree_line)
        print(f"{Color.green}{'-' * 80}{Color.reset}")
        # break
    print(f"{Color.green}{'*' * 80}{Color.reset}")


def main():
    function()


if __name__ == "__main__":
    sys.exit(main())
