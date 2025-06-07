# shellcheck disable=SC2148
# === <media> =================================================================

# -----------------------------------------------------------------------------
# descript: unit conversion
#   n-ref :   $1   : return value : value with units
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnUnit_conversion() {
	fnDebugout ""
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare -r -a __UNIT=("Byte" "KiB" "MiB" "GiB" "TiB")
	declare -i    __CALC=0
	declare       __WORK=""				# work variables
	declare -i    I=0
	# --- is numeric ----------------------------------------------------------
	if [[ ! ${2:?} =~ ^-?[0-9]+\.?[0-9]*$ ]]; then
		__RETN_VALU="$(printf "Error [%s]" "$2" || true)"
		return
	fi
	# --- Byte ----------------------------------------------------------------
	if [[ "$2" -lt 1024 ]]; then
		__RETN_VALU="$(printf "%'d Byte" "$2" || true)"
		return
	fi
	# --- numfmt --------------------------------------------------------------
	if command -v numfmt > /dev/null 2>&1; then
		__RETN_VALU="$(echo -n "$2" | numfmt --to=iec-i --suffix=B || true)"
		return
	fi
	# --- calculate -----------------------------------------------------------
	for ((I=3; I>0; I--))
	do
		__CALC=$((1024**I))
		if [[ "$2" -ge "${__CALC}" ]]; then
			__WORK="$(echo "$2" "${__CALC}" | awk '{printf("%.1f", $1/$2)}')"
			__RETN_VALU="$(printf "%s %s" "${__WORK}" "${__UNIT[I]}" || true)"
			return
		fi
	done
}

# -----------------------------------------------------------------------------
# descript: get volume id
#   n-ref :   $1   : return value : volume id
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetVolID() {
	fnDebugout ""
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __VLID=""				# volume id
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	if [[ -n "${2:-}" ]] && [[ -s "${2:?}" ]]; then
		if command -v blkid > /dev/null 2>&1; then
			__VLID="$(blkid -s LABEL -o value "$2" || true)"
		else
			__VLID="$(LANG=C file -L "$2")"
			__VLID="${__VLID#*: }"
			__WORK="${__VLID%%\'*}"
			__VLID="${__VLID#"${__WORK}"}"
			__WORK="${__VLID##*\'}"
			__VLID="${__VLID%"${__WORK}"}"
		fi
	fi
	__RETN_VALU="${__VLID:-}"
}

# -----------------------------------------------------------------------------
# descript: get file information
#   n-ref :   $1   : return value : path tmstamp size vol-id
#   input :   $2   : input value
#   output: stdout : unused
#   return:        : unused
# shellcheck disable=SC2317
function fnGetFileinfo() {
	fnDebugout ""
	declare -n    __RETN_VALU="${1:?}"	# return value
	declare       __DIRS=""				# directory
	declare       __FNAM=""				# file name
	declare       __VLID=""				# volume id
	declare       __RSLT=""				# result
	declare       __WORK=""				# work variables
	declare -a    __ARRY=()				# work variables
	# -------------------------------------------------------------------------
	__ARRY=()
	if [[ -n "${2:-}" ]] && [[ -s "${2}" ]]; then
		__WORK="$(realpath -s "$2")"	# full path
		__FNAM="${__WORK##*/}"
		__DIRS="${__WORK%"${__FNAM}"}"
		__WORK="$(LANG=C find "${__DIRS:-.}" -name "${__FNAM}" -follow -printf "%p %TY-%Tm-%Td%%20%TH:%TM:%TS%Tz %s")"
		if [[ -n "${__WORK}" ]]; then
			read -r -a __ARRY < <(echo "${__WORK}")
			fnGetVolID __RSLT "${__ARRY[0]}"
			__VLID="${__RSLT#\'}"
			__VLID="${__VLID%\'}"
			__VLID="${__VLID:--}"
			__ARRY+=("${__VLID// /%20}")	# volume id
		fi
	fi
	__RETN_VALU="${__ARRY[*]}"
}

# -----------------------------------------------------------------------------
# descript: distro to efi image file name
#   input :   $1   : input value
#   output: stdout : output
#   return:        : unused
# shellcheck disable=SC2317
function fnDistro2efi() {
	fnDebugout ""
	declare       __WORK=""				# work variables
	# -------------------------------------------------------------------------
	case "${1:?}" in
		debian      | \
		ubuntu      ) __WORK="boot/grub/efi.img";;
		fedora      | \
		centos      | \
		almalinux   | \
		rockylinux  | \
		miraclelinux) __WORK="images/efiboot.img";;
		opensuse    ) __WORK="boot/x86_64/efi";;
		*           ) ;;
	esac
	echo -n "${__WORK}"
}
