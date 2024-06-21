@Echo Off
SetLocal
Set SHARENAME=\\sv-server\lhome\master\share\imgs\windows-11
Echo Enter the name of the Windows shared folder where you extracted the installation media.
Echo %SHARENAME%
Set /P SHARENAME=
wpeinit
net use %SHARENAME%
%SHARENAME%\setup.exe /Unattend:%SHARENAME%\unattend.xml
EndLocal
