#!/usr/bin/env python3
import re
from pathlib import Path

# --- 設定項目 ---
SRC_DIR = Path("/srv/user/private/src/git/linux/script/py_custom_cmd/src")
UTILS_INIT = SRC_DIR / "common" / "utils" / "__init__.py"
SHARED_INIT = SRC_DIR / "common" / "shared" / "__init__.py"

TEMPLATE_FILE = Path("Makefile.tmpl")
OUTPUT_FILE = Path("Makefile")


def load_module_map(init_path: Path):
    """__init__.py から _MODULE_MAP の中身をパースして辞書を作成する"""
    if not init_path.exists():
        print(f"⚠️ 警告: ファイルが見つかりません: {init_path}")
        return {}

    content = init_path.read_text(encoding="utf-8")
    match = re.search(r"_MODULE_MAP\s*=\s*\{(.*?)\}", content, re.DOTALL)
    if not match:
        return {}

    module_map = {}
    for line in match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = re.findall(r'["\']([^"\']+)["\']', line)
        if len(parts) >= 2:
            module_map[parts[0]] = parts[1]
    return module_map


def parse_actual_imports(script_path: Path) -> dict:
    """
    対象スクリプトの import 文を解析し、
    common.utils と common.shared から実際にインポートされている名前のセットを返す
    """
    imported_names = {"utils": set(), "shared": set()}
    if not script_path.exists():
        return imported_names

    content = script_path.read_text(encoding="utf-8")

    # 1. 複数行にわたる from common.xxx import ( ... ) のパース
    multiline_pattern = re.compile(
        r"from\s+common\.(utils|shared)\s+import\s*\((.*?)\)", re.DOTALL
    )
    for match in multiline_pattern.finditer(content):
        pkg_type = match.group(1)
        body = match.group(2)
        for line in body.splitlines():
            line = re.sub(r"#.*", "", line).strip().replace(",", "").replace(")", "").replace("(", "")
            if line:
                imported_names[pkg_type].add(line)

    # 2. 単一行の from common.xxx import a, b, c のパース (括弧がないパターン)
    singleline_pattern = re.compile(
        r"from\s+common\.(utils|shared)(?:\.[a-zA-Z0-9_]+)?\s+import\s+([^\n]+)"
    )
    for match in singleline_pattern.finditer(content):
        pkg_type = match.group(1)
        body = match.group(2).strip()
        if not body.startswith("("):
            body = re.sub(r"#.*", "", body).strip()
            names = [n.strip() for n in body.replace(",", " ").split() if n.strip()]
            for name in names:
                imported_names[pkg_type].add(name)

    return imported_names


def resolve_dependencies_recursive(script_path: Path, utils_map: dict, shared_map: dict, found_modules: set):
    """
    スクリプトの import 文を解析し、さらにそのインポート先ファイルも再帰的に読み込んで
    芋づる式にすべての隠れた自作依存モジュールを網羅する
    """
    actual_imports = parse_actual_imports(script_path)
    new_modules = set()

    # 1. utils の照合
    for name in actual_imports["utils"]:
        if name in utils_map:
            sub_mod = utils_map[name].lstrip(".")
            new_modules.add(f"common.utils.{sub_mod}")

    # 2. shared の照合
    for name in actual_imports["shared"]:
        if name in shared_map:
            sub_mod = shared_map[name]
            if sub_mod.startswith("..utils."):
                mod_name = sub_mod.replace("..utils.", "utils.")
            else:
                mod_name = f"shared.{sub_mod.lstrip('.')}"
            new_modules.add(f"common.{mod_name}")

    # 3. 直接モジュールファイルごとインポートしているケース
    if script_path.exists():
        content = script_path.read_text(encoding="utf-8")
        direct_mod_pattern = re.compile(r"from\s+common\.((?:utils|shared)\.[a-zA-Z0-9_]+)\s+import")
        for match in direct_mod_pattern.finditer(content):
            new_modules.add(f"common.{match.group(1)}")

    # 新しく見つかったモジュールに対して、さらに再帰的にそのファイルの中身を調査
    for mod in new_modules:
        if mod not in found_modules:
            found_modules.add(mod)
            # フルパスの解決 (例: common.utils.my_config -> SRC_DIR / common / utils / my_config.py)
            rel_path = mod.replace(".", "/") + ".py"
            next_script_path = SRC_DIR / rel_path
            resolve_dependencies_recursive(next_script_path, utils_map, shared_map, found_modules)


def analyze_script(script_path: Path, utils_map: dict, shared_map: dict):
    """再帰スキャンを開始し、ソートされた hidden-import リストを返す"""
    hidden_imports = set()
    resolve_dependencies_recursive(script_path, utils_map, shared_map, hidden_imports)
    return sorted(list(hidden_imports))


def generate_target_block(target_name: str, imports: list):
    """特定のターゲット向けのマクロ定義テキストを生成する"""
    lines = []
    lines.append(f"# --- {target_name}.py --------------------------------------")

    # 💡 修正箇所1: インポートがない場合は末尾に「\」を付けず、綺麗に空文字にする
    if not imports:
        lines.append(f"{target_name:<40} :   IMPORT_PKGS     =")
    else:
        lines.append(f"{target_name:<40} :   IMPORT_PKGS     = \\")
        for imp in imports[:-1]:
            lines.append(f"{'':<48}--hidden-import=\"{imp}\" \\")
        lines.append(f"{'':<48}--hidden-import=\"{imports[-1]}\"")

    lines.append(rf"{target_name:<40} :   EXCLUDE_PKGS    = $(EXCLUDE_CUI)")
    lines.append("")
    return "\n".join(lines)


def main():
    if not TEMPLATE_FILE.exists():
        print(f"❌ エラー: テンプレートファイル {TEMPLATE_FILE} が存在しません。")
        return

    tmpl_text = TEMPLATE_FILE.read_text(encoding="utf-8")
    script_match = re.search(
        r"TARGET_SCRIPT\s*=\s*(.*?)(?=\n[A-Z_]+\s*=|\n\n|\Z)",
        tmpl_text,
        re.DOTALL,
    )

    if not script_match:
        print("❌ エラー: テンプレートから TARGET_SCRIPT を抽出できませんでした。")
        return

    target_scripts = [
        s.strip().replace("\\", "")
        for s in script_match.group(1).splitlines()
        if s.strip()
    ]

    utils_map = load_module_map(UTILS_INIT)
    shared_map = load_module_map(SHARED_INIT)

    generated_blocks = []
    for script_name in target_scripts:
        script_path = Path(script_name)
        target_name = script_path.stem

        if not script_path.exists():
            block = generate_target_block(target_name, [])
        else:
            imports = analyze_script(script_path, utils_map, shared_map)
            block = generate_target_block(target_name, imports)

        generated_blocks.append(block)

    configs_string = "\n".join(generated_blocks)
    final_makefile_content = tmpl_text.replace(
        "@TARGET_SPECIFIC_CONFIGS@", configs_string
    )

    OUTPUT_FILE.write_text(final_makefile_content, encoding="utf-8")
    print("✨ 各スクリプトの実際の import 文と共通モジュールの内部依存を再帰解析し、'Makefile' を更新しました。")


if __name__ == "__main__":
    main()
