filename = "menu_debian.ipxe"
script = r"""#!ipxe

# --- Menu block --------------------------------------------------------------
# https://wiki.debian.org/DebianReleases/
set edition server
:menu
menu Select the OS type you want to boot
item --gap --                                   [ Return menu ]
item -- return                                  - Return
item --gap --                                   [ Edition ]
item -- server                                  - Server
item -- desktop                                 - Desktop
item --gap --                                   [ Development ]
item -- sid                                     - Debian ${edition} sid (unstable)
item -- testing                                 - Debian ${edition} testing (testing)
item -- duke                                    - Debian ${edition} 15.0 duke (unreleased)
item -- forky                                   - Debian ${edition} 14.0 forky (unreleased)
item --gap --                                   [ Current (supported) ]
item -- trixie                                  - Debian ${edition} 13.0 trixie (stable)
item -- bookworm                                - Debian ${edition} 12.0 bookworm (oldstable)
item -- bullseye                                - Debian ${edition} 11.0 bullseye (oldoldstable)
#item --gap --                                  [ Extended LTS support ]
#item -- buster                                 - Debian ${edition} 10.0 buster
#item -- stretch                                - Debian ${edition} 9.0 stretch
#item --gap --                                  [ End of life (unsupported) ]
#item -- jessie                                 - Debian ${edition} 8.0 jessie
#item -- wheezy                                 - Debian ${edition} 7.0 wheezy
#item -- squeeze                                - Debian ${edition} 6.0 squeeze
#item -- lenny                                  - Debian ${edition} 5.0 lenny
#item -- etch                                   - Debian ${edition} 4.0 etch
#item -- sarge                                  - Debian ${edition} 3.1 sarge
#item -- woody                                  - Debian ${edition} 3.0 woody
#item -- potato                                 - Debian ${edition} 2.2 potato
#item -- slink                                  - Debian ${edition} 2.1 slink
#item -- hamm                                   - Debian ${edition} 2.0 hamm
#item -- bo                                     - Debian ${edition} 1.3 bo
#item -- rex                                    - Debian ${edition} 1.2 rex
#item -- buzz                                   - Debian ${edition} 1.1 buzz
choose --default ${selected} selected || goto menu
iseq ${selected} return  && goto return  ||
iseq ${selected} server  && goto edition ||
iseq ${selected} desktop && goto edition ||
isset ${selected} && goto ${selected} ||
goto menu

:edition
iseq ${selected} server  && set edition server ||
iseq ${selected} desktop && set edition desktop ||
goto menu

:sid
:testing
:duke
:forky
:trixie
:bookworm
:bullseye
#:buster
#:stretch
#:jessie
#:wheezy
#:squeeze
#:lenny
#:etch
#:sarge
#:woody
#:potato
#:slink
#:hamm
#:bo
#:rex
#:buzz
clear vers
iseq ${selected} sid      && set vers unstable ||
iseq ${selected} testing  && set vers testing  ||
iseq ${selected} duke     && set vers 15       ||
iseq ${selected} forky    && set vers 14       ||
iseq ${selected} trixie   && set vers 13       ||
iseq ${selected} bookworm && set vers 12       ||
iseq ${selected} bullseye && set vers 11       ||
isset ${vers} || goto menu
iseq ${edition} server  && goto debian-server ||
iseq ${edition} desktop && goto debian-desktop ||
goto menu

:debian-server
set messages Loading Debian ${vers} Server ...
set parmauto auto=true preseed/url=${srvrhttp}/conf/preseed/ps_debian_server.cfg
set imgsdirs ${srvrhttp}/imgs/debian-mini-${vers}
#set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/debian-mini-${vers}
goto debian-common

:debian-desktop
set messages Loading Debian ${vers} Desktop ...
set parmauto auto=true preseed/url=${srvrhttp}/conf/preseed/ps_debian_desktop.cfg
set imgsdirs ${srvrhttp}/imgs/debian-mini-${vers}
#set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/debian-mini-${vers}
goto debian-common

:debian-common
set kernlopt ${imgsdirs}/linux
set inirdopt ${imgsdirs}/initrd.gz
set hnameopt sv-debian.workgroup
set enameopt ens160
set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
set otheropt --- quiet vga=788
set consoles dummy_console=tty0 dummy_console=ttyS0,9600
set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
set debugopt ${consoles} ${sulogins}
echo "Loading menu/booting.ipxe ..."
chain --autofree --replace ${ipxebase}/menu/booting.ipxe && exit ||
goto menu

"""
