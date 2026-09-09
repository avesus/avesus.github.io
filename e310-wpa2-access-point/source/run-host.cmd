@echo off
setlocal
if "%~2"=="" (
  echo Usage: run-host COM_PORT PASSPHRASE_FILE
  echo Start the radio-side packet agent first; this command does not configure RF.
  exit /b 2
)
set "GFPORT=%~1"
set "GFKEY=%~f2"
if not exist "%GFKEY%" exit /b 2
rem This is the real native executable, not a web server on the PC's network.
"%~dp0wifi_e310_link\build\windows-packets\gf_e310_windows_ap.exe" --run --port "%GFPORT%" --baud 460800 --passphrase-file "%GFKEY%" --page "%~dp0page.html" --beacon-tu 10 --seconds 0
exit /b %errorlevel%
