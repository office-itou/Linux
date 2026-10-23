import tkinter as tk
from datetime import datetime
from tkinter import font, ttk
from typing import Any


def _safe_format(value: Any, fmt_str: str | None) -> str:
    """
    値を安全にフォーマット文字列へ適用するヘルパー関数。
    ISO 8601形式 ("2024-08-27T06:14:31+00:00") の場合は、
    実行環境（PC）のローカルタイムゾーンに自動変換してから整形します。
    """
    if value is None:
        return ""
    if not fmt_str:
        return str(value)
    try:
        # 1. 既に datetime オブジェクト、または数値の場合はそのままフォーマット適用
        return fmt_str.format(value)
    except (TypeError, ValueError):
        # 2. 文字列型の日付が渡されていて、日付フォーマットが指定されている場合
        if isinstance(value, str) and "%" in fmt_str:
            if "T" in value:
                try:
                    # ISO 8601 形式の文字列を datetime に変換（この時点で UTC などの情報を持つ）
                    dt = datetime.fromisoformat(value)
                    # 💡 実行環境（ローカルPC）のタイムゾーンへ動的に変換
                    # dt.tzinfo が存在する場合のみ変換し、存在しない場合はそのまま処理します
                    if dt.tzinfo is not None:
                        dt = dt.astimezone()
                    return fmt_str.format(dt)
                except ValueError:
                    pass
            # 従来のフォーマットに対するフォールバック（タイムゾーン情報がない文字列用）
            for parse_fmt in (
                "%Y-%m-%d %H:%M:%S",
                "%Y/%m/%d %H:%M:%S",
                "%Y-%m-%d",
                "%Y/%m/%d",
            ):
                try:
                    dt = datetime.strptime(value, parse_fmt)
                    return fmt_str.format(dt)
                except ValueError:
                    continue
        # 3. どうしても適用できない場合はフォールバックとして通常の文字列変換
        return str(value)


def _on_tree_click(event: tk.Event) -> None:
    """チェックボックス列がクリックされた際にトグル切り替えを行うイベントハンドラ"""
    tree = event.widget
    region = tree.identify_region(event.x, event.y)
    if region != "cell":
        return
    column = tree.identify_column(event.x)
    item_id = tree.identify_row(event.y)
    if not item_id:
        return
    cols = tree["columns"]
    col_idx = int(column.replace("#", "")) - 1
    col_name = cols[col_idx]
    if "checked" in col_name.lower():
        current_values = list(tree.item(item_id, "values"))
        next_state = "☑" if current_values[col_idx] == "☐" else "☐"
        current_values[col_idx] = next_state
        tree.item(item_id, values=current_values)
        # 💡 【追加】背後にあるデータオブジェクトに対しても即座に状態を反映させる
        # tree.master や格納された参照を探す代わりに、MainWindow側の datas_map と同期をとるため、
        # master(LabelFrame) -> master(main_frame) -> master(MainWindow) のインスタンスを参照します
        try:
            row_idx = int(item_id)
            # コンテナ構成に合わせて親を遡り、MainWindow が保持する datas_map を書き換える
            main_window = tree.master.master.master
            if hasattr(main_window, "datas_map"):
                # tree の属するテーブルIDをコンテナ名などから特定、または割り出し
                for t_id, t_widget in main_window.table_widgets.items():
                    if t_widget == tree:
                        target_data = main_window.datas_map.get(t_id, [])
                        if row_idx < len(target_data):
                            target_data[row_idx].is_target = next_state == "☑"
                        break
        except Exception:  # noqa: BLE001, S110
            pass


