@echo off
setlocal
rem An alternate directory builds a candidate without relinking the live EXE.
set "BUILD_DIR=%~dp0build\windows-packets"
if not "%~1"=="" set "BUILD_DIR=%~f1"
if not "%~2"=="" exit /b 2
set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" exit /b 2
for /f "usebackq delims=" %%I in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSROOT=%%I"
if not defined VSROOT exit /b 2
call "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 exit /b %errorlevel%
cmake.exe -S "%~dp0host\windows" -B "%BUILD_DIR%" -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 exit /b %errorlevel%
cmake.exe --build "%BUILD_DIR%" --config Release
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_windows_protocol_selftest.exe"
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_packet_wire_selftest.exe"
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_rx_event_selftest.exe"
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_counter_snapshot_test.exe"
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_packet_tx_wait_selftest.exe"
if errorlevel 1 exit /b %errorlevel%
"%BUILD_DIR%\gf_e310_windows_ap.exe" --self-test
exit /b %errorlevel%
