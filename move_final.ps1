# Ensure parent directories exist
New-Item -ItemType Directory -Force -Path "lib\features\admin\presentation"
New-Item -ItemType Directory -Force -Path "lib\features\auth\presentation"
New-Item -ItemType Directory -Force -Path "lib\features\caregiver\presentation"
New-Item -ItemType Directory -Force -Path "lib\features\patient\presentation"
New-Item -ItemType Directory -Force -Path "lib\features\shared\presentation"

if (Test-Path "lib\screens\admin") { Move-Item -Path "lib\screens\admin" -Destination "lib\features\admin\presentation\screens" -Force }
if (Test-Path "lib\screens\auth") { Move-Item -Path "lib\screens\auth" -Destination "lib\features\auth\presentation\screens" -Force }
if (Test-Path "lib\screens\caregiver") { Move-Item -Path "lib\screens\caregiver" -Destination "lib\features\caregiver\presentation\screens" -Force }
if (Test-Path "lib\screens\patient") { Move-Item -Path "lib\screens\patient" -Destination "lib\features\patient\presentation\screens" -Force }
if (Test-Path "lib\screens\shared") { Move-Item -Path "lib\screens\shared" -Destination "lib\features\shared\presentation\screens" -Force }

if (Test-Path "lib\services") { Move-Item -Path "lib\services" -Destination "lib\core\services" -Force }
if (Test-Path "lib\routes") { Move-Item -Path "lib\routes" -Destination "lib\router" -Force }
