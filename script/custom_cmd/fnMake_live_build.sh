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
#   g-var : _DIRS_RTMP : read
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
	declare       __ARCH=""				# architecture
	declare       __VLID=""				# volume id
	declare       __SUBD=""				# sub directory
	declare -r    __TEMP="${_DIRS_TEMP:?}"	# local
	declare -r    __RTMP="${_DIRS_RTMP:?}"	# remote
	declare -a    __TGET=()				# target list
	declare       __WORK=""				# work
	declare -a    __ARRY=()				# work
	# --- get options ---------------------------------------------------------
	set -f -- "${@:-}"
	set +f
	__TGET=()
	while [[ -n "${1:-}" ]]
	do
		__WORK="${1%%:*}"
		__WORK="${__WORK,,}"
		case "${__WORK:-}" in
			-*      ) break;;
			debian  ) ;;
			ubuntu  ) ;;
			fedora  ) ;;
			centos  ) ;;
			alma    ) ;;
			rocky   ) ;;
			opensuse) ;;
#			miracle ) ;;
			*       ) continue;;
		esac
		__TGET+=("${1:-}")
		shift
	done
	__NAME_REFR="${*:-}"
	# --- main ----------------------------------------------------------------
	# -m build:debian:13.0:server build:ubuntu:26.04:desktop ...
	for I in "${!__TGET[@]}"
	do
		read -r -d ':' -a __ARRY < <(echo "${__TGET[I]}")
		__OPRT="${__ARRY[1]:?}"								# operation
		__DIST="${__ARRY[2]:?}"								# distribution
		__VERS="${__ARRY[3]:-}"								# version
		__EDTN="${__ARRY[4]:-}"								# edition
		__OPRT="${__OPRT,,}"								# operation
		__DIST="${__DIST,,}"								# --distribution=
		__VERS="${__VERS,,}"								# --release=
		__EDTN="${__EDTN,,}"								# --environment=EDITION=
		__CODE="$(fnFind_codename "${__DIST}" "${__VERS}")"	# code name
		__ARCH="${_MKOS_ARCH//_/-}"							# architecture
		__VLID="$(fnFind_distribution "${__DIST}")"			# volume id
		__VLID="${__VLID}${__VERS:+" ${__VERS^}"}${__ARCH:+" ${__ARCH}"}${__EDTN:+" ${__EDTN^}"}"
		__VLID="${__VLID// /-}"
		__SUBD="${__DIST}-${__CODE:-"${__VERS}"}${__ARCH:+-"${__ARCH//_/-}"}${__EDTN+-"${__EDTN}"}"
		__WRKD="${__TEMP:?}/${__SUBD:?}" # --workspace-directory=
		__OUTD="${__RTMP:?}/${__SUBD:?}" # --output-directory=
		# --- build -----------------------------------------------------------
		fnMake_live_mkosi "${__OPRT:-}" "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}" "${__WRKD:-}" "${__OUTD:-}"
		fnMake_live_vmimg "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}" "${__VLID:-}" "${__OUTD:-}"
		fnMake_live_cdimg "${__DIST:-}" "${__CODE:-"${__VERS:-}"}" "${__EDTN:-}" "${__VLID:-}" "${__OUTD:-}"
	done

	unset __ARRY __WORK __TGET __SUBD __VLID __ARCH __CODE __HOST __EDTN __OUTD __WRKD __VERS __DIST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
