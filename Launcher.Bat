@echo off
setlocal EnableDelayedExpansion
title MYNA X SYSTEM - MynaTask Launcher
color 0F

:: Ensure working directory stays in script path after UAC elevation
cd /d "%~dp0"

:: ==================================================
:: PHASE 1: ADMIN PRIVILEGES & DEPENDENCIES
:: ==================================================
echo [STEP 1] Verifying Administrator privileges...

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Extract runtime dependencies to application root directory (%~dp0)
if exist "%~dp0Assets\7z\libstdc++-6.7z" (
    if exist "%~dp0Assets\7z\7z.exe" (
        echo [INFO] Unpacking runtime dependencies...
        "%~dp0Assets\7z\7z.exe" x -o"%~dp0" "%~dp0Assets\7z\libstdc++-6.7z" -aoa -y >nul 2>&1
    )
)

:: ==================================================
:: PHASE 2: COMPATIBILITY WARNING DISCLAIMER
:: ==================================================
:EnvironmentWarning
cls
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host '          ENVIRONMENT COMPATIBILITY WARNING       ' -ForegroundColor Yellow"
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
echo.
powershell -Command "Write-Host 'NOTICE: Special OS Environment Compatibility Warning' -ForegroundColor Yellow"
echo.
echo  This application relies heavily on native Windows APIs, DWM composition, 
echo  WMI system telemetry, and standard core background services.
echo.
echo  If running in WinPE, WinLite, or heavily modified OS environments:
echo   * The application may freeze, crash, or fail to render UI elements.
echo   * System metrics and process monitoring features may fail.
echo   * SYSTEM or TrustedInstaller escalation may not function properly.
echo.
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
echo Please choose how you would like to proceed:
echo.
echo  [1] I agree and understand the risks (Continue)
echo  [2] Exit launcher
echo.
set /p "warnChoice=Enter your choice (1-2): "

if "%warnChoice%"=="1" goto Main
if "%warnChoice%"=="2" exit /b
goto EnvironmentWarning

:: ==================================================
:: PHASE 3: MAIN LAUNCHER
:: ==================================================
:Main
set "appPath=%~dp0MynaTaskCore.exe"
set "NSPath=%~dp0Assets\NSudo\NSudoLG.exe"
set "psexecPath=%~dp0Assets\OldExe\Lib.exe"

if not exist "%appPath%" (
    powershell -Command "Write-Host '[ERROR] File not found: %appPath%' -ForegroundColor Red"
    pause
    exit /b
)

:Menu
cls
echo ==================================================
echo                 MYNA X SYSTEM - LAUNCHER
echo ==================================================
echo  Target: %appPath%
echo ==================================================
echo Select privileges level:
echo.
echo [1] Run as Administrator (Standard)
echo [2] Run as SYSTEM (Advanced)
echo [3] Run as TrustedInstaller (Maximum)
echo.
echo [E] Exit
echo ==================================================
set /p "choice=Enter your choice (1-3): "

if "%choice%"=="1" goto RunAdmin
if "%choice%"=="2" goto RunSystem
if "%choice%"=="3" goto RunTrustInstaller
if /i "%choice%"=="e" exit
goto Menu

:RunAdmin
cls
echo [INFO] Launching with Administrator privileges...
start "" "%appPath%"
exit /b

:RunSystem
cls
echo [INFO] Escalating to SYSTEM privileges...
if exist "%NSPath%" (
    "%NSPath%" -U:S -P:E "%appPath%"
    if !errorlevel! neq 0 goto FallbackSystem
    exit /b
)
:FallbackSystem
if exist "%psexecPath%" (
    "%psexecPath%" -i -s "%appPath%"
) else (
    echo [ERROR] Privilege escalation tools missing!
    pause
    goto RunAdmin
)
exit /b

:RunTrustInstaller
cls
echo [INFO] Escalating to TrustedInstaller privileges...
if exist "%NSPath%" (
    "%NSPath%" -U:T -P:E "%appPath%"
) else (
    echo [ERROR] NSudoLG.exe is required for TrustedInstaller!
    pause
    goto Menu
)
exit /b