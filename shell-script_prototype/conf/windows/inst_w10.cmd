    @Echo Off
Rem SetLocal
    Set WindowsVer=10
    Set ShareName=\\sv-server\pxe-share
    Set SetupExe=%ShareName%\windows-%WindowsVer%\setup.exe
    Set AutoInst=%SystemDrive%\Windows\System32\unattend.xml
    Echo Start the automatic installation of Windows %WindowsVer%
    Wpeinit
    Set StartTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    Set EndTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
:Loop
    Net Use %ShareName% > Nul 2>&1
    If %ErrorLevel% EQU 0 GoTo Next
    If %EndTime% LSS %StartTime% Then Set /A EndTime=%EndTime%+86400
    Set /A ElapsedTime=%EndTime%-%StartTime%
    If %ElapsedTime% GEQ 10 GoTo Exit
    Set EndTime=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
    GoTo Loop
:Exit
    Net Use %ShareName% > Nul 2>&1
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
