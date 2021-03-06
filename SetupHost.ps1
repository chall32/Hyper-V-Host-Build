<# SetupHost.ps1 - Setup Hyper-V Hosts After Sysprep
#-------------------------------------------------------------------------------------------------------------------------------- 
# Chris Hall
#
# v0.WIP  - 16 Apr 2014 - Chris Hall - Initial Release
#>
#
# ---- RUNNUMBER HANDLING - WHICH BOOT ARE WE? ---------------------------------------------------------------------------------- 
#
 param (
    [validateset("1","2")][int]$RunNumber = $(Read-Host "-RunNumber is required. Enter it now")
 )
#
# ---- WHAT TO DO ON ERROR AND START LOGGING ------------------------------------------------------------------------------------ 
#
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\SetupHostLog.txt -append
Write-Output "BEGIN BUILD PHASE $RunNumber - $(Get-Date -Format u)"
#
# ---- CLEAR DOWN AND WAIT FOR COMMAND COMPLETION ------------------------------------------------------------------------------- 
#
function ClearDown {
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
}
ClearDown
#
# ---- NETWORKING + HOSTNAME ---------------------------------------------------------------------------------------------------- 
# Last team created should always be MGMT-TEAM as this will then appear 1st in final NIC binding order
#
If ($RunNumber -eq 1) {
    # First Pass of CSV to Set NIC Names, Set NICs to DHCP & Set Computer Name
    #
    Write-Output "START NIC Config ...."
    $NICs = Import-Csv "c:\scripts\nic-config.csv" #| Where-Object {$_.computername -eq $env:COMPUTERNAME}
    foreach ($NIC in $NICs) {
        $NetAdapter = Get-NetAdapter | Where-Object {$_.MacAddress -eq $NIC.MAC}
        if ($NetAdapter) {
            $NetAdapter = $NetAdapter | Rename-NetAdapter -NewName $NIC.NIC -PassThru
            # Set NIC to DHCP if TRUE in the CSV-file
            if ($NIC.DHCP -eq 'TRUE') {
                $NetAdapter = $NetAdapter | Set-NetIPInterface -DHCP Disabled -PassThru
            }
            #Change Computername if it is not correct
            if ($env:COMPUTERNAME -ne $NIC.ComputerName) {
                Rename-Computer -NewName $NIC.ComputerName
            }
        }
    }
    Write-Output "..... NIC Config DONE"
    ClearDown
    Write-Output "START NIC Teaming ...."
    #Second Pass of CSV to set Teams
    #
    $PendCompName = (Get-ItemProperty hklm:\SYSTEM\ControlSet001\Control\ComputerName\ComputerName  -name “ComputerName”).ComputerName
    $Teams = Import-Csv "c:\scripts\nic-config.csv" | Where-Object {$_.computername -eq $PendCompName}
    foreach ($Team in $Teams) {
        if ($Team.NIC -eq "VM-PROD-TEAM") {
            New-NetLbfoTeam -Name $Team.NIC -TeamMembers "VM-PROD-A","VM-PROD-B" -TeamingMode $Team.TeamingMode -LoadBalancingAlgorithm $Team.LoadBalancingAlgorithm -Confirm:$false
        }
        if ($Team.NIC -eq "HOST-MGMT-TEAM") {
            New-NetLbfoTeam -Name $Team.NIC -TeamMembers "HOST-MGMT-A","HOST-MGMT-B" -TeamingMode $Team.TeamingMode -LoadBalancingAlgorithm $Team.LoadBalancingAlgorithm -Confirm:$false
            $TeamAttributes = @{}
            if ($Team.AddressFamily) {
                $TeamAttributes.Add('AddressFamily',$Team.AddressFamily)
            }
            if ($Team.IPAddress) {
                $TeamAttributes.Add('IPAddress',$Team.IPAddress)
            }
            if ($Team.PrefixLength) {
                $TeamAttributes.Add('PrefixLength',$Team.PrefixLength)
            }
            if ($Team.Type) {
                $TeamAttributes.Add('Type',$Team.Type)
            }
            if ($Team.DefaultGateway) {
                $TeamAttributes.Add('DefaultGateway',$Team.DefaultGateway)
            }
            if ($Team.PolicyStore) {
                $TeamAttributes.Add('PolicyStore',$Team.PolicyStore)
            }
            # Configuring IP address settings by using splatting.
            $NetAdapter = Get-NetAdapter | Where-Object {$_.Name -eq $Team.NIC}
            $NetAdapter | New-NetIPAddress @TeamAttributes
            if ($Team.DnsServerAddresses) {
                Set-DnsClientServerAddress -InterfaceAlias $($Team.NIC) -ServerAddresses $Team.DnsServerAddresses
            }
            # Configuring DNS suffix, if defined in the CSV-file.
            if ($Team.DnsSuffix) {
                Set-DnsClient -InterfaceAlias $($Team.NIC) -ConnectionSpecificSuffix $Team.DnsSuffix
            }
        }
    }
    Write-Output "..... NIC Teaming DONE"
    ClearDown
    }
