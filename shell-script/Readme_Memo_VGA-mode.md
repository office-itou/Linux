# **Linux VGA mode**  
  
|screnn size| info  |  8(256) | 16(64k) | 24(16M) |  32(4G) |  mode  |  ratio  |
| --------: | :---: | :-----: | :-----: | :-----: | :-----: | :----- | :------ |
|  320x 200 | 0x000 |   800   | 782/814 |   ---   |   828   |        | (16:10) |
|  320x 240 | 0x00b |   854   |   855   |   ---   |   856   |        | (4:3)   |
|  320x 400 |       |   801   |   815   |   ---   |   829   |        |         |
|  400x 300 | 0x00c |   857   |   858   |   ---   |   859   |        | (4:3)   |
|  512x 384 | 0x00d |   860   |   861   |   ---   |   862   |        | (4:3)   |
|  640x 400 |       | 768/802 |   816   |   ---   |   830   |        |         |
|  640x 480 | 0x001 | 769/803 | 785/817 |   786   | 809/831 | VGA    | (4:3)   |
|  720x 480 | 0x012 |   878   |   879   |   ---   |   880   |        | (3:2)   |
|  720x 576 | 0x013 |   881   |   882   |   ---   |   883   |        | ()      |
|  800x 480 | 0x014 |   884   |   885   |   ---   |   886   |        | (5:3)   |
|  800x 600 | 0x002 | 771/804 | 788/818 |   789   |   832   | SVGA   | (4:3)   |
|  854x 480 | 0x00e |   863   |   864   |   ---   |   865   |        | (16:9)  |
| 1024x 768 | 0x003 | 773/805 | 791/819 |   792   | 824/833 | XGA    | (4:3)   |
| 1152x 864 | 0x005 |   806   |   820   |   ---   |   834   |        | (4:3)   |
| 1280x 720 | 0x00f |   ---   |   ---   |   ---   |   ---   | WXGA   | (16:9)  |
| 1280x 768 | 0x015 |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 1280x 800 | 0x010 |   ---   |   ---   |   ---   |   ---   |        | (16:10) |
| 1280x 960 | 0x006 |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 1280x1024 | 0x004 |   775   |   794   |   795   |   ---   | SXGA   | (5:4)   |
| 1280x1024 | 0x007 |   ---   |   ---   |   ---   |   ---   | SXGA   | (5:4)   |
| 1360x 768 | 0x00a |   ---   |   ---   |   ---   |   ---   | HD     | (16:9)  |
| 1400x1050 | 0x008 |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 1440x 900 | 0x011 |   ---   |   ---   |   ---   |   ---   | WXGA+  | (16:10) |
| 1600x1200 | 0x009 |   ---   |   ---   |   ---   |   ---   | UXGA   | (4:3)   |
| 1680x1050 |       |   ---   |   ---   |   ---   |   ---   | WSXGA+ | (16:10) |
| 1792x1344 |       |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 1856x1392 |       |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 1920x1080 |       |   ---   |   ---   |   ---   |   980   | FHD    | (16:9)  |
| 1920x1200 |       |   893   |   ---   |   ---   |   ---   | WUXGA  | (16:10) |
| 1920x1440 |       |   ---   |   ---   |   ---   |   ---   |        | (4:3)   |
| 2560x1440 |       |   ---   |   ---   |   ---   |   ---   | WQHD   | (16:9)  |
| 2560x1600 |       |   ---   |   ---   |   ---   |   ---   |        | (16:10) |
| 2880x1800 |       |   ---   |   ---   |   ---   |   ---   |        | (16:10) |
| 3840x2160 |       |   ---   |   ---   |   ---   |   ---   | 4K UHD | (16:9)  |
| 3840x2400 |       |   ---   |   ---   |   ---   |   ---   |        | (16:10) |
| 7680x4320 |       |   ---   |   ---   |   ---   |   ---   | 8K UHD | (16:9)  |
  
# ***menu resolution  
  
