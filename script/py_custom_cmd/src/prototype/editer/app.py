# app.py
import json
import tkinter as tk
from tkinter import filedialog, messagebox, ttk
from typing import Any

from card_editor import CardEditorWindow
from messages import MESSAGES
from utils import clean_value, detect_language


class JsonManagerApp:
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root

        # 1. 共通関数からシステム言語を取得
        self.lang: str = detect_language()
        self.t: dict[str, str] = MESSAGES[self.lang]

        self.root.title(self.t["title"])
        self.root.geometry("900x550")

        self.data: list[dict[str, Any]] = []
        self.file_path: str = ""
        self.current_columns: list[str] = []

        self.create_menu()
        self.create_main_ui()

    def create_menu(self) -> None:
        if hasattr(self, "menubar"):
            self.root.config(menu="")

        self.menubar: tk.Menu = tk.Menu(self.root)
        self.filemenu: tk.Menu = tk.Menu(self.menubar, tearoff=0)
        self.filemenu.add_command(label=self.t["menu_open"], command=self.open_file)
        self.filemenu.add_command(label=self.t["menu_save"], command=self.save_file)
        self.filemenu.add_command(
            label=self.t["menu_save_as"], command=self.save_file_as
        )
        self.filemenu.add_separator()
        self.filemenu.add_command(label=self.t["menu_exit"], command=self.root.quit)
        self.menubar.add_cascade(label=self.t["menu_file"], menu=self.filemenu)
        self.root.config(menu=self.menubar)

    def create_main_ui(self) -> None:
        top_frame: ttk.Frame = ttk.Frame(self.root, padding=5)
        top_frame.pack(fill="x", padx=10)

        self.info_label: ttk.Label = ttk.Label(
            top_frame, text=self.t["info_start"], font=("Arial", 10, "italic")
        )
        self.info_label.pack(side="left", fill="x", expand=True)

        btn_text: str = "English" if self.lang == "ja" else "日本語"
        self.lang_btn: ttk.Button = ttk.Button(
            top_frame, text=btn_text, command=self.toggle_language
        )
        self.lang_btn.pack(side="right", padx=5)

        self.table_frame: ttk.Frame = ttk.Frame(self.root)
        self.table_frame.pack(fill="both", expand=True, padx=15, pady=5)

        self.scrollbar_y: ttk.Scrollbar = ttk.Scrollbar(
            self.table_frame, orient="vertical"
        )
        self.scrollbar_y.pack(side="right", fill="y")
        self.scrollbar_x: ttk.Scrollbar = ttk.Scrollbar(
            self.table_frame, orient="horizontal"
        )
        self.scrollbar_x.pack(side="bottom", fill="x")

        self.tree: ttk.Treeview = ttk.Treeview(self.table_frame, show="headings")
        self.tree.pack(fill="both", expand=True)

        self.scrollbar_y.config(command=self.tree.yview)
        self.scrollbar_x.config(command=self.tree.xview)

    def toggle_language(self) -> None:
        self.lang = "en" if self.lang == "ja" else "ja"
        self.t = MESSAGES[self.lang]

        self.root.title(self.t["title"])
        self.lang_btn.config(text="English" if self.lang == "ja" else "日本語")

        if not self.file_path:
            self.info_label.config(text=self.t["info_start"])
        else:
            self.info_label.config(
                text=self.t["info_open"].format(
                    path=self.file_path, count=len(self.data)
                )
            )

        self.create_menu()
        if self.data:
            self.setup_table_columns()
            self.refresh_table()

    def setup_table_columns(self) -> None:
        if not self.data:
            return

        all_keys: list[str] = list(self.data[0].keys())
        self.current_columns = all_keys[:8]

        self.tree.destroy()
        self.tree = ttk.Treeview(
            self.table_frame,
            columns=self.current_columns,
            show="headings",
            yscrollcommand=self.scrollbar_y.set,
            xscrollcommand=self.scrollbar_x.set,
        )
        self.tree.pack(fill="both", expand=True)
        self.scrollbar_y.config(command=self.tree.yview)
        self.scrollbar_x.config(command=self.tree.xview)

        for col in self.current_columns:
            display_title: str = self.t.get(col, col)
            self.tree.heading(col, text=display_title)
            self.tree.column(col, width=120, anchor="w")

        self.tree.bind("<Double-1>", self.on_row_double_click)

    def open_file(self) -> None:
        path: str = filedialog.askopenfilename(
            title=self.t["menu_open"],
            filetypes=[("JSON Files", "*.json"), ("All Files", "*.*")],
        )
        if not path:
            return

        try:
            with open(path, "r", encoding="utf-8") as f:
                self.data = json.load(f)
            self.file_path = path
            self.info_label.config(
                text=self.t["info_loading"].format(
                    path=self.file_path, count=len(self.data)
                ),
                font=("Arial", 10, "normal"),
            )
            self.setup_table_columns()
            self.refresh_table()
        except Exception as e:  # noqa: BLE001
            messagebox.showerror(
                self.t["msg_err_title"], self.t["msg_err_load"].format(e=e)
            )

    def refresh_table(self) -> None:
        for row in self.tree.get_children():
            self.tree.delete(row)

        for index, item in enumerate(self.data):
            row_values: list[str] = []
            for col in self.current_columns:
                val: Any = item.get(col, "-")
                row_values.append(clean_value(val))

            self.tree.insert("", "end", iid=str(index), values=row_values)

    def on_row_double_click(self, event: tk.Event) -> None:
        selected_items: tuple = self.tree.selection()
        if not selected_items:
            return
        data_index: int = int(selected_items[0])

        CardEditorWindow(
            parent_root=self.root,
            data=self.data,
            start_index=data_index,
            lang_dict=self.t,
            on_confirm_callback=self.refresh_table,
        )

    def save_file(self) -> None:
        if not self.file_path:
            self.save_file_as()
            return
        try:
            with open(self.file_path, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=4)
            messagebox.showinfo(
                self.t["msg_save_title"],
                self.t["msg_save_success"].format(path=self.file_path),
            )
        except Exception as e:  # noqa: BLE001
            messagebox.showerror(
                self.t["msg_err_title"], self.t["msg_err_save"].format(e=e)
            )

    def save_file_as(self) -> None:
        path: str = filedialog.asksaveasfilename(
            title=self.t["menu_save_as"],
            filetypes=[("JSON Files", "*.json")],
            defaultextension=".json",
        )
        if not path:
            return
        self.file_path = path
        self.save_file()
        self.info_label.config(
            text=self.t["info_open"].format(path=self.file_path, count=len(self.data))
        )


if __name__ == "__main__":
    root: tk.Tk = tk.Tk()
    app: JsonManagerApp = JsonManagerApp(root)
    root.mainloop()
