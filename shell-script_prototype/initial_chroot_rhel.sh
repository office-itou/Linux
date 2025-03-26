#!/bin/bash

	case "${1:-}" in
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
	if [[ "$(whoami)" != "root" ]]; then
		echo "run as root user."
		exit 1
	fi

	# --- working directory name ----------------------------------------------
	declare -r    PROG_PATH="$0"
#	declare -r -a PROG_PARM=("${@:-}")
#	declare -r    PROG_DIRS="${PROG_PATH%/*}"
	declare -r    PROG_NAME="${PROG_PATH##*/}"
	declare -r    PROG_PROC="${PROG_NAME}.$$"
	              DIRS_TEMP="$(mktemp -qtd "${PROG_PROC}.XXXXXX")"
	readonly      DIRS_TEMP

	trap 'rm -rf '"${DIRS_TEMP:?}"'' EXIT

	# --- shared directory parameter ------------------------------------------
	declare -r    DIRS_TOPS="/srv"							# top of shared directory
#	declare -r    DIRS_HGFS="${DIRS_TOPS}/hgfs"				# vmware shared
#	declare -r    DIRS_HTML="${DIRS_TOPS}/http/html"		# html contents
#	declare -r    DIRS_SAMB="${DIRS_TOPS}/samba"			# samba shared
#	declare -r    DIRS_TFTP="${DIRS_TOPS}/tftp"				# tftp contents
	declare -r    DIRS_USER="${DIRS_TOPS}/user"				# user file

#	# --- shared of user file -------------------------------------------------
	declare -r    DIRS_SHAR="${DIRS_USER}/share"			# shared of user file
#	declare -r    DIRS_CONF="${DIRS_SHAR}/conf"				# configuration file
#	declare -r    DIRS_KEYS="${DIRS_CONF}/_keyring"			# keyring file
#	declare -r    DIRS_TMPL="${DIRS_CONF}/_template"		# templates for various configuration files
#	declare -r    DIRS_IMGS="${DIRS_SHAR}/imgs"				# iso file extraction destination
#	declare -r    DIRS_ISOS="${DIRS_SHAR}/isos"				# iso file
#	declare -r    DIRS_LOAD="${DIRS_SHAR}/load"				# load module
#	declare -r    DIRS_RMAK="${DIRS_SHAR}/rmak"				# remake file

	declare -r    DIRS_CHRT="/home/\${SUDO_USER}/chroot"	# chgroot file
	declare -r    DIRS_REPO="${DIRS_SHAR}/chroot/_repo"		# yum / dnf repository file
	declare -r    DIRS_SHEL="${DIRS_SHAR}/chroot/_shell"	# shell file

	rm -rf "${DIRS_REPO:?}"
	rm -rf "${DIRS_SHEL:?}"
	rm -rf "${DIRS_CHRT:?}"
	mkdir -p "${DIRS_REPO}"
	mkdir -p "${DIRS_SHEL}"
	mkdir -p "${DIRS_CHRT}"

	for _LIST in \
		'o  fedora-40           Fedora-40           fedora              metalink    https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch                   ' \
		'o  fedora-41           Fedora-41           fedora              metalink    https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch                   ' \
		'o  fedora-42           Fedora-42           fedora              metalink    https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch                   ' \
		'o  centos-stream-9     CentOS-stream-9     centos-stream       metalink    https://mirrors.centos.org/metalink?repo=centos-baseos-$stream&arch=$basearch&protocol=https,http   ' \
		'o  centos-stream-10    CentOS-stream-10    centos-stream       metalink    https://mirrors.centos.org/metalink?repo=centos-baseos-$stream&arch=$basearch&protocol=https,http   ' \
		'o  almalinux-9         AlmaLinux-9         almalinux           mirrorlist  https://mirrors.almalinux.org/mirrorlist/$releasever/baseos                                         ' \
		'o  rockylinux-9        RockyLinux-9        rockylinux          mirrorlist  https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever$rltype             ' \
		'o  miraclelinux-9      MiracleLinux-9      miraclelinux        mirrorlist  https://repo.dist.miraclelinux.net/miraclelinux/mirrorlist/$releasever/$basearch/baseos             ' \
		'-  -                   -                   -                   -           -                                                                                                   '
	do
		read -r -a _LINE < <(echo "${_LIST}")
		if [[ "${_LINE[0]}" != "o" ]]; then
			continue
		fi
		printf "%-20.20s %s\n" "${_LINE[1]}" "${_LINE[5]}"
		# --- create chgroot environment --------------------------------------
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${DIRS_SHEL}/mk_${_LINE[1]}".sh
			#!/bin/bash
			
			 	case "${1:-}" in
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
			 	if [[ "$(whoami)" != "root" ]]; then
			 		echo "run as root user."
			 		exit 1
			 	fi
			
			 	# --- unmount -------------------------------------------------------------
			 	if mount | grep -q "${DIRS_CHRT}/${_LINE[1]}"; then
			 		umount \$(awk '{print \$2;}' /proc/mounts | grep "${DIRS_CHRT}/${_LINE[1]}" | sort -r)
			 	fi
			
			 	# --- create directory ----------------------------------------------------
			 	rm -rf "${DIRS_CHRT}/${_LINE[1]}"
			 	mkdir -p "${DIRS_CHRT}/${_LINE[1]}"
			
			 	# --- create chgroot environment ------------------------------------------
			 	dnf \\
			 		--assumeyes \\
			 		--config "${DIRS_REPO}/${_LINE[3]}.repo" \\
			 		--disablerepo=* \\
			 		--enablerepo=${_LINE[1]%-*}-chroot-BaseOS \\
