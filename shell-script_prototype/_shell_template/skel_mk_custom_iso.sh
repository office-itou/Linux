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

# :_tmpl_005_function_section_mk_custom_iso.sh_:

# --- initialization ----------------------------------------------------------
function funcInitialization() {
:
}

# --- debug out parameter -----------------------------------------------------
funcDebug_parameter() {
	declare       _VARS_CHAR="_"		# variable initial letter
	declare       _VARS_NAME=""			#          name
	declare       _VARS_VALU=""			#          value

#	if [[ -z "${_DBGS_FLAG:-}" ]]; then
#		return
#	fi

	# https://qiita.com/t_nakayama0714/items/80b4c94de43643f4be51#%E5%AD%A6%E3%81%B3%E3%81%AE%E6%88%90%E6%9E%9C%E3%82%92%E6%84%9F%E3%81%98%E3%82%8B%E3%83%AF%E3%83%B3%E3%83%A9%E3%82%A4%E3%83%8A%E3%83%BC
#	for _VARS_CHAR in {A..Z} {a..z} "_"
#	do
		for _VARS_NAME in $(eval printf "%q\\\n"  \$\{\!"${_VARS_CHAR}"\@\})
		do
			_VARS_NAME="${_VARS_NAME#\'}"
			_VARS_NAME="${_VARS_NAME%\'}"
			if [[ -z "${_VARS_NAME}" ]]; then
				continue
			fi
			case "${_VARS_NAME}" in
				_TEXT_*    | \
				_VARS_CHAR | \
				_VARS_NAME | \
				_VARS_VALU ) continue;;
				*) ;;
			esac
			_VARS_VALU="$(eval printf "%q" \$\{"${_VARS_NAME}":-\})"
			printf "%s=[%s]\n" "${_VARS_NAME}" "${_VARS_VALU/#\'\'/}"
		done
#	done
}

# --- help --------------------------------------------------------------------
function funcHelp() {
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g'
		usage: [sudo] ./${_PROG_PATH##*/} [command (options)]
		
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
	declare -i    _time_start=0			# start of elapsed time
	declare -i    _time_end=0			# end of elapsed time
	declare -i    _time_elapsed=0		# result of elapsed time
	declare -r -a _OPTN_PARM=("${@:-}")	# option parameter
	declare -a    _RETN_PARM=()			# name reference
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	declare -a    _LIST=()				# work variables
	declare -i    I=0					# work variables

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME}" != "root" ]]; then
		printf "${_CODE_ESCP}[m%s${_CODE_ESCP}[m\n" "run as root user."
		exit 1
	fi

	# --- get command line ----------------------------------------------------
	set -f -- "${_OPTN_PARM[@]:-}"
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
	_time_start=$(date +%s)
	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_start}" +"%Y/%m/%d %H:%M:%S" || true) processing start"

	# --- main ----------------------------------------------------------------
	funcInitialization					# initialization

	set -f -- "${_OPTN_PARM[@]:-}"
	while [[ -n "${1:-}" ]]
	do
		_RETN_PARM=()
		case "${1:-}" in
			create  )					# force create
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
						o) ;;
						*) continue;;
					esac
					if [[ -z "${_LIST[3]##-}" ]]; then
						continue
					fi
					if [[ -z "${_LIST[13]##-}" ]]; then
						continue
					fi
