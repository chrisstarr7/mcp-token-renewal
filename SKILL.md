---
name: zentao-token-renewal
description: Configure and troubleshoot ZenTao MCP authentication and renewable tokens for Codex, Claude Code, OpenCode, and other MCP hosts.
---

# ZenTao Token Renewal

Use this skill when a user wants to configure or troubleshoot MCP authentication renewal across agent applications or model providers.

## Choose the right layer

First identify both the **agent host** that connects to MCP and the **model provider** that generates tool calls. They are separate layers. A model provider that supports function calling does not automatically connect to MCP servers or refresh their credentials. Read [client compatibility](references/client-compatibility.md) when selecting an integration path.

Prefer, in order:

1. The MCP service's standard OAuth flow when the client supports it.
2. A client-native dynamic header/token helper when available, such as Codex `http_headers_helper` or Claude Code `headersHelper`.
3. A provider-specific local adapter only when the client has no native renewal path and the user wants that added complexity.

Do not describe renewal as working until the client's trigger, the service's error response, and the token issuer's renewal behavior match. Distinguish API-key substitution, re-login, OAuth refresh-token renewal, and an actual refresh endpoint.

## Security and scope

- Never put real passwords, API keys, access tokens, or refresh tokens in this Skill, source control, chat, shell history, or plaintext client configuration.
- Prefer the operating system credential vault or OS-bound encryption. Environment variables can be used when the client only supports them, but document their storage and process exposure.
- Send credentials only to the configured issuer over HTTPS. Validate host and redirects; do not accept an arbitrary login URL alongside a stored password.
- Keep diagnostics free of credentials and token values. If a client requires the renewed token as helper stdout, return only the exact required JSON and avoid capturing it in logs.
- Authentication calls may create sessions, rotate tokens, trigger rate limits, or lock an account. Establish issuer behavior and bound retries before enabling automation.
- Inspect current client/service configuration before edits. Change only the selected MCP entry, preserve unrelated configuration, and never test renewal by changing production data or forcing expiry on a production account.

## Workflow

1. Determine the client application, its version/scope (local or remote), MCP transport, service URL, header name, and credential issuer.
2. Check current official client documentation for OAuth, dynamic headers, environment interpolation, helper execution, and retry triggers. Do not assume features transfer between clients.
3. Check the service's official authentication documentation for the exact login or refresh endpoint, response shape, expiry behavior, and whether a new token differs from the previous one.
4. Select the least complex supported native mechanism. A Skill does not monitor MCP traffic or run when a tool fails. Where supported, the MCP host invokes a configured local header helper on connection and its documented authentication retry path.
5. For Windows Codex or Claude Code + the bundled ZenTao example, run `setup.ps1`; macOS uses `setup.mjs` and the built-in Keychain, with no PowerShell installation. Both paths validate selected client configs before requesting credentials, back up existing configs, update only the `zentao` MCP entry, and restore configs if setup fails. Windows stores the password with current-user DPAPI; macOS stores it in Keychain. Do not configure OpenCode with this helper; its documented remote MCP settings do not provide a command helper for this API-token flow.
6. Use the included ZenTao scripts only for the documented ZenTao API V2 login flow; they are not a generic credential adapter. Verify only authentication and tool discovery with read-only calls. Do not claim the expiry-retry path was verified unless tested in an isolated or disposable environment.
7. Report supported behavior, assumptions, checks performed, and any server-side condition still needing confirmation.

## ZenTao API V2 example

For the known company ZenTao service, Windows uses `setup.ps1` and macOS uses `setup.mjs`. Both let the user select Codex, Claude Code, or both; validate selected configs before credential entry; make timestamped backups; and refuse to replace an existing `zentao` entry pointing at another URL or unsupported Codex TOML shapes. Windows stores the password with DPAPI and runs `get-headers.ps1`; macOS stores it in Keychain and runs the native Node.js helper. If a config write or credential setup fails, setup attempts to restore the original client configs. The helper logs in to the fixed company API V2 endpoint and emits the `token` header JSON. These scripts do not configure OpenCode or make the DeepSeek API itself an MCP host.

ZenTao documents `POST /api.php/v2/users/login` for acquiring an API token, not a dedicated refresh-token grant. This is a fresh login (re-authentication), not refresh-token rotation. For expiry recovery, the company MCP gateway must surface HTTP 401/403 in the way the selected client documents, and ZenTao must allow another login with the stored account. Codex retries after refresh only when returned headers changed; Claude Code reconnects and retries once. The scripts cannot guarantee a retry if the gateway reports expiry as a successful HTTP response containing an application-level error, or if the newly issued header is identical and the client declines to retry.
