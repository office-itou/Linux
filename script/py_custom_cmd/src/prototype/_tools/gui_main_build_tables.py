"""main window build tables"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from tkinter import font, ttk
from typing import Any

# --- my library --------------------------------------------------------------
# ruff: isort: ofn
from common.shared import InfoCommon
from common.utils import safe_format


# ruff: isort: on


# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- main --------------------------------------------------------------------
def _on_tree_click(event: tk.Event) -> None:
    """チェックボックス列がクリックされた際にトグル切り替えを行うイベントハンドラ"""
    tree = event.widget
    if not isinstance(tree, ttk.Treeview):
        return

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
        try:
            # 💡 iid がデータモデルのインデックス (row_idx)
            # そのものになっているため安全に直結
            row_idx = int(item_id)

            root = tree.winfo_toplevel()
            main_window: Any = getattr(root, "app", None)

            if main_window is None:
                master: Any = tree.master
                while master is not None:
                    if hasattr(master, "datas_map"):
                        main_window = master
                        break
                    master = getattr(master, "master", None)

            if main_window and hasattr(main_window, "datas_map"):
                table_widgets = getattr(main_window, "table_widgets", {})
                datas_map = getattr(main_window, "datas_map", {})

                for t_id, t_widget in table_widgets.items():
                    if t_widget == tree:
                        target_data = datas_map.get(t_id, [])
                        if row_idx < len(target_data):
                            target_data[row_idx].is_target = next_state == "☑"
                        break
        except Exception:  # noqa: BLE001, S110
            pass


class MainWindowBuildTables:
    ui_def: dict
    current_messages: dict[str, str]
    info_comm: InfoCommon

    table_widgets: dict[str, ttk.Treeview]
    datas_map: dict[str, list[Any]]

    def _generate_center_tables(self, parent_frame: tk.Widget) -> None:
        """メインフレーム内にJSON定義に基づいたテーブル群を構築する"""
        if not hasattr(self, "table_widgets"):
            self.table_widgets = {}

        for table_data in self.ui_def.get("tables", []):
            table_id = table_data.get("table_id", "")
            grid_info = table_data.get("grid_layout", {})
            table_container = ttk.Frame(parent_frame)
            table_container.grid(
                row=grid_info.get("row", 0),
                column=grid_info.get("column", 0),
                rowspan=grid_info.get("row_span", 1),
                columnspan=grid_info.get("column_span", 1),
                padx=grid_info.get("padx", 5),
                pady=grid_info.get("pady", 5),
                sticky=grid_info.get("sticky", "nsew"),
            )
            table_container.columnconfigure(0, weight=1)
            table_container.rowconfigure(1, weight=1)
            table_container.rowconfigure(2, weight=0)

            lbl_key = table_data.get("label_key", "")
            lbl_text: float | str | None = self.current_messages.get(lbl_key, lbl_key)
            if lbl_text:
                lbl = ttk.Label(table_container, text=lbl_text, font=("", 9, "bold"))
                lbl.grid(row=0, column=0, sticky="w", pady=(0, 5))

            cols = [col["field"] for col in table_data.get("columns", [])]
            tree = ttk.Treeview(table_container, columns=cols, show="headings")
            tree.bind("<Button-1>", _on_tree_click)

            self.table_widgets[table_id] = tree

            even_bg = table_data.get("even_bg", "#ffffff")
            odd_bg = table_data.get("odd_bg", "#ffffff")
            updated_bg = table_data.get("updated_bg", "#e0f2fe")
            even_tag = f"{table_id}_even"
            odd_tag = f"{table_id}_odd"
            updated_tag = f"{table_id}_updated"
            tree.tag_configure(even_tag, background=even_bg)
            tree.tag_configure(odd_tag, background=odd_bg)
            tree.tag_configure(updated_tag, background=updated_bg)

            for col_info in table_data.get("columns", []):
                field = col_info["field"]
                width = (
                    col_info["width"] + 8
                    if col_info["width"] > 0
                    else col_info["width"]
                )
                anchor = col_info["anchor"]
                disp_name: str | None = self.current_messages.get(field, field)
                if disp_name:
                    tree.heading(field, text=disp_name)
                if width > 0:
                    tree.column(field, width=width, anchor=anchor, stretch=False)
                else:
                    tree.column(field, anchor=anchor, stretch=True)
            tree.grid(row=1, column=0, sticky="nsew")

            v_scrollbar = ttk.Scrollbar(
                table_container, orient=tk.VERTICAL, command=tree.yview
            )
            tree.configure(yscrollcommand=v_scrollbar.set)
            v_scrollbar.grid(row=1, column=1, sticky="ns")

            h_scrollbar = ttk.Scrollbar(
                table_container, orient=tk.HORIZONTAL, command=tree.xview
            )
            tree.configure(xscrollcommand=h_scrollbar.set)
            h_scrollbar.grid(row=2, column=0, sticky="ew")

        self.reload_table_data()

        if not hasattr(self, "datas_map"):
            self.datas_map = {}
        self.datas_map["active_table"] = self.info_comm.mdia.data

        # --- style ---
        font.nametofont("TkDefaultFont")
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

    def reload_table_data(self) -> None:
        """💡 表の内容のみをデータモデルからクリア＆再読込するメソッド"""
        if not hasattr(self, "table_widgets"):
            return

        for table_data in self.ui_def.get("tables", []):
            table_id = table_data.get("table_id", "")
            tree = self.table_widgets.get(table_id)
            if not tree:
                continue

            for item in tree.get_children():
                tree.delete(item)

            formats = {
                col["field"]: col.get("format") for col in table_data.get("columns", [])
            }
            even_tag = f"{table_id}_even"
            odd_tag = f"{table_id}_odd"

            # 💡 index は単なるストライプ（偶数・奇数行背景色）の判定用としてのみ利用
            visible_row_count = 0
            for c_idx, col_info in enumerate(table_data.get("columns", [])):
                if "checked" in col_info.get("field", "").lower():
                    break

            for row_index, item_obj in enumerate(self.info_comm.mdia.data):
                value = []
                for col_info in table_data.get("columns", []):
                    if getattr(item_obj, "entry_flag", "") == "o":
                        field = col_info["field"]
                        raw_value = getattr(item_obj, field, "")

                        if field == "is_checked":
                            raw_value = (
                                "☑" if getattr(item_obj, "is_target", False) else "☐"
                            )
                        else:
                            raw_value = raw_value if raw_value else "-"

                        val_str = safe_format(raw_value, formats.get(field))
                        value.append(val_str)

                if value:
                    row_tag = even_tag if visible_row_count % 2 == 0 else odd_tag

                    # 💡 🌟 【超重要】iid を連動のズレる index ではなく、
                    # データ配列の絶対位置 row_index に固定
                    tree.insert(
                        "", "end", iid=str(row_index), values=value, tags=(row_tag,)
                    )
                    visible_row_count += 1
