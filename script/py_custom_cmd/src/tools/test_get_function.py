#!/usr/bin/env python3
"""Test function"""

# --- Python library ----------------------------------------------------------
import os
import re
import sys
import time
from pathlib import Path
from typing import Literal, TypedDict

# --- my library --------------------------------------------------------------
execusr = os.getenv("SUDO_USER", os.getenv("USER"))
homedir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{execusr}"
libsdir = Path(homedir) / "linux/script/py_custom_cmd/src"
if str(libsdir) not in sys.path:
    sys.path.append(str(libsdir))
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
    message_start,
)


# =============================================================================
# --- 1. カラーテーマの定義 ---
class TreeTheme:
    """ツリー表示の見た目を管理するクラス"""

    def __init__(self, use_color: bool = True):
        # ターミナル用のANSIカラーコード（仮のColorクラスの代わり）
        if use_color:
            self.file = Color.br_magenta
            self.node_type = Color.br_blue
            self.cls_name = Color.br_cyan
            self.cls_tag = Color.cyan
            self.func_name = Color.br_green
            self.func_tag = Color.green
            self.label = Color.white  # white
            self.value = Color.br_yellow
            self.doc = Color.yellow
            self.doc_bracket = Color.br_white
            self.reset = Color.reset
        else:
            # Markdownやプレーンテキスト用（すべて空文字）
            self.file = ""
            self.node_type = ""
            self.cls_name = ""
            self.cls_tag = ""
            self.func_name = ""
            self.func_tag = ""
            self.label = ""
            self.value = ""
            self.doc = ""
            self.doc_bracket = ""
            self.reset = ""


# --- 2. 内部データ構造の型定義 ---
class ArgInfo(TypedDict):
    raw: str  # 'self' や 'queries: list[...]' の文字列
    name: str  # 'queries' などの純粋な変数名


class NodeData(TypedDict):
    type: Literal["class", "func"]
    raw_name: str  # 色なしの純粋な名前
    level: int
    args: list[ArgInfo]
    return_type: str | None
    args_docs: dict[str, str]
    returns_doc: str
    summary: str


@debug_logger
@debug_logger
def build_perfect_tree_with_docs_phase1(
    file_name: str,
    list_data_str: str,
    output_format: Literal["terminal", "markdown"] = "terminal",
) -> list[NodeData]:
    # func_pattern = re.compile(
    #    r"^(\s*)(?:async\s+def|def)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([^\s:]+))?\s*:"
    #    r"|"
    #    r"^(\s*)(?:class)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:",
    #    re.MULTILINE | re.DOTALL,
    # )
    func_pattern = re.compile(
        # 【関数用パターン】
        # 引数末尾の ) から : までの間に -> 型宣言 が挟まっても、全体を正しくキャッチします
        r"^(\s*)(?:async\s+def|def)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([\s\S]*?))?\s*:"
        r"|"
        # 【クラス用パターン】
        r"^(\s*)(?:class)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:",
        re.MULTILINE,
    )
    # docstringブロック全体を抽出するパターン
    docstring_block_pattern = re.compile(r"^\s*\"\"\"([\s\S]*?)\"\"\"", re.MULTILINE)

    doc_summary_pattern = re.compile(r"^\s*([\s\S]*?)(?:Args:|Returns:|\"\"\"|\Z)")
    doc_args_pattern = re.compile(
        r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\([^)]*\))?\s*:\s*(.*)$"
    )
    doc_returns_pattern = re.compile(
        r"^\s*Returns:\s*(?:\n\s*)?([^\n]+(?:\n\s+[^\n]+)*)"
    )

    raw_nodes: list[NodeData] = []

    for match in func_pattern.finditer(list_data_str):
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
        indent_level = len(class_spcs if is_class else func_spcs) // 4
        node_type = "class" if is_class else "func"
        raw_name = class_name if is_class else func_name

        # 改行と余分な空白を省く最適化を適用
        raw_args = " ".join(func_args.split()) if func_name else ""
        return_type = func_return if func_name else None

        if is_class and class_bases:
            return_type = class_bases

        summary_text = ""
        args_docs = {}
        returns_doc = ""

        # 【修正ポイント】定義の終了位置（match.end()）から直後のテキストを取得してdocstringを解析
        after_definition_text = list_data_str[match.end() :]
        if doc_block_match := docstring_block_pattern.match(after_definition_text):
            doc_block = doc_block_match.group(1)
            doc_lines = doc_block.splitlines()

            # 1. 概要 (Summary) の抽出
            if sum_match := doc_summary_pattern.search(doc_block):
                summary_lines = [
                    line.strip()
                    for line in sum_match.group(1).splitlines()
                    if line.strip()
                ]
                if summary_lines:
                    summary_text = summary_lines[0]

            # 2. 引数 (Args) の抽出
            if "Args:" in doc_block:
                for d_line in doc_lines:
                    if arg_match := doc_args_pattern.match(d_line):
                        args_docs[arg_match.group(1)] = arg_match.group(2).strip()

            # 3. 戻り値 (Returns) の抽出
            if ret_match := doc_returns_pattern.search(doc_block):
                returns_doc = ret_match.group(1).strip().split("\n")[0]

        # 引数のリスト化
        # parsed_args = []
        # if raw_args:
        #    arg_items = [a.strip() for a in raw_args.split(",") if a.strip()]
        #    for arg in arg_items:
        #        arg_pure_name = arg.split(":")[0].strip()
        #        parsed_args.append({"raw": arg, "name": arg_pure_name})
        # --- [修正後] 型アノテーションのカンマに壊されない安全な分割ロジック ---
        parsed_args = []
        if raw_args:
            # 改行と連続する空白を1つの半角スペースに美しく統合
            clean_args_line = " ".join(raw_args.split())

            arg_items = []
            current_arg = []
            bracket_level = 0  # [ ] や { } の深さを数えるカウンター

            # 1文字ずつ走査して、型アノテーション内部のカンマを無視して安全に切り分ける
            for char in clean_args_line:
                if char in "[{(":
                    bracket_level += 1
                elif char in "]})":
                    bracket_level -= 1

                # 最外周（型アノテーションの括弧の外）にあるカンマに出会ったら区切る
                if char == "," and bracket_level == 0:
                    item_str = "".join(current_arg).strip()
                    if item_str:
                        arg_items.append(item_str)
                    current_arg = []
                else:
                    current_arg.append(char)

            # 最後の引数を追加
            item_str = "".join(current_arg).strip()
            if item_str:
                arg_items.append(item_str)

            # 純粋な変数名と型付きの文字列を分けて格納
            for arg in arg_items:
                arg_pure_name = arg.split(":")[0].strip()
                parsed_args.append({"raw": arg, "name": arg_pure_name})
        raw_nodes.append(
            {
                "type": node_type,
                "raw_name": raw_name,
                "level": indent_level,
                "args": parsed_args,
                "return_type": return_type,
                "args_docs": args_docs,
                "returns_doc": returns_doc,
                "summary": summary_text,
            }
        )
    return raw_nodes


