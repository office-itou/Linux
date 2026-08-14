filename = "menu_centos.ipxe"
script = r"""#!ipxe

# --- Menu block --------------------------------------------------------------
# https://en.wikipedia.org/wiki/CentOS_Stream
set edition server
:menu
menu Select the OS type you want to boot
item --gap --                                   [ Return menu ]
item -- return                                  - Return
item --gap --                                   [ Edition ]
item -- server                                  - Server
item -- desktop                                 - Desktop
#item --gap --                                  [ Development ]
item --gap --                                   [ Current (supported) ]
item -- 10                                      - CentOS Stream ${edition} 10
item --  9                                      - CentOS Stream ${edition} 9
item --  8                                      - CentOS Stream ${edition} 8
#item --gap --                                  [ End of life (unsupported) ]
choose --default ${selected} selected || goto menu
iseq ${selected} return  && goto return  ||
iseq ${selected} server  && goto edition ||
iseq ${selected} desktop && goto edition ||
isset ${selected} && goto centos-${selected} ||
goto menu

:edition
iseq ${selected} server  && set edition server ||
iseq ${selected} desktop && set edition desktop ||
goto menu

:centos-10
:centos-9
:centos-8
clear vers
set vers ${selected}
isset ${vers} || goto menu
iseq ${edition} server  && goto centos-server ||
iseq ${edition} desktop && goto centos-desktop ||
goto menu

:centos-server
set messages Loading CentOS Stream ${vers} Server ...
set parmauto inst.ks=${srvrhttp}/conf/kickstart/ks_centos-stream-${vers}_net.cfg
set imgsdirs ${srvrhttp}/imgs/centos-stream-netinst-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/centos-stream-netinst-${vers}
goto centos-common

:centos-desktop
set messages Loading CentOS Stream ${vers} Desktop ...
set parmauto inst.ks=${srvrhttp}/conf/kickstart/ks_centos-stream-${vers}_net_desktop.cfg
set imgsdirs ${srvrhttp}/imgs/centos-stream-netinst-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/centos-stream-netinst-${vers}
goto centos-common

:centos-common
set kernlopt ${imgsdirs}/images/pxeboot/vmlinuz
set inirdopt ${imgsdirs}/images/pxeboot/initrd.img
set hnameopt sv-centos.workgroup
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
