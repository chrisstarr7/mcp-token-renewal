$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'common.ps1')

$platform = Get-MtrPlatform

$account = Read-Host 'ZenTao login name'
if ([string]::IsNullOrWhiteSpace($account)) {
    throw 'A non-empty ZenTao login name is required.'
}

$directory = Get-MtrCredentialDirectory
$null = New-Item -ItemType Directory -Force -Path $directory
$credentialPath = Get-MtrCredentialPath
$keychainItemAdded = $false
$credentialId = $null
$oldCredentialId = $null
if ($platform -eq 'macOS' -and (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
    try { $oldCredentialId = [string](Get-Content -LiteralPath $credentialPath -Raw | ConvertFrom-Json).credential_id }
    catch { throw 'Existing credential metadata is invalid; resolve it before replacing credentials.' }
}

if ($platform -eq 'Windows') {
    $password = Read-Host 'ZenTao password (input is hidden)' -AsSecureString
    if ($password.Length -eq 0) { throw 'A non-empty ZenTao password is required.' }
    $record = [ordered]@{
        account = $account
        password_protected = (ConvertFrom-SecureString -SecureString $password)
    }
}
else {
    $security = Get-MtrSecurityCommand
    $credentialId = [guid]::NewGuid().ToString('N')
    Write-Host 'Enter the ZenTao password in the macOS Keychain password prompt.'
    & $security add-generic-password -U -s (Get-MtrCredentialService) -a $credentialId -w
    if ($LASTEXITCODE -ne 0) { throw 'Could not save the password to macOS Keychain.' }
    $keychainItemAdded = $true
    $record = [ordered]@{
        account = $account
        credential_id = $credentialId
    }
}

$temporaryPath = "$credentialPath.tmp-$PID"
try {
    [IO.File]::WriteAllText($temporaryPath, ($record | ConvertTo-Json -Compress), [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $credentialPath -Force
}
catch {
    if ($keychainItemAdded) {
        & $security delete-generic-password -s (Get-MtrCredentialService) -a $credentialId 2>$null
    }
    throw
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force -ErrorAction SilentlyContinue
    }
}
if ($platform -eq 'macOS' -and $oldCredentialId -and $oldCredentialId -ne $credentialId) {
    & $security delete-generic-password -s (Get-MtrCredentialService) -a $oldCredentialId 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Warning 'The old macOS Keychain entry could not be removed.' }
}
if ($platform -eq 'Windows') {
    Write-Host "Credentials saved with current-user DPAPI protection: $credentialPath"
}
else {
    Write-Host "ZenTao password saved in macOS Keychain; account metadata saved to $credentialPath"
}
