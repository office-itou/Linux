    @Echo Off
Rem SetLocal
    Set WindowsVer=10
    Set ShareName=\\sv-server\pxe-share
    Set SetupExe=%ShareName%\windows-%WindowsVer%\setup.exe
    Set AutoInst=%SystemDrive%\Windows\System32\unattend.xml
    Echo Start the automatic installation of Windows %WindowsVer%
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
