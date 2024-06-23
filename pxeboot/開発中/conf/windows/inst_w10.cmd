    @Echo Off
Rem SetLocal
    Wpeinit
    Set ShareName=\\sv-server\lhome\master\share\imgs\windows-10
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
