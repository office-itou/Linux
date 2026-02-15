# --- all ---------------------------------------------------------------------
EXES=\
	./autoinst_cmd/autoinst_cmd_early.sh \
	./autoinst_cmd/autoinst_cmd_late.sh \
	./autoinst_cmd/autoinst_cmd_part.sh \
	./autoinst_cmd/autoinst_cmd_run.sh \
	./custom_cmd/test_server.sh \
	./custom_cmd/mk_custom_iso.sh

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

# --- autoinst_cmd_early.sh ---------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_early.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_early.sh
OBJS=\
	./autoinst_cmd/fnGlobal_variables.sh\
	./_common_sh/fnMsgout.sh\
	./_common_sh/fnString.sh\
	./_common_sh/fnStrmsg.sh\
	./_common_sh/fnIPv6FullAddr.sh\
	./_common_sh/fnIPv6RevAddr.sh\
	./_common_sh/fnIPv4Netmask.sh\
	./autoinst_cmd/fnDbgout.sh\
	./autoinst_cmd/fnDbgdump.sh\
	./autoinst_cmd/fnDbgparam.sh\
	./autoinst_cmd/fnFind_command.sh\
	./autoinst_cmd/fnFind_service.sh\
	./autoinst_cmd/fnSystem_param.sh\
	./autoinst_cmd/fnNetwork_param.sh\
	./autoinst_cmd/fnFile_backup.sh\
	./autoinst_cmd/fnInitialize.sh\
	./autoinst_cmd/fnSetup_wireplumber.sh\
	./autoinst_cmd/fnGet_conf_file.sh\
	./autoinst_cmd/fnCmdline.sh\
	./autoinst_cmd/skel_autoinst_cmd_early.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@echo "complete: $@"

# --- autoinst_cmd_late.sh ----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_late.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_late.sh
OBJS=\
	./autoinst_cmd/fnGlobal_variables.sh\
	./_common_sh/fnMsgout.sh\
	./_common_sh/fnString.sh\
	./_common_sh/fnStrmsg.sh\
	./_common_sh/fnIPv6FullAddr.sh\
	./_common_sh/fnIPv6RevAddr.sh\
	./_common_sh/fnIPv4Netmask.sh\
	./autoinst_cmd/fnDbgout.sh\
	./autoinst_cmd/fnDbgdump.sh\
	./autoinst_cmd/fnDbgparam.sh\
	./autoinst_cmd/fnFind_command.sh\
	./autoinst_cmd/fnFind_service.sh\
	./autoinst_cmd/fnSystem_param.sh\
	./autoinst_cmd/fnNetwork_param.sh\
	./autoinst_cmd/fnFile_backup.sh\
	./autoinst_cmd/fnInitialize.sh\
	./autoinst_cmd/fnPackage_update.sh\
	./autoinst_cmd/fnPackage_install.sh \
	./autoinst_cmd/fnMkdir_share.sh\
	./autoinst_cmd/fnSetup_connman.sh\
	./autoinst_cmd/fnSetup_netplan.sh\
	./autoinst_cmd/fnSetup_netman.sh\
	./autoinst_cmd/fnSetup_hostname.sh\
	./autoinst_cmd/fnSetup_hosts.sh\
	./autoinst_cmd/fnSetup_tcp_wrapper.sh\
	./autoinst_cmd/fnSetup_firewalld.sh\
	./autoinst_cmd/fnSetup_dnsmasq.sh\
	./autoinst_cmd/fnSetup_resolv.sh\
	./autoinst_cmd/fnSetup_apache.sh\
	./autoinst_cmd/fnSetup_samba.sh\
	./autoinst_cmd/fnSetup_timesyncd.sh\
	./autoinst_cmd/fnSetup_chronyd.sh\
	./autoinst_cmd/fnSetup_ssh.sh\
	./autoinst_cmd/fnSetup_vmware.sh\
	./autoinst_cmd/fnSetup_wireplumber.sh\
	./autoinst_cmd/fnSetup_input_method.sh\
	./autoinst_cmd/fnSetup_desktop.sh\
	./autoinst_cmd/fnSetup_skel_user.sh\
	./autoinst_cmd/fnSetup_skel_im.sh\
	./autoinst_cmd/fnSetup_skel_copy.sh\
	./autoinst_cmd/fnSetup_sudo.sh\
	./autoinst_cmd/fnSetup_blacklist.sh\
	./autoinst_cmd/fnSetup_module_ipxe.sh\
	./autoinst_cmd/fnSetup_apparmor.sh\
	./autoinst_cmd/fnSetup_selinux.sh\
	./autoinst_cmd/fnSetup_ipfilter.sh\
	./autoinst_cmd/fnSetup_service.sh\
	./autoinst_cmd/fnSetup_grub_menu.sh\
	./autoinst_cmd/fnCmdline.sh\
	./autoinst_cmd/skel_autoinst_cmd_late.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@echo "complete: $@"

