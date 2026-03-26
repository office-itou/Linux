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
	# __MODS[0]: a:add, o:omit, -:exclusion
	# __MODS[1]: Debian/ubuntu
	# __MODS[2]: Rhel
	# __MODS[3]: order
	# __MODS[4]: Name
	# __MODS[5]: summary
	declare -r -a __MODS=(\
		"a  D   R   00  bash                            bash_(bash_is_preferred_interpreter_if_there_more_of_them_available)                                    "	\
		"!  D   -   00  dash                            dash                                                                                                    "	\
		"-  D   -   00  mksh                            -                                                                                                       "	\
		"a  D   R   00  systemd                         Adds_systemd_as_early_init_initialization_system                                                        "	\
		"!  D   R   00  systemd-network-management      Adds_network_management_for_systemd                                                                     "	\
		"!  D   R   00  warpclock                       Sets_kernel's_timezone_and_reset_the_system_time_if_adjtime_is_set_to_LOCAL                             "	\
		"!  D   R   01  fips                            Enforces_FIPS_security_standard_regulations                                                             "	\
		"-  -   R   01  fips-crypto-policies            -                                                                                                       "	\
		"!  D   R   01  systemd-ac-power                systemd-ac-power                                                                                        "	\
		"!  D   R   01  systemd-ask-password            systemd-ask-password                                                                                    "	\
		"-  -   R   01  systemd-battery-check           -                                                                                                       "	\
		"-  -   R   01  systemd-bsod                    -                                                                                                       "	\
		"-  D   R   01  systemd-coredump                systemd-coredump                                                                                        "	\
		"-  -   R   01  systemd-creds                   -                                                                                                       "	\
		"-  -   R   01  systemd-cryptsetup              -                                                                                                       "	\
		"!  D   R   01  systemd-hostnamed               systemd-hostnamed                                                                                       "	\
		"!  D   R   01  systemd-initrd                  systemd-initrd                                                                                          "	\
		"!  D   R   01  systemd-integritysetup          systemd-integritysetup                                                                                  "	\
		"!  D   R   01  systemd-journald                systemd-journald                                                                                        "	\
		"!  D   R   01  systemd-ldconfig                systemd-ldconfig                                                                                        "	\
		"a  D   R   01  systemd-modules-load            systemd-modules-load                                                                                    "	\
		"!  D   R   01  systemd-networkd                systemd-networkd                                                                                        "	\
		"-  D   R   01  systemd-pcrphase                systemd-pcrphase                                                                                        "	\
		"!  D   R   01  systemd-portabled               systemd-portabled                                                                                       "	\
		"!  D   R   01  systemd-pstore                  systemd-pstore                                                                                          "	\
		"!  D   R   01  systemd-repart                  systemd-repart                                                                                          "	\
		"!  D   R   01  systemd-resolved                systemd-resolved                                                                                        "	\
		"!  D   -   01  systemd-rfkill                  -                                                                                                       "	\
		"a  D   R   01  systemd-sysctl                  systemd-sysctl                                                                                          "	\
		"!  D   R   01  systemd-sysext                  systemd-sysext                                                                                          "	\
		"!  D   R   01  systemd-timedated               systemd-timedated                                                                                       "	\
		"!  D   R   01  systemd-timesyncd               systemd-timesyncd                                                                                       "	\
		"a  D   R   01  systemd-tmpfiles                systemd-tmpfiles                                                                                        "	\
		"!  D   R   01  systemd-udevd                   systemd-udevd                                                                                           "	\
		"!  D   R   01  systemd-veritysetup             systemd-veritysetup                                                                                     "	\
		"!  D   -   02  caps                            drop_capabilities_before_init                                                                           "	\
		"!  D   R   03  modsign                         kernel_module_for_signing,_keyutils                                                                     "	\
		"a  D   R   03  rescue                          utilities_for_rescue_mode_(such_as_ping,_ssh,_vi,_fsck.*)                                               "	\
		"!  D   R   04  watchdog                        Includes_watchdog_devices_management;_works_only_if_systemd_not_in_use                                  "	\
		"!  D   R   04  watchdog-modules                kernel_modules_for_watchdog_loaded_early_in_booting                                                     "	\
		"-  -   R   05  nss-softokn                     -                                                                                                       "	\
		"-  D   R   06  dbus-broker                     dbus-broker                                                                                             "	\
		"a  D   R   06  dbus-daemon                     dbus-daemon                                                                                             "	\
		"-  D   R   06  rngd                            Starts_random_generator_serive_on_early_boot                                                            "	\
		"!  D   -   09  console-setup                   console-setup                                                                                           "	\
		"a  D   R   09  dbus                            Virtual_module_for_dbus-broker_or_dbus-daemon                                                           "	\
		"a  D   R   10  i18n                            Includes_keymaps,_console_fonts,_etc.                                                                   "	\
		"!  D   R   30  convertfs                       Merges_/_into_/usr_on_next_boot                                                                         "	\
		"-  D   R   35  connman                         connman                                                                                                 "	\
		"!  D   -   35  network-legacy                  Includes_legacy_networking_tools_support                                                                "	\
		"a  D   R   35  network-manager                 network-manager                                                                                         "	\
		"!  D   R   40  network                         Virtual_module_for_network_service_providers                                                            "	\
		"!  D   R   45  drm                             kernel_modules_for_DRM_(complex_graphics_devices)                                                       "	\
		"!  D   -   45  ifcfg                           -                                                                                                       "	\
		"-  -   R   45  net-lib                         -                                                                                                       "	\
		"!  D   R   45  plymouth                        show_splash_via_plymouth                                                                                "	\
		"-  -   R   45  simpledrm                       -                                                                                                       "	\
		"a  D   R   45  url-lib                         Includes_curl_and_SSL_certs                                                                             "	\
		"!  D   R   60  systemd-sysusers                systemd-sysusers                                                                                        "	\
		"-  D   R   62  bluetooth                       Includes_bluetooth_devices_support                                                                      "	\
		"-  -   R   71  prefixdevname                   -                                                                                                       "	\
		"-  -   R   71  prefixdevname-tools             -                                                                                                       "	\
		"-  D   -   80  cms                             -                                                                                                       "	\
		"!  D   R   80  lvmmerge                        Merges_lvm_snapshots                                                                                    "	\
		"!  D   R   80  lvmthinpool-monitor             Monitor_LVM_thinpool_service                                                                            "	\
		"-  D   -   81  cio_ignore                      cio_ignore                                                                                              "	\
		"-  D   R   90  btrfs                           btrfs                                                                                                   "	\
		"!  D   R   90  crypt                           encrypted_LUKS_filesystems_and_cryptsetup                                                               "	\
		"a  D   R   90  dm                              device-mapper                                                                                           "	\
		"!  D   R   90  dmraid                          DMRAID_arrays                                                                                           "	\
		"a  D   R   90  dmsquash-live                   SquashFS_images                                                                                         "	\
		"a  D   R   90  dmsquash-live-autooverlay       creates_a_partition_for_overlayfs_usage_in_the_free_space_on_the_root_filesystem's_parent_block_device  "	\
		"-  D   R   90  dmsquash-live-ntfs              SquashFS_images_located_in_NTFS_filesystems                                                             "	\
		"a  D   R   90  kernel-modules                  kernel_modules_for_root_filesystems_and_other_boot-time_devices                                         "	\
		"a  D   R   90  kernel-modules-extra            extra_out-of-tree_kernel_modules                                                                        "	\
		"a  D   R   90  kernel-network-modules          Includes_and_loads_kernel_modules_for_network_devices                                                   "	\
		"a  D   R   90  livenet                         Fetch_live_updates_for_SquashFS_images                                                                  "	\
		"!  D   R   90  lvm                             LVM_devices                                                                                             "	\
		"!  D   R   90  mdraid                          kernel_module_for_md_raid_cluster,_mdadm                                                                "	\
		"!  D   R   90  multipath                       multipath_devices                                                                                       "	\
		"-  -   R   90  numlock                         -                                                                                                       "	\
		"!  D   R   90  nvdimm                          non-volatile_DIMM_devices                                                                               "	\
		"!  D   R   90  overlayfs                       kernel_module_for_overlayfs                                                                             "	\
		"!  D   R   90  overlay-root                    overlay-root                                                                                            "	\
		"-  D   R   90  ppcmac                          thermal_for_PowerPC                                                                                     "	\
		"!  D   R   90  qemu                            kernel_modules_to_boot_inside_qemu                                                                      "	\
		"!  D   R   90  qemu-net                        Includes_network_kernel_modules_for_QEMU_environment                                                    "	\
		"!  D   R   91  crypt-gpg                       GPG_for_crypto_operations_and_SmartCards_(may_requires_GPG_keys)                                        "	\
		"!  D   R   91  crypt-loop                      encrypted_loopback_devices_(symmetric_key)                                                              "	\
		"!  D   R   91  fido2                           fido2                                                                                                   "	\
		"-  D   R   91  pcsc                            Adds_support_for_PCSC_Smart_cards                                                                       "	\
		"!  D   R   91  pkcs11                          Includes_PKCS11_libraries                                                                               "	\
		"-  D   R   91  tpm2-tss                        Adds_support_for_TPM2_devices                                                                           "	\
		"-  D   -   91  zipl                            zipl                                                                                                    "	\
		"!  D   R   95  cifs                            CIFS,_cifs-utils                                                                                        "	\
		"-  D   -   95  dasd                            dasd                                                                                                    "	\
		"-  D   -   95  dasd_mod                        dasd_mod                                                                                                "	\
		"-  D   -   95  dasd_rules                      -                                                                                                       "	\
		"-  D   -   95  dcssblk                         dcssblk                                                                                                 "	\
		"!  D   R   95  debug                           debug_features                                                                                          "	\
		"-  D   R   95  fcoe                            Adds_support_for_Fibre_Channel_over_Ethernet_(FCoE)                                                     "	\
		"-  D   R   95  fcoe-uefi                       Adds_support_for_Fibre_Channel_over_Ethernet_(FCoE)_in_EFI_mode                                         "	\
		"-  D   R   95  fstab-sys                       Arranges_for_arbitrary_partitions_to_be_mounted_before_rootfs                                           "	\
		"-  -   R   95  hwdb                            -                                                                                                       "	\
		"!  D   R   95  iscsi                           Adds_support_for_iSCSI_devices                                                                          "	\
		"!  D   R   95  lunmask                         Masks_LUN_devices_to_select_only_ones_which_required_to_boot                                            "	\
		"!  D   R   95  nbd                             kernel_module_for_Network_Block_Device,_nbd                                                             "	\
		"!  D   R   95  nfs                             kernel_module_for_NFS,_nfs-utils                                                                        "	\
		"-  D   R   95  nvmf                            Adds_support_for_NVMe_over_Fabrics_devices                                                              "	\
		"-  D   -   95  qeth_rules                      -                                                                                                       "	\
		"!  D   R   95  resume                          resume_from_low-power_state                                                                             "	\
		"!  D   R   95  rootfs-block                    mount_block_device_as_rootfs                                                                            "	\
		"-  -   R   95  squash-erofs                    -                                                                                                       "	\
		"-  -   R   95  squash-squashfs                 -                                                                                                       "	\
		"a  D   R   95  ssh-client                      Includes_ssh_and_scp_clients                                                                            "	\
		"!  D   R   95  terminfo                        Includes_a_terminfo_file                                                                                "	\
		"!  D   R   95  udev-rules                      Includes_udev_and_some_basic_rules                                                                      "	\
		"a  D   R   95  virtfs                          virtual_filesystems_(9p)                                                                                "	\
		"a  D   R   95  virtiofs                        virtiofs                                                                                                "	\
		"-  D   -   95  zfcp                            -                                                                                                       "	\
		"-  D   -   95  zfcp_rules                      -                                                                                                       "	\
		"-  D   -   95  znet                            -                                                                                                       "	\
		"!  D   R   96  securityfs                      mount_securityfs_early                                                                                  "	\
		"-  D   R   97  biosdevname                     BIOS_network_device_renaming                                                                            "	\
		"!  D   R   97  masterkey                       masterkey_that_can_be_used_to_decrypt_other_keys_and_keyutils                                           "	\
		"-  -   R   97  systemd-emergency               -                                                                                                       "	\
		"!  D   R   98  dracut-systemd                  Base_systemd_dracut_module                                                                              "	\
		"!  D   R   98  ecryptfs                        kernel_module_for_ecryptfs_(stacked_cryptographic_filesystem)                                           "	\
		"!  D   R   98  integrity                       Extended_Verification_Module_and_ima-evm-utils                                                          "	\
		"a  D   R   98  pollcdrom                       polls_CD-ROM                                                                                            "	\
		"!  D   R   98  selinux                         selinux_policy                                                                                          "	\
		"!  D   R   98  syslog                          Includes_syslog_capabilites                                                                             "	\
		"!  D   R   98  usrmount                        mounts_/usr                                                                                             "	\
		"a  D   R   99  base                            Base_module_with_required_utilities                                                                     "	\
		"x  D   R   99  busybox                         busybox                                                                                                 "	\
		"-  -   R   99  earlykdump                      -                                                                                                       "	\
		"a  D   R   99  fs-lib                          filesystem_tools_(including_fsck.*_and_mount)                                                           "	\
		"!  D   R   99  img-lib                         Includes_various_tools_for_decompressing_images                                                         "	\
		"-  -   R   99  kdumpbase                       -                                                                                                       "	\
		"-  D   R   99  memstrack                       Includes_memstrack_for_memory_usage_monitoring                                                          "	\
		"-  -   R   99  microcode_ctl-fw_dir_override   -                                                                                                       "	\
		"-  -   R   99  openssl                         -                                                                                                       "	\
		"-  -   R   99  shell-interpreter               -                                                                                                       "	\
		"!  D   -   99  shutdown                        Sets_up_hooks_to_run_on_shutdown                                                                        "	\
		"-  -   R   99  shutdown                        -                                                                                                       "	\
		"-  -   R   99  squash                          -                                                                                                       "	\
		"-  -   R   99  squash-lib                      -                                                                                                       "	\
		"!  D   R   99  uefi-lib                        Includes_UEFI_tools                                                                                     "	\
	)
	if [[ -e /usr/lib/modules/. ]]; then
		declare -r    __KDIR="/usr/lib/modules"
	else
		declare -r    __KDIR="/lib/modules"
	fi
	declare -r    __KRNL="$(ls "${__KDIR:?}")"
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
			a    ) __ADDS+=("${__LIST[4]}");;	# common add
			d    ) __OMIT+=("${__LIST[4]}");;	# "      omit
			D|R|S) [[ "${__DIST:-}" = "${__LIST[0]}" ]] && __ADDS+=("${__LIST[4]}");;
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
		--force-drivers "nvme" \
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
		if [[ ! -e "/boot/vmlinuz-${__KRNL}" ]]; then
			cp -a "${__KDIR}/${__KRNL}/vmlinuz" "/boot/vmlinuz-${__KRNL}"
		fi
	fi

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
