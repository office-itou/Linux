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
sudo apt-get -y install wget ca-certificates
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
  
### **psqlでよく使うオプション**  
  
``` bash:
#  -q, --quiet              run quietly (no messages, only query output)
#  -t, --tuples-only        print rows only
#  -A, --no-align           unaligned table output mode
#  -X, --no-psqlrc          do not read startup file (~/.psqlrc)
```
  
### **psqlで作成するユーザーとデーターベースの情報**  
  
``` bash:
# user(owner): master
# password   : master
# database   : mydb
```
  
### **ユーザーの作成**  
  
``` bash:
sudo -u postgres psql -q   --command="CREATE USER master PASSWORD 'master' CREATEDB;"
sudo -u postgres psql -qtA --command="SELECT USENAME FROM pg_user;"
```
  
#### 登録されているユーザーの確認  
  
``` bash:
postgres
master
```
  
### **データーベースの作成**  
  
``` bash:
sudo -u postgres psql -q   --command="CREATE DATABASE mydb OWNER master;"
sudo -u postgres psql -qtA --command="SELECT datname FROM pg_database;"
```
  
#### 登録されているデーターベースの確認  
  
``` bash:
postgres
mydb
template1
template0
```
  
### **テーブルの作成**  
  
#### **テーブルの仕様**  
  
##### テーブル: distribution  
  
| No. | フィールド名 |           属性           |                 内容                 |                                               登録例                                               |
| :-: | :----------- | :----------------------- | :----------------------------------- | :------------------------------------------------------------------------------------------------- |
|   1 | version      | TEXT           NOT NULL  | version                              | debian-12.0                                                                                        |
|   2 | name         | TEXT           NOT NULL  | distribution name                    | Debian                                                                                             |
|   3 | version_id   | TEXT           NOT NULL  | version id                           | 12.0                                                                                               |
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
  
#### **SQLの実行**  
  
##### テーブル: distribution  
  
``` bash:
psql      --dbname=mydb --command="
DROP TABLE if exists distribution CASCADE;
CREATE TABLE distribution (
  version    TEXT           NOT NULL
, name       TEXT           NOT NULL
, version_id TEXT           NOT NULL
, code_name  TEXT
, life       TEXT
, release    TEXT
, support    TEXT
, long_term  TEXT
, rhel       TEXT
, kerne      TEXT
, note       TEXT
, CONSTRAINT distribution_PKC PRIMARY KEY (version)
);
"
```
  
##### テーブル: media  
  
``` bash:
psql      --dbname=mydb --command="
DROP TABLE if exists media CASCADE;
CREATE TABLE media (
  type       TEXT           NOT NULL
, entry_flag TEXT           NOT NULL
, entry_name TEXT           NOT NULL
, entry_disp TEXT           NOT NULL
, version    TEXT
, latest     TEXT
, release    TEXT
, support    TEXT
, web_regexp TEXT
, web_path   TEXT
, web_tstamp TIMESTAMP WITH TIME ZONE
, web_size   BIGINT
, web_status TEXT
, iso_path   TEXT
, iso_tstamp TIMESTAMP WITH TIME ZONE
, iso_size   BIGINT
, iso_volume TEXT
, rmk_path   TEXT
, rmk_tstamp TIMESTAMP WITH TIME ZONE
, rmk_size   BIGINT
, rmk_volume TEXT
, ldr_initrd TEXT
, ldr_kernel TEXT
, cfg_path   TEXT
, cfg_tstamp TIMESTAMP WITH TIME ZONE
, lnk_path   TEXT
, CONSTRAINT media_PKC PRIMARY KEY (type,entry_flag,entry_name,entry_disp)
);
"
```
  
### **データーの登録**  
  
空のテーブルに登録する場合  
  
#### **SQLの実行**  
  
##### テーブル: distribution  
  
