@echo off
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system /v legalnoticecaption /f
reg delete HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\policies\system /v legalnoticetext /f
cd C:\Windows\System32\Sysprep\
rmdir c:\Windows\Panther /s /q
mkdir c:\Windows\Panther
ver | findstr /i "6.3" > nul
if %errorlevel% equ 0 goto 2012R2
ver | findstr /i "6.2" > nul
if %errorlevel% equ 0 goto 2012R0
exit

:2012R2
echo 2012R2 detected
copy C:\Scripts\R2Autounattend.xml C:\Windows\System32\Sysprep\Autounattend.xml /Y
goto END

:2012R0
echo 2012R0 detected
copy C:\Scripts\R0Autounattend.xml C:\Windows\System32\Sysprep\Autounattend.xml /Y
goto END:

:END
pause
sysprep /generalize /oobe /shutdown /unattend:Autounattend.xml