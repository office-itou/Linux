    @Echo Off
Rem SetLocal
    Set WindowsVer=11
    Set ShareName=\\sv-server\pxe-share
    Set SetupExe=%ShareName%\windows-%WindowsVer%\setup.exe
    Set AutoInst=%SystemDrive%\Windows\System32\unattend.xml
    Echo Start the automatic installation of Windows %WindowsVer%
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassTPMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassCPUCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassRAMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassStorageCheck    /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
    Wpeinit
Rem Net Use %ShareName%
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
        cmd.exe
    )
    Echo Ending the automatic installation of Windows %WindowsVer%
Rem EndLocal
    Pause.
