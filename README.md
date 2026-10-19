# MCP Token Renewal

A reusable Agent Skill for assessing and configuring renewable authentication for remote MCP servers.

It helps distinguish authentication handled by the MCP host from tool calling handled by the model provider, checks the selected client's documented renewal behavior, and avoids claiming that a token refresh works until the server and issuer behavior match the client's retry mechanism.

## Supported clients and providers

| Product | Role | Relevant support |
|---|---|---|
| Codex | MCP host | Supports a local `http_headers_helper` for supported local HTTP MCP connections. |
| Claude Code | MCP host | Supports OAuth renewal and a custom `headersHelper` for remote HTTP MCP authentication. The helper must complete within Claude Code's documented timeout. |
| OpenCode | MCP host | Supports remote MCP headers and OAuth. Its documented configuration does not support a command helper for the ZenTao API-token login flow. |
| DeepSeek API | Model provider | Supports function/tool calls; it is not itself an MCP host. Use it through an MCP-capable application. |

Claude Desktop and Claude web connectors are separate from Claude Code. Their remote connector flow is configured through the Claude UI and does not expose Claude Code's local `headersHelper` mechanism.

See [`references/client-compatibility.md`](references/client-compatibility.md) for client-specific behavior and official documentation links.

## Installation

Install this repository as a Skill directory so the `SKILL.md` file is directly inside the installed directory.

Typical user-level locations:

- Codex and OpenCode: `~/.agents/skills/mcp-token-renewal`
- Claude Code: `~/.claude/skills/mcp-token-renewal`

For Codex or OpenCode, clone the repository directly into the Skill directory:

```sh
git clone https://github.com/chrisstarr7/mcp-token-renewal.git ~/.agents/skills/mcp-token-renewal
```

For Claude Code, use `~/.claude/skills/mcp-token-renewal` as the clone destination instead. The repository must be accessible to the GitHub account used for cloning.

To share one checkout between these clients, install it under `~/.agents/skills/mcp-token-renewal` and create a symlink at `~/.claude/skills/mcp-token-renewal` pointing to that folder. Restart or reload the client if it does not discover the Skill immediately.

## ZenTao automatic re-login setup (Windows)

The included PowerShell scripts are an optional, company-specific example for ZenTao API V2; they are not a generic token-renewal engine.

After installing the Skill, run its setup script once in PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

If installed somewhere else, replace the path with that checkout's `scripts\zentao\configure.ps1`. The script asks whether to configure Codex, Claude Code, or both, then prompts for the ZenTao account and hidden password. It:

1. Stores the password using current-user Windows DPAPI under `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`.
2. Backs up each selected client config with a timestamp.
3. Adds or updates only the `zentao` MCP entry to call the local `get-headers.ps1` script, preserving the other client settings. It stops if the existing `zentao` entry points to another URL.

Restart the selected client after setup. The client calls the helper when connecting and, for documented HTTP 401/403 cases, can refresh headers and retry once. The helper sends credentials only to the fixed HTTPS ZenTao API V2 login endpoint and prints only the `token` header JSON to stdout. On errors it suppresses response details.

This is automatic **re-login**, not a ZenTao refresh-token grant. It works after an expired token only if the MCP gateway returns HTTP 401/403 in the form the client expects, ZenTao accepts another login, and the helper returns headers that cause the client to retry. This end-to-end expiry path has not been verified against the company gateway. Do not force expiry or use write operations to test it. OpenCode and DeepSeek API do not invoke this helper; DeepSeek is a model provider, not the MCP host.

## Security

- Never commit account passwords, API tokens, OAuth credentials, or generated credential files.
- Keep credentials in an OS credential store or OS-protected local storage; do not put secrets in `SKILL.md`, README files, source control, shell history, or plaintext client configuration.
- Use the helper only with the fixed HTTPS issuer endpoint in the script. Do not accept an arbitrary login URL alongside stored credentials.
- Do not test renewal by forcing token expiry or by performing write operations against production data.
- Review the client-specific timeout and retry behavior before enabling a helper. A Skill provides instructions; it does not run in the background or intercept MCP traffic by itself.

## Repository contents

```text
.gitignore
SKILL.md
README.md
references/
  client-compatibility.md
scripts/
  zentao/
    configure.ps1
    get-headers.ps1
    save-credentials.ps1
```

## References

- [Codex MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)
- [Codex Skills](https://learn.chatgpt.com/docs/build-skills)
- [Claude Code MCP authentication](https://code.claude.com/docs/en/mcp#authenticating-with-remote-mcp-servers)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Desktop remote MCP connectors](https://support.anthropic.com/en/articles/11503834-building-custom-connectors-via-remote-mcp-servers)
- [OpenCode MCP servers](https://opencode.ai/docs/mcp-servers)
- [DeepSeek tool calls](https://api-docs.deepseek.com/guides/tool_calls)
- [ZenTao API V2 login](https://www.zentao.net/book/api/post-users-login-2142.html)
