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
	declare -i    __time_start=0		# start of elapsed time
	declare -i    __time_end=0			# end of elapsed time
	declare -i    __time_elapsed=0		# result of elapsed time
	declare -r -a __OPTN_PARM=("${@:-}") # option parameter
	declare -a    __RETN_PARM=()		# name reference
	declare -a    __RANG=()				# range
	declare       __RSLT=""				# result
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	declare -a    __LIST=()				# work variables
	declare -i    I=0					# work variables

	# --- check the execution user --------------------------------------------
	if [[ "${_USER_NAME}" != "root" ]]; then
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
#				funcPrint_menu __RSLT "create" "${_LIST_MDIA[@]}"
#				IFS= mapfile -d $'\n' -t _LIST_MDIA < <(echo -n "${__RSLT}")
#				for I in "${!_LIST_MDIA[@]}"
#				do
#					read -r -a __LIST < <(echo "${_LIST_MDIA[I]}")
#set -x
#printf "%-100.100s\n" "${_LIST_MDIA[@]}"
				IFS= mapfile -d $'\n' -t __RANG < <(printf "%s\n" "${_LIST_MDIA[@]}" | awk '/mini.iso/' || true)
				funcPrint_menu __RSLT "create" "${__RANG[@]}"
				IFS= mapfile -d $'\n' -t __RANG < <(echo -n "${__RSLT}")
				for I in "${!__RANG[@]}"
				do
					read -r -a __LIST < <(echo "${__RANG[I]}")
#					case "${__LIST[0]}" in
#						mini.iso      ) ;;
#						netinst       ) ;;
#						dvd           ) ;;
#						live_install  ) ;;
#						live          ) continue;;
#						tool          ) continue;;
#						custom_live   ) continue;;
#						custom_netinst) continue;;
#						system        ) continue;;
#						*             ) continue;;
#					esac
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
#					funcPrint_menu __RSLT "create" "${__LIST[*]}"
#					IFS= mapfile -d $'\n' -t _LIST_MDIA < <(echo -n "${__RSLT}")
					funcRemastering "${__LIST[@]}"
					# --- new local remaster iso files ------------------------
#					__WORK="$(funcGetFileinfo "${__LIST[17]##-}")"
#					read -r -a __ARRY < <(echo "${__WORK}")
##					__LIST[17]="${__ARRY[0]:--}"				# rmk_path
#					__LIST[18]="${__ARRY[1]:--}"				# rmk_tstamp
#					__LIST[19]="${__ARRY[2]:--}"				# rmk_size
#					__LIST[20]="${__ARRY[3]:--}"				# rmk_volume
					# --- update media data record ----------------
#					_LIST_MDIA[I]="${__LIST[*]}"
#					printf "%20.20s: %-20.20s: %s\n" "$(date +"%Y/%m/%d %H:%M:%S" || true)" "complete" "${__LIST[13]##*/}" 1>&2
				done
#				funcPut_media_data
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
						create   ) shift; fncCreate_directory __RETN_PARM "${@:-}"; funcPut_media_data;;
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
