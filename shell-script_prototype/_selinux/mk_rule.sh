#!/bin/sh

set -eu

	readonly PROG_PATH="$0"
#	readonly PROG_PRAM="$*"
#	readonly PROG_DIRS="${PROG_PATH%/*}"
	readonly PROG_NAME="${PROG_PATH##*/}"
#	readonly PROG_PROC="${PROG_NAME}.$$"

	         DIRS_INIT="${PWD}"

# --- selinux settings: compile -----------------------------------------------
funcSepolicy_compile() {
	_TGET_DIRS="${1:?}"
	_TGET_NAME="${2:?}"
	_CURR_DIRS="${PWD}"
	cd "${_TGET_DIRS}"
	printf "\033[m${PROG_NAME}: \033[96m%s\033[m\n" "    compile : ${_TGET_NAME}"
	make -s -f /usr/share/selinux/devel/Makefile "${_TGET_NAME}.pp" || exit
	printf "\033[m${PROG_NAME}: \033[96m%s\033[m\n" "    install : ${_TGET_NAME}"
	semodule -i "${_TGET_NAME}.pp"
}

# --- selinux settings: NetworkManager_t --------------------------------------
funcSepolicy_NetworkManager() {
	_TGET_TYPE="NetworkManager_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type NetworkManager_etc_t;'                                    \
	    -e 'a \  type default_t;'                                               \
	    -e 'a \  type init_runtime_t;'                                          \
	    -e 'a \  type initrc_runtime_t;'                                        \
	    -e 'a \  type init_t;'                                                  \
	    -e 'a \  type security_t;'                                              \
	    -e 'a \  type udev_runtime_t;'                                          \
	    -e 'a \  type udev_t;'                                                  \
	    -e 'a \  type usr_t;'                                                   \
	    -e 'a \  type xdg_cache_t;'                                             \
	    -e 'a \  type xdm_t;'                                                   \
	    -e 'a \  class dir { add_name create getattr open read remove_name search write };'  \
	    -e 'a \  class file { append create execute execute_no_trans getattr ioctl map open read rename setattr unlink write };' \
	    -e 'a \  class lnk_file { create unlink };'                             \
	    -e 'a \  class sock_file write;'                                        \
	    -e 'a \  class system reload;'                                          \
	    -e 'a \  class unix_stream_socket connectto;'                           \
	    -e 'a \  class lnk_file read;'                                          \
	    -e 'a \  class dir { read watch };'                                     \
	    -e 'a \  class netlink_selinux_socket { create bind };'                 \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow NetworkManager_t NetworkManager_etc_t:dir watch;'          \
	    -e '$a allow NetworkManager_t default_t:dir search;'                    \
	    -e '$a allow NetworkManager_t init_runtime_t:file { create open read rename setattr unlink write };'   \
	    -e '$a allow NetworkManager_t init_runtime_t:lnk_file { create unlink };'                              \
	    -e '$a allow NetworkManager_t initrc_runtime_t:dir { add_name getattr open read remove_name search };' \
	    -e '$a allow NetworkManager_t initrc_runtime_t:file { create rename setattr unlink };'                 \
	    -e '$a allow NetworkManager_t security_t:file map;'                     \
	    -e '$a allow NetworkManager_t udev_runtime_t:dir { add_name read remove_name };'                       \
	    -e '$a allow NetworkManager_t udev_runtime_t:file { create rename setattr unlink write };'             \
	    -e '$a allow NetworkManager_t udev_runtime_t:sock_file write;'          \
	    -e '$a allow NetworkManager_t udev_t:unix_stream_socket connectto;'     \
	    -e '$a allow NetworkManager_t usr_t:file { execute execute_no_trans };' \
	    -e '$a allow NetworkManager_t xdg_cache_t:dir search;'                  \
	    -e '$a allow NetworkManager_t init_runtime_t:dir { add_name remove_name write };' \
	    -e '$a allow NetworkManager_t initrc_runtime_t:dir { create write };'   \
	    -e '$a allow NetworkManager_t init_t:system reload;'                    \
	    -e '$a allow NetworkManager_t usr_t:file map;'                          \
	    -e '$a allow NetworkManager_t xdm_t:unix_stream_socket connectto;'      \
	    -e '$a allow NetworkManager_t self:netlink_selinux_socket { create bind };'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: dnsmasq_t ---------------------------------------------
funcSepolicy_dnsmasq() {
	_TGET_TYPE="dnsmasq_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type systemd_resolved_runtime_t;'                              \
	    -e 'a \  class lnk_file read;'                                          \
	    -e 'a \  class dir { read watch };'                                     \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow dnsmasq_t systemd_resolved_runtime_t:dir { read watch };'  \
	    -e '$a allow dnsmasq_t systemd_resolved_runtime_t:lnk_file read;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: firewalld_t -------------------------------------------
funcSepolicy_firewalld() {
	_TGET_TYPE="firewalld_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type firewalld_tmpfs_t;'                                       \
	    -e 'a \  type initrc_t;'                                                \
	    -e 'a \  type proc_t;'                                                  \
	    -e 'a \  type sysctl_kernel_t;'                                         \
	    -e 'a \  type unconfined_t;'                                            \
	    -e 'a \  type user_home_dir_t;'                                         \
	    -e 'a \  class capability { dac_read_search setpcap };'                 \
	    -e 'a \  class dbus send_msg;'                                          \
	    -e 'a \  class dir search;'                                             \
	    -e 'a \  class file { execute open read };'                             \
	    -e 'a \  class filesystem getattr;'                                     \
	    -e 'a \  class process { getcap setcap };'                              \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow firewalld_t firewalld_tmpfs_t:file execute;'               \
	    -e '$a allow firewalld_t initrc_t:dbus send_msg;'                       \
	    -e '$a allow firewalld_t proc_t:filesystem getattr;'                    \
	    -e '$a allow firewalld_t sysctl_kernel_t:dir search;'                   \
	    -e '$a allow firewalld_t sysctl_kernel_t:file { open read };'           \
	    -e '$a allow firewalld_t user_home_dir_t:dir search;'                   \
	    -e '$a allow firewalld_t unconfined_t:dbus send_msg;'                   \
	    -e '$a allow firewalld_t self:capability { dac_read_search setpcap };'  \
	    -e '$a allow firewalld_t self:process { getcap setcap };'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: fwupd_t -----------------------------------------------
funcSepolicy_fwupd() {
	_TGET_TYPE="fwupd_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type default_t;'                                               \
	    -e 'a \  type fwupd_conf_t;'                                            \
	    -e 'a \  type fwupd_var_lib_t;'                                         \
	    -e 'a \  type gpg_agent_exec_t;'                                        \
	    -e 'a \  type proc_t;'                                                  \
	    -e 'a \  type removable_device_t;'                                      \
	    -e 'a \  type security_t;'                                              \
	    -e 'a \  type sysctl_kernel_t;'                                         \
	    -e 'a \  type sysfs_t;'                                                 \
	    -e 'a \  class dir { search watch };'                                   \
	    -e 'a \  class file { execute execute_no_trans map open read setattr write };' \
	    -e 'a \  class blk_file { open read };'                                 \
	    -e 'a \  class sock_file { create getattr setattr write };'             \
	    -e 'a \  class unix_stream_socket connectto;'                           \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow fwupd_t default_t:dir search;'                             \
	    -e '$a allow fwupd_t fwupd_conf_t:file { setattr write };'              \
	    -e '$a allow fwupd_t fwupd_var_lib_t:sock_file { create getattr setattr write };' \
	    -e '$a allow fwupd_t gpg_agent_exec_t:file { execute execute_no_trans map open read };' \
	    -e '$a allow fwupd_t proc_t:dir watch;'                                 \
	    -e '$a allow fwupd_t removable_device_t:blk_file { open read };'        \
	    -e '$a allow fwupd_t security_t:dir watch;'                             \
	    -e '$a allow fwupd_t sysctl_kernel_t:dir watch;'                        \
	    -e '$a allow fwupd_t sysfs_t:dir watch;'                                \
	    -e '$a allow fwupd_t sysfs_t:file map;'                                 \
	    -e '$a allow fwupd_t self:unix_stream_socket connectto;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: getty_t -----------------------------------------------
funcSepolicy_getty() {
	_TGET_TYPE="getty_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  class capability2 checkpoint_restore;'                         \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow getty_t self:capability2 checkpoint_restore;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: httpd_t -----------------------------------------------
funcSepolicy_httpd() {
	_TGET_TYPE="httpd_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type fusefs_t;'                                                \
	    -e 'a \  type public_content_t;'                                        \
	    -e 'a \  type tftpdir_t;'                                               \
	    -e 'a \  class dir { getattr open read search };'                       \
	    -e 'a \  class file { getattr open read map };'                         \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow httpd_t fusefs_t:dir { getattr open read search };'        \
	    -e '$a allow httpd_t fusefs_t:file { getattr open read map };'          \
	    -e '$a allow httpd_t public_content_t:file map;'                        \
	    -e '$a allow httpd_t tftpdir_t:dir { getattr open read search };'       \
	    -e '$a allow httpd_t tftpdir_t:file { getattr open read };'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: initrc_t ----------------------------------------------
funcSepolicy_initrc() {
	_TGET_TYPE="initrc_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  class process execmem;'                                        \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow initrc_t self:process execmem;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: kmod_t ------------------------------------------------
funcSepolicy_kmod() {
	_TGET_TYPE="kmod_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  class capability net_admin;'                                   \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow kmod_t self:capability net_admin;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: mount_t -----------------------------------------------
funcSepolicy_mount() {
	_TGET_TYPE="mount_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type sysctl_vm_overcommit_t;'                                  \
	    -e 'a \  type sysctl_vm_t;'                                             \
	    -e 'a \  type tmp_t;'                                                   \
	    -e 'a \  class process signal;'                                         \
	    -e 'a \  class dir { search };'                                         \
	    -e 'a \  class file { open read write };'                               \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow mount_t tmp_t:file { open read write };'                   \
	    -e '$a allow mount_t self:process signal;'                              \
	    -e '$a allow mount_t sysctl_vm_overcommit_t:file { open read };'        \
	    -e '$a allow mount_t sysctl_vm_t:dir search;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: sshd_t ------------------------------------------------
funcSepolicy_sshd() {
	_TGET_TYPE="sshd_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type lib_t;'                                                   \
	    -e 'a \  type systemd_runtime_notify_t;'                                \
	    -e 'a \  type unconfined_t;'                                            \
	    -e 'a \  type user_home_dir_t;'                                         \
	    -e 'a \  type usr_t;'                                                   \
	    -e 'a \  type var_lib_t;'                                               \
	    -e 'a \  type var_t;'                                                   \
	    -e 'a \  type boot_t;'                                                  \
	    -e 'a \  type fixed_disk_device_t;'                                     \
	    -e 'a \  type fsadm_exec_t;'                                            \
	    -e 'a \  type mount_exec_t;'                                            \
	    -e 'a \  type mount_runtime_t;'                                         \
	    -e 'a \  type var_log_t;'                                               \
	    -e 'a \  type xdg_cache_t;'                                             \
	    -e 'a \  class dir { add_name create getattr search write };'           \
	    -e 'a \  class file { append create execute execute_no_trans getattr ioctl map open read };' \
	    -e 'a \  class capability dac_override;'                                \
	    -e 'a \  class cap_userns sys_ptrace;'                                  \
	    -e 'a \  class sock_file getattr;'                                      \
	    -e 'a \  class key { link search };'                                    \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow sshd_t lib_t:file execute_no_trans;'                       \
	    -e '$a allow sshd_t systemd_runtime_notify_t:sock_file getattr;'        \
	    -e '$a allow sshd_t unconfined_t:key { link search };'                  \
	    -e '$a allow sshd_t user_home_dir_t:dir { add_name create write };'     \
	    -e '$a allow sshd_t user_home_dir_t:file { create getattr open write };' \
	    -e '$a allow sshd_t usr_t:file { execute execute_no_trans };'           \
	    -e '$a allow sshd_t var_lib_t:file { getattr open read setattr write };' \
	    -e '$a allow sshd_t var_t:file { getattr open read };'                  \
	    -e '$a allow sshd_t boot_t:dir search;'                                 \
	    -e '$a allow sshd_t fixed_disk_device_t:blk_file { getattr ioctl open read };' \
	    -e '$a allow sshd_t fsadm_exec_t:file { execute execute_no_trans getattr map open read };' \
	    -e '$a allow sshd_t mount_exec_t:file { execute execute_no_trans getattr map open read };' \
	    -e '$a allow sshd_t mount_runtime_t:dir search;'                        \
	    -e '$a allow sshd_t var_log_t:dir { add_name write };'                  \
	    -e '$a allow sshd_t var_log_t:file { append create getattr ioctl open };' \
	    -e '$a allow sshd_t xdg_cache_t:dir search;'                            \
	    -e '$a allow sshd_t self:capability dac_override;'                      \
	    -e '$a allow sshd_t self:cap_userns sys_ptrace;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: system_dbusd_t ----------------------------------------
funcSepolicy_system_dbusd() {
	_TGET_TYPE="system_dbusd_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type var_lib_t;'                                               \
	    -e 'a \  class dir watch;'                                              \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow system_dbusd_t var_lib_t:dir watch;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_generator_t -----------------------------------
funcSepolicy_systemd_generator() {
	_TGET_TYPE="systemd_generator_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type init_runtime_t;'                                          \
	    -e 'a \  type initrc_runtime_t;'                                        \
	    -e 'a \  type usr_t;'                                                   \
	    -e 'a \  type var_run_t;'                                               \
	    -e 'a \  class capability sys_rawio;'                                   \
	    -e 'a \  class dir { add_name create search write };'                   \
	    -e 'a \  class file { append create map open read unlink write };'      \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_generator_t init_runtime_t:file unlink;'           \
	    -e '$a allow systemd_generator_t initrc_runtime_t:dir search;'          \
	    -e '$a allow systemd_generator_t initrc_runtime_t:file { append open write };' \
	    -e '$a allow systemd_generator_t usr_t:file { map open read };'         \
	    -e '$a allow systemd_generator_t var_run_t:dir { add_name create write };' \
	    -e '$a allow systemd_generator_t var_run_t:file { append create open write };' \
	    -e '$a allow systemd_generator_t self:capability sys_rawio;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_journal_init_t --------------------------------
funcSepolicy_systemd_journal_init() {
	_TGET_TYPE="systemd_journal_init_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type etc_runtime_t;'                                           \
	    -e 'a \  type systemd_journal_t;'                                       \
	    -e 'a \  type var_log_t;'                                               \
	    -e 'a \  class dir search;'                                             \
	    -e 'a \  class file { getattr ioctl map open read write };'             \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_journal_init_t etc_runtime_t:file { open read };'  \
	    -e '$a allow systemd_journal_init_t systemd_journal_t:file map;'        \
	    -e '$a allow systemd_journal_init_t var_log_t:dir search;'              \
	    -e '$a allow systemd_journal_init_t var_log_t:file { getattr ioctl write };'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_logind_t --------------------------------------
funcSepolicy_systemd_logind() {
	_TGET_TYPE="systemd_logind_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type unconfined_t;'                                            \
	    -e 'a \  class fd use;'                                                 \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_logind_t unconfined_t:fd use;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_resolved_t ------------------------------------
funcSepolicy_systemd_resolved() {
	_TGET_TYPE="systemd_resolved_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type NetworkManager_t;'                                        \
	    -e 'a \  type locale_t;'                                                \
	    -e 'a \  class dir search;'                                             \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_resolved_t NetworkManager_t:dir search;'           \
	    -e '$a allow systemd_resolved_t locale_t:dir search;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_tmpfiles_t ------------------------------------
funcSepolicy_systemd_tmpfiles() {
	_TGET_TYPE="systemd_tmpfiles_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type bin_t;'                                                   \
	    -e 'a \  type init_exec_t;'                                             \
	    -e 'a \  type shell_exec_t;'                                            \
	    -e 'a \  type tmpfs_t;'                                                 \
	    -e 'a \  type locale_t;'                                                 \
	    -e 'a \  class dir { search write };'                                   \
	    -e 'a \  class file { add_name create getattr ioctl open read setattr write };' \
	    -e 'a \  class lnk_file { create getattr read };'                       \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_tmpfiles_t bin_t:lnk_file read;'                   \
	    -e '$a allow systemd_tmpfiles_t init_exec_t:file getattr;'              \
	    -e '$a allow systemd_tmpfiles_t tmpfs_t:dir write;'                     \
	    -e '$a allow systemd_tmpfiles_t tmpfs_t:lnk_file { create getattr read };' \
	    -e '$a allow systemd_tmpfiles_t bin_t:dir search;'                      \
	    -e '$a allow systemd_tmpfiles_t init_exec_t:file { open read };'        \
	    -e '$a allow systemd_tmpfiles_t shell_exec_t:file { getattr open read };' \
	    -e '$a allow systemd_tmpfiles_t tmpfs_t:dir { add_name create setattr };' \
	    -e '$a allow systemd_tmpfiles_t tmpfs_t:file { create getattr ioctl open setattr write };' \
	    -e '$a allow systemd_tmpfiles_t locale_t:file read;' \
	    -e '$a allow systemd_tmpfiles_t locale_t:lnk_file read;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: systemd_user_runtime_dir_t ----------------------------
funcSepolicy_systemd_user_runtime_dir() {
	_TGET_TYPE="systemd_user_runtime_dir_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type locale_t;'                                                \
	    -e 'a \  class dir search;'                                             \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow systemd_user_runtime_dir_t locale_t:dir search;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: udev_t ------------------------------------------------
funcSepolicy_udev() {
	_TGET_TYPE="udev_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type init_runtime_t;'                                          \
	    -e 'a \  type nsfs_t;'                                                  \
	    -e 'a \  class file { getattr ioctl open read };'                       \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow udev_t init_runtime_t:file { getattr ioctl open read };'   \
	    -e '$a allow udev_t nsfs_t:file { getattr open read };'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: unconfined_t ------------------------------------------
funcSepolicy_unconfined() {
	_TGET_TYPE="unconfined_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  class process execmem;'                                        \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow unconfined_t self:process execmem;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: useradd_t ---------------------------------------------
funcSepolicy_useradd() {
	_TGET_TYPE="useradd_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  class capability dac_read_search;'                             \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow useradd_t self:capability dac_read_search;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: vmware_tools_t ----------------------------------------
funcSepolicy_vmware_tools() {
	_TGET_TYPE="vmware_tools_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type vmware_log_t;'                                            \
	    -e 'a \  type vmware_vgauth_service_t;'                                 \
	    -e 'a \  type NetworkManager_t;'                                        \
	    -e 'a \  type auditd_t;'                                                \
	    -e 'a \  type blkmapd_t;'                                               \
	    -e 'a \  type boot_t;'                                                  \
	    -e 'a \  type crond_t;'                                                 \
	    -e 'a \  type dnsmasq_t;'                                               \
	    -e 'a \  type firewalld_t;'                                             \
	    -e 'a \  type getty_t;'                                                 \
	    -e 'a \  type httpd_t;'                                                 \
	    -e 'a \  type kernel_t;'                                                \
	    -e 'a \  type modemmanager_t;'                                          \
	    -e 'a \  type mount_t;'                                                 \
	    -e 'a \  type nfsd_t;'                                                  \
	    -e 'a \  type nmbd_t;'                                                  \
	    -e 'a \  type ntpd_t;'                                                  \
	    -e 'a \  type policykit_t;'                                             \
	    -e 'a \  type rpcbind_t;'                                               \
	    -e 'a \  type rpcd_t;'                                                  \
	    -e 'a \  type smbd_t;'                                                  \
	    -e 'a \  type sshd_t;'                                                  \
	    -e 'a \  type syslogd_t;'                                               \
	    -e 'a \  type system_dbusd_t;'                                          \
	    -e 'a \  type systemd_logind_t;'                                        \
	    -e 'a \  type systemd_resolved_runtime_t;'                              \
	    -e 'a \  type systemd_resolved_t;'                                      \
	    -e 'a \  type udev_t;'                                                  \
	    -e 'a \  type unconfined_t;'                                            \
	    -e 'a \  type urandom_device_t;'                                        \
	    -e 'a \  type vmware_vgauth_service_t;'                                 \
	    -e 'a \  type winbind_t;'                                               \
	    -e 'a \  type dosfs_t;'                                                 \
	    -e 'a \  class dir { read search };'                                    \
	    -e 'a \  class file { getattr open unlink read write };'                \
	    -e 'a \  class chr_file read;'                                          \
	    -e 'a \  class capability { net_admin sys_ptrace };'                    \
	    -e 'a \  class blk_file read;'                                          \
	    -e 'a \  class filesystem getattr;'                                     \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow vmware_tools_t NetworkManager_t:dir search;'               \
	    -e '$a allow vmware_tools_t NetworkManager_t:file read;'                \
	    -e '$a allow vmware_tools_t auditd_t:dir search;'                       \
	    -e '$a allow vmware_tools_t auditd_t:file read;'                        \
	    -e '$a allow vmware_tools_t blkmapd_t:dir search;'                      \
	    -e '$a allow vmware_tools_t blkmapd_t:file read;'                       \
	    -e '$a allow vmware_tools_t boot_t:dir search;'                         \
	    -e '$a allow vmware_tools_t crond_t:dir search;'                        \
	    -e '$a allow vmware_tools_t crond_t:file read;'                         \
	    -e '$a allow vmware_tools_t dnsmasq_t:dir search;'                      \
	    -e '$a allow vmware_tools_t dnsmasq_t:file read;'                       \
	    -e '$a allow vmware_tools_t dosfs_t:filesystem getattr;'                \
	    -e '$a allow vmware_tools_t firewalld_t:dir search;'                    \
	    -e '$a allow vmware_tools_t firewalld_t:file read;'                     \
	    -e '$a allow vmware_tools_t getty_t:dir search;'                        \
	    -e '$a allow vmware_tools_t getty_t:file read;'                         \
	    -e '$a allow vmware_tools_t httpd_t:dir search;'                        \
	    -e '$a allow vmware_tools_t httpd_t:file read;'                         \
	    -e '$a allow vmware_tools_t kernel_t:dir search;'                       \
	    -e '$a allow vmware_tools_t kernel_t:file read;'                        \
	    -e '$a allow vmware_tools_t modemmanager_t:dir search;'                 \
	    -e '$a allow vmware_tools_t modemmanager_t:file read;'                  \
	    -e '$a allow vmware_tools_t mount_t:dir search;'                        \
	    -e '$a allow vmware_tools_t mount_t:file read;'                         \
	    -e '$a allow vmware_tools_t nfsd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t nfsd_t:file read;'                          \
	    -e '$a allow vmware_tools_t nmbd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t nmbd_t:file read;'                          \
	    -e '$a allow vmware_tools_t ntpd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t ntpd_t:file read;'                          \
	    -e '$a allow vmware_tools_t policykit_t:dir search;'                    \
	    -e '$a allow vmware_tools_t policykit_t:file read;'                     \
	    -e '$a allow vmware_tools_t rpcbind_t:dir search;'                      \
	    -e '$a allow vmware_tools_t rpcbind_t:file read;'                       \
	    -e '$a allow vmware_tools_t rpcd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t rpcd_t:file read;'                          \
	    -e '$a allow vmware_tools_t smbd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t smbd_t:file read;'                          \
	    -e '$a allow vmware_tools_t sshd_t:dir search;'                         \
	    -e '$a allow vmware_tools_t sshd_t:file read;'                          \
	    -e '$a allow vmware_tools_t syslogd_t:dir search;'                      \
	    -e '$a allow vmware_tools_t syslogd_t:file read;'                       \
	    -e '$a allow vmware_tools_t system_dbusd_t:dir search;'                 \
	    -e '$a allow vmware_tools_t system_dbusd_t:file read;'                  \
	    -e '$a allow vmware_tools_t systemd_logind_t:dir search;'               \
	    -e '$a allow vmware_tools_t systemd_logind_t:file read;'                \
	    -e '$a allow vmware_tools_t systemd_resolved_runtime_t:dir search;'     \
	    -e '$a allow vmware_tools_t systemd_resolved_runtime_t:file { getattr open read };' \
	    -e '$a allow vmware_tools_t systemd_resolved_t:dir search;'             \
	    -e '$a allow vmware_tools_t systemd_resolved_t:file read;'              \
	    -e '$a allow vmware_tools_t udev_t:dir search;'                         \
	    -e '$a allow vmware_tools_t udev_t:file read;'                          \
	    -e '$a allow vmware_tools_t unconfined_t:dir search;'                   \
	    -e '$a allow vmware_tools_t unconfined_t:file read;'                    \
	    -e '$a allow vmware_tools_t urandom_device_t:chr_file read;'            \
	    -e '$a allow vmware_tools_t vmware_log_t:file { unlink write };'        \
	    -e '$a allow vmware_tools_t vmware_vgauth_service_t:dir search;'        \
	    -e '$a allow vmware_tools_t vmware_vgauth_service_t:file { open read};' \
	    -e '$a allow vmware_tools_t winbind_t:dir search;'                      \
	    -e '$a allow vmware_tools_t winbind_t:file read;'                       \
	    -e '$a allow vmware_tools_t self:capability sys_ptrace;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

# --- selinux settings: winbind_t ---------------------------------------------
funcSepolicy_winbind() {
	_TGET_TYPE="winbind_t"
	if ! seinfo -t | grep -q "${_TGET_TYPE}"; then
		return
	fi
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    start   : ${_TGET_TYPE}"
	sepolicy generate --customize -d "${_TGET_TYPE}" -n "custom_${_TGET_TYPE%_t}" --path "${_DIRS_TGET}" > /dev/null
	sed -i "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.te"                           \
	    -e "/type[ \t]\+${_TGET_TYPE};/ {"                                      \
	    -e 'a \  type samba_var_t;'                                             \
	    -e 'a \  type samba_runtime_t;'                                         \
	    -e 'a \  type samba_log_t;'                                             \
	    -e 'a \  type shell_exec_t;'                                            \
	    -e 'a \  type urandom_device_t;'                                        \
	    -e 'a \  class file { map execute };'                                   \
	    -e 'a \  class capability { net_admin setgid };'                        \
	    -e 'a \  class chr_file write;'                                         \
	    -e 'a \  class unix_dgram_socket sendto;'                               \
	    -e 's/^[ \t]*\([^ \t].*;\)$/  \1/g'                                     \
	    -e '}'                                                                  \
	    -e '$a allow winbind_t samba_runtime_t:file map;'                       \
	    -e '$a allow winbind_t samba_var_t:file map;'                           \
	    -e '$a allow winbind_t samba_log_t:file { read unlink write };'         \
	    -e '$a allow winbind_t shell_exec_t:file execute;'                      \
	    -e '$a allow winbind_t urandom_device_t:chr_file write;'                \
	    -e '$a allow winbind_t self:capability { net_admin setgid };'           \
	    -e '$a allow winbind_t self:unix_dgram_socket sendto;'
	: > "${_DIRS_TGET}/custom_${_TGET_TYPE%_t}.if"
	funcSepolicy_compile "${_DIRS_TGET}" "custom_${_TGET_TYPE%_t}"
	printf "\033[m${PROG_NAME}: \033[92m%s\033[m\n" "    complete: ${_TGET_TYPE}"
}

	# --- custom rule ---------------------------------------------------------
	# ausearch --start today | audit2allow -a -M test_rule
	if command -v sepolicy > /dev/null 2>&1; then
		_DIRS_TGET="${DIRS_INIT}/tmp/rule"
		rm -rf "{_DIRS_TGET:?}"
		mkdir -p "${_DIRS_TGET}"
		# --- make rule -------------------------------------------------------
		funcSepolicy_NetworkManager				# NetworkManager_t
		funcSepolicy_dnsmasq					# dnsmasq_t
		funcSepolicy_firewalld					# firewalld_t
		funcSepolicy_fwupd						# fwupd_t
		funcSepolicy_getty						# getty_t
		funcSepolicy_httpd						# httpd_t
		funcSepolicy_initrc						# initrc_t
		funcSepolicy_kmod						# kmod_t
		funcSepolicy_mount						# mount_t
		funcSepolicy_sshd						# sshd_t
		funcSepolicy_system_dbusd				# system_dbusd_t
		funcSepolicy_systemd_generator			# systemd_generator_t
		funcSepolicy_systemd_journal_init		# systemd_journal_init_t
		funcSepolicy_systemd_logind				# systemd_logind_t
		funcSepolicy_systemd_resolved			# systemd_resolved_t
		funcSepolicy_systemd_tmpfiles			# systemd_tmpfiles_t
		funcSepolicy_systemd_user_runtime_dir	# systemd_user_runtime_dir_t
		funcSepolicy_udev						# udev_t
		funcSepolicy_unconfined					# unconfined_t
		funcSepolicy_useradd					# useradd_t
		funcSepolicy_vmware_tools				# vmware_tools_t
		funcSepolicy_winbind					# winbind_t
	fi
