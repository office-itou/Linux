# **function**  
  
## **list of functions**  
  
### **skeleton**  
  
|                                          shell file name                                          |                                                     function name                                                     |                                  explanation                                  |
| :------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| [skel_mk_custom_iso.sh](./skel_mk_custom_iso.sh)                                                  | funcInitialization                                                                                                    |                                                                               |
|                                                                                                   | funcDebug_parameter                                                                                                   |                                                                               |
|                                                                                                   | funcHelp                                                                                                              |                                                                               |
|                                                                                                   | funcMain                                                                                                              |                                                                               |
| [skel_mk_pxeboot_conf.sh](./skel_mk_pxeboot_conf.sh)                                              | funcInitialization                                                                                                    |                                                                               |
|                                                                                                   | funcDebug_parameter                                                                                                   |                                                                               |
|                                                                                                   | funcHelp                                                                                                              |                                                                               |
|                                                                                                   | funcMain                                                                                                              |                                                                               |
| [skel_test_function.sh](./skel_test_function.sh)                                                  | funcTrap                                                                                                              |                                                                               |
|                                                                                                   | funcInitialization                                                                                                    |                                                                               |
|                                                                                                   | funcDebug_parameter                                                                                                   |                                                                               |
|                                                                                                   | funcHelp                                                                                                              |                                                                               |
|                                                                                                   | funcMain                                                                                                              |                                                                               |
  
### **template**  
  
