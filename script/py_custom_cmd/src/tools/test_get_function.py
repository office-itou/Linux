#!/usr/bin/env python3

# === Python library ==========================================================
import argparse
import inspect
import os
import re
import sys
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Literal, TypedDict

import __main__

# from typing import Dict, List, Literal, Optional, TypedDict

# === my library ==============================================================


# --- escape code -------------------------------------------------------------
@dataclass
class Code:
    """Control code class"""

    escape: str = "\x1b"


# --- color code --------------------------------------------------------------
# https://qiita.com/ko1nksm/items/095bdb8f0eca6d327233
@dataclass
class Color(Code):
    """Color code class"""

    code = Code()
    reset: str = f"{code.escape}[0m"  # reset all attributes
    bold: str = f"{code.escape}[1m"  # (no comments)
    faint: str = f"{code.escape}[2m"  # (no comments)
    italic: str = f"{code.escape}[3m"  # (no comments)
    underline: str = f"{code.escape}[4m"  # set underline
    blink: str = f"{code.escape}[5m"  # (no comments)
    fast_blink: str = f"{code.escape}[6m"  # (no comments)
    reverse: str = f"{code.escape}[7m"  # set reverse display
    conceal: str = f"{code.escape}[8m"  # (no comments)
    strike: str = f"{code.escape}[9m"  # (no comments)
    gothic: str = f"{code.escape}[20m"  # (no comments)
    double_underline: str = f"{code.escape}[21m"  # (no comments)
    normal: str = f"{code.escape}[22m"  # (no comments)
    no_italic: str = f"{code.escape}[23m"  # (no comments)
    no_underline: str = f"{code.escape}[24m"  # reset underline
    no_blink: str = f"{code.escape}[25m"  # (no comments)
    no_reverse: str = f"{code.escape}[27m"  # reset reverse display
    no_conceal: str = f"{code.escape}[28m"  # (no comments)
    no_strike: str = f"{code.escape}[29m"  # (no comments)
    black: str = f"{code.escape}[30m"  # text dark black
    red: str = f"{code.escape}[31m"  # text dark red
    green: str = f"{code.escape}[32m"  # text dark green
    yellow: str = f"{code.escape}[33m"  # text dark yellow
    blue: str = f"{code.escape}[34m"  # text dark blue
    magenta: str = f"{code.escape}[35m"  # text dark purple
    cyan: str = f"{code.escape}[36m"  # text dark light blue
    white: str = f"{code.escape}[37m"  # text dark white
    default: str = f"{code.escape}[39m"  # (no comments)
    bg_black: str = f"{code.escape}[40m"  # text reverse black
    bg_red: str = f"{code.escape}[41m"  # text reverse red
    bg_green: str = f"{code.escape}[42m"  # text reverse green
    bg_yellow: str = f"{code.escape}[43m"  # text reverse yellow
    bg_blue: str = f"{code.escape}[44m"  # text reverse blue
    bg_magenta: str = f"{code.escape}[45m"  # text reverse purple
    bg_cyan: str = f"{code.escape}[46m"  # text reverse light blue
    bg_white: str = f"{code.escape}[47m"  # text reverse white
    bg_default: str = f"{code.escape}[49m"  # (no comments)
    br_black: str = f"{code.escape}[90m"  # text black
    br_red: str = f"{code.escape}[91m"  # text red
    br_green: str = f"{code.escape}[92m"  # text green
    br_yellow: str = f"{code.escape}[93m"  # text yellow
    br_blue: str = f"{code.escape}[94m"  # text blue
    br_magenta: str = f"{code.escape}[95m"  # text purple
    br_cyan: str = f"{code.escape}[96m"  # text light blue
    br_white: str = f"{code.escape}[97m"  # text white
    br_default: str = f"{code.escape}[99m"  # (no comments)


# -----------------------------------------------------------------------------
def message_alert(func_name: str, message: str):
    """Message output for alert

    Args:
        func_name (str): Function name
        message (str): Message
    """
    program_name = (
        Path(__main__.__file__).stem if hasattr(__main__, "__file__") else "interactive"
    )
    text_prog = f"{program_name}({func_name})"
    text_mesg = message
    print(f"{Color.reset}{Color.br_red}{text_prog}:\n  {text_mesg}{Color.reset}")


