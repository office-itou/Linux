#!/bin/bash

###############################################################################
##
##	pxeboot configuration shell
##	  developed for debian
##
##	developer   : J.Itou
##	release     : 2025/04/13
##
##	history     :
##	   data    version    developer    point
##	---------- -------- -------------- ----------------------------------------
##	2025/04/13 000.0000 J.Itou         first release
##
##	shellcheck -o all "filename"
##
###############################################################################

# :_tmpl_001_initialize_common.sh_:

# :_tmpl_001_initialize_mk_custom_iso.sh_:

# :_tmpl_002_data_section.sh_:

# :_tmpl_003_function_section_library.sh_:

# :_tmpl_003_function_section_library_network.sh_:

# :_tmpl_003_function_section_library_media.sh_:

# :_tmpl_003_function_section_library_initrd.sh_:

# :_tmpl_003_function_section_library_mkiso.sh_:

# :_tmpl_003_function_section_library_web_tool.sh_:

# :_tmpl_004_function_section_common.sh_:

# :_tmpl_005_function_section_common.sh_:

# :_tmpl_005_function_section_mk_custom_iso.sh_:

# --- initialization ----------------------------------------------------------
function funcInitialization() {
:
}

# --- debug out parameter -----------------------------------------------------
function funcDebug_parameter() {
	declare       __CHAR="_"			# variable initial letter
	declare       __NAME=""				#          name
	declare       __VALU=""				#          value

#	if [[ -z "${_DBGS_FLAG:-}" ]]; then
#		return
#	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for __CHAR in {A..Z} {a..z} "_"
#	do
		for __NAME in $(eval printf "%q\\\n"  \$\{\!"${__CHAR}"\@\})
		do
			__NAME="${__NAME#\'}"
			__NAME="${__NAME%\'}"
			if [[ -z "${__NAME}" ]]; then
				continue
			fi
			case "${__NAME}" in
				_TEXT_*| \
				__CHAR | \
				__NAME | \
				__VALU ) continue;;
				*) ;;
			esac
			__VALU="$(eval printf "%q" \$\{"${__NAME}":-\})"
			printf "%s=[%s]\n" "${__NAME}" "${__VALU/#\'\'/}"
		done
#	done
}

# --- help --------------------------------------------------------------------
function funcHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ./${_PROG_PATH:-"${0##*/}"}${_PROG_PATH##*/} [command (options)]
		
		  iso image files:
		    create|update|download [all|(mini|net|dvd|live {a|all|id})|version]
		      empty             : waiting for input
		      all               : all target
		      mini|net|dvd|live : each target
		        all             : all of each target
		        id number       : selected id
		
		  list files:
		    list [create|update|download]
		      empty             : display of list data
		      create            : update / download list files
		
		  config files:
		    conf [create]
		      create            : create common configuration file
		
		  pre-config files:
		    preconf [all|(preseed|nocloudkickstart|autoyast)]
		      all               : all pre-config files
		      preseed           : preseed.cfg
		      nocloud           : nocloud
		      kickstart         : kickstart.cfg
		      autoyast          : autoyast.xml
		
		  symbolic link:
		    link
		      create            : create symbolic link
		
		  debug print and test
		    debug [func|text|parm]
		      parm              : display of main internal parameters
_EOT_
}

# === main ====================================================================