``` bash:
                                                            # resolution
#   declare -r    MENU_RESO="7680x4320"                     # 8K UHD (16:9)
#   declare -r    MENU_RESO="3840x2400"                     #        (16:10)
#   declare -r    MENU_RESO="3840x2160"                     # 4K UHD (16:9)
#   declare -r    MENU_RESO="2880x1800"                     #        (16:10)
#   declare -r    MENU_RESO="2560x1600"                     #        (16:10)
#   declare -r    MENU_RESO="2560x1440"                     # WQHD   (16:9)
#   declare -r    MENU_RESO="1920x1440"                     #        (4:3)
#   declare -r    MENU_RESO="1920x1200"                     # WUXGA  (16:10)
#   declare -r    MENU_RESO="1920x1080"                     # FHD    (16:9)
#   declare -r    MENU_RESO="1856x1392"                     #        (4:3)
#   declare -r    MENU_RESO="1792x1344"                     #        (4:3)
#   declare -r    MENU_RESO="1680x1050"                     # WSXGA+ (16:10)
#   declare -r    MENU_RESO="1600x1200"                     # UXGA   (4:3)
#   declare -r    MENU_RESO="1400x1050"                     #        (4:3)
#   declare -r    MENU_RESO="1440x900"                      # WXGA+  (16:10)
#   declare -r    MENU_RESO="1360x768"                      # HD     (16:9)
#   declare -r    MENU_RESO="1280x1024"                     # SXGA   (5:4)
#   declare -r    MENU_RESO="1280x960"                      #        (4:3)
#   declare -r    MENU_RESO="1280x800"                      #        (16:10)
#   declare -r    MENU_RESO="1280x768"                      #        (4:3)
#   declare -r    MENU_RESO="1280x720"                      # WXGA   (16:9)
#   declare -r    MENU_RESO="1152x864"                      #        (4:3)
    declare -r    MENU_RESO="1024x768"                      # XGA    (4:3)
#   declare -r    MENU_RESO="800x600"                       # SVGA   (4:3)
#   declare -r    MENU_RESO="640x480"                       # VGA    (4:3)

                                                            # colors
    declare -r    MENU_DPTH="8"                             # 256
#   declare -r    MENU_DPTH="16"                            # 65536
#   declare -r    MENU_DPTH="24"                            # 16 million
#   declare -r    MENU_DPTH="32"                            # 4.2 billion
```
  
# ***screen mode (vga=nnn)  
  
``` bash:
#                                                           # 7680x4320   : 8K UHD (16:9)
#                                                           # 3840x2400   :        (16:10)
#                                                           # 3840x2160   : 4K UHD (16:9)
#                                                           # 2880x1800   :        (16:10)
#                                                           # 2560x1600   :        (16:10)
#                                                           # 2560x1440   : WQHD   (16:9)
#                                                           # 1920x1440   :        (4:3)
#   declare -r    SCRN_MODE="893"                           # 1920x1200x 8: WUXGA  (16:10)
#   declare -r    SCRN_MODE=""                              #          x16
#   declare -r    SCRN_MODE=""                              #          x24
#   declare -r    SCRN_MODE=""                              #          x32
#   declare -r    SCRN_MODE=""                              # 1920x1080x 8: FHD    (16:9)
#   declare -r    SCRN_MODE=""                              #          x16
#   declare -r    SCRN_MODE=""                              #          x24
#   declare -r    SCRN_MODE="980"                           #          x32
#                                                           # 1856x1392   :        (4:3)
#                                                           # 1792x1344   :        (4:3)
#                                                           # 1680x1050   : WSXGA+ (16:10)
#                                                           # 1600x1200   : UXGA   (4:3)
#                                                           # 1400x1050   :        (4:3)
#                                                           # 1440x 900   : WXGA+  (16:10)
#                                                           # 1360x 768   : HD     (16:9)
#   declare -r    SCRN_MODE="775"                           # 1280x1024x 8: SXGA   (5:4)
#   declare -r    SCRN_MODE="794"                           #          x16
#   declare -r    SCRN_MODE="795"                           #          x24
#   declare -r    SCRN_MODE="829"                           #          x32
#                                                           # 1280x 960   :        (4:3)
#                                                           # 1280x 800   :        (16:10)
#                                                           # 1280x 768   :        (4:3)
#                                                           # 1280x 720   : WXGA   (16:9)
#                                                           # 1152x 864   :        (4:3)
#   declare -r    SCRN_MODE="773"                           # 1024x 768x 8: XGA    (4:3)
#   declare -r    SCRN_MODE="791"                           #          x16
#   declare -r    SCRN_MODE="792"                           #          x24
#   declare -r    SCRN_MODE="824"                           #          x32
#   declare -r    SCRN_MODE="771"                           #  800x 600x 8: SVGA   (4:3)
#   declare -r    SCRN_MODE="788"                           #          x16
#   declare -r    SCRN_MODE="789"                           #          x24
#   declare -r    SCRN_MODE="814"                           #          x32
#   declare -r    SCRN_MODE="769"                           #  640x 480x 8: VGA    (4:3)
#   declare -r    SCRN_MODE="785"                           #          x16
#   declare -r    SCRN_MODE="786"                           #          x24
#   declare -r    SCRN_MODE="809"                           #          x32
```
  
# ***screen mode (vga=nnn) [ VMware ]  
  
