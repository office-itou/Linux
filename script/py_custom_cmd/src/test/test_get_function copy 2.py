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
def build_perfect_tree(file_name: str, list_data: str) -> list[str]:
    # 1: func_spcs, 2: func_name, 3: func_args, 4: func_return
    # 5: class_spcs, 6: class_name, 7: class_bases
    func_pattern = re.compile(
        r"^(\s*)(?:async\s+)?def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\(([\s\S]*?)\)\s*(?:->\s*([^\s:]+))?\s*:"
        r"|"
        r"^(\s*)class\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(?:\(([\s\S]*?)\))?\s*:"
    )
    # -------------------------------------------------------------------------
    raw_nodes = []
    for line in list_data.splitlines():
        if not (match := func_pattern.match(line)):
            continue

        (
            func_spcs,
            func_name,
            func_args,
            func_return,
            class_spcs,
            class_name,
            class_bases,
        ) = match.groups()
        # ---------------------------------------------------------------------
        if class_name:
            node_type = "class"
            name = f"{Color.br_cyan}{class_name}{Color.reset}"
            indent_level = len(class_spcs) // 4
            details = [f"({class_bases})"] if class_bases else []
        elif func_name:
            node_type = "func"
            name = f"{Color.br_yellow}{func_name}{Color.reset}"
            indent_level = len(func_spcs) // 4
            details = []
            args_str = func_args.strip()
            return_type = func_return
            # -----------------------------------------------------------------
            if args_str:
                clean_args = args_str.replace("\n", " ").strip()
                details.append(
                    f"{Color.white}arg{Color.reset}: {Color.magenta}{clean_args}{Color.reset}"
                )
            if return_type:
                details.append(
                    f"{Color.white}ret{Color.reset}: {Color.magenta}{return_type}{Color.reset}"
                )
        # ---------------------------------------------------------------------
        raw_nodes.append(
            {
                "type": node_type,
                "name": name,
                "level": indent_level,
                "details": details,
            }
        )
    # -------------------------------------------------------------------------
    pick_data = [f"{Color.br_green}{file_name}{Color.reset}:"]
    num_nodes = len(raw_nodes)
    for i, node in enumerate(raw_nodes):
        level = node["level"]
        # ---------------------------------------------------------------------
        active_layers = []
        for l in range(level):
            has_future_sibling = any(
                raw_nodes[j]["level"] == l for j in range(i + 1, num_nodes)
            )
            active_layers.append(has_future_sibling)
        # ---------------------------------------------------------------------
        indent_text = "".join("|   " if active else "    " for active in active_layers)
        # ---------------------------------------------------------------------
        has_next_sibling = any(
            raw_nodes[j]["level"] == level for j in range(i + 1, num_nodes)
        )
        branch = "+-- " if has_next_sibling else "`-- "
        # ---------------------------------------------------------------------
        pick_data.append(
            f"{Color.white}{indent_text}{branch}{Color.reset}{Color.white}{node['type']}{Color.reset}: {node['name']}"
        )
        # ---------------------------------------------------------------------
        num_details = len(node["details"])
        for d_idx, detail in enumerate(node["details"]):
            is_last_detail = d_idx == num_details - 1
            d_branch = "`-- " if is_last_detail else "+-- "
            # -----------------------------------------------------------------
            child_prefix = "|   " if has_next_sibling else "    "
            # -----------------------------------------------------------------
            pick_data.append(
                f"{Color.white}{indent_text}{child_prefix}{d_branch}{Color.reset}{detail}"
            )
    # -------------------------------------------------------------------------
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
        result_tree = build_perfect_tree(path_file.stem, list_data)
        for tree_line in result_tree:
            print(tree_line)
        print(f"{Color.green}{'-' * 80}{Color.reset}")
        # break
    print(f"{Color.green}{'*' * 80}{Color.reset}")


def main():
    function()


if __name__ == "__main__":
    sys.exit(main())
