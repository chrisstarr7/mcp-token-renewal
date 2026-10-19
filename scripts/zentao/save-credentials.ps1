$ErrorActionPreference = 'Stop'

if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
    throw 'This credential setup uses Windows DPAPI and must run on Windows.'
}

$account = Read-Host 'ZenTao login name'
if ([string]::IsNullOrWhiteSpace($account)) {
    throw 'A non-empty ZenTao login name is required.'
}

$password = Read-Host 'ZenTao password (input is hidden)' -AsSecureString
if ($password.Length -eq 0) {
    throw 'A non-empty ZenTao password is required.'
}

$directory = Join-Path $env:LOCALAPPDATA 'McpTokenRenewal\zentao'
$null = New-Item -ItemType Directory -Force -Path $directory
$credentialPath = Join-Path $directory 'credentials.json'
$protectedPassword = ConvertFrom-SecureString -SecureString $password
$record = [ordered]@{
    account = $account
    password_protected = $protectedPassword
}
$record | ConvertTo-Json -Compress | Set-Content -LiteralPath $credentialPath -Encoding UTF8
Write-Host "Credentials saved with current-user DPAPI protection: $credentialPath"