``` bash:
                                                            # Mode: Resolution:     Type
#   declare -r    SCRN_MODE="3840"                          # 0 F00   80x  25       VGA
#   declare -r    SCRN_MODE="3841"                          # 1 F01   80x  50       VGA
#   declare -r    SCRN_MODE="3842"                          # 2 F02   80x  43       VGA
#   declare -r    SCRN_MODE="3843"                          # 3 F03   80x  28       VGA
#   declare -r    SCRN_MODE="3845"                          # 4 F05   80x  30       VGA
#   declare -r    SCRN_MODE="3846"                          # 5 F06   80x  34       VGA
#   declare -r    SCRN_MODE="3847"                          # 6 F07   80x  60       VGA
#   declare -r    SCRN_MODE="768"                           # 7 300  640x 400x 8    VESA
#   declare -r    SCRN_MODE="769"                           # 8 301  640x 480x 8    VESA
#   declare -r    SCRN_MODE="771"                           # 9 303  800x 600x 8    VESA
    declare -r    SCRN_MODE="773"                           # a 305 1024x 768x 8    VESA
#   declare -r    SCRN_MODE="782"                           # b 30E  320x 200x16    VESA
#   declare -r    SCRN_MODE="785"                           # c 311  640x 480x16    VESA
#   declare -r    SCRN_MODE="788"                           # d 314  800x 600x16    VESA
#   declare -r    SCRN_MODE="791"                           # e 317 1024x 768x16    VESA
#   declare -r    SCRN_MODE="800"                           # f 320  320x 200x 8    VESA
#   declare -r    SCRN_MODE="801"                           # g 321  320x 400x 8    VESA
#   declare -r    SCRN_MODE="802"                           # h 322  640x 400x 8    VESA
#   declare -r    SCRN_MODE="803"                           # i 323  640x 480x 8    VESA
#   declare -r    SCRN_MODE="804"                           # j 324  800x 600x 8    VESA
#   declare -r    SCRN_MODE="805"                           # k 325 1024x 768x 8    VESA
#   declare -r    SCRN_MODE="806"                           # l 326 1152x 864x 8    VESA
#   declare -r    SCRN_MODE="814"                           # m 32E  320x 200x16    VESA
#   declare -r    SCRN_MODE="815"                           # n 32F  320x 400x16    VESA
#   declare -r    SCRN_MODE="816"                           # o 330  640x 400x16    VESA
#   declare -r    SCRN_MODE="817"                           # p 331  640x 480x16    VESA
#   declare -r    SCRN_MODE="818"                           # q 332  800x 600x16    VESA
#   declare -r    SCRN_MODE="819"                           # r 333 1024x 768x16    VESA
#   declare -r    SCRN_MODE="820"                           # s 334 1152x 864x16    VESA
#   declare -r    SCRN_MODE="828"                           # t 33C  320x 200x32    VESA
#   declare -r    SCRN_MODE="829"                           # u 33D  320x 400x32    VESA
#   declare -r    SCRN_MODE="830"                           # v 33E  640x 400x32    VESA
#   declare -r    SCRN_MODE="831"                           # w 33F  640x 480x32    VESA
#   declare -r    SCRN_MODE="832"                           # x 340  800x 600x32    VESA
#   declare -r    SCRN_MODE="833"                           # y 341 1024x 768x32    VESA
#   declare -r    SCRN_MODE="834"                           # z 342 1152x 864x32    VESA
#   declare -r    SCRN_MODE="854"                           # - 356  320x 240x 8    VESA
#   declare -r    SCRN_MODE="855"                           # - 357  320x 240x16    VESA
#   declare -r    SCRN_MODE="856"                           # - 358  320x 240x32    VESA
#   declare -r    SCRN_MODE="857"                           # - 359  400x 300x 8    VESA
#   declare -r    SCRN_MODE="858"                           # - 35A  400x 300x16    VESA
#   declare -r    SCRN_MODE="859"                           # - 35B  400x 300x32    VESA
#   declare -r    SCRN_MODE="860"                           # - 35C  512x 384x 8    VESA
#   declare -r    SCRN_MODE="861"                           # - 35D  512x 384x16    VESA
#   declare -r    SCRN_MODE="862"                           # - 35E  512x 384x32    VESA
#   declare -r    SCRN_MODE="863"                           # - 35F  854x 480x 8    VESA
#   declare -r    SCRN_MODE="864"                           # - 360  854x 480x16    VESA
#   declare -r    SCRN_MODE="865"                           # - 361  854x 480x32    VESA
#   declare -r    SCRN_MODE="878"                           # - 36E  720x 480x 8    VESA
#   declare -r    SCRN_MODE="879"                           # - 36F  720x 480x16    VESA
#   declare -r    SCRN_MODE="880"                           # - 370  720x 480x32    VESA
#   declare -r    SCRN_MODE="881"                           # - 371  720x 576x 8    VESA
#   declare -r    SCRN_MODE="882"                           # - 372  720x 576x16    VESA
#   declare -r    SCRN_MODE="883"                           # - 373  720x 576x32    VESA
#   declare -r    SCRN_MODE="884"                           # - 374  800x 480x 8    VESA
#   declare -r    SCRN_MODE="885"                           # - 375  800x 480x16    VESA
#   declare -r    SCRN_MODE="886"                           # - 376  800x 480x32    VESA
```
  
