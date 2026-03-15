#!/bin/bash

set -eu

declare -r    _DIRS_MKOS="/srv/user/share/conf/_mkosi"

declare -a    __DIST=""
declare -a    __CODE=""

for __CONF in "${_DIRS_MKOS:?}"/_template/mkosi.*.conf
do
	sed -ne '/^\[Match\]/,/^#*\[.\+\]/ {' -e '/^#*Distribution=/{' -e 's/^.*[^[:alnum:]]//p}}' "${__CONF}" | while read -r __DIST
	do
		sed -ne '/^\[Match\]/,/^#*\[.\+\]/ {' -e '/^#Release=/{' -e 's/^.*[^[:alnum:].]//p}}' "${__CONF}" | while read -r __CODE
		do
			case "${__CODE}" in
				bullseye    ) __VERS="11.0.${__CODE}";;		# debian
				bookworm    ) __VERS="12.0.${__CODE}";;
				trixie      ) __VERS="13.0.${__CODE}";;
				forky       ) __VERS="14.0.${__CODE}";;
				duke        ) __VERS="15.0.${__CODE}";;
				testing     ) __VERS="xx.x.${__CODE}";;
				sid         ) __VERS="xx.x.${__CODE}";;
				experimental) __VERS="xx.x.${__CODE}";;
				xenial      ) __VERS="16.04.${__CODE}";;	# ubuntu
				bionic      ) __VERS="18.04.${__CODE}";;
				focal       ) __VERS="20.04.${__CODE}";;
				jammy       ) __VERS="22.04.${__CODE}";;
				noble       ) __VERS="24.04.${__CODE}";;
				plucky      ) __VERS="25.04.${__CODE}";;
				questing    ) __VERS="25.10.${__CODE}";;
				resolute    ) __VERS="26.04.${__CODE}";;
				F*          ) if [[ "${__DIST}" != "fedora" ]]; then continue; fi; __VERS="${__CODE#F}";;	# fedora
				*           ) if [[ "${__DIST}" =  "fedora" ]]; then continue; fi; __VERS="${__CODE}"  ;;	# rhel, opensuse
			esac
			__EDTN=":__EDITION__:"
			__PATH="${_DIRS_MKOS:?}/mkosi.conf.d/mkosi.${__DIST:?}.${__VERS:?}.${__EDTN:?}.conf"
			__SRVR="${__PATH//${__EDTN}/server}"
			__DTOP="${__PATH//${__EDTN}/desktop}"
			# --- server ------------------------------------------------------
			echo "create: ${__SRVR}"
			sed -e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
			    -e '/^Distribution=/                           s/^/#/' \
			    -e '/^#*Distribution=|*'"${__DIST}"'/          s/^#//' \
			    -e '/^Release=/                                s/^/#/' \
			    -e '/^#*Release=|*'"${__CODE}"'/               s/^#//' \
			    -e '/^Environment=/                                 {' \
			    -e 's/!\(EDITION=desktop\)/\1/                       ' \
			    -e 's/\(EDITION=desktop\)/!\1/                       ' \
			    -e '}}'                                                \
			  "${__CONF}"                                              \
			> "${__SRVR}"
			case "${__DIST:?}.${__VERS:?}" in
				debian.11.0.*)
					sed -i "${__SRVR}"                                         \
					    -e '/^\[Distribution\]/,/^#*\[.\+\]/                {' \
					    -e '/^Repositories=/ s/,*non-free-firmware//         ' \
					    -e '}'                                                 \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *dhcpcd-base */                        s/^ /#/' \
					    -e '/^ *systemd-boot */                       s/^ /#/' \
					    -e '/^ *systemd-boot-efi */                   s/^ /#/' \
					    -e '/^ *systemd-resolved */                   s/^ /#/' \
					    -e '/^ *ubuntu-keyring */                     s/^ /#/' \
					    -e '/^ *util-linux-extra */                   s/^ /#/' \
					    -e '}}'
					;;
				ubuntu.22.04.*)
					sed -i "${__SRVR}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *dhcpcd-base */                        s/^ /#/' \
					    -e '/^ *systemd-boot */                       s/^ /#/' \
					    -e '/^ *systemd-boot-efi */                   s/^ /#/' \
					    -e '/^ *systemd-resolved */                   s/^ /#/' \
					    -e '/^ *ubuntu-keyring */                     s/^ /#/' \
					    -e '/^ *util-linux-extra */                   s/^ /#/' \
					    -e '}}'
					;;
				fedora.*)
					sed -i "${__SRVR}"                                         \
					    -e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
					    -e '/^Release=/ s/[^=]\+$/'"${__CODE#F}"'/           ' \
					    -e '}'                                                 \
					    -e '/^\[Distribution\]/,/^#*\[.\+\]/                {' \
					    -e '/^Repositories=epel$/                      s/^/#/' \
					    -e '}'                                                 \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *epel-release */                       s/^ /#/' \
					    -e '/^ *kpatch */                             s/^ /#/' \
					    -e '/^ *kpatch-dnf */                         s/^ /#/' \
					    -e '/^ *systemd-timesyncd */                  s/^ /#/' \
					    -e '}}'
					;;
				centos.9 | \
				alma.9   | \
				rocky.9)
					sed -i "${__SRVR}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *amd-ucode-firmware */                 s/^ /#/' \
					    -e '/^ *google-noto-sans-cjk-vf-fonts */      s/^ /#/' \
					    -e '/^ *google-noto-sans-mono-cjk-vf-fonts */ s/^ /#/' \
					    -e '/^ *google-noto-serif-cjk-vf-fonts */     s/^ /#/' \
					    -e '/^ *iwlwifi-dvm-firmware */               s/^ /#/' \
					    -e '/^ *iwlwifi-mvm-firmware */               s/^ /#/' \
					    -e '/^ *plocate */                            s/^ /#/' \
					    -e '/^ *realtek-firmware */                   s/^ /#/' \
					    -e '/^ *vim-data */                           s/^ /#/' \
					    -e '/^ *xxd */                                s/^ /#/' \
					    -e '}}'
					;;
				opensuse.15.6)
					sed -i "${__SRVR}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *flake-pilot-firecracker-dracut-netstart */ s/^ /#/' \
					    -e '/^ *dbus-1-daemon */                      s/^ /#/' \
					    -e '/^ *systemd-resolved */                   s/^ /#/' \
					    -e '}}'
					;;
				*) ;;
			esac
			# --- desktop -----------------------------------------------------
			echo "create: ${__DTOP}"
			sed -e '/^\[Match\]/,/^#*\[.\+\]/                       {' \
			    -e '/^Environment=/                                 {' \
			    -e 's/!\(EDITION=desktop\)/\1/                       ' \
			    -e '}}'                                                \
			    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
			    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
			    -e '/^#.* desktop .*$/,/^# *-\+.*$/                 {' \
			    -e '/^# *[[:alnum:]]\+/                      s/^#/ /g' \
			    -e '}}}'                                               \
			  "${__SRVR}"                                              \
			> "${__DTOP}"
			case "${__DIST:?}.${__VERS:?}" in
				debian.11.0.*)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *adwaita-icon-theme-legacy */          s/^ /#/' \
					    -e '/^ *gnome-classic */                      s/^ /#/' \
					    -e '/^ *gnome-classic-xsession */             s/^ /#/' \
					    -e '/^ *fcitx5-anthy */                       s/^ /#/' \
					    -e '/^ *gnome-shell-extension-manager */      s/^ /#/' \
					    -e '/^ *vlc-plugin-pipewire */                s/^ /#/' \
					    -e '}}'
					;;
				debian.12.0.*)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *adwaita-icon-theme-legacy */          s/^ /#/' \
					    -e '/^ *gnome-classic */                      s/^ /#/' \
					    -e '/^ *gnome-classic-xsession */             s/^ /#/' \
					    -e '}}'
					;;
				debian.13.0.*)
					;;
				debian.14.0.* | \
				debian.15.0.* | \
				debian.xx.x.*)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *gnome-classic-xsession */             s/^ /#/' \
					    -e '/^ *fcitx5-mozc */                        s/^ /#/' \
					    -e '/^ *mozc-utils-gui */                     s/^ /#/' \
					    -e '}}'
					;;
				ubuntu.22.04.*)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *vlc-plugin-pipewire */                s/^ /#/' \
					    -e '}}'
					;;
				ubuntu.26.04.*)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *fcitx5-mozc */                        s/^ /#/' \
					    -e '/^ *mozc-utils-gui */                     s/^ /#/' \
					    -e '}}'
					;;
				centos.9 | \
				alma.9   | \
				rocky.9)
					sed -i "${__DTOP}"                                         \
					    -e '/^\[Content\]/,/^#*\[.\+\]/                     {' \
					    -e '/^Packages=/,/^#*\(\[.\+\]\|[[:alnum:]]\+=\)/   {' \
					    -e '/^ *google-noto-sans-cjk-vf-fonts */      s/^ /#/' \
					    -e '/^ *google-noto-sans-mono-cjk-vf-fonts */ s/^ /#/' \
					    -e '/^ *google-noto-serif-cjk-vf-fonts */     s/^ /#/' \
					    -e '/^ *realtek-firmware */                   s/^ /#/' \
					    -e '/^ *gnome-initial-setup */                s/^ /#/' \
					    -e '}}'
					;;
				*) ;;
			esac
		done
	done
done
chown sambauser "${_DIRS_MKOS:?}"/mkosi.conf.d/*.conf
chmod g+w "${_DIRS_MKOS:?}"/mkosi.conf.d/*.conf
