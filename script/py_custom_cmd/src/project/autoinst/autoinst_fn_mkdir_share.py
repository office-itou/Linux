# --- python library ----------------------------------------------------------
import grp
import os
import pwd
import shutil
from pathlib import Path

# --- my library --------------------------------------------------------------
from common.utils import (
    addpath,
    daemon_reload,
    debug_logger,
    delpath,
    file_backup,
    file_origin,
    fread,
    fwrite,
    get_caller_name,
    message_info,
    message_warn,
    run_subprocess,
)


# --- import module -----------------------------------------------------------
# --- class and function ------------------------------------------------------
@debug_logger
def mkdir_share(info_syst) -> None:
    _caller = get_caller_name()
    _data = info_syst.data
    _tget_path: Path = getattr(_data, "tget_path", None)
    # --- create system user id -----------------------------------------------
    message_info(_caller, f"{'info':<10}:create system user id", omit=True)
    _sudo_list: list[str] = ["sudo", "-n"]
    if not grp.getgrnam(_data.samb_grup):
        run_subprocess([*_sudo_list, "groupadd", "--system", _data.samb_grup])
    if not grp.getgrnam(_data.samb_gadm):
        run_subprocess([*_sudo_list, "groupadd", "--system", _data.samb_gadm])
    if not pwd.getpwnam(_data.samb_user):
        run_subprocess(
            [
                *_sudo_list,
                "useradd",
                "--system",
                "--shell",
                str(_data.nlin_path),
                "--groups",
                _data.samb_grup,
                _data.samb_gadm,
            ]
        )
    # --- create directory ----------------------------------------------------
    message_info(_caller, f"{'info':<10}:create directory", omit=True)
    _dirs_list = [
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
        # _data.samb_path / "pub/resource/image/isos/windows/windows-7",
        # _data.samb_path / "pub/resource/image/isos/windows/windows-8.1",
        _data.samb_path / "pub/resource/image/isos/windows/windows-10",
        _data.samb_path / "pub/resource/image/isos/windows/windows-11",
        # _data.samb_path / "pub/resource/image/isos/windows/windows-adk",
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
    for _dir in _dirs_list:
        _dir.mkdir(parents=True, exist_ok=True)
    # --- change file mode ----------------------------------------------------
    message_info(_caller, f"{'info':<10}:change file mode", omit=True)
    if _data.samb_user and _data.samb_user:

        def recursive(path: Path, user: str, group: str, mode: int):
            if not path.exists():
                return
            try:
                for _root, _dirs, _files in os.walk(path):
                    _path = (
                        [Path(_root)]
                        + [Path(_root) / d for d in _dirs]
                        + [Path(_root) / f for f in _files]
                    )
                    shutil.chown(path=_path, user=user, group=group)
                    os.chmod(_path, mode)
            except Exception:
                pass

        recursive(
            path=_data.samb_path,
            user=_data.samb_user,
            group=_data.samb_grup,
            mode=0o2770,
        )
        recursive(
            path=_data.conf_path,
            user=_data.samb_user,
            group=_data.samb_grup,
            mode=0o2775,
        )
        recursive(
            path=_data.isos_path,
            user=_data.samb_user,
            group=_data.samb_grup,
            mode=0o2775,
        )
        recursive(
            path=_data.rmak_path,
            user=_data.samb_user,
            group=_data.samb_grup,
            mode=0o2775,
        )
    # --- create fstab --------------------------------------------------------
    message_info(_caller, f"{'info':<10}:create fstab", omit=True)
    _mntp_list: list[dict] = [
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
    _ftab_path: Path = addpath(base=_tget_path, path=Path("/etc/fstab"))
    _read_text = fread(src_path=_ftab_path, text=True)
    if "/srv/" in _read_text:
        file_backup(info_syst=info_syst, orig_path=_ftab_path)
        file_origin(info_syst=info_syst, orig_path=_ftab_path)
        _fmat_parm = "{:<27} {:<35} {:<7} {:<27} {:<7} {}\n"
        _fmat_list = [
            _fmat_parm.format(
                "# <file system>",
                "<mount point>",
                "<type>",
                "<options>",
                "<dump>",
                "<pass>",
            ),
        ]
        for _line in _mntp_list:
            _fmat_list.append(
                _fmat_parm.format(
                    _line["fsys"], _line["mntp"], "none", "bind,ro", "0", "0"
                ),
            )
        _writ_text = "\n".join(s for s in _read_text + _fmat_list)
        fwrite(dest_path=_ftab_path, data=_writ_text, text=True, backup=False)
    # --- check mount ---------------------------------------------------------
    message_info(_caller, f"{'info':<10}:check mount", omit=True)
    if not _data.tget_chrt:
        daemon_reload()
        for _line in _mntp_list:
            _mntp_path = _line["mntp"]
            _result = run_subprocess(["mount", str(_mntp_path)])
            if _result.returncode == 0:
                message_info(
                    _caller, f"{'success':<10}:mounted:{_mntp_path}", omit=True
                )
            else:
                message_info(
                    _caller, f"{'failed':<10}:not mounted:{_mntp_path}", omit=True
                )
    file_backup(info_syst=info_syst, orig_path=_ftab_path, mode="init")
    # --- create symbolic link ------------------------------------------------
    message_info(_caller, f"{'info':<10}:create symbolic link", omit=True)
    _slnk_list: list[dict] = [
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
    for _line in _slnk_list:
        _srcs_path: Path = addpath(base=_tget_path, path=_line["tget"])
        _dest_path: Path = addpath(base=_tget_path, path=_line["dest"])
        if _line["dest"].endswith("/"):
            _dest_path = _dest_path / Path(_line["tget"]).name
        if not _srcs_path.exists():
            message_warn(_caller, f"create: [{_srcs_path}]", omit=True)
            if str(_srcs_path).endswith("syslinux.cfg"):
                _srcs_path.write_text("", encoding="utf-8")
                file_backup(info_syst=info_syst, orig_path=_srcs_path, mode="init")
            else:
                _srcs_path.mkdir(parents=True, exist_ok=True)
        if not _dest_path.exists():
            message_info(_caller, f"{'info':<10}:link: [{_dest_path}]", omit=True)
            _srcs_path = delpath(base=_tget_path, path=_srcs_path)
            _dest_path.symlink_to(
                target=_srcs_path, target_is_directory=bool(_line["dest"].endswith("/"))
            )
    # --- create index.html ---------------------------------------------------
    message_info(_caller, f"{'info':<10}:create index.html", omit=True)
    _indx_path: Path = addpath(base=_tget_path, path=_data.html_path) / "index.html"
    _indx_path.write_text(f'"Hello, world!" from {_data.nics_fqdn}', encoding="utf-8")
    file_backup(info_syst=info_syst, orig_path=_indx_path, mode="init")
    # --- create autoexec.ipxe ------------------------------------------------
    _auto_path: Path = Path(f"{_data.tftpl_path}/ipxe/autoexec.ipxe")
    _writ_text: str = (
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
        f"isset ${66} && set srvraddr ${66} || set srvraddr ${_data.nics_ipv4}\n"
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
    )
    fwrite(dest_path=_auto_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_auto_path, mode="init")
    # --- create menu.ipxe ----------------------------------------------------
    _auto_path: Path = Path(f"{_data.tftpl_path}/ipxe/menu/menu.ipxe")
    _writ_text: str = (
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
    )
    fwrite(dest_path=_auto_path, data=_writ_text, text=True, backup=False)
    file_backup(info_syst=info_syst, orig_path=_auto_path, mode="init")
