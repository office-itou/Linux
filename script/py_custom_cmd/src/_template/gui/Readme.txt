# -----------------------------------------------------------------------------

# 仮想環境を作成して有効化
python3 -m venv myenv
source myenv/bin/activate

# PyInstallerをインストール
pip install pyinstaller

# -----------------------------------------------------------------------------

# 1. 既存の仮想環境を無効化して削除
deactivate
rm -rf myenv

# 2. システムパッケージへのアクセスを許可するフラグ (--system-site-packages) をつけて再作成
python3 -m venv --system-site-packages myenv

# 3. 仮想環境をアクティベート
source myenv/bin/activate

# 4. PyInstallerを再インストールしてビルド
pip install pyinstaller
pyinstaller --onefile app.py

# -----------------------------------------------------------------------------