``` bash:
psql      --dbname=mydb --command="
INSERT INTO public.distribution(version,name,version_id,code_name,life,release,support,long_term,rhel,kerne,note) values 
    ('debian-1.1','Debian','1.1','Buzz','EOL','1996-06-17',NULL,NULL,NULL,NULL,NULL)
  , ('debian-1.2','Debian','1.2','Rex','EOL','1996-12-12',NULL,NULL,NULL,NULL,NULL)
  , ('debian-1.3','Debian','1.3','Bo','EOL','1997-06-05',NULL,NULL,NULL,NULL,NULL)
  , ('debian-2.0','Debian','2.0','Hamm','EOL','1998-07-24',NULL,NULL,NULL,NULL,NULL)
  , ('debian-2.1','Debian','2.1','Slink','EOL','1999-03-09','2000-10-30',NULL,NULL,NULL,NULL)
  , ('debian-2.2','Debian','2.2','Potato','EOL','2000-08-15','2003-06-30',NULL,NULL,NULL,NULL)
  , ('debian-3.0','Debian','3.0','Woody','EOL','2002-07-19','2006-06-30',NULL,NULL,NULL,NULL)
  , ('debian-3.1','Debian','3.1','Sarge','EOL','2005-06-06','2008-03-31',NULL,NULL,NULL,NULL)
  , ('debian-4.0','Debian','4.0','Etch','EOL','2007-04-08','2010-02-15',NULL,NULL,NULL,NULL)
  , ('debian-5.0','Debian','5.0','Lenny','EOL','2009-02-14','2012-02-06',NULL,NULL,NULL,NULL)
  , ('debian-6.0','Debian','6.0','Squeeze','EOL','2011-02-06','2014-05-31','2016-02-29',NULL,NULL,NULL)
  , ('debian-7.0','Debian','7.0','Wheezy','EOL','2013-05-04','2016-04-25','2018-05-31',NULL,NULL,NULL)
  , ('debian-8.0','Debian','8.0','Jessie','EOL','2015-04-25','2018-06-17','2020-06-30',NULL,NULL,NULL)
  , ('debian-9.0','Debian','9.0','Stretch','EOL','2017-06-17','2020-07-18','2022-06-30',NULL,NULL,NULL)
  , ('debian-10.0','Debian','10.0','Buster','EOL','2019-07-06','2022-09-10','2024-06-30',NULL,NULL,'oldoldstable')
  , ('debian-11.0','Debian','11.0','Bullseye','LTS','2021-08-14','2024-08-15','2026-08-31',NULL,'5.10','oldstable')
  , ('debian-12.0','Debian','12.0','Bookworm',NULL,'2023-06-10','2026-06-xx','2028-06-xx',NULL,'6.1','stable')
  , ('debian-13.0','Debian','13.0','Trixie',NULL,'2025-xx-xx','20xx-xx-xx','20xx-xx-xx',NULL,NULL,'testing')
  , ('debian-14.0','Debian','14.0','Forky',NULL,'2027-xx-xx','20xx-xx-xx','20xx-xx-xx',NULL,NULL,NULL)
  , ('debian-15.0','Debian','15.0','Duke',NULL,'20xx-xx-xx','20xx-xx-xx','20xx-xx-xx',NULL,NULL,NULL)
  , ('debian-testing','Debian','testing','Testing',NULL,'20xx-xx-xx','20xx-xx-xx','20xx-xx-xx',NULL,NULL,'testing')
  , ('debian-sid','Debian','sid','SID',NULL,'20xx-xx-xx','20xx-xx-xx','20xx-xx-xx',NULL,NULL,'sid')
  , ('ubuntu-4.10','Ubuntu','4.10','Warty Warthog','EOL','2004-10-20','2006-04-30',NULL,NULL,'2.6.8',NULL)
  , ('ubuntu-5.04','Ubuntu','5.04','Hoary Hedgehog','EOL','2005-04-08','2006-10-31',NULL,NULL,'2.6.10',NULL)
  , ('ubuntu-5.10','Ubuntu','5.10','Breezy Badger','EOL','2005-10-12','2007-04-13',NULL,NULL,'2.6.12',NULL)
  , ('ubuntu-6.06','Ubuntu','6.06','Dapper Drake','EOL','2006-06-01','2009-07-14','2011-06-01',NULL,'2.6.15',NULL)
  , ('ubuntu-6.10','Ubuntu','6.10','Edgy Eft','EOL','2006-10-26','2008-04-25',NULL,NULL,'2.6.17',NULL)
  , ('ubuntu-7.04','Ubuntu','7.04','Feisty Fawn','EOL','2007-04-19','2008-10-19',NULL,NULL,'2.6.20',NULL)
  , ('ubuntu-7.10','Ubuntu','7.10','Gutsy Gibbon','EOL','2007-10-18','2009-04-18',NULL,NULL,'2.6.22',NULL)
  , ('ubuntu-8.04','Ubuntu','8.04','Hardy Heron','EOL','2008-04-24','2011-05-12','2013-05-09',NULL,'2.6.24',NULL)
  , ('ubuntu-8.10','Ubuntu','8.10','Intrepid Ibex','EOL','2008-10-30','2010-04-30',NULL,NULL,'2.6.27',NULL)
  , ('ubuntu-9.04','Ubuntu','9.04','Jaunty Jackalope','EOL','2009-04-23','2010-10-23',NULL,NULL,'2.6.28',NULL)
  , ('ubuntu-9.10','Ubuntu','9.10','Karmic Koala','EOL','2009-10-29','2011-04-30',NULL,NULL,'2.6.31',NULL)
  , ('ubuntu-10.04','Ubuntu','10.04','Lucid Lynx','EOL','2010-04-29','2013-05-09','2015-04-30',NULL,'2.6.32',NULL)
  , ('ubuntu-10.10','Ubuntu','10.10','Maverick Meerkat','EOL','2010-10-10','2012-04-10',NULL,NULL,'2.6.35',NULL)
  , ('ubuntu-11.04','Ubuntu','11.04','Natty Narwhal','EOL','2011-04-28','2012-10-28',NULL,NULL,'2.6.38',NULL)
  , ('ubuntu-11.10','Ubuntu','11.10','Oneiric Ocelot','EOL','2011-10-13','2013-05-09',NULL,NULL,'3.0',NULL)
  , ('ubuntu-12.04','Ubuntu','12.04','Precise Pangolin','EOL','2012-04-26','2017-04-28','2019-04-26',NULL,'3.2',NULL)
  , ('ubuntu-12.10','Ubuntu','12.10','Quantal Quetzal','EOL','2012-10-18','2014-05-16',NULL,NULL,'3.5',NULL)
  , ('ubuntu-13.04','Ubuntu','13.04','Raring Ringtail','EOL','2013-04-25','2014-01-27',NULL,NULL,'3.8',NULL)
  , ('ubuntu-13.10','Ubuntu','13.10','Saucy Salamander','EOL','2013-10-17','2014-07-17',NULL,NULL,'3.11',NULL)
  , ('ubuntu-14.04','Ubuntu','14.04','Trusty Tahr','EOL','2014-04-17','2019-04-25','2024-04-25',NULL,'3.13',NULL)
  , ('ubuntu-14.10','Ubuntu','14.10','Utopic Unicorn','EOL','2014-10-23','2015-07-23',NULL,NULL,'3.16',NULL)
  , ('ubuntu-15.04','Ubuntu','15.04','Vivid Vervet','EOL','2015-04-23','2016-02-04',NULL,NULL,'3.19',NULL)
  , ('ubuntu-15.10','Ubuntu','15.10','Wily Werewolf','EOL','2015-10-22','2016-07-28',NULL,NULL,'4.2',NULL)
  , ('ubuntu-16.04','Ubuntu','16.04','Xenial Xerus','LTS','2016-04-21','2021-04-30','2026-04-23',NULL,'4.4',NULL)
  , ('ubuntu-16.10','Ubuntu','16.10','Yakkety Yak','EOL','2016-10-13','2017-07-20',NULL,NULL,'4.8',NULL)
  , ('ubuntu-17.04','Ubuntu','17.04','Zesty Zapus','EOL','2017-04-13','2018-01-13',NULL,NULL,'4.10',NULL)
  , ('ubuntu-17.10','Ubuntu','17.10','Artful Aardvark','EOL','2017-10-19','2018-07-19',NULL,NULL,'4.13',NULL)
  , ('ubuntu-18.04','Ubuntu','18.04','Bionic Beaver','LTS','2018-04-26','2023-05-31','2028-04-26',NULL,'4.15',NULL)
  , ('ubuntu-18.10','Ubuntu','18.10','Cosmic Cuttlefish','EOL','2018-10-18','2019-07-18',NULL,NULL,'4.18',NULL)
  , ('ubuntu-19.04','Ubuntu','19.04','Disco Dingo','EOL','2019-04-18','2020-01-23',NULL,NULL,'5.0',NULL)
  , ('ubuntu-19.10','Ubuntu','19.10','Eoan Ermine','EOL','2019-10-17','2020-07-17',NULL,NULL,'5.3',NULL)
  , ('ubuntu-20.04','Ubuntu','20.04','Focal Fossa',NULL,'2020-04-23','2025-05-29','2030-04-23',NULL,'5.4',NULL)
  , ('ubuntu-20.10','Ubuntu','20.10','Groovy Gorilla','EOL','2020-10-22','2021-07-22',NULL,NULL,'5.8',NULL)
  , ('ubuntu-21.04','Ubuntu','21.04','Hirsute Hippo','EOL','2021-04-22','2022-01-20',NULL,NULL,'5.11',NULL)
  , ('ubuntu-21.10','Ubuntu','21.10','Impish Indri','EOL','2021-10-14','2022-07-14',NULL,NULL,'5.13',NULL)
  , ('ubuntu-22.04','Ubuntu','22.04','Jammy Jellyfish',NULL,'2022-04-21','2027-06-01','2032-04-21',NULL,'5.15 or 5.17',NULL)
  , ('ubuntu-22.10','Ubuntu','22.10','Kinetic Kudu','EOL','2022-10-20','2023-07-20',NULL,NULL,'5.19',NULL)
  , ('ubuntu-23.04','Ubuntu','23.04','Lunar Lobster','EOL','2023-04-20','2024-01-25',NULL,NULL,'6.2',NULL)
  , ('ubuntu-23.10','Ubuntu','23.10','Mantic Minotaur','EOL','2023-10-12','2024-07-11',NULL,NULL,'6.5',NULL)
  , ('ubuntu-24.04','Ubuntu','24.04','Noble Numbat',NULL,'2024-04-25','2029-05-31','2034-04-25',NULL,'6.8',NULL)
  , ('ubuntu-24.10','Ubuntu','24.10','Oracular Oriole',NULL,'2024-10-10','2025-07-xx',NULL,NULL,'6.11',NULL)
  , ('ubuntu-25.04','Ubuntu','25.04','Plucky Puffin',NULL,'2025-04-17','2026-01-xx',NULL,NULL,'6.14',NULL)
  , ('fedora-27','Fedora','27',NULL,'EOL','2017-11-14','2018-11-30',NULL,NULL,'4.13',NULL)
  , ('fedora-28','Fedora','28',NULL,'EOL','2018-05-01','2019-05-28',NULL,NULL,'4.16',NULL)
  , ('fedora-29','Fedora','29',NULL,'EOL','2018-10-30','2019-11-26',NULL,NULL,'4.18',NULL)
  , ('fedora-30','Fedora','30',NULL,'EOL','2019-04-30','2020-05-26',NULL,NULL,'5.0',NULL)
  , ('fedora-31','Fedora','31',NULL,'EOL','2019-10-29','2020-11-24',NULL,NULL,'5.3',NULL)
  , ('fedora-32','Fedora','32',NULL,'EOL','2020-04-28','2021-05-25',NULL,NULL,'5.6',NULL)
  , ('fedora-33','Fedora','33',NULL,'EOL','2020-10-27','2021-11-30',NULL,NULL,'5.8',NULL)
  , ('fedora-34','Fedora','34',NULL,'EOL','2021-04-27','2022-06-07',NULL,NULL,'5.11',NULL)
  , ('fedora-35','Fedora','35',NULL,'EOL','2021-11-02','2022-12-13',NULL,NULL,'5.14',NULL)
  , ('fedora-36','Fedora','36',NULL,'EOL','2022-05-10','2023-05-16',NULL,NULL,'5.17',NULL)
  , ('fedora-37','Fedora','37',NULL,'EOL','2022-11-15','2023-12-05',NULL,NULL,'6.0',NULL)
  , ('fedora-38','Fedora','38',NULL,'EOL','2023-04-18','2024-05-21',NULL,NULL,'6.2',NULL)
  , ('fedora-39','Fedora','39',NULL,'EOL','2023-11-07','2024-11-26',NULL,NULL,'6.5',NULL)
  , ('fedora-40','Fedora','40',NULL,NULL,'2024-04-23','2025-05-28',NULL,NULL,'6.8',NULL)
  , ('fedora-41','Fedora','41',NULL,NULL,'2024-10-29','2025-11-19',NULL,NULL,'6.11',NULL)
  , ('fedora-42','Fedora','42',NULL,NULL,'2025-04-15','2026-05-13',NULL,NULL,'6.14',NULL)
  , ('fedora-43','Fedora','43',NULL,NULL,'2025-11-11','2026-12-02',NULL,NULL,NULL,NULL)
  , ('centos-7.4','CentOS','7.4-1708',NULL,'EOL','2017-09-14',NULL,NULL,'2017-08-01','3.10.0-693',NULL)
  , ('centos-7.5','CentOS','7.5-1804',NULL,'EOL','2018-05-10',NULL,NULL,'2018-04-10','3.10.0-862',NULL)
  , ('centos-7.6','CentOS','7.6-1810',NULL,'EOL','2018-12-03',NULL,NULL,'2018-10-30','3.10.0-957',NULL)
  , ('centos-7.7','CentOS','7.7-1908',NULL,'EOL','2019-09-17',NULL,NULL,'2019-08-06','3.10.0-1062',NULL)
  , ('centos-7.8','CentOS','7.8-2003',NULL,'EOL','2020-04-27',NULL,NULL,'2020-03-30','3.10.0-1127',NULL)
  , ('centos-7.9','CentOS','7.9-2009',NULL,'EOL','2020-11-12','2024-06-30',NULL,'2020-09-29','3.10.0-1160',NULL)
  , ('centos-8.0','CentOS','8.0-1905',NULL,'EOL','2019-09-24',NULL,NULL,'2019-05-07','4.18.0-80',NULL)
  , ('centos-stream-8','CentOS Stream','8',NULL,'EOL','2019-09-24','2024-05-31',NULL,NULL,'4.18.0',NULL)
  , ('centos-8.1','CentOS','8.1-1911',NULL,'EOL','2020-01-15',NULL,NULL,'2019-11-05','4.18.0-147',NULL)
  , ('centos-8.2','CentOS','8.2-2004',NULL,'EOL','2020-06-15',NULL,NULL,'2020-04-28','4.18.0-193',NULL)
  , ('centos-8.3','CentOS','8.3-2011',NULL,'EOL','2020-11-03',NULL,NULL,'2020-12-07','4.18.0-240',NULL)
  , ('centos-8.4','CentOS','8.4-2015',NULL,'EOL','2021-06-03',NULL,NULL,'2021-05-18','4.18.0-305',NULL)
  , ('centos-8.5','CentOS','8.5-2111',NULL,'EOL','2021-11-16','2021-12-31',NULL,'2021-11-09','4.18.0-348',NULL)
  , ('centos-stream-9','CentOS Stream','9',NULL,NULL,'2021-12-03','2027-05-31',NULL,NULL,'5.14.0',NULL)
  , ('centos-stream-10','CentOS Stream','10','Coughlan',NULL,'2024-12-12','2030-01-01',NULL,NULL,'6.12.0',NULL)
  , ('almalinux-8.3','AlmaLinux','8.3',NULL,'EOL','2021-03-30',NULL,NULL,'2020-11-03','4.18.0-240',NULL)
  , ('almalinux-8.4','AlmaLinux','8.4',NULL,'EOL','2021-05-26',NULL,NULL,'2021-05-18','4.18.0-305',NULL)
  , ('almalinux-8.5','AlmaLinux','8.5',NULL,'EOL','2021-11-12',NULL,NULL,'2021-11-09','4.18.0-348',NULL)
  , ('almalinux-8.6','AlmaLinux','8.6',NULL,'EOL','2022-05-12',NULL,NULL,'2022-05-10','4.18.0-372',NULL)
  , ('almalinux-8.7','AlmaLinux','8.7',NULL,'EOL','2022-11-10',NULL,NULL,'2022-11-09','4.18.0-425',NULL)
  , ('almalinux-8.8','AlmaLinux','8.8',NULL,'EOL','2023-05-18',NULL,NULL,'2023-05-16','4.18.0-477',NULL)
  , ('almalinux-8.9','AlmaLinux','8.9',NULL,'EOL','2023-11-21',NULL,NULL,'2023-11-14','4.18.0-513.5.1',NULL)
  , ('almalinux-8.10','AlmaLinux','8.10','Cerulean Leopard',NULL,'2024-05-28',NULL,NULL,'2024-05-22','4.18.0-553',NULL)
  , ('almalinux-9.0','AlmaLinux','9.0',NULL,'EOL','2022-05-26',NULL,NULL,'2022-05-17','5.14.0-70.13.1',NULL)
  , ('almalinux-9.1','AlmaLinux','9.1',NULL,'EOL','2022-11-17',NULL,NULL,'2022-11-15','5.14.0-162.6.1',NULL)
  , ('almalinux-9.2','AlmaLinux','9.2',NULL,'EOL','2023-05-10',NULL,NULL,'2023-05-10','5.14.0-284.11.1',NULL)
  , ('almalinux-9.3','AlmaLinux','9.3',NULL,'EOL','2023-11-13',NULL,NULL,'2023-11-07','5.14.0-362.8.1',NULL)
  , ('almalinux-9.4','AlmaLinux','9.4',NULL,'EOL','2024-05-06',NULL,NULL,'2024-04-30','5.14.0-427.13.1',NULL)
  , ('almalinux-9.5','AlmaLinux','9.5','Teal Serval',NULL,'2024-11-18',NULL,NULL,'2024-11-13','5.14.0-503.11.1',NULL)
  , ('rockylinux-8.3','Rocky Linux','8.3',NULL,'EOL','2021-05-01',NULL,NULL,'2020-11-03','4.18.0-240',NULL)
  , ('rockylinux-8.4','Rocky Linux','8.4',NULL,'EOL','2021-06-21',NULL,NULL,'2021-05-18','4.18.0-305',NULL)
  , ('rockylinux-8.5','Rocky Linux','8.5',NULL,'EOL','2021-11-15',NULL,NULL,'2021-11-09','4.18.0-348',NULL)
  , ('rockylinux-8.6','Rocky Linux','8.6',NULL,'EOL','2022-05-16',NULL,NULL,'2022-05-10','4.18.0-372.9.1',NULL)
  , ('rockylinux-8.7','Rocky Linux','8.7',NULL,'EOL','2022-11-14',NULL,NULL,'2022-11-09','4.18.0-425.3.1',NULL)
  , ('rockylinux-8.8','Rocky Linux','8.8',NULL,'EOL','2023-05-20',NULL,NULL,'2023-05-16','4.18.0-477.10.1',NULL)
  , ('rockylinux-8.9','Rocky Linux','8.9',NULL,'EOL','2023-11-22',NULL,NULL,'2023-11-14','4.18.0-513.5.1',NULL)
  , ('rockylinux-8.10','Rocky Linux','8.10','Green Obsidian',NULL,'2024-05-30',NULL,NULL,'2024-05-22','4.18.0-553',NULL)
  , ('rockylinux-9.0','Rocky Linux','9.0',NULL,'EOL','2022-07-14',NULL,NULL,'2022-05-17','5.14.0-70.13.1',NULL)
  , ('rockylinux-9.1','Rocky Linux','9.1',NULL,'EOL','2022-11-26',NULL,NULL,'2022-11-15','5.14.0-162.6.1',NULL)
  , ('rockylinux-9.2','Rocky Linux','9.2',NULL,'EOL','2023-05-16',NULL,NULL,'2023-05-10','5.14.0-284.11.1',NULL)
  , ('rockylinux-9.3','Rocky Linux','9.3',NULL,'EOL','2023-11-20',NULL,NULL,'2023-11-07','5.14.0-362.8.1',NULL)
  , ('rockylinux-9.4','Rocky Linux','9.4',NULL,'EOL','2024-05-09',NULL,NULL,'2024-04-30','5.14.0-427.13.1',NULL)
  , ('rockylinux-9.5','Rocky Linux','9.5','Blue Onyx',NULL,'2024-11-19',NULL,NULL,'2024-11-12','5.14.0-503.14.1',NULL)
  , ('miraclelinux-8.4','Miracle Linux','8.4',NULL,'EOL','2021-10-04',NULL,NULL,'2021-05-18','4.18.0-305.el8',NULL)
  , ('miraclelinux-8.6','Miracle Linux','8.6',NULL,'EOL','2022-11-01',NULL,NULL,'2022-05-10','4.18.0-372.el8',NULL)
  , ('miraclelinux-8.8','Miracle Linux','8.8',NULL,NULL,'2023-10-05',NULL,NULL,'2023-05-16','4.18.0-477.el8',NULL)
  , ('miraclelinux-8.10','Miracle Linux','8.10','Peony',NULL,'2024-10-17',NULL,NULL,'2024-05-22','4.18.0-553.el8_10',NULL)
  , ('miraclelinux-9.0','Miracle Linux','9.0',NULL,'EOL','2022-11-01',NULL,NULL,'2022-05-17','5.14.0-70.el9',NULL)
  , ('miraclelinux-9.2','Miracle Linux','9.2',NULL,'EOL','2023-10-05',NULL,NULL,'2023-05-10','5.14.0-284.el9',NULL)
  , ('miraclelinux-9.4','Miracle Linux','9.4','Feige',NULL,'2024-09-02',NULL,NULL,'2024-04-30','5.14.0-427.13.1.el9_4',NULL)
  , ('opensuse-leap-15.0','openSUSE','15.0',NULL,'EOL','2018-05-25','2019-12-03',NULL,NULL,'4.12',NULL)
  , ('opensuse-leap-15.1','openSUSE','15.1',NULL,'EOL','2019-05-22','2021-01-31',NULL,NULL,'4.12',NULL)
  , ('opensuse-leap-15.2','openSUSE','15.2',NULL,'EOL','2020-07-02','2021-12-31',NULL,NULL,'5.3.18',NULL)
  , ('opensuse-leap-15.3','openSUSE','15.3',NULL,'EOL','2021-06-02','2022-12-31',NULL,NULL,'5.3.18',NULL)
  , ('opensuse-leap-15.4','openSUSE','15.4',NULL,'EOL','2022-06-08','2023-12-31',NULL,NULL,'5.14.21',NULL)
  , ('opensuse-leap-15.5','openSUSE','15.5',NULL,'EOL','2023-06-07','2024-12-31',NULL,NULL,'5.14.21',NULL)
  , ('opensuse-leap-15.6','openSUSE','15.6',NULL,NULL,'2024-06-12','2025-12-31',NULL,NULL,'6.4',NULL)
  , ('opensuse-leap-16.0','openSUSE','16.0',NULL,NULL,'2025-10-xx','20xx-xx-xx',NULL,NULL,NULL,NULL)
  , ('opensuse-tumbleweed','openSUSE','tumbleweed',NULL,NULL,'2014-11-xx','20xx-xx-xx',NULL,NULL,NULL,NULL)
;
"
```
  
