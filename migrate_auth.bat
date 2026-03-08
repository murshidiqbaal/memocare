@echo off
if not exist "lib\features\auth\presentation\screens" mkdir "lib\features\auth\presentation\screens"
robocopy "lib\screens\auth" "lib\features\auth\presentation\screens" /e /move /ndl /nfl /njh /njs
echo Auth Migration Complete.
