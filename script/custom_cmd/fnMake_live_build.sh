# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: exec live build
#   n-ref :     $1     : return value : serialized target data
#   input :     $@     : option parameter
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
#   g-var : _MKOS_BOOT : read
#   g-var : _MKOS_OUTP : read
#   g-var : _MKOS_FMAT : read
#   g-var : _MKOS_NWRK : read
#   g-var : _MKOS_RECM : read
#   g-var : _MKOS_ARCH : read
#   g-var : _DIRS_MKOS : read
#   g-var : _DIRS_TEMP : read
#   g-var : _DIRS_RTFS : read
function fnMake_live_build() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -n    __NAME_REFR="${1:-}"	# name reference
	shift
	              __NAME_REFR="${*:-}"
#	declare -a    __OPTN=("${@:-}")		# options
	declare       __OPRT=""				# operation
	declare -r    __BOOT="${_MKOS_BOOT:-}"	# --bootable=
	declare -r    __OUTP="${_MKOS_OUTP:-}"	# --output=
	declare -r    __FMAT="${_MKOS_FMAT:-}"	# --format=
	declare -r    __NWRK="${_MKOS_NWRK:-}"	# --with-network=
	declare -r    __RECM="${_MKOS_RECM:-}"	# --with-recommends
	declare       __DIST=""					# --distribution=
	declare       __VERS=""					# --release=
	declare -r    __ARCH="${_MKOS_ARCH:-}"	# --architecture=
	declare -r    __MKOS="${_DIRS_MKOS:-}"	# --directory=
	declare       __WRKD="" 			# --workspace-directory=
#	declare       __CACH=""				# --package-cache-dir=
	declare       __OUTD="" 			# --output-directory=
	declare       __EDTN=""				# --environment=EDITION=
	declare       __HOST=""				# --hostname=
#	declare -a    __COMD=()				# command
	declare       __CODE=""				# code name
#	declare       __ARCH=""				# architecture
	declare       __VLID=""				# volume id
	declare       __ENTR=""				# menu entry
	declare       __ISOS=""				# output file name
	declare       __SUBD=""				# sub directory
	declare -r    __TEMP="${_DIRS_TEMP:?}"	# local
	declare -r    __RTMP="${_DIRS_RTMP:?}"	# remote
	declare -a    __TGET=()				# target list
	declare       __STRG=""				# storage
	declare       __SPLS=""				# splash.png
	declare       __WORK=""				# work
	declare -a    __ARRY=()				# work
	declare -i    I=0					# work
	declare -i    __time_start=0
	declare -i    __time_end=0
	declare -i    __time_elapsed=0
	# --- get options ---------------------------------------------------------
	set -f -- "${@:-}"
	set +f
	__TGET=()
	while [[ -n "${1:-}" ]]
	do
		IFS=':' read -r -a __ARRY < <(echo "${1,,}")
		case "${__ARRY[1]}" in
			-*      ) break;;
			debian  ) __TGET+=("${__ARRY[*]}");;
			ubuntu  ) __TGET+=("${__ARRY[*]}");;
			fedora  ) __TGET+=("${__ARRY[*]}");;
			centos  ) __TGET+=("${__ARRY[*]}");;
			alma    ) __TGET+=("${__ARRY[*]}");;
			rocky   ) __TGET+=("${__ARRY[*]}");;
			opensuse) __TGET+=("${__ARRY[*]}");;
#			miracle ) __TGET+=("${__ARRY[*]}");;
			*       ) ;;
		esac
		shift
	done
	__NAME_REFR="${*:-}"
	# --- main ----------------------------------------------------------------
	# -m build:debian:13.0:server build:ubuntu:26.04:desktop ...
	for I in "${!__TGET[@]}"
	do
		__time_start=$(date +%s)
		fnMsgout "${_PROG_NAME:-}" "start" "$(date -d "@${__time_start}" +"%Y/%m/%d %H:%M:%S" || true)"
		read -r -a __ARRY < <(echo "${__TGET[I]:-}")
		__OPRT="${__ARRY[0]:?}"								# operation
		__DIST="${__ARRY[1]:?}"								# --distribution=distribution
		__VERS="${__ARRY[2]:?}"								# --release=version
		__EDTN="${__ARRY[3]:?}"								# --environment=EDITION=edition
		__CODE="$(fnFind_codename "${__DIST}" "${__VERS}")"	# code name
