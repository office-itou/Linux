# -----------------------------------------------------------------------------
DIRS_TOPS = /srv
DIRS_TFTP = $(DIRS_TOPS)/tftp
DIRS_BINS = $(DIRS_TOPS)/user/private/bin
DIRS_SRCS = $(DIRS_TOPS)/user/private/src/git/linux/script/py_custom_cmd/src
DIRS_CONF = $(DIRS_TOPS)/user/share/conf
BKUP_DEST = ~/samba_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz
TGET_DIRS = $(DIRS_TFTP) \
            $(DIRS_BINS) \
            $(DIRS_SRCS) \
            $(DIRS_CONF)
BKUP_XCLD = --exclude='__pycache__' \
            --exclude='*.pyc' \
            --exclude='*.pyo' \
            --exclude='.pytest_cache' \
            --exclude='.mypy_cache' \
            --exclude='.coverage' \
            --exclude='build' \
            --exclude='dist' \
            --exclude='*.egg-info' \
            --exclude='.git'
BKUP_REGX = .*/((distribution|media)(.dat)?_[0-9]{14}_[0-9]{6}\.(dat|json)|.*(\.(BAK|bak)|~))

# -----------------------------------------------------------------------------
.PHONY: archive-src clean-backups clean-python clean-build clean-all

# -----------------------------------------------------------------------------
help:
	@echo "利用可能なコマンド一覧:"
	@echo "  make archive-src   - 削除前に現在のソースコードを圧縮保存します"
	@echo "  make clean-backups - データバックアップファイルを削除します"
	@echo "  make clean-python  - Pythonのキャッシュ・ワークファイルを削除します"
	@echo "  make clean-build   - Pythonのビルド成果物（build/dist/egg-info）を削除します"
	@echo "  make clean-all:    - すべてのクリーンアップ処理を行います"

archive-src:
	@echo "--- 削除前に現在のソースコードを圧縮保存します ---"
	@echo "保存先: $(BKUP_DEST)"
	@tar $(BKUP_XCLD) -czf $(BKUP_DEST) $(TGET_DIRS)
	@echo "圧縮保存が完了しました。"

clean-backups:
	@echo "--- データバックアップファイルを削除します ---"
	@find $(TGET_DIRS) -type f -regextype posix-extended -regex "$(BKUP_REGX)" -exec rm -f {} +

clean-python:
	@echo "--- Pythonのキャッシュ・ワークファイルを削除します ---"
	@find $(DIRS_SRCS) -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" \) -exec rm -rf {} +
	@find $(DIRS_SRCS) -type f \( -name "*.pyc" -o -name "*.pyo" -o -name ".coverage" \) -exec rm -f {} +

clean-build:
	@echo "--- Pythonのビルド成果物（build/dist/egg-info）を削除します ---"
	@find $(DIRS_SRCS) -type d \( -name "build" -o -name "dist" -o -name "*.egg-info" \) -exec rm -rf {} +

clean-all: archive-src clean-backups clean-python clean-build
	@echo "すべてのクリーンアップ処理が正常に完了しました。"
