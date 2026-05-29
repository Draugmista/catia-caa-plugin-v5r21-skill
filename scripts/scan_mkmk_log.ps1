param(
    [Parameter(Mandatory = $true)]
    [string]$LogPath
)

$ErrorActionPreference = "Stop"

$path = (Resolve-Path -LiteralPath $LogPath).Path
$lines = Get-Content -LiteralPath $path

$patterns = [ordered]@{
    "LICENSE_MAB" = "RequestLicensesFromSettings|requested licenses do not authorize|MAB"
    "MKMK_ERROR" = "mkmk-ERROR"
    "MAKE_ERROR" = "make-ERROR"
    "SYSTEM_ERROR" = "syst-ERROR"
    "CPP_FATAL" = "fatal error"
    "CPP_ERROR" = "error C[0-9]+"
    "LINK_ERROR" = "LNK[0-9]+|unresolved external symbol"
    "ENCODING_WARNING" = "warning C4819|常量中有换行符|newline in constant"
    "IGNORED_LINK_MODULE" = "ignored because it is not a direct prerequisite|not a direct prerequisite"
}

Write-Output "mkmk log scan: $path"

$hasFindings = $false
foreach ($name in $patterns.Keys) {
    $matches = $lines | Select-String -Pattern $patterns[$name]
    if (-not $matches) {
        continue
    }

    $hasFindings = $true
    Write-Output ""
    Write-Output "[$name]"
    $matches | Select-Object -First 12 | ForEach-Object {
        Write-Output ("{0}: {1}" -f $_.LineNumber, $_.Line.Trim())
    }
}

Write-Output ""
if (-not $hasFindings) {
    Write-Output "Conclusion: no known fatal/error patterns were found. Still verify runtime artifacts because mkmk can skip up-to-date outputs."
    exit 0
}

if (($lines | Select-String -Pattern $patterns["LICENSE_MAB"])) {
    Write-Output "Conclusion: license/setup failure is present. Do not treat this as a C++ fix until RADE/CATIA license context is verified."
    exit 3
}

$compilePattern = @($patterns["CPP_FATAL"], $patterns["CPP_ERROR"], $patterns["LINK_ERROR"]) -join "|"
if (($lines | Select-String -Pattern $compilePattern)) {
    Write-Output "Conclusion: compile or link failure is present. Fix the first C++ error before chasing secondary linker output."
    exit 2
}

$buildPattern = @($patterns["MKMK_ERROR"], $patterns["MAKE_ERROR"], $patterns["SYSTEM_ERROR"], $patterns["IGNORED_LINK_MODULE"]) -join "|"
if (($lines | Select-String -Pattern $buildPattern)) {
    Write-Output "Conclusion: build-system failure is present. Check CATIAV5Level.lvl, Install_config_win_b64, IdentityCard.h, and direct prerequisites."
    exit 2
}

Write-Output "Conclusion: warnings or known non-fatal patterns found. Review the grouped lines above."
exit 1