#
# ---- REGION + TIMEZONE -------------------------------------------------------------------------------------------------------- 
# Some of this is set by sysprep, however doing this here allows for 
# greater flexability. EG Running this script without sysprep first
#
If ($RunNumber -eq 1) {
    # Current User
    Write-Output "START Current User Reginal Settings ...."
    set-culture "en-GB" # Twice for good measure
    set-winhomelocation 242
    set-winsystemlocale "en-GB"
    set-winuserlanguagelist "en-GB" -force -confirm:$false
    Set-WinDefaultInputMethodOverride "0809:00000809"
    Set-WinCultureFromLanguageListOptOut 1

    Set-WinDefaultInputMethodOverride "0809:00000809"
    Set-WinUILanguageOverride en-GB
    
    Write-Output "..... Current User Reginal Settings DONE"
    ClearDown
    # Welcome Screen
    Write-Output "START Welcome Screen Reginal Settings ...."
    Remove-Item "Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-18\Control Panel\International" -Recurse -Force
    Copy-Item "HKCU:\Control Panel\International" -Destination "Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-18\Control Panel\International" -Recurse -Force
    Remove-Item "Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-18\Control Panel\International\User Profile System Backup" -Recurse -Force
    Set-ItemProperty "Microsoft.PowerShell.Core\Registry::HKEY_USERS\S-1-5-18\Keyboard Layout\Preload" -Name "1" -Value "00000809" -Type String
    Write-Output "..... Welcome Screen Reginal Settings DONE"
    ClearDown
    # New User Accounts
    Write-Output "START New User Account Reginal Settings ...."
    Invoke-Command {reg.exe load "HKLM\DEFAULT_NTUSER" "C:\Users\Default\NTUSER.DAT"}
    Remove-Item "Microsoft.PowerShell.Core\Registry::HKLM\DEFAULT_NTUSER\Control Panel\International" -Recurse -Force
    Copy-Item "HKCU:\Control Panel\International" -Destination "Microsoft.PowerShell.Core\Registry::HKLM\DEFAULT_NTUSER\Control Panel\International" -Recurse -Force
    Set-ItemProperty "Microsoft.PowerShell.Core\Registry::HKLM\DEFAULT_NTUSER\Keyboard Layout\Preload" -Name "1" -Value "00000809" -Type String 
    ClearDown
    Invoke-Command {reg.exe unload "HKLM\DEFAULT_NTUSER"}
    Write-Output "..... New User Account Reginal Settings DONE"
    # Set time zone
    Write-Output "START Time Zone Config ...."
    Invoke-Command {tzutil /s "GMT Standard Time"}
    Write-Output "..... Time Zone Config DONE"
    }
#
# ---- INSTALL HYPER-V + ENABLE HYPER-V POWERSHELL ------------------------------------------------------------------------------ 
#
If ($RunNumber -eq 1) {
    Write-Output "START Install Hyper-V + Tools ...."
    Install-WindowsFeature Hyper-V
    ClearDown
    Install-WindowsFeature Hyper-V-Tools
    ClearDown
    Enable-WindowsOptionalFeature –Online -NoRestart -FeatureName Microsoft-Hyper-V-Management-PowerShell
    ClearDown
    Write-Output "..... Install Hyper-V + Tools DONE"
    }
#
# ---- INSTALL MULTIPATH I/O ---------------------------------------------------------------------------------------------------- 
#
If ($RunNumber -eq 1) {
    Write-Output "START Install MPIO ...."
    Enable-WindowsOptionalFeature -Online -NoRestart -Featurename MultiPathIO
    Write-Output "..... Install MPIO DONE"
    }
#
# ---- STORAGE WORKAROUNDS ------------------------------------------------------------------------------------------------------ 
#
If ($RunNumber -eq 1) {
    Write-Output "START Storage Workarounds ...."
    # Diasble Trim/Umap
    Set-ItemProperty hklm:\system\currentcontrolset\control\filesystem -Name “DisableDeleteNotification” -Value 1 -Type DWord 
    # Disable ODX
    Set-ItemProperty hklm:\system\currentcontrolset\control\filesystem -Name “FilterSupportedFeaturesMode” -Value 1 -Type DWord
    Write-Output "..... Storage Workarounds DONE"
    }
