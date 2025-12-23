# **data base layout**

* ## **distribution information (distribution.dat)**

  ``` bash:
  #    1: version     ( 23)   TEXT            NOT NULL    
  #    2: name        ( 23)   TEXT            NOT NULL    
  #    3: version_id  ( 23)   TEXT            NOT NULL    
  #    4: code_name   ( 39)   TEXT                        
  #    5: life        ( 15)   TEXT                        
  #    6: release     ( 15)   TEXT                        
  #    7: support     ( 15)   TEXT                        
  #    8: long_term   ( 15)   TEXT                        
  #    9: rhel        ( 15)   TEXT                        
  #   10: kerne       ( 27)   TEXT                        
  #   11: note        ( 27)   TEXT                        
  #   12: wallpaper   ( 87)   TEXT                        
  #   13: create_flag ( 11)   TEXT                        
  ```

* ## **media information (media.dat)**

  ``` bash:
  #    1: type        ( 11)   TEXT            NOT NULL    media type
  #    2: entry_flag  ( 11)   TEXT            NOT NULL    [m] menu, [o] output, [else] hidden
  #    3: entry_name  ( 39)   TEXT            NOT NULL    entry name (unique)
  #    4: entry_disp  ( 39)   TEXT            NOT NULL    entry name for display
  #    5: version     ( 23)   TEXT                        version id
  #    6: latest      ( 23)   TEXT                        latest version
  #    7: release     ( 15)   TEXT                        release date
  #    8: support     ( 15)   TEXT                        support end date
  #    9: web_regexp  (143)   TEXT                        web file  regexp
  #   10: web_path    (143)   TEXT                        "         path
  #   11: web_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   12: web_size    ( 15)   BIGINT                      "         file size
  #   13: web_check   ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   14: web_status  ( 15)   TEXT                        "         download status
  #   15: iso_path    ( 87)   TEXT                        iso image file path
  #   16: iso_tstamp  ( 47)   TEXT                        "         time stamp
  #   17: iso_size    ( 15)   BIGINT                      "         file size
  #   18: iso_volume  ( 43)   TEXT                        "         volume id
  #   19: rmk_path    ( 87)   TEXT                        remaster  file path
  #   20: rmk_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   21: rmk_size    ( 15)   BIGINT                      "         file size
  #   22: rmk_volume  ( 43)   TEXT                        "         volume id
  #   23: ldr_initrd  ( 87)   TEXT                        initrd    file path
  #   24: ldr_kernel  ( 87)   TEXT                        kernel    file path
  #   25: cfg_path    ( 87)   TEXT                        config    file path
  #   26: cfg_tstamp  ( 47)   TIMESTAMP WITH TIME ZONE    "         time stamp
  #   27: lnk_path    ( 87)   TEXT                        symlink   directory or file path
  #   28: create_flag ( 11)   TEXT                        create flag
  ```