function funcMain() {
	declare -i    __time_start=0		# start of elapsed time
	declare -i    __time_end=0			# end of elapsed time
	declare -i    __time_elapsed=0		# result of elapsed time
	declare -r -a __OPTN_PARM=("${@:-}") # option parameter
	declare -a    __RETN_PARM=()		# name reference
	declare -a    __OPTN=()				# option parameter
	declare       __TGET=""				# target
	declare       __RANG=""				# range
	declare       __RSLT=""				# result
	declare       __RETN=""				# return value
	declare -a    __MDIA=()				# selected media list by type
	declare -i    __RNUM=0				# record number
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables
	declare -i    J=0					# work variables

	# --- help ----------------------------------------------------------------
	if [[ -z "${__OPTN_PARM[*]:-}" ]]; then
		funcHelp
		exit 0
	fi
	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME:-"$(whoami || true)"}" != "root" ]]; then
		printf "${_CODE_ESCP:+"${_CODE_ESCP}[m"}${_CODE_ESCP:+"${_CODE_ESCP}[91m"}%s${_CODE_ESCP:+"${_CODE_ESCP}[m"}\n" "run as root user."
		exit 1
	fi
	# --- get command line ----------------------------------------------------
	set -f -- "${__OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		case "${1%%=*}" in
			--debug | \
			--dbg   ) shift; _DBGS_FLAG="true"; set -x;;
			--dbgout) shift; _DBGS_FLAG="true";;
			help    ) shift; funcHelp; exit 0;;
			*       ) shift;;
		esac
	done
	if set -o | grep "^xtrace\s*on$"; then
		_DBGS_FLAG="true"
		exec 2>&1
	fi

	# --- start ---------------------------------------------------------------
	__time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	funcInitialization					# initialization

	set -f -- "${__OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		__RETN_PARM=()
		case "${1:-}" in
			create  )					# (force create)
				shift
				__OPTN=("${@:-}")
				case "${1:-}" in
					a|all) shift; __OPTN=("mini" "all" "netinst" "all" "dvd" "all" "liveinst" "all" "${@:-}");;
					*    ) ;;
				esac
				__TGET=""
				set -f -- "${__OPTN[@]:-}"
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						mini    ) shift; __TGET="mini.iso";;
						netinst ) shift; __TGET="netinst";;
						dvd     ) shift; __TGET="dvd";;
						liveinst) shift; __TGET="live_install";;
#						live    ) shift; __TGET="live";;
#						tool    ) shift; __TGET="tool";;
#						clive   ) shift; __TGET="custom_live";;
#						cnetinst) shift; __TGET="custom_netinst";;
#						system  ) shift; __TGET="system";;
						*       ) break;;
					esac
					__RANG=""
					while [[ -n "${1:-}" ]]
					do
						case "${1,,}" in
							a|all                           ) __RANG="all"; shift; break;;
							[0-9]|[0-9][0-9]|[0-9][0-9][0-9]) __RANG="${__RANG:+"${__RANG} "}$1"; shift;;
							*                               ) break;;
						esac
					done
					# --- selection by media type -----------------------------
					funcPrint_menu "__RSLT" "create" "${__RANG:-"all"}" "${_LIST_MDIA[@]}"
					IFS= mapfile -d $'\n' -t __MDIA < <(printf "%s\n" "${__RSLT[@]}" || true)
					# --- select by input value -------------------------------
					if [[ -z "${__RANG:-}" ]]; then
						read -r -p "enter the number to create:" __RANG
					fi
					if [[ -z "${__RANG:-}" ]]; then
						continue
					fi
					case "${__RANG,,}" in
						a|all) __RANG="$(eval "echo {1..${#__MDIA[@]}}")";;
						*    ) ;;
					esac
					# --- main loop -------------------------------------------
					__RNUM=0
					for I in "${!__MDIA[@]}"
					do
						read -r -a __LIST < <(echo "${__MDIA[I]}")
						case "${__LIST[1]}" in
							o) ;;
							*) continue;;
						esac
						if [[ -z "${__LIST[3]##-}"  ]] \
						|| [[ -z "${__LIST[13]##-}" ]] \
						|| [[ -z "${__LIST[23]##-}" ]] || [[ -z "${__LIST[24]##-}" ]]; then
							continue
						fi
						if ! echo "$((++__RNUM))" | grep -qE '^('"${__RANG[*]// /\|}"')$'; then
							continue
						fi
						# --- start -------------------------------------------
						printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "start" "${__LIST[17]##*/}" 1>&2
						# --- conversion --------------------------------------
						for J in "${!__LIST[@]}"
						do
							__LIST[J]="${__LIST[J]##-}"		# empty
							__LIST[J]="${__LIST[J]//%20/ }"	# space
						done
						# --- download ----------------------------------------
						if [[ -n "${__LIST[9]##-}" ]]; then
							case "${__LIST[12]}" in
								200)
									# --- lnk_path ----------------------------
									if [[ -n "${__LIST[25]##-}" ]] && [[ ! -e "${__LIST[13]}" ]] && [[ ! -h "${__LIST[13]}" ]]; then
										funcPrintf "%20.20s: %s" "create symlink" "${__LIST[25]} -> ${__LIST[13]}"
										ln -s "${__LIST[25]%%/}/${__LIST[13]##*/}" "${__LIST[13]}"
									fi
									__RSLT="$(funcDateDiff "${__LIST[10]:-@0}" "${__LIST[14]:-@0}")"
									if [[ "${__RSLT}" -lt 0 ]]; then
										funcGetWeb_contents "${__LIST[13]}" "${__LIST[9]}"
									fi
									if [[ -n "${__LIST[13]}" ]]; then
										funcGetFileinfo __RETN "${__LIST[13]}"			# iso_path
										read -r -a __ARRY < <(echo "${__RETN:-"- - - -"}")
										__ARRY=("${__ARRY[@]##-}")
