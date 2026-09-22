"""language functions"""

# --- Python library ----------------------------------------------------------
import locale
import os


# --- my library --------------------------------------------------------------
# -----------------------------------------------------------------------------
def detect_language() -> str:
    try:
        locale.setlocale(locale.LC_ALL, "")
        sys_lang, _ = locale.getlocale()
    except Exception:  # noqa: BLE001
        sys_lang = None
    if not sys_lang:
        sys_lang = os.environ.get("LANG", "")
    if sys_lang:
        return sys_lang.replace("-", "_").split("_")[0].lower()
    return "en"
