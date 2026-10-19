# MCP Token Renewal

跨客户端 MCP 身份认证续期指南，并提供 ZenTao API V2 的 Windows 配置示例。Skill 会根据 MCP 客户端和服务端的认证能力，指导选择 OAuth、客户端原生 Header Helper 或其他合适方案。

## 功能

- 指导为支持动态 Header Helper 的 MCP 客户端配置认证续期。
- 提供 Codex 和 Claude Code 的 ZenTao API V2 登录示例。
- 使用本机 Windows DPAPI 保护保存的登录密码，不把密码写入 MCP 配置。

## 支持范围

| 客户端或服务 | 支持情况 |
| --- | --- |
| Codex（Windows） | 支持 ZenTao Header Helper 配置 |
| Claude Code（Windows） | 支持 ZenTao Header Helper 配置 |
| OpenCode | 当前配置示例不支持命令型 Header Helper |
| DeepSeek API | 模型服务，不是 MCP 客户端；需通过支持 MCP 的客户端连接服务 |

ZenTao 示例使用固定的公司服务地址，不能直接用于其他 ZenTao 实例。其他 MCP 服务请先确认其认证方式、客户端重试行为和令牌签发规则，再按 Skill 指引配置。

## 环境要求

- Windows
- Node.js、npm 和 Git
- Codex 或 Claude Code
- ZenTao 账号，并且该实例允许使用 API V2 登录

## 安装

```powershell
npx skills add chrisstarr7/mcp-token-renewal -g -a codex claude-code -y
```

此命令将 Skill 安装到当前 Windows 用户的 Codex 和 Claude Code。安装后重启客户端或开启新会话。

## 配置 ZenTao

在 PowerShell 运行配置脚本：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

脚本会让你选择 Codex、Claude Code 或两者，检查客户端配置后，在本机提示输入禅道账号，并通过隐藏提示输入密码。密码使用当前 Windows 用户的 DPAPI 加密保存。写入前会备份已有配置；遇到不支持的配置格式或已有不同的 `zentao` 地址时会停止。

配置完成后重启所选客户端。不要在聊天中输入或发送账号密码。

## 验证

- Codex：运行 `codex mcp list`，确认 `zentao` 已加载；再执行只读查询确认工具可用。
- Claude Code：运行 `claude mcp list` 检查 MCP 配置，并在新会话中确认禅道工具可用。

验证时使用只读查询，不要通过生产写操作或手动让令牌过期来测试。

## 续期行为与限制

ZenTao API V2 登录接口会重新登录并签发 API Token；这属于重新登录，不是 refresh-token 流程。客户端会按照各自的规则调用本地 Header Helper。自动续期取决于服务端返回的 HTTP 状态码和客户端重试规则；Header Helper 不会在后台定时刷新令牌。

## 安全说明

ZenTao 示例将账号密码发送到固定的 HTTPS 登录地址：`https://pms.daoyoudao.com/zentao/api.php/v2/users/login`。使用前请确认这是你信任的禅道实例。脚本禁止自动跟随重定向，不会把密码或令牌写入仓库或 MCP 配置。

## 常见问题

- **配置脚本提示地址冲突：** 检查客户端现有的 `zentao` MCP 配置。脚本不会覆盖指向其他地址的条目。
- **登录失败：** 确认账号密码正确，并向禅道管理员确认 API V2 登录是否可用，以及账号是否需要验证码或多因素认证。
- **工具未加载：** 重启客户端，检查 MCP 配置中的服务地址，并确认客户端版本支持对应的 Header Helper。

## 更新与卸载

修改禅道密码后，再次运行配置脚本并输入新密码。

更新 Skill：

```powershell
npx skills update mcp-token-renewal -g
```

卸载 Skill：

```powershell
npx skills remove mcp-token-renewal -g -y
```

卸载不会删除客户端中的 MCP 配置或本机凭据。停止使用时，恢复配置备份，并按需删除 `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`。

更多客户端认证细节见 [`references/client-compatibility.md`](references/client-compatibility.md)。