#										__LIST[13]="${__ARRY[0]:-}"						# iso_path
										__LIST[14]="${__ARRY[1]:-}"						# iso_tstamp
										__LIST[15]="${__ARRY[2]:-}"						# iso_size
										__LIST[16]="${__ARRY[3]:-}"						# iso_volume
									fi
									;;
								*  ) ;;
							esac
						fi
						# --- remastering -------------------------------------
						if [[ -s "${__LIST[13]}" ]]; then
							funcRemastering "${__LIST[@]}"
							# --- new local remaster iso files ----------------
							funcGetFileinfo "__RETN" "${__LIST[17]##-}"
							read -r -a __ARRY < <(echo "${__RETN}")
#							__LIST[17]="${__ARRY[0]:--}"		# rmk_path
							__LIST[18]="${__ARRY[1]:--}"		# rmk_tstamp
							__LIST[19]="${__ARRY[2]:--}"		# rmk_size
							__LIST[20]="${__ARRY[3]:--}"		# rmk_volume
						fi
						# --- conversion --------------------------------------
						for J in "${!__LIST[@]}"
						do
							__LIST[J]="${__LIST[J]:--}"		# empty
							__LIST[J]="${__LIST[J]// /%20}"	# space
						done
						# --- update media data record ------------------------
						__MDIA[I]="${__LIST[*]}"
						for J in "${!_LIST_MDIA[@]}"
						do
							read -r -a __ARRY < <(echo "${_LIST_MDIA[J]}")
							if [[ "${__LIST[0]}" != "${__ARRY[0]}" ]] \
							|| [[ "${__LIST[1]}" != "${__ARRY[1]}" ]] \
							|| [[ "${__LIST[2]}" != "${__ARRY[2]}" ]] \
							|| [[ "${__LIST[3]}" != "${__ARRY[3]}" ]]; then
								continue
							fi
							_LIST_MDIA[J]="${__LIST[*]}"
							break
						done
						# --- complete ----------------------------------------
						printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${__LIST[17]##*/}" 1>&2
					done
				done
				funcPut_media_data
				;;
			update  )					# (create new files only)
				shift
