# --- all ---------------------------------------------------------------------
EXES= \
	./autoinst_cmd/autoinst_cmd_early.sh \
	./autoinst_cmd/autoinst_cmd_late.sh \
	./autoinst_cmd/autoinst_cmd_part.sh \
	./autoinst_cmd/autoinst_cmd_run.sh \
	./custom_cmd/test_server.sh \
	./custom_cmd/mk_custom_iso.sh \
	./custom_cmd/mk_live_iso.sh

.PHONY: all
all:
	@echo "start   : $@"
	@make $(EXES)
	@echo "complete: $@"

# --- clean -------------------------------------------------------------------
.PHONY: clean
clean:
	@echo "start   : $@"
	@echo "rm -f $(EXES)"
	@read -r -p "Are you sure ? [Y or else] " _INPT; \
	 if [ "$${_INPT}" =  "Y" ]; then rm -f $(EXES); echo "deleted"; else echo "cancel"; fi; \
	 unset _INPT
	@echo "complete: $@"

# --- clean backup ------------------------------------------------------------
.PHONY: clbak
clbak:
	@echo "start   : $@"
	@if [ -e ./. ]; then \
	   find ./ \( -iname '*.bak' -o -iname '*~' \) -print; \
	   read -r -p "Are you sure ? [Y or else] " _INPT; \
	   if [ "$${_INPT}" =  "Y" ]; then find ./ \( -iname '*.bak' -o -iname '*~' \) -exec rm {} \;; echo "deleted"; else echo "cancel"; fi; \
	   unset _INPT; \
	 fi
	@if [ -e /srv/user/share/conf/. ]; then \
	   find /srv/user/share/conf/ \( -iname '*.bak' -o -iname '*~' \) -print; \
	   read -r -p "Are you sure ? [Y or else] " _INPT; \
	   if [ "$${_INPT}" =  "Y" ]; then sudo bash -c 'find /srv/user/share/conf/ \( -iname '\''*.bak'\'' -o -iname '\''*~'\'' \) -exec rm {} \;'; echo "deleted"; else echo "cancel"; fi; \
	   unset _INPT; \
	 fi
	@echo "complete: $@"

# --- autoinst_cmd_early.sh ---------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_early.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_early.sh
OBJS= \
	./autoinst_cmd/fnGlobal_variables.sh \
	./_common_sh/fnMsgout.sh \
	./_common_sh/fnString.sh \
	./_common_sh/fnStrmsg.sh \
	./_common_sh/fnIPv6FullAddr.sh \
	./_common_sh/fnIPv6RevAddr.sh \
	./_common_sh/fnIPv4Netmask.sh \
	./autoinst_cmd/fnDbgout.sh \
	./autoinst_cmd/fnDbgdump.sh \
	./autoinst_cmd/fnDbgparam.sh \
	./autoinst_cmd/fnFind_command.sh \
	./autoinst_cmd/fnFind_service.sh \
	./autoinst_cmd/fnSystem_param.sh \
	./autoinst_cmd/fnNetwork_param.sh \
	./autoinst_cmd/fnFile_backup.sh \
	./autoinst_cmd/fnInitialize.sh \
	./autoinst_cmd/fnSetup_wireplumber.sh \
	./autoinst_cmd/fnGet_conf_file.sh \
	./autoinst_cmd/fnCmdline.sh \
	./autoinst_cmd/skel_autoinst_cmd_early.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@sudo chmod +x /srv/user/share/conf/script/$(notdir $@)
	@echo "complete: $@"

