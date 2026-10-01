# --- python library ----------------------------------------------------------
from datetime import datetime
from typing import Any


# --- my library --------------------------------------------------------------
# ruff: isort: off
from common.utils import (
    debug_logger,
)


# ruff: isort: on
# =============================================================================
@debug_logger
def safe_format(value: Any, fmt_str: str | None) -> str:
    """
    値を安全にフォーマット文字列へ適用するヘルパー関数。
    ISO 8601形式 ("2024-08-27T06:14:31+00:00") の場合は、
    実行環境（PC）のローカルタイムゾーンに自動変換してから整形します。
    """
    if value is None:
        return ""
    if not fmt_str:
        return str(value)
    try:
        # 1. 既に datetime オブジェクト、または数値の場合はそのままフォーマット適用
        return fmt_str.format(value)
    except (TypeError, ValueError):
        # 2. 文字列型の日付が渡されていて、日付フォーマットが指定されている場合
        if isinstance(value, str) and "%" in fmt_str:
            if "T" in value:
                try:
                    # ISO 8601 形式の文字列を datetime に変換
                    # （この時点で UTC などの情報を持つ）
                    dt = datetime.fromisoformat(value)
                    # 💡 実行環境（ローカルPC）のタイムゾーンへ動的に変換
                    # dt.tzinfo が存在する場合のみ変換し、
                    # 存在しない場合はそのまま処理します
                    if dt.tzinfo is not None:
                        dt = dt.astimezone()
                    return fmt_str.format(dt)
                except ValueError:
                    pass
            # 従来のフォーマットに対するフォールバック（タイムゾーン情報がない文字列用）
            for parse_fmt in (
                "%Y-%m-%d %H:%M:%S",
                "%Y/%m/%d %H:%M:%S",
                "%Y-%m-%d",
                "%Y/%m/%d",
            ):
                try:
                    dt = datetime.strptime(value, parse_fmt)
                    return fmt_str.format(dt)
                except ValueError:
                    continue
        # 3. どうしても適用できない場合はフォールバックとして通常の文字列変換
        return str(value)
