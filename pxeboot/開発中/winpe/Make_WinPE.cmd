@Echo Off

Rem ###########################################################################
Rem # x64                                                                     #
Rem ###########################################################################

    Cls

Rem === Create a working directory ============================================

    Echo === Create a working directory ================================================
    If Exist "%USERPROFILE%\Documents\winpe\x64" (RmDir /S /Q "%USERPROFILE%\Documents\winpe\x64" || GoTo Fail)

    Call CopyPE amd64 "%USERPROFILE%\Documents\winpe\x64" > Nul || GoTo Fail

Rem === Mount WinPE image =====================================================

    Echo === Mount WinPE image =========================================================
    Dism /Quiet /Mount-Image /ImageFile:"%USERPROFILE%\Documents\winpe\x64\media\sources\boot.wim" /Index:1 /MountDir:"%USERPROFILE%\Documents\winpe\x64\mount" || GoTo Fail

Rem === WinPE Optional Components =============================================

    Echo === WinPE Optional Components =================================================

Rem --- WinPE-Font Support-JA-JP: Fonts/WinPE-Font Support-JA-JP --------------
Rem     WinPE-Font Support-JA-JP contains two Japanese font families that are packaged as TrueType Collection (TTC) files.
    Echo --- Fonts/WinPE-Font Support-JA-JP --------------------------------------------
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-FontSupport-JA-JP.cab" || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\lp.cab" || GoTo Fail

Rem --- WinPE-WMI               : Scripting/WinPE-WMI -------------------------
Rem     WinPE-WMI contains a subset of the Windows Management Instrumentation (WMI) providers that enable minimal system diagnostics.
    Echo --- Scripting/WinPE-WMI -------------------------------------------------------
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-WMI.cab" || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-WMI_ja-jp.cab" || GoTo Fail

Rem --- WinPE-NetFx             : Microsoft .NET/WinPE-NetFx ------------------
Rem     WinPE-NetFx contains a subset of the .NET Framework 4.5 that is designed for client applications.
Rem     Dependencies: Install WinPE-WMI before you install WinPE-NetFX.
Rem Echo --- Microsoft .NET/WinPE-NetFx ------------------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-NetFx.cab" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-NetFx_ja-jp.cab" || GoTo Fail

Rem --- WinPE-Scripting         : Scripting/WinPE-Scripting -------------------
Rem     WinPE-Scripting contains a multiple-language scripting environment that is ideal for automating system administration tasks, such as batch file processing.
Rem     Dependencies: Install WinPE-Scripting to make sure that full scripting functionality is available when you are using WinPE-NetFX and WinPE-HTA. The installation order is irrelevant.
    Echo --- Scripting/WinPE-Scripting -------------------------------------------------
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-Scripting.cab" || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-Scripting_ja-jp.cab" || GoTo Fail

Rem --- WinPE-PowerShell        : Windows PowerShell/WinPE-PowerShell ---------
Rem     WinPE-PowerShell contains Windows PowerShell-based diagnostics that simplify using Windows Management Instrumentation (WMI) to query the hardware during manufacturing. 
Rem     Dependencies: Install WinPE-WMI > WinPE-NetFX > WinPE-Scripting before you install WinPE-PowerShell.
Rem Echo --- Windows PowerShell/WinPE-PowerShell ---------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-PowerShell.cab" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-PowerShell_ja-jp.cab" || GoTo Fail

Rem --- WinPE-SecureStartup     : Startup/WinPE-SecureStartup -----------------
Rem     WinPE-SecureStartup enables provisioning and management of BitLocker and the Trusted Platform Module (TPM).
Rem     Dependencies: Install WinPE-WMI before you install WinPE-SecureStartup.
Rem Echo --- Startup/WinPE-SecureStartup -----------------------------------------------
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-SecureStartup.cab" || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-SecureStartup_ja-jp.cab" || GoTo Fail

Rem --- WinPE-PlatformID        : Windows PowerShell/WinPE-PlatformID ---------
Rem     WinPE-PlatformID contains the Windows PowerShell cmdlets to retrieve the Platform Identifier of the physical machine.
Rem     Dependencies: Install WinPE-WMI and WinPE-SecureStartup before you install WinPE-PlatformID.
Rem Echo --- Windows PowerShell/WinPE-PlatformID ---------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-PlatformId.cab" || GoTo Fail

