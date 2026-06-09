@echo off
setlocal
echo Starting SoundPax...
echo.
echo   Desktop: a "SoundPax" window on your taskbar (native app, not a browser tab)
echo   Browser: Chrome opens in a separate window (http://127.0.0.1:PORT — see web console)
echo.
echo NOTE: Windows Developer Mode must be enabled for the desktop build.
set "PATH=%LOCALAPPDATA%\flutter\bin;%USERPROFILE%\.cargo\bin;%PATH%"
cd /d "%~dp0.."
call flutter pub get
start "SoundPax (Web)" cmd /k "%~dp0run_web.bat"
call flutter run -d windows
pause
