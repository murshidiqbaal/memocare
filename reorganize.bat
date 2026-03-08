@echo off

echo Reorganizing Patient...
if exist "lib\features\patient\presentation\screens\patient" (
    move "lib\features\patient\presentation\screens\patient\*" "lib\features\patient\presentation\screens\"
    rmdir /s /q "lib\features\patient\presentation\screens\patient"
)

echo Reorganizing Caregiver...
if exist "lib\features\caregiver\presentation\screens\caregiver" (
    move "lib\features\caregiver\presentation\screens\caregiver\*" "lib\features\caregiver\presentation\screens\"
    rmdir /s /q "lib\features\caregiver\presentation\screens\caregiver"
)

echo Reorganizing Admin...
if exist "lib\features\admin\presentation\screens\admin" (
    move "lib\features\admin\presentation\screens\admin\*" "lib\features\admin\presentation\screens\"
    rmdir /s /q "lib\features\admin\presentation\screens\admin"
)

echo Reorganizing Auth...
if exist "lib\features\auth\presentation\screens\auth" (
    move "lib\features\auth\presentation\screens\auth\*" "lib\features\auth\presentation\screens\"
    rmdir /s /q "lib\features\auth\presentation\screens\auth"
)

echo Reorganizing Shared...
if exist "lib\features\shared\presentation\screens\shared" (
    move "lib\features\shared\presentation\screens\shared\*" "lib\features\shared\presentation\screens\"
    rmdir /s /q "lib\features\shared\presentation\screens\shared"
)

echo DONE.
