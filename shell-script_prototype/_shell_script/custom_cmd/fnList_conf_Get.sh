# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get common configuration data
#   input :     $1     : target file name
#   output:   stdout   : message
#   return:            : unused
#   g-var : _LIST_CONF : write
# shellcheck disable=SC2148,SC2317,SC2329
function fnList_conf_Get() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	IFS= mapfile -d $'\n' -t _LIST_CONF < <(awk '
		{
			delete _parm
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
					sub(/^="*/, "", _valu)
					sub(/"* *$/, "", _valu)
					_wval=_valu
					while (1) {
						match(_wval, /:_[[:alnum:]]+_[[:alnum:]]+_:/)
						if (RSTART == 0) {
						break
						}
						_ptrn=substr(_wval, RSTART, RLENGTH)
						_wnam=substr(_ptrn, 3, length(_ptrn)-4)
						sub(_ptrn, _parm[_wnam], _wval)
					}
					_parm[_name]=_wval
					_start=index(_line, _valu)
					if (_start > 0) {
						_line=sprintf("%s%s%s", substr(_line, 1, _start-1), _wval, substr(_line, _start+length(_valu)))
					}
				}
				printf "%s\n", _line
			} while ((getline) > 0)
		}
	' "$1" || true)
	while read -r __LINE
	do
		__NAME="${__LINE%%=*}"
		__VALU="${__LINE#"${__NAME}="}"
		__NAME="${__NAME:+"_${__NAME}"}"
		read -r "${__NAME:?}" < <(eval echo "${__VALU}" || true)
		_LIST_PARM+=("${__NAME}=${!__NAME}")
	done < <(printf "%s\n" "${_LIST_CONF[@]:-}" | grep -E '^[[:alnum:]]+_[[:alnum:]]+=')

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
