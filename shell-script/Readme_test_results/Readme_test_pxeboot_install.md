# **Testing the installation from PXEBoot**  
  
## **Machine specs**  
  
### **Virtual machine**
  
VMware Workstation 16 Pro (16.2.5 build-20904516)
  
| device    | specification      | note                          |
| :-------- | :----------------- | :---------------------------- |
| processor | 1processor / 2core | core i7-6700                  |
| memory    | 4GiB               | Most distributions            |
|     "     | 8GiB               | Ubuntu live server            |
|     "     |   "                | Ubuntu desktop 20.04/22.04    |
|     "     | 16GiB              | Ubuntu desktop 24.04 or newer |
| storage   | NVMe 64GiB         |                               |
| nic       | e1000e             |                               |
| sound     | ES1371             |                               |
  
## **iPXE**  
  
|       distribution       | mini| net | dvd | live| release_date |end_of_support|long_term_supp| rhel_release |kernel_version_information|  various_information_from_the_iso_media   |                       wiki_url                        |  mini.iso_time_stamp  | netinstall_time_stamp | dvd_media_time_stamp  | live_media_time_stamp |
| :----------------------- | :-: | :-: | :-: | :-: | :----------: | :----------: | :----------: | :----------: | :----------------------- | :---------------------------------------- | :---------------------------------------------------- | :-------------------: | :-------------------: | :-------------------: | :-------------------: |
| debian-11                |  o  |  x  |  x  |  x  |  2021-08-14  |  2024-08-15  |  2026-08-31  |       -      | 5.10                     | debian-11.11.0 / bullseye / oldstable     | https://en.wikipedia.org/wiki/Debian_version_history  |  2024-08-27 06:14:31  |  2024-08-31 16:11:10  |  2024-08-31 16:11:53  |  2024-08-31 15:15:29  |
| debian-12                |  o  |  x  |  x  |  x  |  2023-06-10  |  2026-06-xx  |  2028-06-xx  |       -      | 6.1                      | debian-12.9.0  / bookworm / stable        | "                                                     |  2025-01-06 18:01:36  |  2025-01-11 12:53:04  |  2025-01-11 12:53:52  |  2025-01-11 10:25:55  |
| debian-13                |  *  |  -  |  -  |  -  |  2025-xx-xx  |  20xx-xx-xx  |  20xx-xx-xx  |       -      |                          | debian-13      / trixie   / testing       | "                                                     |  2024-12-27 09:14:03  |           -           |           -           |           -           |
| debian-14                |  -  |  -  |  -  |  -  |  2027-xx-xx  |  20xx-xx-xx  |  20xx-xx-xx  |       -      |         -                | debian-14      / forky                    | "                                                     |           -           |           -           |           -           |           -           |
| debian-15                |  -  |  -  |  -  |  -  |  20xx-xx-xx  |  20xx-xx-xx  |  20xx-xx-xx  |       -      |         -                | debian-15      / duke                     | "                                                     |           -           |           -           |           -           |           -           |
| debian-testing           |  o  |  x  |  x  |  x  |       -      |       -      |       -      |       -      |                          | debian-testing / testing daily or weekly  | "                                                     |  2025-02-28 00:02:24  |  2025-02-28 21:40:35  |  2025-02-24 05:38:23  |  2025-02-24 02:18:47  |
| ubuntu-20.04             |  o  |  -  |  x  |  o  |  2020-04-23  |  2025-05-29  |  2030-04-23  |       -      | 5.4                      | ubuntu-20.04.6 / focal                    | https://en.wikipedia.org/wiki/Ubuntu_version_history  |  2023-03-14 22:28:31  |           -           |  2023-03-14 23:02:35  |  2023-03-16 15:58:09  |
| ubuntu-22.04             |  -  |  -  |  o  |  o  |  2022-04-21  |  2027-06-01  |  2032-04-21  |       -      | 5.15 or 5.17             | ubuntu-22.04.5 / jammy                    | "                                                     |           -           |           -           |  2024-09-11 18:46:55  |  2024-09-11 14:38:59  |
| ubuntu-24.04             |  -  |  -  |  o  |  o  |  2024-04-25  |  2029-05-31  |  2034-04-25  |       -      | 6.8                      | ubuntu-24.04.2 / noble                    | "                                                     |           -           |           -           |  2025-02-16 22:49:40  |  2025-02-15 09:16:38  |
| ubuntu-24.10             |  -  |  -  |  o  |  o  |  2024-10-10  |  2025-07-xx  |       -      |       -      | 6.11                     | ubuntu-24.10   / oracular                 | "                                                     |           -           |           -           |  2024-10-07 21:19:04  |  2024-10-09 14:32:32  |
| ubuntu-25.04             |  -  |  -  |  o  |  *  |  2025-04-17  |  2026-01-xx  |              |       -      |                          | ubuntu-25.04   / plucky                   | "                                                     |           -           |           -           |  2025-02-27 13:57:46  |  2025-02-28 06:40:21  |
| Fedora-40                |  -  |  o  |  o  |  -  |  2024-04-23  |  2025-05-28  |       -      |       -      | 6.8                      | Fedora-40-1.14                            | https://en.wikipedia.org/wiki/Fedora_Linux            |           -           |  2024-04-14 18:30:19  |  2024-04-14 22:54:06  |           -           |
| Fedora-41                |  -  |  o  |  o  |  -  |  2024-10-29  |  2025-11-19  |       -      |       -      | 6.11                     | Fedora-41-1.4                             | "                                                     |           -           |  2024-10-24 13:36:10  |  2024-10-24 14:48:35  |           -           |
| Fedora-42                |  -  |  -  |  -  |  -  |  2025-04-22  |  2026-05-13  |       -      |       -      |         -                |                     -                     | "                                                     |           -           |           -           |           -           |           -           |
| Fedora-43                |  -  |  -  |  -  |  -  |  2025-11-11  |  2026-12-02  |       -      |       -      |         -                |                     -                     | "                                                     |           -           |           -           |           -           |           -           |
| CentOS-Stream-9          |  -  |  o  |  o  |  -  |  2021-12-03  |  2027-05-31  |       -      |       -      | 5.14.0                   |                     -                     | https://en.wikipedia.org/wiki/CentOS_Stream           |           -           |  2025-02-24 16:13:12  |  2025-02-24 16:27:26  |           -           |
| CentOS-Stream-10         |  -  |  o  |  o  |  -  |  2024-12-12  |  2030-01-01  |       -      |       -      | 6.12.0                   |                     -                     | "                                                     |           -           |  2025-02-26 04:19:22  |  2025-02-26 04:26:38  |           -           |
| AlmaLinux-8              |  -  |  -  |  -  |  -  |  2024-05-28  |       -      |       -      |  2024-05-22  | 4.18.0-553               | AlmaLinux-8.10                            | https://en.wikipedia.org/wiki/AlmaLinux               |           -           |           -           |           -           |           -           |
| AlmaLinux-9              |  -  |  o  |  o  |  -  |  2024-11-18  |       -      |       -      |  2024-11-13  | 5.14.0-503.11.1          | AlmaLinux-9.5                             | "                                                     |           -           |  2024-11-13 09:40:34  |  2024-11-13 09:59:46  |           -           |
| Rocky-8                  |  -  |  -  |  -  |  -  |  2024-05-30  |       -      |       -      |  2024-05-22  | 4.18.0-553               | Rocky-8.10                                | https://en.wikipedia.org/wiki/Rocky_Linux             |           -           |  2024-05-27 14:13:45  |  2024-05-27 15:14:45  |           -           |
| Rocky-9                  |  -  |  o  |  o  |  -  |  2024-11-19  |       -      |       -      |  2024-11-12  | 5.14.0-503.14.1          | Rocky-9.5                                 | "                                                     |           -           |  2024-11-16 01:52:35  |  2024-11-16 04:23:15  |           -           |
| MIRACLELINUX-8           |  -  |  -  |  -  |  -  |  2023-10-05  |       -      |       -      |  202x-xx-xx  | 4.18.0-xxx.xxx           | MIRACLELINUX-8.10                         | https://en.wikipedia.org/wiki/Miracle_Linux           |           -           |  2024-10-11 07:13:59  |  2024-10-17 03:23:34  |           -           |
| MIRACLELINUX-9           |  -  |  o  |  o  |  -  |  2023-10-05  |       -      |       -      |  202x-xx-xx  | 5.14.0-xxx.xxx           | MIRACLELINUX-9.4                          | "                                                     |           -           |  2024-08-23 05:57:18  |  2024-08-23 05:57:18  |           -           |
| openSUSE-Leap-15.6       |  -  |  o  |  o  |  -  |  2024-06-12  |  2025-12-31  |       -      |       -      | 6.4                      | openSUSE-Leap-15.6                        | https://en.wikipedia.org/wiki/OpenSUSE                |           -           |  2024-06-20 11:42:39  |  2024-06-20 11:56:54  |           -           |
| openSUSE-Leap-16.0       |  -  |  -  |  -  |  -  |  2025-11-xx  |  20xx-xx-xx  |       -      |       -      |                          | openSUSE-Leap-16.0                        | "                                                     |           -           |           -           |           -           |           -           |
| openSUSE-Tumbleweed      |  -  |  x  |  x  |  -  |  2014-11-xx  |  20xx-xx-xx  |       -      |       -      |                          | openSUSE-Tumbleweed                       | "                                                     |           -           |  2025-02-27 19:24:30  |  2025-02-27 19:27:37  |           -           |
| agama-installer-Leap-PXE |  -  |  x  |  -  |  -  |       -      |       -      |       -      |       -      |                          |                     -                     |                           -                           |           -           |  2025-01-28 18:13:43  |           -           |           -           |
| agama-installer-Leap     |  -  |  x  |  -  |  -  |       -      |       -      |       -      |       -      |                          |                     -                     |                           -                           |           -           |  2025-01-28 18:11:00  |           -           |           -           |
| Win10_22H2_Japanese_x64  |  -  |  -  |  o  |  -  |       -      |       -      |       -      |       -      |         -                | Windows 10 22H2                           |                           -                           |           -           |           -           |  2022-10-18 15:21:50  |           -           |
| Win11_24H2_Japanese_x64  |  -  |  -  |  o  |  -  |       -      |       -      |       -      |       -      |         -                | Windows 11 24H2                           |                           -                           |           -           |           -           |  2024-10-01 12:18:50  |           -           |
| WinPE_ATI2020x64         |  -  |  -  |  o  |  -  |       -      |       -      |       -      |       -      |         -                | ATI2020x64 with WinPE                     |                           -                           |           -           |           -           |  2022-01-28 13:12:34  |           -           |
| WinPE_ATI2020x86         |  -  |  -  |  *  |  -  |       -      |       -      |       -      |       -      |         -                | ATI2020x86 with WinPE                     |                           -                           |           -           |           -           |  2022-01-28 13:07:12  |           -           |
| WinPEx64.iso             |  -  |  -  |  o  |  -  |       -      |       -      |       -      |       -      |         -                | WinPEx64                                  |                           -                           |           -           |           -           |  2024-10-21 12:19:39  |           -           |
| WinPEx86.iso             |  -  |  -  |  -  |  -  |       -      |       -      |       -      |       -      |         -                | WinPEx86                                  |                           -                           |           -           |           -           |           -           |           -           |
| mt86plus                 |  -  |  -  |  o  |  -  |       -      |       -      |       -      |       -      |         -                | mt86plus_7.20_64.grub                     |                           -                           |           -           |           -           |  2024-11-11 09:15:12  |           -           |
  
note
  
| mark| result |
| :-: | :----: |
|  o  |   OK   |
|  x  |   NG   |
|  -  |  none  |
  
| item |    object   |               information               |
| :--: | :---------- | :-------------------------------------- |
| mini | mini.iso    | debian-xx and ubuntu-20.04(focal) only  |
| net  | net install |                                         |
| dvd  | dvd media   | inlude: ubuntu-live-server              |
| live | live media  | inlude: ubuntu-desktop                  |
  
* debian-13 mini.iso  
Aborted due to kernel version mismatch  
  
* Other than debian mini.iso  
Aborted because installer was stuck on detecting ISO file  
  
* ubuntu-25.04 desktop (plucky-desktop-amd64.iso)  
No reboot after installation. An internal error occurs after logging in.  
  
* openSUSE-Tumbleweed  
Aborted due to network not functioning  
  
* WinPE_ATI2020x86  
BIOS mode only  
  
