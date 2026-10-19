# MCP Token Renewal

A reusable Agent Skill for assessing and configuring renewable authentication for remote MCP servers.

It helps distinguish authentication handled by the MCP host from tool calling handled by the model provider, checks the selected client's documented renewal behavior, and avoids claiming that a token refresh works until the server and issuer behavior match the client's retry mechanism.

## Supported clients and providers

| Product | Role | Relevant support |
|---|---|---|
| Codex | MCP host | Supports a local `http_headers_helper` for supported local HTTP MCP connections. |
| Claude Code | MCP host | Supports OAuth renewal and a custom `headersHelper` for remote HTTP MCP authentication. The helper must complete within Claude Code's documented timeout. |
| OpenCode | MCP host | Supports remote MCP headers and OAuth. Use native OAuth where the MCP server supports it. |
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

## ZenTao example scripts

The included PowerShell scripts are an optional, company-specific example for ZenTao API V2; they are not a generic token-renewal engine.

On Windows:

1. Run `scripts/zentao/save-credentials.ps1` interactively. It prompts for the ZenTao account and hidden password input.
2. The password is stored using Windows current-user DPAPI under `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`.
3. Configure the MCP host to run `scripts/zentao/get-headers.ps1` as its documented dynamic-header helper.
4. The helper sends credentials only to the fixed HTTPS ZenTao API V2 login endpoint and writes the `token` header JSON to stdout. It suppresses response details on errors.

The helper re-authenticates through ZenTao API V2 login; ZenTao's documented flow is not a dedicated refresh-token grant. The MCP gateway must return the status expected by the host before a host-level retry can occur. Verify this in a safe environment before relying on renewal. The script does not configure an MCP client automatically.

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
