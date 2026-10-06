"""Global variables (utils) (For both CUI/GUI)"""

# --- Python library ----------------------------------------------------------
import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

# --- my library --------------------------------------------------------------
from common.utils import (
    TimeElapsed,
)


# ruff: isort: on
# =============================================================================
@dataclass
class SystemData:
    """System data class (For both CUI/GUI)"""

    # --- global: args --------------------------------------------------------
    args: str | None = None
    # --- global: debug -------------------------------------------------------
    debug: bool = False
    debugout: bool = False
    # --- global: system ------------------------------------------------------
    program_name: str | None = None
    program_path: Path | None = None
    columns: int = 0
    rows: int = 0
    elapsed: float = 0.0
    # --- global: user --------------------------------------------------------
    exec_user: str | None = None
    home_dir: str | None = None
    # --- Extended property for GUI support -----------------------------------
    is_gui: bool = False
    # --- Slot for registering a function to display a dialog on the GUI side -
    #     (arguments: title, message)
    gui_info_callback: Any = None
    gui_error_callback: Any = None
    log_window_active: bool = False
    # --- Coordinate management for cascade layout ----------------------------
    #     (initial position: X=50, Y=50)
    next_win_x: int = 50
    next_win_y: int = 50
    # --- laguage -------------------------------------------------------------
    lang: str = "en"


# -----------------------------------------------------------------------------
class InfoSystem:
    """System information class"""

    def __init__(self) -> None:
        # __init__ はインスタンス変数の枠だけを用意し、
        # 重い処理やインポートは一切行わない
        self.data: SystemData | None = None
        self.elapsed = TimeElapsed()

    def _create_system_data(self, is_gui: bool) -> SystemData:
        """引数の is_gui に応じて、環境情報を解析し
        SystemData インスタンスを生成する共通メソッド"""
        import shutil

        from common.utils import detect_language

        import __main__

        terminal_size = shutil.get_terminal_size()
        # 実行中のプログラム名とユーザー環境情報の取得
        program_path = (
            Path(__main__.__file__) if hasattr(__main__, "__file__") else None
        )
        program_name = program_path.stem if program_path else "interactive"
        exec_user = os.getenv("SUDO_USER", os.getenv("USER"))
        home_dir = os.getenv("SUDO_HOME") or os.getenv("HOME") or f"/home/{exec_user}"
        lang = detect_language() or "en"
        # GUIとCUIによるパラメータの振り分け処理（一本化）
        if is_gui:
            try:
                from tkinter import messagebox
            except (OSError, Exception) as e:
                raise SystemExit from e
            gui_error_callback = messagebox.showerror
            gui_info_callback = messagebox.showinfo
            log_window_active = True
            columns = 120
            rows = 40
            debug = False  # 💡 🌟 ここを追加！
            debugout = False
        else:
            gui_error_callback = None
            gui_info_callback = None
            log_window_active = False
            columns = terminal_size.columns
            rows = terminal_size.lines
            debug = False  # 💡 🌟 ここを追加！
            debugout = False
        return SystemData(
            lang=lang,
            is_gui=is_gui,
            debug=debug,  # 💡 🌟 dataclassの生成時にも忘れず渡す
            debugout=debugout,
            program_name=program_name,
            program_path=program_path,
            columns=columns,
            rows=rows,
            exec_user=exec_user if exec_user else "",
            home_dir=home_dir if home_dir else "",
            gui_error_callback=gui_error_callback,
            gui_info_callback=gui_info_callback,
            log_window_active=log_window_active,
        )

    def _ensure_default_data(self) -> None:
        """データが未初期化の場合にのみ、最小限のデフォルトデータを安全に生成する"""
        if self.data is None:
            # 共通メソッドを CUIモード(False) で呼び出す
            self.data = self._create_system_data(is_gui=False)

    def initialize(self, is_gui: bool = False) -> None:
        """明示的にGUI/CUI環境の最適化初期化を行う"""
        # 共通メソッドを呼び出してインスタンスを上書き
        self.data = self._create_system_data(is_gui=is_gui)

    def __getattr__(self, name: str) -> Any:
        self._ensure_default_data()
        return getattr(self.data, name)

    def __setattr__(self, name: str, value: Any) -> None:
        if (
            name != "data"
            and "data" in self.__dict__
            and self.data is not None
            and hasattr(self.data, name)
        ):
            setattr(self.data, name, value)
        else:
            super().__setattr__(name, value)

    def to_dict(self) -> dict[str, Any]:
        self._ensure_default_data()
        if self.data is None:
            return {}
        return asdict(self.data)


infosystem = InfoSystem()
# --- eof ---------------------------------------------------------------------
