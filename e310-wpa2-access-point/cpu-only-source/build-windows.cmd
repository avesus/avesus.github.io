@echo off
setlocal
cmake -S "%~dp0." -B "%~dp0build" -A x64
if errorlevel 1 exit /b 1
cmake --build "%~dp0build" --config Release --parallel 4
if errorlevel 1 exit /b 1
ctest --test-dir "%~dp0build" -C Release --output-on-failure
exit /b %errorlevel%
