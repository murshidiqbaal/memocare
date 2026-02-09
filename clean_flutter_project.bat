@echo off
title Flutter Project Super Clean

echo =====================================
echo     Flutter Project Deep Cleanup
echo =====================================
echo.

:: Step 1 - Run flutter clean
echo [1/5] Running flutter clean...
flutter clean

:: Step 2 - Remove build & cache folders
echo.
echo [2/5] Removing unnecessary build/cache folders...

rd /s /q build 2>nul
rd /s /q .dart_tool 2>nul
rd /s /q android\.gradle 2>nul
rd /s /q android\app\build 2>nul
rd /s /q ios\Pods 2>nul
rd /s /q ios\.symlinks 2>nul
rd /s /q .idea 2>nul
rd /s /q .vscode 2>nul

:: Step 3 - Remove logs & temp files
echo.
echo [3/5] Removing log and temp files...
del /q *.log 2>nul
del /q *.tmp 2>nul

:: Step 4 - Re-download only required dependencies
echo.
echo [4/5] Fetching minimal dependencies...
flutter pub get

:: Step 5 - Done
echo.
echo =====================================
echo   Cleanup Completed Successfully!
echo   Your project is now ready to ZIP.
echo =====================================
echo.

pause