class ToolTip:
    """マウスの下のテキストをポップアップ表示するヘルパーモジュール"""

    def __init__(self, widget):
        self.widget = widget
        self.tip_window = None
        self.current_text = None  # 💡 現在表示中のテキストを保持

    def show_tip(self, text, x, y):
        # 💡 テキストが変わった場合は、古いウィンドウを一度閉じて作り直す
        if self.tip_window and self.current_text != text:
            self.hide_tip()
        if self.tip_window:
            # 既に同じテキストの窓が開いている場合は、マウスの位置に合わせて少し移動させるだけにする
            self.tip_window.wm_geometry(f"+{x + 15}+{y + 15}")
            return
        self.current_text = text
        # マウスの少し右下にウィンドウを作成
        self.tip_window = tw = tk.Toplevel(self.widget)
        tw.wm_overrideredirect(True)  # 枠線の無いウィンドウ
        tw.wm_geometry(f"+{x + 15}+{y + 15}")
        label = tk.Label(
            tw,
            text=text,
            justify=tk.LEFT,
            background="#ffffe0",
            relief=tk.SOLID,
            borderwidth=1,
            font=("TkDefaultFont", 9),
            padx=4,
            pady=2,
        )
        label.pack()

    def hide_tip(self):
        tw = self.tip_window
        self.tip_window = None
        self.current_text = None  # テキスト保持もクリア
        if tw:
            tw.destroy()


def _on_tree_motion(event: tk.Event, tooltip: ToolTip) -> None:
    """マウスが動いたときに現在のセル位置（行・列）を監視し、ヒントをリアルタイム更新する"""
    tree = event.widget
    region = tree.identify_region(event.x, event.y)
    # セル以外の場所（ヘッダーや枠線など）にマウスがある場合はヒントを消す
    if region != "cell":
        tooltip.hide_tip()
        return
    item_id = tree.identify_row(event.y)
    column = tree.identify_column(event.x)
    if not item_id or not column:
        tooltip.hide_tip()
        return
    col_idx = int(column.replace("#", "")) - 1
    values = tree.item(item_id, "values")
    if values and col_idx < len(values):
        cell_text = str(values[col_idx]).strip()
        # 空白行やチェックボックス文字の列では非表示にする
        if cell_text and cell_text not in ("☐", "☑"):
            # ディスプレイ上の絶対座標を算出
            abs_x = tree.winfo_rootx() + event.x
            abs_y = tree.winfo_rooty() + event.y
            # 💡 テキストを渡す（ToolTip側で行・列の切り替えを検知して自動更新されます）
            tooltip.show_tip(cell_text, abs_x, abs_y)
            return
    tooltip.hide_tip()


