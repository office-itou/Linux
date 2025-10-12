# SELinux  

## Create and install SELinux policy package files  

### Tree diagram of the files that will be created  

The files are placed under the current directory at the time of execution as follows.  

``` bash:
./tmp/rule/
|-- custom_NetworkManager.fc
|-- custom_NetworkManager.if
|-- custom_NetworkManager.pp
|-- custom_NetworkManager.sh
|-- custom_NetworkManager.te
|-- custom_NetworkManager_selinux.spec
|-- custom_accountsd ...
|-- custom_colord ...
|-- custom_devicekit_disk ...
|-- custom_dnsmasq ...
|-- custom_firewalld ...
|-- custom_fwupd ...
|-- custom_getty ...
|-- custom_httpd ...
|-- custom_initrc ...
|-- custom_kmod ...
|-- custom_low_mem_mon ...
|-- custom_mount ...
|-- custom_semanage ...
|-- custom_smbd ...
|-- custom_sshd ...
|-- custom_switcheroo ...
|-- custom_system_dbusd ...
|-- custom_systemd_generator ...
|-- custom_systemd_journal_init ...
|-- custom_systemd_logind ...
|-- custom_systemd_resolved ...
|-- custom_systemd_tmpfiles ...
|-- custom_systemd_user_runtime_dir ...
|-- custom_udev ...
|-- custom_unconfined ...
|-- custom_useradd ...
|-- custom_vmware_tools ...
|-- custom_winbind ...
|-- custom_xdm ...
`-- tmp
```

### Packages required to run  

``` bash:
apt-get install -y selinux-basics selinux-policy-default auditd rpm
```

### Executing a shell  

By executing this shell, a package policy file will be created and installed.  

``` bash:
sudo ./mk_rule.sh
```

### Runtime logs  

``` bash:
mk_rule.sh:     start   : NetworkManager_t
Compiling default custom_NetworkManager module
Creating default custom_NetworkManager.pp policy package
mk_rule.sh:     complete: NetworkManager_t
mk_rule.sh:     start   : accountsd_t
Compiling default custom_accountsd module
Creating default custom_accountsd.pp policy package
mk_rule.sh:     complete: accountsd_t
mk_rule.sh:     start   : colord_t
Compiling default custom_colord module
Creating default custom_colord.pp policy package
mk_rule.sh:     complete: colord_t
mk_rule.sh:     start   : devicekit_disk_t
Compiling default custom_devicekit_disk module
Creating default custom_devicekit_disk.pp policy package
mk_rule.sh:     complete: devicekit_disk_t
mk_rule.sh:     start   : dnsmasq_t
Compiling default custom_dnsmasq module
Creating default custom_dnsmasq.pp policy package
mk_rule.sh:     complete: dnsmasq_t
mk_rule.sh:     start   : firewalld_t
Compiling default custom_firewalld module
Creating default custom_firewalld.pp policy package
mk_rule.sh:     complete: firewalld_t
mk_rule.sh:     start   : fwupd_t
Compiling default custom_fwupd module
Creating default custom_fwupd.pp policy package
mk_rule.sh:     complete: fwupd_t
mk_rule.sh:     start   : getty_t
Compiling default custom_getty module
Creating default custom_getty.pp policy package
mk_rule.sh:     complete: getty_t
mk_rule.sh:     start   : httpd_t
Compiling default custom_httpd module
Creating default custom_httpd.pp policy package
mk_rule.sh:     complete: httpd_t
mk_rule.sh:     start   : initrc_t
Compiling default custom_initrc module
Creating default custom_initrc.pp policy package
mk_rule.sh:     complete: initrc_t
mk_rule.sh:     start   : kmod_t
Compiling default custom_kmod module
Creating default custom_kmod.pp policy package
mk_rule.sh:     complete: kmod_t
mk_rule.sh:     start   : low_mem_mon_t
Compiling default custom_low_mem_mon module
Creating default custom_low_mem_mon.pp policy package
mk_rule.sh:     complete: low_mem_mon_t
mk_rule.sh:     start   : mount_t
Compiling default custom_mount module
Creating default custom_mount.pp policy package
mk_rule.sh:     complete: mount_t
mk_rule.sh:     start   : semanage_t
Compiling default custom_semanage module
Creating default custom_semanage.pp policy package
mk_rule.sh:     complete: semanage_t
mk_rule.sh:     start   : smbd_t
Compiling default custom_smbd module
Creating default custom_smbd.pp policy package
mk_rule.sh:     complete: smbd_t
mk_rule.sh:     start   : sshd_t
Compiling default custom_sshd module
Creating default custom_sshd.pp policy package
mk_rule.sh:     complete: sshd_t
mk_rule.sh:     start   : switcheroo_t
Compiling default custom_switcheroo module
Creating default custom_switcheroo.pp policy package
mk_rule.sh:     complete: switcheroo_t
mk_rule.sh:     start   : system_dbusd_t
Compiling default custom_system_dbusd module
Creating default custom_system_dbusd.pp policy package
mk_rule.sh:     complete: system_dbusd_t
mk_rule.sh:     start   : systemd_generator_t
Compiling default custom_systemd_generator module
Creating default custom_systemd_generator.pp policy package
mk_rule.sh:     complete: systemd_generator_t
mk_rule.sh:     start   : systemd_journal_init_t
Compiling default custom_systemd_journal_init module
Creating default custom_systemd_journal_init.pp policy package
mk_rule.sh:     complete: systemd_journal_init_t
mk_rule.sh:     start   : systemd_logind_t
Compiling default custom_systemd_logind module
Creating default custom_systemd_logind.pp policy package
mk_rule.sh:     complete: systemd_logind_t
mk_rule.sh:     start   : systemd_resolved_t
Compiling default custom_systemd_resolved module
Creating default custom_systemd_resolved.pp policy package
mk_rule.sh:     complete: systemd_resolved_t
mk_rule.sh:     start   : systemd_tmpfiles_t
Compiling default custom_systemd_tmpfiles module
Creating default custom_systemd_tmpfiles.pp policy package
mk_rule.sh:     complete: systemd_tmpfiles_t
mk_rule.sh:     start   : systemd_user_runtime_dir_t
Compiling default custom_systemd_user_runtime_dir module
Creating default custom_systemd_user_runtime_dir.pp policy package
mk_rule.sh:     complete: systemd_user_runtime_dir_t
mk_rule.sh:     start   : udev_t
Compiling default custom_udev module
Creating default custom_udev.pp policy package
mk_rule.sh:     complete: udev_t
mk_rule.sh:     start   : unconfined_t
Compiling default custom_unconfined module
Creating default custom_unconfined.pp policy package
mk_rule.sh:     complete: unconfined_t
mk_rule.sh:     start   : useradd_t
Compiling default custom_useradd module
Creating default custom_useradd.pp policy package
mk_rule.sh:     complete: useradd_t
mk_rule.sh:     start   : vmware_tools_t
Compiling default custom_vmware_tools module
Creating default custom_vmware_tools.pp policy package
mk_rule.sh:     complete: vmware_tools_t
mk_rule.sh:     start   : winbind_t
Compiling default custom_winbind module
Creating default custom_winbind.pp policy package
mk_rule.sh:     complete: winbind_t
mk_rule.sh:     start   : xdm_t
Compiling default custom_xdm module
Creating default custom_xdm.pp policy package
mk_rule.sh:     complete: xdm_t
mk_rule.sh:     start   : install modules
libsemanage.add_user: user sddm not in password file
mk_rule.sh:     complete: install modules
```

### SELinux policy package files installation tree diagram

#### for debian

``` bash:
/var/lib/selinux/default/active/modules/400/
|-- custom_NetworkManager
|   |-- cil
|   |-- hll
|   `-- lang_ext
|-- custom_accountsd ...
|-- custom_colord ...
|-- custom_devicekit_disk ...
|-- custom_dnsmasq ...
|-- custom_firewalld ...
|-- custom_fwupd ...
|-- custom_getty ...
|-- custom_httpd ...
|-- custom_initrc ...
|-- custom_kmod ...
|-- custom_low_mem_mon ...
|-- custom_mount ...
|-- custom_semanage ...
|-- custom_smbd ...
|-- custom_sshd ...
|-- custom_switcheroo ...
|-- custom_system_dbusd ...
|-- custom_systemd_generator ...
|-- custom_systemd_journal_init ...
|-- custom_systemd_logind ...
|-- custom_systemd_resolved ...
|-- custom_systemd_tmpfiles ...
|-- custom_systemd_user_runtime_dir ...
|-- custom_udev ...
|-- custom_unconfined ...
|-- custom_useradd ...
|-- custom_vmware_tools ...
|-- custom_winbind ...
`-- custom_xdm ...
```
