# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get media information data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _DBGS_FAIL : write
#   g-var : _LIST_MDIA : write
#   g-var : _LIST_PARM : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_mdia_Get() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	IFS= mapfile -d $'\n' -t _LIST_MDIA < <(awk -v list="${_LIST_PARM[*]}" '
		BEGIN {
			split(list, _arry, " ")
			delete _parm
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
				_parm[_name]=_valu
			}
		}
		{
			_line=$0
			while (1) {
				match(_line, /:_[[:alnum:]]+_[[:alnum:]]+_:/)
				if (RSTART == 0) {
					break
				}
				_ptrn=substr(_line, RSTART, RLENGTH)
				_name="_"substr(_line, RSTART+2, RLENGTH-4)
				gsub(_ptrn, _parm[_name], _line)
			}
			printf "%s\n", _line
		}
	' "$1" || true)

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
