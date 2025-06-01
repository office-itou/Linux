# **function**  
  
## **list of functions**  
  
### **skeleton**  
  
|                                          shell file name                                          |                                                     function name                                                     |                                  explanation                                  |
| :------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| [skel_mk_custom_iso.sh](./skel_mk_custom_iso.sh)                                                  | [fnInitialization](#initialization-for-skel_mk_custom_isosh-dummy)                                                    | initialization for skel_mk_custom_iso.sh (dummy)                              |
|                                                                                                   | [fnDebug_parameter](#debug-out-parameter-for-skel_mk_custom_isosh)                                                    | debug out parameter for skel_mk_custom_iso.sh                                 |
|                                                                                                   | [fnHelp](#help-for-skel_mk_custom_isosh)                                                                              | help for skel_mk_custom_iso.sh                                                |
|                                                                                                   | [fnMain](#main-for-skel_mk_custom_isosh) "\$@"                                                                        | main for skel_mk_custom_iso.sh                                                |
| [skel_mk_pxeboot_conf.sh](./skel_mk_pxeboot_conf.sh)                                              | [fnInitialization](#initialization-for-skel_mk_pxeboot_confsh-dummy)                                                  | initialization for skel_mk_pxeboot_conf.sh (dummy)                            |
|                                                                                                   | [fnDebug_parameter](#debug-out-parameter-for-skel_mk_pxeboot_confsh)                                                  | debug out parameter for skel_mk_pxeboot_conf.sh                               |
|                                                                                                   | [fnHelp](#help-for-skel_mk_pxeboot_confsh)                                                                            | help for skel_mk_pxeboot_conf.sh                                              |
|                                                                                                   | [fnMain](#main-for-skel_mk_pxeboot_confsh) "\$@"                                                                      | main for skel_mk_pxeboot_conf.sh                                              |
| [skel_test_function.sh](./skel_test_function.sh)                                                  | [fnInitialization](#initialization-for-skel_test_functionsh-dummy)                                                    | initialization for skel_test_function.sh (dummy)                              |
|                                                                                                   | [fnDebug_parameter](#debug-out-parameter-for-skel_test_functionsh)                                                    | debug out parameter for skel_test_function.sh                                 |
|                                                                                                   | [fnHelp](#help-for-skel_test_functionsh)                                                                              | help for skel_test_function.sh                                                |
|                                                                                                   | [fnMain](#main-for-skel_test_functionsh) "\$@"                                                                        | main for skel_test_function.sh                                                |
  
### **template**  
  
|                                          shell file name                                          |                                                     function name                                                     |                                  explanation                                  |
| :------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------- |
| [tmpl_001_initialize_common.sh](./tmpl_001_initialize_common.sh)                                  | [fnTrap](#trap)                                                                                                       | trap                                                                          |
| [tmpl_001_initialize_mk_custom_iso.sh](./tmpl_001_initialize_mk_custom_iso.sh)                    |                                                                                                                       |                                                                               |
| [tmpl_001_initialize_mk_pxeboot_conf.sh](./tmpl_001_initialize_mk_pxeboot_conf.sh)                |                                                                                                                       |                                                                               |
| [tmpl_001_initialize_test_function.sh](./tmpl_001_initialize_test_function.sh)                    |                                                                                                                       |                                                                               |
| [tmpl_002_data_section.sh](./tmpl_002_data_section.sh)                                            |                                                                                                                       |                                                                               |
| [tmpl_003_function_section_library.sh](./tmpl_003_function_section_library.sh)                    | [fnDebugout](#debug-print) "\$@"                                                                                      | debug print                                                                   |
|                                                                                                   | [fnDebug_parameter_list](#print-out-of-internal-variables)                                                            | print out of internal variables                                               |
|                                                                                                   | [fnIsNumeric](#is-numeric) "\$1"                                                                                      | is numeric                                                                    |
|                                                                                                   | [fnSubstr](#substr) "\$1" "\$2" "\$3"                                                                                 | substr                                                                        |
|                                                                                                   | [fnString](#string-output) "\$1" "\$2"                                                                                | string output                                                                 |
|                                                                                                   | [fnLtrim](#ltrim) "\$1"                                                                                               | ltrim                                                                         |
|                                                                                                   | [fnRtrim](#rtrim) "\$1"                                                                                               | rtrim                                                                         |
|                                                                                                   | [fnTrim](#trim) "\$1"                                                                                                 | trim                                                                          |
|                                                                                                   | [fnDateDiff](#date-diff) "\$1" "\$2"                                                                                  | date diff                                                                     |
|                                                                                                   | [fnCenter](#print-with-centering) "\$1" "\$2"                                                                         | print with centering                                                          |
|                                                                                                   | [fnPrintf](#print-with-screen-control) "\$@"                                                                          | print with screen control                                                     |
| [tmpl_003_function_section_library_initrd.sh](./tmpl_003_function_section_library_initrd.sh)      | [fnXcpio](#extract-a-compressed-cpio) "\$1" "\$2" "\$@"                                                               | extract a compressed cpio                                                     |
|                                                                                                   | [fnReadhex](#read-bytes-out-of-a-file-checking-that-they-are-valid-hex-digits) "\$1" "\$2" "\$3"                      | read bytes out of a file, checking that they are valid hex digits             |
|                                                                                                   | [fnCheckzero](#check-for-a-zero-byte-in-a-file) "\$1" "\$2"                                                           | check for a zero byte in a file                                               |
|                                                                                                   | [fnSplit_initramfs](#split-an-initramfs-into-target-files-and-call-funcxcpio-on-each) "\$1" "\$2"                     | split an initramfs into target files and call funcxcpio on each               |
| [tmpl_003_function_section_library_media.sh](./tmpl_003_function_section_library_media.sh)        | [fnUnit_conversion](#unit-conversion) "\$1" "\$2"                                                                     | unit conversion                                                               |
|                                                                                                   | [fnGetVolID](#get-volume-id) "\$1" "\$2"                                                                              | get volume id                                                                 |
|                                                                                                   | [fnGetFileinfo](#get-file-information) "\$1" "\$2"                                                                    | get file information                                                          |
|                                                                                                   | [fnDistro2efi](#distro-to-efi-image-file-name) "\$1"                                                                  | distro to efi image file name                                                 |
| [tmpl_003_function_section_library_mkiso.sh](./tmpl_003_function_section_library_mkiso.sh)        | [fnCreate_iso](#create-iso-image) "\$1" "\$2" "\$@"                                                                   | create iso image                                                              |
| [tmpl_003_function_section_library_network.sh](./tmpl_003_function_section_library_network.sh)    | [fnIPv4GetNetmask](#ipv4-netmask-conversion-netmask-and-cidr-conversion) "\$1"                                        | IPv4 netmask conversion (netmask and cidr conversion)                         |
|                                                                                                   | [fnIPv6GetFullAddr](#ipv6-full-address) "\$1"                                                                         | IPv6 full address                                                             |
|                                                                                                   | [fnIPv6GetRevAddr](#ipv6-reverse-address) "\$1"                                                                       | IPv6 reverse address                                                          |
| [tmpl_003_function_section_library_web_tool.sh](./tmpl_003_function_section_library_web_tool.sh)  | [fnGetWeb_contents](#get-web-contents) "\$1" "\$2"                                                                    | get web contents                                                              |
|                                                                                                   | [fnGetWeb_header](#get-web-header) "\$1" "\$2"                                                                        | get web header                                                                |
|                                                                                                   | [fnGetWeb_address](#get-web-address-completion) "\$1" "\$2"                                                           | get web address completion                                                    |
|                                                                                                   | [fnGetWeb_info](#get-web-information) "\$1" "\$2"                                                                     | get web information                                                           |
|                                                                                                   | [fnGetWeb_status](#get-web-status-message) "\$1"                                                                      | get web status message                                                        |
| [tmpl_004_function_section_common.sh](./tmpl_004_function_section_common.sh)                      | [fnInitialization](#initialization)                                                                                   | initialization                                                                |
|                                                                                                   | [fnCreate_conf](#create-common-configuration-file)                                                                    | create common configuration file                                              |
|                                                                                                   | [fnGet_media_data](#get-media-data)                                                                                   | get media data                                                                |
|                                                                                                   | [fnPut_media_data](#put-media-data)                                                                                   | put media data                                                                |
|                                                                                                   | [fnCreate_directory](#create-directory) "\$1" "\$@"                                                                   | create directory                                                              |
|                                                                                                   | [fnCreate_preseed](#create-preseedcfg) "\$1"                                                                          | create preseed.cfg                                                            |
|                                                                                                   | [fnCreate_nocloud](#create-nocloud) "\$1"                                                                             | create nocloud                                                                |
|                                                                                                   | [fnCreate_kickstart](#create-kickstartcfg) "\$1"                                                                      | create kickstart.cfg                                                          |
|                                                                                                   | [fnCreate_autoyast](#create-autoyastxml) "\$1"                                                                        | create autoyast.xml                                                           |
|                                                                                                   | [fnCreate_precon](#create-pre-configuration-file-templates) "\$1" "\$@"                                               | create pre-configuration file templates                                       |
| [tmpl_005_function_section_mk_custom_iso.sh](./tmpl_005_function_section_mk_custom_iso.sh)        | [fnRemastering_preseed](#create-a-boot-option-for-preseed-of-the-remaster) "\$@"                                      | create a boot option for preseed of the remaster                              |
|                                                                                                   | [fnRemastering_nocloud](#create-a-boot-option-for-nocloud-of-the-remaster) "\$@"                                      | create a boot option for nocloud of the remaster                              |
|                                                                                                   | [fnRemastering_kickstart](#create-a-boot-option-for-kickstart-of-the-remaster) "\$@"                                  | create a boot option for kickstart of the remaster                            |
|                                                                                                   | [fnRemastering_autoyast](#create-a-boot-option-for-autoyast-of-the-remaster) "\$@"                                    | create a boot option for autoyast of the remaster                             |
|                                                                                                   | [fnRemastering_boot_options](#create-a-boot-option-of-the-remaster) "\$@"                                             | create a boot option of the remaster                                          |
|                                                                                                   | [fnRemastering_path](#create-path-for-configuration-file) "\$1" "\$2"                                                 | create path for configuration file                                            |
|                                                                                                   | [fnRemastering_isolinux_autoinst_cfg](#create-autoinstall-configuration-file-for-isolinux) "\$1" "\$2" "\$3" "\$@"    | create autoinstall configuration file for isolinux                            |
|                                                                                                   | [fnRemastering_isolinux](#editing-isolinux-for-autoinstall) "\$1" "\$2" "\$@"                                         | editing isolinux for autoinstall                                              |
|                                                                                                   | [fnRemastering_grub_autoinst_cfg](#create-autoinstall-configuration-file-for-grub) "\$1" "\$2" "\$3" "\$@"            | create autoinstall configuration file for grub                                |
|                                                                                                   | [fnRemastering_grub](#editing-grub-for-autoinstall) "\$1" "\$2" "\$@"                                                 | editing grub for autoinstall                                                  |
|                                                                                                   | [fnRemastering_copy](#copy-auto-install-files) "\$1" "\$@"                                                            | copy auto-install files                                                       |
|                                                                                                   | [fnRemastering_initrd](#remastering-for-initrd) "\$1" "\$@"                                                           | remastering for initrd                                                        |
|                                                                                                   | [fnRemastering_media](#remastering-for-media) "\$1" "\$@"                                                             | remastering for media                                                         |
|                                                                                                   | [fnRemastering](#remastering) "\$@"                                                                                   | remastering                                                                   |
|                                                                                                   | [fnExec_menu](#print-out-of-menu) "\$1" "\$@"                                                                         | print out of menu                                                             |
|                                                                                                   | [fnExec_download](#executing-the-download) "\$1" "\$@"                                                                | executing the download                                                        |
|                                                                                                   | [fnExec_remastering](#executing-the-remastering) "\$1" "\$@"                                                          | executing the remastering                                                     |
|                                                                                                   | [fnExec](#executing-the-action) "\$1" "\$@"                                                                           | executing the action                                                          |
| [tmpl_005_function_section_mk_pxeboot_conf.sh](./tmpl_005_function_section_mk_pxeboot_conf.sh)    | [fnPxeboot_copy](#file-copy) "\$1" "\$2"                                                                              | file copy                                                                     |
|                                                                                                   | [fnPxeboot_preseed](#create-a-boot-option-for-preseed-of-the-pxeboot) "\$@"                                           | create a boot option for preseed of the pxeboot                               |
|                                                                                                   | [fnPxeboot_nocloud](#create-a-boot-option-for-nocloud-of-the-pxeboot) "\$@"                                           | create a boot option for nocloud of the pxeboot                               |
|                                                                                                   | [fnPxeboot_kickstart](#create-a-boot-option-for-kickstart-of-the-pxeboot) "\$@"                                       | create a boot option for kickstart of the pxeboot                             |
|                                                                                                   | [fnPxeboot_autoyast](#create-a-boot-option-for-autoyast-of-the-pxeboot) "\$@"                                         | create a boot option for autoyast of the pxeboot                              |
|                                                                                                   | [fnPxeboot_boot_options](#create-a-boot-option-of-the-pxeboot) "\$@"                                                  | create a boot option of the pxeboot                                           |
|                                                                                                   | [fnPxeboot_ipxe](#create-autoexecipxe) "\$1" "\$2" "\$@"                                                              | create autoexec.ipxe                                                          |
|                                                                                                   | [fnPxeboot_grub](#create-grubcfg) "\$1" "\$2" "\$@"                                                                   | create grub.cfg                                                               |
|                                                                                                   | [fnPxeboot_slnx](#create-bios-mode) "\$1" "\$2" "\$@"                                                                 | create bios mode                                                              |
|                                                                                                   | [fnPxeboot](#executing-the-action) "\$1" "\$@"                                                                        | executing the action                                                          |
| [tmpl_005_function_section_test_function.sh](./tmpl_005_function_section_test_function.sh)        | [fnServiceStatus](#service-status) "\$@"                                                                              | service status                                                                |
|                                                                                                   | [fnIsPackage](#function-is-package) "\$1"                                                                             | function is package                                                           |
|                                                                                                   | [fnDiff](#diff) "\$1" "\$2"                                                                                           | diff                                                                          |
|                                                                                                   | [fnDebug_color](#text-color-test)                                                                                     | text color test                                                               |
|                                                                                                   | [fnDebug_function](#function-test)                                                                                    | function test                                                                 |
  
* * *
  
### **skel_mk_custom_iso.sh**  
  
* * *
  
#### initialization for skel_mk_custom_iso.sh (dummy)  
  
*fnInitialization*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### debug out parameter for skel_mk_custom_iso.sh  
  
*fnDebug_parameter*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### help for skel_mk_custom_iso.sh  
  
*fnHelp*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### main for skel_mk_custom_iso.sh  
  
*fnMain "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | option parameter       |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **skel_mk_pxeboot_conf.sh**  
  
* * *
  
#### initialization for skel_mk_pxeboot_conf.sh (dummy)  
  
*fnInitialization*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### debug out parameter for skel_mk_pxeboot_conf.sh  
  
*fnDebug_parameter*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### help for skel_mk_pxeboot_conf.sh  
  
*fnHelp*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### main for skel_mk_pxeboot_conf.sh  
  
*fnMain "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | option parameter       |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **skel_test_function.sh**  
  
* * *
  
#### initialization for skel_test_function.sh (dummy)  
  
*fnInitialization*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### debug out parameter for skel_test_function.sh  
  
*fnDebug_parameter*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### help for skel_test_function.sh  
  
*fnHelp*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### main for skel_test_function.sh  
  
*fnMain "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | option parameter       |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_001_initialize_common.sh**  
  
* * *
  
#### trap  
  
*fnTrap*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_001_initialize_mk_custom_iso.sh**  
  
* * *
  
### **tmpl_001_initialize_mk_pxeboot_conf.sh**  
  
* * *
  
### **tmpl_001_initialize_test_function.sh**  
  
* * *
  
### **tmpl_002_data_section.sh**  
  
* * *
  
### **tmpl_003_function_section_library.sh**  
  
* * *
  
#### debug print  
  
*fnDebugout "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stderr | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### print out of internal variables  
  
*fnDebug_parameter_list*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stderr | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### is numeric  
  
*fnIsNumeric "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout |                        | =0 (numer)                                 |
| "      |        |                        | !0 (not number)                            |
| return |        | unused                 |                                            |
  
* * *
  
#### substr  
  
*fnSubstr "\$1" "\$2" "\$3"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| input  | $2     | starting position      |                                            |
| input  | $3     | number of characters   |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### string output  
  
*fnString "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | number of characters   |                                            |
| input  | $2     | output character       |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### ltrim  
  
*fnLtrim "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input                  |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### rtrim  
  
*fnRtrim "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input                  |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### trim  
  
*fnTrim "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input                  |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### date diff  
  
*fnDateDiff "\$1" "\$2"*  
  
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
  
#### print with centering  
  
*fnCenter "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | print width            |                                            |
| input  | $2     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### print with screen control  
  
*fnPrintf "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_003_function_section_library_initrd.sh**  
  
* * *
  
#### extract a compressed cpio  
  
*fnXcpio "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| input  | $@     | cpio options           |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### read bytes out of a file, checking that they are valid hex digits  
  
*fnReadhex "\$1" "\$2" "\$3"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | skip bytes             |                                            |
| input  | $3     | count bytes            |                                            |
| output | stdout | result                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### check for a zero byte in a file  
  
*fnCheckzero "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | skip bytes             |                                            |
| output | stdout | unused                 |                                            |
| return |        | status                 |                                            |
  
* * *
  
#### split an initramfs into target files and call funcxcpio on each  
  
*fnSplit_initramfs "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_003_function_section_library_media.sh**  
  
* * *
  
#### unit conversion  
  
*fnUnit_conversion "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | value with units                           |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get volume id  
  
*fnGetVolID "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | volume id                                  |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get file information  
  
*fnGetFileinfo "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size vol-id                   |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### distro to efi image file name  
  
*fnDistro2efi "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_003_function_section_library_mkiso.sh**  
  
* * *
  
#### create iso image  
  
*fnCreate_iso "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | output path            |                                            |
| input  | $@     | xorrisofs options      |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_003_function_section_library_network.sh**  
  
* * *
  
#### IPv4 netmask conversion (netmask and cidr conversion)  
  
*fnIPv4GetNetmask "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### IPv6 full address  
  
*fnIPv6GetFullAddr "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### IPv6 reverse address  
  
*fnIPv6GetRevAddr "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_003_function_section_library_web_tool.sh**  
  
* * *
  
#### get web contents  
  
*fnGetWeb_contents "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | output path            |                                            |
| input  | $2     | url                    |                                            |
| output | stdout | message                |                                            |
| return |        | status                 |                                            |
  
* * *
  
#### get web header  
  
*fnGetWeb_header "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size status contents          |
| input  | $2     | url                    |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web address completion  
  
*fnGetWeb_address "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | address completion path                    |
| input  | $2     | input value            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web information  
  
*fnGetWeb_info "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | path tmstamp size status contents          |
| input  | $2     | url                    |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get web status message  
  
*fnGetWeb_status "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input vale             |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_004_function_section_common.sh**  
  
* * *
  
#### initialization  
  
*fnInitialization*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create common configuration file  
  
*fnCreate_conf*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### get media data  
  
*fnGet_media_data*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### put media data  
  
*fnPut_media_data*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create directory  
  
*fnCreate_directory "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $@     | input vale             |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create preseed.cfg  
  
*fnCreate_preseed "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create nocloud  
  
*fnCreate_nocloud "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create kickstart.cfg  
  
*fnCreate_kickstart "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoyast.xml  
  
*fnCreate_autoyast "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create pre-configuration file templates  
  
*fnCreate_precon "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $@     | input value            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_005_function_section_mk_custom_iso.sh**  
  
* * *
  
#### create a boot option for preseed of the remaster  
  
*fnRemastering_preseed "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for nocloud of the remaster  
  
*fnRemastering_nocloud "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for kickstart of the remaster  
  
*fnRemastering_kickstart "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for autoyast of the remaster  
  
*fnRemastering_autoyast "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option of the remaster  
  
*fnRemastering_boot_options "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create path for configuration file  
  
*fnRemastering_path "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target path            |                                            |
| input  | $2     | directory              |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoinstall configuration file for isolinux  
  
*fnRemastering_isolinux_autoinst_cfg "\$1" "\$2" "\$3" "\$@"*  
  
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
  
*fnRemastering_isolinux "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoinstall configuration file for grub  
  
*fnRemastering_grub_autoinst_cfg "\$1" "\$2" "\$3" "\$@"*  
  
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
  
*fnRemastering_grub "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $2     | boot options           |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### copy auto-install files  
  
*fnRemastering_copy "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering for initrd  
  
*fnRemastering_initrd "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering for media  
  
*fnRemastering_media "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target directory       |                                            |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### remastering  
  
*fnRemastering "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | target data            |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### print out of menu  
  
*fnExec_menu "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | options                                    |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the download  
  
*fnExec_download "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the remastering  
  
*fnExec_remastering "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | target data            |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the action  
  
*fnExec "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | option parameter       |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_005_function_section_mk_pxeboot_conf.sh**  
  
* * *
  
#### file copy  
  
*fnPxeboot_copy "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file            |                                            |
| input  | $2     | destination directory  |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for preseed of the pxeboot  
  
*fnPxeboot_preseed "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for nocloud of the pxeboot  
  
*fnPxeboot_nocloud "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for kickstart of the pxeboot  
  
*fnPxeboot_kickstart "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option for autoyast of the pxeboot  
  
*fnPxeboot_autoyast "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create a boot option of the pxeboot  
  
*fnPxeboot_boot_options "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create autoexec.ipxe  
  
*fnPxeboot_ipxe "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create grub.cfg  
  
*fnPxeboot_grub "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### create bios mode  
  
*fnPxeboot_slnx "\$1" "\$2" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | target file (menu)     |                                            |
| input  | $2     | tabs count             |                                            |
| input  | $@     | target data (list)     |                                            |
| output | stdout | unused                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### executing the action  
  
*fnPxeboot "\$1" "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| n-ref  | $1     | return value           | serialized target data                     |
| input  | $@     | option parameter       |                                            |
| output | stdout | message                |                                            |
| return |        | unused                 |                                            |
  
* * *
  
### **tmpl_005_function_section_test_function.sh**  
  
* * *
  
#### service status  
  
*fnServiceStatus "\$@"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $@     | input value            |                                            |
| output | stdout | output                 | =0 (program is running or service is OK [unit is active]) |
| "      |        |                        | =1 (program is dead and /var/run pid file exists [unit not failed (used by is-failed)]) |
| "      |        |                        | =2 (program is dead and /var/lock lock file exists [unused]) |
| "      |        |                        | =3 (program is not running [unit is not active]) |
| "      |        |                        | =4 (program or service status is unknown [no such unit]) |
| return |        | unused                 |                                            |
  
* * *
  
#### function is package  
  
*fnIsPackage "\$1"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | input value            |                                            |
| output | stdout | output                 | empty (not install)                        |
| "      |        |                        | other (installed)                          |
| return |        | unused                 |                                            |
  
* * *
  
#### diff  
  
*fnDiff "\$1" "\$2"*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  | $1     | file 1                 |                                            |
| input  | $2     | file 2                 |                                            |
| output | stdout | result                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### text color test  
  
*fnDebug_color*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
  
* * *
  
#### function test  
  
*fnDebug_function*  
  
|  i/o   | value  |      explanation       |                    note                    |
| :----: | :----: | :--------------------- | :----------------------------------------- |
| input  |        | unused                 |                                            |
| output | stdout | output                 |                                            |
| return |        | unused                 |                                            |
