**・無人インストール用メディア作成シェル**  
　Debian/Ubuntu/CentOS/Fedora/OpenSUSE対応  
**・Knoppix日本語化メディア作成シェル**  
  
# 【開発環境】  
　・**Debian 11.3.0 64bit版**（他環境未確認、knoppix-live.shを除く）  
　・**220GiBの空き容量があるHDD等**（原本100GiB、作成物120GiB消費）  
  
　当方の開発環境のディスク構成。/homeが作業場所。  
　原本のISOファイルはVMware共有の/mnt/hgfsに置いてシンボリックリンを設定し作業している。  
  
```bash:df -h
master@sv-server:~/mkcd$ df -h
ファイルシス          サイズ  使用  残り 使用% マウント位置
udev                    1.9G     0  1.9G    0% /dev
tmpfs                   390M  2.7M  388M    1% /run
/dev/mapper/vg00-root    18G  5.9G   11G   36% /
tmpfs                   2.0G     0  2.0G    0% /dev/shm
tmpfs                   5.0M  4.0K  5.0M    1% /run/lock
vmhgfs-fuse             764G  624G  140G   82% /mnt/hgfs
/dev/sdb2               463M   99M  340M   23% /boot
/dev/sdb1               487M  6.0M  481M    2% /boot/efi
/dev/mapper/vg01-home   177G  121G   47G   73% /home
tmpfs                   390M   48K  390M    1% /run/user/115
tmpfs                   390M   44K  390M    1% /run/user/1000
master@sv-server:~/mkcd$
```
```bash:lsblk --ascii
master@sv-server:~/mkcd$ lsblk --ascii
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda             8:0    0  180G  0 disk
`-sda1          8:1    0  180G  0 part
  `-vg01-home 254:2    0  180G  0 lvm  /home
sdb             8:16   0   20G  0 disk
|-sdb1          8:17   0  487M  0 part /boot/efi
|-sdb2          8:18   0  488M  0 part /boot
`-sdb3          8:19   0   19G  0 part
  |-vg00-swap 254:0    0  976M  0 lvm  [SWAP]
  `-vg00-root 254:1    0 18.1G  0 lvm  /
sr0            11:0    1  3.7G  0 rom
master@sv-server:~/mkcd$
```
  
# 【実行方法】  
　・**sudo ./dist_remaster_dvd.sh** [OPTION]... [NUMBER]...  
　・**sudo ./dist_remaster_mini.sh** [OPTION]... [NUMBER]...  
　・**sudo ./dist_remaster_net.sh** [OPTION]... [NUMBER]...  
　・**sudo ./live-custom.sh** [OPTION]... [NUMBER]...  
　・**sudo ./knoppix-live.sh**  
  
| OPTION      | 説明                                 |
| ----------- | ------------------------------------ |
| -h, --help  | このヘルプ                           |
| -i, --init  | 初期設定                             |
| -l, --log   | ログ出力（メディア作成時）           |
| -d, --debug | デバッグモード（未実装）             |
| -s, --skip  | サブシェル処理スキップ               |
| -a, --all   | 全登録リスト処理                     |
  
| NUMBER      | 説明
| ----------- | ------------------------------------ |
|             | 処理する登録リスト番号               |
|             | ブレース展開可（重複チェック未実装） |
  
　＜注意＞  
　・引数省略時はメニュー画面で指定(knoppix-live.shを除く)  
　・必要パッケージは初回実行時に本シェルが導入  
  
