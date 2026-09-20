import tkinter as tk

# from tkinter import filedialog, messagebox, ttk
from typing import Any

from menu_data import FILE_MENU_DATA, LANG_MENU_DATA
from messages import MESSAGES


class MainWindow:
    def __init__(self, root: tk.Tk) -> None:
        self.root: tk.Tk = root
        # --- screen generation -----------------------------------------------
        self.root.geometry("800x600")
        self.current_lang: tk.StringVar = tk.StringVar(value="ja")
        # ---------------------------------------------------------------------
        # 💡 インポートしたデータをクラス内で扱えるように保持
        self.file_menu_data = FILE_MENU_DATA
        self.lang_menu_data = LANG_MENU_DATA
        # 💡 ショートカットキーとコマンドの一括自動バインド
        for item in self.file_menu_data:
            if "cmd_name" in item:
                # getattr(self, "open_file") は self.open_file と同じ意味になります
                cmd_func = getattr(self, item["cmd_name"])

                if "bind" in item:
                    self.root.bind(item["bind"], lambda event, c=cmd_func: c())
        # ---------------------------------------------------------------------
        self.create_main()

    def _build_command_menu(self, menu_items: list[dict[str, Any]]) -> tk.Menu:
        menu = tk.Menu(self.menubar, tearoff=0)
        for item in menu_items:
            if item.get("separator"):
                menu.add_separator()
            else:
                label_text = self.message[item["msg_key"]]
                # 💡 ここでも getattr を使って文字列から実際の関数オブジェクトを取得
                cmd_func = getattr(self, item["cmd_name"])

                menu.add_command(
                    label=label_text, command=cmd_func, accelerator=item.get("acc", "")
                )
        return menu

    def _build_radio_menu(self, menu_items: list[dict[str, Any]]) -> tk.Menu:
        menu = tk.Menu(self.menubar, tearoff=0)
        for item in menu_items:
            menu.add_radiobutton(
                label=item["label"],
                variable=self.current_lang,
                value=item["value"],
                command=self.switch_language,
            )
        return menu

    def create_main(self) -> None:
        if hasattr(self, "menubar"):
            self.root.config(menu="")
        lang_code = self.current_lang.get()
        self.message: dict[str, str] = MESSAGES[lang_code]
        self.root.title(self.message["title"])
        self.menubar: tk.Menu = tk.Menu(self.root)
        self.menubar.add_cascade(
            label=f"{self.message['menu_file']} (F)",
            menu=self._build_command_menu(self.file_menu_data),
            underline=len(f"{self.message['menu_file']} (F)") - 2,
        )
        self.menubar.add_cascade(
            label=f"{self.message['menu_lang']} (L)",
            menu=self._build_radio_menu(self.lang_menu_data),
            underline=len(f"{self.message['menu_lang']} (L)") - 2,
        )
        self.root.config(menu=self.menubar)

    def open_file(self) -> None:
        return

    def save_file(self) -> None:
        return

    def save_file_as(self) -> None:
        return

    def quit_app(self) -> None:
        self.root.quit()

    def switch_language(self) -> None:
        self.create_main()


if __name__ == "__main__":
    root: tk.Tk = tk.Tk()
    app: MainWindow = MainWindow(root)
    root.mainloop()
