# **Bridge Connection**

## setup

<details><summary>install (apt-get)</summary>

``` bash:
sudo bash -c '
  apt-get update
  apt-get install qemu-system bridge-utils
'
```

</details>

<details><summary>bridge</summary>

``` bash:
sudo bash -c '
  mkdir -p /etc/qemu
  echo "allow br0" > /etc/qemu/bridge.conf
'
```

</details>

<details><summary>network (permanent)</summary>

``` bash:
sudo bash -c '
  [[ -e /etc/NetworkManager/system-connections/Wired\ connection\ 1 ]] && nmcli connection delete Wired\ connection\ 1
  [[ -e /etc/NetworkManager/system-connections/ens160.nmconnection  ]] && nmcli connection delete ens160
  [[ -e /etc/NetworkManager/system-connections/br0.nmconnection     ]] && nmcli connection delete br0
  nmcli connection add type bridge \
    autoconnect yes \
    con-name br0 \
    ifname br0 \
    bridge.stp no \
    ipv4.addresses 192.168.1.1/24 \
    ipv4.gateway 192.168.1.254 \
    ipv4.dns 192.168.1.254 \
    ipv4.dns-search workgroup \
    ipv4.method manual \
    ipv6.method auto \
    connection.zone home_use
  nmcli connection add type bridge-slave autoconnect yes con-name ens160 master br0
  brctl stp br0 off
  brctl show
  nmcli connection show
  sleep 1
  reboot
'
```

</details>

<details><summary>qemu (nvme) (debian/ubuntu)</summary>

``` bash:
mkdir -p ~/qemu
cd ~/qemu
qemu-img create -f raw qemu-nvme.raw 20G
sudo qemu-system-x86_64 \
  -enable-kvm \
  -boot menu=on \
  -m 4G \
  -device nvme,drive=nvme0,serial=deadbeef \
  -drive file=qemu-nvme.raw,if=none,id=nvme0,format=raw \
  -nic bridge,id=br0 \
  -nographic \
  -vga virtio \
  -full-screen \
  -display curses,charset=CP932 \
  -k ja
```

</details>

## configuration files

<details><summary>cat /etc/NetworkManager/system-connections/br0.nmconnection</summary>

``` bash
$ sudo cat /etc/NetworkManager/system-connections/br0.nmconnection
[connection]
id=br0
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
type=bridge
interface-name=br0
zone=home_use

[ethernet]

[bridge]
stp=false

[ipv4]
address1=192.168.1.1/24
dns=192.168.1.254;
dns-search=workgroup;
gateway=192.168.1.254
method=manual

[ipv6]
addr-gen-mode=default
method=auto

[proxy]
```

</details>

<details><summary>cat /etc/NetworkManager/system-connections/ens160.nmconnection</summary>

``` bash
$ sudo cat /etc/NetworkManager/system-connections/ens160.nmconnection
[connection]
id=ens160
uuid=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
type=ethernet
controller=br0
port-type=bridge

[ethernet]

[bridge-port]
```

</details>
