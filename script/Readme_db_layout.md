# **data base layout**

* ## **distribution information (distribution.dat)**

  ``` bash:
  #    0: version     ( 23)   TEXT            NOT NULL    
  #    1: name        ( 23)   TEXT            NOT NULL    
  #    2: version_id  ( 23)   TEXT            NOT NULL    
  #    3: code_name   ( 39)   TEXT                        
  #    4: life        ( 15)   TEXT                        
  #    5: release     ( 15)   TEXT                        
  #    6: support     ( 15)   TEXT                        
  #    7: long_term   ( 15)   TEXT                        
  #    8: rhel        ( 15)   TEXT                        
  #    9: kerne       ( 27)   TEXT                        
  #   10: note        ( 27)   TEXT                        
  #   11: wallpaper   ( 87)   TEXT                        
  #   12: create_flag ( 11)   TEXT                        
  ```

* ## **media information (media.dat)**

  ``` bash:
  #    0: type        ( 11)   TEXT            NOT NULL    media type
  #    1: entry_flag  ( 11)   TEXT            NOT NULL    [m] menu, [o] output, [else] hidden
  #    2: entry_name  ( 39)   TEXT            NOT NULL    entry name (unique)
  #    3: entry_disp  ( 39)   TEXT            NOT NULL    entry name for display
  #    4: version     ( 23)   TEXT                        version id
  #    5: latest      ( 23)   TEXT                        latest version
  #    6: release     ( 15)   TEXT                        release date
  #    7: support     ( 15)   TEXT                        support end date
  #    8: web_regexp  (143)   TEXT                        web file  regexp
  #    9: web_path    (143)   TEXT                        "         path
  #   10: web_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   11: web_size    ( 15)   BIGINT                      "         file size
  #   12: web_check   ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   13: web_status  ( 15)   TEXT                        "         download status
  #   14: iso_path    ( 87)   TEXT                        iso image file path
  #   15: iso_tstamp  ( 47)   TEXT                        "         time stamp
  #   16: iso_size    ( 15)   BIGINT                      "         file size
  #   17: iso_volume  ( 43)   TEXT                        "         volume id
  #   18: rmk_path    ( 87)   TEXT                        remaster  file path
  #   19: rmk_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   20: rmk_size    ( 15)   BIGINT                      "         file size
  #   21: rmk_volume  ( 43)   TEXT                        "         volume id
  #   22: ldr_initrd  ( 87)   TEXT                        initrd    file path
  #   23: ldr_kernel  ( 87)   TEXT                        kernel    file path
  #   24: cfg_path    ( 87)   TEXT                        config    file path
  #   25: cfg_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   26: lnk_path    ( 87)   TEXT                        symlink   directory or file path
  #   27: create_flag ( 11)   TEXT                        create flag
  ```
