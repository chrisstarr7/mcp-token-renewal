function Get-MtrPlatform {
    if ($IsWindows -or [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { return 'Windows' }
    if ($IsMacOS) { return 'macOS' }
    throw 'ZenTao setup supports Windows and macOS only.'
}

function Get-MtrHomeDirectory {
    $homePath = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
    if ([string]::IsNullOrWhiteSpace($homePath)) { throw 'Could not determine the current user home directory.' }
    return $homePath
}

function Get-MtrConfigPath([ValidateSet('Codex', 'Claude')][string]$Client) {
    $homePath = Get-MtrHomeDirectory
    if ($Client -eq 'Codex') { return Join-Path (Join-Path $homePath '.codex') 'config.toml' }
    return Join-Path $homePath '.claude.json'
}

function Get-MtrCredentialDirectory {
    $homePath = Get-MtrHomeDirectory
    if ((Get-MtrPlatform) -eq 'Windows') {
        $basePath = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $homePath 'AppData/Local' }
        return Join-Path $basePath 'McpTokenRenewal/zentao'
    }
    return Join-Path $homePath 'Library/Application Support/McpTokenRenewal/zentao'
}

function Get-MtrCredentialPath {
    return Join-Path (Get-MtrCredentialDirectory) 'credentials.json'
}

function ConvertTo-MtrShellArgument([string]$Value) {
    $quote = "'"
    $escaped = $Value.Replace($quote, ($quote + '"' + $quote + '"' + $quote))
    return $quote + $escaped + $quote
}

function Get-MtrHelperCommand([string]$HelperPath) {
    $platform = Get-MtrPlatform
    if ($platform -eq 'Windows') {
        $powershell = Get-Command powershell.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1
        $powershellPath = if ($powershell.Source) { $powershell.Source } else { $powershell.Path }
        if ([string]::IsNullOrWhiteSpace($powershellPath)) { throw 'Windows PowerShell is required.' }
        $quotedPwsh = '"' + $powershellPath.Replace('"', '\"') + '"'
        $quotedHelper = '"' + $HelperPath.Replace('"', '\"') + '"'
        return "$quotedPwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $quotedHelper"
    }

    $pwsh = Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $pwshPath = if ($pwsh.Source) { $pwsh.Source } else { $pwsh.Path }
    if ([string]::IsNullOrWhiteSpace($pwshPath)) { throw 'PowerShell 7 (pwsh) is required on macOS.' }
    return "$(ConvertTo-MtrShellArgument $pwshPath) -NoProfile -NonInteractive -File $(ConvertTo-MtrShellArgument $HelperPath)"
}

function Get-MtrSecurityCommand {
    if ((Get-MtrPlatform) -ne 'macOS') { throw 'macOS Keychain is available only on macOS.' }
    return '/usr/bin/security'
}

function Get-MtrCredentialService {
    return 'mcp-token-renewal.zentao'
}

function Get-MtrLoginUri {
    return 'https://pms.daoyoudao.com/api.php/v2/users/login'
}

function Import-MtrSecurityModule {
    if ((Get-MtrPlatform) -eq 'Windows' -and -not (Get-Command ConvertTo-SecureString -ErrorAction SilentlyContinue)) {
        $manifest = Join-Path $PSHOME 'Modules/Microsoft.PowerShell.Security/Microsoft.PowerShell.Security.psd1'
        Import-Module -Name $manifest -ErrorAction Stop
    }
}
