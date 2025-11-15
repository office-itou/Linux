# -----------------------------------------------------------------------------
# descript: print out of all variables
#   input :            : unused
#   output:   stdout   : unused
#   return:            : unused
#   g-var :            : unused
#   memo  : https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
# shellcheck disable=SC2148,SC2317,SC2329
function fnDebugout_allparameters() {
	declare       __NAME=""				# variable name
	declare       __VALU=""				# "        value
	for __NAME in $(eval printf "%q\\\n" "\${!"{{A..Z},{a..z},_}"@}")
	do
		__NAME="${__NAME#\'}"
		__NAME="${__NAME%\'}"
		case "${__NAME:-}" in
			''     | \
			__NAME | \
			__VALU ) continue;;
			*) ;;
		esac
		__VALU="${!__NAME:-}"
		printf "%s=[%s]\n" "${__NAME:-}" "${__VALU:-}"
	done
}
