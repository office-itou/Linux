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


def check_is_gui(script_path: Path) -> bool:
    """対象スクリプトおよびインポートされるローカルファイルをスキャンしGUIアプリかを自動判定する"""
    if not script_path.exists():
        return False

    content = script_path.read_text(encoding="utf-8")
    gui_keywords = [
        r"is_gui\s*=\s*True",
        r"import\s+tkinter",
        r"from\s+tkinter",
        r"\.mainloop\(",
    ]

    for kw in gui_keywords:
        if re.search(kw, content):
            return True

    relative_from_pattern = re.compile(
        r"^from\s+\.([a-zA-Z0-9_]+)\s+import", re.MULTILINE
    )
    for match in relative_from_pattern.finditer(content):
        local_mod = match.group(1)
        local_path = script_path.parent / f"{local_mod}.py"
        if local_path.exists():
            local_content = local_path.read_text(encoding="utf-8")
            for kw in gui_keywords:
                if re.search(kw, local_content):
                    return True

    return False


def scan_required_resources(script_path: Path) -> list:
    """
    💡 修正の要: 探索の基点を作業ディレクトリ(.)から、
    対象スクリプトが存在する親ディレクトリ(script_path.parent)に変更
    """
    required_files = set()
    if not script_path.exists():
        return []
    base_dir = script_path.parent
    # 💡 ターゲットスクリプトの親フォルダにあるデータファイルのリストを取得
    available_resources = []
    for ext in ["*.json", "*.txt", "*.png"]:
        available_resources.extend([p.name for p in base_dir.glob(ext)])

    # 再帰的にソースを読み込んでリソースの言及を調べる内部関数
    def search_source(file_path: Path, scanned_paths: set):
        if not file_path.exists() or file_path in scanned_paths:
            return
        scanned_paths.add(file_path)

        src_text = file_path.read_text(encoding="utf-8")

        # コードの文字列内にファイル名が含まれているかチェック
        for res_name in available_resources:
            if re.search(rf'["\']{re.escape(res_name)}["\']', src_text):
                required_files.add(res_name)
        # カレント内の他の依存ソースも追跡対象に加える
        relative_from_pattern = re.compile(
            r"^from\s+\.([a-zA-Z0-9_]+)\s+import", re.MULTILINE
        )
        for match in relative_from_pattern.finditer(src_text):
            local_mod = match.group(1)
            next_path = file_path.parent / f"{local_mod}.py"
            search_source(next_path, scanned_paths)
        # ドット無しの通常のローカルインポート（from gui_main import ... 対策）
        direct_from_pattern = re.compile(
            r"^from\s+([a-zA-Z0-9_]+)\s+import", re.MULTILINE
        )
        for match in direct_from_pattern.finditer(src_text):
            local_mod = match.group(1)
            next_path = file_path.parent / f"{local_mod}.py"
            if next_path.exists():
                search_source(next_path, scanned_paths)

    # 探索を開始
    search_source(script_path, set())
    # PyInstaller 用の --add-data オプション形式に整形して返す
    return [f'--add-data="{f}:."' for f in sorted(list(required_files))]


def parse_actual_imports(script_path: Path) -> dict:
    """対象スクリプトの import 文を解析し、依存関係を抽出する"""
    imported_names = {"utils": set(), "shared": set(), "local": set()}
    if not script_path.exists():
        return imported_names
    content = script_path.read_text(encoding="utf-8")
    multiline_pattern = re.compile(
        r"from\s+common\.(utils|shared)\s+import\s*\((.*?)\)", re.DOTALL
    )
    for match in multiline_pattern.finditer(content):
        pkg_type = match.group(1)
        body = match.group(2)
        for line in body.splitlines():
            line = (
                re.sub(r"#.*", "", line)
                .strip()
                .replace(",", "")
                .replace(")", "")
                .replace("(", "")
            )
            if line:
                imported_names[pkg_type].add(line)
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
    relative_from_pattern = re.compile(
        r"^from\s+\.([a-zA-Z0-9_]+)\s+import", re.MULTILINE
    )
    for match in relative_from_pattern.finditer(content):
        mod_name = match.group(1)
        if (script_path.parent / f"{mod_name}.py").exists():
            imported_names["local"].add(mod_name)
    init_from_pattern = re.compile(r"^from\s+\.\s+import\s+", re.MULTILINE)
    if init_from_pattern.search(content):
        if (script_path.parent / "__init__.py").exists():
            imported_names["local"].add("__init__")
    direct_from_pattern = re.compile(r"^from\s+([a-zA-Z0-9_]+)\s+import", re.MULTILINE)
    for match in direct_from_pattern.finditer(content):
        mod_name = match.group(1)
        if mod_name != "common" and (script_path.parent / f"{mod_name}.py").exists():
            imported_names["local"].add(mod_name)
    return imported_names


