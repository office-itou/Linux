# **Application spec**

* For Debian ([preseed.cfg](../conf/_template/preseed_debian.cfg))

  <details><summary>For servers</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | apparmor                                                        | user-space parser utility for AppArmor                                      |
    | apparmor-utils                                                  | utilities for controlling AppArmor                                          |
    | selinux-basics                                                  | SELinux basic support                                                       |
    | selinux-policy-default                                          | Strict and Targeted variants of the SELinux policy                          |
    | auditd                                                          | User space tools for security auditing                                      |
    | rpm                                                             | package manager for RPM                                                     |
    | sudo                                                            | Provide limited super user privileges to specific users                     |
    | firewalld                                                       | dynamically managed firewall with support for network zones                 |
    | traceroute                                                      | Traces the route taken by packets over an IPv4/IPv6 network                 |
    | network-manager                                                 | network management framework (daemon and userspace tools)                   |
    | bash-completion                                                 | programmable completion for the bash shell                                  |
    | build-essential                                                 | Informational list of build-essential packages                              |
    | wget                                                            | retrieves files from the web                                                |
    | curl                                                            | command line tool for transferring data with URL syntax                     |
    | vim                                                             | Vi IMproved - enhanced vi editor                                            |
    | bc                                                              | GNU bc arbitrary precision calculator language                              |
    | rsync                                                           | fast, versatile, remote (and local) file-copying tool                       |
    | eject                                                           | ejects CDs and operates CD-Changers under Linux                             |
    | tree                                                            | displays an indented directory tree, in color                               |
    | shellcheck                                                      | lint tool for shell scripts                                                 |
    | clamav                                                          | anti-virus utility for Unix - command-line interface                        |
    | openssh-server                                                  | secure shell (SSH) server, for secure access from remote machines           |
    | systemd-resolved                                                | systemd DNS resolver                                                        |
    | systemd-timesyncd                                               | minimalistic service to synchronize local time with NTP servers             |
    | dnsmasq                                                         | Small caching DNS proxy and DHCP/TFTP server - system daemon                |
    | bind9-dnsutils                                                  | Clients provided with BIND 9                                                |
    | apache2                                                         | Apache HTTP Server                                                          |
    | samba                                                           | SMB/CIFS file, print, and login server for Unix                             |
    | smbclient                                                       | command-line SMB/CIFS clients for Unix                                      |
    | cifs-utils                                                      | Common Internet File System utilities                                       |
    | libnss-winbind                                                  | Samba nameservice integration plugins                                       |
    | open-vm-tools                                                   | Open VMware Tools for virtual machines hosted on VMware (CLI)               |
    | open-vm-tools-desktop                                           | Open VMware Tools for virtual machines hosted on VMware (GUI)               |

  </details>

  <details><summary>For desktops</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | task-desktop                                                    | Debian desktop environment                                                  |
    | task-gnome-desktop                                              | GNOME                                                                       |
    | task-laptop                                                     | laptop                                                                      |
    | task-japanese                                                   | Japanese environment                                                        |
    | task-japanese-desktop                                           | Japanese desktop                                                            |
    | adwaita-icon-theme-legacy                                       | fullcolor icon theme providing fallback for legacy applications             |
    | fonts-noto                                                      | metapackage to pull in all Noto fonts                                       |
    | fonts-noto-cjk                                                  | "No Tofu" font families with large Unicode coverage (CJK regular and bold)  |
    | fonts-noto-cjk-extra                                            | "No Tofu" font families with large Unicode coverage (CJK all weight)        |
    | fonts-noto-extra                                                | "No Tofu" font families with large Unicode coverage (extra)                 |
    | fonts-noto-color-emoji                                          | color emoji font from Google                                                |
    | fonts-noto-mono                                                 | "No Tofu" monospaced font family with large Unicode coverage                |
    | fonts-noto-ui-core                                              | "No Tofu" font families with large Unicode coverage (UI core)               |
    | fonts-noto-ui-extra                                             | "No Tofu" font families with large Unicode coverage (UI extra)              |
    | fonts-noto-unhinted                                             | "No Tofu" font families with large Unicode coverage (unhinted)              |
    | gnome-initial-setup                                             | Initial GNOME system setup helper                                           |
    | gnome-packagekit                                                | Graphical distribution neutral package manager for GNOME                    |
    | gnome-tweaks                                                    | tool to adjust advanced configuration settings for GNOME                    |
    | gnome-shell-extensions                                          | Extensions to extend functionality of GNOME Shell                           |
    | gnome-shell-extension-manager                                   | Utility for managing GNOME Shell Extensions                                 |
    | gnome-classic                                                   | Classic version of the GNOME desktop                                        |
    | gnome-classic-xsession                                          | Classic version of the GNOME desktop using Xorg                             |
    | im-config                                                       | Input method configuration framework                                        |
    | x11-common                                                      | X Window System (X.Org) infrastructure                                      |
    | zenity                                                          | Display graphical dialog boxes from shell scripts                           |
    | fcitx5                                                          | Fcitx Input Method Framework v5                                             |
    | fcitx5-anthy                                                    | Fcitx5 wrapper for Anthy IM engine                                          |
    | fcitx5-mozc                                                     | Mozc engine for fcitx5 - Client of the Mozc input method                    |
    | mozc-utils-gui                                                  | GUI utilities of the Mozc input method                                      |
    | libreoffice-l10n-ja                                             | office productivity suite -- Japanese language package                      |
    | libreoffice-help-ja                                             | office productivity suite -- Japanese help                                  |
    | firefox-esr-l10n-ja                                             | Japanese language package for Firefox ESR                                   |
    | thunderbird                                                     | mail/news client with RSS, chat and integrated spam filter support          |
    | thunderbird-l10n-ja                                             | Japanese language package for Thunderbird                                   |
    | chromium                                                        | web browser                                                                 |
    | chromium-sandbox                                                | web browser - setuid security sandbox for chromium                          |
    | chromium-l10n                                                   | web browser - language packs                                                |
    | chromium-driver                                                 | web browser - WebDriver support                                             |
    | chromium-shell                                                  | web browser - minimal shell                                                 |
    | rhythmbox                                                       | music player and organizer for GNOME                                        |
    | libavcodec-extra                                                | FFmpeg library with extra codecs (metapackage)                              |
    | pipewire-audio-client-libraries                                 | transitional package for pipewire-alsa and pipewire-jack                    |
    | bluetooth                                                       | Bluetooth support (metapackage)                                             |
    | bluez                                                           | Bluetooth tools and daemons                                                 |
    | bluez-firmware                                                  | Firmware for Bluetooth devices                                              |
    | firmware-realtek                                                | Binary firmware for Realtek network and audio chips                         |
    | blueman                                                         | Graphical bluetooth manager                                                 |
    | printer-driver-escpr                                            | printer driver for Epson Inkjet that use ESC/P-R                            |

  </details>

  </br>

