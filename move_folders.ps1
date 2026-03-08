# Create directories
New-Item -ItemType Directory -Force -Path "lib\features\auth\presentation\screens"
New-Item -ItemType Directory -Force -Path "lib\features\admin\presentation\screens"
New-Item -ItemType Directory -Force -Path "lib\features\caregiver\presentation"
New-Item -ItemType Directory -Force -Path "lib\features\patient\presentation"
New-Item -ItemType Directory -Force -Path "lib\core\services"
New-Item -ItemType Directory -Force -Path "lib\router"

# Move files
if (Test-Path "lib\screens\auth") { Copy-Item -Path "lib\screens\auth\*" -Destination "lib\features\auth\presentation\screens\" -Recurse -Force; Remove-Item -Path "lib\screens\auth" -Recurse -Force }
if (Test-Path "lib\screens\admin") { Copy-Item -Path "lib\screens\admin\*" -Destination "lib\features\admin\presentation\screens\" -Recurse -Force; Remove-Item -Path "lib\screens\admin" -Recurse -Force }
if (Test-Path "lib\screens\caregiver") { Copy-Item -Path "lib\screens\caregiver" -Destination "lib\features\caregiver\presentation\screens" -Recurse -Force; Remove-Item -Path "lib\screens\caregiver" -Recurse -Force }
if (Test-Path "lib\screens\patient") { Copy-Item -Path "lib\screens\patient" -Destination "lib\features\patient\presentation\screens" -Recurse -Force; Remove-Item -Path "lib\screens\patient" -Recurse -Force }
if (Test-Path "lib\services") { Copy-Item -Path "lib\services\*" -Destination "lib\core\services\" -Recurse -Force; Remove-Item -Path "lib\services" -Recurse -Force }
if (Test-Path "lib\routes") { Copy-Item -Path "lib\routes\*" -Destination "lib\router\" -Recurse -Force; Remove-Item -Path "lib\routes" -Recurse -Force }

Out-File -FilePath "powershell_done.txt" -InputObject "done"