def resolve_dependencies_recursive(
    script_path: Path, utils_map: dict, shared_map: dict, found_modules: set
):
    """共通モジュールおよびカレントのローカルファイルを再帰スキャン"""
    if not script_path.exists():
        return
    actual_imports = parse_actual_imports(script_path)
    new_modules = set()
    for name in actual_imports["utils"]:
        if name in utils_map:
            new_modules.add(f"common.utils.{utils_map[name].lstrip('.')}")
    for name in actual_imports["shared"]:
        if name in shared_map:
            sub_mod = shared_map[name]
            mod_name = (
                sub_mod.replace("..utils.", "utils.")
                if sub_mod.startswith("..utils.")
                else f"shared.{sub_mod.lstrip('.')}"
            )
            new_modules.add(f"common.{mod_name}")
    content = script_path.read_text(encoding="utf-8")
    direct_mod_pattern = re.compile(
        r"from\s+common\.((?:utils|shared)\.[a-zA-Z0-9_]+)\s+import"
    )
    for match in direct_mod_pattern.finditer(content):
        new_modules.add(f"common.{match.group(1)}")
    for local_mod in actual_imports["local"]:
        new_modules.add(local_mod)
    for mod in new_modules:
        if mod not in found_modules:
            found_modules.add(mod)
            next_script_path = (
                SRC_DIR / f"{mod.replace('.', '/')}.py"
                if mod.startswith("common.")
                else script_path.parent / f"{mod}.py"
            )
            resolve_dependencies_recursive(
                next_script_path, utils_map, shared_map, found_modules
            )


def analyze_script(script_path: Path, utils_map: dict, shared_map: dict):
    hidden_imports = set()
    hidden_imports.add(script_path.stem)
    resolve_dependencies_recursive(script_path, utils_map, shared_map, hidden_imports)
    return sorted(list(hidden_imports))


def generate_target_block(
    target_name: str, imports: list, data_files: list, is_gui: bool
):
    """CUI/GUIの判定および動的アセットリストを元に定義ブロックを生成する"""
    lines = []
    mode_str = "GUI Mode" if is_gui else "CUI Mode"
    lines.append(
        f"# --- {target_name}.py ({mode_str}) --------------------------------------"
    )
    if not imports:
        lines.append(f"{target_name:<40} :   IMPORT_PKGS     =")
    else:
        lines.append(f"{target_name:<40} :   IMPORT_PKGS     = \\")
        for imp in imports[:-1]:
            lines.append(f'{"":<48}--hidden-import="{imp}" \\')
        lines.append(f'{"":<48}--hidden-import="{imports[-1]}"')
    if not data_files:
        lines.append(f"{target_name:<40} :   ADD_DATA_FILE   =")
    else:
        lines.append(f"{target_name:<40} :   ADD_DATA_FILE   = \\")
        for df in data_files[:-1]:
            lines.append(f"{'':<48}{df} \\")
        lines.append(f"{'':<48}{data_files[-1]}")
    if is_gui:
        lines.append(f"{target_name:<40} :   BUILD_WINTYPE   = CFG_GUI")
        lines.append(f"{target_name:<40} :   EXCLUDE_PKGS    = $(EXCLUDE_GUI)")
    else:
        lines.append(f"{target_name:<40} :   BUILD_WINTYPE   = CFG_CUI")
        lines.append(f"{target_name:<40} :   EXCLUDE_PKGS    = $(EXCLUDE_CUI)")

    lines.append("")
    return "\n".join(lines)


def main():
    if not TEMPLATE_FILE.exists():
        print(f"❌ エラー: テンプレートファイル {TEMPLATE_FILE} が存在しません。")
        return
    tmpl_text = TEMPLATE_FILE.read_text(encoding="utf-8")
    script_match = re.search(
        r"TARGET_SCRIPT\s*=\s*(.*?)(?=\n[A-Z_]+\s*=|\n\n|\Z)", tmpl_text, re.DOTALL
    )
    if not script_match:
        print("❌ エラー: TARGET_SCRIPT を抽出できませんでした。")
        return
    target_scripts = []
    for s in script_match.group(1).splitlines():
        s_clean = s.strip().replace("\\", "")
        if s_clean and not s_clean.startswith("#"):
            target_scripts.append(s_clean)
    utils_map = load_module_map(UTILS_INIT)
    shared_map = load_module_map(SHARED_INIT)
    generated_blocks = []
    for script_name in target_scripts:
        script_path = Path(script_name)
        target_name = script_path.stem
        if not script_path.exists():
            block = generate_target_block(target_name, [], [], False)
        else:
            is_gui = check_is_gui(script_path)
            imports = analyze_script(script_path, utils_map, shared_map)
            # 💡 修正ポイント2: コメント行が排除されたことで正常にデータファイルを
            #    引き当てられるようになります
            data_files = scan_required_resources(script_path)
            block = generate_target_block(target_name, imports, data_files, is_gui)
        generated_blocks.append(block)
    configs_string = "\n".join(generated_blocks)
    final_makefile_content = tmpl_text.replace(
        "@TARGET_SPECIFIC_CONFIGS@", configs_string
    )
    OUTPUT_FILE.write_text(final_makefile_content, encoding="utf-8")
    print(
        "✨ CUI/GUIの自動切り替え判定を組み込んだ一本化版 'Makefile' を生成しました。"
    )


if __name__ == "__main__":
    main()
