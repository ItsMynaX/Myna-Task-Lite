@echo off
title MYNA X SYSTEM - MynaTask Launcher
setlocal enabledelayedexpansion

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "appPath=%~dp0MynaTaskLite.ps1"
set "psexecPath=%~dp0lib.exe"

if not exist "%appPath%" (
    echo [ERROR] File not found: %appPath%
    pause
    exit /b
)

:Menu
cls
echo ==================================================
echo             MYNATASK LAUNCHER OPTIONS
echo ==================================================
echo Select permission:
echo.
echo [1] Run as Administrator 
echo [2] Run as SYSTEM (Highest Privileges)         
echo ==================================================
set /p "choice=Enter your choice (1 or 2): "

if "%choice%"=="1" goto RunAdmin
if "%choice%"=="2" goto RunSystem
goto Menu

:RunAdmin
cls
echo [INFO] Running MynaTask with Administrator privileges...
powershell -ExecutionPolicy Bypass -File "%appPath%"
exit /b

:RunSystem
cls
if exist "%psexecPath%" (
    echo [INFO] Running MynaTask with SYSTEM privileges...
    "%psexecPath%" -i -s powershell.exe -ExecutionPolicy Bypass -File "%appPath%"
) else (
    echo [WARNING] Cannot find lib.exe to escalate privileges to SYSTEM!
    echo [INFO] Automatically switches to run as Administrator...
    pause
    powershell -ExecutionPolicy Bypass -File "%appPath%"
)
exit /b