@debug_logger
def build_perfect_tree_with_docs_phase2(
    file_name: str,
    raw_nodes: list[NodeData],
    output_format: Literal["terminal", "markdown"] = "terminal",
) -> list[NodeData]:
    theme = TreeTheme(use_color=(output_format == "terminal"))
    pick_data = []
    # Markdown出力の場合はコードブロックの開始タグを入れる
    if output_format == "markdown":
        pick_data.append("```text")
    pick_data.append(f"{theme.file}{file_name}{theme.label}:{theme.reset}")
    num_nodes = len(raw_nodes)
    for i, node in enumerate(raw_nodes):
        level = node["level"]
        # 縦棒の計算
        active_layers = [
            any(raw_nodes[j]["level"] == l for j in range(i + 1, num_nodes))
            for l in range(level)
        ]
        indent_text = "".join("|   " if active else "    " for active in active_layers)
        has_next_sibling = any(
            raw_nodes[j]["level"] == level for j in range(i + 1, num_nodes)
        )
        branch = "+-- " if has_next_sibling else "`-- "
        # 名前の装飾
        if node["type"] == "class":
            display_name = f"{theme.cls_name}{node['raw_name']}{theme.cls_tag}"
        else:
            display_name = f"{theme.func_name}{node['raw_name']}{theme.func_tag}()"
        summary_suffix = f" # {node['summary']}" if node["summary"] else ""
        # ノードのメイン行を追加
        pick_data.append(
            f"{theme.label}{indent_text}{branch}{theme.node_type}{node['type']}{theme.label}: {display_name}{summary_suffix}{theme.reset}"
        )
        # 詳細項目（引数・戻り値）の組み立て
        details = []
        if node["type"] == "class":
            if node["return_type"]:  # 基底クラスがある場合
                details.append(f"base: {node['return_type']}")
        else:
            # 引数の装飾
            for arg in node["args"]:
                if arg["name"] == "self":
                    details.append(f"{theme.label}arg : {theme.value}self{theme.reset}")
                    continue
                if arg["name"] in node["args_docs"]:
                    doc_str = node["args_docs"][arg["name"]]
                    details.append(
                        f"{theme.label}arg : {theme.doc_bracket}[{theme.value}{arg['raw']} {theme.doc_bracket}[{theme.doc}{doc_str}{theme.doc_bracket}]{theme.label}]{theme.reset}"
                    )
                else:
                    details.append(
                        f"{theme.label}arg : {theme.doc_bracket}[{theme.value}{arg['raw']}{theme.doc_bracket}]{theme.reset}"
                    )
            # 戻り値の装飾
            if node["return_type"]:
                ret_msg = f"{theme.label}ret : {theme.doc_bracket}[{theme.value}{node['return_type']}{theme.doc_bracket}]{theme.reset}"
                if node["returns_doc"]:
                    ret_msg += f"{theme.label} {theme.doc_bracket}[{theme.doc}{node['returns_doc']}{theme.doc_bracket}]{theme.reset}"
                details.append(ret_msg)
        # 詳細行の出力
        num_details = len(details)
        for d_idx, detail in enumerate(details):
            d_branch = "`-- " if d_idx == num_details - 1 else "+-- "
            child_prefix = "|   " if has_next_sibling else "    "
            pick_data.append(
                f"{theme.label}{indent_text}{child_prefix}{d_branch}{theme.reset}{detail}"
            )
    # Markdown出力の場合はコードブロックの閉じタグを入れる
    if output_format == "markdown":
        pick_data.append("```")
    return pick_data


