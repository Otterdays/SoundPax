@echo off
setlocal
echo Usage: create_from_template.bat "My App" com.mycompany "C:\path\to\new_app"
echo.
if "%~3"=="" (
  echo Example:
  echo   create_from_template.bat "My App" com.mycompany "C:\dev\my_app"
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create_from_template.ps1" -AppName "%~1" -Org "%~2" -OutputDir "%~3"
pause
