@echo off

echo Migrating Patient...
if not exist "lib\features\patient\presentation\screens" mkdir "lib\features\patient\presentation\screens"
robocopy "lib\screens\patient" "lib\features\patient\presentation\screens" /e /move /ndl /nfl /njh /njs

echo Migrating Caregiver...
if not exist "lib\features\caregiver\presentation\screens" mkdir "lib\features\caregiver\presentation\screens"
robocopy "lib\screens\caregiver" "lib\features\caregiver\presentation\screens" /e /move /ndl /nfl /njh /njs

echo Migrating Admin...
if not exist "lib\features\admin\presentation\screens" mkdir "lib\features\admin\presentation\screens"
robocopy "lib\screens\admin" "lib\features\admin\presentation\screens" /e /move /ndl /nfl /njh /njs

echo Migrating Shared...
if not exist "lib\features\shared\presentation\screens" mkdir "lib\features\shared\presentation\screens"
robocopy "lib\screens\shared" "lib\features\shared\presentation\screens" /e /move /ndl /nfl /njh /njs

echo Migrating Services...
if not exist "lib\core\services" mkdir "lib\core\services"
move "lib\services\*" "lib\core\services\"

echo Migrating Router...
if not exist "lib\router" mkdir "lib\router"
move "lib\routes\app_router.dart" "lib\router\"

echo FINISHED MIGRATION.