【メディア作成シェル】  
| ファイル名         | 機能                  |
| ------------------ | --------------------- |
| [dist_remaster.sh](https://github.com/office-itou/Linux/blob/master/installer/source/dist_remaster.sh)    | メディア作成シェル |
| [knoppix-live.sh](https://github.com/office-itou/Linux/blob/master/installer/source//knoppix-live.sh)    | Knoppix日本語化用 |
  
　・ファイル名によって処理内容が変わるのでリンクを利用
```bash:
ln -s ./dist_remaster.sh ./dist_remaster_dvd.sh     # DVDイメージ用
ln -s ./dist_remaster.sh ./dist_remaster_mini.sh    # miniイメージ用
ln -s ./dist_remaster.sh ./dist_remaster_net.sh     # Netイメージ用
ln -s ./dist_remaster.sh ./live-custom.sh           # Liveイメージ用
chmod +x *.sh
```
  
# 【無人インストール定義ファイル】  
| ファイル名              | 機能     |
| ----------------------- | -------- |
| [preseed_debian.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/preseed_debian.cfg)      | debian用 |
| [preseed_ubuntu.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/preseed_ubuntu.cfg)      | ubuntu用 |
| [kickstart_common.cfg](https://github.com/office-itou/Linux/blob/master/installer/source/kickstart_common.cfg)    | CentOS系 |
| [yast_opensuse.xml](https://github.com/office-itou/Linux/blob/master/installer/source/yast_opensuse.xml) | OpenSUSE用 |
| [nocloud-ubuntu-user-data](https://github.com/office-itou/Linux/blob/master/installer/source/nocloud-ubuntu-user-data) | ubuntu用nocloud |
  
# 【インストール補助作業シェル】  
| ファイル名              | 機能                |
| ----------------------- | ------------------- |
| [install.sh](https://github.com/office-itou/Linux/blob/master/installer/source/install.sh)              | インストール作業用  |
| [addusers.sh](https://github.com/office-itou/Linux/blob/master/installer/source/addusers.sh)             | ユーザー登録用      |
| [addusers_txt_maker.sh](https://github.com/office-itou/Linux/blob/master/installer/source/addusers_txt_maker.sh)   | 登録ユーザー取得用  |
| [cloud_preseed.sh](https://github.com/office-itou/Linux/blob/master/installer/source/cloud_preseed.sh)   | preseed.cfg→user-data変換  |
  
# 【メニュー画面】  
**・文字色について**  
| 属性 | 説明                                 |
| :--: | ------------------------------------ |
| 赤色 | 通信エラー（リンク先消失等）         |
| 白色 | 作成ファイル最新（ダウンロード不要） |
| 緑色 | 作成ファイル無し（ファイル作成対象） |
| 黄色 | 作成ファイル在り（ファイル作成対象） |
| 水色 | 原本ファイル無し（ファイル作成対象） |
| 反転 | 原本ダウンロード（ファイル作成対象） |
  
**・スクリーンショット**  
| 作業内容              | スクリーンショット                                                              |
| --------------------- | :-----------------------------------------------------------------------------: |
| dist_remaster_dvd.sh  | ![dist_remaster_dvd.sh.jpg](https://github.com/office-itou/Linux/raw/master/installer/picture/dist_remaster_dvd.sh.jpg) |
| dist_remaster_mini.sh | ![dist_remaster_mini.sh.jpg](https://github.com/office-itou/Linux/raw/master/installer/picture/dist_remaster_mini.sh.jpg) |
| dist_remaster_net.sh  | ![dist_remaster_net.sh.jpg](https://github.com/office-itou/Linux/raw/master/installer/picture/dist_remaster_net.sh.jpg) |
| live-custom.sh        | ![dist_remaster_net.sh.jpg](https://github.com/office-itou/Linux/raw/master/installer/picture/live-custom.sh.jpg) |
  
# 【ダウンロード用コピペ】  
  
```bash:
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/addusers.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/addusers_txt_maker.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/cloud_preseed.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/dist_remaster.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/install.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/kickstart_common.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/knoppix-live.sh"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/live-debian_config.conf"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/nocloud-ubuntu-meta-data"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/nocloud-ubuntu-user-data"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_debian.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/preseed_ubuntu.cfg"
wget "https://raw.githubusercontent.com/office-itou/Linux/master/installer/source/yast_opensuse.xml"
# -----------------------------------------------------------------------------
ln -s ./dist_remaster.sh ./dist_remaster_dvd.sh     # DVDイメージ用
ln -s ./dist_remaster.sh ./dist_remaster_mini.sh    # miniイメージ用
ln -s ./dist_remaster.sh ./dist_remaster_net.sh     # Netイメージ用
ln -s ./dist_remaster.sh ./live-custom.sh           # Liveイメージ用
# -----------------------------------------------------------------------------
chmod +x *.sh
```
  
