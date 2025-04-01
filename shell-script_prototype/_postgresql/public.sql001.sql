SELECT
    m.type
    , m.entry_flag
    , m.entry_name
    , m.entry_disp
    , m.version
    , d.version AS latest
    , d.release
    , d.support
    , m.web_url
    , m.web_tstamp
    , m.web_size
    , m.web_status
    , m.iso_path
    , m.iso_tstamp
    , m.iso_size
    , m.iso_volume
    , m.rmk_path
    , m.rmk_tstamp
    , m.rmk_size
    , m.rmk_volume
    , m.ldr_initrd
    , m.ldr_kernel
    , m.cfg_path
    , m.cfg_tstamp
    , lnk_path
FROM
    media AS m
    LEFT JOIN distribution AS d
        ON d.version = (
            SELECT
                s.version
            FROM
                distribution AS s
            WHERE LENGTH(m.version) > 0 AND
                s.version SIMILAR TO '%' || m.version || '\.*.*%'
            ORDER BY
                LPAD(SPLIT_PART(SubString(regexp_replace(regexp_replace(s.version, '-', '.', 'g'), '^[^0-9]+', '') FROM '[0-9.]+$'), '.', 1), 3, '0') DESC
              , LPAD(SPLIT_PART(SubString(regexp_replace(regexp_replace(s.version, '-', '.', 'g'), '^[^0-9]+', '') FROM '[0-9.]+$'), '.', 2), 3, '0') DESC
              , LPAD(SPLIT_PART(SubString(regexp_replace(regexp_replace(s.version, '-', '.', 'g'), '^[^0-9]+', '') FROM '[0-9.]+$'), '.', 3), 3, '0') DESC
            LIMIT
                1
        )
ORDER BY type,latest,entry_flag
