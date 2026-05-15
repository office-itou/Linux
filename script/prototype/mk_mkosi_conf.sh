#!/bin/bash

set -eu

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_create() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare -r    __TGET_DIST="${2:-}"	# distribution
	declare -r    __TGET_RELS="${3:-}"	# release
	declare -r    __TGET_REPO="${4:-}"	# repository
	declare -r    __TGET_SAND="${5:-}"	# sandbox
	declare -r    __TGET_PACK="${6:-}"	# package

	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		# === Match ===================================================================
		[Match]
		${__TGET_DIST:-"#Distribution="}
		Environment=!EDITION=desktop
		${__TGET_RELS:-"#Release=general"}

		# === Distribution ============================================================
		[Distribution]
		${__TGET_REPO:-"#Repositories="}
		RepositoryKeyCheck=no
		RepositoryKeyFetch=yes

		# === Build ===================================================================
		[Build]
		WithNetwork=yes
		WorkspaceDirectory=\$SUDO_HOME/.workdirs/mkosi/%d-%r-%a-\$EDITION/workdir/
		PackageCacheDirectory=/srv/user/share/cache/%d-%r-%a
		${__TGET_SAND:-"#SandboxTrees="}
		#CacheDirectory=/srv/user/share/cache/
		#CacheKey=%d-%r-%a
		#BuildSources=\$SUDO_HOME/.workdirs/mkosi/%d-%r-%a/sources/
		#BuildKey=%d-%r-%a

		# === Output ==================================================================
		[Output]
		#Format=disk
		#Format=directory
		Output=rootfs
		OutputDirectory=\$SUDO_HOME/.workdirs/mkosi/%d-%r-%a-\$EDITION/outputs/

		# === Runtime =================================================================
		[Runtime]
		Machine=pc-%d-%r-%a

		# === Validation ==============================================================
		[Validation]
		SecureBoot=no

		# === Content =================================================================
		[Content]
		# --- user --------------------------------------------------------------------
		RootPassword=r00t
		#Autologin=yes
		# --- locale ------------------------------------------------------------------
		Locale=ja_JP.UTF-8
		LocaleMessages=ja_JP.UTF-8
		Keymap=jp
		Timezone=Asia/Tokyo
		# --- host --------------------------------------------------------------------
		Hostname=sv-%d.workgroup
		RootShell=/bin/bash
		SELinuxRelabel=no
		Bootable=no
		# --- initramfs ---------------------------------------------------------------
		#MakeInitrd=yes
		#InitrdPackages=
		# --- install -----------------------------------------------------------------
		WithRecommends=yes
		#SyncScripts=mkosi.builddir/add-backports.sh
		#SyncScripts=base/add-backports.sh
		${__TGET_PACK:-"#Packages="}

		# === eof =====================================================================
_EOT_
}

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_template() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare       __DIST=""				# distribution
	declare       __RELS=""				# release
	declare       __REPO=""				# repository
	declare       __SAND=""				# sandbox
	declare       __PACK=""				# package

	__DIST="distribution"
	__RELS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
_EOT_
	)"
	__REPO=""
	__SAND="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
_EOT_
	)"
	__PACK="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Packages=
			    # --- mkosi ---------------------------------------------------------------
			    # --- kernel --------------------------------------------------------------
			    # --- microcode -----------------------------------------------------------
			    # --- grub ----------------------------------------------------------------
			    # --- development ---------------------------------------------------------
			    # --- dracut --------------------------------------------------------------
			    # --- dracut install modules ----------------------------------------------
			    # --- qemu ----------------------------------------------------------------
			    # --- server (from the preconfiguration file) -----------------------------
			    # --- desktop (from the preconfiguration file) ----------------------------
			    # --- installation environment --------------------------------------------
			    # -------------------------------------------------------------------------
_EOT_
	)"
	fnMake_mkosi_conf_create "${__TGET_PATH:?}" "${__DIST:-}" "${__RELS:-}" "${__REPO:-}" "${__SAND:-}" "${__PACK:-}"
}

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_debian() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare       __DIST=""				# distribution
	declare       __RELS=""				# release
	declare       __REPO=""				# repository
	declare       __SAND=""				# sandbox
	declare       __PACK=""				# package

	# o 11.0  bullseye
	# o 12.0  bookworm
	# o 13.0  trixie
	# o 14.0  forky
	# - 15.0  duke
	# o ----  testing
	# o ----  sid
	# o ----  experimental

	__DIST="Distribution=debian"
	__RELS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			#Release=bullseye
			#Release=bookworm
			#Release=trixie
			#Release=forky
			#Release=testing
			#Release=sid
			#Release=experimental
_EOT_
	)"
	__REPO="Repositories=main,contrib,non-free,non-free-firmware"
	__SAND="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			SandboxTrees=repository/apt-conf:/etc/apt/apt.conf.d/apt-conf
			SandboxTrees=repository/%d-%r-backports.sources:/etc/apt/sources.list.d/%d-%r-backports.sources