#
# ---- GET READY TO AUTOLOGON + CALL POSTSYSPREP2 ------------------------------------------------------------------------------- 
#
If ($RunNumber -eq 1) {
    Write-Output "START Setup for Reboot ...."
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value 1 -Type String
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoLogonCount" -Value 1 -Type DWord
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "SECURITY-Pr0blem!" -Type String
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "RIS" -Value "CMD /C C:\Scripts\PostSysprep2.bat" -Type String
    Write-Output "..... Setup for Reboot DONE"
    }
#
# ---- REBOOT 1 - ALL DONE FOR FIRST BOOT --------------------------------------------------------------------------------------- 
#
If ($RunNumber -eq 1) {
    Stop-Transcript
    ClearDown
    Restart-Computer
    }
#
# ---- HYPER-V CONFIGURATION ---------------------------------------------------------------------------------------------------- 
#
If ($RunNumber -eq 2) {
    Write-Output "START Hyper-V Config ...."
    Import-Module Hyper-V
    New-VMSwitch -Name "VM-PROD-SWITCH" -NetAdapterName "VM-PROD-TEAM" -AllowManagementOS $false -Notes "VM Production LAN, No Parent OS Access"
    # Add-VMMigrationNetwork 192.168.174.0/24  - 2012R2 disallows this without an AD
    Set-VMHost -UseAnyNetworkForMigration $false -MaximumVirtualMachineMigrations 4 -MaximumStorageMigrations 4
    # Enable-VMMigration - 2012R2 disallows this without an AD
    Write-Output "..... Hyper-V Config DONE"
    ClearDown
    }
#
# ---- MPIO CLAIM PATHS -------------------------------------------------------------------------------------------------------- 
#
If ($RunNumber -eq 2) {
    Write-Output "START MPIO Path Claiming ...."
    Invoke-Command {mpclaim.exe -n -i -d "DGC     LUNZ            "} # For EMC VNX - Specifically "DGC<5 spaces>LUNZ<12 spaces>"
    Invoke-Command {mpclaim.exe -n -i -d "DGC     VRAID           "} # For EMC VNX - Specifically "DGC<5 spaces>VRAID<11 spaces>"
    Write-Output "..... MPIO Path Claiming DONE"
    ClearDown
    }
#
# ---- RENAME ADMINISTRATOR + GUEST ACCOUNTS ------------------------------------------------------------------------------------ 
#
If ($RunNumber -eq 2) {
    Write-Output "START Account Renaming ...."
    $Admin = Get-WMIObject Win32_UserAccount -Filter "Name='Administrator'"
    if ($Admin) { $Admin.Rename("LOCAL-Load") }
    $Guest = Get-WMIObject Win32_UserAccount -Filter "Name='Guest'"
    if ($Guest) { $Guest.Rename("LOCAL-Visitor") }
    Write-Output "..... Account Renaming DONE"
    }
#
# ---- RE-ADD LOCALOGON NOTICE -------------------------------------------------------------------------------------------------- 
# These were removed prior to sysprep to allow fully unattended install on reboot after sysprep
#
If ($RunNumber -eq 2) {
    Write-Output "START Add Logon Notice ...."
    Set-ItemProperty hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system -Name "legalnoticecaption" -Value `
    "LOCAL Warning: Use of this System is Restricted to Authorized Users" -Type String
    #
    Set-ItemProperty hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system -Name "legalnoticetext" -Value `
    "This computer system is the private property of the Company and may only be used by those individuals authorized by Company management in accordance with Company electronic communication system policies. Unauthorized, illegal or improper use may result in disciplinary action and civil or criminal prosecution. Your use of this system is subject to monitoring and disclosure in accordance with Company policy and applicable law. By continuing to access this system,you agree that such access and use is subject to the foregoing." -Type String
    Write-Output "..... Add Logon Notice DONE"
    }
#
# ---- REBOOT 2 - ALL DONE + FINAL CLEAN UPS ------------------------------------------------------------------------------------ 
#
If ($RunNumber -eq 2) {
    Write-Output "START Final Clean Up ...."
    Remove-Item -Recurse -Force "C:\Windows\Panther"
    New-Item -ItemType Directory -Path "C:\Windows\Panther"
    Write-Output "..... Final Clean Up DONE - Rebooting"
    Stop-Transcript
    ClearDown
    # Restart-Computer - Passed to PostSysprep2.bat
    }