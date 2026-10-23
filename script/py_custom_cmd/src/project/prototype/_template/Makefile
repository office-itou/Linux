# ==============================================================================
# Python プロジェクト管理用 Makefile for Linux (複数ソース分割対応版)
# ==============================================================================

PYTHON       = python3
PIP          = pip
PYINSTALLER  = pyinstaller
MAIN_SCRIPT  = main.py
EXE_NAME     = template
IMPORT_PKGS  = tkinter

# 常時使用する固定のパス定義は上部でOK
SRC_DIR      = /srv/user/private/src/git/linux/script/py_custom_cmd/src
UTILS_DIR    = $(SRC_DIR)/common/utils
SHARED_DIR   = $(SRC_DIR)/common/shared

# 💡 修正: shell pwd を毎回実行するのを防ぐため、Makefile組み込み変数 $(CURDIR) に変更
CURRENT_DIR  = $(CURDIR)
LIB_DIRS     = -p $(CURRENT_DIR) -p $(UTILS_DIR) -p $(SHARED_DIR)

.PHONY: help install run build clean ruff-init path-init

help:
	@echo "利用可能なコマンド一覧:"
	@echo "  make install  - 必要なライブラリのインストールと各種初期設定を行います"
	@echo "  make run      - アプリを起動します（開発テスト用）"
	@echo "  make build    - 分割されたソースを統合し、単一の .exe を生成します"
	@echo "  make clean    - ビルド時の一時フォルダやPythonのキャッシュを削除します"

# 💡 修正: path-init も一緒に自動実行されるように連結
install:
	$(PIP) install pyinstaller ruff
	$(MAKE) ruff-init
	$(MAKE) path-init

run:
	@$(PYTHON) -c "import site; print(site.getsitepackages())"
	$(PYTHON) $(MAIN_SCRIPT)

build:
	$(PYINSTALLER) --onefile --noconsole $(LIB_DIRS) --name=$(EXE_NAME) $(MAIN_SCRIPT)
	@echo "--------------------------------------------------"
	@echo "ビルド成功！ 'dist/$(EXE_NAME)' が生成されました。"
	@echo "--------------------------------------------------"

clean:
	@if [ -e build ]; then rm -rf build; fi
	@if [ -e dist ]; then rm -rf dist; fi
	@if [ -e __pycache__ ]; then rm -rf __pycache__; fi
	@if [ -e .pytest_cache ]; then rm -rf .pytest_cache; fi
	@if [ -e *.spec ]; then rm -f *.spec; fi
	@echo "クリーンアップが完了しました。"

# ==============================================================================
# 🌟 ruff-init が呼ばれたときだけ実行されるようにする
# ==============================================================================
ruff-init: LOCAL_PY_FILES   = $(shell find . -maxdepth 1 -name "*.py" ! -name "$(MAIN_SCRIPT)" | sed 's|.*/||;s|\.py$$||')
ruff-init: LOCAL_DIR_FILES  = $(shell find . -maxdepth 1 -type d ! -name "." ! -name "__pycache__" ! -name "build" ! -name "dist" ! -name ".*" | sed 's|.*/||')
ruff-init: RUFF_LOCAL_FOLDERS = $(shell echo '$(LOCAL_PY_FILES) $(LOCAL_DIR_FILES)' | tr -s ' ' | sed 's/^ *//;s/ *$$//;s/ /", "/g;s/^/["/;s/$$/"]/')
ruff-init:
	@echo "ruff.toml を自動生成しています..."
	@echo "検出されたローカルモジュール: $(LOCAL_PY_FILES) $(LOCAL_DIR_FILES)"
	@echo '[lint]' > ruff.toml
	@echo 'select = ["I", "E", "F"]' >> ruff.toml
	@echo '' >> ruff.toml
	@echo '[lint.isort]' >> ruff.toml
	@echo 'lines-after-imports = 2' >> ruff.toml
	@echo 'known-local-folder = $(RUFF_LOCAL_FOLDERS)' >> ruff.toml
	@echo "ruff.toml の生成が完了しました。"

# ==============================================================================
# 🌟 path-init が呼ばれたときだけ実行されるようにする
# ==============================================================================
path-init: USER_SITE_DIR = $(shell $(PYTHON) -m site --user-site)
path-init: PTH_FILE      = $(USER_SITE_DIR)/my_lib.pth
path-init:
	@echo ".pth ファイルを作成してパスを通しています..."
	@mkdir -p $(USER_SITE_DIR)
	@echo "$(UTILS_DIR)" > $(PTH_FILE)
	@echo "$(SHARED_DIR)" >> $(PTH_FILE)
	@echo "以下のパスを登録しました ($(PTH_FILE)):"
	@cat $(PTH_FILE)
	@echo "--------------------------------------------------"
