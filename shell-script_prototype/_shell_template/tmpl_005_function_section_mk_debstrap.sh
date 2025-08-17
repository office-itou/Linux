# shellcheck disable=SC2148
# === <creating> ==============================================================

function fnCreate_debian() {
	fnDebugout ""
	declare -r    __TGET="${1:?}"		 					# target
	declare -r    __CODE="${2:?}"							# code name
	declare -r    __COMP="${3:-}"							# components
	declare -r    __PACK="${4:-}"							# packages
	declare -r    __KEYS="${_DIRS_KEYS}"					# keyring
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"			# target directory
	declare -r    __HOOK="rm -f \$1/etc/hostname"
	declare -r -a __OPTN=( \
		"--variant=minbase" \
		"--mode=sudo" \
		"--format=directory" \
		"${__KEYS:+--keyring=${__KEYS//,/ }}" \
		"${__PACK:+--include=${__PACK//,/ }}" \
		"${__COMP:+--components=${__COMP//,/ }}" \
		"${__HOOK:+--customize-hook=${__HOOK}}" \
		"${__CODE}" \
		"${__DIRS}" \
	)
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	# shellcheck disable=SC2016
	mmdebstrap "${__OPTN[@]}"
}

function fnCreate_rhel() {
	fnDebugout ""
	declare -r    __TGET="${1:?}"		 										# target
	declare -r    __PACK="${2:-}"												# packages
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"								# target directory
	declare -r    __REPO="${_DIRS_CONF}/_repository/${__TGET%-*}.repo"			# repository
	declare -r    __VERS="${__TGET##*-}"										# release verion
	declare -a    __INST=( \
		"--assumeyes" \
		"--config=${__REPO}" \
		"--installroot=${__DIRS}" \
		"--releasever=${__VERS}" \
		"install" \
		"dnf" \
		"dnf-command(config-manager)" \
	)
	case "${__TGET}" in
		rockylinux-*   ) __INST+=("rocky-repos");;
		*              ) __INST+=("${__TGET%-*}-repos");;
	esac
	declare -a    __EPEL=( \
		"${__DIRS}" \
		"dnf" \
		"--assumeyes" \
		"install" \
		"epel-release" \
	)
	declare -a    __INCL=()
	read -r -a __INCL < <(echo "${__PACK//,/ }")
	declare -r -a __OPTN=( \
		"${__DIRS}" \
		"dnf" \
		"--assumeyes" \
		"install" \
		"${__INCL[@]}" \
	)
	declare       __STAT=""				# work variables
	declare       __WORK=""				# work variables
	case "${__TGET}" in
		fedora-*       ) __EPEL=();;
		miraclelinux-* ) __EPEL=();;
		centos-stream-*) ;;
		*              ) ;;
	esac
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	dnf "${__INST[@]:-}"
	mount -t proc /proc/         "${__DIRS}/proc/"                                         && _LIST_RMOV+=("${__DIRS}/proc/" )
	mount --rbind /sys/          "${__DIRS}/sys/"  && mount --make-rslave "${__DIRS}/sys/" && _LIST_RMOV+=("${__DIRS}/sys/" )
	[[ -L "${__DIRS}/etc/resolv.conf" ]] && mkdir -p "${__DIRS}/run/systemd/resolve/"
	echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > "${__DIRS}/etc/resolv.conf"
	if [[ -n "${__EPEL[*]:-}" ]]; then
		if ! chroot "${__EPEL[@]:-}"; then
			__STAT="$?"
			printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%-10.10s: %s${_CODE_ESCP}[m\n${_CODE_ESCP}[m${_CODE_ESCP}[93m%s${_CODE_ESCP}[m\n" "error" "${__TGET}" "EPEL: ${__EPEL[*]:-}"
		fi
	fi
	if ! chroot "${__OPTN[@]:-}"; then
		__STAT="$?"
		printf "${_CODE_ESCP}[m${_CODE_ESCP}[41m%-10.10s: %s${_CODE_ESCP}[m\n${_CODE_ESCP}[m${_CODE_ESCP}[93m%s${_CODE_ESCP}[m\n" "error" "${__TGET}" "OPTN: ${__OPTN[*]:-}"
	fi
	[[ -e "${__DIRS}/etc/resolv.conf.orig" ]] && mv -b "${__DIRS}/etc/resolv.conf.orig" "${__DIRS}/etc/resolv.conf"
	umount --recursive     "${__DIRS}/sys/"
	umount                 "${__DIRS}/proc/"
	if [[ -n "${__STAT:-}" ]]; then
		exit "${__STAT}"
	fi
}

function fnCreate_opensuse() {
	declare -r    __TGET="${1:?}"		 					# target
	declare -r    __PACK="${2:-}"							# packages
	declare -r    __DIRS="${_DIRS_CHRT}/${__TGET}"			# target directory
	declare -r    __REPO="${_DIRS_CONF}/_repository/"		# repository
	declare -r    __VERS="${__TGET##*-}"					# release verion
	declare -a    __INST=()
	read -r -a __INST < <(echo "${__PACK//,/ }")
	rm -rf --one-file-system "${__DIRS:?}"
	mkdir -p "${__DIRS}"
	zypper \
		--non-interactive \
		--reposd-dir "${__REPO}" \
		--no-gpg-checks \
		--installroot "${__DIRS}" \
		--releasever "${__VERS}" \
		install \
			"${__INST[@]}"

}

# -----------------------------------------------------------------------------
# descript: executing the action
#   n-ref :   $1   : return value : serialized target data
#   input :   $@   : option parameter
#   output: stdout : message
#   return:        : unused
function fnExec() {
	fnDebugout ""
	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	declare       __TGET=""				# target
	declare -a    __LINE=()				# work variables
	declare -i    I=0					# work variables

	while [[ -n "${1:-}" ]]
	do
		__TGET="$1"
		shift
		for I in "${!_LIST_DSTP[@]}"
		do
			read -r -a __LINE < <(echo "${_LIST_DSTP[I]}")
			if [[ "${__LINE[0]}" != "o" ]]; then
				continue
			fi
			if [[ "${__LINE[1]}" = "${__TGET}" ]]; then
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%-10.10s: %s${_CODE_ESCP}[m\n" "start" "${__LINE[1]}"
				case "${__LINE[1]:-}" in
					debian-*        ) fnCreate_debian "${__LINE[1]}" "${__LINE[2]}" "main,contrib,non-free,non-free-firmware" "${__LINE[5]}";;
					ubuntu-*        ) fnCreate_debian "${__LINE[1]}" "${__LINE[2]}" "main,multiverse,restricted,universe"     "${__LINE[5]}";;
					fedora-*        | \
					centos-stream-* | \
					almalinux-*     | \
					rockylinux-*    | \
					miraclelinux-*  ) fnCreate_rhel "${__LINE[1]}" "${__LINE[5]}";;
					opensuse-*      ) fnCreate_opensuse "${__LINE[1]}" "${__LINE[5]}";;
					*)	break 2;;
				esac
				printf "${_CODE_ESCP}[m${_CODE_ESCP}[92m%-10.10s: %s${_CODE_ESCP}[m\n" "complete" "${__LINE[1]}"
				break
			fi
		done
	done
	__NAME_REFR="${*:-}"
	fnDebug_parameter_list
}