#					sleep 1
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "start" "${_LIST[13]##*/}" 1>&2
					# --- web original iso file -------------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "web original iso file" 1>&2
					_WORK="$(funcGetWebinfo "${_LIST[9]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[10]="${_ARRY[1]:--}"	# web_tstamp
					_LIST[11]="${_ARRY[2]:--}"	# web_size
					_LIST[12]="${_ARRY[3]:--}"	# web_status
					# --- local original iso file -----------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local original iso file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[13]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[13]="${_ARRY[0]:--}"	# iso_path
					_LIST[14]="${_ARRY[1]:--}"	# iso_tstamp
					_LIST[15]="${_ARRY[2]:--}"	# iso_size
					_LIST[16]="${_ARRY[3]:--}"	# iso_volume
					# --- local remastering iso file --------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local remastering iso file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[17]="${_ARRY[0]:--}"	# rmk_path
					_LIST[18]="${_ARRY[1]:--}"	# rmk_tstamp
					_LIST[19]="${_ARRY[2]:--}"	# rmk_size
					_LIST[20]="${_ARRY[3]:--}"	# rmk_volume
					# --- config file  ----------------------------
					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "config file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[23]##-}")"
					if [[ -n "${_LIST[23]##-}" ]] && [[ -d "${_LIST[23]}" ]]; then
						_WORK="$(funcGetFileinfo "${_LIST[23]##-}/user-data")"
					fi
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[23]="${_ARRY[0]:--}"	# cfg_path
					_LIST[24]="${_ARRY[1]:--}"	# cfg_tstamp
					# ---------------------------------------------------------
					if [[ -z "${_LIST[23]##-}" ]] || [[ -z "${_LIST[24]##-}" ]]; then
						continue
					fi
					funcRemastering "${_LIST[@]}"
					# --- new local remaster iso files ------------------------
					_WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[17]="${_ARRY[0]:--}"				# rmk_path
					_LIST[18]="${_ARRY[1]:--}"				# rmk_tstamp
					_LIST[19]="${_ARRY[2]:--}"				# rmk_size
					_LIST[20]="${_ARRY[3]:--}"				# rmk_volume
					# --- update media data record ----------------
					_LIST_MDIA[I]="${_LIST[*]}"
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${_LIST[13]##*/}" 1>&2
				done
				funcPut_media_data
				;;
			update  )					# create new files only
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
						o) ;;
						*) continue;;
					esac
					if [[ -z "${_LIST[3]##-}" ]]; then
						continue
					fi
					if [[ -z "${_LIST[13]##-}" ]]; then
						continue
					fi
#					sleep 1
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "start" "${_LIST[13]##*/}" 1>&2
					# --- web original iso file -------------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "web original iso file" 1>&2
					_WORK="$(funcGetWebinfo "${_LIST[9]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[10]="${_ARRY[1]:--}"	# web_tstamp
					_LIST[11]="${_ARRY[2]:--}"	# web_size
					_LIST[12]="${_ARRY[3]:--}"	# web_status
					# --- local original iso file -----------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local original iso file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[13]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[13]="${_ARRY[0]:--}"	# iso_path
					_LIST[14]="${_ARRY[1]:--}"	# iso_tstamp
					_LIST[15]="${_ARRY[2]:--}"	# iso_size
					_LIST[16]="${_ARRY[3]:--}"	# iso_volume
					# --- local remastering iso file --------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local remastering iso file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[17]="${_ARRY[0]:--}"	# rmk_path
					_LIST[18]="${_ARRY[1]:--}"	# rmk_tstamp
					_LIST[19]="${_ARRY[2]:--}"	# rmk_size
					_LIST[20]="${_ARRY[3]:--}"	# rmk_volume
					# --- config file  ----------------------------
#					printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "config file" 1>&2
					_WORK="$(funcGetFileinfo "${_LIST[23]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
#					_LIST[23]="${_ARRY[0]:--}"	# cfg_path
					_LIST[24]="${_ARRY[1]:--}"	# cfg_tstamp
					# ---------------------------------------------------------
					if [[ -z "${_LIST[23]##-}" ]] || [[ -z "${_LIST[24]##-}" ]]; then
						continue
					fi
					if [[ -n "${_LIST[13]##-}" ]] && [[ -n "${_LIST[14]##-}" ]] && [[ -n "${_LIST[15]##-}" ]]; then
						if [[ -n  "${_LIST[9]##-}" ]] && [[ -n "${_LIST[10]##-}" ]] && [[ -n "${_LIST[11]##-}" ]]; then
							if [[ -n "${_LIST[17]##-}" ]] && [[ -n "${_LIST[18]##-}" ]] && [[ -n "${_LIST[19]##-}" ]]; then
								_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[10]}")"
								if [[ "${_WORK}" -eq 0 ]] && [[ "${_LIST[15]}" -ne "${_LIST[11]}" ]]; then
									_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[18]}")"
									if [[ "${_WORK}" -lt 0 ]]; then
										continue
									fi
									if [[ -n "${_LIST[23]##-}" ]] && [[ -n "${_LIST[24]##-}" ]]; then
										_WORK="$(funcDateDiff "${_LIST[14]}" "${_LIST[24]}")"
										if [[ "${_WORK}" -lt 0 ]]; then
											continue
										fi
									fi
								fi
							fi
						fi
					fi
					funcRemastering "${_LIST[@]}"
					# --- new local remaster iso files ------------------------
					_WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
					read -r -a _ARRY < <(echo "${_WORK}")
					_LIST[17]="${_ARRY[0]:--}"				# rmk_path
					_LIST[18]="${_ARRY[1]:--}"				# rmk_tstamp
					_LIST[19]="${_ARRY[2]:--}"				# rmk_size
					_LIST[20]="${_ARRY[3]:--}"				# rmk_volume
					# --- update media data record ----------------
					_LIST_MDIA[I]="${_LIST[*]}"
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${_LIST[13]##*/}" 1>&2
				done
				funcPut_media_data
				;;
			download)					# download only
				shift
				for I in "${!_LIST_MDIA[@]}"
				do
					read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
					case "${_LIST[1]}" in
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
						create   ) shift; fncCreate_directory _RETN_PARM "${@:-}"; funcPut_media_data;;
						update   ) ;;
						download ) ;;
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
							for I in "${!_LIST_MDIA[@]}"
							do
								read -r -a _LIST < <(echo "${_LIST_MDIA[I]}")