Rem --- WinPE-DismCmdlets       : Windows PowerShell/WinPE-DismCmdlets --------
Rem     WinPE-DismCmdlets contains the DISM PowerShell module, which includes cmdlets used for managing and servicing Windows images.
Rem     Dependencies: Install WinPE-WMI > WinPE-NetFX > WinPE-Scripting > WinPE-PowerShell before you install WinPE-DismCmdlets.
Rem Echo --- Windows PowerShell/WinPE-DismCmdlets --------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-DismCmdlets.cab" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-DismCmdlets_ja-jp.cab" || GoTo Fail

Rem --- WinPE-SecureBootCmdlets : Windows PowerShell/WinPE-SecureBootCmdlets --
Rem     WinPE-SecureBootCmdlets contains the PowerShell cmdlets for managing the UEFI (Unified Extensible Firmware Interface) environment variables for Secure Boot.
Rem     Dependencies: Install WinPE-WMI > WinPE-NetFX > WinPE-Scripting > WinPE-PowerShell before you install WinPE-SecureBootCmdlets.
Rem Echo --- Windows PowerShell/WinPE-SecureBootCmdlets --------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-SecureBootCmdlets.cab" || GoTo Fail

Rem --- WinPE-StorageWMI        : Windows PowerShell/WinPE-StorageWMI ---------
Rem     WinPE-StorageWMI contains PowerShell cmdlets for storage management.
Rem     Dependencies: Install WinPE-WMI > WinPE-NetFX > WinPE-Scripting > WinPE-PowerShell before you install WinPE-StorageWMI.
Rem Echo --- Windows PowerShell/WinPE-StorageWMI ---------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-StorageWMI.cab" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-StorageWMI_ja-jp.cab" || GoTo Fail

Rem --- WinPE-WDS-Tools         : Network/WinPE-WDS-Tools ---------------------
Rem     WinPE-WDS-Tools includes APIs to enable the Image Capture tool and a multicast scenario that involves a custom Windows Deployment Services client.
Rem Echo --- Network/WinPE-WDS-Tools ---------------------------------------------------
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\WinPE-WDS-Tools.cab" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%WinPERoot%\amd64\WinPE_OCs\ja-jp\WinPE-WDS-Tools_ja-jp.cab" || GoTo Fail

Rem === Install drivers =======================================================

Rem Echo === Install drivers ===========================================================
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-Driver /Driver:"%USERPROFILE%\Documents\winpe\drivers\vmxnet3\Win10" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-Driver /Driver:"%USERPROFILE%\Documents\winpe\drivers\pvscsi\Win10" || GoTo Fail

Rem === Install Windows Update ================================================

Rem Echo === Install Windows Update ====================================================
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%USERPROFILE%\Documents\winpe\update\windows11.0-kb5037771-x64_19a3f100fb8437d059d7ee2b879fe8e48a1bae42.msu"
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Add-package /PackagePath:"%USERPROFILE%\Documents\winpe\update\windows11.0-kb5037591-x64-ndp481_c9be84bc9c76e3869fdde0a02c610796fb3d05ce.msu"

Rem === Setup language ========================================================

    Echo === Setup language ============================================================
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Set-AllIntl:ja-jp || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Set-InputLocale:0411:00000411 || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Set-LayeredDriver:6 || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Set-TimeZone:"Tokyo Standard Time" || GoTo Fail

Rem === Setup feature =========================================================

Rem Echo === Setup feature =============================================================
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:SMB1Protocol || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:SMB1Protocol-Client || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:SMB1Protocol-Server || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-WMI || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-NetFx || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:Microsoft-Windows-NetFx-Shared-Package-WinPE || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-PowerShell || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-DismCmdlets || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-SecureBootCmdlets || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-SecureStartup || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-TPM || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-PlatformId || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-StorageWMI || GoTo Fail
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-Scripting || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Enable-Feature /FeatureName:WinPE-WDS-Tools || GoTo Fail

Rem === Setup registry ========================================================

