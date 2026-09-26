# ==============================================================================
# Python プロジェクト管理用 Makefile (仮想環境 venv 特化・最軽量ビルド版)
# ==============================================================================

PYTHON        = python3
PIP           = pip
PYINSTALLER   = pyinstaller

PROJECT_NAME  := $(notdir $(CURDIR))
VENV_PATH     := $(HOME)/.venv_$(PROJECT_NAME)

# 💡 実行ファイルの参照先をホームディレクトリの仮想環境へ向けます
PYTHON        := $(VENV_PATH)/bin/python3
PYINSTALLER   := $(VENV_PATH)/bin/pyinstaller
PIP           := $(VENV_PATH)/bin/pip
PIP_INSTALL   = pyinstaller \
                ruff \
                setuptools \
                python-gettext \
                fasteners \
                aiohttp \
                aiofiles \
                pandas \
                python-magic \
                bs4 \
                rich \
                natsort
PIP_INSTALL   = pyinstaller \
                pandas \
                pandas-stubs \
                python-gettext \
                fasteners \
                matplotlib
APT_INSTALL   = python3-tk
BUILD_ONEDIR  = --onedir
BUILD_ONEFILE = --onefile
BUILD_TYPE    = $(BUILD_ONEFILE)
MAIN_SCRIPT   = main.py
EXE_NAME      = my_tools
ADD_DATA_FILE = --add-data="ui_definition.json:."
IMPORT_PKGS   = --collect-submodule tkinter
EXCLUDE_PKGS  = --exclude-module="matplotlib" \
                --exclude-module="numpy" \
                --exclude-module="scipy" \
                --exclude-module="PIL" \
                --exclude-module="tkinter.test"
UNIQUE_SUFFIX := $(USER)_$(PROJECT_NAME)
TMP_WORK_DIR  := /tmp/pyinstaller_work_$(UNIQUE_SUFFIX)
WORK_PATH     = --workpath="$(TMP_WORK_DIR)"
#DIST_PATH     = --distpath="$(CURDIR)/dist"

# パス定義
SRC_DIR      = /srv/user/private/src/git/linux/script/py_custom_cmd/src
UTILS_DIR    = $(SRC_DIR)/common/utils
SHARED_DIR   = $(SRC_DIR)/common/shared
CURRENT_DIR  = $(CURDIR)
#LIB_DIRS     = --paths $(CURRENT_DIR):$(UTILS_DIR):$(SHARED_DIR)
LIB_DIRS     = --paths $(CURRENT_DIR)

.PHONY: help install run build clean ruff-init path-init

help:
	@echo "利用可能なコマンド一覧:"
	@echo "  make install  - ホームディレクトリ配下に仮想環境を作成しライブラリを揃えます"
	@echo "  make run      - 離れた場所にある仮想環境のPythonでアプリを起動します"
	@echo "  make build    - 離れた場所にある仮想環境のPyInstallerで最軽量ビルドを行います"
	@echo "  make clean    - ビルド一時ファイルやホームの仮想環境まで一括でクリーンアップします"

# 💡 仮想環境の自動作成とパッケージ導入を完全自動化
install:
	@echo "📦 ホームディレクトリ配下に仮想環境を作成しています: $(VENV_PATH)"
	@if [ -n "$(VENV_PATH)" ] && [ -d "$(VENV_PATH)" ]; then rm -rf "$(VENV_PATH)"; fi
	python3 -m venv --system-site-packages $(VENV_PATH)
	$(PIP) install --upgrade pip $(PIP_INSTALL)
	$(MAKE) ruff-init
	$(MAKE) path-init

run:
	$(PYTHON) $(MAIN_SCRIPT)

build:
	@mkdir -p $(TMP_WORK_DIR)
	# 💡 不要なシステム側パッケージを巻き込まないよう、仮想環境のPyInstallerを駆動
	$(PYINSTALLER) $(BUILD_TYPE) $(LIB_DIRS) $(IMPORT_PKGS) $(EXCLUDE_PKGS) $(ADD_DATA_FILE) $(WORK_PATH) --name=$(EXE_NAME) $(MAIN_SCRIPT)
	@if [ -d $(TMP_WORK_DIR) ]; then rm -rf $(TMP_WORK_DIR); fi
	@echo "--------------------------------------------------"
	@echo "ビルド成功！ 'dist/template' が生成されました。"
	@#if realpath $(CURRENT_DIR) | grep hgfs; then echo "hgfsを含まないディレクトリーで実行して下さい。遅いです。"; fi
	@echo "--------------------------------------------------"

clean:
	@rm -rf build dist __pycache__ .pytest_cache *.spec
	@if [ -n "$(TMP_WORK_DIR)" ] && [ -d "$(TMP_WORK_DIR)" ]; then rm -rf "$(TMP_WORK_DIR)"; fi
	@# 💡 安全装置付きでホームディレクトリの下の仮想環境を丸ごと削除
	@if [ -n "$(VENV_PATH)" ] && [ -d "$(VENV_PATH)" ]; then rm -rf "$(VENV_PATH)"; fi
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
	@echo "これらのディレクトリー/ファイルが実際に有るか確認して下さい"
	@#$(PYTHON) -c "import site; print(site.getsitepackages())"
	@echo "--------------------------------------------------"

# ==============================================================================
# 🌟 依存する apt-get パッケージの簡易リストアップ
# ==============================================================================
check-apt-deps:
	@echo "🔍 ソースコードから必要な apt-get パッケージ候補を抽出しています..."
	@echo "--------------------------------------------------"
	@# 1. ローカルの独自モジュール（my_xxx や gui_xxx）の名前を取得
	@LOCAL_MODS=$$(find . -maxdepth 1 -name "*.py" | sed 's|.*/||;s|\.py$$||'); \
	\
	# 2. .py ファイルから 'import xxx' や 'from xxx import' を抽出し、標準ライブラリや独自モジュールを除外
	echo "📦 [apt-get install] 推奨パッケージ一覧:" ; \
	grep -h -r -E "^(import|from)[[:space:]]+" . --include="*.py" | \
	awk '{print $$2}' | sed 's/\..*//' | sort -u | \
	while read -r mod; do \
		# 標準モジュールやローカルモジュールならスキップ \
		if echo "$$LOCAL_MODS asyncio tkinter datetime os sys threading pathlib" | grep -q -w "$$mod"; then \
			if [ "$$mod" = "tkinter" ]; then echo "  -> python3-tk (Tkinter画面用)"; fi; \
			continue; \
		fi; \
		# それ以外は python3-モジュール名 の形式で出力 \
		echo "  -> python3-$$mod"; \
	done
	@echo "--------------------------------------------------"