# --- autoinst_cmd_part.sh ----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_part.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_part.sh
OBJS=\
	./autoinst_cmd/fnGlobal_variables.sh\
	./_common_sh/fnMsgout.sh\
	./_common_sh/fnString.sh\
	./_common_sh/fnStrmsg.sh\
	./_common_sh/fnIPv6FullAddr.sh\
	./_common_sh/fnIPv6RevAddr.sh\
	./_common_sh/fnIPv4Netmask.sh\
	./autoinst_cmd/fnDbgout.sh\
	./autoinst_cmd/fnDbgparam.sh\
	./autoinst_cmd/fnFind_command.sh\
	./autoinst_cmd/fnSystem_param.sh\
	./autoinst_cmd/fnNetwork_param.sh\
	./autoinst_cmd/fnFile_backup.sh\
	./autoinst_cmd/fnInitialize.sh\
	./autoinst_cmd/fnCmdline.sh\
	./autoinst_cmd/skel_autoinst_cmd_part.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@echo "complete: $@"

# --- autoinst_cmd_run.sh -----------------------------------------------------
TGET=./autoinst_cmd/autoinst_cmd_run.sh
SRCS=./autoinst_cmd/skel_autoinst_cmd_run.sh
OBJS=\
	./autoinst_cmd/fnGlobal_variables.sh\
	./_common_sh/fnMsgout.sh\
	./_common_sh/fnString.sh\
	./_common_sh/fnStrmsg.sh\
	./_common_sh/fnIPv6FullAddr.sh\
	./_common_sh/fnIPv6RevAddr.sh\
	./_common_sh/fnIPv4Netmask.sh\
	./autoinst_cmd/fnDbgout.sh\
	./autoinst_cmd/fnDbgparam.sh\
	./autoinst_cmd/fnFind_command.sh\
	./autoinst_cmd/fnSystem_param.sh\
	./autoinst_cmd/fnNetwork_param.sh\
	./autoinst_cmd/fnFile_backup.sh\
	./autoinst_cmd/fnInitialize.sh\
	./autoinst_cmd/fnCmdline.sh\
	./autoinst_cmd/skel_autoinst_cmd_run.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/script/
	@echo "complete: $@"

# --- test_server.sh ----------------------------------------------------------
TGET=./custom_cmd/test_server.sh
SRCS=./custom_cmd/skel_test_server.sh
OBJS=\
	./custom_cmd/fnSystem_common.sh \
	./custom_cmd/fnGlobal_variables.sh \
	./custom_cmd/fnGlobal_common.sh \
	./_common_bash/fnMsgout.sh \
	./_common_bash/fnString.sh \
	./_common_bash/fnStrmsg.sh \
	./_common_bash/fnIPv6FullAddr.sh \
	./_common_bash/fnIPv6RevAddr.sh \
	./_common_bash/fnIPv4Netmask.sh \
	./custom_cmd/fnDbgout.sh \
	./custom_cmd/fnDbgparameters.sh \
	./custom_cmd/fnDbgparameters_all.sh \
	./custom_cmd/fnFind_command.sh \
	./custom_cmd/fnSystem_param.sh \
	./custom_cmd/fnNetwork_param.sh \
	./custom_cmd/fnTrap.sh \
	./custom_cmd/fnInitialize_test_server.sh \
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
	./custom_cmd/fnHelp_test_server.sh \
	./custom_cmd/fnMain_test_server.sh \
	./custom_cmd/skel_test_server.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "complete: $@"

