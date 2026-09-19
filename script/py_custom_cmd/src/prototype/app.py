import tkinter as tk
from tkinter import ttk, messagebox
import json
import os

# 編集対象のファイル名
JSON_FILE = "data.json"

class JsonCardEditor:
    def __init__(self, root):
        self.root = root
        self.root.title("JSON カード式エディタ")
        self.root.geometry("500x650")
        
        # データの読み込み
        self.data = self.load_json()
        self.current_index = 0
        self.entries = {}
        
        if not self.data:
            messagebox.showerror("エラー", f"有効なデータが見つかりません。{JSON_FILE} を確認してください。")
            self.root.destroy()
            return
            
        # メインフレーム（カードの土台）
        self.card_frame = ttk.LabelFrame(root, text=" カード情報 ", padding=15)
        self.card_frame.pack(fill="both", expand=True, padx=15, pady=15)
        
        # 入力項目の作成
        self.create_widgets()
        
        # ナビゲーションバー
        self.create_navigation()
        
        # 最初のデータを表示
        self.display_current_card()

    def load_json(self):
        """JSONファイルを読み込む"""
        if not os.path.exists(JSON_FILE):
            # テスト用にファイルが存在しない場合は空ファイルを防ぐ警告
            return []
        try:
            with open(JSON_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"読み込みエラー: {e}")
            return []

    def create_widgets(self):
        """JSONのキーに応じた入力フォームを動的に生成"""
        # サンプルの最初の要素からキーを取得
        sample_item = self.data[0]
        
        # 各項目を縦に配置
        for i, key in enumerate(sample_item.keys()):
            label = ttk.Label(self.card_frame, text=key, font=("Arial", 10, "bold"))
            label.grid(row=i, column=0, sticky="w", pady=4, padx=5)
            
            entry = ttk.Entry(self.card_frame, font=("Arial", 10))
            entry.grid(row=i, column=1, sticky="ew", pady=4, padx=5)
            
            self.entries[key] = entry
            
        self.card_frame.columnconfigure(1, weight=1)

    def create_navigation(self):
        """画面下部の操作ボタンエリア"""
        nav_frame = ttk.Frame(self.root, padding=10)
        nav_frame.pack(fill="x", side="bottom")
        
        # 現在の位置表示用ラベル
        self.status_label = ttk.Label(nav_frame, text="", font=("Arial", 10))
        self.status_label.pack(pady=5)
        
        btn_frame = ttk.Frame(nav_frame)
        btn_frame.pack()
        
        self.btn_prev = ttk.Button(btn_frame, text="◀ 前へ", command=self.prev_card)
        self.btn_prev.grid(row=0, column=0, padx=10)
        
        btn_save = ttk.Button(btn_frame, text="💾 変更を保存", command=self.save_data)
        btn_save.grid(row=0, column=1, padx=10)
        
        self.btn_next = ttk.Button(btn_frame, text="次へ ▶", command=self.next_card)
        self.btn_next.grid(row=0, column=2, padx=10)

    def display_current_card(self):
        """現在のインデックスのデータを画面に反映"""
        item = self.data[self.current_index]
        for key, entry in self.entries.items():
            entry.delete(0, tk.END)
            # URLエンコードされた文字（%20など）のデコードはお好みで調整してください
            val = item.get(key, "-")
            entry.insert(0, str(val))
            
        # ステータス更新
        self.status_label.config(text=f"レコード: {self.current_index + 1} / {len(self.data)}")
        
        # ボタンの有効・無効切り替え
        self.btn_prev.config(state="normal" if self.current_index > 0 else "disabled")
        self.btn_next.config(state="normal" if self.current_index < len(self.data) - 1 else "disabled")

    def save_current_inputs_to_memory(self):
        """現在画面に入力されている内容をメモリ上のデータ配列に一時保存"""
        for key, entry in self.entries.items():
            self.data[self.current_index][key] = entry.get()

    def next_card(self):
        """次のカードへ進む"""
        self.save_current_inputs_to_memory()
        if self.current_index < len(self.data) - 1:
            self.current_index += 1
            self.display_current_card()

    def prev_card(self):
        """前のカードへ戻る"""
        self.save_current_inputs_to_memory()
        if self.current_index > 0:
            self.current_index -= 1
            self.display_current_card()

    def save_data(self):
        """現在の入力を反映し、JSONファイルへ書き出す"""
        self.save_current_inputs_to_memory()
        try:
            with open(JSON_FILE, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=4)
            messagebox.showinfo("成功", f"{JSON_FILE} に変更を保存しました！")
        except Exception as e:
            messagebox.showerror("エラー", f"ファイル保存に失敗しました:\n{e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = JsonCardEditor(root)
    root.mainloop()
