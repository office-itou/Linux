# **PostgreSQLのインストールとテーブルの作成**  
  
## **環境**  
  
### **OSのバージョン**  
``` bash:
master@sv-server:~$ lsb_release --all
No LSB modules are available.
Distributor ID: Debian
Description:    Debian GNU/Linux 12 (bookworm)
Release:        12
Codename:       bookworm
```
  
### **PostgreSQLのバージョン**  
  
``` bash:
master@sv-server:~$ psql --version
psql (PostgreSQL) 17.4 (Debian 17.4-1.pgdg120+2)
```
  
## **インストール**  
  
[PostgreSQL: Downloads](https://www.postgresql.org/download/)を参考に行う  
  
### **debian / ubuntu aptの場合**  
  
``` bash:
sudo apt-get -y install wget ca-certificates lsb-release
sudo install -d /usr/share/postgresql-common/pgdg
sudo wget --output-document=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc https://www.postgresql.org/media/keys/ACCC4CF8.asc
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt '"$(lsb_release -cs 2> /dev/null)"'-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
sudo apt-get update
sudo apt-get -y install postgresql
```
  
### **rhel 9 dnfの場合**  
  
``` bash:
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql17-server
sudo /usr/pgsql-17/bin/postgresql-17-setup initdb
sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17
```
  
## **セットアップ**  
  
### **設定ファイルの変更**  
  
``` bash:
sudo sed -i.org -e '$i host    all             all             192.168.1.0/24          md5' /etc/postgresql/17/main/pg_hba.conf
sudo sed -i.org -e '$i listen_addresses = '\''*'\''' /etc/postgresql/17/main/postgresql.conf
sudo systemctl restart postgresql.service
```
  
IPアドレスの範囲は各自の環境に合わせ変更の事  
  
### **psqlでよく使うオプション**  
  
``` bash:
#  -q, --quiet              run quietly (no messages, only query output)
#  -t, --tuples-only        print rows only
#  -A, --no-align           unaligned table output mode
#  -X, --no-psqlrc          do not read startup file (~/.psqlrc)
```
  
### **psqlで作成するユーザーとデーターベースの情報**  
  
``` bash:
# host name      : sv-server
# database       : mydb
# user(owner)    : master
# password       : master
# user(not owner): dbuser
# password       : dbuser
```
  
### **ユーザーの作成**  
  
``` bash:
sudo -u postgres psql -q   --command="CREATE ROLE master PASSWORD 'master' LOGIN CREATEDB;"
sudo -u postgres psql -q   --command="CREATE ROLE dbuser PASSWORD 'dbuser' LOGIN;"
sudo -u postgres psql -qtA --command="SELECT * FROM pg_user WHERE (usename = 'master') OR (usename = 'dbuser');"
sudo -u postgres psql -qtA --command="SELECT * FROM pg_roles WHERE (rolname = 'master') OR (rolname = 'dbuser');"
```
  
dbuserでSQL実行時にパスワードの入力を省略  
  
PostgreSQL 16.4文書 [34.16. パスワードファイル](https://www.postgresql.jp/document/16/html/libpq-pgpass.html)  
  
``` bash:
echo "*:*:*:master:master" >  ~/.pgpass
echo "*:*:*:dbuser:dbuser" >> ~/.pgpass
chmod 0600 ~/.pgpass
```
  
### **データーベースの作成**  
  
``` bash:
sudo -u postgres psql -q   --command="CREATE DATABASE mydb OWNER master;"
sudo -u postgres psql -qtA --command="SELECT datname FROM pg_database  WHERE datname = 'mydb';"
```
  
### **テーブルの作成**  
  
#### **SQLの実行**  
  
以下のSQLファイルを使いテーブルの作成とデーター登録しdbuserにアクセス権を付与する  
(クライアント環境での作業を想定)  

* [mydb_create_table_distribution.sql](./mydb_create_table_distribution.sql)
* [mydb_create_table_media.sql](./mydb_create_table_media.sql)
  
``` bash:
psql --username=master --host=sv-server --username=master --dbname=mydb --file=./mydb_create_table_distribution.sql
psql --username=master --host=sv-server --username=master --dbname=mydb --file=./mydb_create_table_media.sql
psql --username=master --host=sv-server --username=master --dbname=mydb -qtA --command="SELECT tablename FROM pg_tables WHERE (tablename = 'distribution') OR (pg_catalog.pg_tables.tablename = 'media');"
psql --username=master --host=sv-server --username=master --dbname=mydb -qtA --command="SELECT c.relname, c.relacl FROM pg_class c INNER JOIN pg_namespace ns ON ns.oid = c.relnamespace WHERE (c.relname = 'distribution') OR (c.relname = 'media');"
```
  
#### **テーブルの仕様**  
  
##### テーブル: distribution  
  
| No. | フィールド名 |           属性           |                 内容                 |                                               登録例                                               |
| :-: | :----------- | :----------------------- | :----------------------------------- | :------------------------------------------------------------------------------------------------- |
|   1 | version      | TEXT           NOT NULL  | version                              | debian-12.0                                                                                        |
|   2 | name         | TEXT                     | distribution name                    | Debian                                                                                             |
|   3 | version_id   | TEXT                     | version id                           | 12.0                                                                                               |
|   4 | code_name    | TEXT                     | code name                            | Bookworm                                                                                           |
|   5 | life         | TEXT                     | life                                 | EOL                                                                                                |
|   6 | release      | TEXT                     | release date                         | 2023-06-10                                                                                         |
|   7 | support      | TEXT                     | support end                          | 2026-06-xx                                                                                         |
|   8 | long_term    | TEXT                     | long term end                        | 2028-06-xx                                                                                         |
|   9 | rhel         | TEXT                     | later than rhel                      |                                                                                                    |
|  10 | kerne        | TEXT                     | kernel version                       | 6.1                                                                                                |
|  11 | note         | TEXT                     | note                                 | stable                                                                                             |

##### テーブル: media  
  
| No. | フィールド名 |           属性           |                 内容                 |                                               登録例                                               |
| :-: | :----------- | :----------------------- | :----------------------------------- | :------------------------------------------------------------------------------------------------- |
|   1 | type         | TEXT           NOT NULL  | media type                           | mini.iso                                                                                           |
|   2 | entry_flag   | TEXT           NOT NULL  | [m] menu, [o] output, [else] hidden  | o                                                                                                  |
|   3 | entry_name   | TEXT           NOT NULL  | entry name (unique)                  | debian-mini-12                                                                                     |
|   4 | entry_disp   | TEXT           NOT NULL  | entry name for display               | Debian%2012                                                                                        |
|   5 | version      | TEXT                     | version id                           | debian-12.0                                                                                        |
|   6 | latest       | TEXT                     | latest version                       | debian-12.10.0                                                                                     |
|   7 | release      | TEXT                     | release date                         | 2023-06-10                                                                                         |
|   8 | support      | TEXT                     | support end date                     | 2026-06-xx                                                                                         |
|   9 | web_regexp   | TEXT                     | web file  regexp                     | NULL                                                                                               |
|  10 | web_path     | TEXT                     | web file  path                       | https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso  |
|  11 | web_tstamp   | TIMESTAMP WITH TIME ZONE | web file  time stamp                 | NULL                                                                                               |
|  12 | web_size     | BIGINT                   | web file  file size                  | NULL                                                                                               |
|  13 | web_status   | TEXT                     | web file  download status            | NULL                                                                                               |
|  14 | iso_path     | TEXT                     | iso image file path                  | :_DIRS_ISOS_:/mini-bookworm-amd64.iso                                                              |
|  15 | iso_tstamp   | TIMESTAMP WITH TIME ZONE | iso image time stamp                 | TIMESTAMP 2025-03-10 12:28:07.000                                                                  |
|  16 | iso_size     | BIGINT                   | iso image file size                  | 65011712                                                                                           |
|  17 | iso_volume   | TEXT                     | iso image volume id                  | ISOIMAGE                                                                                           |
|  18 | rmk_path     | TEXT                     | remaster  file path                  | :_DIRS_RMAK_:/mini-bookworm-amd64_preseed.iso                                                      |
|  19 | rmk_tstamp   | TIMESTAMP WITH TIME ZONE | remaster  time stamp                 | TIMESTAMP 2025-03-26 02:24:57.000                                                                  |
|  20 | rmk_size     | BIGINT                   | remaster  file size                  | 99614720                                                                                           |
|  21 | rmk_volume   | TEXT                     | remaster  volume id                  | NULL                                                                                               |
|  22 | ldr_initrd   | TEXT                     | initrd    file path                  | :_DIRS_LOAD_:/initrd.gz                                                                            |
|  23 | ldr_kernel   | TEXT                     | kernel    file path                  | :_DIRS_LOAD_:/linux                                                                                |
|  24 | cfg_path     | TEXT                     | config    file path                  | :_DIRS_CONF_:/preseed/ps_debian_server.cfg                                                         |
|  25 | cfg_tstamp   | TIMESTAMP WITH TIME ZONE | config    time stamp                 | NULL                                                                                               |
|  26 | lnk_path     | TEXT                     | symlink   directory or file path     | :_DIRS_HGFS_:/workspace/image/linux/debian                                                         |
  
### **データーベースの管理**  
  
#### **テーブルの削除**  
  
```bash:
sudo -u postgres psql --dbname=mydb --command="DROP TABLE distribution,media"
```
#### **データーベースの削除**  
  
```bash:
sudo -u postgres psql --command="DROP DATABASE mydb"
```
  
#### **ユーザーの削除**  
  
```bash:
sudo -u postgres psql --command="DROP ROLE dbuser,master"
```
  
## **参考**  
  
[PostgreSQL 16.4文書](https://www.postgresql.jp/document/16/html/)  
[〃 パート VI. リファレンス](https://www.postgresql.jp/document/16/html/reference.html)  
[〃 パート II. SQL言語](https://www.postgresql.jp/document/16/html/sql.html)  
  
[PostgreSQL wiki](https://wiki.postgresql.org/wiki/Main_Page/ja)  
  
