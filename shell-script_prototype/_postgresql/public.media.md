# media

## テーブル情報

| 項目                           | 値                                                                                                   |
|:-------------------------------|:-----------------------------------------------------------------------------------------------------|
| システム名                     |                                                                                                      |
| サブシステム名                 |                                                                                                      |
| スキーマ名                     | public                                                                                               |
| 物理テーブル名                 | media                                                                                                |
| 論理テーブル名                 |                                                                                                      |
| 作成者                         | Jun                                                                                                  |
| 作成日                         | 2025/04/06                                                                                           |
| RDBMS                          | PostgreSQL 17.4 (Ubuntu 17.4-1.pgdg25.04+2) on x86_64-pc-linux-gnu, compiled by gcc (Ubuntu 14.2.0-17ubuntu1) 14.2.0, 64-bit 17.4 |



## カラム情報

| No. | 論理名                         | 物理名                         | データ型                       | Not Null | デフォルト           | 備考                           |
|----:|:-------------------------------|:-------------------------------|:-------------------------------|:---------|:---------------------|:-------------------------------|
|   1 |                                | type                           | text                           | Yes (PK) |                      |                                |
|   2 |                                | entry_flag                     | text                           | Yes (PK) |                      |                                |
|   3 |                                | entry_name                     | text                           | Yes (PK) |                      |                                |
|   4 |                                | entry_disp                     | text                           | Yes (PK) |                      |                                |
|   5 |                                | version                        | text                           |          |                      |                                |
|   6 |                                | latest                         | text                           |          |                      |                                |
|   7 |                                | release                        | text                           |          |                      |                                |
|   8 |                                | support                        | text                           |          |                      |                                |
|   9 |                                | web_url                        | text                           |          |                      |                                |
|  10 |                                | web_tstamp                     | timestamp(6) without time zone |          |                      |                                |
|  11 |                                | web_size                       | bigint                         |          |                      |                                |
|  12 |                                | web_status                     | text                           |          |                      |                                |
|  13 |                                | iso_path                       | text                           |          |                      |                                |
|  14 |                                | iso_tstamp                     | timestamp(6) without time zone |          |                      |                                |
|  15 |                                | iso_size                       | bigint                         |          |                      |                                |
|  16 |                                | iso_volume                     | text                           |          |                      |                                |
|  17 |                                | rmk_path                       | text                           |          |                      |                                |
|  18 |                                | rmk_tstamp                     | timestamp(6) without time zone |          |                      |                                |
|  19 |                                | rmk_size                       | bigint                         |          |                      |                                |
|  20 |                                | rmk_volume                     | text                           |          |                      |                                |
|  21 |                                | ldr_initrd                     | text                           |          |                      |                                |
|  22 |                                | ldr_kernel                     | text                           |          |                      |                                |
|  23 |                                | cfg_path                       | text                           |          |                      |                                |
|  24 |                                | cfg_tstamp                     | timestamp(6) without time zone |          |                      |                                |
|  25 |                                | lnk_path                       | text                           |          |                      |                                |



## インデックス情報

| No. | インデックス名                 | カラムリスト                             | ユニーク   | オプション                     | 
|----:|:-------------------------------|:-----------------------------------------|:-----------|:-------------------------------|
|   1 | media_pkc                      | type,entry_flag,entry_name,entry_disp    | Yes        |                                |



## 制約情報

| No. | 制約名                         | 種類                           | 制約定義                       |
|----:|:-------------------------------|:-------------------------------|:-------------------------------|
|   1 | 2200_27011_1_not_null          | CHECK                          | type IS NOT NULL               |
|   2 | 2200_27011_2_not_null          | CHECK                          | entry_flag IS NOT NULL         |
|   3 | 2200_27011_3_not_null          | CHECK                          | entry_name IS NOT NULL         |
|   4 | 2200_27011_4_not_null          | CHECK                          | entry_disp IS NOT NULL         |
|   5 | media_pkc                      | PRIMARY KEY                    | type,entry_flag,entry_name,entry_disp |



## 外部キー情報

| No. | 外部キー名                     | カラムリスト                             | 参照先                         | 参照先カラムリスト                       | ON DELETE    | ON UPDATE    |
|----:|:-------------------------------|:-----------------------------------------|:-------------------------------|:-----------------------------------------|:-------------|:-------------|



## 外部キー情報(PK側)

| No. | 外部キー名                     | カラムリスト                             | 参照元                         | 参照元カラムリスト                       | ON DELETE    | ON UPDATE    |
|----:|:-------------------------------|:-----------------------------------------|:-------------------------------|:-----------------------------------------|:-------------|:-------------|



## トリガー情報

| No. | トリガー名                     | イベント                                 | タイミング           | 条件                           |
|----:|:-------------------------------|:-----------------------------------------|:---------------------|:-------------------------------|



## RDBMS固有の情報

| No. | プロパティ名                   | プロパティ値                                                                                         |
|----:|:-------------------------------|:-----------------------------------------------------------------------------------------------------|
|   1 | schemaname                     | public                                                                                               |
|   2 | tablename                      | media                                                                                                |
|   3 | tableowner                     | master                                                                                               |
|   4 | tablespace                     |                                                                                                      |
|   5 | hasindexes                     | True                                                                                                 |
|   6 | hasrules                       | False                                                                                                |
|   7 | hastriggers                    | False                                                                                                |
|   8 | rowsecurity                    | False                                                                                                |


