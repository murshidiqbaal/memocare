$files = Get-ChildItem -Path "lib\features" -Filter *.dart -Recurse

foreach ($f in $files) {
    try {
        $content = Get-Content -Path $f.FullName -Raw
        $newContent = [regex]::Replace($content, "(import|export)\s+'(\.\./)", "`$1 '../../`$2")
        
        if ($newContent -cne $content) {
            Set-Content -Path $f.FullName -Value $newContent -NoNewline
        }
    } catch {
    }
}

$services = Get-ChildItem -Path "lib\core\services" -Filter *.dart -Recurse
foreach ($f in $services) {
    try {
        $content = Get-Content -Path $f.FullName -Raw
        $newContent = [regex]::Replace($content, "(import|export)\s+'(\.\./)", "`$1 '../`$2")
        if ($newContent -cne $content) {
            Set-Content -Path $f.FullName -Value $newContent -NoNewline
        }
    } catch {}
}

$routes = Get-ChildItem -Path "lib\router" -Filter *.dart -Recurse
foreach ($f in $routes) {
    try {
        $content = Get-Content -Path $f.FullName -Raw
        $newContent = [regex]::Replace($content, "(\.\./)screens/([^/]+)/", "`$1features/`$2/presentation/screens/")
        if ($newContent -cne $content) {
            Set-Content -Path $f.FullName -Value $newContent -NoNewline
        }
    } catch {}
}
