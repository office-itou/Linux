SELECT
    public.media.type
    , public.media.entry_flag
    , public.media.entry_name
    , public.media.entry_disp
    , public.media.version
    , public.media.latest
    , public.media.release
    , public.media.support
    , public.media.web_regexp
    , public.media.web_path
    , public.media.web_tstamp
    , public.media.web_size
    , public.media.web_status
    , public.media.iso_path
    , public.media.iso_tstamp
    , public.media.iso_size
    , public.media.iso_volume
    , public.media.rmk_path
    , public.media.rmk_tstamp
    , public.media.rmk_size
    , public.media.rmk_volume
    , public.media.ldr_initrd
    , public.media.ldr_kernel
    , public.media.cfg_path
    , public.media.cfg_tstamp
    , public.media.lnk_path
    , public.media.create
FROM
    public.media
ORDER BY
    public.media.type = 'mini' DESC
    , public.media.type = 'netinst' DESC
    , public.media.type = 'dvd' DESC
    , public.media.type = 'liveinst' DESC
    , public.media.type = 'live' DESC
    , public.media.type = 'tool' DESC
    , public.media.type = 'clive' DESC
    , public.media.type = 'cnetinst' DESC
    , public.media.type = 'system' DESC
    , public.media.entry_disp != '-' DESC
    , public.media.entry_name = 'menu-entry' DESC
    , public.media.entry_name ~ 'debian-*' DESC
    , public.media.entry_name ~ 'ubuntu-*' DESC
    , public.media.entry_name ~ 'fedora-*' DESC
    , public.media.entry_name ~ 'centos-stream-*' DESC
    , public.media.entry_name ~ 'almalinux-*' DESC
    , public.media.entry_name ~ 'rockylinux-*' DESC
    , public.media.entry_name ~ 'miraclelinux-*' DESC
    , public.media.entry_name ~ 'opensuse-*' DESC
    , public.media.entry_name ~ 'windows-*' DESC
    , public.media.entry_name = 'memtest86plus' DESC
    , public.media.entry_name = 'winpe-x86' DESC
    , public.media.entry_name = 'winpe-x64' DESC
    , public.media.entry_name = 'ati2020x86' DESC
    , public.media.entry_name = 'ati2020x64' DESC
    , public.media.entry_name ~ '.*-sid'
    , public.media.entry_name ~ '.*-testing'
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 3), 3, '0')
;
