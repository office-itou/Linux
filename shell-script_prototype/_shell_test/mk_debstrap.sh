#!/bin/bash

set -eu

	declare -r -a _LIST_MDIA=(
		"o  debian-11           bullseye                    "
		"o  debian-12           bookworm                    "
		"o  debian-13           trixie                      "
		"-  debian-14           forky                       "
		"-  debian-15           duke                        "
		"o  debian-testing      testing                     "
		"o  debian-sid          sid                         "
		"o  ubuntu-16.04        xenial                      "
		"o  ubuntu-18.04        bionic                      "
		"o  ubuntu-20.04        focal                       "
		"o  ubuntu-22.04        jammy                       "
		"o  ubuntu-24.04        noble                       "
		"o  ubuntu-24.10        oracular                    "
		"o  ubuntu-25.04        plucky                      "
		"o  ubuntu-25.10        questing                    "
		"o  fedora-42           -                           "
		"-  fedora-43           -                           "
		"o  centos-stream-9     -                           "
		"o  centos-stream-10    -                           "
		"o  almalinux-9         -                           "
		"o  almalinux-10        -                           "
		"o  rockylinux-9        -                           "
		"o  rockylinux-10       -                           "
		"o  miraclelinux-9      -                           "
		"o  opensuse-leap-15    -                           "
		"o  opensuse-leap-16    -                           "
		"o  opensuse-tumbleweed -                           "
	)

	declare -a    _LIST_LINE=()
	declare -a    _LIST_TGET=()

	for I in "${!_LIST_MDIA[@]}"
	do
		read -r -a _LIST_LINE < <(echo "${_LIST_MDIA[I]}")
		if [[ "${_LIST_LINE[0]}" != "o" ]]; then
			continue
		fi
		if [[ "${_LIST_LINE[1]}" = "${1:-}" ]]; then
			_LIST_TGET=("${_LIST_LINE[@]}")
			break
		fi
	done

	case "${_LIST_TGET[1]:-}" in
		debian-* )
			rm -rf --one-file-system "/srv/user/share/chroot/${_LIST_TGET[1]:?}"
			mkdir -p "/srv/user/share/chroot/${_LIST_TGET[1]}"
			# shellcheck disable=SC2016
			mmdebstrap \
				--variant=minbase \
				--mode=sudo \
				--format=directory \
				--keyring=/srv/user/share/conf/_keyring/ \
				--include=" \
					apt-listchanges \
					apt-utils \
					bash-completion \
					bc \
					build-essential \
					curl \
					fakechroot \
					file \
					gnupg \
					iproute2 \
					iputils-ping \
					linux-image-amd64 \
					less \
					locales \
					locales-all \
					lsb-release \
					man \
					shellcheck \
					sudo \
					systemd \
					traceroute \
					tree \
					vim \
					wget \
				" \
				--components="main contrib non-free non-free-firmware" \
				--customize-hook='rm "$1"/etc/hostname' \
				"${_LIST_TGET[2]}" \
				"/srv/user/share/chroot/${_LIST_TGET[1]}"
			;;
		ubuntu-* )
			rm -rf --one-file-system "/srv/user/share/chroot/${_LIST_TGET[1]:?}"
			mkdir -p "/srv/user/share/chroot/${_LIST_TGET[1]}"
			# shellcheck disable=SC2016
			mmdebstrap \
				--variant=minbase \
				--mode=sudo \
				--format=directory \
				--keyring=/srv/user/share/conf/_keyring/ \
				--include=" \
					apt-listchanges \
					apt-utils \
					bash-completion \
					bc \
					build-essential \
					curl \
					fakechroot \
					file \
					gnupg \
					iproute2 \
					iputils-ping \
					linux-image-generic \
					less \
					locales \
					locales-all \
					lsb-release \
					man \
					shellcheck \
					sudo \
					systemd \
					traceroute \
					tree \
					vim \
					wget \
				" \
				--components="main multiverse restricted universe" \
				--customize-hook='rm "$1"/etc/hostname' \
				"${_LIST_TGET[2]}" \
				"/srv/user/share/chroot/${_LIST_TGET[1]}"
			;;
		fedora-*        | \
		centos-stream-* | \
		almalinux-*     | \
		rockylinux-*    | \
		miraclelinux-*  | \
		opensuse-*      )
			;;
		*)	;;
	esac
