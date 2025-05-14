# **Test results for DVD media and PXEboot installation**  
  
**Updated: 2025/4/28**  
  
|         version          | iso mini| iso net | iso dvd | iso live| pxe mini| pxe net | pxe dvd | pxe live| life |  release   |support end | long term  |    rhel    |         kerne         |      code name      |          note           |
| :----------------------- | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :--: | :--------: | :--------: | :--------: | :--------: | :-------------------- | :------------------ | :---------------------- |
| Debian-11.0 (11.11.0)    |         |         |         |         |    o    |    x    |    x    |    x    | LTS  | 2021/08/14 | 2024/08/14 | 2026/08/31 |            | 5.10                  | Bullseye            | oldstable               |
| Debian-12.0 (12.10.0)    |         |         |         |         |    o    |    x    |    x    |    x    |      | 2023/06/10 | 2026/06/10 | 2028/06/30 |            | 6.1                   | Bookworm            | stable                  |
| Debian-13.0              |    -    |    -    |    -    |    -    |    x    |    -    |    -    |    -    |      | 2025/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Trixie              | testing                 |
| Debian-14.0              |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2027/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Forky               |                         |
| Debian-15.0              |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Duke                |                         |
| Debian-testing           |         |         |         |         |    x    |    x    |    x    |    x    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Testing             | testing                 |
| Debian-testing (daily)   |         |    -    |    -    |    -    |    o    |    x    |    x    |    x    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | Testing             | testing_daily_build     |
| Debian-sid               |    -    |    -    |    -    |    -    |    -    |    x    |    x    |    x    |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | SID                 | sid                     |
| Ubuntu-16.04 (16.04.7)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | LTS  | 2016/04/21 | 2021/04/30 | 2026/04/23 |            | 4.4                   | Xenial_Xerus        |                         |
| Ubuntu-18.04 (18.04.6)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | LTS  | 2018/04/26 | 2023/05/31 | 2028/04/26 |            | 4.15                  | Bionic_Beaver       |                         |
| Ubuntu-20.04 (20.04.5)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2020/04/23 | 2025/05/29 | 2030/04/23 |            | 5.4                   | Focal_Fossa         |                         |
| Ubuntu-22.04 (22.04.5)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2022/04/21 | 2027/06/01 | 2032/04/21 |            | 5.15 or 5.17          | Jammy_Jellyfish     |                         |
| Ubuntu-24.04 (24.04.2)   |    -    |    -    |         |         |    -    |    -    |         |    *    |      | 2024/04/25 | 2029/05/31 | 2034/04/25 |            | 6.8                   | Noble_Numbat        | desktop_use_16GiB       |
| Ubuntu-24.10 (24.10)     |    -    |    -    |         |         |    -    |    -    |         |    *    |      | 2024/10/10 | 2025/07/xx |            |            | 6.11                  | Oracular_Oriole     | "                       |
| Ubuntu-25.04 (25.04)     |    -    |    -    |         |         |    -    |    -    |         |    *    |      | 2025/04/17 | 2026/01/xx |            |            | 6.14                  | Plucky_Puffin       | "                       |
| Fedora-40                |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2024/04/23 | 2025/05/28 |            |            | 6.8                   |                     |                         |
| Fedora-41                |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/10/29 | 2025/11/19 |            |            | 6.11                  |                     |                         |
| Fedora-42                |    -    |         |         |    -    |    -    |         |         |    -    |      | 2025/04/15 | 2026/05/13 |            |            | 6.14                  |                     |                         |
| Fedora-43                |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2025/11/11 | 2026/12/02 |            |            |                       |                     |                         |
| CentOS Stream-9          |    -    |         |         |    -    |    -    |         |         |    -    |      | 2021/12/03 | 2027/05/31 |            |            | 5.14.0                |                     |                         |
| CentOS Stream-10         |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/12/12 | 2030/01/01 |            |            | 6.12.0                | Coughlan            |                         |
| AlmaLinux-8 (8.10)       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2024/05/28 |            |            | 2024/05/22 | 4.18.0_553            | Cerulean_Leopard    |                         |
| AlmaLinux-9 (9.5)        |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/11/18 |            |            | 2024/11/13 | 5.14.0_503.11.1       | Teal_Serval         |                         |
| Rocky Linux-8 (8.10)     |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2024/05/30 |            |            | 2024/05/22 | 4.18.0_553            | Green_Obsidian      |                         |
| Rocky Linux-9 (9.5)      |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/11/19 |            |            | 2024/11/12 | 5.14.0_503.14.1       | Blue_Onyx           |                         |
| Miracle Linux-8 (8.10)   |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2024/10/17 |            |            | 2024/05/22 | 4.18.0_553.el8_10     | Peony               |                         |
| Miracle Linux-9 (9.4)    |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/09/02 |            |            | 2024/04/30 | 5.14.0_427.13.1.el9_4 | Feige               |                         |
| openSUSE-15 (15.6)       |    -    |         |         |    -    |    -    |         |         |    -    |      | 2024/06/12 | 2025/12/31 |            |            | 6.4                   |                     |                         |
| openSUSE-16 (16.0)       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 2025/10/xx | 20xx/xx/xx |            |            |                       |                     |                         |
| openSUSE-tumbleweed      |    -    |         |         |    -    |    -    |         |         |    -    |      | 2014/11/xx | 20xx/xx/xx |            |            |                       |                     |                         |
| Win10_22H2_Japanese_x64  |    -    |    -    |         |    -    |    -    |    -    |         |    -    |      | 2022/10/18 | 2025/10/14 |            |            |                       |                     |                         |
| Win11_24H2_Japanese_x64  |    -    |    -    |         |    -    |    -    |    -    |         |    -    |      | 2024/10/01 | 2026/10/13 |            |            |                       |                     |                         |
| WinPE_ATI2020x64         |    -    |    -    |   ( )   |    -    |    -    |    -    |   ( )   |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                     | startup_check_only      |
| WinPE_ATI2020x86         |    -    |    -    |   ( )   |    -    |    -    |    -    |   ( )   |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                     | "                       |
| WinPEx64.iso             |    -    |    -    |   ( )   |    -    |    -    |    -    |   ( )   |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                     | "                       |
| WinPEx86.iso             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                     | "                       |
| mt86plus                 |    -    |    -    |   ( )   |    -    |    -    |    -    |   ( )   |    -    |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                     | "                       |
  
| media |        edition        |
| :---: | :-------------------- |
| mini  | mini.iso              |
| net   | net install           |
| dvd   | server                |
| live  | desktop or live media |
  
| mark |            status            |
| :--: | :--------------------------- |
|  o   | OK                           |
|  x   | NG                           |
|  -   | Excluded                     |
|  *   | Depends on H/W configuration |
