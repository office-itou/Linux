# --- all ---------------------------------------------------------------------
EXES= \
mk_conf_edit.sh \
mk_custom_iso.sh \
mk_custom_live.sh \
mk_downloader.sh \
mk_ipxe_menu.sh

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
	   echo "target:"; \
	   find ./ \( -iname '*.bak' -o -iname '*~' \) -print; \
	   read -r -p "Are you sure ? [Y or else] " _INPT; \
	   if [ "$${_INPT}" =  "Y" ]; then sudo bash -c 'find ./ \( -iname '\''*.bak'\'' -o -iname '\''*~'\'' \) -exec rm {} \;'; echo "deleted"; else echo "cancel"; fi; \
	   unset _INPT; \
	 fi
	@if [ -e /srv/user/share/conf/. ]; then \
	   echo "target:"; \
	   find /srv/user/share/conf/ \( -iname '*.bak' -o -iname '*~' \) -print; \
	   read -r -p "Are you sure ? [Y or else] " _INPT; \
	   if [ "$${_INPT}" =  "Y" ]; then sudo bash -c 'find /srv/user/share/conf/ \( -iname '\''*.bak'\'' -o -iname '\''*~'\'' \) -exec rm {} \;'; echo "deleted"; else echo "cancel"; fi; \
	   unset _INPT; \
	 fi
	@echo "complete: $@"

# --- mk_conf_edit.sh ---------------------------------------------------------
TGET=./mk_conf_edit.sh
SRCS=./skel_mk_conf_edit.sh
OBJS= \
	./skel_mk_conf_edit.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# --- mk_custom_iso.sh ---------------------------------------------------------
TGET=./mk_custom_iso.sh
SRCS=./skel_mk_custom_iso.sh
OBJS= \
	./skel_mk_custom_iso.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# --- mk_custom_live.sh -------------------------------------------------------
TGET=./mk_custom_live.sh
SRCS=./skel_mk_custom_live.sh
OBJS= \
	./skel_mk_custom_live.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# --- mk_downloader.sh --------------------------------------------------------
TGET=./mk_downloader.sh
SRCS=./skel_mk_downloader.sh
OBJS= \
	./skel_mk_downloader.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# --- mk_ipxe_menu.sh --------------------------------------------------------
TGET=./mk_ipxe_menu.sh
SRCS=./skel_mk_ipxe_menu.sh
OBJS= \
	../custom_cmd/fnComm_system_common.sh \
	./fnComm_global_common.sh \
	./fnComm_global_variables.sh \
	../_common_bash/fnColorcode.sh \
	../_common_bash/fnTrim.sh \
	../_common_bash/fnDirname.sh \
	../_common_bash/fnBasename.sh \
	../_common_bash/fnFilename.sh \
	../_common_bash/fnMsgout.sh \
	../_common_bash/fnString.sh \
	../_common_bash/fnStrmsg.sh \
	../_common_bash/fnGetWebinfo.sh \
	../_common_bash/fnGetFileinfo.sh \
	../custom_cmd/fnComm_dbgout.sh \
	../custom_cmd/fnComm_dbgparameters.sh \
	../custom_cmd/fnComm_dbgparameters_all.sh \
	../custom_cmd/fnComm_find_command.sh \
	../custom_cmd/fnComm_download.sh \
	../custom_cmd/fnComm_rsync.sh \
	../custom_cmd/fnComm_trap.sh \
	../custom_cmd/fnComm_list_conf_Get.sh \
	../custom_cmd/fnComm_list_mdia_Get.sh \
	../custom_cmd/fnComm_list_mdia_Put.sh \
	./fnMake_ipxe_autoexec.sh \
	./fnMake_ipxe_menu.sh \
	./fnMake_ipxe_booting.sh \
	./fnMake_ipxe_live.sh \
	./fnMake_ipxe_custom_live.sh \
	./fnMake_ipxe_debian.sh \
	./fnMake_ipxe_ubuntu.sh \
	./fnMake_ipxe_fedora.sh \
	./fnMake_ipxe_centos.sh \
	./fnMake_ipxe_almalinux.sh \
	./fnMake_ipxe_rockylinux.sh \
	./fnMake_ipxe_miraclelinux.sh \
	./fnMake_ipxe_opensuse.sh \
	./fnMake_ipxe_windows.sh \
	./fnMake_ipxe.sh \
	./fnMake_init_mk_ipxe_menu.sh \
	./fnMake_help_mk_ipxe_menu.sh \
	./fnMake_main_mk_ipxe_menu.sh \
	./skel_mk_ipxe_menu.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@shellcheck -o all $@
	@sudo chmod +x $@
	@echo "complete: $@"

# --- eof ---------------------------------------------------------------------
