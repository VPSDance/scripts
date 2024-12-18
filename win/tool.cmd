@ECHO OFF
:: https://sh.vps.dance/tool.cmd
:: References: nat.ee, https://t.me/nat_ee

:: utf-8
chcp 65001>nul

>nul 2>&1 "%SYSTEMROOT%\system32\caCLS.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
GOTO UACPrompt
) ELSE ( GOTO gotAdmin )
:UACPrompt
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
ECHO UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
title tool.cmd
mode con: cols=50 lines=16
color 17
SET "wall=HKLM\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules"
SET "rdp=HKLM\SYSTEM\ControlSet001\Control\Terminal Server"
:Menu
CLS
ECHO.
ECHO 1. Change the RDP(Remote Desktop) Port
ECHO.
ECHO 2. Change Password of Administrator
ECHO.
ECHO 3. Reboot
ECHO.
ECHO 4. Show file extensions and hidden files
ECHO.
choice /C:1234 /N /M "Type the number [1,2,3,4]": 
if errorlevel 4 GOTO:ShowHidden
if errorlevel 3 GOTO:Restart
if errorlevel 2 GOTO:Password
if errorlevel 1 GOTO:RemotePort
:ShowHidden
CLS
ECHO Show file extensions and hidden files
:: Show hidden files
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSuperHidden /t REG_DWORD /d 1 /f
:: Show file extensions
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f
taskkill /f /im explorer.exe >nul
start explorer >nul
TIMEOUT 3 >NUL
GOTO:Menu
:RemotePort
SET Port=3389
CLS
ECHO Change the RDP Port (default: 3389)
ECHO.
ECHO Press Enter to continue
ECHO.
SET /P "Port=Port range(1-65535):"
ECHO;%Port%|find " "&&goto:RemotePort
ECHO;%Port%|findstr "^0.*"&&goto:RemotePort
IF "%Port%" == "q" (GOTO:Menu)
IF "%Port%" == "0" (GOTO:RemotePort)
IF "%Port%" == "" (SET Port=3389)
IF %Port% LEQ 65535 (
Reg add "%rdp%\Wds\rdpwd\Tds\tcp" /v "PortNumber" /t REG_DWORD /d "%Port%" /f  > nul
Reg add "%rdp%\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d "%Port%" /f  > NUL
Reg add "%wall%" /v "{338933891-3389-3389-3389-338933893389}" /t REG_SZ /d "v2.29|Action=Allow|Active=TRUE|Dir=In|Protocol=6|LPort=%Port%|Name=Remote Desktop(TCP-In)|" /f
Reg add "%wall%" /v "{338933892-3389-3389-3389-338933893389}" /t REG_SZ /d "v2.29|Action=Allow|Active=TRUE|Dir=In|Protocol=17|LPort=%Port%|Name=Remote Desktop(UDP-In)|" /f
CLS
ECHO.
ECHO Success, RDP Port: %Port% 
ECHO.
ECHO Please reboot to take effect
TIMEOUT 5 >NUL
GOTO:Menu
) ELSE (
CLS
ECHO.
ECHO Port: %Port% is invalid.
ECHO Port is out of range (1-65535)
TIMEOUT 3 >NUL
GOTO:RemotePort
)
:Password
SET pwd1=
SET pwd2=
CLS
ECHO Change %username%'s password
ECHO.
ECHO Press Enter to continue
ECHO.
SET /p pwd1=New Password: 
CLS
ECHO.
ECHO Press Enter to continue
ECHO.
SET /p pwd2=Confirm password: 
IF "%pwd1%" == "%pwd2%" (
CLS
net user "%username%" "%pwd2%"||PAUSE&&GOTO:Password
ECHO.
TIMEOUT 3 >NUL
GOTO:Menu
) ELSE (
CLS
ECHO.
ECHO Passwords do not match.
TIMEOUT 3 >NUL
GOTO:Password
)
:Restart
CLS
ECHO The server will restart in 5 seconds
TIMEOUT /t 5
shutdown.exe /r /f /t 0
EXIT