|                                          shell file name                                          |                                                     function name                                                     |                                  explanation                                  |
| :------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| [tmpl_001_initialize_common.sh](./tmpl_001_initialize_common.sh)                                  | [funcTrap](#trap)                                                                                                     | trap                                                                          |
| [tmpl_001_initialize_mk_custom_iso.sh](./tmpl_001_initialize_mk_custom_iso.sh)                    |                                                                                                                       |                                                                               |
| [tmpl_001_initialize_mk_pxeboot_conf.sh](./tmpl_001_initialize_mk_pxeboot_conf.sh)                |                                                                                                                       |                                                                               |
| [tmpl_001_initialize_test_function.sh](./tmpl_001_initialize_test_function.sh)                    |                                                                                                                       |                                                                               |
| [tmpl_002_data_section.sh](./tmpl_002_data_section.sh)                                            |                                                                                                                       |                                                                               |
| [tmpl_003_function_section_library.sh](./tmpl_003_function_section_library.sh)                    | [funcIsNumeric](#is-numeric) "\$1"                                                                                    | is numeric                                                                    |
|                                                                                                   | [funcSubstr](#substr) "\$1" "\$2" "\$3"                                                                               | substr                                                                        |
|                                                                                                   | [funcString](#string-output) "\$1" "\$2"                                                                              | string output                                                                 |
|                                                                                                   | [funcDateDiff](#date-diff) "\$1" "\$2"                                                                                | date diff                                                                     |
|                                                                                                   | [funcPrintf](#print-with-screen-control) "\$@"                                                                        | print with screen control                                                     |
| [tmpl_003_function_section_library_initrd.sh](./tmpl_003_function_section_library_initrd.sh)      | [funcXcpio](#extract-a-compressed-cpio) "\$1" "\$2" "\$@"                                                             | extract a compressed cpio                                                     |
|                                                                                                   | [funcReadhex](#read-bytes-out-of-a-file-checking-that-they-are-valid-hex-digits) "\$1" "\$2" "\$3"                    | read bytes out of a file, checking that they are valid hex digits             |
|                                                                                                   | [funcCheckzero](#check-for-a-zero-byte-in-a-file) "\$1" "\$2"                                                         | check for a zero byte in a file                                               |
|                                                                                                   | [funcSplit_initramfs](#split-an-initramfs-into-target-files-and-call-funcxcpio-on-each) "\$1" "\$2"                   | split an initramfs into target files and call funcxcpio on each               |
| [tmpl_003_function_section_library_media.sh](./tmpl_003_function_section_library_media.sh)        | [funcUnit_conversion](#unit-conversion) "\$1" "\$2"                                                                   | unit conversion                                                               |
|                                                                                                   | [funcGetVolID](#get-volume-id) "\$1" "\$2"                                                                            | get volume id                                                                 |
|                                                                                                   | [funcGetFileinfo](#get-file-information) "\$1" "\$2"                                                                  | get file information                                                          |
|                                                                                                   | [funcDistro2efi](#distro-to-efi-image-file-name) "\$1"                                                                | distro to efi image file name                                                 |
| [tmpl_003_function_section_library_mkiso.sh](./tmpl_003_function_section_library_mkiso.sh)        | [funcCreate_iso](#create-iso-image) "\$1" "\$2" "\$@"                                                                 | create iso image                                                              |
| [tmpl_003_function_section_library_network.sh](./tmpl_003_function_section_library_network.sh)    | [funcIPv4GetNetmask](#ipv4-netmask-conversion-netmask-and-cidr-conversion) "\$1"                                      | IPv4 netmask conversion (netmask and cidr conversion)                         |
|                                                                                                   | [funcIPv6GetFullAddr](#ipv6-full-address) "\$1"                                                                       | IPv6 full address                                                             |
|                                                                                                   | [funcIPv6GetRevAddr](#ipv6-reverse-address) "\$1"                                                                     | IPv6 reverse address                                                          |
| [tmpl_003_function_section_library_web_tool.sh](./tmpl_003_function_section_library_web_tool.sh)  | [funcGetWeb_contents](#get-web-contents) "\$1" "\$2"                                                                  | get web contents                                                              |
|                                                                                                   | [funcGetWeb_header](#get-web-header) "\$1" "\$2"                                                                      | get web header                                                                |
|                                                                                                   | [funcGetWeb_address](#get-web-address-completion) "\$1" "\$2"                                                         | get web address completion                                                    |
|                                                                                                   | [funcGetWeb_info](#get-web-information) "\$1" "\$2"                                                                   | get web information                                                           |
|                                                                                                   | [funcGetWeb_status](#get-web-status-message) "\$1"                                                                    | get web status message                                                        |
| [tmpl_004_function_section_common.sh](./tmpl_004_function_section_common.sh)                      | [funcInitialization](#initialization)                                                                                 | initialization                                                                |
|                                                                                                   | [funcCreate_conf](#create-common-configuration-file)                                                                  | create common configuration file                                              |
|                                                                                                   | [funcGet_media_data](#get-media-data)                                                                                 | get media data                                                                |
|                                                                                                   | [funcPut_media_data](#put-media-data)                                                                                 | put media data                                                                |
|                                                                                                   | [funcCreate_directory](#create-directory) "\$1" "\$@"                                                                 | create directory                                                              |
|                                                                                                   | [funcCreate_preseed](#create-preseedcfg) "\$1"                                                                        | create preseed.cfg                                                            |
|                                                                                                   | [funcCreate_nocloud](#create-nocloud) "\$1"                                                                           | create nocloud                                                                |
|                                                                                                   | [funcCreate_kickstart](#create-kickstartcfg) "\$1"                                                                    | create kickstart.cfg                                                          |
|                                                                                                   | [funcCreate_autoyast](#create-autoyastxml) "\$1"                                                                      | create autoyast.xml                                                           |
|                                                                                                   | [funcCreate_precon](#create-pre-configuration-file-templates) "\$1" "\$@"                                             | create pre-configuration file templates                                       |
| [tmpl_005_function_section_common.sh](./tmpl_005_function_section_common.sh)                      | [funcPrint_menu](#print-out-of-menu) "\$1" "\$2" "\$3" "\$@"                                                          | print out of menu                                                             |
| [tmpl_005_function_section_mk_custom_iso.sh](./tmpl_005_function_section_mk_custom_iso.sh)        | [funcRemastering_preseed](#create-a-boot-option-for-preseed-of-the-remaster) "\$@"                                    | create a boot option for preseed of the remaster                              |
|                                                                                                   | [funcRemastering_nocloud](#create-a-boot-option-for-nocloud-of-the-remaster) "\$@"                                    | create a boot option for nocloud of the remaster                              |
|                                                                                                   | [funcRemastering_kickstart](#create-a-boot-option-for-kickstart-of-the-remaster) "\$@"                                | create a boot option for kickstart of the remaster                            |
|                                                                                                   | [funcRemastering_autoyast](#create-a-boot-option-for-autoyast-of-the-remaster) "\$@"                                  | create a boot option for autoyast of the remaster                             |
|                                                                                                   | [funcRemastering_boot_options](#create-a-boot-option-of-the-remaster) "\$@"                                           | create a boot option of the remaster                                          |
|                                                                                                   | [funcRemastering_path](#create-path-for-configuration-file) "\$1" "\$2"                                               | create path for configuration file                                            |
|                                                                                                   | [funcRemastering_isolinux_autoinst_cfg](#create-autoinstall-configuration-file-for-isolinux) "\$1" "\$2" "\$3" "\$@"  | create autoinstall configuration file for isolinux                            |
|                                                                                                   | [funcRemastering_isolinux](#editing-isolinux-for-autoinstall) "\$1" "\$2" "\$@"                                       | editing isolinux for autoinstall                                              |
|                                                                                                   | [funcRemastering_grub_autoinst_cfg](#create-autoinstall-configuration-file-for-grub) "\$1" "\$2" "\$3" "\$@"          | create autoinstall configuration file for grub                                |
|                                                                                                   | [funcRemastering_grub](#editing-grub-for-autoinstall) "\$1" "\$2" "\$@"                                               | editing grub for autoinstall                                                  |
|                                                                                                   | [funcRemastering_copy](#copy-auto-install-files) "\$1" "\$@"                                                          | copy auto-install files                                                       |
|                                                                                                   | [funcRemastering_initrd](#remastering-for-initrd) "\$1" "\$@"                                                         | remastering for initrd                                                        |
|                                                                                                   | [funcRemastering_media](#remastering-for-media) "\$1" "\$@"                                                           | remastering for media                                                         |
|                                                                                                   | [funcRemastering](#remastering) "\$@"                                                                                 | remastering                                                                   |
|                                                                                                   | [funcExec_download](#executing-the-download) "\$1" "\$@"                                                              | executing the download                                                        |
|                                                                                                   | [funcExec_remastering](#executing-the-remastering) "\$1" "\$@"                                                        | executing the remastering                                                     |
|                                                                                                   | funcXXX                                                                                                               |                                                                               |
| [tmpl_005_function_section_mk_pxeboot_conf.sh](./tmpl_005_function_section_mk_pxeboot_conf.sh)    | [funcPxeboot_copy](#file-copy) "\$1" "\$2"                                                                            | file copy                                                                     |
|                                                                                                   | [funcPxeboot_preseed](#create-a-boot-option-for-preseed-of-the-pxeboot) "\$@"                                         | create a boot option for preseed of the pxeboot                               |
|                                                                                                   | [funcPxeboot_nocloud](#create-a-boot-option-for-nocloud-of-the-pxeboot) "\$@"                                         | create a boot option for nocloud of the pxeboot                               |
|                                                                                                   | [funcPxeboot_kickstart](#create-a-boot-option-for-kickstart-of-the-pxeboot) "\$@"                                     | create a boot option for kickstart of the pxeboot                             |
|                                                                                                   | [funcPxeboot_autoyast](#create-a-boot-option-for-autoyast-of-the-pxeboot) "\$@"                                       | create a boot option for autoyast of the pxeboot                              |
|                                                                                                   | [funcPxeboot_boot_options](#create-a-boot-option-of-the-pxeboot) "\$@"                                                | create a boot option of the pxeboot                                           |
|                                                                                                   | [funcPxeboot_ipxe](#create-autoexecipxe) "\$1" "\$2" "\$@"                                                            | create autoexec.ipxe                                                          |
|                                                                                                   | [funcPxeboot_grub](#create-grubcfg) "\$1" "\$2" "\$@"                                                                 | create grub.cfg                                                               |
|                                                                                                   | [funcPxeboot_slnx](#create-bios-mode) "\$1" "\$2" "\$@"                                                               | create bios mode                                                              |
|                                                                                                   | [funcPxeboot](#create-pxeboot-menu)                                                                                   | create pxeboot menu                                                           |
| [tmpl_005_function_section_test_function.sh](./tmpl_005_function_section_test_function.sh)        | funcServiceStatus                                                                                                     |                                                                               |
|                                                                                                   | funcIsPackage                                                                                                         |                                                                               |
|                                                                                                   | funcDiff                                                                                                              |                                                                               |
|                                                                                                   | funcCurl                                                                                                              |                                                                               |
|                                                                                                   | funcDebug_color                                                                                                       |                                                                               |
|                                                                                                   | funcDebug_function                                                                                                    |                                                                               |
  
### **tmpl_001_initialize_common.sh**  
  
* * *
  
#### trap  
  
*funcTrap*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### is numeric  
  
*funcIsNumeric "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        |                        | =0 (numer)                                 |
| "      |        |                        | !0 (not number)                            |
  
* * *
  
#### substr  
  
*funcSubstr "\$1" "\$2" "\$3"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| input  | $2     | starting position      |                                            |
| input  | $3     | number of characters   |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### string output  
  
*funcString "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | number of characters   |                                            |
| input  | $2     | output character       |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### date diff  
  
*funcDateDiff "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | date 1                 |                                            |
| input  | $2     | date 2                 |                                            |
| output | stdout |                        |   0 ($1 = $2)                              |
| "      |        |                        |   1 ($1 < $2)                              |
| "      |        |                        |  -1 ($1 > $2)                              |
| "      |        |                        | emp (error)                                |
| return |        | status                 |                                            |
  
* * *
  
#### print with screen control  
  
*funcPrintf "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### extract a compressed cpio  
  
*funcXcpio "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| input  | $@     | cpio options           |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### read bytes out of a file, checking that they are valid hex digits  
  
*funcReadhex "\$1" "\$2" "\$3"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | skip bytes             |                                            |
| input  | $3     | count bytes            |                                            |
| output | stdout | result                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### check for a zero byte in a file  
  
*funcCheckzero "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | skip bytes             |                                            |
| output | stdout | unused                 |                                            |
| return |        | status                 |                                            |
  
* * *
  
#### split an initramfs into target files and call funcxcpio on each  
  
*funcSplit_initramfs "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### unit conversion  
  
*funcUnit_conversion "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | value with units                           |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get volume id  
  
*funcGetVolID "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | volume id                                  |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get file information  
  
*funcGetFileinfo "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size vol-id                   |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### distro to efi image file name  
  
*funcDistro2efi "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create iso image  
  
*funcCreate_iso "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | output path            |                                            |
| input  | $@     | xorrisofs options      |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### IPv4 netmask conversion (netmask and cidr conversion)  
  
*funcIPv4GetNetmask "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### IPv6 full address  
  
*funcIPv6GetFullAddr "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### IPv6 reverse address  
  
*funcIPv6GetRevAddr "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web contents  
  
*funcGetWeb_contents "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | output path            |                                            |
| input  | $2     | url                    |                                            |
| output | stdout | message                |                                            |
| return |        | status                 |                                            |
  
* * *
  
#### get web header  
  
*funcGetWeb_header "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size status contents          |
| input  | $2     | url                    |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web address completion  
  
*funcGetWeb_address "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | address completion path                    |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web information  
  
*funcGetWeb_info "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size status contents          |
| input  | $2     | url                    |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web status message  
  
*funcGetWeb_status "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### initialization  
  
*funcInitialization*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create common configuration file  
  
*funcCreate_conf*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get media data  
  
*funcGet_media_data*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### put media data  
  
*funcPut_media_data*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create directory  
  
*funcCreate_directory "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $@     | input vale             |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create preseed.cfg  
  
*funcCreate_preseed "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create nocloud  
  
*funcCreate_nocloud "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create kickstart.cfg  
  
*funcCreate_kickstart "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoyast.xml  
  
*funcCreate_autoyast "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create pre-configuration file templates  
  
*funcCreate_precon "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $@     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### print out of menu  
  
*funcPrint_menu "\$1" "\$2" "\$3" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $2     | command type           |                                            |
| input  | $3     | target range           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for preseed of the remaster  
  
*funcRemastering_preseed "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for nocloud of the remaster  
  
*funcRemastering_nocloud "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for kickstart of the remaster  
  
*funcRemastering_kickstart "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for autoyast of the remaster  
  
*funcRemastering_autoyast "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option of the remaster  
  
*funcRemastering_boot_options "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create path for configuration file  
  
*funcRemastering_path "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target path            |                                            |
| input  | $2     | directory              |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoinstall configuration file for isolinux  
  
*funcRemastering_isolinux_autoinst_cfg "\$1" "\$2" "\$3" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | file name              | autoinst.cfg                               |
| input  | $3     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### editing isolinux for autoinstall  
  
*funcRemastering_isolinux "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoinstall configuration file for grub  
  
*funcRemastering_grub_autoinst_cfg "\$1" "\$2" "\$3" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | file name              | autoinst.cfg                               |
| input  | $3     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### editing grub for autoinstall  
  
*funcRemastering_grub "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### copy auto-install files  
  
*funcRemastering_copy "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering for initrd  
  
*funcRemastering_initrd "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering for media  
  
*funcRemastering_media "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering  
  
*funcRemastering "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the download  
  
*funcExec_download "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the remastering  
  
*funcExec_remastering "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### no items  
  
*funcXXX "\$1" "\$2" "\$3" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $2     | command type           |                                            |
| input  | $3     | target range           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### file copy  
  
*funcPxeboot_copy "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for preseed of the pxeboot  
  
*funcPxeboot_preseed "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for nocloud of the pxeboot  
  
*funcPxeboot_nocloud "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for kickstart of the pxeboot  
  
*funcPxeboot_kickstart "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for autoyast of the pxeboot  
  
*funcPxeboot_autoyast "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option of the pxeboot  
  
*funcPxeboot_boot_options "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoexec.ipxe  
  
*funcPxeboot_ipxe "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create grub.cfg  
  
*funcPxeboot_grub "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create bios mode  
  
*funcPxeboot_slnx "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create pxeboot menu  
  
*funcPxeboot*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### no items  
  
*funcServiceStatus*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
  
* * *
  
#### no items  
  
*funcIsPackage*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
  
* * *
  
#### no items  
  
*funcDiff*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
  
* * *
  
#### no items  
  
*funcCurl*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
  
* * *
  
#### no items  
  
*funcDebug_color*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
  
* * *
  
#### no items  
  
*funcDebug_function*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
