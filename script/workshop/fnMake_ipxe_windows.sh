# shellcheck disable=SC2148

function fnMk_ipxe_windows() {
	declare -r    __FUNC_NAME="${FUNCNAME[0]}"
	_DBGS_FAIL+=("${__FUNC_NAME:-}")
	fnMsgout "${_PROG_NAME:-}" "start" "[${__FUNC_NAME}]"

	declare -r    __TGET_PATH="${1:?}"	# taget file
	declare       __DIST=""				# distribution

	__DIST="${__TGET_PATH##*/}"
	__DIST="${__DIST%.*}"
	readonly __DIST

	# --- create --------------------------------------------------------------
	mkdir -p "${__TGET_PATH%/*}"
	cat <<- _EOT_ | sed -e '/^ [^ ]\+/ s/^ *//g' -e 's/^ \+$//g' > "${__TGET_PATH:?}" || true
		#!ipxe

		# --- Menu block --------------------------------------------------------------
		# 
		#set edition server
		:menu
		menu Select the OS type you want to boot
		$(printf "%-47s %s" "item --gap --"                                 "[ Return menu ]")
		$(printf "%-47s %s" "item -- return"                                "- Return")
		$(printf "%-47s %s" "#item --gap --"                                "[ Edition ]")
		$(printf "%-47s %s" "#item -- server"                               "- Server")
		$(printf "%-47s %s" "#item -- desktop"                              "- Desktop")
		$(printf "%-47s %s" "#item --gap --"                                "[ Development ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ Current (supported) ]")
		$(printf "%-47s %s" "item -- windows-10"                            "- Windows 10")
		$(printf "%-47s %s" "item -- windows-11"                            "- Windows 11")
		$(printf "%-47s %s" "#item --gap --"                                "[ Extended LTS support ]")
		$(printf "%-47s %s" "#item --gap --"                                "[ End of life (unsupported) ]")
		$(printf "%-47s %s" "item --gap --"                                 "[ System tools ]")
		$(printf "%-47s %s" "item -- memtest86plus"                         "- Memtest86+ 8.10")
		$(printf "%-47s %s" "item -- winpe-x64"                             "- WinPE x64")
		$(printf "%-47s %s" "item -- ati2020x86"                            "- Acronis True Image 2020x86")
		$(printf "%-47s %s" "item -- ati2020x64"                            "- Acronis True Image 2020x64")
		$(printf "%-47s %s" "item -- aomei-backupper"                       "- AOMEI Backupper Standard")
		choose --default \${selected} selected || goto menu
		iseq \${selected} return  && goto return  ||
		#iseq \${selected} server  && goto edition ||
		#iseq \${selected} desktop && goto edition ||
		isset \${selected} && goto \${selected} ||
		goto menu

		#:edition
		#iseq \${selected} server  && set edition server ||
		#iseq \${selected} desktop && set edition desktop ||
		#goto menu

		:windows-10
		echo Loading Windows 10 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/windows-10
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w10.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:windows-11
		echo Loading Windows 11 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/windows-11
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd -n install.cmd \${cfgaddr}/inst_w11.cmd  install.cmd  || goto error
		initrd \${cfgaddr}/unattend.xml                 unattend.xml || goto error
		initrd \${cfgaddr}/shutdown.cmd                 shutdown.cmd || goto error
		initrd \${cfgaddr}/winpeshl.ini                 winpeshl.ini || goto error
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:memtest86plus
		echo Loading Memtest86+ 8.10 ...
		set knladdr \${srvrhttp}/imgs/memtest86plus
		iseq \${platform} efi && set knlfile \${knladdr}/EFI/BOOT/memtest || set knlfile \${knladdr}/boot/memtest
		echo Loading boot files ...
		kernel \${knlfile} || goto error
		boot || goto error
		exit

		:winpe-x64
		echo Loading WinPE x64 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/winpe-x64
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:ati2020x86
		echo Loading Acronis True Image 2020x86 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/ati2020x86
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:ati2020x64
		echo Loading Acronis True Image 2020x64 ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/ati2020x64
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/Boot/BCD                     BCD          || goto error
		initrd \${knladdr}/Boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:aomei-backupper
		echo Loading AOMEI Backupper Standard ...
		set ipxaddr \${srvrhttp}/tftp/ipxe
		set knladdr \${srvrhttp}/imgs/aomei-backupper
		set cfgaddr \${srvrhttp}/conf/windows
		echo Loading boot files ...
		kernel \${ipxaddr}/wimboot
		initrd \${knladdr}/bootmgr                      bootmgr      || goto error
		initrd \${knladdr}/boot/bcd                     BCD          || goto error
		initrd \${knladdr}/boot/boot.sdi                boot.sdi     || goto error
		initrd \${knladdr}/sources/boot.wim             boot.wim     || goto error
		boot || goto error
		exit

		:return
		echo "Return ..."
		chain \${ipxebase}/menu/menu.ipxe
		goto menu

		:exit
		exit

		:error
		prompt Press any key to continue
		exit
_EOT_
	if [[ ! -s "${__TGET_PATH:?}" ]]; then
		fnMsgout "${_PROG_NAME:-}" "failed" "[${__FUNC_NAME}]: ${__TGET_PATH:?}"
		exit 1
	fi
#	unset __TGET_PATH

	# --- complete ------------------------------------------------------------
	fnMsgout "${_PROG_NAME:-}" "complete" "[${__FUNC_NAME}]"
	unset '_DBGS_FAIL[${#_DBGS_FAIL[@]}-1]'
	_DBGS_FAIL=("${_DBGS_FAIL[@]}")
	fnDbgparameters
#	unset __FUNC_NAME
}
