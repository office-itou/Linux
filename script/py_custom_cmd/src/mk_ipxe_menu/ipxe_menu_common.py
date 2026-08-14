script=r"""# --- system control ----------------------------------------------------------
:shell
echo "Booting iPXE shell ..."
shell
goto menu

:shutdown
echo "System shutting down ..."
poweroff
exit

:restart
echo "System rebooting ..."
reboot
exit

:return
echo "Return ..."
chain ${ipxebase}/menu/menu.ipxe
goto menu

:exit
exit

:error
prompt Press any key to continue
exit

# --- eof ---------------------------------------------------------------------"""
