# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: mkosi build live media
#   input :     $1     : operation
#   input :     $2     : distribution
#   input :     $3     : version
#   input :     $4     : code
#   input :     $5     : edition
#   input :     $6     : workspace directory
#   input :     $7     : output directory
#   output:   stdout   : message
#   return:            : unused
#   g-var : _AUTO_INST : read
function fnMake_live_mkosi() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_OPRT="${1:-}"	# operation
	declare -r    __TGET_DIST="${2:-}"	# distribution
	declare -r    __TGET_VERS="${3:-}"	# version
	declare -r    __TGET_CODE="${4:-}"	# version
	declare -r    __TGET_EDTN="${5:-}"	# edition
	declare -r    __TGET_WRKD="${6:-}"	# local work directory
#	declare -r    __TGET_WRKD="${6:-}"	# --workspace-directory=
#	declare -r    __TGET_OUTD="${7:-}"	# --output-directory=
	declare       __HOST=""				# --hostname=
	declare -a    __OPTN=()				# command
#	declare -r    __MKOS="${_DIRS_MKOS:?}"						# --directory
	declare -r    __MKOS="${__TGET_WRKD:_}/mkosi-directory"		# --directory
#	declare -r    __WIPE=""										# --wipe-build-dir
	declare -r    __DIST="${__TGET_DIST:-}"						# --distribution, --tools-tree-distribution
	declare -r    __RELS="${__TGET_CODE:-"${__TGET_VERS:-}"}"	# --release, --tools-tree-release
	declare -r    __ARCH="${_MKOS_ARCH:-}"						# --architecture
	declare -r    __RCHK=""										# --repository-key-check
	declare -r    __RKEY=""										# --repository-key-fetch
	declare -r    __REPO=""										# --repositories
	declare -r    __FMAT="${_MKOS_FMAT:-}"						# --format
	declare -r    __OUTP="${_MKOS_OUTP:-}"						# --output
	declare -r    __COMP=""										# --compress-output
#	declare -r    __OUTD="${__TGET_OUTD:-}"						# --output-directory
	declare -r    __OUTD="${__TGET_WRKD:-}"						# --output-directory
	declare -r    __PKGS=""										# --package
	declare -r    __RECM="${_MKOS_RECM:-}"						# --with-recommends
	declare -r    __BOOT="${_MKOS_BOOT:-}"						# --bootable
#	declare -r    __TOOL="yes"										# --tools-tree
	declare -r    __WRKD="${__TGET_WRKD:-}"						# --workspace-directory
	declare -r    __CACH=""										# --package-cache-dir
	declare -r    __BSRC=""										# --build-sources
	declare -r    __NWRK="${_MKOS_NWRK:-}"						# --with-network
	declare -r    __EDTN="${__TGET_EDTN:-}"						# --environment=EDITION
	declare -r    __LANG=""										# --locale, --locale-messages
	declare -r    __KMAP=""										# --keymap
	declare -r    __TZON=""										# --timezone
	declare       __HOST=""										# --hostname
	declare -r    __RTPW=""										# --root-password

	# --- --hostname= ---------------------------------------------------------
	__HOST="$(fnFind_distribution "${__DIST}")"
	__HOST="${__HOST:+"sv-${__HOST}.workgroup"}"
	__HOST="${__HOST,,}"
	readonly __HOST
	# --- command -------------------------------------------------------------
	__OPTN=(
		--force
		${__MKOS:+--directory="${__MKOS}"}
		${__DIST:+--distribution="${__DIST}"}
		${__RELS:+--release="${__RELS}"}
		${__ARCH:+--architecture="${__ARCH//_/-}"}
		${__RCHK:+--repository-key-check="${__RCHK}"}
		${__RKEY:+--repository-key-fetch="${__RKEY}"}
		${__REPO:+--repositories="${__REPO}"}
		${__FMAT:+--format="${__FMAT}"}
		${__OUTP:+--output="${__OUTP}"}
		${__COMP:+--compress-output="${__COMP}"}
		${__OUTD:+--output-directory="${__OUTD}"}
		${__PKGS:+--package="${__PKGS}"}
		${__RECM:+--with-recommends="${__RECM}"}
		${__BOOT:+--bootable="${__BOOT}"}
		${__WRKD:+--workspace-directory="${__WRKD}"}
		${__CACH:+--package-cache-dir="${__CACH}"}
		${__BSRC:+--build-sources="${__BSRC}"}
		${__NWRK:+--with-network="${__NWRK}"}
		${__EDTN:+--environment=EDITION="${__EDTN}"}
		${__LANG:+--locale="${__LANG}"}
		${__LANG:+--locale-messages="${__LANG}"}
		${__KMAP:+--keymap="{__KMAP}"}
		${__TZON:+--timezone="${__TZON}"}
		${__HOST:+--hostname="${__HOST}"}
		${__RTPW:+--root-password="${__RTPW}"}
	)
#		${__TOOL:+--tools-tree="${__TOOL}"}
#		${__DIST:+--tools-tree-distribution="${__DIST}"}
#		${__RELS:+--tools-tree-release="${__RELS}"}
	case "${__OPRT:-}" in
#		init         ) __OPTN=("${__OPRT}");;
		summary      ) __OPTN+=(--no-pager summary);;
#		cat-config   ) __OPTN=("${__OPRT}");;
		build        ) __OPTN+=(--wipe-build-dir build);;
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
	readonly __OPTN

#	mkdir -p "${__WRKD:?}" "${__BSRC:?}"
#	pushd "${__WRKD:?}" > /dev/null || exit 1
	mkdir -p "${__MKOS:?}"/{repository,script}
	cp --preserve=timestamps "${_DIRS_MKOS:?}/mkosi.conf.d/mkosi-${__DIST:?}.${__VERS:?}.${__CODE:+"${__CODE}."}${__EDTN:?}.conf" "${__MKOS:?}/mkosi.conf"
	cp --preserve=timestamps "${_DIRS_MKOS:?}/mkosi.finalize.d/mkosi.finalize.sh.chroot" "${__MKOS:?}/mkosi.finalize.chroot"
	cp --preserve=timestamps "${_DIRS_MKOS:?}/repository"/* "${__MKOS:?}"/repository/
	cp --preserve=timestamps "${_DIRS_MKOS:?}/script"/* "${__MKOS:?}"/script
	fnMk_mkosi "${__OPTN[@]}"
#	rm -rf "${__MKOS:?}"
#	popd > /dev/null || exit 1

#	unset __OPTN __HOST

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
}
