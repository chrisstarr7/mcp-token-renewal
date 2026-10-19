$ErrorActionPreference = 'Stop'
if (-not (Get-Command Get-MtrPlatform -CommandType Function -ErrorAction SilentlyContinue)) {
    . (Join-Path $PSScriptRoot 'common.ps1')
}

$credentialPath = Get-MtrCredentialPath
if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
    Write-Host 'No saved ZenTao credentials were found.'
    exit 0
}

$credential = Get-Content -LiteralPath $credentialPath -Raw | ConvertFrom-Json
if ((Get-MtrPlatform) -eq 'macOS' -and $credential.credential_id) {
    $security = Get-MtrSecurityCommand
    & $security delete-generic-password -s (Get-MtrCredentialService) -a ([string]$credential.credential_id) 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Could not remove the ZenTao password from macOS Keychain.' }
}

Remove-Item -LiteralPath $credentialPath -Force
Write-Host 'Saved ZenTao credentials removed.'
