powershell set-executionpolicy unrestricted
powershell C:\Scripts\SetupHost.ps1 -RunNumber 2
start c:\Windows\system32\shutdown.exe -c "Setup Host complete. Rebooting server." -r -t 15
rmdir c:\Scripts /s /q
