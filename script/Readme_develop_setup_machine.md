# setup machine

## install

* Debian / Ubuntu

  ``` bash
  sudo bash -c '
    apt-get update
    apt-get --yes install git gawk python3-pefile xxd parted dosfstools grub2-common grub-efi-amd64-bin grub-pc-bin squashfs-tools xorriso && \
    apt-get --yes install qemu-system-x86 websockify novnc && \
    apt-get --yes install debian-archive-keyring ubuntu-keyring distribution-gpg-keys && \
    apt-get --yes install dnf rpm alien elfutils rpm-i18n rpmlint zypper && \
    apt-get --yes install gzip zstd xz-utils lz4 bzip2 lzop && \
    apt-get --yes install bridge-utils && \
    apt-get --yes install nbdkit libnbd-bin && \
  '
  ```

## network

* bridge

  ``` bash
  # br0: 192.168.1.1/24, 192.168.1.254
  # ens160
  sudo bash -c '
    mkdir -p /etc/qemu
    echo "allow br0" > /etc/qemu/bridge.conf
    # setup network manager
    nmcli connection add type bridge ifname br0 \
      connection.id br0 \
      connection.interface-name br0 \
      ipv4.method manual \
      ipv4.address 192.168.1.1/24 \
      ipv4.gateway 192.168.1.254
    nmcli connection modify br0 bridge.stp no
    nmcli connection modify ens160 master br0 slave-type bridge
    # 他サービス
    while read -r __PATH
    do
    sed -i "${__PATH}"      \
        -e 's/ens160/br0/g'
    done < <(find /etc/dnsmasq.d/ /etc/samba/ /etc/firewalld/zones/ -type f || true)
    systemctl daemon-reload
    systemctl restart dnsmasq.service
    systemctl restart smb.service nmb.service
    systemctl restart firewalld.service
  '
  ```

* nbd

  ``` bash
  # exports
  sudo bash -c '
    rm -rf /srv/exports/nbd
    mkdir -p /srv/exports/nbd
    find /srv/user/share/isos/ /srv/user/share/rmak/ -type f -name '*.iso' -exec ln -s {} /srv/exports/nbd/ \;
  '
  # nbdkit.socket
  cat <<- _EOT_ | sudo tee /etc/systemd/system/nbdkit.socket
    [Unit]
    Description=NBDKit Network Block Device server
    [Socket]
    ListenStream=10809
    # Optional settings to detect dead clients:
    #KeepAlive=true
    #KeepAliveTimeSec=60
    #KeepAliveIntervalSec=10
    #KeepAliveProbes=5
    [Install]
    WantedBy=sockets.target
  _EOT_
  # nbdkit.service
  cat <<- _EOT_ | sudo tee /etc/systemd/system/nbdkit.service
    [Service]
    ExecStart=$(command -v nbdkit) --exit-with-parent --readonly file cache=default fadvise=normal dir=/srv/exports/nbd
    # Optional settings to run as non-root:
    #User=nbd
    #Group=nbd
  _EOT_
  # サービス起動
  sudo systemctl daemon-reload
  sudo systemctl enable --now nbdkit.socket
  systemctl status nbdkit.socket nbdkit.service
  # 動作確認
  nbdinfo --list nbd://localhost
  ```
