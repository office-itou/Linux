# ==============================================================================
# Python プロジェクト管理用 Makefile for Linux (複数ソース分割対応版)
# ==============================================================================

PYTHON       = python
PIP          = pip
PYINSTALLER  = pyinstaller
MAIN_SCRIPT  = app.py
EXE_NAME     = app
IMPORT_PKGS  = tkinter

.PHONY: help install run build clean

help:
	@echo "利用可能なコマンド一覧:"
	@echo "  make install  - 必要なライブラリ（PyInstaller）をインストールします"
	@echo "  make run      - アプリを起動します（開発テスト用）"
	@echo "  make build    - 分割されたソースを統合し、単一の .exe を生成します"
	@echo "  make clean    - ビルド時の一時フォルダやPythonのキャッシュを削除します"

install:
	$(PIP) install pyinstaller

run:
	$(PYTHON) $(MAIN_SCRIPT)

build:
	$(PYINSTALLER) --onefile --noconsole --name=$(EXE_NAME) $(MAIN_SCRIPT)
	# $(PYINSTALLER) --onefile --noconsole --collect-all $(IMPORT_PKGS) --name=$(EXE_NAME) $(MAIN_SCRIPT)
	# $(PYINSTALLER) --onefile --noconsole --hidden-import=$(IMPORT_PKGS) --name=$(EXE_NAME) $(MAIN_SCRIPT)
	@echo "--------------------------------------------------"
	@echo "ビルド成功！ 'dist/$(EXE_NAME).exe' が生成されました。"
	@echo "--------------------------------------------------"

clean:
	@if [ -e build ]; then rm -rf build; fi
	@if [ -e dist ]; then rm -rf dist; fi
	@if [ -e __pycache__ ]; then rm -rf __pycache__; fi
	@if [ -e .pytest_cache ]; then rm -rf .pytest_cache; fi
	@if [ -e *.spec ]; then rm -f *.spec; fi
	@echo "クリーンアップが完了しました。"