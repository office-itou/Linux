# VMware上でLinuxをpipewireでサウンド再生し音割れした時の確認 (**hdaudio版**)

サウンド再生時にブツブツとなってしまうのを回避する。

## 再生できた時のサウンドカード情報

``` bash: wpctl status
[master@sv-fedora ~]$ wpctl status | grep -E 'alsa|bluez5'
 x      51. HD Audio Controller                 [alsa]
 x      93. WI-C310                             [bluez5]
```

## VMware側の確認

### VMwareゲストの構成

|      Device      | composition |
| :--------------- | :---------: |
| Core/Processor   |    1 / 2    |
| Memory           |    8 GiB    |
| NVMe 1           |    64 GiB   |
| CD/DVD (SATA)    |     Yes     |
| Network (Bridge) |    e1000e   |
| USB controller   |   USB 3.1   |
| Sound card       |   hdaudio   |
| Display          |     3D      |
| Bluetooth        |     Yes     |

### 以下が有れば必ずコメントにする

``` text: vmxファイル
#pciSound.PlayBuffer = "500"  # サウンドバッファの指定
#sound.bufferTime = "400"     # サウンドカードのバックグラウンドノイズ対策
```

## Linux側の確認

設定ファイルの追加変更を行ったらサービスを再起動する。

**sudoを使わない事に注意**

``` bash: サービスの再起動
systemctl --user restart wireplumber.service
```

### pipewireのバージョンが0.3.65の場合

#### pipewireのバージョンの確認

``` bash: pipewire --version
master@sv-debian:~$ pipewire --version
pipewire
Compiled with libpipewire 0.3.65
Linked with libpipewire 0.3.65
master@sv-debian:~$
```

#### 追加するファイルのツリー図

``` bash: /etc/wireplumber/wireplumber.conf.d/
master@sv-debian:~$ tree -f --charset C /etc/
/etc/wireplumber
|-- /etc/wireplumber/bluetooth.lua.d
|   `-- /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua
`-- /etc/wireplumber/main.lua.d
    `-- /etc/wireplumber/main.lua.d/50-alsa-config.lua

3 directories, 2 files
```

#### VMwareでの音割れ対策

以下をコピーし変更する。

* コピー元: /usr/share/wireplumber/main.lua.d/50-alsa-config.lua
* コピー先: /etc/wireplumber/main.lua.d/50-alsa-config.lua

``` bash: /etc/wireplumber/main.lua.d/50-alsa-config.lua
master@sv-debian:~$ diff /usr/share/wireplumber/main.lua.d/50-alsa-config.lua /etc/wireplumber/main.lua.d/50-alsa-config.lua
141a142
>         ["api.alsa.period-size"]   = 1024,
143a145
>         ["api.alsa.headroom"]      = 16384,
```

* コピー元: /usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua
* コピー先: /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua

``` bash: /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua
master@sv-debian:~$ diff /usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua /etc/wireplumber/bluetooth.lua.d/50-bluez-config.lua
23a24
>     ["bluez5.headset-roles"] = "[ ]",
30a32
>     ["bluez5.hfphsp-backend"] = "none",
137a140,141
>         ["bluez5.auto-connect"] = "[ a2dp_sink ]",
>         ["bluez5.hw-volume"]    = "[ a2dp_sink ]",
```

### pipewireのバージョンが1.4.1の場合

#### pipewireのバージョンの確認

``` bash: pipewire --version
[master@sv-fedora ~]$ pipewire --version
pipewire
Compiled with libpipewire 1.4.1
Linked with libpipewire 1.4.1
```

#### 追加するファイルのツリー図

``` bash: /etc/wireplumber/wireplumber.conf.d/
[master@sv-fedora ~]$ tree -f --charset C /etc/wireplumber/wireplumber.conf.d/
/etc/wireplumber/wireplumber.conf.d
|-- /etc/wireplumber/wireplumber.conf.d/alsa-vm.conf
`-- /etc/wireplumber/wireplumber.conf.d/bluez.conf

1 directory, 2 files
```

