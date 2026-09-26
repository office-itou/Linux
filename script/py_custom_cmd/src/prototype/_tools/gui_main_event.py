"""main window event"""

# --- python library ----------------------------------------------------------
import tkinter as tk


# --- my library --------------------------------------------------------------
# ruff: isort: off
from my_config import infosystem
from my_string import eprint, set_gui_log_window


# ruff: isort: on
# --- gui window module ------------------------------------------------------
# ruff: isort: off
# ruff: isort: on
# --- main --------------------------------------------------------------------
class MainWindowEvent:
    def __init__(self, root: tk.Tk) -> None:
        """initialization
        Args:
            root (tk.Tk): the generated window object
        """
        self.root: tk.Tk = root
        self.current_lang_strvar: tk.StringVar = tk.StringVar(value=infosystem.lang)
        self.current_messages: dict[str, str] = {}

    def event_open_file(self) -> None:
        """open event"""
        message = self.current_messages.get("menu_open", "Open File...")
        eprint(message)

    def event_save_file(self) -> None:
        """save event"""
        message = self.current_messages.get("menu_save", "Save")
        eprint(message)

    def event_save_file_as(self) -> None:
        """save as event"""
        message = self.current_messages.get("menu_save_as", "Save As...")
        eprint(message)

    def event_quit_app(self) -> None:
        """quit event"""
        message = self.current_messages.get("menu_exit", "Exit")
        eprint(message)
        infosystem.log_window_active = False
        set_gui_log_window(None)
        for child in self.root.winfo_children():
            if isinstance(child, tk.Toplevel) and child.winfo_exists():
                try:
                    child.destroy()
                except Exception:  # noqa: BLE001, S110
                    pass
        self.root.quit()

    def event_switch_language(self) -> None:
        """switch language event"""
        message = self.current_messages.get("menu_lang", "Language")
        eprint(f"{message}({self.current_lang_strvar.get()})")
        self.generate_window()

    def event_exec(self) -> None:
        """exec event"""
        message = self.current_messages.get("btn_exec", "Run")
        eprint(message)

    def event_confirm(self) -> None:
        """confirm event"""
        message = self.current_messages.get("btn_confirm", "Confirm")
        eprint(message)

    def event_debug_mon(self) -> None:
        """debug monitor event"""
        message = self.current_messages.get("btn_debug", "Debug monitor")
        eprint(message)

    def event_toggle_all_checks(self, table_id: str, check_char: str) -> None:
        """toggle all checks event
        Args:
            table_id (str): _description_
            check_char (str): _description_
        """
        # if table_id not in self.table_widgets:
        return
