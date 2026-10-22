import assert from 'node:assert/strict';
import test from 'node:test';
import { shellQuote, updateClaudeConfig, updateCodexConfig } from '../scripts/zentao/macos.mjs';

const serverUrl = 'https://pms.daoyoudao.com/zentao/mcp';
const helper = "'/usr/local/bin/node' '/Users/test/.agents/skills/mcp-token-renewal/scripts/zentao/macos.mjs' headers";

test('Codex setup appends one user-level MCP server without changing other tables', () => {
  const result = updateCodexConfig('[projects]\n"/tmp" = { trust_level = "trusted" }\n', helper);
  assert.match(result, /\[projects\]/);
  assert.match(result, /\[mcp_servers\.zentao\]/);
  assert.match(result, new RegExp(`url = "${serverUrl.replaceAll('.', '\\.')}"`));
  assert.match(result, /http_headers_helper = /);
});

test('Codex setup replaces auth settings in the matching server section only', () => {
  const source = `[mcp_servers.zentao]\nurl = "${serverUrl}"\nhttp_headers = { token = "stale" }\n\n[mcp_servers.other]\nurl = "https://example.com/mcp"\n`;
  const result = updateCodexConfig(source, helper);
  assert.doesNotMatch(result, /http_headers =/);
  assert.match(result, /http_headers_helper =/);
  assert.match(result, /\[mcp_servers\.other\]\nurl = "https:\/\/example.com\/mcp"/);
});

test('Codex setup refuses duplicate, unsupported, and conflicting entries', () => {
  assert.throws(() => updateCodexConfig(`[mcp_servers.zentao]\nurl = "${serverUrl}"\n[mcp_servers.zentao]\n`, helper), /duplicate/);
  assert.throws(() => updateCodexConfig(`[[mcp_servers.zentao]]\nurl = "${serverUrl}"\n`, helper), /array table/);
  assert.throws(() => updateCodexConfig('[mcp_servers.zentao]\nurl = "https://other.example/mcp"\n', helper), /different URL/);
});

test('Claude setup preserves unrelated servers and removes conflicting auth fields', () => {
  const source = JSON.stringify({ mcpServers: {
    other: { type: 'http', url: 'https://example.com/mcp' },
    zentao: { type: 'http', url: serverUrl, headers: { token: 'stale' }, oauth: {} },
  } });
  const result = JSON.parse(updateClaudeConfig(source, helper));
  assert.deepEqual(result.mcpServers.other, { type: 'http', url: 'https://example.com/mcp' });
  assert.equal(result.mcpServers.zentao.headersHelper, helper);
  assert.equal('headers' in result.mcpServers.zentao, false);
  assert.equal('oauth' in result.mcpServers.zentao, false);
});

test('Claude setup refuses a conflicting ZenTao URL and malformed JSON', () => {
  assert.throws(() => updateClaudeConfig('{"mcpServers":{"zentao":{"url":"https://other.example/mcp"}}}', helper), /different URL/);
  assert.throws(() => updateClaudeConfig('{', helper), /not valid JSON/);
});

test('shell quoting preserves apostrophes in executable and script paths', () => {
  assert.equal(shellQuote("/Users/D'Angelo/node"), "'/Users/D'\\''Angelo/node'");
});
