# =============================================================================
# Python プロジェクト管理用 Makefile (自動生成版・最軽量ビルド)
# =============================================================================
# ⚠️ このファイルは Makefile.tmpl からスクリプトによって自動生成されています。
# ⚠️ 直接編集せず、Makefile.tmpl または自動生成スクリプト側を修正してください。
# =============================================================================

PYTHON        = python3
PIP           = pip
PYINSTALLER   = pyinstaller

PROJECT_NAME  := $(notdir $(CURDIR))
VENV_PATH     := $(HOME)/.venv_$(PROJECT_NAME)
ifneq ($(wildcard $(VENV_PATH)/bin/python3),)
    PYTHON    := $(VENV_PATH)/bin/python3
endif
PIP           := $(VENV_PATH)/bin/pip
PYINSTALLER   := $(VENV_PATH)/bin/pyinstaller

PIP_INSTALL   = pyinstaller \
                ruff \
                setuptools \
                pandas \
                pandas-stubs \
                python-gettext \
                fasteners \
                matplotlib \
                beautifulsoup4
APT_INSTALL   = python3-tk \
                python3-aiohttp \
                python3-aiofiles \
                python3-natsort

BUILD_ONEDIR  = --onedir
BUILD_ONEFILE = --onefile
BUILD_ONETYPE = $(BUILD_ONEFILE)

CFG_CUI       = --console
CFG_GUI       = --windowed

MAIN_SCRIPT   = 
EXE_NAME      = 

TARGET_SCRIPT = my_tool.py
TARGET_SCRIPT = creation_of_functions_init_file.py \
                creation_of_the_ipxe_menu.py \
                management_of_shared_data.py \
                test_get_web_file_info.py

TARGET_EXES   = $(TARGET_SCRIPT:.py=)

EXCLUDE_BASE  = --exclude-module="matplotlib" \
                --exclude-module="numpy" \
                --exclude-module="scipy" \
                --exclude-module="PIL" \
                --exclude-module="unittest" \
                --exclude-module="pydoc" \
                --exclude-module="openpyxl" \
                --exclude-module="lxml"

EXCLUDE_CUI   = $(EXCLUDE_BASE) \
                --exclude-module="tkinter" \
                --exclude-module="tkinter.test" \
                --exclude-module="Tkinter" \
                --exclude-module="_tkinter"

EXCLUDE_GUI   = $(EXCLUDE_BASE)

UNIQUE_SUFFIX := $(USER)_$(PROJECT_NAME)
TMP_WORK_DIR  := /tmp/pyinstaller_work_$(UNIQUE_SUFFIX)
WORK_PATH     = --workpath="$(TMP_WORK_DIR)"

SRC_DIR      = /srv/user/private/src/git/linux/script/py_custom_cmd/src
LIBS_DIR     = $(SRC_DIR)/common
UTILS_DIR    = $(LIBS_DIR)/utils
SHARED_DIR   = $(LIBS_DIR)/shared
CURRENT_DIR  = $(CURDIR)
LIB_DIRS     = --paths $(CURRENT_DIR)

.PHONY: help install run build clean ruff-init path-init gen-make $(TARGET_EXES)

help:
	@echo "利用可能なコマンド一覧:"
	@echo "  make gen-make - スクリプトのインポート関係を自動解析し Makefile を再生成します"
	@echo "  make install  - ホームディレクトリ配下に仮想環境を作成しライブラリを揃えます"
	@echo "  make build    - 各ターゲットの個別最適化 (CUI/GUI自動切り替え) で最軽量ビルドを行います"
	@echo "  make clean    - ビルド一時ファイルや仮想環境まで一括でクリーンアップします"

install:
	@echo "📦 仮想環境を作成しています: $(VENV_PATH)"
	@if [ -n "$(VENV_PATH)" ] && [ -d "$(VENV_PATH)" ]; then rm -rf "$(VENV_PATH)"; fi
	python3 -m venv --system-site-packages $(VENV_PATH)
	$(PIP) install --upgrade pip $(PIP_INSTALL)
	$(MAKE) ruff-init
	$(MAKE) path-init