* For Ubuntu ([nocloud/user-data](../conf/_template/user-data_ubuntu))

  <details><summary>For servers</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | apparmor                                                        | user-space parser utility for AppArmor                                      |
    | apparmor-utils                                                  | utilities for controlling AppArmor                                          |
    | selinux-basics                                                  | SELinux basic support                                                       |
    | selinux-policy-default                                          | Strict and Targeted variants of the SELinux policy                          |
    | auditd                                                          | User space tools for security auditing                                      |
    | rpm                                                             | package manager for RPM                                                     |
    | sudo                                                            | Provide limited super user privileges to specific users                     |
    | firewalld                                                       | dynamically managed firewall with support for network zones                 |
    | traceroute                                                      | Traces the route taken by packets over an IPv4/IPv6 network                 |
    | network-manager                                                 | network management framework (daemon and userspace tools)                   |
    | bash-completion                                                 | programmable completion for the bash shell                                  |
    | build-essential                                                 | Informational list of build-essential packages                              |
    | wget                                                            | retrieves files from the web                                                |
    | curl                                                            | command line tool for transferring data with URL syntax                     |
    | vim                                                             | Vi IMproved - enhanced vi editor                                            |
    | bc                                                              | GNU bc arbitrary precision calculator language                              |
    | rsync                                                           | fast, versatile, remote (and local) file-copying tool                       |
    | eject                                                           | ejects CDs and operates CD-Changers under Linux                             |
    | tree                                                            | displays an indented directory tree, in color                               |
    | shellcheck                                                      | lint tool for shell scripts                                                 |
    | tasksel                                                         | tool for selecting tasks for installation on Debian systems                 |
    | clamav                                                          | anti-virus utility for Unix - command-line interface                        |
    | openssh-server                                                  | secure shell (SSH) server, for secure access from remote machines           |
    | systemd-resolved                                                | systemd DNS resolver                                                        |
    | systemd-timesyncd                                               | minimalistic service to synchronize local time with NTP servers             |
    | dnsmasq                                                         | Small caching DNS proxy and DHCP/TFTP server - system daemon                |
    | bind9-dnsutils                                                  | Clients provided with BIND 9                                                |
    | apache2                                                         | Apache HTTP Server                                                          |
    | samba                                                           | SMB/CIFS file, print, and login server for Unix                             |
    | smbclient                                                       | command-line SMB/CIFS clients for Unix                                      |
    | cifs-utils                                                      | Common Internet File System utilities                                       |
    | libnss-winbind                                                  | Samba nameservice integration plugins                                       |
    | open-vm-tools                                                   | Open VMware Tools for virtual machines hosted on VMware (CLI)               |
    | open-vm-tools-desktop                                           | Open VMware Tools for virtual machines hosted on VMware (GUI)               |
    | ubuntu-server                                                   | Ubuntu Server system                                                        |
    | ubuntu-server-minimal                                           | Ubuntu Server minimal system                                                |

  </details>

  <details><summary>For desktops</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | ubuntu-desktop                                                  | Ubuntu desktop system                                                       |
    | ubuntu-desktop-minimal                                          | Ubuntu desktop minimal system                                               |
    | ubuntu-gnome-desktop                                            | The Ubuntu desktop system (transitional package)                            |
    | language-pack-ja                                                | translation updates for language Japanese                                   |
    | language-pack-gnome-ja                                          | GNOME translation updates for language Japanese                             |
    | fonts-noto                                                      | metapackage to pull in all Noto fonts                                       |
    | fonts-noto-cjk                                                  | "No Tofu" font families with large Unicode coverage (CJK regular and bold)  |
    | fonts-noto-cjk-extra                                            | "No Tofu" font families with large Unicode coverage (CJK all weight)        |
    | fonts-noto-extra                                                | "No Tofu" font families with large Unicode coverage (extra)                 |
    | fonts-noto-color-emoji                                          | color emoji font from Google                                                |
    | fonts-noto-mono                                                 | "No Tofu" monospaced font family with large Unicode coverage                |
    | fonts-noto-ui-core                                              | "No Tofu" font families with large Unicode coverage (UI core)               |
    | fonts-noto-ui-extra                                             | "No Tofu" font families with large Unicode coverage (UI extra)              |
    | fonts-noto-unhinted                                             | "No Tofu" font families with large Unicode coverage (unhinted)              |
    | gnome-initial-setup                                             | Initial GNOME system setup helper                                           |
    | gnome-packagekit                                                | Graphical distribution neutral package manager for GNOME                    |
    | gnome-tweaks                                                    | tool to adjust advanced configuration settings for GNOME                    |
    | gnome-shell-extensions                                          | Extensions to extend functionality of GNOME Shell                           |
    | gnome-shell-extension-manager                                   | Utility for managing GNOME Shell Extensions                                 |
    | im-config                                                       | Input method configuration framework                                        |
    | x11-common                                                      | X Window System (X.Org) infrastructure                                      |
    | zenity                                                          | Display graphical dialog boxes from shell scripts                           |
    | fcitx5                                                          | Next generation of Fcitx Input Method Framework                             |
    | fcitx5-anthy                                                    | Fcitx5 wrapper for Anthy IM engine                                          |
    | fcitx5-mozc                                                     | Mozc engine for fcitx5 - Client of the Mozc input method                    |
    | mozc-utils-gui                                                  | GUI utilities of the Mozc input method                                      |
    | libreoffice-l10n-ja                                             | office productivity suite -- Japanese language package                      |
    | libreoffice-help-ja                                             | office productivity suite -- Japanese help                                  |
    | firefox                                                         | Installs Firefox snap and provides some system integration                  |
    | firefox-locale-ja                                               | Transitional package - firefox-locale-ja -> firefox snap                    |
    | thunderbird                                                     | Transitional package - thunderbird -> thunderbird snap                      |
    | thunderbird-locale-ja                                           | Transitional package - thunderbird-locale-ja -> thunderbird snap            |
    | chromium-browser                                                | Transitional package - chromium-browser -> chromium snap                    |
    | chromium-browser-l10n                                           | Transitional package - chromium-browser-l10n -> chromium snap               |
    | chromium-chromedriver                                           | Transitional package - chromium-chromedriver -> chromium snap               |
    | rhythmbox                                                       | music player and organizer for GNOME                                        |
    | libavcodec-extra                                                | FFmpeg library with extra codecs (metapackage)                              |
    | gstreamer1.0-libav                                              | ffmpeg plugin for GStreamer                                                 |
    | pipewire-audio-client-libraries                                 | transitional package for pipewire-alsa and pipewire-jack                    |
    | bluetooth                                                       | Bluetooth support (metapackage)                                             |
    | bluez                                                           | Bluetooth tools and daemons                                                 |
    | bluez-firmware                                                  | Firmware for Bluetooth devices                                              |
    | blueman                                                         | Graphical bluetooth manager                                                 |
    | printer-driver-escpr                                            | printer driver for Epson Inkjet that use ESC/P-R                            |

  </details>

  </br>

