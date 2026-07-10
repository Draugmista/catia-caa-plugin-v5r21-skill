param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$Framework,

    [string]$Module
)

$ErrorActionPreference = "Stop"

$script:OkCount = 0
$script:WarningCount = 0
$script:MissingCount = 0

function Write-Check {
    param(
        [ValidateSet("OK", "WARN", "MISSING")]
        [string]$Status,
        [string]$Message,
        [string]$Path = ""
    )

    switch ($Status) {
        "OK" { $script:OkCount++ }
        "WARN" { $script:WarningCount++ }
        "MISSING" { $script:MissingCount++ }
    }

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
        return
    }

    if ($Required) {
        Write-Check "MISSING" $Label $Path
    }
    else {
        Write-Check "WARN" $Label $Path
    }
}

function Test-Directory {
    param(
        [string]$Label,
        [string]$Path,
        [switch]$Required
    )

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Write-Check "OK" $Label $Path
        return
    }

    if ($Required) {
        Write-Check "MISSING" $Label $Path
    }
    else {
        Write-Check "WARN" $Label $Path
    }
}

if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    Write-Output "[MISSING] Project root :: $ProjectRoot"
    Write-Output ""
    Write-Output "Summary: OK=0 WARN=0 MISSING=1"
    exit 2
}

$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
Write-Output "CAA project preflight: $root"

Test-File "CAA level file" (Join-Path $root "CATIAV5Level.lvl") -Required
Test-File "Install config" (Join-Path $root "Install_config_win_b64") -Required
Test-Directory "Runtime bin directory" (Join-Path $root "win_b64\code\bin")
Test-Directory "Runtime dictionary directory" (Join-Path $root "win_b64\code\dictionary")
Test-Directory "Runtime msgcatalog directory" (Join-Path $root "win_b64\resources\msgcatalog")

$frameworkRoots = @()
if ($Framework) {
    $frameworkRoots = @(Join-Path $root $Framework)
}
else {
    $frameworkRoots = @(
        Get-ChildItem -LiteralPath $root -Directory |
            Where-Object {
                Test-Path -LiteralPath (Join-Path $_.FullName "IdentityCard\IdentityCard.h") -PathType Leaf
            } |
            ForEach-Object { $_.FullName }
    )
}

if (-not $frameworkRoots -or $frameworkRoots.Count -eq 0) {
    Write-Check "MISSING" "No framework with IdentityCard\IdentityCard.h found" $root
}
else {
    foreach ($frameworkRoot in $frameworkRoots) {
        $frameworkName = Split-Path -Path $frameworkRoot -Leaf
        Write-Output ""
        Write-Output "Framework: $frameworkName"

        Test-File "Identity card" (Join-Path $frameworkRoot "IdentityCard\IdentityCard.h") -Required
        Test-Directory "Public interfaces" (Join-Path $frameworkRoot "PublicInterfaces")
        Test-Directory "CNext dictionary source" (Join-Path $frameworkRoot "CNext\code\dictionary")
        Test-Directory "CNext msgcatalog source" (Join-Path $frameworkRoot "CNext\resources\msgcatalog")

        $moduleRoots = @()
        if ($Module) {
            $moduleRoots = @(Join-Path $frameworkRoot $Module)
        }
        elseif (Test-Path -LiteralPath $frameworkRoot -PathType Container) {
            $moduleRoots = @(
                Get-ChildItem -LiteralPath $frameworkRoot -Directory -Filter "*.m" |
                    ForEach-Object { $_.FullName }
            )
        }

        if (-not $moduleRoots -or $moduleRoots.Count -eq 0) {
            Write-Check "WARN" "No module directory (*.m) found" $frameworkRoot
            continue
        }

        foreach ($moduleRoot in $moduleRoots) {
            $moduleName = Split-Path -Path $moduleRoot -Leaf
            $moduleBase = $moduleName -replace '\.m$', ''
            Write-Output "  Module: $moduleName"

            Test-File "  Imakefile" (Join-Path $moduleRoot "Imakefile.mk") -Required
            Test-Directory "  Local interfaces" (Join-Path $moduleRoot "LocalInterfaces") -Required
            Test-Directory "  Source directory" (Join-Path $moduleRoot "src") -Required

            $dllPath = Join-Path $root "win_b64\code\bin\$moduleBase.dll"
            $libPath = Join-Path $root "win_b64\code\lib\$moduleBase.lib"
            Test-File "  Runtime DLL" $dllPath
            Test-File "  Runtime import lib" $libPath
        }

        $dictionarySourceRoot = Join-Path $frameworkRoot "CNext\code\dictionary"
        $sourceDicos = @(
            Get-ChildItem -LiteralPath $dictionarySourceRoot -Filter "*.dico" -ErrorAction SilentlyContinue
        )
        foreach ($dico in $sourceDicos) {
            $runtimeDico = Join-Path $root "win_b64\code\dictionary\$($dico.Name)"
            Test-File "Runtime dictionary copy for $($dico.Name)" $runtimeDico
        }

        $msgCatalogSourceRoot = Join-Path $frameworkRoot "CNext\resources\msgcatalog"
        $sourceNls = @(
            Get-ChildItem -LiteralPath $msgCatalogSourceRoot -Filter "*.CATNls" -ErrorAction SilentlyContinue
        )
        foreach ($nls in $sourceNls) {
            $runtimeNls = Join-Path $root "win_b64\resources\msgcatalog\$($nls.Name)"
            Test-File "Runtime msgcatalog copy for $($nls.Name)" $runtimeNls
        }

        $sourceRsc = @(
            Get-ChildItem -LiteralPath $msgCatalogSourceRoot -Filter "*.CATRsc" -ErrorAction SilentlyContinue
        )
        foreach ($rsc in $sourceRsc) {
            $runtimeRsc = Join-Path $root "win_b64\resources\msgcatalog\$($rsc.Name)"
            Test-File "Runtime msgcatalog copy for $($rsc.Name)" $runtimeRsc
        }

        $sourceIconRoot = Join-Path $frameworkRoot "CNext\resources\graphic\icons\normal"
        if (Test-Path -LiteralPath $sourceIconRoot -PathType Container) {
            $sourceIcons = @(
                Get-ChildItem -LiteralPath $sourceIconRoot -Filter "*.bmp" -ErrorAction SilentlyContinue
            )
            foreach ($icon in $sourceIcons) {
                $runtimeIcon = Join-Path $root "win_b64\resources\graphic\icons\normal\$($icon.Name)"
                Test-File "Runtime toolbar icon copy for $($icon.Name)" $runtimeIcon
            }
        }
    }
}

Write-Output ""
Write-Output "Summary: OK=$script:OkCount WARN=$script:WarningCount MISSING=$script:MissingCount"

if ($script:MissingCount -gt 0) {
    exit 2
}
if ($script:WarningCount -gt 0) {
    exit 1
}
exit 0