#		__ARCH="${_MKOS_ARCH//_/-}"							# architecture
		# --- work directory --------------------------------------------------
		__SUBD="${__DIST}-${__CODE:-"${__VERS}"}${__ARCH:+-"${__ARCH//_/-}"}${__EDTN+-"${__EDTN}"}"
		__WRKD="${__TEMP:?}/${__SUBD:?}" # --workspace-directory=
		__OUTD="${__RTMP:?}/${__SUBD:?}" # --output-directory=
		# --- iso file name ---------------------------------------------------
		__VLID="$(fnFind_distribution "${__DIST}")"			# volume id (<=16) Debian13.0x64s / AlmaLinux10x64s / openSUSE16.0x64s
		__ENTR="${__VLID}${__VERS:+" ${__VERS^}"}${__ARCH:+" ${__ARCH//-/_}"}${__EDTN:+" ${__EDTN^}"}"
		__ISOS="${__ENTR// /-}"
		__ISOS="${_DIRS_RMAK:?}/live-${__ISOS,,}.iso"
		# --- volume id -------------------------------------------------------
		__VLID="${__VLID%%-*}"
		__VLID="${__VLID}${__VERS::$((6+6-${#__VLID}))}${__ARCH//[0-9]*[_-]}${__EDTN::1}"
		__VLID="${__VLID//[ -!@#.]/_}"
		__VLID="${__VLID// /\x20}"
		__VLID="${__VLID^^}"
		__VLID="${__VLID::16}"
		# --- build -----------------------------------------------------------
		fnMake_live_mkosi "${__OPRT:-}" "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}" "${__WRKD:-}" "${__WRKD:-}"
		case "${__OPRT:-}" in
			build        )
				__STRG="${__OUTD:?}/vm_uefi_${__VLID,,}.raw"
				__SPLS="${__OUTD:?}/${_MENU_SPLS:?}"
				# --- splash.png ----------------------------------------------
				mkdir -p "${__OUTD:?}"
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' | xxd -p -r | gzip -d -k > "${__SPLS:?}"
					1f8b0808462b8d69000373706c6173682e706e6700eb0cf073e7e592e262
					6060e0f5f47009626060566060608ae060028a888a88aa3330b0767bba38
					8654dc7a7b909117287868c177ff5c3ef3050ca360148c8251300ae8051a
					c299ff4c6660bcb6edd00b10d7d3d5cf659d53421300e6198186c4050000
_EOT_
				# --- create iso image file -----------------------------------
				fnMake_live_vmimg "${__OUTD:-}" "${__WRKD:?}" "${__VLID:-}" "${__ENTR:-}" "${__STRG:-}" "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}"
				fnMake_live_qemu  "${__STRG:-}"
				fnMake_live_cdimg "${__OUTD:-}" "${__VLID:-}" "${__ENTR:-}" "${__STRG:-}" "${__ISOS:-}"
				;;
			*            ) __OPTN=("help");;
		esac
		rm -rf "${__WRKD:?}" \
		       "${__OUTD:?}"
		__time_end=$(date +%s)
		__time_elapsed=$((__time_end - __time_start))
		fnMsgout "${_PROG_NAME:-}" "complete" "$(date -d "@${__time_end}" +"%Y/%m/%d %H:%M:%S" || true)"
		fnMsgout "${_PROG_NAME:-}" "elapsed" "$(printf "%dd%02dh%02dm%02ds\n" $((__time_elapsed/86400)) $((__time_elapsed%86400/3600)) $((__time_elapsed%3600/60)) $((__time_elapsed%60)) || true)"
	done
	unset __time_start __time_end __time_elapsed
	unset I __ARRY __WORK __STRG __TGET __SUBD __ISOS __VLID __CODE __HOST __EDTN __OUTD __WRKD __VERS __DIST
	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
