# menu_data.py
from typing import Any

# --- command menu (file) -----------------------------------------------------
# 1: msg_key : message key
# 2: acc     : accelerator
# 3: bind    : keyboard shortcuts
# 4: cmd_name: command funtion name
FILE_MENU_DATA: list[dict[str, str]] = [
    {
        "msg_key": "menu_open",
        "acc": "Ctrl+O",
        "bind": "<Control-o>",
        "cmd_name": "open_file",
    },
    {
        "msg_key": "menu_save",
        "acc": "Ctrl+S",
        "bind": "<Control-s>",
        "cmd_name": "save_file",
    },
    {
        "msg_key": "menu_save_as",
        "acc": "Ctrl+Shift+S",
        "bind": "<Control-Shift-S>",
        "cmd_name": "save_file_as",
    },
    {"separator": True},
    {
        "msg_key": "menu_exit",
        "acc": "Ctrl+Q",
        "bind": "<Control-q>",
        "cmd_name": "quit_app",
    },
]

# --- radio button (language) -------------------------------------------------
# 1: label
# 2: value
LANG_MENU_DATA: list[dict[str, Any]] = [
    {"label": "English", "value": "en", "cmd_name": "switch_language"},
    {"label": "日本語 (Japanese)", "value": "ja", "cmd_name": "switch_language"},
]

# button (exec) ---------------------------------------------------------------
# 1: text   :
# 2: command:
EXEC_BTN_DATA = {
    "en": {"text": "Exec", "cmd_name": "create_md"},
    "ja": {"text": "実行", "cmd_name": "create_md"},
}
