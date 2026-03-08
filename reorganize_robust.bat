@echo off

echo Reorganizing Patient...
if exist "lib\features\patient\presentation\screens\patient" (
    robocopy "lib\features\patient\presentation\screens\patient" "lib\features\patient\presentation\screens" /e /move /ndl /nfl /njh /njs
)

echo Reorganizing Caregiver...
if exist "lib\features\caregiver\presentation\screens\caregiver" (
    robocopy "lib\features\caregiver\presentation\screens\caregiver" "lib\features\caregiver\presentation\screens" /e /move /ndl /nfl /njh /njs
)

echo Reorganizing Admin...
if exist "lib\features\admin\presentation\screens\admin" (
    robocopy "lib\features\admin\presentation\screens\admin" "lib\features\admin\presentation\screens" /e /move /ndl /nfl /njh /njs
)

echo Reorganizing Auth...
if exist "lib\features\auth\presentation\screens\auth" (
    robocopy "lib\features\auth\presentation\screens\auth" "lib\features\auth\presentation\screens" /e /move /ndl /nfl /njh /njs
)

echo Reorganizing Shared...
if exist "lib\features\shared\presentation\screens\shared" (
    robocopy "lib\features\shared\presentation\screens\shared" "lib\features\shared\presentation\screens" /e /move /ndl /nfl /njh /njs
)

echo DONE.
