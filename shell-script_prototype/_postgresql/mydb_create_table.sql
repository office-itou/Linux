DROP TABLE if exists public.distribution CASCADE;
CREATE TABLE public.distribution (
  version       TEXT           NOT NULL
, name          TEXT           NOT NULL
, version_id    TEXT           NOT NULL
, code_name     TEXT
, life          TEXT
, release       TEXT
, support       TEXT
, long_term     TEXT
, rhel          TEXT
, kerne         TEXT
, note          TEXT
, wallpaper     TEXT
, create_flag   TEXT
, CONSTRAINT distribution_PKC PRIMARY KEY (version)
);
GRANT SELECT,INSERT,UPDATE,DELETE ON public.distribution TO dbuser;
DROP TABLE if exists public.media CASCADE;
CREATE TABLE public.media (
  type          TEXT           NOT NULL
, entry_flag    TEXT           NOT NULL
, entry_name    TEXT           NOT NULL
, entry_disp    TEXT           NOT NULL
, version       TEXT
, latest        TEXT
, release       TEXT
, support       TEXT
, web_regexp    TEXT
, web_path      TEXT
, web_tstamp    TIMESTAMP WITH TIME ZONE
, web_size      BIGINT
, web_status    TEXT
, iso_path      TEXT
, iso_tstamp    TEXT
, iso_size      BIGINT
, iso_volume    TEXT
, rmk_path      TEXT
, rmk_tstamp    TIMESTAMP WITH TIME ZONE
, rmk_size      BIGINT
, rmk_volume    TEXT
, ldr_initrd    TEXT
, ldr_kernel    TEXT
, cfg_path      TEXT
, cfg_tstamp    TIMESTAMP WITH TIME ZONE
, lnk_path      TEXT
, create_flag   TEXT
, CONSTRAINT media_PKC PRIMARY KEY (type,entry_flag,entry_name,entry_disp)
);
GRANT SELECT,INSERT,UPDATE,DELETE ON public.media TO dbuser;
