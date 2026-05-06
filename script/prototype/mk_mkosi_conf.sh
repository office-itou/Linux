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
			#o  fbterm                              # fast framebuffer based terminal emulator for Linux
			    fdisk                               # collection of partitioning utilities
			    file                                # Recognize the type of data in a file using "magic" numbers
			#o  fonts-unifont                       # OpenType version of GNU Unifont
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
			#   fbterm                              # fast framebuffer based terminal emulator for Linux
			    fdisk                               # collection of partitioning utilities
			    file                                # Recognize the type of data in a file using "magic" numbers
			#   fonts-unifont                       # OpenType version of GNU Unifont
			#   groff-base                          # GNU troff text-formatting system (base system components)
			#   grub-efi-amd64                      # GRand Unified Bootloader, version 2 (EFI-AMD64 version)
			#   ifupdown                            # high level tools to configure network interfaces
			#   inetutils-telnet                    # telnet client
			#   init                                # metapackage ensuring an init system is installed
			#x  initramfs-tools                     # generic modular initramfs generator (automation)
			    initramfs-tools-bin                 # generic modular initramfs generator (binary tools)
			#x  initramfs-tools-core                # generic modular initramfs generator (core tools)
			#x  installation-report                 #
			#   iputils-ping                        # Tools to test the reachability of network hosts
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
			    dbus-broker                         # Linux D-Bus Message Broker
			#   device-mapper-multipath             # Tools to manage multipath devices using device-mapper
			#   iscsi-initiator-utils               # iSCSI daemon and utility programs
			#   ntfs-3g                             # Linux NTFS userspace driver
			#   ntfs-3g-libs                        # Runtime libraries for ntfs-3g
			#   nvme-cli                            # NVMe management command line interface
			#   openssl                             # Utilities from the general purpose cryptography library with TLS implementation
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
			    patterns-base-base                  # Base System
			    patterns-base-basesystem            # Base System (alias pattern for base)
			#   patterns-base-documentation         # Help and Support Documentation
			    patterns-base-enhanced_base         # Enhanced Base System
			    patterns-base-kdump                 # Kernel dump tooling
			    patterns-base-minimal_base          # Minimal Appliance Base
			    patterns-base-selinux               # SELinux Support
			    patterns-glibc-hwcaps-x86_64_v3     # Install x86-64-v3 optimized libraries
			    sudo                                # Execute some commands as root
			    firewalld                           # A firewall daemon with D-Bus interface providing a dynamic firewall
			    traceroute                          # Packet route path tracing utility
			    NetworkManager                      # Standard Linux network configuration tool suite
			    bash-completion                     # Programmable Completion for Bash
			    wget                                # A Tool for Mirroring FTP and HTTP Servers
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
			#   patterns-gnome-gnome                # GNOME Desktop Environment (Wayland)
			#x  gnome-desktop2                      #
			#x  gnome-desktop2-lang                 #
			#   gnome-terminal                      # GNOME Terminal
			#   gnome-shell                         # GNOME Shell
			#   gstreamer-plugins-libav             # A ffmpeg/libav plugin for GStreamer
			#x  wireplumber-audio                   #
			#   adwaita-icon-theme                  # GNOME Icon Theme
			#   google-noto-sans-jp-fonts           # Noto Sans Japanese Font
			#   google-noto-serif-jp-fonts          # Noto Serif Japanese Font
			#x  noto-coloremoji-fonts               # 
			#x  noto-fonts                          #
			#   gnome-initial-setup                 # GNOME Initial Setup Assistant
			#   gnome-initial-setup-lang            # Translations for package gnome-initial-setup
			#   MozillaFirefox                      # Mozilla Firefox Web Browser
			#   MozillaThunderbird                  # An integrated email, news feeds, chat, and newsgroups client
			#   chromium                            # Google's open source browser project
			#x  audacious                           #
			#   rhythmbox                           # GNOME Music Management Application
			#   bluez                               # Bluetooth Stack for Linux
			#x  epson-inkjet-printer-escpr          #
			    # --- installation environment --------------------------------------------
			    attr                                # Commands for Manipulating Extended Attributes
			    dbus-1                              # D-Bus Message Bus System
			    dbus-1-x11                          # D-Bus Message Bus System
			    dbus-1-daemon                       # D-Bus message bus daemon
			#o  dbus-broker                         # XDG message bus implementation
			#   glibc                               # Standard Shared Libraries (from the GNU C Library)
			#o  glibc-i18ndata                      # Database Sources for 'locale'
			#o  glibc-locale                        # Locale Data for Localized Programs
			#o  less                                # Text File Browser and Pager Similar to more
			#   libcap2                             # Library for Capabilities (linux-privs) Support
			#   libsemanage2                        # SELinux policy management library
			#   notification-daemon                 # Notification Daemon
			#   openssl                             # Secure Sockets and Transport Layer Security
			#   policycoreutils                     # SELinux policy core utilities
			#   selinux-policy                      # SELinux policy configuration
			#   selinux-policy-targeted             # SELinux targeted base policy
			#   sudo-policy-wheel-auth-self         # Users in the wheel group can authenticate as admin
			#   systemd-boot                        # A simple UEFI boot manager
			#   util-linux                          # A collection of basic system utilities (core part)
			#   util-linux-lang                     # Translations for package util-linux
			#   util-linux-systemd                  # A collection of basic system utilities (systemd dependent part)
			#o  zypper                              # Command line software manager using libzypp
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
