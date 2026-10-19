# MCP Token Renewal

为 MCP 宿主配置动态身份验证。当前包含 ZenTao API V2 的 Windows 重新登录示例，适用于 Codex 和 Claude Code。

## 快速开始

### 环境要求

- Node.js、npm 和 Git，用于运行 Skills 安装器并获取仓库。
- Codex 或 Claude Code。
- ZenTao 自动重新登录示例需要 Windows PowerShell。

### 1. 安装 Skill

```sh
npx skills add chrisstarr7/mcp-token-renewal --skill mcp-token-renewal -g -a codex -a claude-code
```

这条命令使用公开仓库，只安装 `mcp-token-renewal` 这个 Skill，并将其安装到当前用户的 Codex 和 Claude Code。安装器可能询问使用符号链接还是复制；Windows 无法创建符号链接时选复制。

### 2. 配置 ZenTao 登录

在 PowerShell 中运行配置脚本。Codex 默认安装路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

Claude Code 默认安装路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.claude\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

如果安装在其他目录，把命令中的路径替换为实际位置。脚本会让你选择 Codex、Claude Code 或两者，然后在本机提示输入禅道登录名和隐藏密码。密码使用当前 Windows 用户的 DPAPI 加密保存；脚本会备份客户端配置，并只更新 `zentao` MCP 项。

### 3. 重启并检查

重启已配置的客户端。Codex 可运行 `codex mcp list` 确认 MCP 服务已加载，再用只读查询确认工具可用。Claude Code 可在新会话中查看禅道 MCP 工具。

## 自动重新登录如何工作

1. 客户端连接禅道时运行本地 `get-headers.ps1`。脚本使用本机保存的账号密码调用固定的 HTTPS ZenTao API V2 登录地址，并将 `token` Header JSON 返回给客户端。
2. 如果公司 MCP 网关对过期凭据返回客户端支持的 HTTP 401/403，客户端会再次运行 Header Helper 并按其规则重试一次。

这里执行的是重新登录，不是 refresh-token 流程。Codex 仅在新 Header 与旧 Header 不同时重试。若网关用 HTTP 200 返回应用层错误，客户端可能不会触发重试。公司网关的过期场景尚未端到端验证。

## 客户端支持范围

客户端 | 作为 MCP 宿主 | ZenTao 自动重新登录
--- | --- | ---
Codex | 是 | 支持 `http_headers_helper`；受 401/403 和 Header 变化条件限制。
Claude Code | 是 | 支持 `headersHelper`；受其 HTTP 401/403 重试规则限制。
OpenCode | 是 | 当前无适用于此 ZenTao 登录流程的命令型 Header Helper。
DeepSeek API | 否，是模型提供方 | 需通过 Codex、Claude Code 等 MCP 宿主使用；自身不会调用 Helper。

Claude Desktop 和 Claude 网页连接器不同于 Claude Code，不支持本仓库使用的本地命令型 Helper。

## 更新与卸载

更新 Skill：

```sh
npx skills update mcp-token-renewal -g
```

更新禅道密码：重新运行安装目录下的 `scripts/zentao/save-credentials.ps1`，在本机重新输入账号密码。

卸载 Skill：

```sh
npx skills remove mcp-token-renewal -g -a codex -a claude-code
```

卸载 Skill 不会移除 MCP 配置或本机凭据。要停止自动登录，请恢复配置备份，并按需删除 `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`。

## 故障排查

- **安装时提示连接 `github.com:443` 超时：** 当前网络无法通过 HTTPS 连接 GitHub。若本机已配置 GitHub SSH Key，可改用 SSH 源：

  ```sh
  npx skills add git@github.com:chrisstarr7/mcp-token-renewal.git --skill mcp-token-renewal -g -a codex -a claude-code
  ```

- **配置脚本提示 ZenTao URL 不匹配：** 脚本不会覆盖指向其他地址的 `zentao` 项。先检查 Codex 或 Claude Code 当前配置里的 MCP URL。
- **登录失败：** 检查账号密码，并向管理员确认 ZenTao API V2 登录是否允许，以及是否要求验证码或 MFA。
- **密码已更改：** 重新运行 `save-credentials.ps1` 更新本机保存的密码。

## 安全说明

- 不要在聊天、README 或客户端配置中输入或保存明文密码、Token。
- Helper 只向脚本内固定的 HTTPS ZenTao 登录地址发送凭据，不把 Token 写入日志。
- 不要通过强制过期或生产写操作测试续期。

更多客户端细节见 [`references/client-compatibility.md`](references/client-compatibility.md)。官方参考：[Skills CLI](https://github.com/vercel-labs/skills)、[Codex MCP](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)、[Claude Code MCP](https://code.claude.com/docs/en/mcp#authenticating-with-remote-mcp-servers)、[ZenTao API V2 登录](https://www.zentao.net/book/api/post-users-login-2142.html)。
