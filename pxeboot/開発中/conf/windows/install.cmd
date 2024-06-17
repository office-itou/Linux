@Echo Off
SetLocal
Echo Enter the name of the Windows shared folder where you extracted the installation media.
Set /P SHARENAME=
wpeinit
net use %SHARENAME%
%SHARENAME%\setup.exe /Unattend:%SHARENAME%\unattend.xml
EndLocal