_EOT_
	)"
	__PACK="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Packages=
			    # --- mkosi ---------------------------------------------------------------
			#-  mkosi                               # build Bespoke OS Images
			    debian-archive-keyring              # OpenPGP archive certificates of the Debian archive
			    debian-keyring                      # OpenPGP certificates of Debian Developers and Maintainers
			    dnf                                 # Dandified Yum package manager
			    dosfstools                          # utilities for making and checking MS-DOS FAT filesystems
			#o  gawk                                # GNU awk, a pattern scanning and processing language
			#o  grub-efi-amd64-bin                  # GRand Unified Bootloader, version 2 (EFI-AMD64 modules)
			#o  grub-pc-bin                         # GRand Unified Bootloader, version 2 (PC/BIOS modules)
			#o  grub2-common                        # GRand Unified Bootloader (common files for version 2)
			    mtools                              # Tools for manipulating MSDOS files
			    python3-pefile                      # Portable Executable (PE) parsing module for Python
			    squashfs-tools                      # Tool to create and append to squashfs filesystems
			    systemd-container                   # systemd container/nspawn tools
			    systemd-repart                      # Provides the systemd-repart and systemd-sbsign utilities
			#-  task-english                        # General English environment
			    task-japanese                       # Japanese environment
			    ubuntu-archive-keyring              # GnuPG keys of the Ubuntu archive - transition package
			    ubuntu-keyring                      # GnuPG keys used by Ubuntu Project
			#o  xorriso                             # command line ISO-9660 and Rock Ridge manipulation tool
			#o  xxd                                 # tool to make (or reverse) a hex dump
			    zypper                              # command line software manager using libzypp
			    # --- kernel --------------------------------------------------------------
			    linux-image-amd64                   # Linux for 64-bit PCs (meta-package)
			    # --- microcode -----------------------------------------------------------
			    amd64-microcode                     # Platform firmware and microcode for AMD CPUs and SoCs
			    intel-microcode                     # Processor microcode firmware for Intel CPUs
			    # --- grub ----------------------------------------------------------------
			    grub-efi-amd64-bin                  # GRand Unified Bootloader, version 2 (EFI-AMD64 modules)
			    grub-pc-bin                         # GRand Unified Bootloader, version 2 (PC/BIOS modules)
			    grub2-common                        # GRand Unified Bootloader (common files for version 2)
			    isolinux                            # collection of bootloaders (ISO 9660 bootloader)
			    syslinux-common                     # collection of bootloaders (common)
			    # --- development ---------------------------------------------------------
			    # --- dracut --------------------------------------------------------------
			    dracut                              # Initramfs generator using udev
			    dracut-network                      # dracut is an event driven initramfs infrastructure (network modules)
			    dracut-live                         # dracut is an event driven initramfs infrastructure (live image modules)
			    locales                             # GNU C Library: National Language (locale) data
			    locales-all                         # GNU C Library: Precompiled locale data
			    xz-utils                            # XZ-format compression utilities
			    # --- dracut install modules ----------------------------------------------
			    # --- qemu ----------------------------------------------------------------
			    bridge-utils                        # Utilities for configuring the Linux Ethernet bridge
			    libvirt0                            # virtualization library
			    novnc                               # HTML5 VNC client - daemon and programs
			    ovmf                                # UEFI firmware for 64-bit x86 virtual machines
			    qemu-system-x86                     # QEMU full system emulation binaries (x86)
			    qemu-utils                          # QEMU utilities
			    virtiofsd                           # Virtio-fs vhost-user device daemon
			    websockify                          # WebSockets support for any application/server
			    # --- server (from the preconfiguration file) -----------------------------
			    apparmor                            # user-space parser utility for AppArmor
			    apparmor-utils                      # utilities for controlling AppArmor
			#-  selinux-basics                      # SELinux basic support
			#-  selinux-policy-default              # Strict and Targeted variants of the SELinux policy
			    auditd                              # User space tools for security auditing
			#-  rpm                                 # package manager for RPM
			    sudo                                # Provide limited super user privileges to specific users
			    firewalld                           # dynamically managed firewall with support for network zones
			    traceroute                          # Traces the route taken by packets over an IPv4/IPv6 network
			    network-manager                     # network management framework (daemon and userspace tools)
			    bash-completion                     # programmable completion for the bash shell
			    build-essential                     # Informational list of build-essential packages
			    wget                                # retrieves files from the web
			    curl                                # command line tool for transferring data with URL syntax
			    vim                                 # Vi IMproved - enhanced vi editor
			    bc                                  # GNU bc arbitrary precision calculator language
			    rsync                               # fast, versatile, remote (and local) file-copying tool
			    eject                               # ejects CDs and operates CD-Changers under Linux
			    tree                                # displays an indented directory tree, in color
			    shellcheck                          # lint tool for shell scripts
			    xxd                                 # tool to make (or reverse) a hex dump
			    xorriso                             # command line ISO-9660 and Rock Ridge manipulation tool
			    gawk                                # GNU awk, a pattern scanning and processing language
			    jq                                  # lightweight and flexible command-line JSON processor
			    tasksel                             # tool for selecting tasks for installation on Debian systems
			    clamav                              # anti-virus utility for Unix - command-line interface
			    clamav-daemon                       # anti-virus utility for Unix - scanner daemon
			    openssh-server                      # secure shell (SSH) server, for secure access from remote machines
			    systemd-resolved                    # systemd DNS resolver
			    systemd-timesyncd                   # minimalistic service to synchronize local time with NTP servers
			    dnsmasq                             # Small caching DNS proxy and DHCP/TFTP server - system daemon
			    bind9-dnsutils                      # Clients provided with BIND 9
			    apache2                             # Apache HTTP Server
			    samba                               # SMB/CIFS file, print, and login server for Unix
			    smbclient                           # command-line SMB/CIFS clients for Unix
			    cifs-utils                          # Common Internet File System utilities
			    libnss-winbind                      # Samba nameservice integration plugins
			    lvm2                                # Linux Logical Volume Manager
			    open-vm-tools                       # Open VMware Tools for virtual machines hosted on VMware (CLI)
			    open-vm-tools-desktop               # Open VMware Tools for virtual machines hosted on VMware (GUI)
			    # --- desktop (from the preconfiguration file) ----------------------------
			#   task-desktop                        # Debian desktop environment
			#   task-gnome-desktop                  # GNOME
			#   task-laptop                         # laptop
			#   task-japanese                       # Japanese environment
			#   task-japanese-desktop               # Japanese desktop
			#   adwaita-icon-theme-legacy           # fullcolor icon theme providing fallback for legacy applications
			#   fonts-noto                          # metapackage to pull in all Noto fonts
			#   fonts-noto-cjk                      # "No Tofu" font families with large Unicode coverage (CJK regular and bold)
			#   fonts-noto-cjk-extra                # "No Tofu" font families with large Unicode coverage (CJK all weight)
			#   fonts-noto-extra                    # "No Tofu" font families with large Unicode coverage (extra)
			#   fonts-noto-color-emoji              # color emoji font from Google
			#   fonts-noto-mono                     # "No Tofu" monospaced font family with large Unicode coverage
			#   fonts-noto-ui-core                  # "No Tofu" font families with large Unicode coverage (UI core)
			#   fonts-noto-ui-extra                 # "No Tofu" font families with large Unicode coverage (UI extra)
			#   fonts-noto-unhinted                 # "No Tofu" font families with large Unicode coverage (unhinted)
			#   gnome-initial-setup                 # Initial GNOME system setup helper
			#   gnome-packagekit                    # Graphical distribution neutral package manager for GNOME
			#   gnome-tweaks                        # tool to adjust advanced configuration settings for GNOME
			#   gnome-shell-extensions              # Extensions to extend functionality of GNOME Shell
			#   gnome-shell-extension-manager       # Utility for managing GNOME Shell Extensions
			#   gnome-classic                       # Classic version of the GNOME desktop
			#   gnome-classic-xsession              # Classic version of the GNOME desktop using Xorg
			#   im-config                           # Input method configuration framework
			#   x11-common                          # X Window System (X.Org) infrastructure
			#   zenity                              # Display graphical dialog boxes from shell scripts
			#   fcitx5                              # Fcitx Input Method Framework v5
			#   fcitx5-anthy                        # Fcitx5 wrapper for Anthy IM engine
			#   fcitx5-mozc                         # Mozc engine for fcitx5 - Client of the Mozc input method
			#   mozc-utils-gui                      # GUI utilities of the Mozc input method
			#   libreoffice-l10n-ja                 # office productivity suite -- Japanese language package
			#   libreoffice-help-ja                 # office productivity suite -- Japanese help
			#   firefox-esr-l10n-ja                 # Japanese language package for Firefox ESR
			#   thunderbird                         # mail/news client with RSS, chat and integrated spam filter support
			#   thunderbird-l10n-ja                 # Japanese language package for Thunderbird
			#   chromium                            # web browser
			#   chromium-sandbox                    # web browser - setuid security sandbox for chromium
			#   chromium-l10n                       # web browser - language packs
			#   chromium-driver                     # web browser - WebDriver support
			#   chromium-shell                      # web browser - minimal shell
			#   rhythmbox                           # music player and organizer for GNOME
			#   libavcodec-extra                    # FFmpeg library with extra codecs (metapackage)
			#   gstreamer1.0-libav                  # ffmpeg plugin for GStreamer
			#   pipewire-audio-client-libraries     # transitional package for pipewire-alsa and pipewire-jack
			#   vlc                                 # multimedia player and streamer
			#   vlc-l10n                            # translations for VLC
			#   vlc-plugin-pipewire                 # PipeWire audio plugins for VLC
			#   bluetooth                           # Bluetooth support (metapackage)
			#   bluez                               # Bluetooth tools and daemons
			#   bluez-firmware                      # Firmware for Bluetooth devices
			#   firmware-realtek                    # Binary firmware for Realtek network and audio chips
			#   blueman                             # Graphical bluetooth manager
			#   printer-driver-escpr                # printer driver for Epson Inkjet that use ESC/P-R
			    # --- installation environment --------------------------------------------
			#   apt-listchanges                     # package change history notification tool
			#   apt-utils                           # package management related utility programs
			    attr                                # utilities for manipulating filesystem extended attributes
			    btrfs-progs                         # Checksumming Copy on Write Filesystem utilities
			    dbus                                # simple interprocess messaging system (system message bus)
			    dbus-broker                         # Linux D-Bus Message Broker
			#   debian-faq                          # Debian Frequently Asked Questions
			#   dhcpcd-base                         # DHCPv4 and DHCPv6 dual-stack client (binaries and exit hooks)
			#   distro-info-data                    # information about the distributions' releases (data files)
			#   doc-debian                          # Debian Project documentation and other documents
			    exfatprogs                          # exFAT file system utilities
			#o  fbterm                              # fast framebuffer based terminal emulator for Linux
			    fdisk                               # collection of partitioning utilities
			    file                                # Recognize the type of data in a file using "magic" numbers
			#o  fonts-unifont                       # OpenType version of GNU Unifont
			    fuse3                               # Filesystem in Userspace (3.x version)
			#   groff-base                          # GNU troff text-formatting system (base system components)
			#   grub-efi-amd64                      # GRand Unified Bootloader, version 2 (EFI-AMD64 version)
			#   ifupdown                            # high level tools to configure network interfaces
			#   inetutils-telnet                    # telnet client
			#   init                                # metapackage ensuring an init system is installed
			#x  initramfs-tools                     # generic modular initramfs generator (automation)
			    initramfs-tools-bin                 # generic modular initramfs generator (binary tools)
			#x  initramfs-tools-core                # generic modular initramfs generator (core tools)
			#   installation-report                 # system installation report
			    iputils-ping                        # Tools to test the reachability of network hosts
			#   klibc-utils                         # small utilities built with klibc for early boot
			    less                                # pager program similar to more
			#o  libc-l10n                           # GNU C Library: localization files
			#o  libcap2-bin                         # POSIX 1003.1e capabilities (utilities)
			#   libklibc                            # minimal libc subset for use with initramfs
			#   libpam-wtmpdb                       # wtmp database PAM module
			#   libpipeline1                        # Unix process pipeline manipulation library
			#   libuchardet0                        # universal charset detection library - shared library
			#o  libx86-1                            # x86 real-mode library
			#o  linux-image-6.12.73+deb13-amd64     # Linux 6.12 for 64-bit PCs (signed)
			#o  locales                             # GNU C Library: National Language (locale) data [support]
			    login                               # system login tools
			#o  lv                                  # Powerful Multilingual File Viewer
			#   man-db                              # tools for reading manual pages
			#o  manpages-ja                         # Japanese version of the manual pages (for users)
			#o  manpages-ja-dev                     # Japanese version of the manual pages (for developers)
			    nano                                # small, friendly text editor inspired by Pico
			#   netcat-traditional                  # TCP/IP swiss army knife
			#o  nkf                                 # Network Kanji code conversion Filter
			    ntfs-3g                             # read/write NTFS driver for FUSE
			    openssl                             # Secure Sockets Layer toolkit - cryptographic utility
			    parted                              # disk partition manipulator
			#o  psf-unifont                         # PSF (console) version of GNU Unifont with APL support
			#   python-apt-common                   # Python interface to libapt-pkg (locales)
			#   python3-apt                         # Python 3 interface to libapt-pkg
			#   python3-debconf                     # interact with debconf from Python 3
			#   python3-debian                      # Python 3 modules to work with Debian-related data formats
			#   python3-debianbts                   # Python interface to Debian's Bug Tracking System
			#   python3-reportbug                   # Python modules for interacting with bug tracking systems
			#   reportbug                           # reports bugs in the Debian distribution
			#o  task-japanese                       # Japanese environment
			#o  unifont                             # font with a glyph for each visible Unicode Plane 0 character
			#   usbutils                            # Linux USB utilities
			#   util-linux-extra                    # interactive login tools
			#   vim-tiny                            # Vi IMproved - enhanced vi editor - compact version
			#   wamerican                           # American English dictionary words for /usr/share/dict
			    whiptail                            # Displays user-friendly dialog boxes from shell scripts
			#   wtmpdb                              # utility to display login/logout/reboot information
			#o  xfonts-unifont                      # PCF (bitmap) version of GNU Unifont
			    # --- nfs -----------------------------------------------------------------
			    nfs-common                          # NFS support files common to client and server
			#   nfs-kernel-server                   # support for NFS kernel server
			    # --- nbd -----------------------------------------------------------------
			    nbd-client                          # Network Block Device protocol - client
			#-  nbd-server                          # Network Block Device protocol - server
			#   nbdkit                              # toolkit for creating NBD servers
			#-  nbdkit-plugin-dev                   # development files for nbdkit
			#   nbdkit-plugin-guestfs               # libguestfs plugin for nbdkit
			#   nbdkit-plugin-libvirt               # libvirt plugin for nbdkit
			#-  nbdkit-plugin-lua                   # Lua plugin for nbdkit
			#   nbdkit-plugin-perl                  # Perl plugin for nbdkit
			#   nbdkit-plugin-python                # Python plugin for nbdkit
			#-  nbdkit-plugin-tcl                   # TCL plugin for nbdkit
			#-  nbdkit-plugin-vddk                  # vddk plugin for nbdkit
			    # --- iscsi ---------------------------------------------------------------
			#   istgt                               # iSCSI userspace target daemon for Unix-like operating systems
			    tgt                                 # Linux SCSI target user-space daemon and tools
			    lsscsi                              # list all SCSI devices (or hosts) currently on system
			    open-iscsi                          # iSCSI initiator tools
			#   targetcli-fb                        # Command shell for managing the Linux LIO kernel target
			    # -------------------------------------------------------------------------