* For Centos-stream ([kickstart.cfg](../conf/_template/kickstart_rhel.cfg)) (And fedora, almalinux, rockylinux, miraclelinux)

  <details><summary>For servers</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | @core                                                           | Group: Minimal host installation                                            |
    | @standard                                                       | Group: The standard installation of Red Hat Enterprise Linux.               |
    | epel-release                                                    | Extra Packages for Enterprise Linux repository configuration                |
    | selinux-policy-targeted                                         | SELinux targeted policy                                                     |
    | rpm                                                             | The RPM package management system                                           |
    | sudo                                                            | Allows restricted root access for specified users                           |
    | firewalld                                                       | A firewall daemon with D-Bus interface providing a dynamic firewall         |
    | traceroute                                                      | Traces the route taken by packets over an IPv4/IPv6 network                 |
    | NetworkManager                                                  | Network connection manager and user applications                            |
    | bash-completion                                                 | Programmable completion for Bash                                            |
    | wget                                                            | A utility for retrieving files using the HTTP or FTP protocols              |
    | curl                                                            | A utility for getting files from remote servers (FTP, HTTP, and others)     |
    | vim                                                             | the VIM editor                                                              |
    | bc                                                              | GNU's bc (a numeric processing language) and dc (a calculator)              |
    | rsync                                                           | A program for synchronizing files over a network                            |
    | tree                                                            | File system tree viewer                                                     |
    | ShellCheck                                                      | Shell script analysis tool                                                  |
    | clamav                                                          | End-user tools for the Clam Antivirus scanner                               |
    | openssh-server                                                  | An open source SSH server daemon                                            |
    | systemd-resolved                                                | Network Name Resolution manager                                             |
    | systemd-timesyncd                                               | System daemon to synchronize local system clock with NTP server             |
    | dnsmasq                                                         | A lightweight DHCP/caching DNS server                                       |
    | tftp-server                                                     | The server for the Trivial File Transfer Protocol (TFTP)                    |
    | bind-utils                                                      | Utilities for querying DNS name servers                                     |
    | httpd                                                           | Apache HTTP Server                                                          |
    | samba                                                           | Server and Client software to interoperate with Windows machines            |
    | samba-client                                                    | Samba client programs                                                       |
    | cifs-utils                                                      | Utilities for mounting and managing CIFS mounts                             |
    | samba-winbind                                                   | Samba winbind                                                               |
    | open-vm-tools                                                   | Open Virtual Machine Tools for virtual machines hosted on VMware            |
    | open-vm-tools-desktop                                           | User experience components for Open Virtual Machine Tools                   |
    | fuse                                                            | File System in Userspace (FUSE) v2 utilities                                |
    | fuse3                                                           | File System in Userspace (FUSE) v3 utilities                                |
    | fuse3-libs                                                      | File System in Userspace (FUSE) v3 libraries                                |

  </details>

  <details><summary>For desktops</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | @gnome-desktop                                                  | Group: Desktop environment and general purpose apps.                        |
    | adwaita-cursor-theme                                            | Adwaita cursor theme                                                        |
    | adwaita-icon-theme                                              | Adwaita icon theme                                                          |
    | google-noto-fonts-common                                        | Common files for Noto fonts                                                 |
    | google-noto-sans-cjk-vf-fonts                                   | Google Noto Sans CJK Variable Fonts                                         |
    | google-noto-sans-mono-cjk-vf-fonts                              | Google Noto Sans Mono CJK Variable Fonts                                    |
    | google-noto-sans-vf-fonts                                       | Noto Sans variable font                                                     |
    | google-noto-serif-cjk-vf-fonts                                  | Google Noto Serif CJK Variable Fonts                                        |
    | google-noto-color-emoji-fonts                                   | Google "Noto Color Emoji" colored emoji font                                |
    | google-noto-emoji-fonts                                         | Google "Noto Emoji" Black-and-White emoji font                              |
    | gnome-initial-setup                                             | Bootstrapping your OS                                                       |
    | firefox                                                         | Mozilla Firefox Web browser                                                 |
    | thunderbird                                                     | Mozilla Thunderbird mail/newsgroup client                                   |
    | chromium                                                        | A WebKit (Blink) powered web browser that Google doesn't want you to use    |
    | audacious                                                       | Advanced audio player                                                       |
    | audacious-plugins-ffaudio                                       | FFmpeg input plugin for Audacious                                           |
    | alsa-firmware                                                   | Firmware for several ALSA-supported sound cards                             |
    | libavcodec-free                                                 | FFmpeg codec library                                                        |
    | bluez                                                           | Bluetooth utilities                                                         |
    | realtek-firmware                                                | Firmware for Realtek WiFi/Bluetooth adapters                                |
    | gnome-bluetooth                                                 | Bluetooth graphical utilities                                               |
    | gutenprint-cups                                                 | CUPS drivers for Canon, Epson, HP and compatible printers                   |

  </details>

  </br>