build: $(TARGET_EXES)

# =============================================================================
# 🌟 ターゲットごとの個別最適化設定（自動挿入領域）
# =============================================================================

	# --- my_tool.py --------------------------------------
my_tool                                  :   IMPORT_PKGS     =
my_tool                                  :   EXCLUDE_PKGS    = $(EXCLUDE_CUI)


# =============================================================================
# 💡 共通ビルドルール (静的パターンルール)
# =============================================================================
$(TARGET_EXES): %: %.py
	@mkdir -p $(TMP_WORK_DIR)
	@echo "🚀 ビルド中: $< -> dist/$@ (個別最適化モード)"
	$(PYINSTALLER) $(BUILD_ONETYPE) $($(BUILD_WINTYPE)) $(LIB_DIRS) $(IMPORT_PKGS) $(EXCLUDE_PKGS) $(ADD_DATA_FILE) $(WORK_PATH) --name=$@ $<
	@if [ -d $(TMP_WORK_DIR) ]; then rm -rf $(TMP_WORK_DIR); fi
	@echo "--------------------------------------------------"
	@echo "ビルド成功！ 'dist/$*' が生成されました。"
	@echo "--------------------------------------------------"

clean:
	@rm -rf build dist __pycache__ .pytest_cache *.spec Makefile
	@if [ -n "$(TMP_WORK_DIR)" ] && [ -d "$(TMP_WORK_DIR)" ]; then rm -rf "$(TMP_WORK_DIR)"; fi
	@if [ -n "$(VENV_PATH)" ] && [ -d "$(VENV_PATH)" ]; then rm -rf "$(VENV_PATH)"; fi
	@echo "クリーンアップが完了しました。Makefileも削除されたため必要に応じて make -f Makefile.tmpl gen-make を実行してください。"

gen-make:
	$(PYTHON) generate_hidden_imports.py

ruff-init: LOCAL_PY_FILES   = $(shell find . -maxdepth 1 -name "*.py" ! -name "$(MAIN_SCRIPT)" | sed 's|.*/||;s|\.py$$||')
ruff-init: LOCAL_DIR_FILES  = $(shell find . -maxdepth 1 -type d ! -name "." ! -name "__pycache__" ! -name "build" ! -name "dist" ! -name ".*" | sed 's|.*/||')
ruff-init: RUFF_LOCAL_FOLDERS = $(shell echo '$(LOCAL_PY_FILES) $(LOCAL_DIR_FILES)' | tr -s ' ' | sed 's/^ *//;s/ *$$//;s/ /", "/g;s/^/["/;s/$$/"]/')
ruff-init:
	@echo "ruff.toml を自動生成しています..."
	@echo '[lint]' > ruff.toml
	@echo 'select = ["I", "E", "F"]' >> ruff.toml
	@echo 'ignore = ["EXE002"]' >> ruff.toml
	@echo '' >> ruff.toml
	@echo '[lint.isort]' >> ruff.toml
	@echo 'lines-after-imports = 2' >> ruff.toml
	@echo 'known-local-folder = $(RUFF_LOCAL_FOLDERS)' >> ruff.toml

path-init: USER_SITE_DIR = $(shell $(PYTHON) -m site --user-site)
path-init: PTH_FILE      = $(USER_SITE_DIR)/my_lib.pth
path-init:
	@mkdir -p $(USER_SITE_DIR)
	@echo "$(SRC_DIR)" > $(PTH_FILE)
	@echo "$(LIBS_DIR)" >> $(PTH_FILE)
	@echo "$(UTILS_DIR)" >> $(PTH_FILE)
	@echo "$(SHARED_DIR)" >> $(PTH_FILE)