# --- autoinst_cmd_late.sh ----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_late.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_late.sh
OBJS= \
	./autoinst_cmd/fnGlobal_variables.sh \
	./_common_sh/fnMsgout.sh \
	./_common_sh/fnString.sh \
	./_common_sh/fnStrmsg.sh \
	./_common_sh/fnIPv6FullAddr.sh \
	./_common_sh/fnIPv6RevAddr.sh \
	./_common_sh/fnIPv4Netmask.sh \
	./autoinst_cmd/fnDbgout.sh \
	./autoinst_cmd/fnDbgdump.sh \
	./autoinst_cmd/fnDbgparam.sh \
	./autoinst_cmd/fnFind_command.sh \
	./autoinst_cmd/fnFind_service.sh \
	./autoinst_cmd/fnSystem_param.sh \
	./autoinst_cmd/fnNetwork_param.sh \
	./autoinst_cmd/fnFile_backup.sh \
	./autoinst_cmd/fnInitialize.sh \
	./autoinst_cmd/fnPackage_update.sh \
	./autoinst_cmd/fnPackage_install.sh \
	./autoinst_cmd/fnMkdir_share.sh \
	./autoinst_cmd/fnSetup_connman.sh \
	./autoinst_cmd/fnSetup_netplan.sh \
	./autoinst_cmd/fnSetup_netman.sh \
	./autoinst_cmd/fnSetup_hostname.sh \
	./autoinst_cmd/fnSetup_hosts.sh \
	./autoinst_cmd/fnSetup_tcp_wrapper.sh \
	./autoinst_cmd/fnSetup_firewalld.sh \
	./autoinst_cmd/fnSetup_dnsmasq.sh \
	./autoinst_cmd/fnSetup_resolv.sh \
	./autoinst_cmd/fnSetup_clamav.sh \
	./autoinst_cmd/fnSetup_apache.sh \
	./autoinst_cmd/fnSetup_samba.sh \
	./autoinst_cmd/fnSetup_timesyncd.sh \
	./autoinst_cmd/fnSetup_chronyd.sh \
	./autoinst_cmd/fnSetup_ssh.sh \
	./autoinst_cmd/fnSetup_vmware.sh \
	./autoinst_cmd/fnSetup_wireplumber.sh \
	./autoinst_cmd/fnSetup_input_method.sh \
	./autoinst_cmd/fnSetup_locale.sh \
	./autoinst_cmd/fnSetup_desktop.sh \
	./autoinst_cmd/fnSetup_skel_user.sh \
	./autoinst_cmd/fnSetup_skel_im_fcitx5.sh \
	./autoinst_cmd/fnSetup_skel_im_ibus.sh \
	./autoinst_cmd/fnSetup_skel_im.sh \
	./autoinst_cmd/fnSetup_skel_copy.sh \
	./autoinst_cmd/fnSetup_dconf.sh \
	./autoinst_cmd/fnSetup_sudo.sh \
	./autoinst_cmd/fnSetup_blacklist.sh \
	./autoinst_cmd/fnSetup_module_ipxe.sh \
	./autoinst_cmd/fnSetup_apparmor.sh \
	./autoinst_cmd/fnSetup_selinux.sh \
	./autoinst_cmd/fnSetup_ipfilter.sh \
	./autoinst_cmd/fnSetup_service.sh \
	./autoinst_cmd/fnSetup_grub_menu.sh \
	./autoinst_cmd/fnCmdline.sh \
	./autoinst_cmd/skel_autoinst_cmd_late.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@sudo chmod +x /srv/user/share/conf/script/$(notdir $@)
	@echo "complete: $@"

# --- autoinst_cmd_part.sh ----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_part.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_part.sh
OBJS= \
	./autoinst_cmd/fnGlobal_variables.sh \
	./_common_sh/fnMsgout.sh \
	./_common_sh/fnString.sh \
	./_common_sh/fnStrmsg.sh \
	./_common_sh/fnIPv6FullAddr.sh \
	./_common_sh/fnIPv6RevAddr.sh \
	./_common_sh/fnIPv4Netmask.sh \
	./autoinst_cmd/fnDbgout.sh \
	./autoinst_cmd/fnDbgparam.sh \
	./autoinst_cmd/fnFind_command.sh \
	./autoinst_cmd/fnSystem_param.sh \
	./autoinst_cmd/fnNetwork_param.sh \
	./autoinst_cmd/fnFile_backup.sh \
	./autoinst_cmd/fnInitialize.sh \
	./autoinst_cmd/fnCmdline.sh \
	./autoinst_cmd/skel_autoinst_cmd_part.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@sudo chmod +x /srv/user/share/conf/script/$(notdir $@)
	@echo "complete: $@"

# --- autoinst_cmd_run.sh -----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_run.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_run.sh
OBJS= \
	./autoinst_cmd/fnGlobal_variables.sh \
	./_common_sh/fnMsgout.sh \
	./_common_sh/fnString.sh \
	./_common_sh/fnStrmsg.sh \
	./_common_sh/fnIPv6FullAddr.sh \
	./_common_sh/fnIPv6RevAddr.sh \
	./_common_sh/fnIPv4Netmask.sh \
	./autoinst_cmd/fnDbgout.sh \
	./autoinst_cmd/fnDbgparam.sh \
	./autoinst_cmd/fnFind_command.sh \
	./autoinst_cmd/fnSystem_param.sh \
	./autoinst_cmd/fnNetwork_param.sh \
	./autoinst_cmd/fnFile_backup.sh \
	./autoinst_cmd/fnInitialize.sh \
	./autoinst_cmd/fnCmdline.sh \
	./autoinst_cmd/skel_autoinst_cmd_run.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@sudo chmod +x /srv/user/share/conf/script/$(notdir $@)
	@echo "complete: $@"

