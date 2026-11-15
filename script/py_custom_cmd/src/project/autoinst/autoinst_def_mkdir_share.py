# --- python library ----------------------------------------------------------
from dataclasses import dataclass, fields
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    debug_logger,
    get_caller_name,
    message_info,
)

# --- import module -----------------------------------------------------------
from autoinst_fn_sysinfo import InfoSystem


# --- class and function ------------------------------------------------------
@dataclass
class SrvDirData:
    dirs: list[Path] | None = None
    attr: list[dict] | None = None
    mntp: list[dict] | None = None
    slnk: list[dict] | None = None
    ipxe: dict[str] | None = None


class InfoSrvDir:
    @debug_logger
    def __init__(self, info_syst: InfoSystem) -> None:
        _caller = get_caller_name()
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'initialize':<10}:system data", omit=True)
        self._valid_fields: set[str] = {f.name for f in fields(SrvDirData)}
        self.data: SrvDirData = SrvDirData()
        self.syst = info_syst
        _data = self.syst.data
        # ---------------------------------------------------------------------
        self.data.dirs = [
            _data.tops_path,
            _data.expo_path,
            _data.hgfs_path,
            _data.html_path,
            _data.samb_path,
            _data.samb_path / "adm/commands",
            _data.samb_path / "adm/profiles",
            _data.samb_path / "pub/_license",
            _data.samb_path / "pub/contents/disc",
            _data.samb_path / "pub/contents/dlna/movies",
            _data.samb_path / "pub/contents/dlna/others",
            _data.samb_path / "pub/contents/dlna/photos",
            _data.samb_path / "pub/contents/dlna/sounds",
            _data.samb_path / "pub/hardware",
            _data.samb_path / "pub/software",
            _data.samb_path / "pub/resource/image/isos/linux",
            _data.samb_path / "pub/resource/image/isos/windows",
            _data.samb_path / "pub/resource/image/isos/linux/almalinux",
            _data.samb_path / "pub/resource/image/isos/linux/centos",
            _data.samb_path / "pub/resource/image/isos/linux/debian",
            # _data.samb_path / "pub/resource/image/isos/linux/emmabuntus",
            _data.samb_path / "pub/resource/image/isos/linux/fedora",
            # _data.samb_path / "pub/resource/image/isos/linux/knoppix",
            _data.samb_path / "pub/resource/image/isos/linux/memtest86plus",
            _data.samb_path / "pub/resource/image/isos/linux/miraclelinux",
            _data.samb_path / "pub/resource/image/isos/linux/opensuse",
            _data.samb_path / "pub/resource/image/isos/linux/rockylinux",
            # _data.samb_path / "pub/resource/image/isos/linux/ubcd",
            _data.samb_path / "pub/resource/image/isos/linux/ubuntu",
            _data.samb_path / "pub/resource/image/isos/windows/aomei",
            _data.samb_path / "pub/resource/image/isos/windows/ati",
            # _data.samb_path / "pub/resource/image/isos/windows/free-dos",
            # _data.samb_path / "pub/resource/image/isos/windows/office-365",
            _data.samb_path / "pub/resource/image/isos/windows/windows-7",
            _data.samb_path / "pub/resource/image/isos/windows/windows-8.1",
            _data.samb_path / "pub/resource/image/isos/windows/windows-10",
            _data.samb_path / "pub/resource/image/isos/windows/windows-11",
            # _data.samb_path / "pub/resource/image/isos/windows/windows-10/22h2",
            # _data.samb_path / "pub/resource/image/isos/windows/windows-11/23h2",
            # _data.samb_path / "pub/resource/image/isos/windows/windows-11/24h2",
            # _data.samb_path / "pub/resource/image/isos/windows/windows-11/25h2",
            # _data.samb_path / "pub/resource/image/isos/windows/windows-11/26h2",
            _data.samb_path / "pub/resource/image/isos/windows/winpe",
            _data.samb_path / "pub/resource/image/rmak",
            _data.samb_path / "pub/resource/source/git",
            _data.samb_path / "usr",
            _data.tftp_path,
            _data.tftp_path / "boot/grub/fonts",
            _data.tftp_path / "boot/grub/locale",
            _data.tftp_path / "boot/grub/i386-pc",
            _data.tftp_path / "boot/grub/i386-efi",
            _data.tftp_path / "boot/grub/x86_64-efi",
            _data.tftp_path / "exports",
            _data.tftp_path / "ipxe/menu",
            _data.tftp_path / "menu-bios/pxelinux.cfg",
            _data.tftp_path / "menu-efi64/pxelinux.cfg",
            _data.user_path,
            _data.pvat_path,
            _data.pvat_path / "bin",
            _data.pvat_path / "src/git",
            _data.pvat_path / "wrk",
            _data.shar_path,
            _data.conf_path,
            _data.conf_path / "agama",
            _data.conf_path / "autoyast",
            _data.conf_path / "kickstart",
            _data.conf_path / "nocloud/ubuntu_desktop",
            _data.conf_path / "nocloud/ubuntu_server",
            _data.conf_path / "preseed",
            # _data.conf_path / "script",
            _data.conf_path / "windows",
            _data.data_path,
            _data.keys_path,
            _data.mkos_path,
            _data.mkos_path / "_template",
            _data.mkos_path / "mkosi.build.d",
            _data.mkos_path / "mkosi.clean.d",
            _data.mkos_path / "mkosi.conf.d",
            _data.mkos_path / "mkosi.extra",
            _data.mkos_path / "mkosi.finalize.d",
            _data.mkos_path / "mkosi.postinst.d",
            _data.mkos_path / "mkosi.postoutput.d",
            _data.mkos_path / "mkosi.prepare.d",
            _data.mkos_path / "mkosi.repart",
            _data.mkos_path / "mkosi.sync.d",
            _data.mkos_path / "repository",
            _data.mkos_path / _data.shel_path.name,
            _data.tmpl_path,
            _data.shel_path,
            _data.imgs_path,
            _data.isos_path,
            _data.isos_path / "linux",
            _data.isos_path / "linux/debian",
            _data.isos_path / "linux/ubuntu",
            _data.isos_path / "linux/fedora",
            _data.isos_path / "linux/centos",
            _data.isos_path / "linux/almalinux",
            _data.isos_path / "linux/rockylinux",
            _data.isos_path / "linux/miraclelinux",
            _data.isos_path / "linux/opensuse",
            _data.isos_path / "linux/memtest86plus",
            _data.isos_path / "windows",
            _data.isos_path / "windows/windows-10",
            _data.isos_path / "windows/windows-11",
            _data.isos_path / "windows/winpe",
            _data.isos_path / "windows/ati",
            _data.isos_path / "windows/aomei",
            _data.load_path,
            _data.rmak_path,
            _data.cach_path,
            _data.ctnr_path,
            _data.chrt_path,
            _data.xnbd_path,
            _data.xnfs_path,
            _data.xnfs_path / _data.conf_path.name,
            _data.xnfs_path / _data.imgs_path.name,
            _data.xsmb_path,
            _data.xsmb_path / _data.conf_path.name,
            _data.xsmb_path / _data.imgs_path.name,
            _data.xsmb_path / _data.isos_path.name,
            _data.xsmb_path / _data.load_path.name,
            _data.xsmb_path / _data.rmak_path,
        ]
        # ---------------------------------------------------------------------
        self.data.attr = [
            {"path": _data.samb_path, "attr": "2770"},
            {"path": _data.conf_path, "attr": "2775"},
            {"path": _data.isos_path, "attr": "2775"},
            {"path": _data.rmak_path, "attr": "2775"},
        ]
        # ---------------------------------------------------------------------
        self.data.mntp = [
            {
                "fsys": f"{_data.shel_path}",
                "mntp": f"{_data.mkos_path}/{_data.shel_path.name}",
            },
            {
                "fsys": f"{_data.conf_path}",
                "mntp": f"{_data.xnfs_path}/{_data.conf_path.name}",
            },
            {
                "fsys": f"{_data.imgs_path}",
                "mntp": f"{_data.xnfs_path}/{_data.imgs_path.name}",
            },
            {
                "fsys": f"{_data.conf_path}",
                "mntp": f"{_data.xsmb_path}/{_data.conf_path.name}",
            },
            {
                "fsys": f"{_data.imgs_path}",
                "mntp": f"{_data.xsmb_path}/{_data.imgs_path.name}",
            },
            {
                "fsys": f"{_data.isos_path}",
                "mntp": f"{_data.xsmb_path}/{_data.isos_path.name}",
            },
            {
                "fsys": f"{_data.load_path}",
                "mntp": f"{_data.xsmb_path}/{_data.load_path.name}",
            },
            {
                "fsys": f"{_data.rmak_path}",
                "mntp": f"{_data.xsmb_path}/{_data.rmak_path.name}",
            },
        ]
        # ---------------------------------------------------------------------
        self.data.slnk = [
            {"tget": f"{_data.conf_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.imgs_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.isos_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.load_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.rmak_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.tftp_path}", "dest": f"{_data.html_path}/"},
            {"tget": f"{_data.conf_path}", "dest": f"{_data.tftpl_path}/exports/"},
            {"tget": f"{_data.imgs_path}", "dest": f"{_data.tftpl_path}/exports/"},
            {"tget": f"{_data.isos_path}", "dest": f"{_data.tftpl_path}/exports/"},
            {"tget": f"{_data.load_path}", "dest": f"{_data.tftpl_path}/exports/"},
            {"tget": f"{_data.rmak_path}", "dest": f"{_data.tftpl_path}/exports/"},
            {
                "tget": f"../exports/{_data.conf_path.name}",
                "dest": f"{_data.tftpl_path}/menu-bios/",
            },
            {
                "tget": f"../exports/{_data.imgs_path.name}",
                "dest": f"{_data.tftpl_path}/menu-bios/",
            },
            {
                "tget": f"../exports/{_data.isos_path.name}",
                "dest": f"{_data.tftpl_path}/menu-bios/",
            },
            {
                "tget": f"../exports/{_data.load_path.name}",
                "dest": f"{_data.tftpl_path}/menu-bios/",
            },
            {
                "tget": f"../exports/{_data.rmak_path.name}",
                "dest": f"{_data.tftpl_path}/menu-bios/",
            },
            {
                "tget": r"../syslinux.cfg",
                "dest": f"{_data.tftpl_path}/menu-bios/pxelinux.cfg/default",
            },
            {
                "tget": f"../exports/{_data.conf_path.name}",
                "dest": f"{_data.tftpl_path}/menu-efi64/",
            },
            {
                "tget": f"../exports/{_data.imgs_path.name}",
                "dest": f"{_data.tftpl_path}/menu-efi64/",
            },
            {
                "tget": f"../exports/{_data.isos_path.name}",
                "dest": f"{_data.tftpl_path}/menu-efi64/",
            },
            {
                "tget": f"../exports/{_data.load_path.name}",
                "dest": f"{_data.tftpl_path}/menu-efi64/",
            },
            {
                "tget": f"../exports/{_data.rmak_path.name}",
                "dest": f"{_data.tftpl_path}/menu-efi64/",
            },
            {
                "tget": r"../syslinux.cfg",
                "dest": f"{_data.tftpl_path}/menu-efi64/pxelinux.cfg/default",
            },
        ]
        # ---------------------------------------------------------------------
        self.data.ipxe = {
            "autoexec.ipxe": (
                "#!ipxe\n"
                "\n"
                "# --- Define colour pair ------------------------------------------------------\n"  # noqa: E501
                "# Reset the default colour pair\n"
                "cpair 0 ||\n"
                "# Redefine the editable text pair as black on white\n"
                "cpair --foreground 7 --background 0 4 ||\n"
                "\n"
                "# --- Check x86 CPU feature ---------------------------------------------------\n"  # noqa: E501
                '# Check if CPU supports 64-bit operation ("long mode")\n'
                "cpuid --ext 29 && set arch x86_64 || set arch i386\n"
                "\n"
                "# --- Automatically configure interfaces --------------------------------------\n"  # noqa: E501
                "# Automatically configure the first available interface using DHCP\n"
                "ifconf --configurator dhcp ||\n"
                "# Automatically configure the first available interface using IPv6\n"
                "ifconf --configurator ipv6 ||\n"
                "\n"
                "# --- Set the IP address of the PXE boot server -------------------------------\n"  # noqa: E501
                f"isset ${66} && set srvraddr ${66} || set srvraddr ${_data.nics_ipv4}\n"  # noqa: E501
                "\n"
                "# --- Set the parameters. -----------------------------------------------------\n"  # noqa: E501
                "set srvrhttp http://${srvraddr}\n"
                "set ipxebase ${srvrhttp}/tftp/ipxe/\n"
                "set optn-timeout 1000\n"
                "set menu-timeout 0\n"
                "set esc:hex 1b\n"
                "\n"
                "# --- Preventing multiple instances -------------------------------------------\n"  # noqa: E501
                "isset ${menu-default} || set menu-default exit\n"
                "\n"
                "# --- chain -------------------------------------------------------------------\n"  # noqa: E501
                "chain ${ipxebase}/menu/menu.ipxe\n"
                "\n"
            ),
            "menu.ipxe": (
                "#!ipxe\n"
                "\n"
                "# --- Menu block --------------------------------------------------------------\n"  # noqa: E501
                ":menu\n"
                "menu Select the OS type you want to boot\n"
                "item --gap --                                   [ System command ]\n"
                "item -- shell                                   - iPXE shell\n"
                "item -- shutdown                                - System shutdown\n"
                "item -- restart                                 - System reboot\n"
                "choose --timeout ${menu-timeout} --default ${menu-default} selected && goto ${selected}\n"  # noqa: E501
                "goto menu\n"
                "\n"
                "# --- Interactive form block --------------------------------------------------\n"  # noqa: E501
                ":shell\n"
                'echo "Booting iPXE shell ..."\n'
                "shell\n"
                "goto menu\n"
                "\n"
                ":shutdown\n"
                'echo "System shutting down ..."\n'
                "poweroff\n"
                "exit\n"
                "\n"
                ":restart\n"
                'echo "System rebooting ..."\n'
                "reboot\n"
                "exit\n"
                "\n"
                ":exit\n"
                "exit\n"
                "\n"
                ":error\n"
                "prompt Press any key to continue\n"
                "exit\n"
                "\n"
            ),
        }
        # ---------------------------------------------------------------------
        message_info(_caller, f"{'complete':<10}:system data", omit=True)
