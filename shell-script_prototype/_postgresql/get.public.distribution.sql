SELECT
    public.distribution.version
    , public.distribution.name
    , public.distribution.version_id
    , public.distribution.code_name
    , public.distribution.life
    , public.distribution.release
    , public.distribution.support
    , public.distribution.long_term
    , public.distribution.rhel
    , public.distribution.kerne
    , public.distribution.note
FROM
    public.distribution
ORDER BY
      public.distribution.version ~ 'debian-*'       DESC
    , public.distribution.version ~ 'ubuntu-*'       DESC
    , public.distribution.version ~ 'fedora-*'       DESC
    , public.distribution.version ~ 'centos-*'       DESC
    , public.distribution.version ~ 'almalinux-*'    DESC
    , public.distribution.version ~ 'rockylinux-*'   DESC
    , public.distribution.version ~ 'miraclelinux-*' DESC
    , public.distribution.version ~ 'opensuse-*'     DESC
    , public.distribution.version ~ 'windows-*'      DESC
    , public.distribution.version ~ 'memtest86plus'  DESC
    , public.distribution.version ~ 'winpe-x64'      DESC
    , public.distribution.version ~ 'winpe-x86'      DESC
    , public.distribution.version ~ 'ati2020x64'     DESC
    , public.distribution.version ~ 'ati2020x86'     DESC
    , public.distribution.version ~ regexp_replace(public.distribution.version, '[0-9].*$', '') DESC
    , LPAD(SPLIT_PART(SubString(regexp_replace(public.distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(public.distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0')
    , LPAD(SPLIT_PART(SubString(regexp_replace(public.distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0')
