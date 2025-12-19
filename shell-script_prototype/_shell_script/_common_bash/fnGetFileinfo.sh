# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: get file information data
#   input :     $1     : file name
#   output:   stdout   : output (path,time stamp,size,volume id)
#   return:            : unused
#   g-var :            : unused
# shellcheck disable=SC2148,SC2317,SC2329
function fnGetFileinfo() {
	declare       __INFO=""				# file path / size / timestamp
	declare       __VLID=""				# volume id
	declare -a    __LIST=()				# data list
	__LIST=("-" "-" "-")
	__VLID="-"
	__INFO="$(LANG=C find "${1%/*}" -name "${1##*/}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s")"
	if [[ -n "${__INFO:-}" ]]; then
		read -r -a __LIST < <(echo "${__INFO}")
		__LIST[1]="$(TZ=UTC date -d "${__LIST[1]//%20/ }" "+%Y-%m-%d%%20%H:%M:%S%z")"
		__VLID="$(blkid -s LABEL -o value "${1}")"
	fi
	printf "%s %s %s %s" "${__LIST[0]// /%20}" "${__LIST[1]// /%20}" "${__LIST[2]// /%20}" "${__VLID// /%20}"
}
