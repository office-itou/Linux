filename = "menu_fedora.ipxe"
script = r"""#!ipxe

# --- Menu block --------------------------------------------------------------
# https://en.wikipedia.org/wiki/Fedora_Linux_release_history
set edition server
:menu
menu Select the OS type you want to boot
item --gap --                                   [ Return menu ]
item -- return                                  - Return
item --gap --                                   [ Edition ]
item -- server                                  - Server
item -- desktop                                 - Desktop
item --gap --                                   [ Development ]
item -- 46                                      - Fedora ${edition} 46
item -- 45                                      - Fedora ${edition} 45
item --gap --                                   [ Current (supported) ]
item -- 44                                      - Fedora ${edition} 44
item -- 43                                      - Fedora ${edition} 43
#item --gap --                                  [ End of life (unsupported) ]
#item -- 42                                     - Fedora Linux ${edition} 42 (Adams)
#item -- 41                                     - Fedora Linux ${edition} 41
#item -- 40                                     - Fedora Linux ${edition} 40
#item -- 39                                     - Fedora Linux ${edition} 39
#item -- 38                                     - Fedora Linux ${edition} 38
#item -- 37                                     - Fedora Linux ${edition} 37
#item -- 36                                     - Fedora Linux ${edition} 36
#item -- 35                                     - Fedora Linux ${edition} 35
#item -- 34                                     - Fedora Linux ${edition} 34
#item -- 33                                     - Fedora Linux ${edition} 33
#item -- 32                                     - Fedora Linux ${edition} 32
#item -- 31                                     - Fedora Linux ${edition} 31
#item -- 30                                     - Fedora Linux ${edition} 30
#item -- 29                                     - Fedora Linux ${edition} 29
#item -- 28                                     - Fedora Linux ${edition} 28
#item -- 27                                     - Fedora Linux ${edition} 27
#item -- 26                                     - Fedora Linux ${edition} 26
#item -- 25                                     - Fedora Linux ${edition} 25
#item -- 24                                     - Fedora Linux ${edition} 24
#item -- 23                                     - Fedora Linux ${edition} 23
#item -- 22                                     - Fedora Linux ${edition} 22
#item -- 21                                     - Fedora Linux ${edition} 21 (Twenty One)
#item -- 20                                     - Fedora Linux ${edition} 20 (Heisenbug)
#item -- 19                                     - Fedora Linux ${edition} 19 (Schrödinger’s Cat)
#item -- 18                                     - Fedora Linux ${edition} 18 (Spherical Cow)
#item -- 17                                     - Fedora Linux ${edition} 17 (Beefy Miracle)
#item -- 16                                     - Fedora Linux ${edition} 16 (Verne)
#item -- 15                                     - Fedora Linux ${edition} 15 (Lovelock)
#item -- 14                                     - Fedora Linux ${edition} 14 (Laughlin)
#item -- 13                                     - Fedora Linux ${edition} 13 (Goddard)
#item -- 12                                     - Fedora Linux ${edition} 12 (Constantine)
#item -- 11                                     - Fedora Linux ${edition} 11 (Leonidas)
#item -- 10                                     - Fedora Linux ${edition} 10 (Cambridge)
#item --  9                                     - Fedora Linux ${edition} 9 (Sulphur)
#item --  8                                     - Fedora Linux ${edition} 8 (Werewolf)
#item --  7                                     - Fedora Linux ${edition} 7 (Moonshine)
#item --  6                                     - Fedora Core ${edition} 6 (Zod)
#item --  5                                     - Fedora Core ${edition} 5 (Bordeaux)
#item --  4                                     - Fedora Core ${edition} 4 (Stentz)
#item --  3                                     - Fedora Core ${edition} 3 (Heidelberg)
#item --  2                                     - Fedora Core ${edition} 2 (Tettnang)
#item --  1                                     - Fedora Core ${edition} 1 (Yarrow)
choose --default ${selected} selected || goto menu
iseq ${selected} return  && goto return  ||
iseq ${selected} server  && goto edition ||
iseq ${selected} desktop && goto edition ||
isset ${selected} && goto fedora-${selected} ||
goto menu

:edition
iseq ${selected} server  && set edition server ||
iseq ${selected} desktop && set edition desktop ||
goto menu

:fedora-46
:fedora-45
:fedora-44
:fedora-43
clear vers
set vers ${selected}
isset ${vers} || goto menu
iseq ${edition} server  && goto fedora-server ||
iseq ${edition} desktop && goto fedora-desktop ||
goto menu

:fedora-server
set messages Loading Fedora ${vers} Server ...
set parmauto inst.ks=${srvrhttp}/conf/kickstart/ks_fedora-${vers}_net.cfg
set imgsdirs ${srvrhttp}/imgs/fedora-netinst-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-${vers}
goto fedora-common

:fedora-desktop
set messages Loading Fedora ${vers} Desktop ...
set parmauto inst.ks=${srvrhttp}/conf/kickstart/ks_fedora-${vers}_net_desktop.cfg
set imgsdirs ${srvrhttp}/imgs/fedora-netinst-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/fedora-netinst-${vers}
goto fedora-common

:fedora-common
set kernlopt ${imgsdirs}/images/pxeboot/vmlinuz
set inirdopt ${imgsdirs}/images/pxeboot/initrd.img
set hnameopt sv-fedora.workgroup
set enameopt ens160
set languopt locale=ja_JP.UTF-8 timezone=Asia/Tokyo keyboard-configuration/layoutcode=jp keyboard-configuration/modelcode=jp106 language=ja_JP
set otheropt inst.repo=nfs:${exptdirs} --- quiet vga=788
set consoles dummy_console=tty0 dummy_console=ttyS0,9600
set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
set debugopt ${consoles} ${sulogins}
echo "Loading menu/booting.ipxe ..."
chain --autofree --replace ${ipxebase}/menu/booting.ipxe && exit ||
goto menu

"""
