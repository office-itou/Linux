# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: mkosi build live media
#   input :     $1     : operation
#   input :     $2     : distribution
#   input :     $3     : version
#   input :     $4     : edition
#   input :     $5     : workspace directory
#   input :     $6     : output directory
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_mkosi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OPRT="${1:-}"	# operation
	declare -r    __TGET_DIST="${2:-}"	# distribution
	declare -r    __TGET_VERS="${3:-}"	# version
	declare -r    __TGET_EDTN="${4:-}"	# edition
	declare -r    __TGET_WRKD="${5:-}"	# --workspace-directory=
	declare -r    __TGET_OUTD="${6:-}"	# --output-directory=
	declare       __HOST=""				# --hostname=
	declare -a    __OPTN=()				# command
	declare -r    __BOOT="${_MKOS_BOOT:-}"
	declare -r    __OUTP="${_MKOS_OUTP:-}"
	declare -r    __FMAT="${_MKOS_FMAT:-}"
	declare -r    __NWRK="${_MKOS_NWRK:-}"
	declare -r    __RECM="${_MKOS_RECM:-}"
	declare -r    __ARCH="${_MKOS_ARCH:-}"
	declare -r    __MKOS="${_DIRS_MKOS:-}"
	declare -r    __DIST="${__TGET_DIST:-}"
	declare -r    __VERS="${__TGET_VERS:-}"
	declare -r    __EDTN="${__TGET_EDTN:-}"
	declare -r    __WRKD="${__TGET_WRKD:-}"
	declare -r    __OUTD="${__TGET_OUTD:-}"
	declare -r    __CACH=""
	# --- --hostname= ---------------------------------------------------------
	__HOST="$(fnFind_distribution "${__DIST}")"
	__HOST="${__HOST:+"sv-${__HOST}.workgroup"}"
	__HOST="${__HOST,,}"
	# --- command -------------------------------------------------------------
	__OPTN=(
		${__BOOT:+--bootable="${__BOOT}"}
		${__OUTP:+--output="${__OUTP}"}
		${__FMAT:+--format="${__FMAT}"}
		${__NWRK:+--with-network="${__NWRK}"}
		${__RECM:+--with-recommends="${__RECM}"}
		${__DIST:+--distribution="${__DIST}"}
		${__VERS:+--release="${__VERS}"}
		${__ARCH:+--architecture="${__ARCH//_/-}"}
		${__MKOS:+--directory="${__MKOS}"}
		${__WRKD:+--workspace-directory="${__WRKD}"}
		${__CACH:+--package-cache-dir="${__CACH}"}
		${__OUTD:+--output-directory="${__OUTD}"}
		${__EDTN:+--environment=EDITION="${__EDTN}"}
		${__HOST:+--hostname="${__HOST}"}
	)
	case "${__OPRT:-}" in
#		init         ) __OPTN=("${__OPRT}");;
		summary      ) __OPTN+=(--no-pager summary);;
#		cat-config   ) __OPTN=("${__OPRT}");;
		build        ) __OPTN+=(--force --wipe-build-dir build);;
#		shell        ) __OPTN=("${__OPRT}");;
#		boot         ) __OPTN=("${__OPRT}");;
#		vm           ) __OPTN=("${__OPRT}");;
#		ssh          ) __OPTN=("${__OPRT}");;
#		journalctl   ) __OPTN=("${__OPRT}");;
#		coredumpctl  ) __OPTN=("${__OPRT}");;
#		sysupdate    ) __OPTN=("${__OPRT}");;
#		box          ) __OPTN=("${__OPRT}");;
#		dependencies ) __OPTN=("${__OPRT}");;
#		clean        ) __OPTN=("${__OPRT}");;
#		serve        ) __OPTN=("${__OPRT}");;
#		burn         ) __OPTN=("${__OPRT}");;
#		bump         ) __OPTN=("${__OPRT}");;
#		genkey       ) __OPTN=("${__OPRT}");;
#		documentation) __OPTN=("${__OPRT}");;
#		completion   ) __OPTN=("${__OPRT}");;
#		help         ) __OPTN=("${__OPRT}");;
		*            ) __OPTN=("help");;
	esac
#	__OPTN=("--debug" "${__OPTN[@]:-}")
	fnMk_mkosi "${__OPTN[@]}"

	unset __OPTN __HOST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
