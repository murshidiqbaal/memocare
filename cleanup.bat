@echo off
if exist "lib\features\patient" rmdir /s /q "lib\features\patient"
if exist "lib\features\caregiver" rmdir /s /q "lib\features\caregiver"
if exist "lib\features\admin" rmdir /s /q "lib\features\admin"
if exist "lib\features\shared" rmdir /s /q "lib\features\shared"
if exist "lib\core\services" rmdir /s /q "lib\core\services"
if exist "lib\router" rmdir /s /q "lib\router"
echo Cleanup complete.
