# shellcheck disable=SC2148

# -----------------------------------------------------------------------------
# descript: finalize dracut
#   input :            : unused
#   output:   stdout   : message
#   return:            : unused
#   g-var :  FUNCNAME  : read
#   g-var : _PROG_NAME : read
# shellcheck disable=SC2148,SC2317,SC2329
function fnMkosi_finalize_dracut() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	# --- dracut --------------------------------------------------------------
	declare -r    __SHEL="/bin/bash"
	#	dracut --list-modules --no-kernel
	# __MODS[0]: a:add, o:omit, -:exclusion, D:Debian/Ubuntu, R:RHEL/..., S:opensSUSE/SUSE
	declare -r -a __MODS=(\
		"a  00  bash                            bash_(bash_is_preferred_interpreter_if_there_more_of_them_available)                                    "	\
		"!  00  dash                            dash                                                                                                    "	\
		"-  00  mksh                            -                                                                                                       "	\
		"a  00  systemd                         Adds_systemd_as_early_init_initialization_system                                                        "	\
		"!  00  systemd-network-management      Adds_network_management_for_systemd                                                                     "	\
		"!  00  warpclock                       Sets_kernel's_timezone_and_reset_the_system_time_if_adjtime_is_set_to_LOCAL                             "	\
		"!  01  fips                            Enforces_FIPS_security_standard_regulations                                                             "	\
		"!  01  systemd-ac-power                systemd-ac-power                                                                                        "	\
		"!  01  systemd-ask-password            systemd-ask-password                                                                                    "	\
		"-  01  systemd-coredump                systemd-coredump                                                                                        "	\
		"!  01  systemd-hostnamed               systemd-hostnamed                                                                                       "	\
		"!  01  systemd-initrd                  systemd-initrd                                                                                          "	\
		"!  01  systemd-integritysetup          systemd-integritysetup                                                                                  "	\
		"!  01  systemd-journald                systemd-journald                                                                                        "	\
		"!  01  systemd-ldconfig                systemd-ldconfig                                                                                        "	\
		"a  01  systemd-modules-load            systemd-modules-load                                                                                    "	\
		"!  01  systemd-networkd                systemd-networkd                                                                                        "	\
		"-  01  systemd-pcrphase                systemd-pcrphase                                                                                        "	\
		"!  01  systemd-portabled               systemd-portabled                                                                                       "	\
		"!  01  systemd-pstore                  systemd-pstore                                                                                          "	\
		"!  01  systemd-repart                  systemd-repart                                                                                          "	\
		"!  01  systemd-resolved                systemd-resolved                                                                                        "	\
		"!  01  systemd-rfkill                  -                                                                                                       "	\
		"a  01  systemd-sysctl                  systemd-sysctl                                                                                          "	\
		"!  01  systemd-sysext                  systemd-sysext                                                                                          "	\
		"!  60  systemd-sysusers                systemd-sysusers                                                                                        "	\
		"!  01  systemd-timedated               systemd-timedated                                                                                       "	\
		"!  01  systemd-timesyncd               systemd-timesyncd                                                                                       "	\
		"a  01  systemd-tmpfiles                systemd-tmpfiles                                                                                        "	\
		"!  01  systemd-udevd                   systemd-udevd                                                                                           "	\
		"!  01  systemd-veritysetup             systemd-veritysetup                                                                                     "	\
		"!  02  caps                            drop_capabilities_before_init                                                                           "	\
		"!  03  modsign                         kernel_module_for_signing,_keyutils                                                                     "	\
		"a  03  rescue                          utilities_for_rescue_mode_(such_as_ping,_ssh,_vi,_fsck.*)                                               "	\
		"!  04  watchdog                        Includes_watchdog_devices_management;_works_only_if_systemd_not_in_use                                  "	\
		"!  04  watchdog-modules                kernel_modules_for_watchdog_loaded_early_in_booting                                                     "	\
		"x  99  busybox                         busybox                                                                                                 "	\
		"-  06  dbus-broker                     dbus-broker                                                                                             "	\
		"a  06  dbus-daemon                     dbus-daemon                                                                                             "	\
		"-  06  rngd                            Starts_random_generator_serive_on_early_boot                                                            "	\
		"!  09  console-setup                   console-setup                                                                                           "	\
		"a  09  dbus                            Virtual_module_for_dbus-broker_or_dbus-daemon                                                           "	\
		"!  10  i18n                            Includes_keymaps,_console_fonts,_etc.                                                                   "	\
		"!  30  convertfs                       Merges_/_into_/usr_on_next_boot                                                                         "	\
		"-  35  connman                         connman                                                                                                 "	\
		"!  35  network-legacy                  Includes_legacy_networking_tools_support                                                                "	\
		"a  --  network-manager                 network-manager                                                                                         "	\
		"!  40  network                         Virtual_module_for_network_service_providers                                                            "	\
		"!  45  ifcfg                           -                                                                                                       "	\
		"a  45  url-lib                         Includes_curl_and_SSL_certs                                                                             "	\
		"!  45  drm                             kernel_modules_for_DRM_(complex_graphics_devices)                                                       "	\
		"-  45  plymouth                        show_splash_via_plymouth                                                                                "	\
		"-  62  bluetooth                       Includes_bluetooth_devices_support                                                                      "	\
		"-  80  cms                             -                                                                                                       "	\
		"!  80  lvmmerge                        Merges_lvm_snapshots                                                                                    "	\
		"!  80  lvmthinpool-monitor             Monitor_LVM_thinpool_service                                                                            "	\
		"-  81  cio_ignore                      cio_ignore                                                                                              "	\
		"-  90  btrfs                           btrfs                                                                                                   "	\
		"!  90  crypt                           encrypted_LUKS_filesystems_and_cryptsetup                                                               "	\
		"a  90  dm                              device-mapper                                                                                           "	\
		"!  90  dmraid                          DMRAID_arrays                                                                                           "	\
		"a  90  dmsquash-live                   SquashFS_images                                                                                         "	\
		"a  90  dmsquash-live-autooverlay       creates_a_partition_for_overlayfs_usage_in_the_free_space_on_the_root_filesystem's_parent_block_device  "	\
		"-  90  dmsquash-live-ntfs              SquashFS_images_located_in_NTFS_filesystems                                                             "	\
		"a  90  kernel-modules                  kernel_modules_for_root_filesystems_and_other_boot-time_devices                                         "	\
		"a  90  kernel-modules-extra            extra_out-of-tree_kernel_modules                                                                        "	\
		"a  90  kernel-network-modules          Includes_and_loads_kernel_modules_for_network_devices                                                   "	\
		"!  90  livenet                         Fetch_live_updates_for_SquashFS_images                                                                  "	\
		"!  90  lvm                             LVM_devices                                                                                             "	\
		"!  90  mdraid                          kernel_module_for_md_raid_cluster,_mdadm                                                                "	\
		"!  90  multipath                       multipath_devices                                                                                       "	\
		"!  90  nvdimm                          non-volatile_DIMM_devices                                                                               "	\
		"!  90  overlay-root                    overlay-root                                                                                            "	\
		"!  90  overlayfs                       kernel_module_for_overlayfs                                                                             "	\
		"-  90  ppcmac                          thermal_for_PowerPC                                                                                     "	\
		"!  90  qemu                            kernel_modules_to_boot_inside_qemu                                                                      "	\
		"!  90  qemu-net                        Includes_network_kernel_modules_for_QEMU_environment                                                    "	\
		"!  91  crypt-gpg                       GPG_for_crypto_operations_and_SmartCards_(may_requires_GPG_keys)                                        "	\
		"!  91  crypt-loop                      encrypted_loopback_devices_(symmetric_key)                                                              "	\
		"!  91  fido2                           fido2                                                                                                   "	\
		"-  91  pcsc                            Adds_support_for_PCSC_Smart_cards                                                                       "	\
		"!  91  pkcs11                          Includes_PKCS11_libraries                                                                              "	\
		"-  91  tpm2-tss                        Adds_support_for_TPM2_devices                                                                           "	\
		"-  91  zipl                            zipl                                                                                                    "	\
		"!  95  cifs                            CIFS,_cifs-utils                                                                                        "	\
		"-  95  dasd                            dasd                                                                                                    "	\
		"-  95  dasd_mod                        dasd_mod                                                                                                "	\
		"-  95  dasd_rules                      -                                                                                                       "	\
		"-  95  dcssblk                         dcssblk                                                                                                 "	\
		"!  95  debug                           debug_features                                                                                          "	\
		"-  95  fcoe                            Adds_support_for_Fibre_Channel_over_Ethernet_(FCoE)                                                     "	\
		"-  95  fcoe-uefi                       Adds_support_for_Fibre_Channel_over_Ethernet_(FCoE)_in_EFI_mode                                         "	\
		"-  95  fstab-sys                       Arranges_for_arbitrary_partitions_to_be_mounted_before_rootfs                                           "	\
		"!  95  iscsi                           Adds_support_for_iSCSI_devices                                                                          "	\
		"!  95  lunmask                         Masks_LUN_devices_to_select_only_ones_which_required_to_boot                                            "	\
		"!  95  nbd                             kernel_module_for_Network_Block_Device,_nbd                                                             "	\
		"!  95  nfs                             kernel_module_for_NFS,_nfs-utils                                                                        "	\
		"-  95  nvmf                            Adds_support_for_NVMe_over_Fabrics_devices                                                              "	\
		"-  95  qeth_rules                      -                                                                                                       "	\
		"!  95  resume                          resume_from_low-power_state                                                                             "	\
		"!  95  rootfs-block                    mount_block_device_as_rootfs                                                                            "	\
		"!  95  ssh-client                      Includes_ssh_and_scp_clients                                                                            "	\
		"!  95  terminfo                        Includes_a_terminfo_file                                                                                "	\
		"!  95  udev-rules                      Includes_udev_and_some_basic_rules                                                                      "	\
		"!  95  virtfs                          virtual_filesystems_(9p)                                                                                "	\
		"!  95  virtiofs                        virtiofs                                                                                                "	\
		"-  95  zfcp                            -                                                                                                       "	\
		"-  95  zfcp_rules                      -                                                                                                       "	\
		"-  95  znet                            -                                                                                                       "	\
		"!  96  securityfs                      mount_securityfs_early                                                                                  "	\
		"-  97  biosdevname                     BIOS_network_device_renaming                                                                            "	\
		"!  97  masterkey                       masterkey_that_can_be_used_to_decrypt_other_keys_and_keyutils                                           "	\
		"!  98  dracut-systemd                  Base_systemd_dracut_module                                                                              "	\
		"!  98  ecryptfs                        kernel_module_for_ecryptfs_(stacked_cryptographic_filesystem)                                           "	\
		"!  98  integrity                       Extended_Verification_Module_and_ima-evm-utils                                                          "	\
		"a  98  pollcdrom                       polls_CD-ROM                                                                                            "	\
		"!  98  selinux                         selinux_policy                                                                                          "	\
		"!  98  syslog                          Includes_syslog_capabilites                                                                             "	\
		"!  98  usrmount                        mounts_/usr                                                                                             "	\
		"a  99  base                            Base_module_with_required_utilities                                                                     "	\
		"a  99  fs-lib                          filesystem_tools_(including_fsck.*_and_mount)                                                           "	\
		"!  99  img-lib                         Includes_various_tools_for_decompressing_images                                                         "	\
		"-  99  memstrack                       Includes_memstrack_for_memory_usage_monitoring                                                          "	\
		"a  99  shutdown                        Sets_up_hooks_to_run_on_shutdown                                                                        "	\
		"!  99  uefi-lib                        Includes_UEFI_tools                                                                                     "	\
	)
	declare -r    __KRNL="$(ls /usr/lib/modules/)"
	declare -r    __ARCH="${__KRNL##*[-.]}"
	declare -r    __VERS="${__KRNL%[-.]"${__ARCH}"}"
	declare       __DIST=""				# D:debian/ubuntu, R:rhel/..., S:opensuse/suse
	declare -a    __ADDS=()
	declare -a    __OMIT=()
	declare -a    __OPTN=()
	declare -a    __LIST=()				# work variable
	declare -i    __RTCD=0				# return code
	declare -i    I=0

	__DIST=""
	case "${DISTRIBUTION:-}" in
		debian      | \
		ubuntu      ) __DIST="D";;
		fedora      | \
		centos      | \
		alma        | \
		rocky       | \
		miracle     ) __DIST="R";;
		opensuse    ) __DIST="S";;
