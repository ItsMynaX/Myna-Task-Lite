@echo off
setlocal EnableDelayedExpansion
title Myna Task Launcher
color 0F

cd /d "%~dp0"

echo [STEP 1] Verifying Administrator privileges...

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting Administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

if exist "%~dp0Assets\7z\libstdc++-6.7z" (
    if exist "%~dp0Assets\7z\7z.exe" (
        echo [INFO] Unpacking runtime dependencies...
        "%~dp0Assets\7z\7z.exe" x -o"%~dp0" "%~dp0Assets\7z\libstdc++-6.7z" -aoa -y >nul 2>&1
    )
)

if exist "%~dp0RisksAcceptance.ini" (
    for /f "tokens=2 delims==" %%a in ('findstr /i "^Acceptance" "%~dp0RisksAcceptance.ini" 2^>nul') do (
        set "val=%%a"
        set "val=!val: =!"
        if /i "!val!"=="true" goto Main
    )
)

:EnvironmentWarning
cls
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
powershell -Command "Write-Host '          ENVIRONMENT COMPATIBILITY WARNING         ' -ForegroundColor Yellow"
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
echo.
powershell -Command "Write-Host 'NOTICE: Special OS Environment Compatibility Warning' -ForegroundColor Yellow"
echo.
echo   This application relies heavily on native Windows APIs, DWM composition, 
echo   WMI system telemetry, and standard core background services.
echo.
echo   If running in WinPE, WinLite, or heavily modified OS environments:
echo    * The application may freeze, crash, or fail to render UI elements.
echo    * System metrics and process monitoring features may fail.
echo    * SYSTEM or TrustedInstaller escalation may not function properly.
echo.
powershell -Command "Write-Host '==================================================' -ForegroundColor Yellow"
echo Please choose how you would like to proceed:
echo.
echo   [1] I agree and understand the risks (Continue)
echo   [2] Exit launcher
echo.
set /p "warnChoice=Enter your choice (1-2): "

if "%warnChoice%"=="1" (
    (
        echo [RisksAcceptance]
        echo Acceptance = true
    ) > "%~dp0RisksAcceptance.ini"
    goto Main
)
if "%warnChoice%"=="2" exit /b
goto EnvironmentWarning

:Main
set "appPath=%~dp0MynaTaskCore.exe"
set "TICorePath=%~dp0TICore.exe"

if not exist "%appPath%" (
    powershell -Command "Write-Host '[ERROR] File not found: %appPath%' -ForegroundColor Red"
    pause
    exit /b
)

if not exist "%TICorePath%" (
    powershell -Command "Write-Host '[ERROR] TICore.exe not found in root directory!' -ForegroundColor Red"
    pause
    exit /b
)

:Menu
cls
echo ==================================================
echo                  Myna Task Launcher
echo ==================================================
echo   Target: %appPath%
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
echo [INFO] Escalating to SYSTEM privileges via TICore...
"%TICorePath%" --System "%appPath%"
exit /b

:RunTrustInstaller
cls
echo [INFO] Escalating to TrustedInstaller privileges via TICore...
"%TICorePath%" --TI "%appPath%"
exit /b