_EOT_
	)"
	fnMake_mkosi_conf_create "${__TGET_PATH:?}" "${__DIST:-}" "${__RELS:-}" "${__REPO:-}" "${__SAND:-}" "${__PACK:-}"
}

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_ubuntu() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare       __DIST=""				# distribution
	declare       __RELS=""				# release
	declare       __REPO=""				# repository
	declare       __SAND=""				# sandbox
	declare       __PACK=""				# package

	# x 14.04 trusty
	# x 16.04 xenial
	# x 18.04 bionic
	# x 20.04 focal
	# o 22.04 jammy
	# o 24.04 noble
	# x 24.10 oracular
	# x 25.04 plucky
	# o 25.10 questing
	# o 26.04 resolute

	__DIST="Distribution=ubuntu"
	__RELS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			#Release=jammy
			#Release=noble
			#Release=questing
			#Release=resolute
_EOT_
	)"
	__REPO="Repositories=main,restricted,universe,multiverse"
	__SAND="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			SandboxTrees=repository/apt-conf:/etc/apt/apt.conf.d/apt-conf
			SandboxTrees=repository/%d-%r-backports.sources:/etc/apt/sources.list.d/%d-%r-backports.sources
_EOT_
	)"
	__PACK="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Packages=
			    # --- mkosi ---------------------------------------------------------------
			#-  mkosi                               # build Bespoke OS Images
			    debian-archive-keyring              # OpenPGP archive certificates of the Debian archive
			    debian-keyring                      # OpenPGP certificates of Debian Developers and Maintainers
			    dnf                                 # Dandified Yum package manager
			    dosfstools                          # utilities for making and checking MS-DOS FAT filesystems
			#o  gawk                                # GNU awk, a pattern scanning and processing language
			#o  grub-efi-amd64-bin                  # GRand Unified Bootloader, version 2 (EFI-AMD64 modules)
			#o  grub-pc-bin                         # GRand Unified Bootloader, version 2 (PC/BIOS modules)
			#o  grub2-common                        # GRand Unified Bootloader (common files for version 2)
			    mtools                              # Tools for manipulating MSDOS files
			    python3-pefile                      # Portable Executable (PE) parsing module for Python
			    squashfs-tools                      # Tool to create and append to squashfs filesystems
			    systemd-container                   # systemd container/nspawn tools
			    systemd-repart                      # Provides the systemd-repart and systemd-sbsign utilities
			#x  task-english                        #
			#x  task-japanese                       #
			#x  ubuntu-archive-keyring              #
			    ubuntu-keyring                      # GnuPG keys of the Ubuntu archive
			#o  xorriso                             # command line ISO-9660 and Rock Ridge manipulation tool
			#o  xxd                                 # tool to make (or reverse) a hex dump
			    zypper                              # command line software manager using libzypp
			    # --- kernel --------------------------------------------------------------
			    linux-image-generic                 # Generic Linux kernel image
			    # --- microcode -----------------------------------------------------------
			    amd64-microcode                     # Platform firmware and microcode for AMD CPUs and SoCs
			    intel-microcode                     # Processor microcode firmware for Intel CPUs
			    # --- grub ----------------------------------------------------------------
			    grub-efi-amd64-bin                  # GRand Unified Bootloader, version 2 (EFI-AMD64 modules)
			    grub-pc-bin                         # GRand Unified Bootloader, version 2 (PC/BIOS modules)
			    grub2-common                        # GRand Unified Bootloader (common files for version 2)
			    isolinux                            # collection of bootloaders (ISO 9660 bootloader)
			    syslinux-common                     # collection of bootloaders (common)
			    # --- development ---------------------------------------------------------
			    # --- dracut --------------------------------------------------------------
			    dracut                              # Initramfs generator using udev
			    dracut-network                      # dracut is an event driven initramfs infrastructure (network modules)
			    dracut-live                         # dracut is an event driven initramfs infrastructure (live image modules)
			    locales                             # GNU C Library: National Language (locale) data [support]
			    locales-all                         # GNU C Library: Precompiled locale data
			    xz-utils                            # XZ-format compression utilities
			    # --- dracut install modules ----------------------------------------------
			    # --- qemu ----------------------------------------------------------------
			    bridge-utils                        # Utilities for configuring the Linux Ethernet bridge
			    libvirt0                            # virtualization library
			    novnc                               # HTML5 VNC client - daemon and programs
			    ovmf                                # UEFI firmware for 64-bit x86 virtual machines
			    qemu-system-x86                     # QEMU full system emulation binaries
			    qemu-utils                          # QEMU utilities
			    virtiofsd                           # Virtio-fs vhost-user device daemon
			    websockify                          # WebSockets support for any application/server
			    # --- server (from the preconfiguration file) -----------------------------
			    apparmor                            # user-space parser utility for AppArmor
			    apparmor-utils                      # utilities for controlling AppArmor
			#   selinux-basics                      # SELinux basic support
			#   selinux-policy-default              # Strict and Targeted variants of the SELinux policy
			    auditd                              # User space tools for security auditing
			#   rpm                                 # package manager for RPM
			    sudo                                # Provide limited super user privileges to specific users
			    firewalld                           # dynamically managed firewall with support for network zones
			    traceroute                          # Traces the route taken by packets over an IPv4/IPv6 network
			    network-manager                     # network management framework (daemon and userspace tools)
			    bash-completion                     # programmable completion for the bash shell
			    build-essential                     # Informational list of build-essential packages
			    wget                                # retrieves files from the web
			    curl                                # command line tool for transferring data with URL syntax
			    vim                                 # Vi IMproved - enhanced vi editor
			    bc                                  # GNU bc arbitrary precision calculator language
			    rsync                               # fast, versatile, remote (and local) file-copying tool
			    eject                               # ejects CDs and operates CD-Changers under Linux
			    tree                                # displays an indented directory tree, in color
			    shellcheck                          # lint tool for shell scripts
			    xxd                                 # tool to make (or reverse) a hex dump
			    xorriso                             # command line ISO-9660 and Rock Ridge manipulation tool
			    gawk                                # GNU awk, a pattern scanning and processing language
			    jq                                  # lightweight and flexible command-line JSON processor
			    tasksel                             # tool for selecting tasks for installation on Debian systems
			    clamav                              # anti-virus utility for Unix - command-line interface
			    clamav-daemon                       # anti-virus utility for Unix - scanner daemon
			    openssh-server                      # secure shell (SSH) server, for secure access from remote machines
			    systemd-resolved                    # systemd DNS resolver
			    systemd-timesyncd                   # minimalistic service to synchronize local time with NTP servers
			    dnsmasq                             # Small caching DNS proxy and DHCP/TFTP server - system daemon
			    bind9-dnsutils                      # Clients provided with BIND 9
			    apache2                             # Apache HTTP Server
			    samba                               # SMB/CIFS file, print, and login server for Unix
			    smbclient                           # command-line SMB/CIFS clients for Unix
			    cifs-utils                          # Common Internet File System utilities
			    libnss-winbind                      # Samba nameservice integration plugins
			    lvm2                                # Linux Logical Volume Manager
			    open-vm-tools                       # Open VMware Tools for virtual machines hosted on VMware (CLI)
			    open-vm-tools-desktop               # Open VMware Tools for virtual machines hosted on VMware (GUI)
			    # --- desktop (from the preconfiguration file) ----------------------------
			#   ubuntu-desktop                      # Ubuntu desktop system
			#   ubuntu-desktop-minimal              # Ubuntu desktop minimal system
			#   ubuntu-gnome-desktop                # The Ubuntu desktop system (transitional package)
			#   language-pack-ja                    # translation updates for language Japanese
			#   language-pack-gnome-ja              # GNOME translation updates for language Japanese
			#   fonts-noto                          # metapackage to pull in all Noto fonts
			#   fonts-noto-cjk                      # "No Tofu" font families with large Unicode coverage (CJK regular and bold)
			#   fonts-noto-cjk-extra                # "No Tofu" font families with large Unicode coverage (CJK all weight)
			#   fonts-noto-extra                    # "No Tofu" font families with large Unicode coverage (extra)
			#   fonts-noto-color-emoji              # color emoji font from Google
			#   fonts-noto-mono                     # "No Tofu" monospaced font family with large Unicode coverage
			#   fonts-noto-ui-core                  # "No Tofu" font families with large Unicode coverage (UI core)
			#   fonts-noto-ui-extra                 # "No Tofu" font families with large Unicode coverage (UI extra)
			#   fonts-noto-unhinted                 # "No Tofu" font families with large Unicode coverage (unhinted)
			#   gnome-initial-setup                 # Initial GNOME system setup helper
			#   gnome-packagekit                    # Graphical distribution neutral package manager for GNOME
			#   gnome-tweaks                        # tool to adjust advanced configuration settings for GNOME
			#   gnome-shell-extensions              # Extensions to extend functionality of GNOME Shell
			#   gnome-shell-extension-manager       # Utility for managing GNOME Shell Extensions
			#   im-config                           # Input method configuration framework
			#   x11-common                          # X Window System (X.Org) infrastructure
			#   zenity                              # Display graphical dialog boxes from shell scripts
			#   fcitx5                              # Next generation of Fcitx Input Method Framework
			#   fcitx5-anthy                        # Fcitx5 wrapper for Anthy IM engine
			#   fcitx5-mozc                         # Mozc engine for fcitx5 - Client of the Mozc input method
			#   mozc-utils-gui                      # GUI utilities of the Mozc input method
			#   libreoffice-l10n-ja                 # office productivity suite -- Japanese language package
			#   libreoffice-help-ja                 # office productivity suite -- Japanese help
			#   firefox                             # Installs Firefox snap and provides some system integration
			#   firefox-locale-ja                   # Transitional package - firefox-locale-ja -> firefox snap
			#   thunderbird                         # Transitional package - thunderbird -> thunderbird snap
			#   thunderbird-locale-ja               # Transitional package - thunderbird-locale-ja -> thunderbird snap
			#   chromium-browser                    # Transitional package - chromium-browser -> chromium snap
			#   chromium-browser-l10n               # Transitional package - chromium-browser-l10n -> chromium snap
			#   chromium-chromedriver               # Transitional package - chromium-chromedriver -> chromium snap
			#   rhythmbox                           # music player and organizer for GNOME
			#   libavcodec-extra                    # FFmpeg library with extra codecs (metapackage)
			#   gstreamer1.0-libav                  # ffmpeg plugin for GStreamer
			#   pipewire-audio-client-libraries     # transitional package for pipewire-alsa and pipewire-jack
			#   vlc                                 # multimedia player and streamer
			#   vlc-l10n                            # translations for VLC
			#   vlc-plugin-pipewire                 # PipeWire audio plugins for VLC
			#   bluetooth                           # Bluetooth support (metapackage)
			#   bluez                               # Bluetooth tools and daemons
			#   bluez-firmware                      # Firmware for Bluetooth devices
			#   blueman                             # Graphical bluetooth manager
			#   printer-driver-escpr                # printer driver for Epson Inkjet that use ESC/P-R
			    # --- installation environment --------------------------------------------
			#   apt-listchanges                     # package change history notification tool
			#   apt-utils                           # package management related utility programs
			    attr                                # utilities for manipulating filesystem extended attributes
			    btrfs-progs                         # Checksumming Copy on Write Filesystem utilities
			    dbus                                # simple interprocess messaging system (system message bus)
			    dbus-broker                         # Linux D-Bus Message Broker
			#   debian-faq                          # Debian Frequently Asked Questions
			#   dhcpcd-base                         # DHCPv4 and DHCPv6 dual-stack client (binaries and exit hooks)
			#   distro-info-data                    # information about the distributions' releases (data files)
			#   doc-debian                          # Debian Project documentation and other documents
			    exfatprogs                          # exFAT file system utilities
			#   fbterm                              # fast framebuffer based terminal emulator for Linux
			    fdisk                               # collection of partitioning utilities
			    file                                # Recognize the type of data in a file using "magic" numbers
			#   fonts-unifont                       # OpenType version of GNU Unifont
			    fuse3                               # Filesystem in Userspace (3.x version)
			#   groff-base                          # GNU troff text-formatting system (base system components)
			#   grub-efi-amd64                      # GRand Unified Bootloader, version 2 (EFI-AMD64 version)
			#   ifupdown                            # high level tools to configure network interfaces
			#   inetutils-telnet                    # telnet client
			#   init                                # metapackage ensuring an init system is installed
			#x  initramfs-tools                     # generic modular initramfs generator (automation)
			    initramfs-tools-bin                 # generic modular initramfs generator (binary tools)
			#x  initramfs-tools-core                # generic modular initramfs generator (core tools)
			#x  installation-report                 #
			    iputils-ping                        # Tools to test the reachability of network hosts
			#   klibc-utils                         # small utilities built with klibc for early boot
			    less                                # pager program similar to more
			#   libc-l10n                           # 
			#   libcap2-bin                         # POSIX 1003.1e capabilities (utilities)
			#   libklibc                            # minimal libc subset for use with initramfs
			#   libpam-wtmpdb                       # wtmp database PAM module
			#   libpipeline1                        # Unix process pipeline manipulation library
			#   libuchardet0                        # universal charset detection library - shared library
			#   libx86-1                            # x86 real-mode library
			#o  linux-image-generic-6.17            # Generic Linux kernel image
			#o  locales                             # GNU C Library: National Language (locale) data [support]
			    login                               # system login tools
			#   lv                                  # Powerful Multilingual File Viewer
			#   man-db                              # tools for reading manual pages
			#   manpages-ja                         # Japanese version of the manual pages (for users)
			#   manpages-ja-dev                     # Japanese version of the manual pages (for developers)
			    nano                                # small, friendly text editor inspired by Pico
			#   netcat-traditional                  # TCP/IP swiss army knife
			#   nkf                                 # Network Kanji code conversion Filter
			    ntfs-3g                             # read/write NTFS driver for FUSE
			    openssl                             # Secure Sockets Layer toolkit - cryptographic utility
			    parted                              # disk partition manipulator
			#   psf-unifont                         # PSF (console) version of GNU Unifont with APL support
			#   python-apt-common                   # Python interface to libapt-pkg (locales)
			#   python3-apt                         # Python 3 interface to libapt-pkg
			#   python3-debconf                     # interact with debconf from Python 3
			#   python3-debian                      # Python 3 modules to work with Debian-related data formats
			#   python3-debianbts                   # Python interface to Debian's Bug Tracking System
			#   python3-reportbug                   # Python modules for interacting with bug tracking systems
			#   reportbug                           # reports bugs in the Debian distribution
			#o  task-japanese                       # Japanese environment
			#   unifont                             # font with a glyph for each visible Unicode Plane 0 character
			#   usbutils                            # Linux USB utilities
			#   util-linux-extra                    # interactive login tools
			#   vim-tiny                            # Vi IMproved - enhanced vi editor - compact version
			#   wamerican                           # American English dictionary words for /usr/share/dict
			    whiptail                            # Displays user-friendly dialog boxes from shell scripts
			#   wtmpdb                              # utility to display login/logout/reboot information
			#   xfonts-unifont                      # PCF (bitmap) version of GNU Unifont
			    # --- nfs -----------------------------------------------------------------
			    nfs-common                          # NFS support files common to client and server
			#   nfs-kernel-server                   # support for NFS kernel server
			    # --- nbd -----------------------------------------------------------------
			    nbd-client                          # Network Block Device protocol - client
			#-  nbd-server                          # Network Block Device protocol - server
			#   nbdkit                              # toolkit for creating NBD servers
			#-  nbdkit-plugin-dev                   # development files for nbdkit
			#   nbdkit-plugin-guestfs               # libguestfs plugin for nbdkit
			#   nbdkit-plugin-libvirt               # libvirt plugin for nbdkit
			#-  nbdkit-plugin-lua                   # Lua plugin for nbdkit
			#   nbdkit-plugin-perl                  # Perl plugin for nbdkit
			#   nbdkit-plugin-python                # Python plugin for nbdkit
			#-  nbdkit-plugin-tcl                   # TCL plugin for nbdkit
			#-  nbdkit-plugin-vddk                  # vddk plugin for nbdkit
			    # --- iscsi ---------------------------------------------------------------
			#   istgt                               # iSCSI userspace target daemon for Unix-like operating systems
			    tgt                                 # Linux SCSI target user-space daemon and tools
			    lsscsi                              # list all SCSI devices (or hosts) currently on system
			    open-iscsi                          # iSCSI initiator tools
			#   targetcli-fb                        # Command shell for managing the Linux LIO kernel target
			    # -------------------------------------------------------------------------
