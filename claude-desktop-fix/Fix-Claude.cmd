@echo off
REM Fix-Claude.cmd - one double-click repair for install error 0x80073D05.
REM Self-elevates, clears the stale app-data store, restores the shortcut,
REM then opens the download page if the app needs reinstalling.

net session >/dev/null 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator rights...
    powershell -NoProfile -Command "Start-Process -FilePath %~f0 -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
echo ============================================
echo   Claude Desktop install repair (0x80073D05)
echo ============================================
echo.

echo [1/2] Clearing the stale app-data store...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Repair-ClaudeDesktopInstall.ps1"
echo.

echo [2/2] Checking the app and desktop shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -File ".\Restore-ClaudeDesktopShortcut.ps1"
echo.

echo ============================================
echo   Next: if the check above said Claude is NOT
echo   installed, install it from the page opening
echo   now. Choose the Windows download and run it.
echo ============================================
echo.
set /p OPEN=Open the download page now? [Y/n] 
if /i not "%OPEN%"=="n" start "" https://claude.ai/download
echo.
pause
