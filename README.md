Hyper-V Host Build
=====
Completely unattended build of Microsoft Hyper-V hosts when cloned from sysprep'ed "Gold" image.

### Inputs:
1. A Windows 2012 R0 or Windows 2012 R2 base install to act as your "Gold" image
2. Properly completed nic-config.csv - If using Cisco UCS, MAC addresses are simple enough to export once service profiles have been created

### Build Activities Achieved:
1.  Reset all NICs to DHCP
2.  Create NIC teams
3.  Put IP config(s) on NIC Teams
4.  Rename host if required
5.  Set correct regional settings for current user
6.  Set correct regional settings for welcome screen
7.  Set correct regional settings for new user accounts
8.  Set correct time zone
9.  Install Windows Hyper-V feature - http://technet.microsoft.com/en-us/library/hh825322.aspx
10. Install Windows Hyper-V tools features
11. Enable Hyper-V Powershell Cmdlets
12. Install Windows MPIO feature - http://technet.microsoft.com/en-us/library/ee619752(v=ws.10).aspx
13. Disable Trim/Umap - http://technet.microsoft.com/en-us/library/ff383236(v=ws.10).aspx
14. Disable ODX - http://technet.microsoft.com/en-us/library/jj200627.aspx
15. Set up for Second Run and Reboot
16. Create and Configure Hyper-V Switches
17. Set VM migration network **NOTE**: 2012R2 disallows this without an AD 
18. Disable "Use any network for VM migration"
19. Set maximum VM + storage migrations to 4
20. Enable VM migration **NOTE**: 2012R2 disallows this without an AD 
21. Instruct MPIO to claim all multipaths to storage
22. Rename Administrator and Guest accounts - if still default
23. Re-add logon legal caption and notice
24. Remove C:\Windows\Panther folder & files left after sysprep
25. Remove C:\Scripts folder
26. Final Reboot

### Usage:
1.  Prepare base 2012 Rx image (patch, install drivers, etc, etc)
2. Copy nic-config.csv, PostSysprep1.bat, PostSysprep2.bat, R0Autounattend.xml, R2Autounattend.xml (whichever is appropriate to your O/S), SetupHost.ps1 and zzz-Run-Sysprep.bat to C:\Scripts folder 
3. Update nic-config.csv with config info pertaining to target Hyper-V servers
4. Run zzz-Run-Sysprep.bat from and administrative command prompt to execute sysprep and shutdown the gold image
5. Clone gold image to target systems using your preferred method (SAN LUN clone / drive snapshot / ghost / whatever) 
6. Start target servers
7. Grab a coffee, your Hyper-V servers will build themselves !

### Attribution:
Parts "Leveraged" from 
http://blogs.technet.com/b/heyscriptingguy/archive/2012/11/21/use-powershell-to-configure-the-nic-on-windows-server-2012.aspx
