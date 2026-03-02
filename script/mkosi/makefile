# --- all ---------------------------------------------------------------------
EXES=\
	../mkosi/mkosi.finalize.sh.chroot

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
	@echo "complete: $@"

# --- mkosi.finalize.sh.chroot ------------------------------------------------
TGET=../mkosi/mkosi.finalize.sh.chroot
SRCS=../mkosi/skel_mkosi.finalize.sh.chroot.sh
OBJS=\
	../mkosi/fnMkosi_common.sh\
	../_common_bash/fnMsgout.sh\
	../_common_bash/fnString.sh\
	../custom_cmd/fnDbgout.sh\
	../custom_cmd/fnDbgparameters.sh\
	../custom_cmd/fnTrap.sh\
	../mkosi/fnMkosi_initialize.sh\
	../mkosi/fnMkosi_finalize_userenv.sh\
	../mkosi/fnMkosi_finalize_locale.sh\
	../mkosi/fnMkosi_finalize_setup.sh\
	../mkosi/fnMkosi_finalize_dracut.sh\
	../mkosi/fnMkosi_finalize_main.sh

$(TGET): $(SRCS) $(OBJS)
	@echo "start   : $@"
	@echo "create  : $@"
	@../mk_shell.sh --create $<
	@echo "check   : $@"
	@mv $@.sh $@
	@shellcheck -o all $@
	@echo "copy    : $@"
	@sudo cp --preserve=timestamps $@ /srv/user/share/conf/_mkosi/mkosi.finalize.d/
	@sudo chmod +x /srv/user/share/conf/_mkosi/mkosi.finalize.d/$(notdir $@)
	@echo "complete: $@"
