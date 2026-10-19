# MCP Token Renewal

为 Codex 和 Claude Code 配置 MCP 动态鉴权。本仓库提供 ZenTao API V2 的 Windows 重新登录示例。

## 安装

你遇到的 `github.com:443` 超时发生在 Git 克隆阶段，与 `--skill`、`-g` 等参数无关。对当前网络，直接用 SSH 源安装：

```powershell
npx skills add git@github.com:chrisstarr7/mcp-token-renewal.git -g -a codex claude-code -y
```

此仓库目前只有一个 Skill，因此不需要写 `--skill`。命令会把它安装到当前 Windows 用户的 Codex 和 Claude Code。SSH 方式要求本机已配置 GitHub SSH 访问；若 SSH 也无法连接，就需要先使用公司批准的网络/VPN/代理恢复 GitHub 访问，安装器参数无法绕过网络阻断。

## 配置禅道

安装不会自动执行脚本或读取密码。安装后，在 PowerShell 运行这一条命令：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

脚本会先让你选择 Codex、Claude Code 或两者，预检所选配置后再让你在本机隐藏提示中输入禅道账号密码。密码以当前 Windows 用户的 DPAPI 加密保存；配置文件写入前会备份，只更新 `zentao` MCP 项。如果遇到脚本无法安全识别的 Codex 配置格式或已有不同 URL，会停止并提示手动处理，不会追加重复项。配置后重启所选客户端。

可在新会话中让 `mcp-token-renewal` Skill 为你引导同一脚本流程；不要在聊天中发送密码。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$HOME\.agents\skills\mcp-token-renewal\scripts\zentao\configure.ps1"
```

## 验证与续期边界

Codex 运行 `codex mcp list` 确认服务已加载，再做只读查询确认工具可用；Claude Code 在新会话检查禅道 MCP 工具。

过期后，Helper 会用保存的账号密码重新登录 ZenTao API V2。只有 MCP 网关按客户端可识别的 HTTP 401/403 返回鉴权失败时，Codex 或 Claude Code 才可能调用 Helper 并重试。它不是 refresh-token 流程；公司网关的过期重试尚未端到端验证。不要用生产写操作或强制过期来测试。

## 更新与卸载

```powershell
npx skills update mcp-token-renewal -g
npx skills remove mcp-token-renewal -g -y
```

更新禅道密码：再次运行 `configure.ps1`，在本机隐藏提示中输入新密码。

卸载 Skill 不会删除 MCP 配置或本机凭据。若要停用自动登录，请恢复配置备份，并按需删除 `%LOCALAPPDATA%\McpTokenRenewal\zentao\credentials.json`。

## 安全与支持范围

不要把密码或 Token 发到聊天、提交到仓库或写进 MCP 配置。安装器的 Snyk 扫描将固定的 ZenTao 登录地址报告为 [W012 中风险](https://www.skills.sh/chrisstarr7/mcp-token-renewal/mcp-token-renewal/security/snyk)。脚本只向这个固定 HTTPS 地址发送登录信息并禁用自动跳转；输入密码前，请确认该域名确为你所属公司的禅道地址。此示例适用于 Windows Codex 和 Claude Code；OpenCode 没有本示例所需的命令型 Header Helper，DeepSeek API 是模型提供方而非 MCP 宿主。更多细节见 [`references/client-compatibility.md`](references/client-compatibility.md) 和 [Skills CLI 官方文档](https://github.com/vercel-labs/skills#readme)。
