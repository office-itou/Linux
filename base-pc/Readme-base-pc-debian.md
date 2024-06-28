# **Install**  
  
## Main operation screen  
  
Skip Screen is the default value
  
### Automatic installation  
  
| Screenshot                                                                                                       |
| :--------------------------------------------------------------------------------------------------------------: |
| ![autoinstall-001](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-001.png) |
| ![autoinstall-002](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-002.png) |
| ![autoinstall-003](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-003.png) |
| ![autoinstall-004](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-004.png) |
| ![autoinstall-005](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-005.png) |
| ![autoinstall-006](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-006.png) |
| ![autoinstall-007](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-007.png) |
| ![autoinstall-008](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-008.png) |
| ![autoinstall-009](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-009.png) |
| ![autoinstall-010](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-010.png) |
| ![autoinstall-011](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-011.png) |
| ![autoinstall-012](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-012.png) |
| ![autoinstall-013](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-01-autoinstall-013.png) |
  
### Login  
  
| Screenshot                                                                                                       |
| :--------------------------------------------------------------------------------------------------------------: |
| ![login-001](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-02-login-001.png)             |
| ![login-002](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-02-login-002.png)             |
| ![login-003](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-02-login-003.png)             |
| ![login-004](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-02-login-004.png)             |
  
### Setup  
  
| Screenshot                                                                                                       |
| :--------------------------------------------------------------------------------------------------------------: |
| ![setup-001](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-03-setup-001.png)             |
| ![setup-002](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-03-setup-002.png)             |
  
| software                                                                                                         |
| :--------------------------------------------------------------------------------------------------------------- |
| wget https://raw.githubusercontent.com/office-itou/Linux/master/base-pc/script/install.sh                        |
| wget https://raw.githubusercontent.com/office-itou/Linux/master/base-pc/script/install.sh.user.lst               |
  
## Script Operation  
  
| Screenshot                                                                                                       |
| :--------------------------------------------------------------------------------------------------------------: |
| ![script-001](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-001.png)           |
| ![script-002](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-002.png)           |
| ![script-003](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-003.png)           |
| ![script-004](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-004.png)           |
| ![script-005](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-005.png)           |
| ![script-006](https://github.com/office-itou/Linux/blob/master/base-pc/image/debian-04-script-006.png)           |
  
| software                                                                                                         |
| :--------------------------------------------------------------------------------------------------------------- |
| sudo mkdir -p share/conf/_template                                                                               |
| cd share/conf/_template                                                                                          |
| sudo wget -q https://raw.githubusercontent.com/office-itou/Linux/master/conf/_template/{kickstart_common.cfg,nocloud-ubuntu-user-data,preseed_debian.cfg,preseed_ubuntu.cfg,yast_opensuse.xml} |
| wget -q https://raw.githubusercontent.com/office-itou/Linux/master/shell-script/mk_custom_iso.sh                 |
  
