# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: put media information data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_FAIL : write
#   g-var : _LIST_PARM : read
#   g-var : _LIST_MDIA : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_mdia_Put() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	printf "%s\n" "${_LIST_MDIA[@]}" | awk -v list="${_LIST_PARM[*]}" '
		BEGIN {
			split(list, _arry, " ")
			delete _parm
			j = length(_arry)
			for (i in _arry) {
				_name=_arry[i]
				sub(/=.*$/, "", _name)
				_work=_name
				sub(/[[:alnum:]]+$/, "", _work)
				switch (_work) {
					case "_PATH_":
					case "_DIRS_":
					case "_FILE_":
						break
					default:
						continue
						break
				}
				_valu=_arry[i]
				sub(_name, "", _valu)
				sub(/^=/, "", _valu)
				_parm[j--]=_name"="_valu
			}
		}
		{
			_line=$0
			for (j in _parm) {
				_name=_parm[j]
				sub(/=.*$/, "", _name)
				_valu=_parm[j]
				sub(_name, "", _valu)
				sub(/^=/, "", _valu)
				_work=_name
				sub(/^_/, "", _work)
				gsub(_valu, ":_"_work"_:", _line)
			}
			split(_line, _arry, "\n")
			for (i in _arry) {
				split(_arry[i], _list, " ")
				printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n", \
					_list[1], _list[2], _list[3], _list[4], _list[5], _list[6], _list[7], _list[8], _list[9], _list[10], \
					_list[11], _list[12], _list[13], _list[14], _list[15], _list[16], _list[17], _list[18], _list[19], _list[20], \
					_list[21], _list[22], _list[23], _list[24], _list[25], _list[26], _list[27]
			}
		}
	' > "$1"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