# ---- mk_custom_iso.sh -------------------------------------------------------
TGET=./custom_cmd/mk_custom_iso.sh
SRCS=./custom_cmd/skel_mk_custom_iso.sh
OBJS=\
	./custom_cmd/fnSystem_common.sh \
	./custom_cmd/fnGlobal_variables.sh \
	./custom_cmd/fnGlobal_common.sh \
	./_common_bash/fnTrim.sh \
	./_common_bash/fnBasename.sh \
	./_common_bash/fnMsgout.sh \
	./_common_bash/fnString.sh \
	./_common_bash/fnStrmsg.sh \
	./_common_bash/fnGetWebinfo.sh \
	./_common_bash/fnGetFileinfo.sh \
	./custom_cmd/fnDbgout.sh \
	./custom_cmd/fnDbgparameters.sh \
	./custom_cmd/fnDbgparameters_all.sh \
	./custom_cmd/fnFind_command.sh \
	./custom_cmd/fnDownload.sh \
	./custom_cmd/fnRsync.sh \
	./custom_cmd/fnTrap.sh \
	./custom_cmd/fnInitialize.sh \
	./custom_cmd/fnList_conf_Get.sh \
	./custom_cmd/fnList_mdia_Get.sh \
	./custom_cmd/fnList_mdia_Put.sh \
	./custom_cmd/fnMk_symlink_dir.sh \
	./custom_cmd/fnMk_symlink.sh \
	./custom_cmd/fnMk_preconf_preseed.sh \
	./custom_cmd/fnMk_preconf_nocloud.sh \
	./custom_cmd/fnMk_preconf_kickstart.sh \
	./custom_cmd/fnMk_preconf_autoyast.sh \
	./custom_cmd/fnMk_preconf_agama.sh \
	./custom_cmd/fnMk_preconf.sh \
	./custom_cmd/fnMk_print_list.sh \
	./custom_cmd/fnXinitrd.sh \
	./custom_cmd/fnMk_boot_option_preseed.sh \
	./custom_cmd/fnMk_boot_option_nocloud.sh \
	./custom_cmd/fnMk_boot_option_kickstart.sh \
	./custom_cmd/fnMk_boot_option_autoyast.sh \
	./custom_cmd/fnMk_boot_option_agama.sh \
	./custom_cmd/fnMk_boot_options.sh \
	./custom_cmd/fnMk_pxeboot_clear_menu.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_hdrftr.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_windows.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_winpe.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_aomei.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_m86p.sh \
	./custom_cmd/fnMk_pxeboot_ipxe_linux.sh \
	./custom_cmd/fnMk_pxeboot_ipxe.sh \
	./custom_cmd/fnMk_pxeboot_grub_hdrftr.sh \
	./custom_cmd/fnMk_pxeboot_grub_windows.sh \
	./custom_cmd/fnMk_pxeboot_grub_winpe.sh \
	./custom_cmd/fnMk_pxeboot_grub_aomei.sh \
	./custom_cmd/fnMk_pxeboot_grub_m86p.sh \
	./custom_cmd/fnMk_pxeboot_grub_linux.sh \
	./custom_cmd/fnMk_pxeboot_grub.sh \
	./custom_cmd/fnMk_pxeboot_slnx_hdrftr.sh \
	./custom_cmd/fnMk_pxeboot_slnx_windows.sh \
	./custom_cmd/fnMk_pxeboot_slnx_winpe.sh \
	./custom_cmd/fnMk_pxeboot_slnx_aomei.sh \
	./custom_cmd/fnMk_pxeboot_slnx_m86p.sh \
	./custom_cmd/fnMk_pxeboot_slnx_linux.sh \
	./custom_cmd/fnMk_pxeboot_slnx.sh \
	./custom_cmd/fnMk_pxeboot.sh \
	./custom_cmd/fnMk_isofile_conf.sh \
	./custom_cmd/fnMk_isofile_grub_autoinst.sh \
	./custom_cmd/fnMk_isofile_grub_theme.sh \
	./custom_cmd/fnMk_isofile_grub.sh \
	./custom_cmd/fnMk_isofile_ilnx_autoinst.sh \
	./custom_cmd/fnMk_isofile_ilnx_theme.sh \
	./custom_cmd/fnMk_isofile_ilnx.sh \
	./custom_cmd/fnMk_isofile_rebuild.sh \
	./custom_cmd/fnMk_isofile.sh \
	./custom_cmd/fnHelp_mk_custom_iso.sh \
	./custom_cmd/fnMain_mk_custom_iso.sh \
	./custom_cmd/skel_mk_custom_iso.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@./mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@echo "complete: $@"
