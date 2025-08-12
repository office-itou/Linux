#!/bin/bash

set -eu

	# shellcheck disable=SC2016
	declare -r -a _LIST_MDIA=(
		'o  debian-11           bullseye                    -           -                                                                                                   '
		'o  debian-12           bookworm                    -           -                                                                                                   '
		'o  debian-13           trixie                      -           -                                                                                                   '
		'-  debian-14           forky                       -           -                                                                                                   '
		'-  debian-15           duke                        -           -                                                                                                   '
		'o  debian-testing      testing                     -           -                                                                                                   '
		'o  debian-sid          sid                         -           -                                                                                                   '
		'o  ubuntu-16.04        xenial                      -           -                                                                                                   '
		'o  ubuntu-18.04        bionic                      -           -                                                                                                   '
		'o  ubuntu-20.04        focal                       -           -                                                                                                   '
		'o  ubuntu-22.04        jammy                       -           -                                                                                                   '
		'o  ubuntu-24.04        noble                       -           -                                                                                                   '
		'o  ubuntu-24.10        oracular                    -           -                                                                                                   '
		'o  ubuntu-25.04        plucky                      -           -                                                                                                   '
		'o  ubuntu-25.10        questing                    -           -                                                                                                   '
		'o  fedora-42           -                           metalink    https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch                   '
		'-  fedora-43           -                           metalink    https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch                   '
		'o  centos-stream-9     -                           metalink    https://mirrors.centos.org/metalink?repo=centos-baseos-$stream&arch=$basearch&protocol=https,http   '
		'o  centos-stream-10    -                           metalink    https://mirrors.centos.org/metalink?repo=centos-baseos-$stream&arch=$basearch&protocol=https,http   '
		'o  almalinux-9         -                           mirrorlist  https://mirrors.almalinux.org/mirrorlist/$releasever/baseos                                         '
		'o  almalinux-10        -                           mirrorlist  https://mirrors.almalinux.org/mirrorlist/$releasever/baseos                                         '
		'o  rockylinux-9        -                           mirrorlist  https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype             '
		'o  rockylinux-10       -                           mirrorlist  https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype             '
		'o  miraclelinux-9      -                           mirrorlist  https://repo.dist.miraclelinux.net/miraclelinux/mirrorlist/$releasever/$basearch/baseos             '
		'o  miraclelinux-10     -                           mirrorlist  https://repo.dist.miraclelinux.net/miraclelinux/mirrorlist/$releasever/$basearch/baseos             '
		'o  opensuse-leap-15    -                           -           -                                                                                                   '
		'o  opensuse-leap-16    -                           -           -                                                                                                   '
		'o  opensuse-tumbleweed -                           -           -                                                                                                   '
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
					avahi-daemon \
					bash-completion \
					bc \
					build-essential \
					ca-certificates \
					cpio \
					curl \
					dbus \
					dnsmasq \
					fakechroot \
					file \
					gnupg \
					iproute2 \
					iputils-ping \
					libnss-mdns \
					linux-image-amd64 \
					less \
					locales \
					locales-all \
					lsb-release \
					man \
					openssh-server \
					rsync \
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
					avahi-daemon \
					bash-completion \
					bc \
					build-essential \
					ca-certificates \
					cpio \
					curl \
					dbus \
					dnsmasq \
					fakechroot \
					file \
					gnupg \
					iproute2 \
					iputils-ping \
					libnss-mdns \
					linux-image-generic \
					less \
					locales \
					locales-all \
					lsb-release \
					man \
					openssh-server \
					rsync \
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
		miraclelinux-*  )
			rm -rf --one-file-system "/srv/user/share/chroot/${_LIST_TGET[1]:?}"
			mkdir -p "/srv/user/share/chroot/${_LIST_TGET[1]}"
			dnf \
				--assumeyes \
				--config="/srv/user/share/conf/_repository/${_LIST_TGET[1]%-*}.repo" \
				--installroot="/srv/user/share/chroot/${_LIST_TGET[1]}" \
				--releasever="${_LIST_TGET[1]##*-}" \
				install \
					dnf \
					epel-release
			echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" \
			> "/srv/user/share/chroot/${_LIST_TGET[1]}/etc/resolv.conf"
			chroot \
				"/srv/user/share/chroot/${_LIST_TGET[1]}" \
				dnf \
				--assumeyes \
					install \
						@core \
						@standard \
						avahi \
						bash-completion \
						bc \
						bzip2 \
						ca-certificates \
						cpio \
						curl \
						dbus \
						dnsmasq \
						file \
						gnupg \
						isomd5sum \
						kernel \
						langpacks-ja \
						less \
						lsb-release \
						lz4 \
						lzop \
						man \
						nss-mdns \
						openssh-server \
						procps \
						rsync \
						shellcheck \
						sudo \
						systemd \
						tar \
						traceroute \
						tree \
						vim \
						wget \
						xorriso \
						zstd 
			;;
		opensuse-*      )
			;;
		*)	;;
	esac