##### テーブル: media  
  
``` bash:
psql      --dbname=mydb --command="
INSERT INTO public.media(type,entry_flag,entry_name,entry_disp,version,latest,release,support,web_regexp,web_path,web_tstamp,web_size,web_status,iso_path,iso_tstamp,iso_size,iso_volume,rmk_path,rmk_tstamp,rmk_size,rmk_volume,ldr_initrd,ldr_kernel,cfg_path,cfg_tstamp,lnk_path) VALUES 
    ('mini.iso','m','menu-entry','Auto%20install%20mini.iso','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('mini.iso','o','debian-mini-11','Debian%2011','debian-11.0','debian-11.11.0','2021-08-14','2024-08-15',NULL,'https://deb.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-bullseye-amd64.iso',TIMESTAMP '2024-08-27 06:14:31.000',54525952,'ISOIMAGE',':_DIRS_RMAK_:/mini-bullseye-amd64_preseed.iso',TIMESTAMP '2025-03-26 02:24:41.000',78643200,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','o','debian-mini-12','Debian%2012','debian-12.0','debian-12.10.0','2023-06-10','2026-06-xx',NULL,'https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-bookworm-amd64.iso',TIMESTAMP '2025-03-10 12:28:07.000',65011712,'ISOIMAGE',':_DIRS_RMAK_:/mini-bookworm-amd64_preseed.iso',TIMESTAMP '2025-03-26 02:24:57.000',99614720,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','o','debian-mini-13','Debian%2013','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,'https://deb.debian.org/debian/dists/trixie/main/installer-amd64/current/images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-trixie-amd64.iso',TIMESTAMP '2024-12-27 09:14:03.000',65011712,'ISOIMAGE',':_DIRS_RMAK_:/mini-trixie-amd64_preseed.iso',TIMESTAMP '2025-03-26 02:25:10.000',97517568,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','-','debian-mini-14','Debian%2014','debian-14.0','debian-14.0','2027-xx-xx','20xx-xx-xx',NULL,'https://deb.debian.org/debian/dists/forky/main/installer-amd64/current/images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-forky-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','o','debian-mini-testing-daily','Debian%20testing%20daily','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://d-i.debian.org/daily-images/amd64/daily/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-testing-daily-amd64.iso',TIMESTAMP '2025-04-04 00:02:03.000',67108864,'ISOIMAGE',':_DIRS_RMAK_:/mini-testing-daily-amd64_preseed.iso',TIMESTAMP '2025-04-04 14:54:57.000',101711872,'ISOIMAGE',':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','o','debian-mini-testing','Debian%20testing','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://deb.debian.org/debian/dists/testing/main/installer-amd64/current/images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-testing-amd64.iso',TIMESTAMP '2024-12-27 09:14:03.000',65011712,'ISOIMAGE',':_DIRS_RMAK_:/mini-testing-amd64_preseed.iso',TIMESTAMP '2025-03-26 02:25:23.000',97517568,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('mini.iso','o','ubuntu-mini-20.04','Ubuntu%2020.04','ubuntu-20.04','ubuntu-20.04.6','2020-04-23','2025-05-29',NULL,'http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/mini-focal-amd64.iso',TIMESTAMP '2023-03-14 22:28:31.000',82837504,'CDROM',':_DIRS_RMAK_:/mini-focal-amd64_preseed.iso',TIMESTAMP '2025-03-26 02:26:00.000',133169152,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux',':_DIRS_CONF_:/preseed/ps_ubuntu_server_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('mini.iso','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('netinst','m','menu-entry','Auto%20install%20Net%20install','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('netinst','o','debian-netinst-11','Debian%2011','debian-11.0','debian-11.11.0','2021-08-14','2024-08-15','https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.[0-9.]*-amd64-netinst.iso','https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-cd/debian-11.11.0-amd64-netinst.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-11.11.0-amd64-netinst.iso',TIMESTAMP '2024-08-31 16:11:10.000',408944640,'Debian%2011.11.0%20amd64%20n',':_DIRS_RMAK_:/debian-11.11.0-amd64-netinst_preseed.iso',TIMESTAMP '2025-03-26 02:27:09.000',467664896,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('netinst','o','debian-netinst-12','Debian%2012','debian-12.0','debian-12.10.0','2023-06-10','2026-06-xx','https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.[0-9.]*-amd64-netinst.iso','https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/debian-12.10.0-amd64-netinst.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-12.10.0-amd64-netinst.iso',TIMESTAMP '2025-03-15 12:03:05.000',663748608,'Debian%2012.10.0%20amd64%20n',':_DIRS_RMAK_:/debian-12.10.0-amd64-netinst_preseed.iso',TIMESTAMP '2025-03-26 02:28:27.000',790626304,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('netinst','o','debian-netinst-13','Debian%2013','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-13.0.0-amd64-netinst.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('netinst','-','debian-netinst-14','Debian%2014','debian-14.0','debian-14.0','2027-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-14.0.0-amd64-netinst.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('netinst','o','debian-netinst-testing','Debian%20testing','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://cdimage.debian.org/cdimage/daily-builds/daily/current/amd64/iso-cd/debian-testing-amd64-netinst.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-testing-amd64-netinst.iso',TIMESTAMP '2025-04-04 09:15:56.000',883949568,'Debian%20testing%20amd64%20n',':_DIRS_RMAK_:/debian-testing-amd64-netinst_preseed.iso',TIMESTAMP '2025-04-04 14:57:09.000',1153105920,'Debian%20testing%20amd64%20n',':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('netinst','o','fedora-netinst-40','Fedora%20Server%2040','fedora-40','fedora-40','2024-04-23','2025-05-28','https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-[0-9.]*.iso','https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-netinst-x86_64-40-1.14.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Fedora-Server-netinst-x86_64-40-1.14.iso',TIMESTAMP '2024-04-14 18:30:19.000',812312576,'Fedora-S-dvd-x86_64-40',':_DIRS_RMAK_:/Fedora-Server-netinst-x86_64-40-1.14_kickstart.iso',TIMESTAMP '2025-03-26 02:31:53.000',812646400,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_fedora-40_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/fedora')
  , ('netinst','o','fedora-netinst-41','Fedora%20Server%2041','fedora-41','fedora-41','2024-10-29','2025-11-19','https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-[0-9.]*.iso','https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-netinst-x86_64-41-1.4.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Fedora-Server-netinst-x86_64-41-1.4.iso',TIMESTAMP '2024-10-24 13:36:10.000',954900480,'Fedora-S-dvd-x86_64-41',':_DIRS_RMAK_:/Fedora-Server-netinst-x86_64-41-1.4_kickstart.iso',TIMESTAMP '2025-03-26 02:33:33.000',955252736,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_fedora-41_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/fedora')
  , ('netinst','o','centos-stream-netinst-9','CentOS%20Stream%209','centos-stream-9','centos-stream-9','2021-12-03','2027-05-31',NULL,'https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-boot.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/CentOS-Stream-9-latest-x86_64-boot.iso',TIMESTAMP '2025-03-31 03:58:36.000',1261371392,'CentOS-Stream-9-BaseOS-x86_64',':_DIRS_RMAK_:/CentOS-Stream-9-latest-x86_64-boot_kickstart.iso',TIMESTAMP '2025-04-01 15:52:59.000',1442840576,'CentOS-Stream-9-BaseOS-x86_64',':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_centos-stream-9_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/centos')
  , ('netinst','o','centos-stream-netinst-10','CentOS%20Stream%2010','centos-stream-10','centos-stream-10','2024-12-12','2030-01-01',NULL,'https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-boot.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/CentOS-Stream-10-latest-x86_64-boot.iso',TIMESTAMP '2025-03-31 04:20:34.000',857878528,'CentOS-Stream-10-BaseOS-x86_64',':_DIRS_RMAK_:/CentOS-Stream-10-latest-x86_64-boot_kickstart.iso',TIMESTAMP '2025-04-01 15:54:34.000',858783744,'CentOS-Stream-10-BaseOS-x86_64',':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_centos-stream-10_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/centos')
  , ('netinst','o','almalinux-netinst-9','Alma%20Linux%209','almalinux-9','almalinux-9.5','2024-11-18',NULL,NULL,'https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-boot.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/AlmaLinux-9-latest-x86_64-boot.iso',TIMESTAMP '2024-11-13 09:40:34.000',1111998464,'AlmaLinux-9-5-x86_64-dvd',':_DIRS_RMAK_:/AlmaLinux-9-latest-x86_64-boot_kickstart.iso',TIMESTAMP '2025-03-26 02:40:00.000',1283014656,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_almalinux-9_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/almalinux')
  , ('netinst','o','rockylinux-netinst-9','Rocky%20Linux%209','rockylinux-9','rockylinux-9.5','2024-11-19',NULL,NULL,'https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-boot.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Rocky-9-latest-x86_64-boot.iso',TIMESTAMP '2024-11-16 01:52:35.000',1068498944,'Rocky-9-5-x86_64-dvd',':_DIRS_RMAK_:/Rocky-9-latest-x86_64-boot_kickstart.iso',TIMESTAMP '2025-03-26 02:44:23.000',1239089152,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_rockylinux-9_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/rocky')
  , ('netinst','o','miraclelinux-netinst-9','Miracle%20Linux%209','miraclelinux-9','miraclelinux-9.4','2024-09-02',NULL,'https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-minimal-x86_64.iso','https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-minimal-x86_64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/MIRACLELINUX-9.4-rtm-minimal-x86_64.iso',TIMESTAMP '2024-08-23 05:57:18.000',2184937472,'MIRACLE-LINUX-9-4-x86_64',':_DIRS_RMAK_:/MIRACLELINUX-9.4-rtm-minimal-x86_64_kickstart.iso',TIMESTAMP '2025-03-26 02:48:33.000',2312994816,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_miraclelinux-9_net.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/miraclelinux')
  , ('netinst','o','opensuse-leap-netinst-15.6','openSUSE%20Leap%2015.6','opensuse-leap-15.6','opensuse-15.6','2024-06-12','2025-12-31',NULL,'https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-NET-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Leap-15.6-NET-x86_64-Media.iso',TIMESTAMP '2024-06-20 11:42:39.000',273678336,'openSUSE-Leap-15.6-NET-x86_64710',':_DIRS_RMAK_:/openSUSE-Leap-15.6-NET-x86_64-Media_autoyast.iso',TIMESTAMP '2025-03-26 02:49:19.000',273678336,NULL,':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_leap-15.6_net.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('netinst','o','opensuse-leap-netinst-16.0','openSUSE%20Leap%2016.0','opensuse-leap-16.0','opensuse-16.0','2025-10-xx','20xx-xx-xx',NULL,'https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-NET-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Leap-16.0-NET-x86_64-Media.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_leap-16.0_net.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('netinst','o','opensuse-tumbleweed-netinst','openSUSE%20Tumbleweed','opensuse-tumbleweed','opensuse-tumbleweed','2014-11-xx','20xx-xx-xx',NULL,'https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-NET-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Tumbleweed-NET-x86_64-Current.iso',TIMESTAMP '2025-04-03 06:51:49.000',309329920,'openSUSE-Tumbleweed-NET-x86_64',':_DIRS_RMAK_:/openSUSE-Tumbleweed-NET-x86_64-Current_autoyast.iso',TIMESTAMP '2025-04-04 14:57:55.000',309329920,'openSUSE-Tumbleweed-NET-x86_64',':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_tumbleweed_net.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('netinst','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('dvd','m','menu-entry','Auto%20install%20DVD%20media','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('dvd','o','debian-11','Debian%2011','debian-11.0','debian-11.11.0','2021-08-14','2024-08-15','https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.[0-9.]*-amd64-DVD-1.iso','https://cdimage.debian.org/cdimage/archive/latest-oldstable/amd64/iso-dvd/debian-11.11.0-amd64-DVD-1.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-11.11.0-amd64-DVD-1.iso',TIMESTAMP '2024-08-31 16:11:53.000',3992977408,'Debian%2011.11.0%20amd64%201',':_DIRS_RMAK_:/debian-11.11.0-amd64-DVD-1_preseed.iso',TIMESTAMP '2025-03-26 02:58:18.000',4048191488,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('dvd','o','debian-12','Debian%2012','debian-12.0','debian-12.10.0','2023-06-10','2026-06-xx','https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.[0-9.]*-amd64-DVD-1.iso','https://cdimage.debian.org/cdimage/release/current/amd64/iso-dvd/debian-12.10.0-amd64-DVD-1.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-12.10.0-amd64-DVD-1.iso',TIMESTAMP '2025-03-15 12:03:59.000',3994091520,'Debian%2012.10.0%20amd64%201',':_DIRS_RMAK_:/debian-12.10.0-amd64-DVD-1_preseed.iso',TIMESTAMP '2025-03-26 03:06:54.000',4119134208,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('dvd','o','debian-13','Debian%2013','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-13.0.0-amd64-DVD-1.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('dvd','-','debian-14','Debian%2014','debian-14.0','debian-14.0','2027-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-14.0.0-amd64-DVD-1.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('dvd','o','debian-testing','Debian%20testing','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://cdimage.debian.org/cdimage/weekly-builds/amd64/iso-dvd/debian-testing-amd64-DVD-1.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-testing-amd64-DVD-1.iso',TIMESTAMP '2025-03-31 05:42:16.000',3989078016,'Debian%20testing%20amd64%201',':_DIRS_RMAK_:/debian-testing-amd64-DVD-1_preseed.iso',TIMESTAMP '2025-04-01 16:04:25.000',4253089792,'Debian%20testing%20amd64%201',':_DIRS_LOAD_:/install.amd/initrd.gz',':_DIRS_LOAD_:/install.amd/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('dvd','o','ubuntu-live-20.04','Ubuntu%2020.04%20Live%20Server','ubuntu-20.04','ubuntu-20.04.6','2020-04-23','2025-05-29','https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-live-server-amd64.iso','https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-20.04.6-live-server-amd64.iso',TIMESTAMP '2023-03-14 23:02:35.000',1487339520,'Ubuntu-Server%2020.04.6%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-20.04.6-live-server-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:11:11.000',1488797696,'Ubuntu-Server%2020.04.6%20LTS%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_server_old',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('dvd','o','ubuntu-live-22.04','Ubuntu%2022.04%20Live%20Server','ubuntu-22.04','ubuntu-22.04.5','2022-04-21','2027-06-01','https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-live-server-amd64.iso','https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-22.04.5-live-server-amd64.iso',TIMESTAMP '2024-09-11 18:46:55.000',2136926208,'Ubuntu-Server%2022.04.5%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-22.04.5-live-server-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:12:06.000',2136997888,'Ubuntu-Server%2022.04.5%20LTS%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_server_old',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('dvd','o','ubuntu-live-24.04','Ubuntu%2024.04%20Live%20Server','ubuntu-24.04','ubuntu-24.04.2','2024-04-25','2029-05-31','https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-live-server-amd64.iso','https://releases.ubuntu.com/24.04/ubuntu-24.04.2-live-server-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.04.2-live-server-amd64.iso',TIMESTAMP '2025-02-16 22:49:40.000',3213064192,'Ubuntu-Server%2024.04.2%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-24.04.2-live-server-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:13:49.000',3214934016,'Ubuntu-Server%2024.04.2%20LTS%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_server',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('dvd','o','ubuntu-live-24.10','Ubuntu%2024.10%20Live%20Server','ubuntu-24.10','ubuntu-24.10','2024-10-10','2025-07-xx','https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-live-server-amd64.iso','https://releases.ubuntu.com/24.10/ubuntu-24.10-live-server-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.10-live-server-amd64.iso',TIMESTAMP '2024-10-07 21:19:04.000',2098460672,'Ubuntu-Server%2024.10%20amd64',':_DIRS_RMAK_:/ubuntu-24.10-live-server-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:15:00.000',2099478528,'Ubuntu-Server%2024.10%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_server',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('dvd','o','ubuntu-live-25.04','Ubuntu%2025.04%20Live%20Server','ubuntu-25.04','ubuntu-25.04','2025-04-17','2026-01-xx','https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-beta-live-server-amd64.iso','https://releases.ubuntu.com/25.04/ubuntu-25.04-beta-live-server-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-25.04-beta-live-server-amd64.iso',TIMESTAMP '2025-03-24 13:14:46.000',2020927488,'Ubuntu-Server%2025.04%20amd64',':_DIRS_RMAK_:/ubuntu-25.04-beta-live-server-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:15:50.000',2022113280,'Ubuntu-Server%2025.04%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_server',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('dvd','o','fedora-40','Fedora%20Server%2040','fedora-40','fedora-40','2024-04-23','2025-05-28','https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-[0-9.]*.iso','https://download.fedoraproject.org/pub/fedora/linux/releases/40/Server/x86_64/iso/Fedora-Server-dvd-x86_64-40-1.14.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Fedora-Server-dvd-x86_64-40-1.14.iso',TIMESTAMP '2024-04-14 22:54:06.000',2612854784,'Fedora-S-dvd-x86_64-40',':_DIRS_RMAK_:/Fedora-Server-dvd-x86_64-40-1.14_kickstart.iso',TIMESTAMP '2025-03-26 03:58:16.000',2612133888,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_fedora-40_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/fedora')
  , ('dvd','o','fedora-41','Fedora%20Server%2041','fedora-41','fedora-41','2024-10-29','2025-11-19','https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-[0-9.]*.iso','https://download.fedoraproject.org/pub/fedora/linux/releases/41/Server/x86_64/iso/Fedora-Server-dvd-x86_64-41-1.4.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Fedora-Server-dvd-x86_64-41-1.4.iso',TIMESTAMP '2024-10-24 14:48:35.000',2818572288,'Fedora-S-dvd-x86_64-41',':_DIRS_RMAK_:/Fedora-Server-dvd-x86_64-41-1.4_kickstart.iso',TIMESTAMP '2025-03-26 04:04:04.000',2818572288,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_fedora-41_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/fedora')
  , ('dvd','o','centos-stream-9','CentOS%20Stream%209','centos-stream-9','centos-stream-9','2021-12-03','2027-05-31',NULL,'https://ftp.iij.ad.jp/pub/linux/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/CentOS-Stream-9-latest-x86_64-dvd1.iso',TIMESTAMP '2025-03-31 04:14:57.000',12822052864,'CentOS-Stream-9-BaseOS-x86_64',':_DIRS_RMAK_:/CentOS-Stream-9-latest-x86_64-dvd1_kickstart.iso',TIMESTAMP '2025-04-01 16:33:47.000',13003143168,'CentOS-Stream-9-BaseOS-x86_64',':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_centos-stream-9_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/centos')
  , ('dvd','o','centos-stream-10','CentOS%20Stream%2010','centos-stream-10','centos-stream-10','2024-12-12','2030-01-01',NULL,'https://ftp.iij.ad.jp/pub/linux/centos-stream/10-stream/BaseOS/x86_64/iso/CentOS-Stream-10-latest-x86_64-dvd1.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/CentOS-Stream-10-latest-x86_64-dvd1.iso',TIMESTAMP '2025-03-31 04:30:11.000',7602765824,'CentOS-Stream-10-BaseOS-x86_64',':_DIRS_RMAK_:/CentOS-Stream-10-latest-x86_64-dvd1_kickstart.iso',TIMESTAMP '2025-04-01 16:51:27.000',7603126272,'CentOS-Stream-10-BaseOS-x86_64',':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_centos-stream-10_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/centos')
  , ('dvd','o','almalinux-9','Alma%20Linux%209','almalinux-9','almalinux-9.5','2024-11-18',NULL,NULL,'https://repo.almalinux.org/almalinux/9/isos/x86_64/AlmaLinux-9-latest-x86_64-dvd.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/AlmaLinux-9-latest-x86_64-dvd.iso',TIMESTAMP '2024-11-13 09:59:46.000',11382292480,'AlmaLinux-9-5-x86_64-dvd',':_DIRS_RMAK_:/AlmaLinux-9-latest-x86_64-dvd_kickstart.iso',TIMESTAMP '2025-03-26 05:37:57.000',11552618496,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_almalinux-9_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/almalinux')
  , ('dvd','o','rockylinux-9','Rocky%20Linux%209','rockylinux-9','rockylinux-9.5','2024-11-19',NULL,NULL,'https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9-latest-x86_64-dvd.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/Rocky-9-latest-x86_64-dvd.iso',TIMESTAMP '2024-11-16 04:23:15.000',11510087680,'Rocky-9-5-x86_64-dvd',':_DIRS_RMAK_:/Rocky-9-latest-x86_64-dvd_kickstart.iso',TIMESTAMP '2025-03-26 06:20:22.000',11680507904,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_rockylinux-9_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/rocky')
  , ('dvd','o','miraclelinux-9','Miracle%20Linux%209','miraclelinux-9','miraclelinux-9.4','2024-09-02',NULL,'https://repo.dist.miraclelinux.net/miraclelinux/isos/9.[0-9.]*-released/x86_64/MIRACLELINUX-9.[0-9.]*-rtm-x86_64.iso','https://repo.dist.miraclelinux.net/miraclelinux/isos/9.4-released/x86_64/MIRACLELINUX-9.4-rtm-x86_64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/MIRACLELINUX-9.4-rtm-x86_64.iso',TIMESTAMP '2024-08-23 05:57:18.000',10582161408,'MIRACLE-LINUX-9-4-x86_64',':_DIRS_RMAK_:/MIRACLELINUX-9.4-rtm-x86_64_kickstart.iso',TIMESTAMP '2025-03-26 06:48:08.000',10709778432,NULL,':_DIRS_LOAD_:/images/pxeboot/initrd.img',':_DIRS_LOAD_:/images/pxeboot/vmlinuz',':_DIRS_CONF_:/kickstart/ks_miraclelinux-9_dvd.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/miraclelinux')
  , ('dvd','o','opensuse-leap-15.6','openSUSE%20Leap%2015.6','opensuse-leap-15.6','opensuse-15.6','2024-06-12','2025-12-31',NULL,'https://ftp.riken.jp/Linux/opensuse/distribution/leap/15.6/iso/openSUSE-Leap-15.6-DVD-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Leap-15.6-DVD-x86_64-Media.iso',TIMESTAMP '2024-06-20 11:56:54.000',4631560192,'openSUSE-Leap-15.6-DVD-x86_64710',':_DIRS_RMAK_:/openSUSE-Leap-15.6-DVD-x86_64-Media_autoyast.iso',TIMESTAMP '2025-03-26 07:00:12.000',4835948544,NULL,':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_leap-15.6_dvd.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('dvd','o','opensuse-leap-16.0','openSUSE%20Leap%2016.0','opensuse-leap-16.0','opensuse-16.0','2025-10-xx','20xx-xx-xx',NULL,'https://ftp.riken.jp/Linux/opensuse/distribution/leap/16.0/iso/openSUSE-Leap-16.0-DVD-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Leap-16.0-DVD-x86_64-Media.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_leap-16.0_dvd.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('dvd','o','opensuse-tumbleweed','openSUSE%20Tumbleweed','opensuse-tumbleweed','opensuse-tumbleweed','2014-11-xx','20xx-xx-xx',NULL,'https://ftp.riken.jp/Linux/opensuse/tumbleweed/iso/openSUSE-Tumbleweed-DVD-x86_64-Current.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/openSUSE-Tumbleweed-DVD-x86_64-Current.iso',TIMESTAMP '2025-04-03 06:55:00.000',4595908608,'openSUSE-Tumbleweed-DVD-x86_64',':_DIRS_RMAK_:/openSUSE-Tumbleweed-DVD-x86_64-Current_autoyast.iso',TIMESTAMP '2025-04-04 15:07:36.000',4597125120,'openSUSE-Tumbleweed-DVD-x86_64',':_DIRS_LOAD_:/boot/x86_64/loader/initrd',':_DIRS_LOAD_:/boot/x86_64/loader/linux',':_DIRS_CONF_:/autoyast/autoinst_tumbleweed_dvd.xml',NULL,':_DIRS_HGFS_:/workspace/image/linux/opensuse')
  , ('dvd','o','windows-10','Windows%2010','windows-10.0','windows-10',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/Win10_22H2_Japanese_x64.iso',TIMESTAMP '2022-10-18 15:21:50.000',6003816448,'CCCOMA_X64FRE_JA-JP_DV9',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/Windows10')
  , ('dvd','-','windows-11-custom','Windows%2011%20custom','windows-11.0','windows-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/Win11_24H2_Japanese_x64_custom.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/Windows11')
  , ('dvd','o','windows-11','Windows%2011','windows-11.0','windows-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/Win11_24H2_Japanese_x64.iso',TIMESTAMP '2024-10-01 12:18:50.000',5751373824,'CCCOMA_X64FRE_JA-JP_DV9',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/Windows11')
  , ('dvd','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('live_install','m','menu-entry','Live%20media%20Install%20mode','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('live_install','o','debian-live-11','Debian%2011%20Live','debian-11.0','debian-11.11.0','2021-08-14','2024-08-15','https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso','https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-11.11.0-amd64-lxde.iso',TIMESTAMP '2024-08-31 15:15:29.000',2566914048,'d-live%2011.11.0%20lx%20amd64',':_DIRS_RMAK_:/debian-live-11.11.0-amd64-lxde_preseed.iso',TIMESTAMP '2025-03-26 07:16:19.000',2566914048,NULL,':_DIRS_LOAD_:/d-i/initrd.gz',':_DIRS_LOAD_:/d-i/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_desktop_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live_install','o','debian-live-12','Debian%2012%20Live','debian-12.0','debian-12.10.0','2023-06-10','2026-06-xx','https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso','https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.10.0-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-12.10.0-amd64-lxde.iso',TIMESTAMP '2025-03-15 09:09:36.000',3181445120,'d-live%2012.10.0%20ld%20amd64',':_DIRS_RMAK_:/debian-live-12.10.0-amd64-lxde_preseed.iso',TIMESTAMP '2025-03-26 07:23:16.000',3275489280,NULL,':_DIRS_LOAD_:/install/initrd.gz',':_DIRS_LOAD_:/install/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_desktop.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live_install','o','debian-live-13','Debian%2013%20Live','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-13.0.0-amd64-lxde.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/install/initrd.gz',':_DIRS_LOAD_:/install/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_desktop.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live_install','o','debian-live-testing','Debian%20testing%20Live','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-testing-amd64-lxde.iso',TIMESTAMP '2025-03-31 02:14:03.000',3717267456,'d-live%20testing%20ld%20amd64',':_DIRS_RMAK_:/debian-live-testing-amd64-lxde_preseed.iso',TIMESTAMP '2025-04-01 16:59:50.000',3871752192,'d-live%20testing%20ld%20amd64',':_DIRS_LOAD_:/install/initrd.gz',':_DIRS_LOAD_:/install/vmlinuz',':_DIRS_CONF_:/preseed/ps_debian_desktop.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live_install','o','ubuntu-desktop-20.04','Ubuntu%2020.04%20Desktop','ubuntu-20.04','ubuntu-20.04.6','2020-04-23','2025-05-29','https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-20.04.6-desktop-amd64.iso',TIMESTAMP '2023-03-16 15:58:09.000',4351463424,'Ubuntu%2020.04.6%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-20.04.6-desktop-amd64_preseed.iso',TIMESTAMP '2025-03-26 07:46:32.000',4351463424,NULL,':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/preseed/ps_ubiquity_desktop_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live_install','o','ubuntu-desktop-22.04','Ubuntu%2022.04%20Desktop','ubuntu-22.04','ubuntu-22.04.5','2022-04-21','2027-06-01','https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-22.04.5-desktop-amd64.iso',TIMESTAMP '2024-09-11 14:38:59.000',4762707968,'Ubuntu%2022.04.5%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-22.04.5-desktop-amd64_preseed.iso',TIMESTAMP '2025-03-26 07:56:56.000',4764340224,NULL,':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/preseed/ps_ubiquity_desktop_old.cfg',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live_install','o','ubuntu-desktop-24.04','Ubuntu%2024.04%20Desktop','ubuntu-24.04','ubuntu-24.04.2','2024-04-25','2029-05-31','https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.04.2-desktop-amd64.iso',TIMESTAMP '2025-02-15 09:16:38.000',6343219200,'Ubuntu%2024.04.2%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-24.04.2-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:28:21.000',6347464704,'Ubuntu%2024.04.2%20LTS%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_desktop',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live_install','o','ubuntu-desktop-24.10','Ubuntu%2024.10%20Desktop','ubuntu-24.10','ubuntu-24.10','2024-10-10','2025-07-xx','https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.10-desktop-amd64.iso',TIMESTAMP '2024-10-09 14:32:32.000',5665497088,'Ubuntu%2024.10%20amd64',':_DIRS_RMAK_:/ubuntu-24.10-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:31:27.000',5670088704,'Ubuntu%2024.10%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_desktop',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live_install','o','ubuntu-desktop-25.04','Ubuntu%2025.04%20Desktop','ubuntu-25.04','ubuntu-25.04','2025-04-17','2026-01-xx','https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-beta-desktop-amd64.iso','https://releases.ubuntu.com/25.04/ubuntu-25.04-beta-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-25.04-beta-desktop-amd64.iso',TIMESTAMP '2025-03-26 20:03:58.000',6339821568,'Ubuntu%2025.04%20amd64',':_DIRS_RMAK_:/ubuntu-25.04-beta-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:34:48.000',6341787648,'Ubuntu%2025.04%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/ubuntu_desktop',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live_install','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('live','m','menu-entry','Live%20media%20Live%20mode','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('live','o','debian-live-11','Debian%2011%20Live','debian-11.0','debian-11.11.0','2021-08-14','2024-08-15','https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.[0-9.]*-amd64-lxde.iso','https://cdimage.debian.org/cdimage/archive/latest-oldstable-live/amd64/iso-hybrid/debian-live-11.11.0-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-11.11.0-amd64-lxde.iso',TIMESTAMP '2024-08-31 15:15:29.000',2566914048,'d-live%2011.11.0%20lx%20amd64',':_DIRS_RMAK_:/debian-live-11.11.0-amd64-lxde_preseed.iso',TIMESTAMP '2025-03-26 07:16:19.000',2566914048,NULL,':_DIRS_LOAD_:/live/initrd.img-5.10.0-32-amd64',':_DIRS_LOAD_:/live/vmlinuz-5.10.0-32-amd64',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live','o','debian-live-12','Debian%2012%20Live','debian-12.0','debian-12.10.0','2023-06-10','2026-06-xx','https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.[0-9.]*-amd64-lxde.iso','https://cdimage.debian.org/cdimage/release/current-live/amd64/iso-hybrid/debian-live-12.10.0-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-12.10.0-amd64-lxde.iso',TIMESTAMP '2025-03-15 09:09:36.000',3181445120,'d-live%2012.10.0%20ld%20amd64',':_DIRS_RMAK_:/debian-live-12.10.0-amd64-lxde_preseed.iso',TIMESTAMP '2025-03-26 07:23:16.000',3275489280,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live','o','debian-live-13','Debian%2013%20Live','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-13.0.0-amd64-lxde.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live','o','debian-live-testing','Debian%20testing%20Live','debian-testing','debian-testing','20xx-xx-xx','20xx-xx-xx',NULL,'https://cdimage.debian.org/cdimage/weekly-live-builds/amd64/iso-hybrid/debian-live-testing-amd64-lxde.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/debian-live-testing-amd64-lxde.iso',TIMESTAMP '2025-03-31 02:14:03.000',3717267456,'d-live%20testing%20ld%20amd64',':_DIRS_RMAK_:/debian-live-testing-amd64-lxde_preseed.iso',TIMESTAMP '2025-04-01 16:59:50.000',3871752192,'d-live%20testing%20ld%20amd64',':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/debian')
  , ('live','o','ubuntu-desktop-20.04','Ubuntu%2020.04%20Desktop','ubuntu-20.04','ubuntu-20.04.6','2020-04-23','2025-05-29','https://releases.ubuntu.com/20.04/ubuntu-20.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-20.04.6-desktop-amd64.iso',TIMESTAMP '2023-03-16 15:58:09.000',4351463424,'Ubuntu%2020.04.6%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-20.04.6-desktop-amd64_preseed.iso',TIMESTAMP '2025-03-26 07:46:32.000',4351463424,NULL,':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live','o','ubuntu-desktop-22.04','Ubuntu%2022.04%20Desktop','ubuntu-22.04','ubuntu-22.04.5','2022-04-21','2027-06-01','https://releases.ubuntu.com/22.04/ubuntu-22.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-22.04.5-desktop-amd64.iso',TIMESTAMP '2024-09-11 14:38:59.000',4762707968,'Ubuntu%2022.04.5%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-22.04.5-desktop-amd64_preseed.iso',TIMESTAMP '2025-03-26 07:56:56.000',4764340224,NULL,':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live','o','ubuntu-desktop-24.04','Ubuntu%2024.04%20Desktop','ubuntu-24.04','ubuntu-24.04.2','2024-04-25','2029-05-31','https://releases.ubuntu.com/24.04/ubuntu-24.04[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.04.2-desktop-amd64.iso',TIMESTAMP '2025-02-15 09:16:38.000',6343219200,'Ubuntu%2024.04.2%20LTS%20amd64',':_DIRS_RMAK_:/ubuntu-24.04.2-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:28:21.000',6347464704,'Ubuntu%2024.04.2%20LTS%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live','o','ubuntu-desktop-24.10','Ubuntu%2024.10%20Desktop','ubuntu-24.10','ubuntu-24.10','2024-10-10','2025-07-xx','https://releases.ubuntu.com/24.10/ubuntu-24.10[0-9.]*-desktop-amd64.iso','https://releases.ubuntu.com/24.10/ubuntu-24.10-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-24.10-desktop-amd64.iso',TIMESTAMP '2024-10-09 14:32:32.000',5665497088,'Ubuntu%2024.10%20amd64',':_DIRS_RMAK_:/ubuntu-24.10-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:31:27.000',5670088704,'Ubuntu%2024.10%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live','o','ubuntu-desktop-25.04','Ubuntu%2025.04%20Desktop','ubuntu-25.04','ubuntu-25.04','2025-04-17','2026-01-xx','https://releases.ubuntu.com/25.04/ubuntu-25.04[0-9.]*-beta-desktop-amd64.iso','https://releases.ubuntu.com/25.04/ubuntu-25.04-beta-desktop-amd64.iso',NULL,NULL,NULL,':_DIRS_ISOS_:/ubuntu-25.04-beta-desktop-amd64.iso',TIMESTAMP '2025-03-26 20:03:58.000',6339821568,'Ubuntu%2025.04%20amd64',':_DIRS_RMAK_:/ubuntu-25.04-beta-desktop-amd64_nocloud.iso',TIMESTAMP '2025-03-27 20:34:48.000',6341787648,'Ubuntu%2025.04%20amd64',':_DIRS_LOAD_:/casper/initrd',':_DIRS_LOAD_:/casper/vmlinuz',':_DIRS_CONF_:/nocloud/',NULL,':_DIRS_HGFS_:/workspace/image/linux/ubuntu')
  , ('live','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('tool','m','menu-entry','System%20tools','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('tool','o','memtest86plus','Memtest86+%207.20','memtest86plus','memtest86plus',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/mt86plus_7.20_64.grub.iso',TIMESTAMP '2024-11-11 09:15:12.000',19988480,'MT86PLUS_64',NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/EFI/BOOT/memtest',':_DIRS_LOAD_:/boot/memtest',NULL,NULL,':_DIRS_HGFS_:/workspace/image/linux/memtest86+')
  , ('tool','o','winpe-x86','WinPE%20x86','winpe-x86','winpe-x86',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/WinPEx86.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/WinPE')
  , ('tool','o','winpe-x64','WinPE%20x64','winpe-x64','winpe-x64',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/WinPEx64.iso',TIMESTAMP '2024-10-21 12:19:39.000',469428224,'CD_ROM',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/WinPE')
  , ('tool','o','ati2020x86','ATI2020x86','ati2020x86','ati2020x86',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/WinPE_ATI2020x86.iso',TIMESTAMP '2022-01-28 13:07:12.000',555139072,'CD_ROM',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/ati')
  , ('tool','o','ati2020x64','ATI2020x64','ati2020x64','ati2020x64',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/WinPE_ATI2020x64.iso',TIMESTAMP '2022-01-28 13:12:34.000',630548480,'CD_ROM',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_HGFS_:/workspace/image/windows/ati')
  , ('tool','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('custom_live','m','menu-entry','Custom%20Live%20Media','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('custom_live','o','live-debian-11-bullseye','Live%20Debian%2011','debian-11.0','debian-11.0','2021-08-14','2024-08-15',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-debian-11-bullseye-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-debian-12-bookworm','Live%20Debian%2012','debian-12.0','debian-12.0','2023-06-10','2026-06-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-debian-12-bookworm-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-debian-13-trixie','Live%20Debian%2013','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-debian-13-trixie-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-debian-xx-unstable','Live%20Debian%20xx','debian-sid','debian-sid','20xx-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-debian-xx-unstable-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','L','live-ubuntu-16.04-xenial','Live%20Ubuntu%2016.04','ubuntu-16.04','ubuntu-16.04','2016-04-21','2021-04-30',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-16.04-xenial-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','L','live-ubuntu-18.04-bionic','Live%20Ubuntu%2018.04','ubuntu-18.04','ubuntu-18.04','2018-04-26','2023-05-31',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-18.04-bionic-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','s','live-ubuntu-20.04-focal','Live%20Ubuntu%2020.04','ubuntu-20.04','ubuntu-20.04','2020-04-23','2025-05-29',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-20.04-focal-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-ubuntu-22.04-jammy','Live%20Ubuntu%2022.04','ubuntu-22.04','ubuntu-22.04','2022-04-21','2027-06-01',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-22.04-jammy-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-ubuntu-24.04-noble','Live%20Ubuntu%2024.04','ubuntu-24.04','ubuntu-24.04','2024-04-25','2029-05-31',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-24.04-noble-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-ubuntu-24.10-oracular','Live%20Ubuntu%2024.10','ubuntu-24.10','ubuntu-24.10','2024-10-10','2025-07-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-24.10-oracular-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','o','live-ubuntu-25.04-plucky','Live%20Ubuntu%2025.04','ubuntu-25.04','ubuntu-25.04','2025-04-17','2026-01-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-25.04-plucky-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','s','live-ubuntu-xx.xx-devel','Live%20Ubuntu%20xx.xx','ubuntu-xx.xx','ubuntu-xx.xx',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_ISOS_:/live-ubuntu-xx.xx-devel-amd64.iso',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/live/initrd.img',':_DIRS_LOAD_:/live/vmlinuz',':_DIRS_CONF_:/preseed/',NULL,NULL)
  , ('custom_live','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('custom_netinst','m','menu-entry','Custom%20Initramfs%20boot','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('custom_netinst','o','netinst-debian-10','Net%20Installer%20Debian%2010','debian-10.0','debian-10.0','2019-07-06','2022-09-10',NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux_debian-10',':_DIRS_CONF_:/preseed/ps_debian_server_oldold.cfg',NULL,NULL)
  , ('custom_netinst','o','netinst-debian-11','Net%20Installer%20Debian%2011','debian-11.0','debian-11.0','2021-08-14','2024-08-15',NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux_debian-11',':_DIRS_CONF_:/preseed/ps_debian_server_old.cfg',NULL,NULL)
  , ('custom_netinst','o','netinst-debian-12','Net%20Installer%20Debian%2012','debian-12.0','debian-12.0','2023-06-10','2026-06-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux_debian-12',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,NULL)
  , ('custom_netinst','o','netinst-debian-13','Net%20Installer%20Debian%2013','debian-13.0','debian-13.0','2025-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux_debian-13',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,NULL)
  , ('custom_netinst','o','netinst-debian-sid','Net%20Installer%20Debian%20sid','debian-sid','debian-sid','20xx-xx-xx','20xx-xx-xx',NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/',NULL,NULL,NULL,NULL,NULL,NULL,NULL,':_DIRS_LOAD_:/initrd.gz',':_DIRS_LOAD_:/linux_debian-sid',':_DIRS_CONF_:/preseed/ps_debian_server.cfg',NULL,NULL)
  , ('custom_netinst','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('system','m','menu-entry','System%20command','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
  , ('system','o','hdt','Hardware%20info','hdt','hdt',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hdt.c32',NULL,NULL,NULL,NULL)
  , ('system','o','restart','System%20restart','restart','restart',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'reboot.c32',NULL,NULL,NULL,NULL)
  , ('system','o','shutdown','System%20shutdown','shutdown','shutdown',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'poweroff.c32',NULL,NULL,NULL,NULL)
  , ('system','m','menu-entry','-','menu-entry','menu-entry',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL)
;
"
```
  
