# **bashの変数展開**

* ## 機能一覧

  |   機能                                    |   変数展開                        |
  |   :-----------------------------------    |   :---------------------------    |
  |   空文字列または未定義時エラー(word出力)  |   ${parameter:?word}              |
  |   未定義時置換(代入なし)                  |   ${parameter-word}               |
  |   未定義時置換(代入あり)                  |   ${parameter=word}               |
  |   定義時置換(代入なし)                    |   ${parameter+word}               |
  |   空文字列または未定義時置換(代入なし)    |   ${parameter:-word}              |
  |   空文字列または未定義時置換(代入あり)    |   ${parameter:=word}              |
  |   文字列をwordに置換(代入なし)            |   ${parameter:+word}              |
  |   部分文字列の取得                        |   ${parameter:offset}             |
  |   部分文字列の取得(取得文字数あり)        |   ${parameter:offset:length}      |
  |   前方一致変数名                          |   ${!prefix*}                     |
  |   前方一致変数名(別々の単語に展開)        |   ${!prefix@}                     |
  |   配列のキーリスト                        |   ${!name[*]}                     |
  |   配列のキーリスト(別々の単語に展開)      |   ${!name[@]}                     |
  |   文字数                                  |   ${#parameter}                   |
  |   位置パラメータ数                        |   ${#parameter}                   |
  |   要素数                                  |   ${#parameter}                   |
  |   前方一致削除(最短一致)                  |   ${parameter#word}               |
  |   前方一致削除(最長一致)                  |   ${parameter##word}              |
  |   後方一致削除(最短一致)                  |   ${parameter%word}               |
  |   後方一致削除(最長一致)                  |   ${parameter%%word}              |
  |   部分文字列置換(最短一致)                |   ${parameter/pattern/string}     |
  |   部分文字列置換(最長一致)                |   ${parameter//pattern/string}    |
  |   前方一致置換                            |   ${parameter/#pattern/string}    |
  |   後方一致置換                            |   ${parameter/%pattern/string}    |
  |   大文字化(先頭文字のみ)                  |   ${parameter^pattern}            |
  |   大文字化(全文字列)                      |   ${parameter^^pattern}           |
  |   小文字化(先頭文字のみ)                  |   ${parameter,pattern}            |
  |   小文字化(全文字列)                      |   ${parameter,,pattern}           |
  |   parameterの名前と定義内容の出力         |   ${parameter@A}                  |
  |   エスケープシーケンスの解釈              |   ${parameter@E}                  |
  |   シングルクォーテーションの追加          |   ${parameter@K}                  |
  |   小文字化(全文字列)                      |   ${parameter@L}                  |
  |   エスケープシーケンスの解釈              |   ${parameter@P}                  |
  |   シングルクォーテーションの追加          |   ${parameter@Q}                  |
  |   大文字化(全文字列)                      |   ${parameter@U}                  |
  |   parameterの属性(ar)                     |   ${parameter@a}                  |
  |   シングルクォーテーションの追加          |   ${parameter@k}                  |
  |   大文字化(先頭文字のみ)                  |   ${parameter@u}                  |

* ## 参照

  * [【シェル芸人への道】Bashの変数展開と真摯に向き合う](https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51)

* ## 実行例

  * ### スクリプト(param.sh)

    ``` bash: param.sh
    #!/bin/bash

    set -eu

    declare -r -a parameter=("${@:-}")
    declare -r -i offset=8
    declare -r -i length=4

    # [[ -n "${2:-}" ]] && unset parameter

    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:?word}"           "${parameter:?word}"			# 空文字列または未定義時エラー(word出力)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter-word}"            "${parameter-word}"			# 未定義時置換(代入なし)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter=word}"            "${parameter=word}"			# 未定義時置換(代入あり)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter+word}"            "${parameter+word}"			# 定義時置換(代入なし)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:-word}"           "${parameter:-word}"			# 空文字列または未定義時置換(代入なし)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:=word}"           "${parameter:=word}"			# 空文字列または未定義時置換(代入あり)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:+word}"           "${parameter:+word}"			# 文字列をwordに置換(代入なし)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:offset}"          "${parameter:offset}"			# 部分文字列の取得
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter:offset:length}"   "${parameter:offset:length}"	# 部分文字列の取得(取得文字数あり)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${!prefix*}"                  "${!p*}"						# 前方一致変数名
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${!prefix@}"                  "${!p@}"						# 前方一致変数名(別々の単語に展開)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${!name[*]}"                  "${!arry[*]}"					# 配列のキーリスト
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${!name[@]}"                  "${!arry[@]}"					# 配列のキーリスト(別々の単語に展開)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${#parameter}"                "${#parameter}"				# 文字数
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${#parameter}"                "${#@}"						# 位置パラメータ数
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${#parameter}"                "${#parameter[@]}"				# 要素数
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter#word}"            "${parameter#*word}"			# 前方一致削除(最短一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter##word}"           "${parameter##*word}"			# 前方一致削除(最長一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter%word}"            "${parameter%*word}"			# 後方一致削除(最短一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter%%word}"           "${parameter%%*word}"			# 後方一致削除(最長一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter/pattern/string}"  "${parameter/pattern/string}"	# 部分文字列置換(最短一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter//pattern/string}" "${parameter//pattern/string}"	# 部分文字列置換(最長一致)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter/#pattern/string}" "${parameter/#pattern/string}"	# 前方一致置換
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter/%pattern/string}" "${parameter/%pattern/string}"	# 後方一致置換
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter^pattern}"         "${parameter^}"				# 大文字化(先頭文字のみ)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter^^pattern}"        "${parameter^^}"				# 大文字化(全文字列)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter,pattern}"         "${parameter,}"				# 小文字化(先頭文字のみ)
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter,,pattern}"        "${parameter,,}"				# 小文字化(全文字列)

    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@A}"               "${parameter@A}"				# parameterの名前と定義内容の出力
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@B}"               "${parameter@B}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@C}"               "${parameter@C}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@D}"               "${parameter@D}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@E}"               "${parameter@E}"				# エスケープシーケンスの解釈 
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@F}"               "${parameter@F}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@G}"               "${parameter@G}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@H}"               "${parameter@H}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@I}"               "${parameter@I}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@J}"               "${parameter@J}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@K}"               "${parameter@K}"				# シングルクォーテーションの追加
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@L}"               "${parameter@L}"				# 小文字化(全文字列)
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@M}"               "${parameter@M}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@N}"               "${parameter@N}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@O}"               "${parameter@O}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@P}"               "${parameter@P}"				# エスケープシーケンスの解釈 
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@Q}"               "${parameter@Q}"				# シングルクォーテーションの追加
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@R}"               "${parameter@R}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@S}"               "${parameter@S}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@T}"               "${parameter@T}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@U}"               "${parameter@U}"				# 大文字化(全文字列)
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@V}"               "${parameter@V}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@W}"               "${parameter@W}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@X}"               "${parameter@X}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@Y}"               "${parameter@Y}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@Z}"               "${parameter@Z}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@a}"               "${parameter@a}"				# parameterの属性(ar)
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@b}"               "${parameter@b}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@c}"               "${parameter@c}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@d}"               "${parameter@d}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@e}"               "${parameter@e}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@f}"               "${parameter@f}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@g}"               "${parameter@g}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@h}"               "${parameter@h}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@i}"               "${parameter@i}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@j}"               "${parameter@j}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@k}"               "${parameter@k}"				# シングルクォーテーションの追加
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@l}"               "${parameter@l}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@m}"               "${parameter@m}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@n}"               "${parameter@n}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@o}"               "${parameter@o}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@p}"               "${parameter@p}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@q}"               "${parameter@q}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@r}"               "${parameter@r}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@s}"               "${parameter@s}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@t}"               "${parameter@t}"				#
    printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@u}"               "${parameter@u}"				# 大文字化(先頭文字のみ)
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@v}"               "${parameter@v}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@w}"               "${parameter@w}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@x}"               "${parameter@x}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@y}"               "${parameter@y}"				#
    #printf "%s: %s: [%s]\n" "${parameter:-}" "\${parameter@z}"               "${parameter@z}"				#
    ```

  * ### 実行結果

    ``` bash:
    $ ./param.sh "\033[42mHoge-Fuga\033[m"
    \033[42mHoge-Fuga\033[m: ${parameter:?word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter-word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter=word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter+word}: [word]
    \033[42mHoge-Fuga\033[m: ${parameter:-word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter:=word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter:+word}: [word]
    \033[42mHoge-Fuga\033[m: ${parameter:offset}: [Hoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter:offset:length}: [Hoge]
    \033[42mHoge-Fuga\033[m: ${!prefix*}: [parameter]
    \033[42mHoge-Fuga\033[m: ${!prefix@}: [parameter]
    \033[42mHoge-Fuga\033[m: ${!name[*]}: []
    \033[42mHoge-Fuga\033[m: ${!name[@]}: []
    \033[42mHoge-Fuga\033[m: ${#parameter}: [23]
    \033[42mHoge-Fuga\033[m: ${#parameter}: [1]
    \033[42mHoge-Fuga\033[m: ${#parameter}: [1]
    \033[42mHoge-Fuga\033[m: ${parameter#word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter##word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter%word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter%%word}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter/pattern/string}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter//pattern/string}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter/#pattern/string}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter/%pattern/string}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter^pattern}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter^^pattern}: [\033[42MHOGE-FUGA\033[M]
    \033[42mHoge-Fuga\033[m: ${parameter,pattern}: [\033[42mHoge-Fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter,,pattern}: [\033[42mhoge-fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter@A}: [declare -ar parameter='\033[42mHoge-Fuga\033[m']
    \033[42mHoge-Fuga\033[m: ${parameter@E}: [Hoge-Fuga]
    \033[42mHoge-Fuga\033[m: ${parameter@K}: ['\033[42mHoge-Fuga\033[m']
    \033[42mHoge-Fuga\033[m: ${parameter@L}: [\033[42mhoge-fuga\033[m]
    \033[42mHoge-Fuga\033[m: ${parameter@P}: [Hoge-Fuga]
    \033[42mHoge-Fuga\033[m: ${parameter@Q}: ['\033[42mHoge-Fuga\033[m']
    \033[42mHoge-Fuga\033[m: ${parameter@U}: [\033[42MHOGE-FUGA\033[M]
    \033[42mHoge-Fuga\033[m: ${parameter@a}: [ar]
    \033[42mHoge-Fuga\033[m: ${parameter@k}: ['\033[42mHoge-Fuga\033[m']
    \033[42mHoge-Fuga\033[m: ${parameter@u}: [\033[42mHoge-Fuga\033[m]
    ```