@debug_logger
def build_perfect_tree_with_docs(target_files: str = ""):
    print(f"{Color.green}{'*' * 80}{Color.reset}")

    markdown_text = ""
    for path_file in target_files:
        source_code = file_read(path_file)

        # ターミナル用に出力して画面表示
        raw_nodes = build_perfect_tree_with_docs_phase1(
            path_file.stem, source_code, output_format="terminal"
        )
        lines = build_perfect_tree_with_docs_phase2(
            path_file, raw_nodes, output_format="terminal"
        )
        print("\n".join(lines) + "\n" * 2)
        print(f"{Color.green}{'-' * 80}{Color.reset}")

        # Markdownオプションが指定されている場合のみ、データを蓄積する
        if hasattr(infosystem.args, "markdown") and infosystem.args.markdown:
            raw_nodes = build_perfect_tree_with_docs_phase1(
                path_file.stem, source_code, output_format="markdown"
            )
            lines_mkdn = build_perfect_tree_with_docs_phase2(
                path_file, raw_nodes, output_format="markdown"
            )
            tree_content = "\n".join(lines_mkdn)

            # <details> タグで囲む構造を作成（空行を適切に挟むのがMarkdownのコツです）
            folded_block = (
                f"<details>\n"
                f"<summary>📦 <b>{path_file.name}</b> の構造ツリーを表示</summary>\n\n"
                f"{tree_content}\n\n"
                f"</details>\n"
            )
            markdown_text += folded_block + "\n"

    # Markdownファイルへの書き込み（オプション指定時のみ実行）
    if (
        hasattr(infosystem.args, "markdown")
        and infosystem.args.markdown
        and markdown_text
    ):
        file_mkdn = Path(infosystem.args.markdown)
        file_write(file_mkdn, markdown_text)
        print(f"Markdownファイルを保存しました: {file_mkdn}")

    print(f"{Color.green}{'*' * 80}{Color.reset}")


@debug_logger
def initarg() -> None:
    """Initialize argument"""
    description = "Pythonソースコードの構造を美しいツリー形式で出力します。\n"
    arg_manager = Argument(description)
    list_args = [
        {
            "arg": "target_path",
            "type": "str",
            "help": "検索対象のファイルパス、またはディレクトリパスを指定します。",
        },
        {
            "arg": ("-p", "--pattern"),
            "type": "str",
            "default": "*.py",
            "help": "ディレクトリを検索する場合のファイル名パターン (例: 'my_*.py') デフォルト: '*.py'",
        },
        {
            "arg": ("-r", "--recursive"),
            "action": "store_true",
            "help": "ディレクトリを指定した場合に、サブディレクトリも含めて再帰的に検索します。",
        },
        {
            "arg": ("-m", "--markdown"),
            "type": "str",
            "default": None,
            "help": "指定した場合、ツリー構造をMarkdownファイルとして出力します (例: 'README.md')。",
        },
    ]
    for line_arg in list_args:
        arg_name = line_arg.pop("arg")
        if isinstance(arg_name, tuple):
            arg_manager.add(*arg_name, **line_arg)
        else:
            arg_manager.add(arg_name, **line_arg)

    infosystem.args = arg_manager.parse()


@debug_logger
def initialize() -> (list[str], str):
    """Initialize"""
    target = Path(infosystem.args.target_path)
    if not target.exists():
        print(f"エラー: 指定されたパスが存在しません: {target}")
        return
    target_files = []
    IGNORE_NAMES = {"__init__.py", "__main__.py"}
    if target.is_file():
        if target.name not in IGNORE_NAMES:
            target_files.append(target)
    elif target.is_dir():
        search_iter = (
            target.rglob(infosystem.args.pattern)
            if infosystem.args.recursive
            else target.glob(infosystem.args.pattern)
        )
        for path_file in search_iter:
            if not path_file.is_file():
                continue
            if path_file.name in IGNORE_NAMES or any(
                part in IGNORE_NAMES for part in path_file.parts
            ):
                continue
            target_files.append(path_file)
    return target_files


@debug_logger
def main():
    """Main"""
    caller = get_caller_name()
    try:
        # --- elapsed start----------------------------------------------------
        start = time.perf_counter()
        # --- startup process -------------------------------------------------
        caller = get_caller_name()
        message_start(caller)
        # --- processing block ------------------------------------------------
        initarg()
        if infosystem.args:
            target_files = initialize()
            build_perfect_tree_with_docs(target_files)
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
    sys.exit(main())
# --- eof ---------------------------------------------------------------------
