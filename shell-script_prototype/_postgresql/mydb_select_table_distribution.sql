SELECT
    * 
FROM
    distribution 
ORDER BY
      distribution.version ~ 'debian-*' DESC
    , distribution.version ~ 'ubuntu-*' DESC
    , distribution.version ~ 'fedora-*' DESC
    , distribution.version ~ 'centos-[0-9]+-*' DESC
    , distribution.version ~ 'centos-stream-*' DESC
    , distribution.version ~ 'almalinux-*' DESC
    , distribution.version ~ 'rockylinux-*' DESC
    , distribution.version ~ 'miraclelinux-*' DESC
    , distribution.version ~ 'opensuse-*' DESC
    , distribution.version ~ 'windows-*' DESC
    , distribution.version ~ 'memtest86plus' DESC
    , distribution.version ~ 'winpe-x64' DESC
    , distribution.version ~ 'winpe-x86' DESC
    , distribution.version ~ 'ati2020x64' DESC
    , distribution.version ~ 'ati2020x86' DESC
    , distribution.version ~ regexp_replace(distribution.version, '[0-9].*$', '')
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 1), 3, '0') 
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 2), 3, '0') 
    , LPAD(SPLIT_PART(SubString(regexp_replace(distribution.version, '^[^0-9]+', ' ') FROM '[0-9.]+$'), '.', 3), 3, '0') 
;