# -----------------------------------------------------------------------------
def handle_fatal_error(caller: str, e: Exception) -> None:
    """Fatal error handler

    Args:
        caller (str): Function name
        e (Exception): Error information

    Raises:
        SystemExit: System exit
    """
    summary = traceback.extract_tb(e.__traceback__)[-1]
    message_alert(caller, f"Fatal error: {e}")
    if isinstance(e, OSError):
        message_alert(caller, f"line number: {summary.lineno}")
    else:
        message_alert(caller, f"file name  : {summary.filename}")
        message_alert(caller, f"line number: {summary.lineno}")
    raise SystemExit from e


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


# -----------------------------------------------------------------------------
def build_perfect_tree_with_docs(
    file_name: str,
    list_data_str: str,
    output_format: Literal["terminal", "markdown"] = "terminal",
) -> list[str]:
    # フォーマットに合わせてテーマを選択
    theme = TreeTheme(use_color=(output_format == "terminal"))

    # 1. 基本的な定義行を分解する正規表現
    func_pattern = re.compile(
        r"^(\s*)(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([^\s:]+))?\s*:"
        r"|"
        r"^(\s*)class\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:"
    )

    # 2. docstring内の各項目を抜き出すための正規表現
    doc_summary_pattern = re.compile(r"^\s*\"\"\"([\s\S]*?)(?:Args:|Returns:|\"\"\")")
    doc_args_pattern = re.compile(
        r"^\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\([^)]*\))?\s*:\s*(.*)\$"
    )
    doc_returns_pattern = re.compile(
        r"^\s*Returns:\s*(?:\n\s*)?([^\n]+(?:\n\s+[^\n]+)*)"
    )

    lines = list_data_str.splitlines()
    num_lines = len(lines)
    raw_nodes: list[NodeData] = []

    # --- 【フェーズ1】パース処理と構造の抽出（ここでは色を付けない） ---
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
            indent_level = len(class_spcs if is_class else func_spcs) // 4
            node_type = "class" if is_class else "func"
            raw_name = class_name if is_class else func_name

            raw_args = func_args.strip() if func_name else ""
            return_type = func_return if func_name else None

            # クラスの基底クラスを引数のように扱うための処理
            if is_class and class_bases:
                return_type = class_bases  # クラスの場合は便宜上ここに入れる

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

            # 引数のリスト化
            parsed_args = []
            if raw_args:
                clean_args_line = raw_args.replace("\n", " ").strip()
                arg_items = [a.strip() for a in clean_args_line.split(",") if a.strip()]
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

    # --- 【フェーズ2】ツリー描画と色付け（出力処理） ---
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


def get_caller_name(only: bool = True) -> str:
    """Get function name

    Args:
        only (bool, optional): Function only or including filename. Defaults to True.

    Returns:
        str: _description_
    """
    frame = inspect.currentframe().f_back
    func_name = str(frame.f_code.co_name)
    file_name = str(Path(frame.f_code.co_filename).stem)
    # modu_name = str(frame.f_globals.get("__name__"))
    call_info = func_name if only == True else f"{file_name}({func_name})"
    return call_info


def file_read(path_src: Path, text: bool = True) -> str | bytes:
    """File read (line break codes in text files are standardized to "\n")

    Args:
        path_src (Path): Source path
        text (bool, optional): Read mode. Defaults to True.

    Raises:
        SystemExit: OSError
        SystemExit: Exception

    Returns:
        str| bytes: Result
    """
    caller = get_caller_name()
    try:
        path_src = path_src.resolve()
        mode = "r" if text else "rb"
        encoding = "utf-8" if text else None
        with open(path_src, mode=mode, encoding=encoding, newline=None) as f:
            return f.read()
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


