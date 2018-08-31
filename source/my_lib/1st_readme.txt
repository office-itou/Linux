my library debug program について

・t_cdrom
  make方法：gcc -Wall t_cdrom.c my_cdrom.c my_file.c my_string.c -o t_cdrom
  実行方法：./t_cdrom *.cue -d
  実行内容：指定した cue/bin ファイルより toc 情報を読取り表示する。
