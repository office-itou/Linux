# **function**  
  
## **skeleton**  
  
### skel_mk_custom_iso.sh  
  
### skel_mk_pxeboot_conf.sh  
  
### skel_test_function.sh  
  
## **template**  
  
### tmpl_000_skeleton.sh  
  
### tmpl_001_initialize.sh  
  
### tmpl_001_initialize_common.sh  
  
#### trap
  
funcTrap  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |        | unused                |
| out | stdout | unused                |
| ret |        | unused                |
  
note:  
  
``` bash:
declare -a    _LIST_RMOV=()             # list remove directory / file
              _LIST_RMOV+=("${_DIRS_TEMP:?}")
```
  
### tmpl_001_initialize_mk_custom_iso.sh  
  
### tmpl_001_initialize_mk_pxeboot_conf.sh  
  
### tmpl_001_initialize_test_function.sh  
  
### tmpl_002_data_section.sh  
  
### tmpl_003_function_section_library.sh  
  
#### string output  
  
funcString "$1" "$2"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | output count          |
| inp |   $2   | output character      |
| out | stdout | output                |
| ret |        | unused                |
  
#### date diff  
  
funcDateDiff "$1" "$2"
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | date 1                |
| inp |   $2   | date 2                |
| out | stdout | unused                |
| ret |        | =0: $1 = $2           |
|  "  |        | >0: $1 < $2           |
|  "  |        | <0: $1 > $2           |
  
#### print with screen control  
  
funcPrintf "$1" ...  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | format                |
| inp |   $@   | value                 |
| out | stdout | output                |
| ret |        | unused                |
  
### tmpl_003_function_section_library_initrd.sh  
  
#### split an initramfs into  
  
funcSplit_initramfs "$1" "$2"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | target file           |
| inp |   $2   | destination directory |
| out | stdout | unused                |
| ret |        | unused                |
  
### tmpl_003_function_section_library_media.sh  
  
#### unit conversion  
  
funcUnit_conversion "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | value with units           |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### get volume id  
  
funcGetVolID "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | volume id                  |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### get file information  
  
funcGetFileinfo "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | pass timestamp size vol-id |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### distro to efi image file name  
  
funcDistro2efi "$1"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
### tmpl_003_function_section_library_mkiso.sh  
  
#### create iso image  
  
funcCreate_iso "$1" "$2" "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | target directory      |
| inp |   $2   | output path           |
| inp |   $@   | xorrisofs options     |
| out | stdout | message               |
| ret |        | unused                |
  
### tmpl_003_function_section_library_network.sh  
  
#### IPv4 netmask conversion (netmask and cidr conversion)  
  
funcIPv4GetNetmask "$1"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### IPv6 full address  
  
funcIPv6GetFullAddr "$1"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### IPv6 reverse address  
  
funcIPv6GetRevAddr "$1"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
### tmpl_003_function_section_library_web_tool.sh  
  
#### get web contents  
  
function funcGetWeb_contents "$1" "$2"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | output path           |
| inp |   $2   | url                   |
| out | stdout | message               |
| ret |        | unused                |
  
#### get web header  
  
funcGetWeb_header "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | pass timestamp size status |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### get web address completion  
  
funcGetWeb_address "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | pass                       |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### get web information  
  
funcGetWeb_info "$1" "$2"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | pass timestamp size status |
| inp |   $2   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
#### get web status message  
  
function funcGetWeb_status "$1"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $1   | status code           |
| out | stdout | message               |
| ret |        | unused                |
  
### tmpl_004_function_section_common.sh  
  
#### initialization  
  
funcInitialization  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |        | unused                |
| out | stdout | unused                |
| ret |        | unused                |
  
#### create common configuration file  
  
funcCreate_conf  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |        | unused                |
| out | stdout | unused                |
| ret |        | unused                |
  
#### get media data  
  
funcGet_media_data  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |        | unused                |
| out | stdout | unused                |
| ret |        | unused                |
  
#### create_directory  
  
fncCreate_directory "$1"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | options                    |
| inp |   $@   | input value           |                            |
| out | stdout | unused                |                            |
| ret |        | unused                |                            |
  
### tmpl_004_function_section_template.sh  
  
### tmpl_005_function_section_common.sh  
  
#### print out of menu  
  
function funcPrint_menu "$1" "$2" "$3" "$@"  
  
| i/o | value  |      explanation      |            note            |
| :-: | :----: | :-------------------- | :------------------------- |
| ref |   $1   | return value          | serialized target data     |
| inp |   $2   | command type          |                            |
| inp |   $3   | target range          |                            |
| inp |   $@   | target data           |                            |
| out | stdout | message               |                            |
| ret |        | unused                |                            |
  
### tmpl_005_function_section_mk_custom_iso.sh  
  
#### create boot options for preseed  
  
funcRemastering_preseed "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $@   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### create boot options for nocloud  
  
funcRemastering_nocloud "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $@   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### create boot options for kickstart  
  
funcRemastering_kickstart "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $@   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### create boot options for autoyast  
  
funcRemastering_autoyast "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $@   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
#### create boot options  
  
funcRemastering_boot_options "$@"  
  
| i/o | value  |      explanation      |
| :-: | :----: | :-------------------- |
| inp |   $@   | input value           |
| out | stdout | output                |
| ret |        | unused                |
  
### tmpl_005_function_section_mk_pxeboot_conf.sh  
  
### tmpl_005_function_section_test_function.sh  
  