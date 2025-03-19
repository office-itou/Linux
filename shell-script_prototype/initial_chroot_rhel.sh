#!/bin/bash

	rm -fr "${HOME}/repo"
	mkdir -p "${HOME}/repo"
	for _LIST in \
		"o  fedora-40           Fedora-40           mirrorlist  https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-40&arch=x86_64&country=JP  " \
		"o  fedora-41           Fedora-41           mirrorlist  https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-41&arch=x86_64&country=JP  " \
		"o  centos-stream-9     CentOS-stream-9     baseurl     https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/os/                         " \
		"o  centos-stream-10    CentOS-stream-10    baseurl     https://mirror.stream.centos.org/10-stream/BaseOS/x86_64/os/                        " \
		"x  almalinux-8         AlmaLinux-8         mirrorlist  https://mirrors.almalinux.org/mirrorlist/8/baseos/                                  " \
		"o  almalinux-9         AlmaLinux-9         mirrorlist  https://mirrors.almalinux.org/mirrorlist/9/baseos/                                  " \
		"x  almalinux-8         AlmaLinux-8         baseurl     https://repo.almalinux.org/almalinux/8/BaseOS/x86_64/os/                            " \
		"-  almalinux-9         AlmaLinux-9         baseurl     https://repo.almalinux.org/almalinux/9/BaseOS/x86_64/os/                            " \
		"x  rockylinux-8        RockyLinux-8        baseurl     https://download.rockylinux.org/pub/rocky/8/BaseOS/x86_64/os/                       " \
		"o  rockylinux-9        RockyLinux-9        baseurl     https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/                       " \
		"x  miraclelinux-8      MiracleLinux-8      baseurl     https://repo.dist.miraclelinux.net/miraclelinux/8-latest/BaseOS/x86_64/os/          " \
		"o  miraclelinux-9      MiracleLinux-9      baseurl     https://repo.dist.miraclelinux.net/miraclelinux/9-latest/BaseOS/x86_64/os/          "
	do
		read -r -a _LINE < <(echo "${_LIST}")
		if [[ "${_LINE[0]}" != "o" ]]; then
			continue
		fi
		printf "%-20.20s %s\n" "${_LINE[1]}" "${_LINE[4]}"
		case "${_LINE[3]}" in
			mirrorlist)
				case "${_LINE[1]%-*}" in
					fedora)
						cat <<- _EOT_ > "${HOME}/repo/${_LINE[1]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]//-/ } - BaseOS
							mirrorlist=${_LINE[4]}
							enabled=1
							gpgcheck=0
							
_EOT_
						;;
					almalinux)
						cat <<- _EOT_ > "${HOME}/repo/${_LINE[1]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]//-/ } - BaseOS
							mirrorlist=${_LINE[4]}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]}-chroot-AppStream]
							name=${_LINE[2]//-/ } - AppStream
							mirrorlist=${_LINE[4]/baseos/appstream}
							enabled=1
							gpgcheck=0
							
							[${_LINE[1]}-chroot-Extras]
							name=${_LINE[2]}-Extras
							mirrorlist=${_LINE[4]/baseos/extras}
							enabled=1
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
						cat <<- _EOT_ > "${HOME}/repo/${_LINE[1]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]}-BaseOS
							baseurl=${_LINE[4]}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-AppStream]
							name=${_LINE[2]}-AppStream
							baseurl=${_LINE[4]/BaseOS/AppStream}
							gpgcheck=0
							
_EOT_
						;;
					*)
						cat <<- _EOT_ > "${HOME}/repo/${_LINE[1]}".repo
							[${_LINE[1]}-chroot-BaseOS]
							name=${_LINE[2]}-BaseOS
							baseurl=${_LINE[4]}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-AppStream]
							name=${_LINE[2]}-AppStream
							baseurl=${_LINE[4]/BaseOS/AppStream}
							gpgcheck=0
							
							[${_LINE[1]}-chroot-Extras]
							name=${_LINE[2]}-Extras
							baseurl=${_LINE[4]/BaseOS/extras}
							gpgcheck=0
							
_EOT_
						;;
				esac
				;;
			*)
				;;
		esac
	done
