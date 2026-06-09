@echo off
setlocal
echo Starting SoundPax (Web)...
echo Chrome should open automatically. Watch below for the URL (usually http://127.0.0.1:PORT).
set "PATH=%LOCALAPPDATA%\flutter\bin;%USERPROFILE%\.cargo\bin;%PATH%"
cd /d "%~dp0.."
call flutter pub get
call flutter run -d chrome
pause
