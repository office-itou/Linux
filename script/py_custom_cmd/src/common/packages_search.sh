#!/bin/bash

echo "# --------------------------------------------------"
echo "# 🔍 ソースコードから必要な apt-get パッケージ（python3-xxx）を抽出しています..."
echo "# --------------------------------------------------"
find . -type f -name "*.py" -exec awk '
    BEGINFILE {
        print "\n#📄 " FILENAME;
        count = 0;
        idx = 0;
        delete matches;
        delete basename;
    }
    {
        if ($0 ~ /^[[:space:]]*(import|from)[[:space:]]+/) {
            sub(/\..*/, "", $2);
            sub(/,.*/, "", $2);
            if ($2 != "" && $2 !~ /^(__[a-zA-Z]+__|my_|argparse|asyncio|collections|csv|dataclasses|datetime|email|fnmatch|inspect|json|locale|operator|os|pathlib|posixpath|resource|re|shutil|subprocess|sys|time|tkinter|traceback|typing|unicodedata|urllib)/) {
                if (!(basename[$2])) {
                    matches[count++] = "  python3-" $2;
                    basename[$2] = 1;
                }
            }
        }
    }
    ENDFILE {
        if (count > 0) {
            print "dpkg -l --no-pager \\";
            for (idx = 0; idx < count; idx++) {
                if (idx == count - 1) {
                    print matches[idx];
                } else {
                    print matches[idx] " \\";
                }
            }
        } else {
            print "#   (このファイルには外部パッケージの依存はありません)";
        }
    }
' {} \; | sed -E 's/([[:cntrl:]]\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK])//g'
echo "# --------------------------------------------------"
