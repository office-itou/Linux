    @Echo Off
Rem SetLocal
    Wpeinit
    Set ShareName=\\sv-server\pxe-share\windows-10
Rem Echo Enter the name of the Windows shared folder where you extracted the installation media.
Rem Echo %ShareName%
Rem Set /P ShareName=
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
        cmd.exe
    )
Rem EndLocal
    Pause.
