$ErrorActionPreference = 'Stop'

$serverName = 'zentao'
$serverUrl = 'https://pms.daoyoudao.com/zentao/mcp'
$helperPath = Join-Path $PSScriptRoot 'get-headers.ps1'

function Get-HelperCommand {
    $escapedPath = $helperPath.Replace('"', '\"')
    return "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File `"$escapedPath`""
}

function Backup-ConfigFile([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
        $backupPath = "$Path.bak-$stamp"
        Copy-Item -LiteralPath $Path -Destination $backupPath
        Write-Host "Backed up existing config to $backupPath"
    }
}

function Write-ConfigFile([string]$Path, [string]$Content) {
    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        $null = New-Item -ItemType Directory -Force -Path $directory
    }
    $temporaryPath = "$Path.tmp-$PID"
    [IO.File]::WriteAllText($temporaryPath, $Content, [Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Set-CodexMcpConfig {
    $configPath = Join-Path $env:USERPROFILE '.codex\config.toml'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        $content = [IO.File]::ReadAllText($configPath)
    }
    else {
        $content = ''
    }

    $sectionRegex = '(?ms)^\[mcp_servers\.zentao\][ \t]*(?:\r?\n|$).*?(?=^\[|\z)'
    $sectionMatches = [regex]::Matches($content, $sectionRegex)
    if ($sectionMatches.Count -gt 1) {
        throw 'Codex config has duplicate [mcp_servers.zentao] sections; resolve them manually before setup.'
    }

    $helper = Get-HelperCommand
    if ($sectionMatches.Count -eq 1) {
        $section = $sectionMatches[0].Value
        $urlMatches = [regex]::Matches($section, '(?m)^url\s*=\s*"([^"]*)"\s*$')
        if ($urlMatches.Count -gt 1) {
            throw 'Codex ZenTao entry has duplicate url keys; resolve them manually before setup.'
        }
        if ($urlMatches.Count -eq 1 -and $urlMatches[0].Groups[1].Value -ne $serverUrl) {
            throw "Existing Codex server '$serverName' uses a different URL; no config was changed."
        }
        if ($urlMatches.Count -eq 0) {
            $section = $section.TrimEnd("`r", "`n") + "`r`nurl = `"$serverUrl`"`r`n"
        }

        $section = [regex]::Replace($section, '(?m)^(?:env_http_headers|http_headers|bearer_token_env_var|bearer_token|oauth|http_headers_helper)\s*=.*(?:\r?\n|$)', '')
        $helperLine = "http_headers_helper = $(ConvertTo-Json -InputObject $helper -Compress)"
        $section = $section.TrimEnd("`r", "`n") + "`r`n$helperLine`r`n"
        $content = $content.Substring(0, $sectionMatches[0].Index) + $section + $content.Substring($sectionMatches[0].Index + $sectionMatches[0].Length)
    }
    else {
        if (-not [string]::IsNullOrWhiteSpace($content) -and -not $content.EndsWith("`n")) { $content += "`r`n" }
        $content += "`r`n[mcp_servers.zentao]`r`nurl = `"$serverUrl`"`r`nhttp_headers_helper = $(ConvertTo-Json -InputObject $helper -Compress)`r`n"
    }

    Backup-ConfigFile $configPath
    Write-ConfigFile $configPath $content
    Write-Host "Configured Codex ZenTao MCP in $configPath"
}

function Set-ClaudeMcpConfig {
    $configPath = Join-Path $env:USERPROFILE '.claude.json'
    if (Test-Path -LiteralPath $configPath -PathType Leaf) {
        try { $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json }
        catch { throw "Claude config is not valid JSON; no config was changed: $configPath" }
    }
    else {
        $config = [pscustomobject]@{}
    }

    if (-not $config.PSObject.Properties['mcpServers']) {
        $config | Add-Member -MemberType NoteProperty -Name mcpServers -Value ([pscustomobject]@{})
    }
    if ($null -eq $config.mcpServers) { $config.mcpServers = [pscustomobject]@{} }
    $existing = $config.mcpServers.PSObject.Properties[$serverName]
    if ($existing -and $existing.Value.url -and $existing.Value.url -ne $serverUrl) {
        throw "Existing Claude Code server '$serverName' uses a different URL; no config was changed."
    }

    if ($existing) {
        $entry = $existing.Value
        foreach ($authProperty in @('headers', 'headersHelper', 'oauth')) {
            if ($entry.PSObject.Properties[$authProperty]) { $entry.PSObject.Properties.Remove($authProperty) }
        }
        if (-not $entry.PSObject.Properties['type']) { $entry | Add-Member -MemberType NoteProperty -Name type -Value 'http' }
        if (-not $entry.PSObject.Properties['url']) { $entry | Add-Member -MemberType NoteProperty -Name url -Value $serverUrl }
        $entry.type = 'http'
        $entry.url = $serverUrl
        $entry | Add-Member -MemberType NoteProperty -Name headersHelper -Value (Get-HelperCommand) -Force
    }
    else {
        $entry = [pscustomobject][ordered]@{
            type = 'http'
            url = $serverUrl
            headersHelper = Get-HelperCommand
        }
        $config.mcpServers | Add-Member -MemberType NoteProperty -Name $serverName -Value $entry
    }

    Backup-ConfigFile $configPath
    $json = ConvertTo-Json -InputObject $config -Depth 100
    Write-ConfigFile $configPath ($json + "`r`n")
    Write-Host "Configured Claude Code ZenTao MCP in $configPath"
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $IsWindows -and $PSVersionTable.PSEdition -eq 'Core') {
        throw 'ZenTao credential protection and this setup flow require Windows.'
    }

    Write-Host 'Select the client(s) to configure:'
    Write-Host '  1. Codex'
    Write-Host '  2. Claude Code'
    Write-Host '  3. Both'
    $choice = Read-Host 'Choice (1-3)'
    if ($choice -notin @('1', '2', '3')) { throw 'Select 1, 2, or 3.' }

    & (Join-Path $PSScriptRoot 'save-credentials.ps1')
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw 'Credential setup failed.' }

    if ($choice -in @('1', '3')) { Set-CodexMcpConfig }
    if ($choice -in @('2', '3')) { Set-ClaudeMcpConfig }

    Write-Host 'Setup complete. Restart the selected MCP client to reload its ZenTao server configuration.'
}