* For openSUSE-15.6 ([autoyast.xml](../conf/_template/yast_opensuse.xml))

  <details><summary>For servers</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | base                                                            | pattern: Minimal Base System                                                |
    | basesystem                                                      | pattern: Base System (alias pattern for base)                               |
    | documentation                                                   | pattern: Help and Support Documentation                                     |
    | enhanced_base                                                   | pattern: Enhanced Base System                                               |
    | minimal_base                                                    | pattern: Minimal Appliance Base                                             |
    | sudo                                                            | Execute some commands as root                                               |
    | firewalld                                                       | A firewall daemon with D-Bus interface providing a dynamic firewall         |
    | traceroute                                                      | A new modern implementation of traceroute(8) utility for Linux systems      |
    | NetworkManager                                                  | Standard Linux network configuration tool suite                             |
    | bash-completion                                                 | Programmable Completion for Bash                                            |
    | wget                                                            | A Tool for Mirroring FTP and HTTP Servers                                   |
    | curl                                                            | A Tool for Transferring Data from URLs                                      |
    | vim                                                             | Vi IMproved                                                                 |
    | bc                                                              | GNU Command Line Calculator                                                 |
    | rsync                                                           | Versatile tool for fast incremental file transfer                           |
    | tree                                                            | File listing as a tree                                                      |
    | ShellCheck                                                      | Shell script analysis tool                                                  |
    | clamav                                                          | Antivirus Toolkit                                                           |
    | openssh-server                                                  | SSH (Secure Shell) server                                                   |
    | systemd-network                                                 | Deprecated package that has been replaced by systemd-networkd and systemd-resolved  |
    | systemd-resolved                                                | Systemd Network Name Resolution Manager                                     |
    | dnsmasq                                                         | DNS Forwarder and DHCP Server                                               |
    | tftp                                                            | Trivial File Transfer Protocol (TFTP)                                       |
    | bind-utils                                                      | Libraries for "bind" and utilities to query and test DNS                    |
    | apache2                                                         | The Apache HTTPD Server                                                     |
    | samba                                                           | A SMB/CIFS File, Print, and Authentication Server                           |
    | samba-client                                                    | Samba Client Utilities                                                      |
    | cifs-utils                                                      | Utilities for doing and managing mounts of the Linux CIFS filesystem        |
    | samba-winbind                                                   | Winbind Daemon and Tool                                                     |
    | open-vm-tools                                                   | Open Virtual Machine Tools                                                  |
    | open-vm-tools-desktop                                           | User experience components for Open Virtual Machine Tools                   |
    | fuse                                                            | User space File System                                                      |
    | glibc-i18ndata                                                  | Database Sources for 'locale'                                               |
    | glibc-locale                                                    | Locale Data for Localized Programs                                          |
    | less                                                            | Text File Browser and Pager Similar to more                                 |
    | which                                                           | Displays where a particular program in your path is located                 |
    | zypper                                                          | Command line software manager using libzypp                                 |

  </details>

  <details><summary>For desktops</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | gnome                                                           | pattern: GNOME Desktop Environment (Wayland)                                |
    | gnome-desktop2                                                  | The GNOME Desktop API Library                                               |
    | gnome-desktop2-lang                                             | Translations for package gnome-desktop2                                     |
    | gnome-terminal                                                  | GNOME Terminal                                                              |
    | gnome-shell                                                     | GNOME Shell                                                                 |
    | gstreamer-plugins-libav                                         | A ffmpeg/libav plugin for GStreamer                                         |
    | wireplumber-audio                                               | Enable audio support in PipeWire / WirePlumber                              |
    | adwaita-icon-theme                                              | GNOME Icon Theme                                                            |
    | google-noto-sans-jp-fonts                                       | Noto Sans Japanese Font - Regular and Bold                                  |
    | google-noto-serif-jp-fonts                                      | Noto Serif Japanese Font - Regular and Bold                                 |
    | noto-coloremoji-fonts                                           | Noto Color Emoji font                                                       |
    | noto-fonts                                                      | All Noto Fonts except CJK and Emoji                                         |
    | gnome-initial-setup                                             | GNOME Initial Setup Assistant                                               |
    | gnome-initial-setup-lang                                        | Translations for package gnome-initial-setup                                |
    | MozillaFirefox                                                  | Mozilla Firefox Web Browser                                                 |
    | MozillaThunderbird                                              | An integrated email, news feeds, chat, and newsgroups client                |
    | chromium                                                        | Google's open source browser project                                        |
    | audacious                                                       | Audio player with graphical UI and library functionality                    |
    | rhythmbox                                                       | GNOME Music Management Application                                          |
    | bluez                                                           | Bluetooth Stack for Linux                                                   |
    | epson-inkjet-printer-escpr                                      | Epson ESC/P-R Inkjet Printer Driver                                         |

  </details>

  </br>

