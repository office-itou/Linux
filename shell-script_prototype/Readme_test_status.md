# **Test results for DVD media and PXEboot installation**  
  
**Updated: 2025/4/28**  
  
|         version          | iso mini| iso net | iso dvd | iso live| pxe mini| pxe net | pxe dvd | pxe live|      code name      | life |  release   |support end | long term  |    rhel    |         kerne         |         note         |
| :----------------------- | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :-----: | :------------------ | :--: | :--------: | :--------: | :--------: | :--------: | :-------------------- | :------------------- |
| Debian-11.0              |         |         |         |         |         |    x    |    x    |    x    | Bullseye            | LTS  | 2021/08/14 | 2024/08/15 | 2026/08/31 |            | 5.10                  | oldstable            |
| Debian-12.0              |         |         |         |         |         |    x    |    x    |    x    | Bookworm            |      | 2023/06/10 | 2026/06/xx | 2028/06/xx |            | 6.1                   | stable               |
| Debian-13.0              |    -    |    -    |    -    |    -    |         |    -    |    -    |    -    | Trixie              |      | 2025/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | testing              |
| Debian-14.0              |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Forky               |      | 2027/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       |                      |
| Debian-15.0              |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Duke                |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       |                      |
| Debian-testing           |         |         |         |         |         |    x    |    x    |    x    | Testing             |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | testing              |
| Debian-testing (daily)   |         |    -    |    -    |    -    |         |    x    |    x    |    x    | Testing             |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | testing_daily_build  |
| Debian-sid               |    -    |    -    |    -    |    -    |    -    |    x    |    x    |    x    | SID                 |      | 20xx/xx/xx | 20xx/xx/xx | 20xx/xx/xx |            |                       | sid                  |
| Ubuntu-16.04             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Xenial_Xerus        | LTS  | 2016/04/21 | 2021/04/30 | 2026/04/23 |            | 4.4                   |                      |
| Ubuntu-18.04             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Bionic_Beaver       | LTS  | 2018/04/26 | 2023/05/31 | 2028/04/26 |            | 4.15                  |                      |
| Ubuntu-20.04             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Focal_Fossa         |      | 2020/04/23 | 2025/05/29 | 2030/04/23 |            | 5.4                   |                      |
| Ubuntu-22.04             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Jammy_Jellyfish     |      | 2022/04/21 | 2027/06/01 | 2032/04/21 |            | 5.15 or 5.17          |                      |
| Ubuntu-24.04             |    -    |    -    |         |         |    -    |    -    |         |         | Noble_Numbat        |      | 2024/04/25 | 2029/05/31 | 2034/04/25 |            | 6.8                   |                      |
| Ubuntu-24.10             |    -    |    -    |         |         |    -    |    -    |         |         | Oracular_Oriole     |      | 2024/10/10 | 2025/07/xx |            |            | 6.11                  |                      |
| Ubuntu-25.04             |    -    |    -    |         |         |    -    |    -    |         |         | Plucky_Puffin       |      | 2025/04/17 | 2026/01/xx |            |            | 6.14                  |                      |
| Fedora-40                |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |                     |      | 2024/04/23 | 2025/05/28 |            |            | 6.8                   |                      |
| Fedora-41                |    -    |         |         |    -    |    -    |         |         |    -    |                     |      | 2024/10/29 | 2025/11/19 |            |            | 6.11                  |                      |
| Fedora-42                |    -    |         |         |    -    |    -    |         |         |    -    |                     |      | 2025/04/15 | 2026/05/13 |            |            | 6.14                  |                      |
| Fedora-43                |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |                     |      | 2025/11/11 | 2026/12/02 |            |            |                       |                      |
| CentOS Stream-9          |    -    |         |         |    -    |    -    |         |         |    -    |                     |      | 2021/12/03 | 2027/05/31 |            |            | 5.14.0                |                      |
| CentOS Stream-10         |    -    |         |         |    -    |    -    |         |         |    -    | Coughlan            |      | 2024/12/12 | 2030/01/01 |            |            | 6.12.0                |                      |
| AlmaLinux-8.10           |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Cerulean_Leopard    |      | 2024/05/28 |            |            | 2024/05/22 | 4.18.0_553            |                      |
| AlmaLinux-9.5            |    -    |         |         |    -    |    -    |         |         |    -    | Teal_Serval         |      | 2024/11/18 |            |            | 2024/11/13 | 5.14.0_503.11.1       |                      |
| Rocky Linux-8.10         |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Green_Obsidian      |      | 2024/05/30 |            |            | 2024/05/22 | 4.18.0_553            |                      |
| Rocky Linux-9.5          |    -    |         |         |    -    |    -    |         |         |    -    | Blue_Onyx           |      | 2024/11/19 |            |            | 2024/11/12 | 5.14.0_503.14.1       |                      |
| Miracle Linux-8.8        |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |                     |      | 2023/10/05 |            |            | 2023/05/16 | 4.18.0_477.el8        |                      |
| Miracle Linux-8.10       |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    | Peony               |      | 2024/10/17 |            |            | 2024/05/22 | 4.18.0_553.el8_10     |                      |
| Miracle Linux-9.4        |    -    |         |         |    -    |    -    |         |         |    -    | Feige               |      | 2024/09/02 |            |            | 2024/04/30 | 5.14.0_427.13.1.el9_4 |                      |
| openSUSE-15.6            |    -    |         |         |    -    |    -    |         |         |    -    |                     |      | 2024/06/12 | 2025/12/31 |            |            | 6.4                   |                      |
| openSUSE-16.0            |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |                     |      | 2025/10/xx | 20xx/xx/xx |            |            |                       |                      |
| openSUSE-tumbleweed      |    -    |         |         |    -    |    -    |         |         |    -    |                     |      | 2014/11/xx | 20xx/xx/xx |            |            |                       |                      |
| Win10_22H2_Japanese_x64  |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| Win11_24H2_Japanese_x64  |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| WinPE_ATI2020x64         |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| WinPE_ATI2020x86         |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| WinPEx64.iso             |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| WinPEx86.iso             |    -    |    -    |    -    |    -    |    -    |    -    |    -    |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
| mt86plus                 |    -    |    -    |         |    -    |    -    |    -    |         |    -    |                     |      | 20xx/xx/xx | 20xx/xx/xx |            |            |                       |                      |
  
| media |        edition        |
| :---: | :-------------------- |
| mini  | mini.iso              |
| net   | net install           |
| dvd   | server                |
| live  | desktop or live media |
  
| mark |  status  |
| :--: | :------- |
|  o   | OK       |
|  x   | NG       |
|  -   | Excluded |
  