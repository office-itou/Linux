"""main window build tables"""

# --- python library ----------------------------------------------------------
import tkinter as tk
from tkinter import font, ttk


# --- my library --------------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- main --------------------------------------------------------------------


class MainWindowBuildTables:
    # 型チェッカー用の定義
    ui_def: dict
    current_messages: dict[str, str]

    def _generate_center_tables(self, parent_frame: tk.Widget) -> None:
        """メインフレーム内にJSON定義に基づいたテーブル群を構築する"""
        for table_data in self.ui_def.get("tables", []):
            grid_info = table_data.get("grid_layout", {})
            # テーブルコンテナ用のフレームを作成
            table_container = ttk.Frame(parent_frame)
            # 動的グリッド配置
            table_container.grid(
                row=grid_info.get("row", 0),
                column=grid_info.get("column", 0),
                rowspan=grid_info.get("row_span", 1),
                columnspan=grid_info.get("column_span", 1),
                padx=grid_info.get("padx", 5),
                pady=grid_info.get("pady", 5),
                sticky=grid_info.get("sticky", "nsew"),
            )
            # 内部の重み設定
            table_container.columnconfigure(0, weight=1)
            table_container.rowconfigure(1, weight=1)  # 1行目: Treeview本体が伸縮
            table_container.rowconfigure(
                2, weight=0
            )  # 2行目: 🌟横スクロールバー用（伸縮しない）
            # ラベルの配置
            lbl_key = table_data.get("label_key", "")
            lbl_text: float | str | None = self.current_messages.get(lbl_key, lbl_key)
            if lbl_text:
                lbl = ttk.Label(table_container, text=lbl_text, font=("", 11, "bold"))
                lbl.grid(row=0, column=0, sticky="w", pady=(0, 5))
            # Treeview 本体を作成
            cols = [col["field"] for col in table_data.get("columns", [])]
            tree = ttk.Treeview(table_container, columns=cols, show="headings")
            # 列ヘッダーと幅の設定
            for col_info in table_data.get("columns", []):
                field = col_info["field"]
                width = col_info["width"]
                anchor = col_info["anchor"]
                disp_name: str | None = self.current_messages.get(field, field)
                if disp_name:
                    tree.heading(field, text=disp_name)
                if width > 0:
                    tree.column(field, width=width, anchor=anchor, stretch=False)
                else:
                    tree.column(field, anchor=anchor, stretch=True)
            tree.grid(row=1, column=0, sticky="nsew")
            # 🌟 縦スクロールバーを追加して連動
            v_scrollbar = ttk.Scrollbar(
                table_container, orient=tk.VERTICAL, command=tree.yview
            )
            tree.configure(yscrollcommand=v_scrollbar.set)
            v_scrollbar.grid(row=1, column=1, sticky="ns")
            # 🌟 横スクロールバーを追加して連動
            h_scrollbar = ttk.Scrollbar(
                table_container, orient=tk.HORIZONTAL, command=tree.xview
            )
            tree.configure(xscrollcommand=h_scrollbar.set)
            h_scrollbar.grid(row=2, column=0, sticky="ew")
            # --- data load ---------------------------------------------------
            for row_index, item_obj in enumerate(self.info_comm.mdia.data):
                value = []
                for k,v in item_obj.__dict__.items():
                    value.append(v)
                tree.insert("", "end", iid=str(row_index), values=value)
        # --- style -----------------------------------------------------------
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
