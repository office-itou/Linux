# === <media> =================================================================

# --- unit conversion ---------------------------------------------------------
# shellcheck disable=SC2317
function funcUnit_conversion() {
	declare -r -a _UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    _CALC=0
	declare       _WORK=""				# work variables
	declare -i    I=0
	# --- is numeric ----------------------------------------------------------
	if [[ ! ${1:?} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		printf "Error [%s]" "$1"
		return
	fi
	# --- Byte ----------------------------------------------------------------
	if [[ "$1" -lt 1024 ]]; then
		printf "%'d Byte" "$1"
		return
	fi
	# --- numfmt --------------------------------------------------------------
	if command -v numfmt > /dev/null 2>&1; then
		echo -n "$1" | numfmt --to=iec-i --suffix=B
		return
	fi
	# --- calculate -----------------------------------------------------------
	for ((I=3; I>0; I--))
	do
		_CALC=$((1024**I))
		if [[ "$1" -ge "${_CALC}" ]]; then
			_WORK="$(echo "$1" "${_CALC}" | awk '{printf("%.1f", $1/$2)}')"
			printf "%s %s" "${_WORK}" "${_UNIT[I]}"
			return
		fi
	done
	echo -n "$1"
}

# --- get volume id -----------------------------------------------------------
# shellcheck disable=SC2317
function funcGetVolID() {
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	if [[ -n "${1:-}" ]] && [[ -s "${1:?}" ]]; then
		if command -v blkid > /dev/null 2>&1; then
			_VLID="$(blkid -s LABEL -o value "$1")"
		else
			_VLID="$(LANG=C file -L "$1")"
			_VLID="${_VLID#*: }"
			_WORK="${_VLID%%\'*}"
			_VLID="${_VLID#"${_WORK}"}"
			_WORK="${_VLID##*\'}"
			_VLID="${_VLID%"${_WORK}"}"
		fi
	fi
	echo -n "${_VLID}"
}

# --- get file information ----------------------------------------------------
# shellcheck disable=SC2317
function funcGetFileinfo() {
	declare       _DIRS=""				# directory
	declare       _FNAM=""				# file name
	declare       _VLID=""				# volume id
	declare       _WORK=""				# work variables
	declare -a    _ARRY=()				# work variables
	# -------------------------------------------------------------------------
	_ARRY=()
	if [[ -n "${1:-}" ]] && [[ -s "${1:?}" ]]; then
		_WORK="$(realpath -s "$1")"		# full path
		_FNAM="${_WORK##*/}"
		_DIRS="${_WORK%"${_FNAM}"}"
		_WORK="$(LANG=C find "${_DIRS:-.}" -name "${_FNAM}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS+%TZ %s")"
		if [[ -n "${_WORK}" ]]; then
			read -r -a _ARRY < <(echo "${_WORK}")
#			_ARRY[0]					# full path
#			_ARRY[1]					# time stamp
#			_ARRY[2]					# size
			_VLID="$(funcGetVolID "${_ARRY[0]}")"
			_VLID="${_VLID#\'}"
			_VLID="${_VLID%\'}"
			_VLID="${_VLID:--}"
			_ARRY+=("${_VLID// /%20}")	# volume id
		fi
	fi
	echo -n "${_ARRY[*]}"
}

# --- distro to efi image file name -------------------------------------------
# shellcheck disable=SC2317
function funcDistro2efi() {
	declare       _WORK=""				# work variables
	# -------------------------------------------------------------------------
	case "${1:?}" in
		debian      | \
		ubuntu      ) _WORK="boot/grub/efi.img";;
		fedora      | \
		centos      | \
		almalinux   | \
		rockylinux  | \
		miraclelinux) _WORK="images/efiboot.img";;
		opensuse    ) _WORK="boot/x86_64/efi";;
		*           ) ;;
	esac
	echo -n "${_WORK}"
}