Rem Echo === Setup registry ============================================================
Rem REG LOAD HKEY_LOCAL_MACHINE\MNT_SYSTEM "%USERPROFILE%\Documents\winpe\x64\mount\Windows\System32\config\SYSTEM" || GoTo Fail
Rem REG ADD HKEY_LOCAL_MACHINE\MNT_SYSTEM\SYSTEM\Setup\LabConfig /v BypassTPMCheck /t REG_DWORD /d 1 /f || GoTo Fail
Rem REG ADD HKEY_LOCAL_MACHINE\MNT_SYSTEM\SYSTEM\Setup\LabConfig /v BypassSecureBootCheck /t REG_DWORD /d 1 /f || GoTo Fail
Rem REG ADD HKEY_LOCAL_MACHINE\MNT_SYSTEM\SYSTEM\Setup\LabConfig /v BypassRAMCheck /t REG_DWORD /d 1 /f || GoTo Fail
Rem REG ADD HKEY_LOCAL_MACHINE\MNT_SYSTEM\CurrentControlSet\Control\Secureboot /v AvailableUpdates /t REG_DWORD /d 0x40 /f || GoTo Fail
Rem REG QUERY HKEY_LOCAL_MACHINE\MNT_SYSTEM\SYSTEM\Setup\LabConfig || GoTo Fail
Rem REG QUERY HKEY_LOCAL_MACHINE\MNT_SYSTEM\CurrentControlSet\Control\Secureboot || GoTo Fail
Rem REG UNLOAD HKEY_LOCAL_MACHINE\MNT_SYSTEM || GoTo Fail

Rem === Copy script file ======================================================

    Echo === Copy script file ==========================================================
    Xcopy /Y "%USERPROFILE%\Documents\winpe\scripts\*.*" "%USERPROFILE%\Documents\winpe\x64\mount\Windows\System32\" || GoTo Fail

Rem === Commit and Unmount ====================================================

    Echo === Commit and Unmount ========================================================
    Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Cleanup-Image /Startcomponentcleanup /Resetbase /ScratchDir:"%TEMP%" || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Cleanup-image /StartComponentCleanup /Resetbase /Defer || GoTo Fail
Rem Dism /Quiet /Image:"%USERPROFILE%\Documents\winpe\x64\mount" /Get-Packages || GoTo Fail
    Dism /Quiet /Unmount-Image /MountDir:"%USERPROFILE%\Documents\winpe\x64\mount" /Commit || GoTo Fail

Rem === Remove [press any key message] ========================================

    Echo === Remove [press any key message] ============================================
    Del "%USERPROFILE%\Documents\winpe\x64\media\Boot\bootfix.bin" || GoTo Fail

Rem === Debug mode ============================================================

Rem Echo === Debug mode ================================================================

Rem --- To enable kernel-mode debugging ---------------------------------------
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\Boot\BCD" /Set {default} debug on || GoTo Fail

Rem --- To enable network kernel-mode debugging: uefi system ------------------
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\EFI\Microsoft\Boot\BCD" /Set {default} debug o || GoTo Failn
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\EFI\Microsoft\Boot\BCD" /Set {default} bootdebug on || GoTo Fail
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\EFI\Microsoft\Boot\BCD" /DbgSetTings NET HOSTIP:xxx.xxx.xxx.xxx PORT:50005 key:5.5.5.5 || GoTo Fail

Rem --- To enable network kernel-mode debugging: bios system ------------------
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\Boot\BCD" /Set {default} debug on || GoTo Fail
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\Boot\BCD" /Set {default} bootdebug on || GoTo Fail
Rem BcdEdit /Store "%USERPROFILE%\Documents\winpe\x64\media\Boot\BCD" /DbgSetTings NET HOSTIP:xxx.xxx.xxx.xxx PORT:50005 key:5.5.5.5 || GoTo Fail

Rem === Create iso file =======================================================

    Echo === Create iso file ===========================================================
    Call MakeWinPEMedia /ISO /F "%USERPROFILE%\Documents\winpe\x64\" "%USERPROFILE%\Documents\WinPEx64.iso" || GoTo Fail

:Success
    Echo --- Success -------------------------------------------------------------------
    GoTo End

:Fail
    Echo --- Fail ----------------------------------------------------------------------
    GoTo End

:End
    Echo === eof =======================================================================

Rem === memo ==================================================================

Rem https://learn.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive?view=windows-11#update-the-windows-pe-add-on-for-the-windows-adk
Rem https://learn.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/winpe-mount-and-customize?view=windows-11#add-updates-to-winpe-if-needed
Rem https://learn.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/winpe-debug-apps?view=windows-11
Rem https://learn.microsoft.com/ja-jp/windows-hardware/manufacture/desktop/oem-deployment-of-windows-desktop-editions?view=windows-11
Rem https://www.catalog.update.microsoft.com/Search.aspx?q=cumulative%20update%20for%20Windows%2010

Rem === eof ===================================================================
