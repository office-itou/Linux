filename = "menu_ubuntu.ipxe"
script = r"""#!ipxe

# --- Menu block --------------------------------------------------------------
# https://ubuntu.com/project/docs/release-team/list-of-releases/
set edition server
:menu
menu Select the OS type you want to boot
item --gap --                                   [ Return menu ]
item -- return                                  - Return
item --gap --                                   [ Edition ]
item -- server                                  - Server
item -- desktop                                 - Desktop
item --gap --                                   [ Development ]
item -- stonking                                - Ubuntu ${edition} 26.10 Stonking Stingray
item --gap --                                   [ Current (supported) ]
item -- resolute                                - Ubuntu ${edition} 26.04 LTS Resolute Raccoon
item -- noble                                   - Ubuntu ${edition} 24.04 LTS Noble Numbat
#item -- jammy                                  - Ubuntu ${edition} 22.04 LTS Jammy Jellyfish
#item -- focal                                  - Ubuntu ${edition} 20.04 LTS Focal Fossa
#item -- bionic                                 - Ubuntu ${edition} 18.04 LTS Bionic Beaver
#item -- xenial                                 - Ubuntu ${edition} 16.04 LTS Xenial Xerus
#item -- trusty                                 - Ubuntu ${edition} 14.04 LTS Trusty Tahr
#item --gap --                                  [ Expanded Security Maintenance ]
#item -- focal                                  - Ubuntu ${edition} 20.04 ESM Focal Fossa
#item -- bionic                                 - Ubuntu ${edition} 18.04 ESM Bionic Beaver
#item -- xenial                                 - Ubuntu ${edition} 16.04 ESM Xenial Xerus
#item -- trusty                                 - Ubuntu ${edition} 14.04 ESM Trusty Tahr
#item -- precise                                - Ubuntu ${edition} 12.04 ESM Precise Pangolin
#item --gap --                                  [ End of life (unsupported) ]")
#item -- questing                               - Ubuntu ${edition} 25.10 Questing Quokka
#item -- plucky                                 - Ubuntu ${edition} 25.04 Plucky Puffin
#item -- oracular                               - Ubuntu ${edition} 24.10 Oracular Oriole
#item -- mantic                                 - Ubuntu ${edition} 23.10 Mantic Minotaur
#item -- lunar                                  - Ubuntu ${edition} 23.04 Lunar Lobster
#item -- kinetic                                - Ubuntu ${edition} 22.10 Kinetic Kudu
#item -- impish                                 - Ubuntu ${edition} 21.10 Impish Indri
#item -- hirsute                                - Ubuntu ${edition} 21.04 Hirsute Hippo
#item -- groovy                                 - Ubuntu ${edition} 20.10 Groovy Gorilla
#item -- eoan                                   - Ubuntu ${edition} 19.10 Eoan Ermine
#item -- disco                                  - Ubuntu ${edition} 19.04 Disco Dingo
#item -- cosmic                                 - Ubuntu ${edition} 18.10 Cosmic Cuttlefish
#item -- artful                                 - Ubuntu ${edition} 17.10 Artful Aardvark
#item -- zesty                                  - Ubuntu ${edition} 17.04 Zesty Zapus
#item -- yakkety                                - Ubuntu ${edition} 16.10 Yakkety Yak
#item -- wily                                   - Ubuntu ${edition} 15.10 Wily Werewolf
#item -- vivid                                  - Ubuntu ${edition} 15.04 Vivid Vervet
#item -- utopic                                 - Ubuntu ${edition} 14.10 Utopic Unicorn
#item -- saucy                                  - Ubuntu ${edition} 13.10 Saucy Salamander
#item -- raring                                 - Ubuntu ${edition} 13.04 Raring Ringtail
#item -- quantal                                - Ubuntu ${edition} 12.10 Quantal Quetzal
#item -- precise                                - Ubuntu ${edition} 12.04 LTS Precise Pangolin
#item -- oneiric                                - Ubuntu ${edition} 11.10 Oneiric Ocelot
#item -- natty                                  - Ubuntu ${edition} 11.04 Natty Narwhal
#item -- maverick                               - Ubuntu ${edition} 10.10 Maverick Meerkat
#item -- lucid                                  - Ubuntu ${edition} 10.04 LTS Lucid Lynx
#item -- karmic                                 - Ubuntu ${edition} 9.10 Karmic Koala
#item -- jaunty                                 - Ubuntu ${edition} 9.04 Jaunty Jackalope
#item -- intrepid                               - Ubuntu ${edition} 8.10 Intrepid Ibex
#item -- hardy                                  - Ubuntu ${edition} 8.04 LTS Hardy Heron
#item -- gutsy                                  - Ubuntu ${edition} 7.10 Gutsy Gibbon
#item -- feisty                                 - Ubuntu ${edition} 7.04 Feisty Fawn
#item -- edgy                                   - Ubuntu ${edition} 6.10 Edgy Eft
#item -- dapper                                 - Ubuntu ${edition} 6.06 LTS Dapper Drake
#item -- breezy                                 - Ubuntu ${edition} 5.10 Breezy Badger
#item -- hoary                                  - Ubuntu ${edition} 5.04 Hoary Hedgehog
#item -- warty                                  - Ubuntu ${edition} 4.10 Warty Warthog
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

:stonking
:resolute
#:questing
#:plucky
#:oracular
:noble
#:mantic
#:lunar
#:kinetic
#:jammy
#:impish
#:hirsute
#:groovy
#:focal
#:eoan
#:disco
#:cosmic
#:bionic
#:artful
#:zesty
#:yakkety
#:xenial
#:wily
#:vivid
#:utopic
#:trusty
#:saucy
#:raring
#:quantal
#:precise
#:precise
#:oneiric
#:natty
#:maverick
#:lucid
#:karmic
#:jaunty
#:intrepid
#:hardy
#:gutsy
#:feisty
#:edgy
#:dapper
#:breezy
#:hoary
#:warty
clear vers
iseq ${selected} stonking && set vers 26.10 ||
iseq ${selected} resolute && set vers 26.04 ||
iseq ${selected} noble    && set vers 24.04 ||
isset ${vers} || goto menu
iseq ${edition} server  && goto ubuntu-server ||
iseq ${edition} desktop && goto ubuntu-desktop ||
goto menu

:ubuntu-server
set messages Loading Ubuntu ${vers} Server ...
set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=${srvrhttp}/conf/nocloud/ubuntu_server
set imgsdirs ${srvrhttp}/imgs/ubuntu-live-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/ubuntu-live-${vers}
goto ubuntu-common

:ubuntu-desktop
set messages Loading Ubuntu ${vers} Desktop ...
set parmauto automatic-ubiquity noprompt autoinstall cloud-config-url=/dev/null ds=nocloud;s=${srvrhttp}/conf/nocloud/ubuntu_desktop
set imgsdirs ${srvrhttp}/imgs/ubuntu-desktop-${vers}
set exptdirs ${srvraddr}:/srv/exports/nfs/imgs/ubuntu-desktop-${vers}
goto ubuntu-common

:ubuntu-common
set kernlopt ${imgsdirs}/casper/vmlinuz
set inirdopt ${imgsdirs}/casper/initrd
set hnameopt sv-ubuntu.workgroup
set enameopt ens160
set languopt language=ja country=JP timezone=Asia/Tokyo keyboard-configuration/xkb-keymap=jp keyboard-configuration/variant=Japanese
set otheropt netboot=nfs nfsroot=${exptdirs} network-config=disabled --- quiet vga=788
set consoles dummy_console=tty0 dummy_console=ttyS0,9600
set sulogins SYSTEMD_SULOGIN_FORCE=1 dummy_init=/sbin/sulogin
set debugopt ${consoles} ${sulogins}
echo "Loading menu/booting.ipxe ..."
chain --autofree --replace ${ipxebase}/menu/booting.ipxe && exit ||
goto menu

"""
