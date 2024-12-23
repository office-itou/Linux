    @Echo Off
Rem SetLocal
    Set WindowsVer=10
    Set ShareName=\\sv-server\pxe-share
    Set ShareDrv=Z:
    Set SetupExe=%ShareDrv%\windows-%WindowsVer%\setup.exe
    Set AutoInst=%SystemDrive%\Windows\System32\unattend.xml
    Echo Start the automatic installation of Windows %WindowsVer%
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassTPMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassCPUCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassRAMCheck        /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\Setup\LabConfig /v BypassStorageCheck    /t REG_DWORD /d 1 /f
    REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\BitLocker /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
    Wpeinit
    Set StartTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    Set EndTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
:Loop
    Net Use %ShareDrv% %ShareName% > Nul 2>&1
    If %ErrorLevel% EQU 0 GoTo Next
    If %EndTime% LSS %StartTime% Then Set /A EndTime=%EndTime%+86400
    Set /A ElapsedTime=%EndTime%-%StartTime%
    If %ElapsedTime% GEQ 10 GoTo Exit
    Set EndTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    GoTo Loop
:Exit
    Net Use %ShareDrv% %ShareName% > Nul 2>&1
:Next
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
