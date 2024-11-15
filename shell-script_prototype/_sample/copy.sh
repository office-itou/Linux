#!/bin/bash

set -e
set -u

declare -r -a LIST=( \
/etc/apache2/apache2.conf \
/etc/apt/sources.list \
/etc/clamav/freshclam.conf \
/etc/connman/main.conf \
/etc/default/grub \
/etc/default/tftpd-hpa \
/etc/dnsmasq.d/pxe.conf \
/etc/firewalld/zones/home.xml \
/etc/firewalld/zones/public.xml \
/etc/fstab \
/etc/hosts \
/etc/hosts.allow \
/etc/hosts.deny \
/etc/locale.gen \
/etc/nsswitch.conf \
/etc/resolv.conf \
/etc/samba/smb.conf \
/etc/ssh/sshd_config.d/sshd.conf \
/etc/systemd/timesyncd.conf \
/etc/wireplumber/wireplumber.conf.d/50-alsa-config.conf \
/root/.bash_history \
/root/.bashrc \
/root/.config/fcitx5/profile \
/root/.config/gtk-3.0/settings.ini \
/root/.config/libfm/libfm.conf \
/root/.config/lxpanel/LXDE/panels/panel \
/root/.config/lxsession/LXDE/desktop.conf \
/root/.config/lxterminal/lxterminal.conf \
/root/.config/monitors.xml \
/root/.config/openbox/lxde-rc.xml \
/root/.config/pcmanfm/LXDE/desktop-items-0.conf \
/root/.curlrc \
/root/.gtkrc-2.0 \
/root/.vimrc \
/home/*/.bash_history \
/home/*/.bashrc \
/home/*/.config/fcitx5/profile \
/home/*/.config/gtk-3.0/settings.ini \
/home/*/.config/libfm/libfm.conf \
/home/*/.config/lxpanel/LXDE/panels/panel \
/home/*/.config/lxsession/LXDE/desktop.conf \
/home/*/.config/lxterminal/lxterminal.conf \
/home/*/.config/monitors.xml \
/home/*/.config/openbox/lxde-rc.xml \
/home/*/.config/pcmanfm/LXDE/desktop-items-0.conf \
/home/*/.curlrc \
/home/*/.gtkrc-2.0 \
/home/*/.vimrc \
/lib/systemd/system/dnsmasq.service \
/var/lib/tftpboot/autoexec.ipxe \
)
for LINE in "${LIST[@]}"
do
	if [[ ! -f "${LINE}" ]]; then
		continue
	fi
	DIRS="/mnt/hgfs/share/data/usr/jun/dat/My Documents/Documents/Deliverables/GitHub/Linux/storage${LINE%/*}"
	if [[ ! -d "${DIRS}/." ]]; then
		mkdir -p "${DIRS}"
	fi
	echo "${LINE}"
	cp --preserve=timestamps "${LINE}" "${DIRS}" || true
done
