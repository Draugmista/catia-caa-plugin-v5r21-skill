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
    "CPP_FATAL" = "\bfatal error C[0-9]+\b"
    "CPP_ERROR" = "\berror C[0-9]+\b"
    "LINK_ERROR" = "\b(?:fatal error|error)\s+LNK[0-9]+\b|unresolved external symbol"
    "LINK_GATE_WARNING" = "\b(?:warning\s+)?LNK(?:4006|4088)\b"
    "LINK_WARNING" = "\bwarning\s+LNK(?!(?:4006|4088)\b)[0-9]+\b"
    "ENCODING_WARNING" = "warning C4819|常量中有换行符|newline in constant"
    "IGNORED_LINK_MODULE" = "ignored because it is not a direct prerequisite|not a direct prerequisite"
}

Write-Output "mkmk log scan: $path"

$findings = @{}
foreach ($name in $patterns.Keys) {
    $matches = @($lines | Select-String -Pattern $patterns[$name])
    $findings[$name] = $matches
    if ($matches.Count -eq 0) {
        continue
    }

    Write-Output ""
    Write-Output "[$name]"
    $matches | Select-Object -First 12 | ForEach-Object {
        Write-Output ("{0}: {1}" -f $_.LineNumber, $_.Line.Trim())
    }
}

Write-Output ""
$hasFindings = ($findings.Values | Where-Object { $_.Count -gt 0 }).Count -gt 0
if (-not $hasFindings) {
    Write-Output "Conclusion: no known fatal/error patterns were found. Still verify runtime artifacts because mkmk can skip up-to-date outputs."
    exit 0
}

if ($findings["LICENSE_MAB"].Count -gt 0) {
    Write-Output "Conclusion: license/setup failure is present. Do not treat this as a C++ fix until RADE/CATIA license context is verified."
    exit 3
}

$compileFailureNames = @("CPP_FATAL", "CPP_ERROR", "LINK_ERROR", "LINK_GATE_WARNING")
if (($compileFailureNames | Where-Object { $findings[$_].Count -gt 0 }).Count -gt 0) {
    Write-Output "Conclusion: compile, link, or link-gate failure is present. Fix the first C++ or linker failure before chasing secondary output."
    exit 2
}

$buildFailureNames = @("MKMK_ERROR", "MAKE_ERROR", "SYSTEM_ERROR", "IGNORED_LINK_MODULE")
if (($buildFailureNames | Where-Object { $findings[$_].Count -gt 0 }).Count -gt 0) {
    Write-Output "Conclusion: build-system failure is present. Check CATIAV5Level.lvl, Install_config_win_b64, IdentityCard.h, and direct prerequisites."
    exit 2
}

Write-Output "Conclusion: reviewable warnings were found, but no known fatal or build-gate pattern matched."
exit 1
