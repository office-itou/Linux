#!/bin/bash

set -eu

declare -r    _USER_NAME="${USER:-"${LOGNAME:-"$(whoami || true)"}"}"
declare -r    _SUDO_USER="${SUDO_USER:-"${_USER_NAME:?}"}"
declare -r    _SUDO_HOME="${SUDO_HOME:-"$(eval echo "~${SUDO_USER:-"${USER:?}"}")"}"

declare -r    _TGET_DIST="debian"
declare -r    _TGET_VERS="trixie"
declare -r    _TGET_ARCH="x86-64"
declare -r    _TGET_REPO="main,contrib,non-free,non-free-firmware"
declare -r    _TGET_FMAT="uki"
declare -r    _TGET_OUTP="image"
declare -r    _TGET_COMP="zstd"
declare -r    _TGET_HNAM="${_TGET_DIST:+"ws-${_TGET_DIST}.workgroup"}"
declare -r    _TGET_LANG="ja_JP.UTF-8"
declare -r    _TGET_KMAP="jp"
declare -r    _TGET_TZON="Asia/Tokyo"
declare -r    _TGET_RTPW="r00t"
declare -r -a _TGET_PAKG=(
	login
	locales
	locales-all
	keyboard-configuration
	hostname
	iproute2
	openssh-server
	vim
	xz-utils
	linux-image-amd64
	systemd-boot-efi
	busybox
	network-manager
	nbd-client
)
#declare -r    _OLD_IFS="${IFS:-}"
#IFS=','
declare       _TGET_PKGS=""
_TGET_PKGS="${_TGET_PAKG[*]}"
_TGET_PKGS="${_TGET_PKGS// /,}"
readonly      _TGET_PKGS
#IFS="${_OLD_IFS:-}"
declare -r    _DIRS_MKOS=""
declare -r    _DIRS_WORK="${_SUDO_HOME:?}/.workdirs/mkosi"
declare -r    _DIRS_OUTP="${_DIRS_WORK:?}/outp"
declare -r    _DIRS_WKSP="${_DIRS_WORK:?}/wksp"
declare -r    _DIRS_BSRC="${_DIRS_WORK:?}/bsrc"
declare -r    _DIRS_CACH="/srv/user/share/cache/${_TGET_DIST:?}-${_TGET_VERS:?}-${_TGET_ARCH:?}"
declare -r    _DIRS_LOAD="/srv/user/share/imgs/_loader"
declare -r -a _COMD_OPTN=(
	--force
	${_DIRS_MKOS:+--directory="${_DIRS_MKOS}"}
	--wipe-build-dir
	${_TGET_DIST:+--distribution="${_TGET_DIST}"}
	${_TGET_VERS:+--release="${_TGET_VERS}"}
	${_TGET_ARCH:+--architecture="${_TGET_ARCH}"}
	--repository-key-check=no
	--repository-key-fetch=yes
	${_TGET_REPO:+--repositories="${_TGET_REPO}"}
	${_TGET_FMAT:+--format="${_TGET_FMAT}"}
	${_TGET_OUTP:+--output="${_TGET_OUTP}"}
	${_TGET_COMP:+--compress-output="${_TGET_COMP}"}
	${_DIRS_OUTP:+--output-directory="${_DIRS_OUTP}"}
	${_TGET_PKGS:+--package="${_TGET_PKGS}"}
	--with-recommends=yes
	--tools-tree=yes
	${_TGET_DIST:+--tools-tree-distribution="${_TGET_DIST}"}
	${_TGET_VERS:+--tools-tree-release="${_TGET_VERS}"}
	${_DIRS_WKSP:+--workspace-directory="${_DIRS_WKSP}"}
	${_DIRS_CACH:+--package-cache-dir="${_DIRS_CACH}"}
	${_DIRS_BSRC:+--build-sources="${_DIRS_BSRC}"}
	--with-network=no
	${_TGET_LANG:+--locale="${_TGET_LANG}"}
	${_TGET_LANG:+--locale-messages="${_TGET_LANG}"}
	${_TGET_KMAP:+--keymap="{_TGET_KMAP}"}
	${_TGET_TZON:+--timezone="${_TGET_TZON}"}
	${_TGET_HNAM:+--hostname="${_TGET_HNAM}"}
	${_TGET_RTPW:+--root-password="${_TGET_RTPW}"}
)

rm -rf "${_DIRS_WORK:?}" "${_SUDO_HOME:?}"/{mkosi.tools,mkosi.tools.manifest}
mkdir -p "${_DIRS_BSRC:?}"
pushd "${_DIRS_WORK:?}" > /dev/null
if ! mkosi "${_COMD_OPTN[@]:-}" build; then
	__RTCD="$?"
	pop "${_DIRS_WORK:?}" > /dev/null
	echo "failed: mkosi ${_COMD_OPTN[*]:-} build"
	exit "${__RTCD:-}"
fi
popd > /dev/null

cp --preserve=timestamps "${_DIRS_OUTP:?}/image.initrd"  "${_DIRS_LOAD:?}/initrd"
cp --preserve=timestamps "${_DIRS_OUTP:?}/image.vmlinuz" "${_DIRS_LOAD:?}/vmlinuz"
ls -lahZ "${_DIRS_LOAD:?}"