#				__RSLT="$(set -e; funcPrint_menu "update" "${_LIST_MDIA[@]}")"
				funcPrint_menu __RSLT "update" "${_LIST_MDIA[@]}"
				IFS= mapfile -d $'\n' -t _LIST_MDIA < <(echo -n "${__RSLT}")
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
					case "${__LIST[1]}" in
						o) ;;
						*) continue;;
					esac
					if [[ -z "${__LIST[3]##-}" ]]; then
						continue
					fi
					if [[ -z "${__LIST[13]##-}" ]]; then
						continue
					fi
					# ---------------------------------------------------------
					if [[ -z "${__LIST[23]##-}" ]] || [[ -z "${__LIST[24]##-}" ]]; then
						continue
					fi
					if [[ -n "${__LIST[13]##-}" ]] && [[ -n "${__LIST[14]##-}" ]] && [[ -n "${__LIST[15]##-}" ]]; then
						if [[ -n  "${__LIST[9]##-}" ]] && [[ -n "${__LIST[10]##-}" ]] && [[ -n "${__LIST[11]##-}" ]]; then
							if [[ -n "${__LIST[17]##-}" ]] && [[ -n "${__LIST[18]##-}" ]] && [[ -n "${__LIST[19]##-}" ]]; then
								__WORK="$(funcDateDiff "${__LIST[14]}" "${__LIST[10]}")"
								if [[ "${__WORK}" -eq 0 ]] && [[ "${__LIST[15]}" -ne "${__LIST[11]}" ]]; then
									__WORK="$(funcDateDiff "${__LIST[14]}" "${__LIST[18]}")"
									if [[ "${__WORK}" -lt 0 ]]; then
										continue
									fi
									if [[ -n "${__LIST[23]##-}" ]] && [[ -n "${__LIST[24]##-}" ]]; then
										__WORK="$(funcDateDiff "${__LIST[14]}" "${__LIST[24]}")"
										if [[ "${__WORK}" -lt 0 ]]; then
											continue
										fi
									fi
								fi
							fi
						fi
					fi
					funcRemastering "${__LIST[@]}"
					# --- new local remaster iso files ------------------------
					__WORK="$(funcGetFileinfo "${__LIST[17]##-}")"
					read -r -a __ARRY < <(echo "${__WORK}")
					__LIST[17]="${__ARRY[0]:--}"				# rmk_path
					__LIST[18]="${__ARRY[1]:--}"				# rmk_tstamp
					__LIST[19]="${__ARRY[2]:--}"				# rmk_size
					__LIST[20]="${__ARRY[3]:--}"				# rmk_volume
					# --- update media data record ----------------
					_LIST_MDIA[I]="${__LIST[*]}"
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${__LIST[13]##*/}" 1>&2
				done
				funcPut_media_data
				;;
			download)					# (download only)
				shift
#				__RSLT="$(set -e; funcPrint_menu "download" "${_LIST_MDIA[@]}")"
				funcPrint_menu __RSLT "download" "${_LIST_MDIA[@]}"
				IFS= mapfile -d $'\n' -t _LIST_MDIA < <(echo -n "${__RSLT}")
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
					case "${__LIST[1]}" in
						o) ;;
						*) continue;;
					esac
				done
				;;
			link    )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						create   ) shift; funcCreate_directory __RETN_PARM "${@:-}"; funcPut_media_data;;
						update   ) shift;;
						download ) shift;;
						*        ) break;;
					esac
				done
				;;
			list    )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						create   ) shift; funcPut_media_data;;
						update   ) 
							shift
#							__RSLT="$(set -e; funcPrint_menu "list" "${_LIST_MDIA[@]}")"
							funcPrint_menu __RSLT "list" "${_LIST_MDIA[@]}"
							IFS= mapfile -d $'\n' -t _LIST_MDIA < <(echo -n "${__RSLT}")
							for I in "${!_LIST_MDIA[@]}"
							do
								read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
#								case "${__LIST[1]}" in
#									o) ;;
#									*) continue;;
#								esac
								if [[ -z "${__LIST[3]##-}" ]]; then
									continue
								fi
#								if [[ -z "${__LIST[13]##-}" ]]; then
#									continue
#								fi
								# --- update media data record ----------------
								_LIST_MDIA[I]="${__LIST[*]}"
#								printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${__LIST[13]##*/}" 1>&2
							done
							# -------------------------------------------------
							funcPut_media_data
							;;
						download ) ;;
						*        ) break;;
					esac
				done
				;;
			conf    )
				shift
				case "${1:-}" in
					create   ) shift; funcCreate_conf;;
					*        ) ;;
				esac
				;;
			preconf )
				shift
				funcCreate_precon __RETN_PARM "${@:-}"
				;;
			help    ) shift; funcHelp; break;;
			debug   )
				shift
				while [[ -n "${1:-}" ]]
				do
					case "${1:-}" in
						parm) shift; funcDebug_parameter;;
						*   ) break;;
					esac
				done
				;;
			*       ) shift;;
		esac
		__RETN_PARM=("${__RETN_PARM:-"${@:-}"}")
		IFS="${_COMD_IFS:-}"
		set -f -- "${__RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
	done

	# --- complete ------------------------------------------------------------
	__time_end=$(date +%s)
	__time_elapsed=$((__time_end-__time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
