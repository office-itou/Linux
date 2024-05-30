# **WinPE**  
  
## Tree diagram
  
```bash:
%USERPROFILE%\Documents
|   Make_WinPE.cmd ------------ WinPE creation batch file
|   WinPEx64.iso -------------- WinPE ISO file (64bit)
\---winpe
    +---drivers
    |   +---pvscsi ------------ VMware SCSI driver
    |   |   \---Win10
    |   \---vmxnet3 ----------- VMware network driver
    |       \---Win10
    +---scripts --------------- WinPE command prompt script
    |       shutdown.cmd ------ Shutdown/Reboot script
    |       startnet.cmd ------ The first script after startup
    +---update ---------------- Windows Update file
    \---x64 ------------------- Work directory (Created by CopyPE)
        +---fwfiles
        +---media
        \---mount
```
  