_EOT_
	)"
		fnMake_mkosi_conf_create "${__TGET_PATH:?}" "${__DIST:-}" "${__RELS:-}" "${__REPO:-}" "${__SAND:-}" "${__PACK:-}"
}

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_rhel_series() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare       __DIST=""				# distribution
	declare       __RELS=""				# release
	declare       __REPO=""				# repository
	declare       __SAND=""				# sandbox
	declare       __PACK=""				# package

	__DIST="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Distribution=rhel
			#Distribution=fedora
			#Distribution=centos
			#Distribution=alma
			#Distribution=rocky
_EOT_
	)"
	__RELS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			#Release=9
			#Release=10
			#Release=F43
			#Release=F44
_EOT_
	)"
	__REPO="Repositories=epel"
	__SAND="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
_EOT_
	)"
	__PACK="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Packages=
			    # --- mkosi ---------------------------------------------------------------
			#-  mkosi                               # 
			    systemd-container                   # Tools for containers and VMs
			    mtools                              # Programs for accessing MS-DOS disks without mounting the disks
			    python3-pefile                      # Python module for working with Portable Executable files
			    squashfs-tools                      # Utility for the creation of squashfs filesystems
			    debian-keyring                      # GnuPG archive keys of the Debian archive
			    ubu-keyring                         # GnuPG keys of the Ubuntu archive
			    apt                                 # Command-line package manager for Debian packages
			    # --- kernel --------------------------------------------------------------
			    kernel                              # The Linux kernel
			    # --- microcode -----------------------------------------------------------
			    amd-ucode-firmware                  # Microcode updates for AMD CPUs
			    microcode_ctl                       # CPU microcode updates for Intel x86 processors
			    # --- grub ----------------------------------------------------------------
			    grub2-pc-modules                    # Modules used to build custom grub images
			    grub2-efi-x64-modules               # Modules used to build custom grub.efi images
			    grub2-efi-x64-cdboot                # Files used to boot removeable media with EFI
			#   isolinux                            # 
			    syslinux                            # Simple kernel loader which boots from a FAT filesystem
			    # --- development ---------------------------------------------------------
			    # --- dracut --------------------------------------------------------------
			    dracut                              # Initramfs generator using udev
			    dracut-network                      # dracut modules to build a dracut initramfs with network support
			    dracut-live                         # dracut modules to build a dracut initramfs with live image capabilities
			    dbus-daemon                         # D-BUS message bus
			    glibc-langpack-en                   # Locale data for English
			    glibc-langpack-ja                   # Locale data for Japanese
			    langtable                           # Guessing reasonable defaults for locale, keyboard layout, territory, and language.
			    setxkbmap                           # X11 keymap client
			    systemd-boot-unsigned               # UEFI boot manager (unsigned version)
			    xkbcomp                             # XKB keymap compiler
			    xz                                  # LZMA compression utilities
			    # --- dracut install modules ----------------------------------------------
			    # --- qemu ----------------------------------------------------------------
			    virtiofsd                           # Virtio-fs vhost-user device daemon (Rust version)
			    virt-v2v                            # Convert a virtual machine to run on KVM
			    # --- server (from the preconfiguration file) -----------------------------
			    @core                               # Minimal host installation
			    @standard                           # The standard installation of Red Hat Enterprise Linux.
			    epel-release                        # Extra Packages for Enterprise Linux repository configuration
			    selinux-policy-targeted             # SELinux targeted policy
			    rpm                                 # The RPM package management system
			    sudo                                # Allows restricted root access for specified users
			    firewalld                           # A firewall daemon with D-Bus interface providing a dynamic firewall
			    traceroute                          # Traces the route taken by packets over an IPv4/IPv6 network
			    NetworkManager                      # Network connection manager and user applications
			    bash-completion                     # Programmable completion for Bash
			    wget                                # A utility for retrieving files using the HTTP or FTP protocols
			    curl                                # A utility for getting files from remote servers (FTP, HTTP, and others)
			    vim-common                          # The common files needed by any version of the VIM editor
			    vim-data                            # Shared data for Vi and Vim
			    vim-enhanced                        # A version of the VIM editor which includes recent enhancements
			    vim-filesystem                      # VIM filesystem layout
			    vim-minimal                         # A minimal version of the VIM editor
			    bc                                  # GNU's bc (a numeric processing language) and dc (a calculator)
			    rsync                               # A program for synchronizing files over a network
			    tree                                # File system tree viewer
			    ShellCheck                          # Shell script analysis tool
			    xxd                                 # A hex dump utility
			    xorriso                             # ISO-9660 and Rock Ridge image manipulation tool
			    gawk                                # The GNU version of the AWK text processing utility
			    jq                                  # Command-line JSON processor
			    clamav                              # End-user tools for the Clam Antivirus scanner
			    openssh-server                      # An open source SSH server daemon
			    systemd-resolved                    # Network Name Resolution manager
			    systemd-timesyncd                   # System daemon to synchronize local system clock with NTP server
			    dnsmasq                             # A lightweight DHCP/caching DNS server
			    tftp-server                         # The server for the Trivial File Transfer Protocol (TFTP)
			    bind-utils                          # Utilities for querying DNS name servers
			    httpd                               # Apache HTTP Server
			    samba                               # Server and Client software to interoperate with Windows machines
			    samba-client                        # Samba client programs
			    cifs-utils                          # Utilities for mounting and managing CIFS mounts
			    samba-winbind                       # Samba winbind
			    lvm2                                # Userland logical volume management tools
			    open-vm-tools                       # Open Virtual Machine Tools for virtual machines hosted on VMware
			    open-vm-tools-desktop               # User experience components for Open Virtual Machine Tools
			    fuse                                # File System in Userspace (FUSE) v2 utilities
			    fuse3                               # File System in Userspace (FUSE) v3 utilities
			    fuse3-libs                          # File System in Userspace (FUSE) v3 libraries
			    # --- desktop (from the preconfiguration file) ----------------------------
			#   @gnome-desktop                      # Desktop environment and general purpose apps.
			#   adwaita-cursor-theme                # Adwaita cursor theme
			#   adwaita-icon-theme                  # Adwaita icon theme
			#   google-noto-fonts-common            # Common files for Noto fonts
			#   google-noto-sans-cjk-vf-fonts       # Google Noto Sans CJK Variable Fonts
			#   google-noto-sans-mono-cjk-vf-fonts  # Google Noto Sans Mono CJK Variable Fonts
			#   google-noto-sans-vf-fonts           # Noto Sans variable font
			#   google-noto-serif-cjk-vf-fonts      # Google Noto Serif CJK Variable Fonts
			#   google-noto-color-emoji-fonts       # Google "Noto Color Emoji" colored emoji font
			#   google-noto-emoji-fonts             # Google “Noto Emoji" Black-and-White emoji font
			#   gnome-initial-setup                 # Bootstrapping your OS
			#   firefox                             # Mozilla Firefox Web browser
			#   thunderbird                         # Mozilla Thunderbird mail/newsgroup client
			#   chromium                            # A WebKit (Blink) powered web browser that Google doesn't want you to use
			#   audacious                           # Advanced audio player
			#   audacious-plugins-ffaudio           # FFmpeg input plugin for Audacious
			#   alsa-firmware                       # Firmware for several ALSA-supported sound cards
			#   libavcodec-free                     # FFmpeg codec library
			#   vlc                                 # The cross-platform open-source multimedia framework, player and server
			#   vlc-plugin-pipewire                 # Pipewire plugin for VLC media player
			#   bluez                               # Bluetooth utilities
			#   realtek-firmware                    # Firmware for Realtek WiFi/Bluetooth adapters
			#   gnome-bluetooth                     # Bluetooth graphical utilities
			#   gutenprint-cups                     # CUPS drivers for Canon, Epson, HP and compatible printers
			    # --- installation environment --------------------------------------------
			    attr                                # Utilities for managing filesystem extended attributes
			    btrfs-progs                         # Userspace programs for btrfs
			    dbus                                # D-BUS message bus
			    dbus-broker                         # Linux D-Bus Message Broker
			#   device-mapper-multipath             # Tools to manage multipath devices using device-mapper
			    exfatprogs                          # Userspace utilities for exFAT filesystems
			#   fdisk                               #
			    file                                # Utility for determining file types
			    fuse3                               # File System in Userspace (FUSE) v3 utilities
			#   initramfs-tools-bin                 #
			#   iputils-ping                        #
			#   iscsi-initiator-utils               # iSCSI daemon and utility programs
			    less                                # A text file browser similar to more, but better
			#   login                               #
			    nano                                # A small text editor
			#   ntfs-3g                             # Linux NTFS userspace driver
			#   ntfs-3g-libs                        # Runtime libraries for ntfs-3g
			    ntfsprogs                           # NTFS filesystem libraries and utilities
			#   nvme-cli                            # NVMe management command line interface
			    openssl                             # Utilities from the general purpose cryptography library with TLS implementation
			    parted                              # 
			#   whiptail                            # not found
			    # --- nfs -----------------------------------------------------------------
			#   nfs-common                          # 
			#   nfs-kernel-server                   # 
			    nfs-utils                           # NFS utilities and supporting clients and daemons for the kernel NFS server
			    # --- nbd -----------------------------------------------------------------
			    nbd                                 # Network Block Device user-space tools (TCP version)
			#   nbd-client                          # 
			#   nbd-server                          # 
			#   nbdfuse                             # FUSE support for libnbd
			#   nbdkit                              # NBD server
			#   nbdkit-bash-completion              # Bash tab-completion for nbdkit
			#   nbdkit-basic-filters                # Basic filters for nbdkit
			#   nbdkit-basic-plugins                # Basic plugins for nbdkit
			#   nbdkit-curl-plugin                  # HTTP/FTP (cURL) plugin for nbdkit
			#   nbdkit-devel                        # Development files and documentation for nbdkit
			#   nbdkit-example-plugins              # Example plugins for nbdkit
			#   nbdkit-linuxdisk-plugin             # Virtual Linux disk plugin for nbdkit
			#   nbdkit-nbd-plugin                   # NBD proxy / forward plugin for nbdkit
			#   nbdkit-python-plugin                # Python 3 plugin for nbdkit
			#   nbdkit-selinux                      # nbdkit SELinux policy
			#   nbdkit-server                       # The nbdkit server
			#   nbdkit-srpm-macros                  # RPM Provides rules for nbdkit plugins and filters
			#   nbdkit-ssh-plugin                   # SSH plugin for nbdkit
			#   nbdkit-tar-filter                   # Tar archive filter for nbdkit
			#   nbdkit-tmpdisk-plugin               # Remote temporary filesystem disk plugin for nbdkit
			#   nbdkit-vddk-plugin                  # VMware VDDK plugin for nbdkit
			#   nbdkit-xz-filter                    # XZ and lzip filters for nbdkit
			    # --- iscsi ---------------------------------------------------------------
			#   istgt                               # 
			#   tgt                                 # 
			    lsscsi                              # List SCSI devices (or hosts) and associated information
			#   open-iscsi                          # 
			    iscsi-initiator-utils               # iSCSI daemon and utility programs
			#   targetcli-fb                        # 
			    # -------------------------------------------------------------------------
