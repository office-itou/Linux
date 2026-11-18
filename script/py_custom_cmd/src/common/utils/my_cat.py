# --- Python library ----------------------------------------------------------
import re


# --- my library --------------------------------------------------------------
# =============================================================================
def cat(text: str) -> str:
    cleaned = re.sub(r"^\n|\n$", "", text)
    if not cleaned:
        return ""
    return re.sub(r"^(?:\t+| +(?=\t+))", "", cleaned, flags=re.MULTILINE) + "\n"


# memo: C:\Users\Jun>dir %APPDATA%\Code\User\keybindings.json
# [
#     {
#         "key": "ctrl+t",
#         "command": "editor.action.insertSnippet",
#         "args": {
#             "snippet": "${0:${TM_SELECTED_TEXT/^/\t/gm}}"
#         },
#         "when": "editorTextFocus"
#     }
# ]
