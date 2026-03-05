@echo off
REM ============================================
REM  Resto RMS - Startup Script (Windows)
REM  Usage: start.bat [edge|chrome|mobile|desktop]
REM ============================================

setlocal enabledelayedexpansion

set "TARGET=%~1"
if "%TARGET%"=="" set "TARGET=edge"

echo ========================================
echo   Resto RMS - Starting Services
echo ========================================
echo.

REM ------------------------------------------
REM 1. Start Backend
REM ------------------------------------------
echo [1/2] Starting backend server...
cd /d "%~dp0backend"
start "Resto-Backend" /min cmd /c "node src/app.js"
echo   Backend starting in background...

REM Wait for backend
echo   Waiting for backend...
set /a count=0
:wait_loop
if %count% geq 30 (
    echo   WARNING: Backend may not be ready yet, continuing anyway...
    goto :start_frontend
)
timeout /t 1 /nobreak >nul
curl.exe -s http://localhost:3000/health >nul 2>&1
if %errorlevel%==0 (
    echo   Backend is ready on http://localhost:3000
    goto :start_frontend
)
set /a count+=1
goto :wait_loop

:start_frontend
echo.

REM ------------------------------------------
REM 2. Start Flutter Frontend
REM ------------------------------------------
echo [2/2] Starting Flutter frontend (target: %TARGET%)...
cd /d "%~dp0"

if /i "%TARGET%"=="edge" (
    echo   Launching on Microsoft Edge...
    flutter run -d edge
) else if /i "%TARGET%"=="chrome" (
    echo   Launching on Chrome...
    flutter run -d chrome
) else if /i "%TARGET%"=="mobile" (
    echo   Launching on connected mobile device...
    flutter run
) else if /i "%TARGET%"=="desktop" (
    echo   Launching as desktop app...
    flutter run -d windows
) else (
    echo   Unknown target: %TARGET%
    echo   Usage: start.bat [edge^|chrome^|mobile^|desktop]
    exit /b 1
)

echo.
echo Shutting down backend...
taskkill /fi "WINDOWTITLE eq Resto-Backend" /f >nul 2>&1
echo Done.
