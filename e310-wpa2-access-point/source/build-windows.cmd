@echo off
setlocal
call "%~dp0wifi_e310_link\build_windows_packet_host.cmd" %*
exit /b %errorlevel%
