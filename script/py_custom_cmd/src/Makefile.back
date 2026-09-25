# --------------------------------------------------------
# 1. 設定エリア
# --------------------------------------------------------
TARGET_DIRS   = /srv/user/share/conf/ \
                /srv/user/private/src/git/linux/script/py_custom_cmd/
BACKUP_DEST   = ~/samba_backup_$(shell date +%Y%m%d_%H%M%S).tar.gz
BACKUP_REGEX  = .*/((distribution|media)(.dat)?_[0-9]{14}_[0-9]{6}\.(dat|json)|.*(\.(BAK|bak)|~))

# --------------------------------------------------------
# 2. コマンドエリア
# --------------------------------------------------------
.PHONY: archive-src clean-backups clean-python clean-build clean-all

# 【新規】削除前にキャッシュ・ワーク・ビルド成果物「以外」の重要ファイルを圧縮保存する
archive-src:
	@echo "--- 削除前に現在のソースコードを圧縮保存します ---"
	@echo "保存先: $(BACKUP_DEST)"
	@tar --exclude='__pycache__' \
	    --exclude='*.pyc' \
	    --exclude='*.pyo' \
	    --exclude='.pytest_cache' \
	    --exclude='.mypy_cache' \
	    --exclude='.coverage' \
	    --exclude='build' \
	    --exclude='dist' \
	    --exclude='*.egg-info' \
	    -czf $(BACKUP_DEST) $(TARGET_DIRS)
	@echo "圧縮保存が完了しました。"

# ターゲット1: バックアップファイルの削除
clean-backups:
	@echo "--- データバックアップファイルを削除します ---"
	@find $(TARGET_DIRS) -type f -regextype posix-extended -regex "$(BACKUP_REGEX)" -exec rm -f {} +

# ターゲット2: Pythonキャッシュ・ワークの削除
clean-python:
	@echo "--- Pythonのキャッシュ・ワークファイルを削除します ---"
	@find $(TARGET_DIRS) -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" \) -exec rm -rf {} +
	@find $(TARGET_DIRS) -type f \( -name "*.pyc" -o -name "*.pyo" -o -name ".coverage" \) -exec rm -f {} +

# ターゲット3: 【新規】ビルド成果物の削除（ターゲットを分離）
clean-build:
	@echo "--- Pythonのビルド成果物（build/dist/egg-info）を削除します ---"
	@find $(TARGET_DIRS) -type d \( -name "build" -o -name "dist" -o -name "*.egg-info" \) -exec rm -rf {} +

# 総合ターゲット: 自動バックアップ後にすべてをクリーンアップ
# ※ archive-src を最初に実行するように依存関係を設定しています
clean-all: archive-src clean-backups clean-python clean-build
	@echo "すべてのクリーンアップ処理が正常に完了しました。"