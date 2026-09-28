"""env_guard.py: 外部ライブラリインポート前の環境変数・sudoチェック"""

import os
import re


if os.geteuid() == 0:
    _sudo_user = os.environ.get("SUDO_USER")
    if not _sudo_user or _sudo_user == "root":
        raise SystemExit(
            "\x1b[91mDirect root login is not supported."
            " Please run as a normal user.\x1b[0m"
        )
    _original_home = os.path.expanduser(f"~{_sudo_user}")
    _current_home = os.environ.get("HOME")
    if _current_home != _original_home:
        _cui_message = (
            "\x1b[91mPlease launch it without using `sudo` or by adding `-E`.\x1b[0m"
            "\n"
            "\x1b[31m  The user's environment variable paths (~/.local)"
            " are not being resolved.\x1b[0m"
        )
        # 環境変数からGUIモードかどうかを判定 (デフォルトはCUI)
        if os.environ.get("GUARD_MODE") == "GUI":
            _gui_message = re.sub(r"\x1b\[[0-9;]*m", "", _cui_message)
            try:
                import tkinter as tk
                from tkinter import messagebox

                _root = tk.Tk()
                _root.withdraw()
                messagebox.showerror("Execution Error", _gui_message)
                _root.destroy()
            except Exception:  # noqa: BLE001, S110
                pass
        raise SystemExit(_cui_message)
# --- クリーンアップ処理 ---
# 正常にチェックを通過した場合（一般ユーザーでの実行時など）、
# このモジュール内に残った一時的な内部変数を削除してメモリを綺麗にします。
# (SystemExit で終了した場合はここへ到達しないため考慮不要です)
_locals = list(locals().keys())
for _name in _locals:
    if _name.startswith("_") and not _name.startswith("__"):
        del locals()[_name]

# ループで使用した変数自体も削除
if "_name" in locals():
    del _name # type: ignore
if "_locals" in locals():
    del _locals