### **データーの取得**  
  
#### **SQLの実行**  
  
##### テーブル: distribution  
  
``` bash:
psql -qtAX --dbname=mydb --command="
SELECT
    * 
FROM
    distribution 
ORDER BY
      distribution.version ~ 'debian-*' DESC
    , distribution.version ~ 'ubuntu-*' DESC
    , distribution.version ~ 'fedora-*' DESC
    , distribution.version ~ 'centos-[0-9]+-*' DESC
    , distribution.version ~ 'centos-stream-*' DESC
    , distribution.version ~ 'almalinux-*' DESC
    , distribution.version ~ 'rockylinux-*' DESC
    , distribution.version ~ 'miraclelinux-*' DESC
    , distribution.version ~ 'opensuse-*' DESC
    , distribution.version ~ 'windows-*' DESC
    , distribution.version ~ 'memtest86plus' DESC
    , distribution.version ~ 'winpe-x64' DESC
    , distribution.version ~ 'winpe-x86' DESC
    , distribution.version ~ 'ati2020x64' DESC
    , distribution.version ~ 'ati2020x86' DESC
    , distribution.version ~ regexp_replace(distribution.version, '[0-9].*$', '')
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0') 
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0') 
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0') 
;
"
```
  
##### テーブル: media  
  
``` bash:
psql -qtAX --dbname=mydb --command="
SELECT
    public.media.type
    , public.media.entry_flag
    , public.media.entry_name
    , public.media.entry_disp
    , public.media.version
    , public.media.latest
    , public.media.release
    , public.media.support
    , public.media.web_regexp
    , public.media.web_path
    , public.media.web_tstamp
    , public.media.web_size
    , public.media.web_status
    , public.media.iso_path
    , public.media.iso_tstamp
    , public.media.iso_size
    , public.media.iso_volume
    , public.media.rmk_path
    , public.media.rmk_tstamp
    , public.media.rmk_size
    , public.media.rmk_volume
    , public.media.ldr_initrd
    , public.media.ldr_kernel
    , public.media.cfg_path
    , public.media.cfg_tstamp
    , public.media.lnk_path 
FROM
    public.media 
WHERE
    public.media.entry_flag != 'x' 
    AND public.media.entry_flag != 'd' 
    AND public.media.entry_flag != 'b' 
ORDER BY
    public.media.type = 'mini.iso' DESC
    , public.media.type = 'netinst' DESC
    , public.media.type = 'dvd' DESC
    , public.media.type = 'live_install' DESC
    , public.media.type = 'live' DESC
    , public.media.type = 'tool' DESC
    , public.media.type = 'custom_live' DESC
    , public.media.type = 'custom_netinst' DESC
    , public.media.type = 'system' DESC
    , public.media.entry_disp != '-' DESC
    , public.media.version = 'menu-entry' DESC
    , public.media.version ~ 'debian-*' DESC
    , public.media.version ~ 'ubuntu-*' DESC
    , public.media.version ~ 'fedora-*' DESC
    , public.media.version ~ 'centos-stream-*' DESC
    , public.media.version ~ 'almalinux-*' DESC
    , public.media.version ~ 'rockylinux-*' DESC
    , public.media.version ~ 'miraclelinux-*' DESC
    , public.media.version ~ 'opensuse-*' DESC
    , public.media.version ~ 'windows-*' DESC
    , public.media.version = 'memtest86plus' DESC
    , public.media.version = 'winpe-x86' DESC
    , public.media.version = 'winpe-x64' DESC
    , public.media.version = 'ati2020x86' DESC
    , public.media.version = 'ati2020x64' DESC
    , public.media.version ~ '.*-sid'
    , public.media.version ~ '.*-testing'
    , public.media.version
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 3), 3, '0')
;
"
```
  
## **参考**  
  
[PostgreSQL 16.4文書](https://www.postgresql.jp/document/16/html/)  
[〃 パート VI. リファレンス](https://www.postgresql.jp/document/16/html/reference.html)  
[〃 パート II. SQL言語](https://www.postgresql.jp/document/16/html/sql.html)  
  
[PostgreSQL wiki](https://wiki.postgresql.org/wiki/Main_Page/ja)  
  