# --- test_server.sh ----------------------------------------------------------
TGET=./custom_cmd/test_server.sh
SRCS=./custom_cmd/skel_test_server.sh
OBJS= \
	./custom_cmd/fnComm_system_common.sh \
	./custom_cmd/fnComm_global_variables.sh \
	./custom_cmd/fnComm_global_common.sh \
	./_common_bash/fnMsgout.sh \
	./_common_bash/fnString.sh \
	./_common_bash/fnStrmsg.sh \
	./_common_bash/fnIPv6FullAddr.sh \
	./_common_bash/fnIPv6RevAddr.sh \
	./_common_bash/fnIPv4Netmask.sh \
	./custom_cmd/fnComm_dbgout.sh \
	./custom_cmd/fnComm_dbgparameters.sh \
	./custom_cmd/fnComm_dbgparameters_all.sh \
	./custom_cmd/fnComm_find_command.sh \
	./custom_cmd/fnComm_system_param.sh \
	./custom_cmd/fnComm_network_param.sh \
	./custom_cmd/fnComm_trap.sh \
	./custom_cmd/fnTest_init_test_server.sh \
	./custom_cmd/fnTest_cmdline.sh \
	./custom_cmd/fnTest_param.sh \
	./custom_cmd/fnTest_service.sh \
	./custom_cmd/fnTest_apparmor.sh \
	./custom_cmd/fnTest_selinux.sh \
	./custom_cmd/fnTest_vmware.sh \
	./custom_cmd/fnTest_netman.sh \
	./custom_cmd/fnTest_port_dns.sh \
	./custom_cmd/fnTest_port_smb.sh \
	./custom_cmd/fnTest_nslookup.sh \
	./custom_cmd/fnTest_dig.sh \
	./custom_cmd/fnTest_getent.sh \
	./custom_cmd/fnTest_ping.sh \
	./custom_cmd/fnTest_timedatectl.sh \
	./custom_cmd/fnTest_chronyc.sh \
	./custom_cmd/fnTest_nmblookup.sh \
	./custom_cmd/fnTest_smbclient.sh \
	./custom_cmd/fnTest_pdbedit.sh \
	./custom_cmd/fnTest_httpd.sh \
	./custom_cmd/fnTest_help_test_server.sh \
	./custom_cmd/fnTest_main_test_server.sh \
	./custom_cmd/skel_test_server.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# ---- mk_custom_iso.sh -------------------------------------------------------
TGET=./custom_cmd/mk_custom_iso.sh
SRCS=./custom_cmd/skel_mk_custom_iso.sh
OBJS= \
	./custom_cmd/fnComm_system_common.sh \
	./custom_cmd/fnComm_global_variables.sh \
	./custom_cmd/fnComm_global_common.sh \
	./_common_bash/fnTrim.sh \
	./_common_bash/fnBasename.sh \
	./_common_bash/fnMsgout.sh \
	./_common_bash/fnString.sh \
	./_common_bash/fnStrmsg.sh \
	./_common_bash/fnGetWebinfo.sh \
	./_common_bash/fnGetFileinfo.sh \
	./custom_cmd/fnComm_dbgout.sh \
	./custom_cmd/fnComm_dbgparameters.sh \
	./custom_cmd/fnComm_dbgparameters_all.sh \
	./custom_cmd/fnComm_find_command.sh \
	./custom_cmd/fnComm_download.sh \
	./custom_cmd/fnComm_rsync.sh \
	./custom_cmd/fnComm_trap.sh \
	./custom_cmd/fnMake_init_mk_custom_iso.sh \
	./custom_cmd/fnComm_list_conf_Get.sh \
	./custom_cmd/fnComm_list_mdia_Get.sh \
	./custom_cmd/fnComm_list_mdia_Put.sh \
	./custom_cmd/fnMake_symlink_dir.sh \
	./custom_cmd/fnMake_symlink.sh \
	./custom_cmd/fnMake_preconf_preseed.sh \
	./custom_cmd/fnMake_preconf_nocloud.sh \
	./custom_cmd/fnMake_preconf_kickstart.sh \
	./custom_cmd/fnMake_preconf_autoyast.sh \
	./custom_cmd/fnMake_preconf_agama.sh \
	./custom_cmd/fnMake_preconf.sh \
	./custom_cmd/fnMake_print_list.sh \
	./custom_cmd/fnComm_xinitrd.sh \
	./custom_cmd/fnMake_boot_option_preseed.sh \
	./custom_cmd/fnMake_boot_option_nocloud.sh \
	./custom_cmd/fnMake_boot_option_kickstart.sh \
	./custom_cmd/fnMake_boot_option_autoyast.sh \
	./custom_cmd/fnMake_boot_option_agama.sh \
	./custom_cmd/fnMake_boot_options.sh \
	./custom_cmd/fnMake_pxeboot_clear_menu.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_hdrftr.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_windows.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_winpe.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_aomei.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_m86p.sh \
	./custom_cmd/fnMake_pxeboot_ipxe_linux.sh \
	./custom_cmd/fnMake_pxeboot_ipxe.sh \
	./custom_cmd/fnMake_pxeboot_grub_hdrftr.sh \
	./custom_cmd/fnMake_pxeboot_grub_windows.sh \
	./custom_cmd/fnMake_pxeboot_grub_winpe.sh \
	./custom_cmd/fnMake_pxeboot_grub_aomei.sh \
	./custom_cmd/fnMake_pxeboot_grub_m86p.sh \
	./custom_cmd/fnMake_pxeboot_grub_linux.sh \
	./custom_cmd/fnMake_pxeboot_grub.sh \
	./custom_cmd/fnMake_pxeboot_slnx_hdrftr.sh \
	./custom_cmd/fnMake_pxeboot_slnx_windows.sh \
	./custom_cmd/fnMake_pxeboot_slnx_winpe.sh \
	./custom_cmd/fnMake_pxeboot_slnx_aomei.sh \
	./custom_cmd/fnMake_pxeboot_slnx_m86p.sh \
	./custom_cmd/fnMake_pxeboot_slnx_linux.sh \
	./custom_cmd/fnMake_pxeboot_slnx.sh \
	./custom_cmd/fnMake_pxeboot.sh \
	./custom_cmd/fnMake_isofile_conf.sh \
	./custom_cmd/fnMake_isofile_grub_autoinst.sh \
	./custom_cmd/fnMake_isofile_grub_theme.sh \
	./custom_cmd/fnMake_isofile_grub.sh \
	./custom_cmd/fnMake_isofile_ilnx_autoinst.sh \
	./custom_cmd/fnMake_isofile_ilnx_theme.sh \
	./custom_cmd/fnMake_isofile_ilnx.sh \
	./custom_cmd/fnComm_xorrisofs.sh \
	./custom_cmd/fnMake_isofile.sh \
	./custom_cmd/fnMake_help_mk_custom_iso.sh \
	./custom_cmd/fnMake_main_mk_custom_iso.sh \
	./custom_cmd/skel_mk_custom_iso.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# ---- mk_live_iso.sh ---------------------------------------------------------
