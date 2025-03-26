#!/bin/bash

	case "" in
		-dbg) set -x; shift;;
		-dbgout) _DBGOUT="true"; shift;;
		*) ;;
	esac

	export LANG=C

#	set -n								# Check for syntax errors
#	set -x								# Show command and argument expansion
	set -o ignoreeof					# Do not exit with Ctrl+D
	set +m								# Disable job control
	set -e								# End with status other than 0
	set -u								# End with undefined variable reference
	set -o pipefail						# End with in pipe error

	trap 'exit 1' SIGHUP SIGINT SIGQUIT SIGTERM

	if set -o | grep "^xtrace\s*on$"; then
		exec 2>&1
	fi

	# --- check the execution user --------------------------------------------
	# shellcheck disable=SC2312
	if [[ "root" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	# --- unmount -------------------------------------------------------------
	if mount | grep -q "/srv/user/share/chroot/almalinux-9"; then
		umount $(awk '{print $2;}' /proc/mounts | grep "/srv/user/share/chroot/almalinux-9" | sort -r)
	fi

	# --- create directory ----------------------------------------------------
	rm -rf "/srv/user/share/chroot/almalinux-9"
	mkdir -p "/srv/user/share/chroot/almalinux-9"

	# --- create chgroot environment ------------------------------------------
	dnf \
		--assumeyes \
		--config "/srv/user/share/chroot/_repo/almalinux.repo" \
		--disablerepo=* \
		--enablerepo=almalinux-chroot-BaseOS \
		--enablerepo=almalinux-chroot-AppStream \
		--enablerepo=almalinux-chroot-Extras \
		--installroot="/srv/user/share/chroot/almalinux-9" \
		--releasever=9 \
		install \
			'@Minimal Install' \
			bash-completion \
			vim \
			tree \
			man \
			wget \
			rsync \
			xorriso \
			procps \
			tar \
			cpio \
			curl \
			isomd5sum \
			bzip2 \
			lz4 \
			lzop \
			zstd