_EOT_
	)"
		fnMake_mkosi_conf_create "${__TGET_PATH:?}" "${__DIST:-}" "${__RELS:-}" "${__REPO:-}" "${__SAND:-}" "${__PACK:-}"
}

# -----------------------------------------------------------------------------
function fnMake_mkosi_conf_opensuse() {
	declare -r    __TGET_PATH="${1:?}"	# target file
	declare       __DIST=""				# distribution
	declare       __RELS=""				# release
	declare       __REPO=""				# repository
	declare       __SAND=""				# sandbox
	declare       __PACK=""				# package

	__DIST="Distribution=opensuse"
	__RELS="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			#Release=15.6
			#Release=16.0
			#Release=16.1
			#Release=tumbleweed
_EOT_
	)"
	__REPO="Repositories=repo-backports-update,repo-sle-update"
	__SAND="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			SandboxTrees=repository/%d-%r-backports.repo:/etc/zypp/repos.d/%d-%r-backports.repo
			SandboxTrees=repository/%d-%r-sle.repo:/etc/zypp/repos.d/%d-%r-sle.repo
_EOT_
	)"
	__PACK="$(
		cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' || true
			Packages=
			    # --- mkosi ---------------------------------------------------------------
			#-  mkosi                               # Build bespoke OS Images
			    systemd-container                   # Systemd tools for container management
			    mtools                              # Tools to access MS-DOS filesystems without kernel drivers
			    # --- kernel --------------------------------------------------------------
			    kernel-default                      # The Standard Kernel
			    kernel-default-extra                # The Standard Kernel - Unsupported kernel modules
			    kernel-default-optional             # The Standard Kernel - Optional kernel modules
			    kernel-firmware-all                 # Compatibility metapackage for kernel firmware files
			#   compat-usrmerge-tools               # UsrMerge tools
			    # --- microcode -----------------------------------------------------------
			    ucode-amd                           # Kernel firmware files for Microcode updates for AMD CPUs
			    ucode-intel                         # Microcode Updates for Intel x86/x86-64 CPUs
			    # --- grub ----------------------------------------------------------------
			    grub2-i386-pc                       # Bootloader with support for Linux, Multiboot and more
			    grub2-x86_64-efi                    # Bootloader with support for Linux, Multiboot and more
			#x  isolinux                            #
			    syslinux                            # Boot Loader for Linux
			    # --- development ---------------------------------------------------------
			    # --- dracut --------------------------------------------------------------
			    dracut                              # Event driven initramfs infrastructure
			#   dracut-extra                        # Dracut modules usually not required for normal operation
			#   dracut-fips                         # Dracut modules to build a dracut initramfs with an integrity check
			#   dracut-ima                          # Dracut modules to build a dracut initramfs with IMA
			#   dracut-kiwi-lib                     # KIWI - Dracut kiwi Library
			#   dracut-kiwi-live                    # KIWI - Dracut module for iso(live) image type
			#   dracut-kiwi-oem-dump                # KIWI - Dracut module for oem(install) image type
			#   dracut-kiwi-oem-repart              # KIWI - Dracut module for oem(repart) image type
			#   dracut-kiwi-overlay                 # KIWI - Dracut module for vmx(+overlay) image type
			#   dracut-kiwi-verity                  # KIWI - Dracut module for disk with embedded verity metadata
			#   dracut-pcr-signature                # Dracut module to import PCR signatures
			#   dracut-sshd                         # Provide SSH access to initramfs early user space
			#   dracut-tools                        # Tools to build a local initramfs
			#   dracut-transactional-update         # Dracut module for supporting transactional updates
			#   xz                                  # A Program for Compressing Files with the Lempel–Ziv–Markov algorithm
			    # --- dracut install modules ----------------------------------------------
			    # --- qemu ----------------------------------------------------------------
			    # --- server (from the preconfiguration file) -----------------------------
			#   patterns-base-apparmor              # AppArmor
			    patterns-base-base                  # Base System
			    patterns-base-basesystem            # Base System (alias pattern for base)
			#   patterns-base-basic_desktop         # A basic desktop (based on IceWM)
			#   patterns-base-bootloader            # Bootloader
			#   patterns-base-console               # Console Tools
			#   patterns-base-documentation         # Help and Support Documentation
			    patterns-base-enhanced_base         # Enhanced Base System
			#   patterns-base-fips                  # FIPS 140-3 specific packages
			    patterns-base-kdump                 # Kernel dump tooling
			    patterns-base-minimal_base          # Minimal Appliance Base
			    patterns-base-selinux               # SELinux Support
			#   patterns-base-sw_management         # Software Management
			#   patterns-base-x11                   # X Window System
			#   patterns-base-x11_enhanced          # X Window System
			    patterns-glibc-hwcaps-x86_64_v3     # Install x86-64-v3 optimized libraries
			    sudo                                # Execute some commands as root
			    firewalld                           # A firewall daemon with D-Bus interface providing a dynamic firewall
			    firewalld-lang                      # Translations for package firewalld
			    traceroute                          # Packet route path tracing utility
			    NetworkManager                      # Standard Linux network configuration tool suite
			    NetworkManager-lang                 # Translations for package NetworkManager
			    bash-completion                     # Programmable Completion for Bash
			    wget                                # A Tool for Mirroring FTP and HTTP Servers
			    wget-lang                           # Translations for package wget
			    curl                                # A Tool for Transferring Data from URLs
			    vim                                 # Vi IMproved
			    bc                                  # GNU Command Line Calculatorr
			    rsync                               # Versatile tool for fast incremental file transfer
			    tree                                # File listing as a tree
			    ShellCheck                          # Shell script analysis tool
			    xorriso                             # ISO 9660 Rock Ridge Filesystem Manipulator
			    gawk                                # Domain-specific language for text processing
			    jq                                  # A lightweight and flexible command-line JSON processor
			    clamav                              # Antivirus Toolkit
			    openssh-server                      # SSH (Secure Shell) server
			    systemd-lang                        # Translations for package systemd
			#x  systemd-network                     #
			    systemd-resolved                    # Systemd Network Name Resolution Manager
			    dnsmasq                             # DNS Forwarder and DHCP Server
			    tftp                                # Trivial File Transfer Protocol (TFTP)
			    bind-utils                          # Libraries for "bind" and utilities to query and test DNS
			    apache2                             # The Apache HTTPD Server
			    samba                               # A SMB/CIFS File, Print, and Authentication Server
			    samba-client                        # Samba Client Utilities
			    cifs-utils                          # Utilities for doing and managing mounts of the Linux CIFS filesystem
			    samba-winbind                       # Winbind Daemon and Tool
			    lvm2                                # Logical Volume Manager Tools
			    open-vm-tools                       # Open Virtual Machine Tools
			    open-vm-tools-desktop               # User experience components for Open Virtual Machine Tools
			    fuse                                # Reference implementation of the "Filesystem in Userspace"
			    glibc-i18ndata                      # Database Sources for 'locale'
			    glibc-locale                        # Locale Data for Localized Programs
			    less                                # Text File Browser and Pager Similar to more
			    which                               # Displays where a particular program in your path is located
			    zypper                              # Command line software manager using libzypp
			    # --- desktop (from the preconfiguration file) ----------------------------
			#   patterns-fonts-fonts                # Fonts
			#   patterns-fonts-fonts_opt            # Fonts
			#o  NetworkManager                      # Standard Linux network configuration tool suite
			#-  NetworkManager-applet-openconnect   # NetworkManager VPN support for OpenConnect
			#-  NetworkManager-applet-openvpn       # NetworkManager VPN support for OpenVPN
			#-  NetworkManager-applet-pptp          # NetworkManager VPN support for PPTP
			#-  NetworkManager-applet-vpnc          # NetworkManager VPN Support for vpnc
			#   adobe-sourcecodepro-fonts           # A set of OpenType fonts designed for coding environments
			#   adwaita-fonts                       # Adwaita Fonts
			#   at-spi2-core                        # Assistive Technology Service Provider Interface - D-Bus based implementation
			#   dconf-editor                        # Graphical editor for the dconf key-based configuration system
			#   desktop-data-openSUSE               # Shared Desktop Files for openSUSE
			#   desktop-file-utils                  # Utilities for Manipulating Desktop Files
			#   distribution-logos-openSUSE-icons   # Icons with distribution logos
			#   evolution                           # The Integrated GNOME Mail, Calendar, and Address Book Suite
			#   evolution-ews                       # Exchange Connector for Evolution, compatible with Exchange 2007 and later
			#   gdm                                 # The GNOME Display Manager
			#   gnome-backgrounds                   # GNOME Backgrounds
			#   gnome-bluetooth                     # GNOME Bluetooth graphical utilities
			#   gnome-calculator                    # A GNOME Calculator Application
			#   gnome-characters                    # Character Map
			#   gnome-clocks                        # Clock application designed for GNOME 3
			#   gnome-console                       # A minimal terminal for GNOME
			#   gnome-contacts                      # Contacts Manager for GNOME
			#   gnome-control-center-color          # Configuration panel for color management
			#   gnome-control-center-goa            # Configuration panel for online accounts
			#   gnome-disk-utility                  # Disks application for dealing with storage devices
			#   gnome-extensions                    # Extensions app for GNOME Shell
			#   gnome-initial-setup                 # GNOME Initial Setup Assistant
			#   gnome-keyring-pam                   # GNOME Keyring - PAM module
			#   gnome-remote-desktop                # GNOME Remote Desktop screen sharing service
			#   gnome-session                       # Session Tools for the GNOME Desktop
			#   gnome-software                      # GNOME Software Store
			#   gnome-system-monitor                # A process monitor for the GNOME desktop
			#   gnome-terminal-lang                 # Translations for package gnome-terminal
			#   gnome-text-editor                   # GNOME Text Editor
			#   gnome-tweaks                        # A tool to customize advanced GNOME 3 options
			#   gnome-user-docs                     # GNOME Desktop Documentation
			#   gnome-user-share                    # GNOME user file sharing
			#   google-noto-sans-cjk-fonts          # Noto Sans CJK Font
			#   google-noto-sans-jp-mono-fonts      # Noto Sans Japanese Font - Monospace
			#   google-noto-sans-mono-fonts         # Noto Mono Sans Serif Font
			#   gpgme                               # Programmatic library interface to GnuPG
			#   gsettings-backend-dconf             # GSettings integration of the dconf key-based configuration system
			#   gutenprint                          # Printer drivers for CUPS from the Gutenprint project
			#   libgnomesu                          # GNOME su Library
			#   malcontent-control                  # Parental Control Application
			#   nautilus                            # File Manager for the GNOME Desktop
			#   nautilus-sendto                     # Integrate Nautilus and E-Mail clients
			#   nautilus-share                      # Nautilus plugin for sharing directories over SMB
			#   orca                                # Screen reader for GNOME
			#   pinentry-gnome3                     # Simple PIN or Passphrase Entry Dialog for GNOME
			#   pipewire                            # A Multimedia Framework designed to be an audio and video server and more
			#   pipewire-pulseaudio                 # PipeWire PulseAudio implementation
			#-  polari                              # An IRC Client for GNOME
			#   polkit-default-privs                # SUSE PolicyKit default permissions
			#   python313-speechd                   # Device independent layer for speech synthesis - Python Bindings
			#   remmina                             # Versatile Remote Desktop Client
			#   seahorse                            # GNOME interface for gnupg
			#   speech-dispatcher                   # Device independent layer for speech synthesis
			#   tinysparql                          # Object database, tag/metadata database, search tool and indexer
			#-  transmission-gtk                    # GTK client for the "transmission" BitTorrent client
			#   xdg-user-dirs-gtk                   # Xdg-user-dir support for Gnome and Gtk+ applications
			#   yelp                                # Help Browser for the GNOME Desktop
			#   zenity                              # GNOME Command Line Dialog Utility
			#   MozillaFirefox                      # Mozilla Firefox Web Browser
			#   MozillaThunderbird                  # An integrated email, news feeds, chat, and newsgroups client
			#   adwaita-icon-theme                  # GNOME Icon Theme
			#   bluez                               # Bluetooth Stack for Linux
			#   chromium                            # Google's open source browser project
			#   gnome-initial-setup-lang            # Translations for package gnome-initial-setup
			#   gnome-shell                         # GNOME Shell
			#   gnome-terminal                      # GNOME Terminal
			#   google-noto-sans-jp-fonts           # Noto Sans Japanese Font
			#   google-noto-serif-jp-fonts          # Noto Serif Japanese Font
			#   gstreamer-plugins-libav             # A ffmpeg/libav plugin for GStreamer
			#   rhythmbox                           # GNOME Music Management Application
			    # --- installation environment --------------------------------------------
			    attr                                # Commands for Manipulating Extended Attributes
			    autoyast2                           # YaST2 - Automated Installation
			    btrfsprogs                          # Utilities for the Btrfs filesystem
			    dbus-1                              # D-Bus Message Bus System
			    dbus-broker                         # XDG message bus implementation
			    exfatprogs                          # Utilities for exFAT file system maintenance
			#   fdisk                               #
			    file                                # A Tool to Determine File Types
			    fuse3                               # Reference implementation of the "Filesystem in Userspace"
			#   glibc                               # Standard Shared Libraries (from the GNU C Library)
			#   glibc-i18ndata                      # Database Sources for 'locale'
			#   glibc-lang                          # Translations for package glibc
			#   glibc-locale                        # Locale Data for Localized Programs
			#   initramfs-tools-bin                 #
			#   iputils-ping                        #
			#   iscsi-initiator-utils               #
			    less                                # Text File Browser and Pager Similar to more
			#   libcap2                             # Library for Capabilities (linux-privs) Support
			#   libsemanage2                        # SELinux policy management library
			#   login                               #
			#   multipath-tools                     # Tools to Manage Multipathed Devices with the device-mapper
			    nano                                # Pico editor clone with enhancements
			    nano-lang                           # Translations for package nano
			#   notification-daemon                 # Notification Daemon
			#   notification-daemon-lang            # Translations for package notification-daemon
			    ntfs-3g                             # NTFS Support in Userspace
			#   ntfs-3g-libs                        #
			    ntfsprogs                           # NTFS Utilities
			#   nvme-cli                            # NVM Express user space tools
			    openssl                             # Secure Sockets and Transport Layer Security
			#   ovpn-dco-kmp-default                # OpenVPN Data Channel Offload in the Linux kernel
			    parted                              # GNU partitioner
			    parted-lang                         # Translations for package parted
			#   policycoreutils                     # SELinux policy core utilities
			#   policycoreutils-lang                # Translations for package policycoreutils
			#   selinux-policy                      # SELinux policy configuration
			#   selinux-policy-targeted             # SELinux targeted base policy
			    sudo-policy-wheel-auth-self         # Users in the wheel group can authenticate as admin
			#   systemd-boot                        # A simple UEFI boot manager
			#   util-linux                          # A collection of basic system utilities (core part)
			#   util-linux-lang                     # Translations for package util-linux
			#   util-linux-systemd                  # A collection of basic system utilities (systemd dependent part)
			#   whiptail                            #
			    zypper                              # Command line software manager using libzypp
			    # --- nfs -----------------------------------------------------------------
			#   nfs-common                          #
			    nfs-client                          # Support Utilities for NFS
			#   nfs-kernel-server                   # Support Utilities for Kernel nfsd
			    # --- nbd -----------------------------------------------------------------
			    nbd                                 # Network Block Device Server and Client Utilities
			#   nbd-client                          #
			#   nbd-server                          #
			#   nbdfuse                             # FUSE support for libnbd
			#   nbdkit                              # Network Block Device server
			#   nbdkit-bash-completion              # Bash tab-completion for nbdkit
			#   nbdkit-basic-filters                # Basic filters for nbdkit
			#   nbdkit-basic-plugins                # Basic plugins for nbdkit
			#   nbdkit-bzip2-filter                 # BZip2 filter for nbdkit
			#   nbdkit-curl-plugin                  # HTTP/FTP (cURL) plugin for nbdkit
			#   nbdkit-devel                        # Development files and documentation for nbdkit
			#   nbdkit-example-plugins              # Example plugins for nbdkit
			#   nbdkit-gcs-plugin                   # Gooogle Cloud Storage plugin nbdkit
			#   nbdkit-linuxdisk-plugin             # Virtual Linux disk plugin for nbdkit
			#   nbdkit-nbd-plugin                   # NBD proxy / forward plugin for nbdkit
			#   nbdkit-python-plugin                # Python 3 plugin for nbdkit
			#   nbdkit-server                       # Network Block Device server
			#   nbdkit-ssh-plugin                   # SSH plugin for nbdkit
			#   nbdkit-stats-filter                 # Statistics filter for nbdkit
			#   nbdkit-tar-filter                   # Tar archive filter for nbdkit
			#   nbdkit-tmpdisk-plugin               # Remote temporary filesystem disk plugin for nbdkit
			#   nbdkit-vddk-plugin                  # VMware VDDK plugin for nbdkit
			#   nbdkit-xz-filter                    # XZ and lzip filters for nbdkit
			    # --- iscsi ---------------------------------------------------------------
			#   istgt                               #
			#   tgt                                 #
			    lsscsi                              # List all SCSI devices in the system
			    open-iscsi                          # Linux iSCSI Software Initiator
			    targetcli-fb-common                 # Common targetcli-fb subpackage for either flavor of Python
			    # -------------------------------------------------------------------------
			#   patterns-base-32bit                     # 32-Bit Runtime Environment
			#   patterns-base-apparmor                  # AppArmor
			#   patterns-base-apparmor-32bit            # AppArmor
			#   patterns-base-base                      # Base System
			#   patterns-base-base-32bit                # Base System
			#   patterns-base-basesystem                # Base System (alias pattern for base)
			#   patterns-base-basic_desktop             # A basic desktop (based on IceWM)
			#   patterns-base-bootloader                # Bootloader
			#   patterns-base-console                   # Console Tools
			#   patterns-base-documentation             # Help and Support Documentation
			#   patterns-base-enhanced_base             # Enhanced Base System
			#   patterns-base-enhanced_base-32bit       # Enhanced Base System
			#   patterns-base-fips                      # FIPS 140-3 specific packages
			#   patterns-base-kdump                     # Kernel dump tooling
			#   patterns-base-minimal_base              # Minimal Appliance Base
			#   patterns-base-minimal_base-32bit        # Minimal Appliance Base
			#   patterns-base-selinux                   # SELinux Support
			#   patterns-base-sw_management             # Software Management
			#   patterns-base-sw_management-32bit       # Software Management
			#   patterns-base-x11                       # X Window System
			#   patterns-base-x11-32bit                 # X Window System
			#   patterns-base-x11_enhanced              # X Window System
			#   patterns-base-x11_enhanced-32bit        # X Window System
			#   patterns-budgie-budgie                  # Budgie Desktop Environment
			#   patterns-budgie-budgie_applets          # Applets for Budgie Desktop Environment
			#   patterns-cinnamon-cinnamon              # Cinnamon Desktop Environment
			#   patterns-cinnamon-cinnamon_basis        # Cinnamon Base System
			#   patterns-cockpit                        # Pattern for Cockpit, a web based remote system management inte->
			#   patterns-cockpit-client                 # Cockpit Client
			#   patterns-container-runtime_docker       # SUSE Docker runtime support
			#   patterns-container-runtime_podman       # SUSE podman runtime pattern
			#   patterns-desktop-books                  # Documentation
			#   patterns-desktop-imaging                # Graphics
			#   patterns-desktop-mobile                 # Mobile
			#   patterns-desktop-multimedia             # Multimedia
			#   patterns-desktop-technical_writing      # Technical Writing
			#   patterns-devel-base-devel_basis         # Base Development
			#   patterns-devel-base-devel_basis-32bit   # Base Development
			#   patterns-devel-base-devel_kernel        # Linux Kernel Development
			#   patterns-devel-base-devel_kernel-32bit  # Linux Kernel Development
			#   patterns-devel-base-devel_rpm_build     # RPM Build Environment
			#   patterns-devel-base-devel_web           # Web Development
			#   patterns-devel-C-C++-devel_C_C++        # C/C++ Development
			#   patterns-devel-vulkan-devel_vulkan      # Vulkan Development
			#   patterns-enlightenment-enlightenment    # Enlightenment
			#   patterns-fonts-fonts                    # Fonts
			#   patterns-fonts-fonts_opt                # Fonts
			#   patterns-games-games                    # Games
			#   patterns-glibc-hwcaps-x86_64_v3         # Install x86-64-v3 optimized libraries
			#   patterns-gnome-devel_gnome              # GNOME Development
			#   patterns-gnome-gnome                    # GNOME Desktop Environment (Wayland)
			#   patterns-gnome-gnome_basic              # GNOME Desktop Environment (Basic)
			#   patterns-gnome-gnome_basis              # GNOME Base System
			#   patterns-gnome-gnome_games              # GNOME Games
			#   patterns-gnome-gnome_ide                # GNOME Integrated Development Environment
			#   patterns-gnome-gnome_imaging            # GNOME Graphics
			#   patterns-gnome-gnome_internet           # GNOME Internet
			#   patterns-gnome-gnome_multimedia         # GNOME Multimedia
			#   patterns-gnome-gnome_office             # GNOME Office
			#   patterns-gnome-gnome_utilities          # GNOME Utilities
			#   patterns-gnome-gnome_x11                # GNOME Desktop Environment (X11)
			#   patterns-gnome-sw_management_gnome      # Package Management - Graphical Tools for GNOME
			#   patterns-kde-devel_kde_frameworks       # KDE Frameworks and Plasma Development
			#   patterns-kde-devel_kde_frameworks6      # KDE Frameworks 6 and Plasma 6 Development
			#   patterns-kde-devel_qt5                  # Qt 5 Development
			#   patterns-kde-devel_qt6                  # Qt 6 Development
			#   patterns-kde-kde                        # KDE Applications and Plasma Desktop
			#   patterns-kde-kde_edutainment            # KDE Education
			#   patterns-kde-kde_games                  # KDE Games
			#   patterns-kde-kde_ide                    # KDE Integrated Development Environment
			#   patterns-kde-kde_imaging                # KDE Graphics
			#   patterns-kde-kde_internet               # KDE Internet
			#   patterns-kde-kde_multimedia             # KDE Multimedia
			#   patterns-kde-kde_office                 # KDE Office
			#   patterns-kde-kde_pim                    # KDE PIM Suite
			#   patterns-kde-kde_plasma                 # KDE Plasma 6 Desktop Base
			#   patterns-kde-kde_utilities              # KDE Utilities
			#   patterns-kde-kde_utilities_opt          # KDE Utilities
			#   patterns-lxqt-lxqt                      # LXQt Desktop Environment
			#   patterns-mate-mate                      # MATE Desktop Environment
			#   patterns-mate-mate_admin                # MATE Administration Tools
			#   patterns-mate-mate_basis                # MATE Base System
			#   patterns-mate-mate_internet             # MATE Internet
			#   patterns-mate-mate_laptop               # MATE Laptop
			#   patterns-mate-mate_office               # MATE Office
			#   patterns-mate-mate_office_opt           # MATE Office
			#   patterns-mate-mate_utilities            # MATE Utilities
			#   patterns-office-office                  # Office Software
			#   patterns-openSUSEway                    # The openSUSEway desktop environment pattern
			#   patterns-rpm-macros                     # RPM macros for building of patterns modules
			#   patterns-server-dhcp_dns_server         # DHCP and DNS Server
			#   patterns-server-dhcp_dns_server-32bit   # DHCP and DNS Server
			#   patterns-server-directory_server        # Directory Server (LDAP)
			#   patterns-server-directory_server-32bit  # Directory Server (LDAP)
			#   patterns-server-file_server             # File Server
			#   patterns-server-file_server-32bit       # File Server
			#   patterns-server-gateway_server          # Internet Gateway
			#   patterns-server-gateway_server-32bit    # Internet Gateway
			#   patterns-server-kvm_server              # KVM Host Server
			#   patterns-server-kvm_tools               # KVM Virtualization Host and tools
			#   patterns-server-lamp_server             # Web and LAMP Server
			#   patterns-server-lamp_server-32bit       # Web and LAMP Server
			#   patterns-server-mail_server             # Mail Server
			#   patterns-server-mail_server-32bit       # Mail and News Server
			#   patterns-server-oracle_server           # Oracle Server Base
			#   patterns-server-printing                # Print Server
			#   patterns-server-printing-32bit          # Print Server
			#   patterns-sway-sway                      # Sway Tiling Wayland Compositor and related tools
			#   patterns-wsl-base                       # Base WSL packages
			#   patterns-wsl-gui                        # WSL GUI packages
			#   patterns-wsl-systemd                    # WSL systemd setup
			#   patterns-wsl-tmpfiles                   # Setup WSLg tmpfiles.d configuration
			#   patterns-xfce-xfce                      # XFCE Desktop Environment
			#   patterns-xfce-xfce_basis                # XFCE Base System
			#   patterns-xfce-xfce_basis_wayland        # XFCE Base System (Experimental Wayland Variant)
			#   patterns-xfce-xfce_extra                # XFCE Extra Applications
			#   patterns-xfce-xfce_extra_wayland        # XFCE Extra Applications (Experimental Wayland Variant)
			#   patterns-xfce-xfce_laptop               # XFCE Laptop
			#   patterns-xfce-xfce_laptop_wayland       # XFCE Laptop (Experimental Wayland Variant)
			#   patterns-xfce-xfce_wayland              # XFCE Desktop Environment (Experimental Wayland Variant)
			    # -------------------------------------------------------------------------
_EOT_
	)"
		fnMake_mkosi_conf_create "${__TGET_PATH:?}" "${__DIST:-}" "${__RELS:-}" "${__REPO:-}" "${__SAND:-}" "${__PACK:-}"
}

# -----------------------------------------------------------------------------
fnMake_mkosi_conf_template    "./mkosi-template.conf"
fnMake_mkosi_conf_debian      "./mkosi-debian.conf"
fnMake_mkosi_conf_ubuntu      "./mkosi-ubuntu.conf"
fnMake_mkosi_conf_rhel_series "./mkosi-rhel_series.conf"
fnMake_mkosi_conf_opensuse    "./mkosi-opensuse.conf"

# -----------------------------------------------------------------------------
#for P in \
#do
#  if ! LANG=C dnf search "$P" 2> /dev/null | grep -E "^$P\."; then
#    echo "$P: not found"
#  fi
#done
#
#LANG=C zypper info --requires
#LANG=C zypper se
#
#for P in \
#do
#  if ! LANG=C zypper se "$P" 2> /dev/null | awk -F '|' '$2~/ '"$P"' / {print $0;}'; then
#    echo "$P: not found"
#  fi
#done