#								case "${_LIST[1]}" in
#									o) ;;
#									*) continue;;
#								esac
								if [[ -z "${_LIST[3]##-}" ]]; then
									continue
								fi
#								if [[ -z "${_LIST[13]##-}" ]]; then
#									continue
#								fi
#								sleep 1
								printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "start: ${_LIST[2]//%20/ }" "${_LIST[13]##*/}" 1>&2
								# --- web original iso file -------------------
#								printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "web original iso file" 1>&2
								_WORK="$(funcGetWebinfo "${_LIST[9]##-}")"
								read -r -a _ARRY < <(echo "${_WORK}")
								_LIST[10]="${_ARRY[1]:--}"	# web_tstamp
								_LIST[11]="${_ARRY[2]:--}"	# web_size
								_LIST[12]="${_ARRY[3]:--}"	# web_status
								# --- local original iso file -----------------
#								printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local original iso file" 1>&2
								_WORK="$(funcGetFileinfo "${_LIST[13]##-}")"
								read -r -a _ARRY < <(echo "${_WORK}")
#								_LIST[13]="${_ARRY[0]:--}"	# iso_path
								_LIST[14]="${_ARRY[1]:--}"	# iso_tstamp
								_LIST[15]="${_ARRY[2]:--}"	# iso_size
								_LIST[16]="${_ARRY[3]:--}"	# iso_volume
								# --- local remastering iso file --------------
#								printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "local remastering iso file" 1>&2
								_WORK="$(funcGetFileinfo "${_LIST[17]##-}")"
								read -r -a _ARRY < <(echo "${_WORK}")
#								_ARRY[3]="${_LIST[16]}"
#								_LIST[17]="${_ARRY[0]:--}"	# rmk_path
								_LIST[18]="${_ARRY[1]:--}"	# rmk_tstamp
								_LIST[19]="${_ARRY[2]:--}"	# rmk_size
								_LIST[20]="${_ARRY[3]:--}"	# rmk_volume
								# --- config file  ----------------------------
#								printf "%20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "config file" 1>&2
								_WORK="$(funcGetFileinfo "${_LIST[23]##-}")"
								if [[ -n "${_LIST[23]##-}" ]] && [[ -d "${_LIST[23]}" ]]; then
									_WORK="$(funcGetFileinfo "${_LIST[23]##-}/user-data")"
								fi
								read -r -a _ARRY < <(echo "${_WORK}")
#								_LIST[23]="${_ARRY[0]:--}"	# cfg_path
								_LIST[24]="${_ARRY[1]:--}"	# cfg_tstamp
								# --- update media data record ----------------
								_LIST_MDIA[I]="${_LIST[*]}"
#								printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${_LIST[13]##*/}" 1>&2
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
				funcCreate_precon _RETN_PARM "${@:-}"
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
		_RETN_PARM=("${_RETN_PARM:-"${@:-}"}")
		IFS="${_COMD_IFS:-}"
		set -f -- "${_RETN_PARM[@]:-}"
		IFS="${_ORIG_IFS:-}"
	done

	# --- complete ------------------------------------------------------------
	_time_end=$(date +%s)
	_time_elapsed=$((_time_end-_time_start))

	printf "${_CODE_ESCP}[m${_CODE_ESCP}[45m%s${_CODE_ESCP}[m\n" "$(date -d "@${_time_end}" +"%Y/%m/%d %H:%M:%S" || true) processing end"
	printf "elapsed time: %dd%02dh%02dm%02ds\n" $((_time_elapsed/86400)) $((_time_elapsed%86400/3600)) $((_time_elapsed%3600/60)) $((_time_elapsed%60))
}

# *** main processing section *************************************************
	funcMain "${_PROG_PARM[@]:-}"
	exit 0

### eof #######################################################################