def build_tables(
    parent: tk.Widget,
    tables_data: list[dict[str, Any]],
    messages: dict[str, str],
    datas_map: dict[str, list[list[Any]]],
    text_padding: int = 25,
) -> dict[str, ttk.Treeview]:
    """
    JSONの定義リストに基づいて、複数のテーブル(Treeview)を動的に構築・配置する共通関数。
    データ配列に無いチェックボックスやメモ欄も、JSONの定義列に合わせて自動補完します。
    """
    tree_widgets = {}
    default_font = font.nametofont("TkDefaultFont")
    style = ttk.Style()
    if style.theme_use() != "clam":
        style.theme_use("clam")
    style.configure(
        "Treeview",
        rowheight=26,
        background="#ffffff",
        fieldbackground="#ffffff",
        borderwidth=1,
        lightcolor="#4b5563",
        darkcolor="#4b5563",
        borderColor="#4b5563",
    )
    style.configure(
        "Treeview.Heading",
        background="#e5e7eb",
        lightcolor="#4b5563",
        darkcolor="#4b5563",
        relief="flat",
    )
    for table_config in tables_data:
        table_id = table_config.get("table_id", "")
        container = ttk.LabelFrame(
            parent, text=messages.get(table_config.get("label_key", ""), "")
        )
        grid_info = table_config.get("grid_layout", {})
        grid_kwargs = {
            "row": grid_info.get("row", 0),
            "column": grid_info.get("column", 0),
            "rowspan": grid_info.get("row_span", 1),
            "columnspan": grid_info.get("column_span", 1),
            "padx": grid_info.get("padx", 5),
            "pady": grid_info.get("pady", 5),
            "sticky": grid_info.get("sticky", "nsew"),
        }
        container.grid(**grid_kwargs)
        scrollbar_y = ttk.Scrollbar(container, orient="vertical")
        scrollbar_y.pack(side="right", fill="y")
        scrollbar_x = ttk.Scrollbar(container, orient="horizontal")
        scrollbar_x.pack(side="bottom", fill="x")
        columns_config = table_config.get("columns", [])
        columns = [col["field"] for col in columns_config]
        formats_map = {col["field"]: col.get("format") for col in columns_config}
        tree = ttk.Treeview(
            container,
            columns=columns,
            show="headings",
            yscrollcommand=scrollbar_y.set,
            xscrollcommand=scrollbar_x.set,
        )
        tree.pack(fill="both", expand=True)
        scrollbar_y.config(command=tree.yview)
        scrollbar_x.config(command=tree.xview)
        # 💡 【追加】ツールチップインスタンスを生成し、イベントを紐付け
        tooltip = ToolTip(tree)
        tree.bind("<Motion>", lambda e, tt=tooltip: _on_tree_motion(e, tt))
        tree.bind(
            "<Leave>", lambda e, tt=tooltip: tt.hide_tip()
        )  # ツリーから離れたら消す
        # 💡 クリックイベントをバインド（チェックボックスのトグル用）
        tree.bind("<Button-1>", _on_tree_click)
        # --- (gui_build_table.py の初期化部分にタグを追加) ---
        even_bg = table_config.get("even_bg", "#ffffff")
        odd_bg = table_config.get("odd_bg", "#ffffff")
        updated_bg = table_config.get("updated_bg", "#e0f2fe")  # 💡 追加
        even_tag = f"{table_id}_even"
        odd_tag = f"{table_id}_odd"
        updated_tag = f"{table_id}_updated"  # 💡 追加
        tree.tag_configure(even_tag, background=even_bg)
        tree.tag_configure(odd_tag, background=odd_bg)
        tree.tag_configure(updated_tag, background=updated_bg)  # 💡 追加
        table_datas = datas_map.get(table_id, [])
        calc_widths = {col: 0 for col in columns}
        # 1. ヘッダーテキストの幅を計測
        for col_name in columns:
            display_title = messages.get(col_name, col_name)
            title_width = default_font.measure(display_title) + text_padding
            calc_widths[col_name] = max(calc_widths[col_name], title_width)
        # 2. 表示用に整形されたデータのリストを事前に作成しつつ幅を計測
        formatted_rows = []
        for row_index, item_obj in enumerate(
            table_datas
        ):  # 💡 row_data から item_obj に変更
            formatted_row = []
            for col_setting in columns_config:
                col_name = col_setting["field"]
                if "checked" in col_name.lower():
                    # 💡 オブジェクト側の is_target フラグを見てチェック状態を復元
                    if hasattr(item_obj, "is_target"):
                        val_str = "☑" if getattr(item_obj, "is_target", False) else "☐"
                    else:
                        val_str = "☐"
                elif col_name == "memo":
                    val_str = ""  # メモ欄の初期化（文言の反映は main.py で行うため空文字列でOK）
                else:
                    # 💡 オブジェクトから動的にフィールド名で値を取得してフォーマット適用
                    raw_value = getattr(item_obj, col_name, "")
                    val_str = _safe_format(raw_value, formats_map.get(col_name))
                val_width = default_font.measure(val_str) + text_padding
                calc_widths[col_name] = max(calc_widths[col_name], val_width)
                formatted_row.append(val_str)
            formatted_rows.append(formatted_row)
        # --- ⚙️ 列プロパティの設定 -------------------------
        num_columns = len(columns_config)
        for idx, col_setting in enumerate(columns_config):
            col_name = col_setting["field"]
            display_title = messages.get(col_name, col_name)
            tree.heading(col_name, text=display_title)
            json_width = col_setting.get("width", 50)
            if json_width == 0:
                final_width = 0
                stretch_option = False
            elif json_width == -1:
                final_width = calc_widths[col_name]
                stretch_option = idx == num_columns - 1
            else:
                final_width = json_width
                stretch_option = idx == num_columns - 1
            tree.column(
                col_name,
                width=final_width,
                minwidth=0 if json_width == 0 else 20,
                anchor=col_setting.get("anchor", "w"),
                stretch=stretch_option,
            )
        for index, item in enumerate(formatted_rows):
            row_tag = even_tag if index % 2 == 0 else odd_tag
            tree.insert("", "end", iid=str(index), values=item, tags=(row_tag,))
        tree_widgets[table_id] = tree
    return tree_widgets
