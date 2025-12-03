# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: put common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _LIST_CONF : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_conf_Put() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	printf "%s\n" "${_LIST_CONF[@]}" | awk -v list="${_LIST_PARM[*]}" '
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
			do {
				_line=$0
				match(_line, /^[[:alnum:]]+_[[:alnum:]]+=/)
				if (RSTART > 0) {
					_name=substr(_line, RSTART, RLENGTH)
					sub(/=.*$/, "", _name)
					_cmnt=_line
					sub(/^[^#]+/, "", _cmnt)
					_valu=_line
					_start=index(_valu, _name)
					if (_start > 0) {
						_valu=substr(_valu, _start+length(_name))
					}
					_start=index(_valu, _cmnt)
					if (_start > 0) {
						_valu=substr(_valu, 1, _start-1)
					}
					sub(/^=*/, "", _valu)
					sub(/ *$/, "", _valu)
					for (j in _parm) {
						_wnam=_parm[j]
						sub(/=.*$/, "", _wnam)
						_wval=_parm[j]
						sub(_wnam, "", _wval)
						sub(/^=/, "", _wval)
						_work=_wnam
						sub(/^_/, "", _work)
						if (_work != _name) {
							gsub(_wval, ":_"_work"_:", _valu)
						}
					}
					_line=sprintf("%-39s %s",_name"="_valu, _cmnt)
				}
				printf "%s\n", _line
			} while ((getline) > 0)
		}
	' > "$1"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
