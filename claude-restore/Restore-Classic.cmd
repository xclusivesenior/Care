@echo off
REM Restore Claude Desktop to a clean install. Just double-click this file.
REM It asks Windows for administrator rights, then runs Restore-Classic.ps1.

setlocal
set "PS1=%~dp0Restore-Classic.ps1"

if not exist "%PS1%" (
  echo.
  echo   Could not find Restore-Classic.ps1 next to this file.
  echo   Keep both files together in the same folder.
  echo.
  pause
  exit /b 1
)

net session >nul 2>&1
if %errorlevel%==0 goto run

echo.
echo   Asking Windows for administrator rights...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PS1%\"'"
exit /b 0

:run
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
exit /b %errorlevel%