def file_write(
    path_dest: Path,
    data: str | bytes | None = None,
    text: bool = True,
) -> None:
    """File write (line break codes in text files are standardized to "\n")

    Args:
        path_dest (Path): Destination path
        data (str | bytes | None, optional): Output data. Defaults to None.
        text (bool, optional): Write mode. Defaults to True.

    Raises:
        SystemExit: OSError
        SystemExit: Exception
    """
    caller = get_caller_name()
    try:
        path_dest = path_dest.resolve()
        mode = "w" if text else "wb"
        encoding = "utf-8" if text else None
        newline = "\n" if text else None
        if data is None:
            data = "" if text else b""
        path_dest.parent.mkdir(parents=True, exist_ok=True)
        with open(path_dest, mode=mode, encoding=encoding, newline=newline) as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        if not path_dest.exists():
            message_alert(get_caller_name(), f"failed: {path_dest}")
    except (OSError, Exception) as e:  # noqa: BLE001
        handle_fatal_error(caller, e)


# -----------------------------------------------------------------------------
def main():
    # --- 1. コマンドライン引数の設定 ---
    parser = argparse.ArgumentParser(
        description="Pythonソースコードの構造を美しいツリー形式で出力します。"
    )
    # 必須引数: 検索対象のパス（ファイル、またはディレクトリ）
    parser.add_argument(
        "target_path",
        type=str,
        help="検索対象のファイルパス、またはディレクトリパスを指定します。",
    )
    # オプション引数: ファイル名パターン（デフォルトは全てのPythonファイル）
    parser.add_argument(
        "-p",
        "--pattern",
        type=str,
        default="*.py",
        help="ディレクトリを検索する場合のファイル名パターン (例: 'my_*.py') デフォルト: '*.py'",
    )
    # フラグ引数: サブディレクトリを再帰的に検索するかどうか
    parser.add_argument(
        "-r",
        "--recursive",
        action="store_true",
        help="ディレクトリを指定した場合に、サブディレクトリも含めて再帰的に検索します。",
    )
    # オプション引数: Markdownの出力先ファイル名
    parser.add_argument(
        "-m",
        "--markdown",
        type=str,
        default=None,
        help="指定した場合、ツリー構造をMarkdownファイルとして出力します (例: 'README.md')。",
    )

    args = parser.parse_args()

    # パスオブジェクトに変換
    target = Path(args.target_path)
    if not target.exists():
        print(f"エラー: 指定されたパスが存在しません: {target}")
        return

    # --- 2. 検索対象ファイルのリストアップ ---
    target_files = []
    IGNORE_NAMES = {"__init__.py", "__main__.py"}

    if target.is_file():
        # 単一ファイルが指定された場合
        if target.name not in IGNORE_NAMES:
            target_files.append(target)
    elif target.is_dir():
        # ディレクトリが指定された場合（再帰フラグで処理を分岐）
        search_iter = (
            target.rglob(args.pattern) if args.recursive else target.glob(args.pattern)
        )
        for path_file in search_iter:
            if not path_file.is_file():
                continue
            # 無視対象のチェック（ファイル名単体、およびパスの一部に含まれるか）
            if path_file.name in IGNORE_NAMES or any(
                part in IGNORE_NAMES for part in path_file.parts
            ):
                continue
            target_files.append(path_file)

    if not target_files:
        print("条件に一致するPythonファイルが見つかりませんでした。")
        return

    # --- 3. 解析と出力処理 ---
    print(f"{Color.green}{'*' * 80}{Color.reset}")

    markdown_text = ""
    for path_file in target_files:
        source_code = file_read(path_file)

        # ターミナル用に出力して画面表示
        lines = build_perfect_tree_with_docs(
            path_file.stem, source_code, output_format="terminal"
        )
        print("\n".join(lines) + "\n" * 2)
        print(f"{Color.green}{'-' * 80}{Color.reset}")

        # Markdownオプションが指定されている場合のみ、データを蓄積する
        if args.markdown:
            lines_mkdn = build_perfect_tree_with_docs(
                path_file.stem, source_code, output_format="markdown"
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
    if args.markdown and markdown_text:
        file_mkdn = Path(args.markdown)
        file_write(file_mkdn, markdown_text)
        print(f"Markdownファイルを保存しました: {file_mkdn}")

    print(f"{Color.green}{'*' * 80}{Color.reset}")


# -----------------------------------------------------------------------------


if __name__ == "__main__":
    sys.exit(main())
