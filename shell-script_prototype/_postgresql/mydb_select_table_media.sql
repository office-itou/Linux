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
FROM
    public.media 
WHERE
    public.media.entry_flag != 'x' 
    AND public.media.entry_flag != 'd' 
    AND public.media.entry_flag != 'b' 
ORDER BY
    public.media.type = 'mini.iso' DESC
    , public.media.type = 'netinst' DESC
    , public.media.type = 'dvd' DESC
    , public.media.type = 'live_install' DESC
    , public.media.type = 'live' DESC
    , public.media.type = 'tool' DESC
    , public.media.type = 'custom_live' DESC
    , public.media.type = 'custom_netinst' DESC
    , public.media.type = 'system' DESC
    , public.media.entry_disp != '-' DESC
    , public.media.version = 'menu-entry' DESC
    , public.media.version ~ 'debian-*' DESC
    , public.media.version ~ 'ubuntu-*' DESC
    , public.media.version ~ 'fedora-*' DESC
    , public.media.version ~ 'centos-stream-*' DESC
    , public.media.version ~ 'almalinux-*' DESC
    , public.media.version ~ 'rockylinux-*' DESC
    , public.media.version ~ 'miraclelinux-*' DESC
    , public.media.version ~ 'opensuse-*' DESC
    , public.media.version ~ 'windows-*' DESC
    , public.media.version = 'memtest86plus' DESC
    , public.media.version = 'winpe-x86' DESC
    , public.media.version = 'winpe-x64' DESC
    , public.media.version = 'ati2020x86' DESC
    , public.media.version = 'ati2020x64' DESC
    , public.media.version ~ '.*-sid'
    , public.media.version ~ '.*-testing'
    , public.media.version
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(public.media.latest FROM '[0-9.]+$'), '.', 3), 3, '0')
;