#### VMwareでの音割れ対策

以下をコピーし変更する。

* コピー元: /usr/share/wireplumber/wireplumber.conf.d/alsa-vm.conf
* コピー先: /etc/wireplumber/wireplumber.conf.d/alsa-vm.conf

``` bash: /etc/wireplumber/wireplumber.conf.d/alsa-vm.conf
[master@sv-fedora ~]$ diff /usr/share/wireplumber/wireplumber.conf.d/alsa-vm.conf /etc/wireplumber/wireplumber.conf.d/alsa-vm.conf
19c19
<         api.alsa.headroom      = 2048
---
>         api.alsa.headroom      = 16384
```

#### Bluetoothヘッドセットの制限

以下は新規作成。

``` bash: /etc/wireplumber/wireplumber.conf.d/bluez.conf
[master@sv-fedora ~]$ cat /etc/wireplumber/wireplumber.conf.d/bluez.conf
monitor.bluez.properties = {
  bluez5.headset-roles  = "[ ]"
  bluez5.hfphsp-backend = "none"
}

monitor.bluez.rules = [
  {
    matches = [
      {
        node.name = "~bluez_input.*"
      }
      {
        node.name = "~bluez_output.*"
      }
    ]
    actions = {
      update-props = {
        bluez5.auto-connect = "[ a2dp_sink ]"
        bluez5.hw-volume    = "[ a2dp_sink ]"
      }
    }
  }
]
```

## あとがき

公式WiKiの情報に沿ってpipewire側の設定をしてもVMware側の設定の不備で解決に時間がかかったのでこれを残す。

## 参考

### 主な自動インストール用事前設定ファイル

上記を確認した時の主な自動インストール用事前設定ファイル。

(ネットワーク設定の部分はブートパラメーターで設定できるようにコメントにしている)

|       Distribution       |                                                                 Preconfiguration Files                                                                 |
| :----------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- |
| Debian (preseed.cfg)     | [ps_debian_desktop.cfg](https://github.com/office-itou/Linux/blob/master/shell-script_prototype/conf/preseed/ps_debian_desktop.cfg)                    |
| Ubuntu (cloud-init)      | [user-data](https://github.com/office-itou/Linux/blob/master/shell-script_prototype/conf/nocloud/ubuntu_desktop/user-data)                             |
| Fedora-42 (kickstart)    | [ks_fedora-42_net_desktop.cfg](https://github.com/office-itou/Linux/blob/master/shell-script_prototype/conf/kickstart/ks_fedora-42_net_desktop.cfg)    |
| openSUSE-16 Beta (agama) | [autoinst_leap-16.0_desktop.json](https://github.com/office-itou/Linux/blob/master/shell-script_prototype/conf/agama/autoinst_leap-16.0_desktop.json)  |

### サンプルファイル

上記設定をしたサンプルファイル。

|    pipewire   | Sample file                                                                                                                     |
| :-----------: | :------------------------------------------------------------------------------------------------------------------------------ |
|     0.3.x     | [50-alsa-config.lua](https://github.com/office-itou/Linux/blob/master/laboratory/pipewire/main.lua.d/50-alsa-config.lua)        |
|       "       | [50-bluez-config.lua](https://github.com/office-itou/Linux/blob/master/laboratory/pipewire/bluetooth.lua.d/50-bluez-config.lua) |
|     1.4.x     | [alsa-vm.conf](https://github.com/office-itou/Linux/blob/master/laboratory/pipewire/wireplumber.conf.d/alsa-vm.conf)            |
|       "       | [bluez.conf](https://github.com/office-itou/Linux/blob/master/laboratory/pipewire/wireplumber.conf.d/bluez.conf)                |

### 設定用シェル

上記設定を行うシェル。

[setup_pipewire.sh](https://github.com/office-itou/Linux/blob/master/laboratory/pipewire/setup_pipewire.sh)
