    @Echo Off
Rem SetLocal
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassTPMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassCPUCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassRAMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassStorageCheck    /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
    Wpeinit
    Set ShareName=\\sv-server\lhome\master\share\imgs\windows-11
    Echo Enter the name of the Windows shared folder where you extracted the installation media.
    Echo %ShareName%
    Set /P ShareName=
    Net Use %ShareName%
    Set SetupExe=%ShareName%\setup.exe
    Set AutoInst=%SystemDrive%\Windows\System32\unattend.xml
    If Exist %SetupExe% (
        If Exist %AutoInst% (
            Echo Run %SetupExe% with %AutoInst%
            %SetupExe% /Unattend:%AutoInst%
        ) Else (
            Echo Run %SetupExe%
            %SetupExe%
        )
    ) Else (
        Echo Missing %SetupExe%
    )
Rem EndLocal
    Pause.