_EOT_
		case "${_LINE[1]%-*}" in
			fedora)
				;;
			centos-stream)
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_SHEL}/mk_${_LINE[1]}".sh
					 		--enablerepo=${_LINE[1]%-*}-chroot-AppStream \\
_EOT_
				;;
			*)
				cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_SHEL}/mk_${_LINE[1]}".sh
					 		--enablerepo=${_LINE[1]%-*}-chroot-AppStream \\
					 		--enablerepo=${_LINE[1]%-*}-chroot-Extras \\
_EOT_
				;;
		esac
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' >> "${DIRS_SHEL}/mk_${_LINE[1]}".sh
			 		--installroot="${DIRS_CHRT}/${_LINE[1]}" \\
			 		--releasever=${_LINE[1]##*-} \\
			 		install \\
			 			'@Minimal Install' \\
			 			bash-completion \\
			 			vim \\
			 			tree \\
			 			man \\
			 			wget \\
			 			rsync \\
			 			xorriso \\
			 			procps \\
			 			tar \\
			 			cpio \\
			 			curl \\
			 			isomd5sum \\
			 			bzip2 \\
			 			lz4 \\
			 			lzop \\
			 			zstd
_EOT_
		if [[ "${_LINE[1]%-*}" = "fedora" ]] && [[ "${_LINE[1]##*-}" -ge 41 ]]; then
			sed -i "${DIRS_SHEL}/mk_${_LINE[1]}".sh     \
			    -e '/dnf/,/[^\]$/                    {' \
			    -e 's/@Minimal Install/@admin-tools/ }'
		fi
		chmod +x "${DIRS_SHEL}/mk_${_LINE[1]}".sh
		# --- create repository -----------------------------------------------
		if [[ -e "${DIRS_REPO}/${_LINE[3]}".repo ]]; then
			continue
		fi
		case "${_LINE[4]}" in
			mirrorlist)
				case "${_LINE[1]%-*}" in
					fedora)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]%-*}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							mirrorlist=${_LINE[5]}
							enabled=1
							gpgcheck=0
							
_EOT_
						;;
					almalinux   | \
					miraclelinux)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]%-*}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							mirrorlist=${_LINE[5]}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]%-*}-chroot-AppStream]
							name=${_LINE[2]%-*} \$releasever - \$basearch - AppStream
							mirrorlist=${_LINE[5]/baseos/appstream}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]%-*}-chroot-Extras]
							name=${_LINE[2]%-*} \$releasever - \$basearch - Extras
							mirrorlist=${_LINE[5]/baseos/extras}
							enabled=1
							gpgcheck=0
							
_EOT_
						;;
					rockylinux)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]%-*}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							mirrorlist=${_LINE[5]}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]%-*}-chroot-AppStream]
							name=${_LINE[2]%-*} \$releasever - \$basearch - AppStream
							mirrorlist=${_LINE[5]/BaseOS/AppStream}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]%-*}-chroot-Extras]
							name=${_LINE[2]%-*} \$releasever - \$basearch - Extras
							mirrorlist=${_LINE[5]/BaseOS/extras}
							enabled=1
							gpgcheck=0
							
_EOT_
						;;
					*)
						;;
				esac
				;;
			metalink)
				_LINE[2]="${_LINE[2]%-*}-\$releasever"
				case "${_LINE[1]%-*}" in
					fedora)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]%-*}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							metalink=${_LINE[5]}
							gpgcheck=0
							
_EOT_
						;;
					centos-stream)
						_LINE[5]="${_LINE[5]/stream/releasever-stream}"
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]%-*}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							metalink=${_LINE[5]}
							gpgcheck=0
							
							[${_LINE[1]%-*}-chroot-AppStream]
							name=${_LINE[2]%-*} \$releasever - \$basearch - AppStream
							metalink=${_LINE[5]/baseos/appstream}
							gpgcheck=0
							
_EOT_
						;;
					*)
						;;
				esac
				;;
			baseurl)
				case "${_LINE[1]%-*}" in
					fedora)
						;;
					centos-stream)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							baseurl=${_LINE[5]}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-AppStream]
							name=${_LINE[2]%-*} \$releasever - \$basearch - AppStream
							baseurl=${_LINE[5]/BaseOS/AppStream}
							gpgcheck=0
							
_EOT_
						;;
					*)
						cat <<- _EOT_ > "${DIRS_REPO}/${_LINE[3]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]%-*} \$releasever - \$basearch - BaseOS
							baseurl=${_LINE[5]}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-AppStream]
							name=${_LINE[2]%-*} \$releasever - \$basearch - AppStream
							baseurl=${_LINE[5]/BaseOS/AppStream}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-Extras]
							name=${_LINE[2]%-*} \$releasever - \$basearch - Extras
							baseurl=${_LINE[5]/BaseOS/extras}
							gpgcheck=0
							
_EOT_
						;;
				esac
				;;
			*)
				;;
		esac
		chmod 600 "${DIRS_REPO}/${_LINE[3]}".repo
	done
