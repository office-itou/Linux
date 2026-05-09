# **mkosi: tree diagram**

<details><summary>tree --charset C --filesfirst -n /srv/user/share/conf/_mkosi/</summary>

``` bash:
$ tree --charset C --filesfirst -n /srv/user/share/conf/_mkosi/
/srv/user/share/conf/_mkosi/
|-- _template
|   |-- mkosi-debian.conf
|   |-- mkosi-opensuse.conf
|   |-- mkosi-rhel_series.conf
|   |-- mkosi-template.conf
|   `-- mkosi-ubuntu.conf
|-- mkosi.build.d
|-- mkosi.clean.d
|-- mkosi.conf.d
|   |-- mkosi-alma.10.desktop.conf
|   |-- mkosi-alma.10.server.conf
|   |-- mkosi-alma.9.desktop.conf
|   |-- mkosi-alma.9.server.conf
|   |-- mkosi-centos.10.desktop.conf
|   |-- mkosi-centos.10.server.conf
|   |-- mkosi-centos.9.desktop.conf
|   |-- mkosi-centos.9.server.conf
|   |-- mkosi-debian.11.0.bullseye.desktop.conf
|   |-- mkosi-debian.11.0.bullseye.server.conf
|   |-- mkosi-debian.12.0.bookworm.desktop.conf
|   |-- mkosi-debian.12.0.bookworm.server.conf
|   |-- mkosi-debian.13.0.trixie.desktop.conf
|   |-- mkosi-debian.13.0.trixie.server.conf
|   |-- mkosi-debian.14.0.forky.desktop.conf
|   |-- mkosi-debian.14.0.forky.server.conf
|   |-- mkosi-debian.xx.x.experimental.desktop.conf
|   |-- mkosi-debian.xx.x.experimental.server.conf
|   |-- mkosi-debian.xx.x.sid.desktop.conf
|   |-- mkosi-debian.xx.x.sid.server.conf
|   |-- mkosi-debian.xx.x.testing.desktop.conf
|   |-- mkosi-debian.xx.x.testing.server.conf
|   |-- mkosi-fedora.43.desktop.conf
|   |-- mkosi-fedora.43.server.conf
|   |-- mkosi-fedora.44.desktop.conf
|   |-- mkosi-fedora.44.server.conf
|   |-- mkosi-opensuse.15.6.desktop.conf
|   |-- mkosi-opensuse.15.6.server.conf
|   |-- mkosi-opensuse.16.0.desktop.conf
|   |-- mkosi-opensuse.16.0.server.conf
|   |-- mkosi-opensuse.16.1.desktop.conf
|   |-- mkosi-opensuse.16.1.server.conf
|   |-- mkosi-opensuse.tumbleweed.desktop.conf
|   |-- mkosi-opensuse.tumbleweed.server.conf
|   |-- mkosi-rhel.10.desktop.conf
|   |-- mkosi-rhel.10.server.conf
|   |-- mkosi-rhel.9.desktop.conf
|   |-- mkosi-rhel.9.server.conf
|   |-- mkosi-rocky.10.desktop.conf
|   |-- mkosi-rocky.10.server.conf
|   |-- mkosi-rocky.9.desktop.conf
|   |-- mkosi-rocky.9.server.conf
|   |-- mkosi-ubuntu.22.04.jammy.desktop.conf
|   |-- mkosi-ubuntu.22.04.jammy.server.conf
|   |-- mkosi-ubuntu.24.04.noble.desktop.conf
|   |-- mkosi-ubuntu.24.04.noble.server.conf
|   |-- mkosi-ubuntu.25.10.questing.desktop.conf
|   |-- mkosi-ubuntu.25.10.questing.server.conf
|   |-- mkosi-ubuntu.26.04.resolute.desktop.conf
|   `-- mkosi-ubuntu.26.04.resolute.server.conf
|-- mkosi.extra
|-- mkosi.finalize.d
|   `-- mkosi.finalize.sh.chroot
|-- mkosi.postinst.d
|-- mkosi.postoutput.d
|-- mkosi.prepare.d
|-- mkosi.repart
|   `-- 10-root.conf
|-- mkosi.sync.d
|-- repository
|   |-- apt-conf
|   |-- debian-bookworm-backports.sources
|   |-- debian-bullseye-backports.sources
|   |-- debian-experimental-backports.sources
|   |-- debian-forky-backports.sources
|   |-- debian-sid-backports.sources
|   |-- debian-testing-backports.sources
|   |-- debian-trixie-backports.sources
|   |-- opensuse-15.6-backports.repo
|   |-- opensuse-15.6-sle.repo
|   |-- opensuse-repo-non-oss.repo
|   |-- opensuse-repo-oss.repo
|   |-- ubuntu-jammy-backports.sources
|   |-- ubuntu-noble-backports.sources
|   |-- ubuntu-oracular-backports.sources
|   |-- ubuntu-plucky-backports.sources
|   |-- ubuntu-questing-backports.sources
|   `-- ubuntu-resolute-backports.sources
`-- script -> (mount bind /srv/user/share/conf/script/)
    |-- autoinst_cmd_early.sh
    |-- autoinst_cmd_late.sh
    |-- autoinst_cmd_part.sh
    `-- autoinst_cmd_run.sh
```

</details>

<details><summary>tree --charset C --filesfirst -n /usr/local/bin/</summary>

``` bash:
$ tree --charset C --filesfirst -n /usr/local/bin/
/usr/local/bin/
|-- mkosi -> /srv/user/private/src/git/mkosi/bin/mkosi
|-- mkosi-addon -> /srv/user/private/src/git/mkosi/bin/mkosi-addon
|-- mkosi-initrd -> /srv/user/private/src/git/mkosi/bin/mkosi-initrd
`-- mkosi-sandbox -> /srv/user/private/src/git/mkosi/bin/mkosi-sandbox
```

</details>

<details><summary>tree --charset C --filesfirst -n -L 1 /srv/user/private/src/git/mkosi/bin/</summary>

``` bash:
$ tree --charset C --filesfirst -n -L 1 /srv/user/private/src/git/mkosi/bin/
/srv/user/private/src/git/mkosi/bin/
|-- mkosi
|-- mkosi-addon -> mkosi
|-- mkosi-initrd -> mkosi
`-- mkosi-sandbox -> mkosi
```

</details>

<details><summary>tree --charset C --filesfirst -n -L 1 /srv/user/share/cache/</summary>

``` bash:
$ tree --charset C --filesfirst -n -L 1 /srv/user/share/cache/
/srv/user/share/cache/
|-- alma-10-x86-64
|-- alma-9-x86-64
|-- centos-10-x86-64
|-- centos-9-x86-64
|-- debian-bookworm-x86-64
|-- debian-bullseye-x86-64
|-- debian-forky-x86-64
|-- debian-sid-x86-64
|-- debian-testing-x86-64
|-- debian-trixie-x86-64
|-- fedora-43-x86-64
|-- fedora-44-x86-64
|-- opensuse-15.6-x86-64
|-- opensuse-16.0-x86-64
|-- rocky-10-x86-64
|-- rocky-9-x86-64
|-- ubuntu-jammy-x86-64
|-- ubuntu-noble-x86-64
|-- ubuntu-plucky-x86-64
|-- ubuntu-questing-x86-64
`-- ubuntu-resolute-x86-64
```

</details>
