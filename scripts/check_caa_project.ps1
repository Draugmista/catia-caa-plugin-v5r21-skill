param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$Framework,

    [string]$Module
)

$ErrorActionPreference = "Stop"

function Write-Check {
    param(
        [string]$Status,
        [string]$Message,
        [string]$Path = ""
    )

    $line = "[$Status] $Message"
    if ($Path) {
        $line = "$line :: $Path"
    }
    Write-Output $line
}

function Test-File {
    param(
        [string]$Label,
        [string]$Path,
        [switch]$Required
    )

    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Write-Check "OK" $Label $Path
        return $true
    }

    if ($Required) {
        Write-Check "MISSING" $Label $Path
    }
    else {
        Write-Check "WARN" $Label $Path
    }
    return $false
}

function Test-Directory {
    param(
        [string]$Label,
        [string]$Path,
        [switch]$Required
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Write-Check "OK" $Label $Path
        return $true
    }

    if ($Required) {
        Write-Check "MISSING" $Label $Path
    }
    else {
        Write-Check "WARN" $Label $Path
    }
    return $false
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
Write-Output "CAA project preflight: $root"

Test-File "CAA level file" (Join-Path $root "CATIAV5Level.lvl") -Required | Out-Null
Test-File "Install config" (Join-Path $root "Install_config_win_b64") -Required | Out-Null
Test-Directory "Runtime bin directory" (Join-Path $root "win_b64\code\bin") | Out-Null
Test-Directory "Runtime dictionary directory" (Join-Path $root "win_b64\code\dictionary") | Out-Null
Test-Directory "Runtime msgcatalog directory" (Join-Path $root "win_b64\resources\msgcatalog") | Out-Null

$frameworkRoots = @()
if ($Framework) {
    $frameworkRoots = @(Join-Path $root $Framework)
}
else {
    $frameworkRoots = Get-ChildItem -LiteralPath $root -Directory |
        Where-Object {
            Test-Path -LiteralPath (Join-Path $_.FullName "IdentityCard\IdentityCard.h") -PathType Leaf
        } |
        ForEach-Object { $_.FullName }
}

if (-not $frameworkRoots -or $frameworkRoots.Count -eq 0) {
    Write-Check "MISSING" "No framework with IdentityCard\IdentityCard.h found" $root
    exit 2
}

foreach ($frameworkRoot in $frameworkRoots) {
    $frameworkName = Split-Path -Path $frameworkRoot -Leaf
    Write-Output ""
    Write-Output "Framework: $frameworkName"

    Test-File "Identity card" (Join-Path $frameworkRoot "IdentityCard\IdentityCard.h") -Required | Out-Null
    Test-Directory "Public interfaces" (Join-Path $frameworkRoot "PublicInterfaces") | Out-Null
    Test-Directory "CNext dictionary source" (Join-Path $frameworkRoot "CNext\code\dictionary") | Out-Null
    Test-Directory "CNext msgcatalog source" (Join-Path $frameworkRoot "CNext\resources\msgcatalog") | Out-Null

    $moduleRoots = @()
    if ($Module) {
        $moduleRoots = @(Join-Path $frameworkRoot $Module)
    }
    else {
        $moduleRoots = Get-ChildItem -LiteralPath $frameworkRoot -Directory -Filter "*.m" |
            ForEach-Object { $_.FullName }
    }

    if (-not $moduleRoots -or $moduleRoots.Count -eq 0) {
        Write-Check "WARN" "No module directory (*.m) found" $frameworkRoot
        continue
    }

    foreach ($moduleRoot in $moduleRoots) {
        $moduleName = Split-Path -Path $moduleRoot -Leaf
        $moduleBase = $moduleName -replace '\.m$', ''
        Write-Output "  Module: $moduleName"

        Test-File "  Imakefile" (Join-Path $moduleRoot "Imakefile.mk") -Required | Out-Null
        Test-Directory "  Local interfaces" (Join-Path $moduleRoot "LocalInterfaces") -Required | Out-Null
        Test-Directory "  Source directory" (Join-Path $moduleRoot "src") -Required | Out-Null

        $dllPath = Join-Path $root "win_b64\code\bin\$moduleBase.dll"
        $libPath = Join-Path $root "win_b64\code\lib\$moduleBase.lib"
        Test-File "  Runtime DLL" $dllPath | Out-Null
        Test-File "  Runtime import lib" $libPath | Out-Null
    }

    $sourceDicos = Get-ChildItem -LiteralPath (Join-Path $frameworkRoot "CNext\code\dictionary") -Filter "*.dico" -ErrorAction SilentlyContinue
    foreach ($dico in $sourceDicos) {
        $runtimeDico = Join-Path $root "win_b64\code\dictionary\$($dico.Name)"
        Test-File "Runtime dictionary copy for $($dico.Name)" $runtimeDico | Out-Null
    }

    $sourceNls = Get-ChildItem -LiteralPath (Join-Path $frameworkRoot "CNext\resources\msgcatalog") -Filter "*.CATNls" -ErrorAction SilentlyContinue
    foreach ($nls in $sourceNls) {
        $runtimeNls = Join-Path $root "win_b64\resources\msgcatalog\$($nls.Name)"
        Test-File "Runtime msgcatalog copy for $($nls.Name)" $runtimeNls | Out-Null
    }
}