#		kali        ) ;;
#		arch        ) ;;
#		mageia      ) ;;
#		rhel-ubi    ) ;;
#		rhel        ) ;;
#		openmandriva) ;;
#		azure       ) ;;
#		custom      ) ;;
		*           ) __DIST="";;
	esac

	__ADDS=()
	__OMIT=()
	for I in "${!__MODS[@]}"
	do
		read -r -a __LIST < <(echo "${__MODS[I]}")
		case "${__LIST[0]}" in
			a    ) __ADDS+=("${__LIST[2]}");;	# common add
			d    ) __OMIT+=("${__LIST[2]}");;	# "      omit
			D|R|S) [[ "${__DIST:-}" = "${__LIST[0]}" ]] && __ADDS+=("${__LIST[2]}");;
			*) continue;;
		esac
	done
	readonly __ADDS
	readonly __OMIT

	__OPTN=(\
		--stdlog 3 \
		--force \
		--no-hostonly \
		--no-early-microcode \
		--nomdadmconf \
		--nolvmconf \
		--gzip \
		${__KRNL:+--kver "${__KRNL}"} \
		${__ADDS[*]:+--add "${__ADDS[*]}"} \
		${__OMIT[*]:+--omit "${__OMIT[*]}"} \
		--filesystems "ext4 fat exfat isofs squashfs udf xfs" \
	)
	readonly __OPTN

	if ! command -v dracut > /dev/null 2>&1; then
		fnMsgout "${_PROG_NAME:-}" "caution" "not exist: dracut"
	else
		if ! dracut "${__OPTN[@]}"; then
			__RTCD="$?"
			fnMsgout "${_PROG_NAME:-}" "failed" "dracut ${__OPTN[*]}"
			fnMsgout "${_PROG_NAME:-}" "start" "${__SHEL}"
			"${__SHEL:?}"
			fnMsgout "${_PROG_NAME:-}" "complete" "${__SHEL}"
			exit "${__RTCD}"
		fi
		cp -a "/usr/lib/modules/${__KRNL}/vmlinuz" "/boot/vmlinuz-${__KRNL}"
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