* For openSUSE-16.0 ([autoinst.json](../conf/_template/agama_opensuse.json))

  <details><summary>For servers</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | base                                                            | pattern: Base System                                                        |
    | basesystem                                                      | pattern: Base System (alias pattern for base)                               |
    | enhanced_base                                                   | pattern: Enhanced Base System                                               |
    | minimal_base                                                    | pattern: Minimal Appliance Base                                             |
    | lvm2                                                            | Logical Volume Manager Tools                                                |
    | selinux-policy-targeted                                         | SELinux targeted base policy                                                |
    | sudo                                                            | Execute some commands as root                                               |
    | firewalld                                                       | A firewall daemon with D-Bus interface providing a dynamic firewall         |
    | traceroute                                                      | Packet route path tracing utility                                           |
    | NetworkManager                                                  | Standard Linux network configuration tool suite                             |
    | bash-completion                                                 | Programmable Completion for Bash                                            |
    | wget                                                            | A Tool for Mirroring FTP and HTTP Servers                                   |
    | curl                                                            | A Tool for Transferring Data from URLs                                      |
    | vim                                                             | Vi IMproved                                                                 |
    | bc                                                              | GNU Command Line Calculator                                                 |
    | rsync                                                           | Versatile tool for fast incremental file transfer                           |
    | tree                                                            | File listing as a tree                                                      |
    | ShellCheck                                                      | Shell script analysis tool                                                  |
    | clamav                                                          | Antivirus Toolkit                                                           |
    | openssh-server                                                  | SSH (Secure Shell) server                                                   |
    | systemd-network                                                 | Systemd Network Manager                                                     |
    | systemd-resolved                                                | Systemd Network Name Resolution Manager                                     |
    | dnsmasq                                                         | DNS Forwarder and DHCP Server                                               |
    | tftp                                                            | Trivial File Transfer Protocol (TFTP)                                       |
    | bind-utils                                                      | Libraries for "bind" and utilities to query and test DNS                    |
    | apache2                                                         | The Apache HTTPD Server                                                     |
    | samba                                                           | A SMB/CIFS File, Print, and Authentication Server                           |
    | samba-client                                                    | Samba Client Utilities                                                      |
    | cifs-utils                                                      | Utilities for doing and managing mounts of the Linux CIFS filesystem        |
    | samba-winbind                                                   | Winbind Daemon and Tool                                                     |
    | open-vm-tools                                                   | Open Virtual Machine Tools                                                  |
    | open-vm-tools-desktop                                           | User experience components for Open Virtual Machine Tools                   |
    | fuse                                                            | Reference implementation of the "Filesystem in Userspace"                   |
    | glibc-i18ndata                                                  | Database Sources for 'locale'                                               |
    | glibc-locale                                                    | Locale Data for Localized Programs                                          |
    | less                                                            | Text File Browser and Pager Similar to more                                 |
    | which                                                           | Displays where a particular program in your path is located                 |
    | zypper                                                          | Command line software manager using libzypp                                 |

  </details>

  <details><summary>For desktops</summary>

    |                          Package name                           |                                 Description                                 |
    | :-------------------------------------------------------------- | :-------------------------------------------------------------------------- |
    | gnome                                                           | pattern: GNOME Desktop Environment (Wayland)                                |
    | gnome-desktop-lang                                              | Translations for package gnome-desktop                                      |
    | gnome-terminal                                                  | GNOME Terminal                                                              |
    | gnome-shell                                                     | GNOME Shell                                                                 |
    | gstreamer-plugins-libav                                         | A ffmpeg/libav plugin for GStreamer                                         |
    | wireplumber                                                     | Session / policy manager implementation for PipeWire                        |
    | adwaita-icon-theme                                              | GNOME Icon Theme                                                            |
    | google-noto-sans-jp-fonts                                       | Noto Sans Japanese Font                                                     |
    | google-noto-serif-jp-fonts                                      | Noto Serif Japanese Font                                                    |
    | google-noto-coloremoji-fonts                                    | Noto Color Emoji font                                                       |
    | google-noto-fonts                                               | All Noto Fonts except CJK and Emoji                                         |
    | gnome-initial-setup                                             | GNOME Initial Setup Assistant                                               |
    | gnome-initial-setup-lang                                        | Translations for package gnome-initial-setup                                |
    | MozillaFirefox                                                  | Mozilla Firefox Web Browser                                                 |
    | MozillaThunderbird                                              | An integrated email, news feeds, chat, and newsgroups client                |
    | chromium                                                        | Google's open source browser project                                        |
    | rhythmbox                                                       | GNOME Music Management Application                                          |
    | bluez                                                           | Bluetooth Stack for Linux                                                   |

  </details>

  </br>
