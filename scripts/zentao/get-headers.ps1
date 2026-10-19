$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Keep this endpoint fixed so stored credentials cannot be redirected to a caller-selected host.
$loginUri = 'https://pms.daoyoudao.com/zentao/api.php/v2/users/login'
$credentialPath = Join-Path $env:LOCALAPPDATA 'McpTokenRenewal\zentao\credentials.json'

try {
    if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) {
        throw 'credential file missing'
    }

    $credential = Get-Content -LiteralPath $credentialPath -Raw | ConvertFrom-Json
    if ([string]::IsNullOrWhiteSpace([string]$credential.account) -or
        [string]::IsNullOrWhiteSpace([string]$credential.password_protected)) {
        throw 'credential file invalid'
    }

    $securePassword = ConvertTo-SecureString ([string]$credential.password_protected)
    $passwordPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    try {
        $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordPointer)
        $body = @{ account = [string]$credential.account; password = $plainPassword } |
            ConvertTo-Json -Compress

        Add-Type -AssemblyName System.Net.Http
        $handler = [System.Net.Http.HttpClientHandler]::new()
        $handler.AllowAutoRedirect = $false
        $client = [System.Net.Http.HttpClient]::new($handler)
        # Claude Code's headersHelper has a 10-second total timeout; leave room for PowerShell startup.
        $client.Timeout = [TimeSpan]::FromSeconds(7)
        $content = [System.Net.Http.StringContent]::new($body, [Text.Encoding]::UTF8, 'application/json')
        $httpResponse = $client.PostAsync($loginUri, $content).GetAwaiter().GetResult()
        if (-not $httpResponse.IsSuccessStatusCode) {
            throw 'login request rejected'
        }
        $responseJson = $httpResponse.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $response = $responseJson | ConvertFrom-Json
    }
    finally {
        if ($passwordPointer -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordPointer)
        }
        $plainPassword = $null
        $body = $null
        $securePassword = $null
        if ($content) { $content.Dispose() }
        if ($httpResponse) { $httpResponse.Dispose() }
        if ($client) { $client.Dispose() }
        if ($handler) { $handler.Dispose() }
        $responseJson = $null
    }

    if ($response.status -ne 'success' -or [string]::IsNullOrWhiteSpace([string]$response.token)) {
        throw 'login rejected'
    }

    [Console]::Out.WriteLine((ConvertTo-Json -InputObject ([ordered]@{ token = [string]$response.token }) -Compress))
    exit 0
}
catch {
    [Console]::Error.WriteLine('ZenTao token helper failed. Check local credentials, API V2 login availability, and network access; response details were suppressed.')
    exit 1
}