TGET=./custom_cmd/mk_live_iso.sh
SRCS=./custom_cmd/skel_mk_live_iso.sh
OBJS= \
	./custom_cmd/fnComm_system_common.sh \
	./custom_cmd/fnComm_global_variables.sh \
	./custom_cmd/fnComm_global_common.sh \
	./custom_cmd/fnMake_live_global_var.sh \
	./_common_bash/fnTrim.sh \
	./_common_bash/fnBasename.sh \
	./_common_bash/fnMsgout.sh \
	./_common_bash/fnString.sh \
	./_common_bash/fnStrmsg.sh \
	./_common_bash/fnGetWebinfo.sh \
	./_common_bash/fnGetFileinfo.sh \
	./custom_cmd/fnComm_dbgout.sh \
	./custom_cmd/fnComm_dbgparameters.sh \
	./custom_cmd/fnComm_dbgparameters_all.sh \
	./custom_cmd/fnComm_find_command.sh \
	./custom_cmd/fnComm_trap.sh \
	./custom_cmd/fnMake_init_mk_live_iso.sh \
	./custom_cmd/fnComm_list_conf_Get.sh \
	./custom_cmd/fnComm_list_mdia_Get.sh \
	./custom_cmd/fnComm_xorrisofs.sh \
	./custom_cmd/fnComm_find_codename.sh \
	./custom_cmd/fnComm_find_distribution.sh \
	./custom_cmd/fnComm_find_kernel.sh \
	./custom_cmd/fnComm_mkosi.sh \
	./custom_cmd/fnComm_squashfs.sh \
	./custom_cmd/fnComm_grub_module.sh \
	./custom_cmd/fnComm_grub_conf.sh \
	./custom_cmd/fnComm_grub_theme.sh \
	./custom_cmd/fnComm_ilnx_conf.sh \
	./custom_cmd/fnComm_ilnx_theme.sh \
	./custom_cmd/fnMake_live_preconf.sh \
	./custom_cmd/fnMake_live_mkosi.sh \
	./custom_cmd/fnMake_live_vmimg_p1.sh \
	./custom_cmd/fnMake_live_vmimg_p2.sh \
	./custom_cmd/fnMake_live_vmimg.sh \
	./custom_cmd/fnMake_live_cdimg_cdfs.sh \
	./custom_cmd/fnMake_live_cdimg_grub.sh \
	./custom_cmd/fnMake_live_cdimg_ilnx.sh \
	./custom_cmd/fnMake_live_cdimg.sh \
	./custom_cmd/fnMake_live_build.sh \
	./custom_cmd/fnMake_help_mk_live_iso.sh \
	./custom_cmd/fnMake_main_mk_live_iso.sh \
	./custom_cmd/skel_mk_live_iso.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"
