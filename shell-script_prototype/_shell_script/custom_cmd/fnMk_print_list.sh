# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: print media list
#   input :     $1     : type
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
function fnMk_print_list() {
	declare -n    __REFR="${1:?}"		# name reference
	declare -r    __TYPE="${2:?}"
	declare -a    __LIST=()
	declare       __FMTT=""
	declare -a    __MDIA=()
	declare       __RETN=""
	declare -a    __ARRY=()
	declare       __MESG=""
	declare       __FILE=""
	declare       __DIRS=""
	declare       __SEED=""
	declare       __BASE=""
	declare       __EXTE=""
	declare       __WORK=""
	declare       __COLR=""
	declare -i    I=0
#	declare -i    J=0

	IFS= mapfile -d $'\n' -t __LIST < <(\
		printf "%s\n" "${_LIST_MDIA[@]}" | \
		awk -v type="${__TYPE:?}" '$1==type && ($2=="m" || $2=="o") {print FNR-1, $0;}' \
	)
	__REFR="$(printf "%s\n" "${__LIST[@]:-}")"
	if [[ "${#__LIST[@]}" -eq 0 ]]; then
		return
	fi
	__FMTT="%2s:%-$((42+6*_COLS_SIZE/120))s:%-10s:%-10s:%-$((_COLS_SIZE-$((70+6*_COLS_SIZE/120))))s"
	printf "\033[m%c%s\033[m%c\n" "#" "${_TEXT_GAP2:1:$((_COLS_SIZE-2))}" "#"
	printf "\033[m%c${__FMTT}\033[m%c\n" "#" "ID" "Target file name" "ReleaseDay" "SupportEnd" "Memo" "#"
	for I in "${!__LIST[@]}"
	do
		read -r -a __MDIA < <(echo "${__LIST[I]}")
		__MDIA=("${__MDIA[@]//%20/ }")
		case "${__MDIA[2]}" in
			o) ;;
			*) continue;;
		esac
		# --- web file ----------------------------------------------------
		__RETN="- - - - -"
		if [[ -n "$(fnTrim "${__MDIA[9]}" "-")" ]]; then
			__RETN="$(fnGetWebinfo "${__MDIA[9]}" "${_COMD_WGET:-}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[10]="${__ARRY[0]:-}"	# web_path
		__MDIA[11]="${__ARRY[1]:-}"	# web_tstamp
		__MDIA[12]="${__ARRY[2]:-}"	# web_size
		__MDIA[13]="${__ARRY[3]:-}"	# web_status
		__MESG="$(fnTrim "${__ARRY[4]:-}" "-")"	# message
		__MESG="${__MESG//%20/ }"
		case "${__MDIA[13]}" in
			2[0-9][0-9])
				__MESG=""
				__FILE="$(fnBasename "${__MDIA[10]}")"
				if [[ -n "${__FILE:-}" ]]; then
					case "${__FILE}" in
						mini.iso) ;;
						*       )
							__DIRS="$(fnDirname "${__MDIA[14]}")"
							__MDIA[14]="${__DIRS:-}/${__FILE}"	# iso_path
							;;
					esac
				fi
				;;
			*) ;;
		esac
		# --- iso file ----------------------------------------------------
		__RETN="- - - -"
		if [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[14]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[15]="${__ARRY[1]:-}"	# iso_tstamp
		__MDIA[16]="${__ARRY[2]:-}"	# iso_size
		__MDIA[17]="${__ARRY[3]:-}"	# iso_volume
		# --- conf file ---------------------------------------------------
		__RETN="- - - -"
		if [[ -n "$(fnTrim "${__MDIA[24]}" "-")" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[24]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[25]="${__ARRY[1]:-}"	# rmk_tstamp
		# --- rmk file ----------------------------------------------------
		if [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]] \
		&& [[ -n "$(fnTrim "${__MDIA[18]}" "-")" ]] \
		&& [[ -n "$(fnTrim "${__MDIA[24]}" "-")" ]]; then
			__SEED="${__MDIA[24]%/*}"
			__SEED="${__SEED##*/}"
			__FILE="${__MDIA[24]#*"${__SEED:+"${__SEED}/"}"}"
			if [[ -n "$(fnTrim "${__FILE}" "-")" ]]; then
				__DIRS="$(fnDirname "${__MDIA[18]}")"
				__BASE="$(fnBasename "${__MDIA[14]}")"
				__FILE="${__BASE%.*}"
				__EXTE="${__BASE#"${__FILE:+"${__FILE}."}"}"
				__MDIA[18]="${__DIRS:-}/${__FILE}${__SEED:+"_${__SEED}"}${__EXTE:+".${__EXTE}"}"
			fi
		fi
		__RETN="- - - -"
		if [[ -n "$(fnTrim "${__MDIA[18]}" "-")" ]]; then
			__RETN="$(fnGetFileinfo "${__MDIA[18]}")"
		fi
		read -r -a __ARRY < <(echo "${__RETN}")
		__MDIA[19]="${__ARRY[1]:-}"	# rmk_tstamp
		__MDIA[20]="${__ARRY[2]:-}"	# rmk_size
		__MDIA[21]="${__ARRY[3]:-}"	# rmk_volume
		# --- decision on next process ------------------------------------
		# download: light blue
		# create  : green
		# error   : red
		__MDIA[27]="-"				# create_flag
		if [[ -n "$(fnTrim "${__MDIA[10]}" "-")" ]] \
		&& [[ -n "$(fnTrim "${__MDIA[14]}" "-")" ]]; then
			case "${__MDIA[13]}" in
				2[0-9][0-9])
					if [[ ! -e "${__MDIA[14]}" ]]; then
						__MDIA[27]="d"	# create_flag (download: original file not found)
					elif [[ "${__MDIA[11]:-}" != "${__MDIA[15]:-}" ]] \
					||   [[ "${__MDIA[12]:-}" != "${__MDIA[16]:-}" ]]; then
						__MDIA[27]="d"	# create_flag (download: timestamp or size differs)
					elif [[ -n "$(fnTrim "${__MDIA[24]}" "-")" ]] \
					&&   [[ -n "$(fnTrim "${__MDIA[18]}" "-")" ]]; then
						if   [[ ! -e "${__MDIA[18]}" ]]; then
							__MDIA[27]="c"	# create_flag (create: remake file not found)
						elif [[ "${__MDIA[15]:-}" -gt "${__MDIA[19]:-}" ]] \
						||   [[ "${__MDIA[25]:-}" -gt "${__MDIA[19]:-}" ]]; then
							__MDIA[27]="c"	# create_flag (create: remake file is out of date)
						else
							__WORK="$(find -L "${_DIRS_SHEL:?}" -newer "${__MDIA[18]}" -name 'auto*sh')"
							if [[ -n "${__WORK:-}" ]]; then
								__MDIA[27]="c"	# create_flag (create: remake file is out of date)
							fi
						fi
					fi
					;;
				*) __MDIA[27]="e";;	# create_flag (error: communication failure)
			esac
		fi
		case "${__MDIA[27]:-}" in
			d) __COLR="96";;	# download
			c) __COLR="92";;	# create
			e) __COLR="91";;	# error
			*) __COLR="";;
		esac
		__BASE="$(fnBasename "${__MDIA[14]}")"
		__SEED="$(fnBasename "${__MDIA[24]}")"
		__RDAT="$(fnTrim "${__MDIA[7]%%%20*}" "-")"
		__SUPE="$(fnTrim "${__MDIA[8]%%%20*}" "-")"
		__MESG="$(fnTrim "${__MESG:-"${__SEED}"}" "-")"
		[[ -n "$(fnTrim "${__MDIA[15]}" "-")" ]] && __RDAT="$(fnTrim "${__MDIA[15]%%%20*}" "-")"	# iso_tstamp
		[[ -n "$(fnTrim "${__MDIA[11]}" "-")" ]] && __RDAT="$(fnTrim "${__MDIA[11]%%%20*}" "-")"	# web_tstamp
		printf "\033[m%c\033[%sm${__FMTT}\033[m%c\n" "#" "${__COLR:-}" "${I}" "${__BASE}" "${__RDAT:-"20xx-xx-xx"}" "${__SUPE:-"20xx-xx-xx"}" "${__MESG:-}" "#"
		# --- data registration -------------------------------------------
		__MDIA=("${__MDIA[@]// /%20}")
		__LIST[I]="${__MDIA[*]}"
#		J="${__MDIA[0]}"
#		_LIST_MDIA[J]="$(
#			printf "%-11s %-11s %-39s %-39s %-23s %-23s %-15s %-15s %-143s %-143s %-47s %-15s %-15s %-87s %-47s %-15s %-43s %-87s %-47s %-15s %-43s %-87s %-87s %-87s %-47s %-87s %-11s \n" \
#			"${__MDIA[@]:1}"
#		)"
	done
	printf "\033[m%c%s\033[m%c\n" "#" "${_TEXT_GAP2:1:$((_COLS_SIZE-2))}" "#"
	__REFR="$(printf "%s\n" "${__LIST[@]:-}")"

	unset __LIST __FMTT __MDIA __RETN __ARRY __MESG __FILE __DIRS __SEED __BASE __EXTE __WORK __COLR I J
}
