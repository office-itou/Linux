# shellcheck disable=SC2148

function fnMk_ipxe() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- create --------------------------------------------------------------
	# https://www.salstar.sk/boot/
#	IFS= mapfile -d $'\n' -t _LIST_DIST < <(cat /srv/user/share/conf/_data/distribution.dat)
	declare       __LINE=""
	declare -a    __LIST=()
	declare       __DIST=""
	declare -a    __ARRY=()
	declare -a    __SORT=()
#	for I in "${!_LIST_DIST[@]}"
#	do
#		__LINE="${_LIST_DIST[I]:-}"
	while read -r __LINE
	do
		read -r -a __LIST < <(echo "${__LINE:-}")
		if [[ "${__DIST:-"${__LIST[0]%%-*}"}" != "${__LIST[0]%%-*}" ]]; then
			__SORT+=("$(printf "%s\n" "${__ARRY[@]:-}" | sort -ruV -k 14 -k 1)")
			__ARRY=()
			case "${__DIST:-}" in
				version      ) fnMk_ipxe_autoexec      "${_PATH_IPXE:?}"
							   fnMk_ipxe_menu          "${_PATH_IPXE%/*}/menu/menu.ipxe"
							   fnMk_ipxe_booting       "${_PATH_IPXE%/*}/menu/booting.ipxe";;
#							   fnMk_ipxe_live          "${_PATH_IPXE%/*}/menu/live.ipxe"
#							   fnMk_ipxe_custom_live   "${_PATH_IPXE%/*}/menu/custom-live.ipxe";;
				debian       ) fnMk_ipxe_debian        "${_PATH_IPXE%/*}/menu/debian.ipxe";;
				ubuntu       ) fnMk_ipxe_ubuntu        "${_PATH_IPXE%/*}/menu/ubuntu.ipxe";;
				fedora       ) fnMk_ipxe_fedora        "${_PATH_IPXE%/*}/menu/fedora.ipxe";;
				centos       ) fnMk_ipxe_centos        "${_PATH_IPXE%/*}/menu/centos.ipxe";;
				almalinux    ) fnMk_ipxe_almalinux     "${_PATH_IPXE%/*}/menu/almalinux.ipxe";;
				rockylinux   ) fnMk_ipxe_rockylinux    "${_PATH_IPXE%/*}/menu/rockylinux.ipxe";;
				miraclelinux ) fnMk_ipxe_miraclelinux  "${_PATH_IPXE%/*}/menu/miraclelinux.ipxe";;
				opensuse     ) fnMk_ipxe_opensuse      "${_PATH_IPXE%/*}/menu/opensuse.ipxe";;
				windows      ) fnMk_ipxe_windows       "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				memtest86plus) fnMk_ipxe_memtest86plus "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				winpe        ) fnMk_ipxe_winpe         "${_PATH_IPXE%/*}/menu/windows.ipxe";;
#				ati2020x86   ) fnMk_ipxe_ati2020x86    "${_PATH_IPXE%/*}/menu/windows.ipxe";;
				*            ) ;;
			esac
		fi
		__DIST="${__LIST[0]%%-*}"
		__ARRY+=("${__LINE:-}")
	done < "${_PATH_DIST:?}"

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
