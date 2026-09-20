# utils.py
import locale
import os
from typing import Any


def detect_language() -> str:
    """システム言語の言語コード（例: 'ja', 'en'）を取得します。"""
    try:
        # 現在の設定を変更せず、デフォルトのロケール設定を適用して読み込む
        locale.setlocale(locale.LC_ALL, "")
        sys_lang, _ = locale.getlocale()
    except Exception:  # noqa: BLE001
        sys_lang = None

    # locale から取得できなかった場合のフォールバック
    if not sys_lang:
        sys_lang = os.environ.get("LANG", "")

    # 言語コードの抽出処理 (プレフィックスの取得)
    if sys_lang:
        # "ja_JP.UTF-8" や "ja-JP"、"ja" のいずれにも対応できるよう分割
        return sys_lang.replace("-", "_").split("_")[0].lower()

    return "en"


def clean_value(val: Any) -> str:
    """%20などのURLエンコード文字を半角スペースに置換する共通関数"""
    return str(val).replace("%20", " ")
