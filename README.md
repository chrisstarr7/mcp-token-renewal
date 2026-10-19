# MCP Token Renewal

为 Codex、Claude Code 等 MCP 宿主评估和配置可续期的身份验证。
ZenTao 示例使用账号密码重新登录，并通过客户端原生 Header Helper 在鉴权失败时刷新并重试。

`Codex` · `Claude Code` · `OpenCode` · `DeepSeek`

---

## 开始使用

安装到当前用户的 Codex 和 Claude Code：

```sh
npx skills add chrisstarr7/mcp-token-renewal --skill mcp-token-renewal -g -a codex -a claude-code
```

这是公开 GitHub 仓库，安装不需要仓库邀请。安装器会询问安装方式；Windows 如果不能创建符号链接，选择复制即可。

环境要求：Node.js/npm（运行 `npx skills`）、Codex 或 Claude Code。ZenTao 自动重新登录示例还需要 Windows PowerShell。

安装后，在 Codex 或 Claude Code 中说：

> 请用已安装的 mcp-token-renewal Skill 配置 ZenTao 自动重新登录。运行本地配置脚本，并让我在隐藏的终端提示中输入账号密码。不要在聊天中索取或显示密码。

也可以在 PowerShell 中直接运行配置脚本。Codex 默认用户级路径：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

Claude Code 默认用户级路径为 `$HOME\.claude\skills\mcp-token-renewal\scripts\zentao\configure.ps1`。如果 Skill 安装在其他位置，将命令中的路径替换为实际安装目录。脚本会让你选择 Codex、Claude Code 或两者，再在本机提示禅道登录名和隐藏密码。账号名保存在本机，密码使用当前 Windows 用户的 DPAPI 加密保存。

配置完成后重启所选客户端。Codex 可用 `codex mcp list` 检查 MCP 服务是否已加载，再执行只读查询检查工具是否可用。

## 支持范围

产品 | 角色 | 能力
--- | --- | ---
Codex | MCP 宿主 | 本地 HTTP MCP 支持 `http_headers_helper`，可在符合条件的鉴权失败后刷新 Header 并重试。
Claude Code | MCP 宿主 | 远程 HTTP MCP 支持 `headersHelper`，可在符合条件的鉴权失败后重新连接并重试。
OpenCode | MCP 宿主 | 可使用 MCP 与 OAuth；当前文档未提供 ZenTao 这种自定义账号密码登录的命令型 Header Helper。
DeepSeek API | 模型提供方 | 提供工具调用能力，本身不是 MCP 宿主；需由 Codex、Claude Code 等宿主连接 MCP。

Claude Desktop 和 Claude 网页连接器与 Claude Code 是不同产品，不支持本仓库脚本使用的本地 `headersHelper`。

## ZenTao 工作流程

1. 首次配置时，脚本备份已选客户端配置，只更新 `zentao` MCP 项，并让用户在本地隐藏提示中输入禅道凭据。
2. MCP 宿主连接禅道时调用本地 `get-headers.ps1`。脚本向固定的 HTTPS 禅道 API V2 登录接口提交凭据，并只把 `token` Header JSON 写到标准输出。
3. 遇到宿主支持的 HTTP 401/403 鉴权失败时，宿主再次运行 Helper 并按其规则重试一次。

禅道 API V2 这里执行的是重新登录，不是 refresh-token 授权流程。能否自动恢复还取决于公司 MCP 网关是否以客户端可识别的 HTTP 401/403 返回过期状态，以及禅道是否接受再次登录。Codex 仅在 Header 发生变化时重试。当前尚未在公司网关上端到端验证过期重试。

不支持通过 Skill 本身监听 MCP 请求或拦截错误。OpenCode 与 DeepSeek API 不会调用这里的 ZenTao Header Helper。

## 日常维护

操作 | 命令
--- | ---
升级 Skill | `npx skills update mcp-token-renewal -g`
查看全局 Skill | `npx skills list -g`
卸载 Skill | `npx skills remove mcp-token-renewal -g -a codex -a claude-code`
更新本地密码 | 重新运行安装目录中的 `scripts/zentao/save-credentials.ps1`

卸载 Skill 不会删除 MCP 配置备份或本机凭据。需要停止自动登录时，恢复客户端配置备份，并按需删除 `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`。

## 隐私与安全

- 不要把密码、Token 或凭据文件提交到 GitHub、发到聊天或写进客户端配置。
- 密码只发送到脚本内固定的 HTTPS 禅道登录地址；错误日志不会输出响应内容或 Token。
- 不要通过强制令牌过期或生产写操作验证续期。
- 账号密码登录可能受禅道验证码、MFA、登录频率或公司策略限制；遇到登录失败时，先由管理员确认 API V2 登录是否允许。

更详细的客户端兼容性和参考链接见 [`references/client-compatibility.md`](references/client-compatibility.md)。Skill 指令见 [`SKILL.md`](SKILL.md)。

## 参考文档

- [Agent Skills 安装 CLI](https://github.com/vercel-labs/skills)
- [Codex MCP 配置](https://learn.chatgpt.com/docs/extend/mcp?surface=cli)
- [Claude Code MCP 认证](https://code.claude.com/docs/en/mcp#authenticating-with-remote-mcp-servers)
- [OpenCode MCP 服务](https://opencode.ai/docs/mcp-servers)
- [禅道 API V2 登录](https://www.zentao.net/book/api/post-users-login-2142.html)
