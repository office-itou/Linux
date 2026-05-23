# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: make live vm-image on qemu
#   input :     $1     : storage
#   input :     $2     : distribution
#   input :     $3     : version
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_qemu() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_STRG="${1:-}"	# storage
	declare -r    __TGET_DIST="${2:-}"	# distribution
	declare -r    __TGET_VERS="${3:-}"	# version
	declare -r    __TGET_CODE="${4:-}"	# code
	declare -a    __OPTN=()
	declare       __DIST=""
	declare       __TEMP=""
	              __TEMP="$(mktemp -qd "/tmp/${_PROG_NAME}.XXXXXX")"
	readonly      __TEMP
	              _LIST_RMOV+=("${__TEMP:?}")
	declare       __MNTP="${__TEMP:?}/mntp"
	mkdir -p "${__MNTP:?}"
	# --- command -------------------------------------------------------------
	# /usr/share/novnc/utils/novnc_proxy --listen [::]:6080
	# http://sv-developer:6080/vnc.html
	  if command -v qemu-system-x86_64 > /dev/null 2>&1; then
		__OPTN=(
			-cpu "host"
			-machine "q35"
			-enable-kvm
			-m "size=4G"
			-boot "order=c"
			-nic "bridge"
			-vga "std"
			-full-screen
			-display "curses,charset=CP932"
			-k "ja"
			-device "ich9-intel-hda"
			-vnc ":0"
			-nographic
			-drive "id=disk,file=${__TGET_STRG:?},format=raw,if=none"
			-device "ich9-ahci,id=ahci"
			-device "ide-hd,drive=disk,bus=ahci.0"
		)
		fnMk_qemu "${__OPTN[@]}"
	elif command -v virt-install > /dev/null 2>&1; then
		case "${__TGET_DIST}" in
			debian      ) __DIST="debian13";;
			ubuntu      ) __DIST="ubuntu25.10";;
			fedora      ) __DIST="fedora42";;
			centos      ) __DIST="centos-stream10";;
			alma        ) __DIST="almalinux10";;
			rocky       ) __DIST="rocky9";;
			opensuse    ) __DIST="opensuse15.6";;
			miraclelinux) __DIST="miraclelinux9.0";;
			*           ) echo "not supported: ${__TGET_DIST}-${__TGET_VERS}"; exit 1;;
		esac
		__OPTN=(
			--name "mkosi-vpc"
			--memory "4096"
			--vcpus "2"
			--disk "${__MNTP:?}/${__TGET_STRG##*/},device=disk,format=raw"
			--import
			--os-variant "${__DIST:?}"
			--network "bridge=br0"
			--graphics "vnc"
		)
		chmod +rx "${__TEMP:?}"
		mount --bind "${__TGET_STRG%/*}" "${__MNTP}" && _LIST_RMOV+=("${__MNTP}")
		fnMk_virt "${__OPTN[@]}"
		umount "${__MNTP}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
		# --os-variant
		# almalinux8 almalinux9 almalinux10
		# centos-stream8 centos-stream9 centos-stream10
		# debian12 debian13 debiantesting debianunstable
		# fedora42
		# miraclelinux8.4 miraclelinux9.0
		# opensuse15.6 opensusetumbleweed
		# rocky8 rocky9
		# ubuntu22.04 ubuntu22.10 ubuntu23.04 ubuntu23.10 ubuntu24.10 ubuntu25.10
		# win10 win11
	fi
	rm -rf "${__TEMP:?}" && unset '_LIST_RMOV[${#_LIST_RMOV[@]}-1]' && _LIST_RMOV=("${_LIST_RMOV[@]}")
	unset __OPTN

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
