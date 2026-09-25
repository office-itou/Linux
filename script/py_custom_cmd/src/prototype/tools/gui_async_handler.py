# gui_async_handler.py
import asyncio
import threading

from typing import Any

from async_io import get_web_file_info
from my_string import eprint


class AsyncProcessHandler:
    """Tkinterとasyncioのサブスレッド間連携を仲介するハンドラクラス"""

    def __init__(self, window_instance: Any) -> None:
        self.win = window_instance  # MainWindowのインスタンスへの参照

    def start_async_process(self) -> None:
        """バックグラウンドで非同期通信処理スレッドを安全に起動する"""
        if self.win.is_running_async:
            eprint("⚠️ 既に処理が実行中です。")
            return
        # 1. 実行前に画面のチェックボックス状態をデータオブジェクトに確定同期
        self._sync_view_to_model()
        eprint(
            "🚀 チェック状態を保持したまま、バックグラウンド非同期処理を開始します..."
        )
        self.win.is_running_async = True
        # 新しいスレッドを起こして、バックグラウンドで asyncio を走らせる
        threading.Thread(target=self._run_async_loop, daemon=True).start()

    def _sync_view_to_model(self) -> None:
        """画面(Treeview)の☑/☐状態をInfoCommonモデルの各オブジェクトへ同期する"""
        for table_id, tree in self.win.table_widgets.items():
            columns = list(tree["columns"])
            if "is_checked" not in columns:
                continue
            check_idx = columns.index("is_checked")
            target_data = self.win.datas_map.get(table_id, [])
            items = tree.get_children()
            for idx, item_id in enumerate(items):
                if idx < len(target_data):
                    current_values = tree.item(item_id, "values")
                    is_checked = current_values[check_idx] == "☑"
                    target_data[idx].is_target = is_checked
                    # 過去の古い「更新フラグ」をクリア
                    if hasattr(target_data[idx], "is_updated_data"):
                        del target_data[idx].is_updated_data

    def _run_async_loop(self) -> None:
        """【サブスレッド側で動作】独立したイベントループで非同期通信を処理"""
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(get_web_file_info(self.win.info_comm))
            loop.close()
        except Exception as e:  # noqa: BLE001
            eprint(f"❌ エラー: {e}")
        finally:
            # メインスレッドに対してスレッドセーフに完了通知を送る
            self.win.root.after(0, self._on_complete)

    def _on_complete(self) -> None:
        """【メインスレッド側で動作】完了後のUI更新トリガー"""
        self.win.is_running_async = False
        eprint("✨ データ取得完了。画面をリフレッシュし、更新行の色を変えます。")
        # 画面の再構築を実行
        self.win.generate_window()
        # 更新された行をハイライトしてメモを差し込む
        self._highlight_updated_rows()

    def _highlight_updated_rows(self) -> None:
        """非同期処理内で「is_updated_data」フラグが立った行の背景色とメモを動的変更"""
        for table_id, tree in self.win.table_widgets.items():
            if table_id == "active_table":
                target_data = [
                    item
                    for item in self.win.info_comm.mdia.data
                    if getattr(item, "entry_flag", "") == "o"
                ]
            else:
                target_data = [
                    item
                    for item in self.win.info_comm.mdia.data
                    if getattr(item, "entry_flag", "") != "o"
                ]
            items = tree.get_children()
            columns = list(tree["columns"])
            memo_idx = columns.index("memo") if "memo" in columns else -1
            for idx, item_id in enumerate(items):
                if idx < len(target_data) and getattr(
                    target_data[idx], "is_updated_data", False
                ):
                    tree.item(item_id, tags=(f"{table_id}_updated",))
                    if memo_idx != -1:
                        vals = list(tree.item(item_id, "values"))
                        vals[memo_idx] = "🔄 データを更新しました"
                        tree.item(item_id, values=vals)
