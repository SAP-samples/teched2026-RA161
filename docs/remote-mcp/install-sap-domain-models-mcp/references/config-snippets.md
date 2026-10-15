# SAP Domain Models MCP editor configuration

Use these templates after `SKILL.md` has resolved the helper shipped in this
onboarding repository. All examples use the binding-derived environment with
stable absolute paths.

## Table of contents

- [Required values](#required-values)
- [Temperature](#temperature)
- [Claude Code](#claude-code)
  - [macOS and Linux](#macos-and-linux)
  - [Windows](#windows)
  - [Windows direct-edit recovery](#windows-direct-edit-recovery)
    - [Claude Code VS Code extension or user scope](#claude-code-vs-code-extension-or-user-scope)
    - [Local scope](#local-scope)
  - [Repair `Cannot POST /register`](#repair-cannot-post-register)
- [Codex](#codex)
- [Cursor](#cursor)
- [Cline](#cline)
- [VS Code native MCP and GitHub Copilot](#vs-code-native-mcp-and-github-copilot)
- [Validate the saved entry](#validate-the-saved-entry)

## Required values

Use the canonical
[binding-to-environment table](./setup-and-troubleshooting.md#binding-based-environment-detection).
In the normal flow, the wizard selects that row from the SAP Domain Models
binding; manual row selection is only a fallback when the wizard cannot run.
Resolve all six values before writing configuration:

| Value         | Requirement                                                                                   |
| ------------- | --------------------------------------------------------------------------------------------- |
| `MCP_NAME`    | Binding-derived name printed by the wizard, such as `prod_usea_sap_domain_models_mcp`         |
| `ENDPOINT`    | Binding-derived endpoint printed by the wizard                                                |
| `CREDS_FILE`  | Literal absolute path from the wizard's `Wrote` or `Replaced` line                            |
| `NODE_BIN`    | Validated absolute Node.js executable                                                         |
| `HELPER_PATH` | Absolute onboarding repository `helper.cjs` path supplied by `SKILL.md`                       |
| `SERVER_PATH` | Stdio-only path beginning with the directory containing `NODE_BIN`, so the helper finds `npx` |

Never save a generic `sap-domain-models-mcp` server name. The endpoint, server
name, and credentials file must come from the wizard's same detected row so
prod DEWC and prod USEA can coexist.

For a file-based editor, parse and inspect its existing configuration, create a
timestamped backup, and merge only the selected environment's server entry.
Parse the result again before reconnecting. Restore the backup if parsing fails
or unrelated servers or scopes changed; never replace the whole
file with one of the abbreviated examples below.

On macOS and Linux, the guided workflow assigns the uppercase shell variables
used below. On Windows, use `$mcpName`, `$endpoint`,
`$credsFile`, `$nodeBin`, `$helperPath`, and `$serverPath` with equivalent
values. Use forward-slash absolute paths in JSON. On Windows the agent's shell
may be a POSIX shell rather than PowerShell (Claude Code uses Git Bash), so
unless the shell is known to be PowerShell, run each PowerShell block through
`powershell -NoProfile -Command "..."` or save it and run it with
`powershell -NoProfile -ExecutionPolicy Bypass -File <path>`.

## Temperature

Keep the hosted default by leaving temperature unset. Do not ask a temperature
question unless the user already requested an override. For an override,
validate a value from `0` through `2` and set `SAP_DOMAIN_MODELS_TEMPERATURE` in
the helper process environment.

## Claude Code

Use direct HTTP with a dynamic `headersHelper`. Inspect the selected entry and
scope before changing it:

```sh
claude mcp get "$MCP_NAME"
```

Do not replace a URL-only entry with another URL-only entry. This service uses
noninteractive client credentials, so the saved entry must contain a working
`headersHelper`. Claude Code defaults new entries to local scope; use it without
asking a scope question. Add `--scope user` or `--scope project` immediately
after `add-json` when the user already requested that scope or when repairing an
existing entry in that scope. Omit `--scope` only for local scope.

### macOS and Linux

Generate the JSON so paths and optional temperature are shell-quoted safely:

```sh
CONFIG="$("$NODE_BIN" -e 'const [url,node,helper,creds,temp]=process.argv.slice(1); const sq=String.fromCharCode(39); const q=(value)=>sq+value.replaceAll(sq,sq+"\\"+sq+sq)+sq; const env=[`SAP_DOMAIN_MODELS_MCP_CREDS_FILE=${q(creds)}`]; if(temp) env.push(`SAP_DOMAIN_MODELS_TEMPERATURE=${q(temp)}`); console.log(JSON.stringify({type:"http",url,headersHelper:`${env.join(" ")} ${q(node)} ${q(helper)} headers`,alwaysLoad:true}))' "$ENDPOINT" "$NODE_BIN" "$HELPER_PATH" "$CREDS_FILE" "${TEMPERATURE:-}")"
claude mcp add-json "$MCP_NAME" "$CONFIG"
```

### Windows

Create one environment-specific `.cmd` wrapper. It contains paths, not secrets,
and avoids fragile nested command quoting:

```powershell
$headersWrapper = Join-Path (Split-Path -Parent $credsFile) "${mcpName}-headers.cmd"
if (Test-Path $headersWrapper) {
  Copy-Item $headersWrapper "$headersWrapper.bak-$(Get-Date -Format yyyyMMddHHmmss)"
}
$wrapperLines = @(
  "@echo off"
  ('set "SAP_DOMAIN_MODELS_MCP_CREDS_FILE={0}"' -f $credsFile)
)
if ($temperature) {
  $wrapperLines += ('set "SAP_DOMAIN_MODELS_TEMPERATURE={0}"' -f $temperature)
}
$wrapperLines += ('"{0}" "{1}" headers' -f $nodeBin, $helperPath)
$wrapperLines | Set-Content -Path $headersWrapper -Encoding ascii

$headersHelper = '"' + $headersWrapper.Replace("\", "/") + '"'
$config = @{
  type = "http"
  url = $endpoint
  headersHelper = $headersHelper
  alwaysLoad = $true
} | ConvertTo-Json -Compress
```

On Windows, `claude mcp add-json` reliably fails with
`Invalid configuration: Invalid input` when the payload contains a
`headersHelper` string. Do not iterate on it — go straight to the
[direct-edit recovery](#windows-direct-edit-recovery) below using the values
assembled above.

If a resolved path contains `%` or `!`, move the onboarding checkout or Node.js
to a simple path before saving a `cmd.exe` wrapper. Retain the `.cmd` extension.

### Windows direct-edit recovery

Write the entry by editing the configuration file directly, in the same scope
the user selected. Claude Code stores both user- and local-scope
MCP servers in `~/.claude.json`; it stores user-scope servers under the top-level
`mcpServers` key and local-scope servers under a project in `projects`.

Do not put an `mcpServers` key in `~/.claude/settings.json`. The Claude Code VS
Code extension shares general settings from that file, but MCP server
definitions there are ignored. Back up `~/.claude.json`, merge only the
selected entry, parse the result, and preserve every unrelated property.

#### Claude Code VS Code extension or user scope

For a server that must appear in the Claude Code VS Code extension across
projects (user scope), merge the entry into the top-level `mcpServers` object
in `~/.claude.json`:

```powershell
$configPath = Join-Path $HOME ".claude.json"
$backupPath = $null
if (Test-Path $configPath -PathType Leaf) {
  $backupPath = "$configPath.bak-$(Get-Date -Format yyyyMMddHHmmss)"
  Copy-Item $configPath $backupPath
}

$editUserScript = @'
const fs = require("node:fs");
const [filePath, name, url, headersHelper] = process.argv.slice(1);
const data = fs.existsSync(filePath)
  ? JSON.parse(fs.readFileSync(filePath, "utf8").replace(/^\uFEFF/, ""))
  : {};
data.mcpServers ||= {};
data.mcpServers[name] = { type: "http", url, headersHelper, alwaysLoad: true };
fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`);
console.log(`Saved user-scope MCP server ${name} with headersHelper ${headersHelper}`);
'@
& $nodeBin -e $editUserScript $configPath $mcpName $endpoint $headersHelper
& $nodeBin -e 'const fs=require("node:fs"); JSON.parse(fs.readFileSync(process.argv[1],"utf8")); console.log("Claude configuration JSON is valid")' $configPath
```

If `$backupPath` is set, compare the top-level `mcpServers` object and
surrounding content with the backup. If unrelated content changed, restore it
with `Copy-Item $backupPath $configPath -Force`. If the file did not exist,
confirm the new file contains only the expected `mcpServers` entry. A local- or
project-scope server with the same name takes precedence over this user-scope
entry; inspect `claude mcp get $mcpName` before changing a duplicate.

#### Local scope

Use this recovery for the default local-scope entry stored under `projects` in
`~/.claude.json`. List the existing project keys and set `$projectKey` to the
exact selected key:

```powershell
$configPath = Join-Path $HOME ".claude.json"
$data = Get-Content $configPath -Raw | ConvertFrom-Json
$data.projects.PSObject.Properties.Name
```

Back up the file, then edit only the selected project and environment:

```powershell
$backupPath = "$configPath.bak-$(Get-Date -Format yyyyMMddHHmmss)"
Copy-Item $configPath $backupPath

$editScript = @'
const fs = require("node:fs");
const [filePath, projectKey, name, url, headersHelper] = process.argv.slice(1);
const data = JSON.parse(fs.readFileSync(filePath, "utf8"));
const project = data.projects?.[projectKey];
if (!project) throw new Error(`Project not found in ${filePath}: ${projectKey}`);
project.mcpServers ||= {};
project.mcpServers[name] = { type: "http", url, headersHelper, alwaysLoad: true };
project.enabledMcpServers ||= [];
if (!project.enabledMcpServers.includes(name)) project.enabledMcpServers.push(name);
fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`);
console.log(`Saved ${name} with headersHelper ${headersHelper}`);
'@
& $nodeBin -e $editScript $configPath $projectKey $mcpName $endpoint $headersHelper
& $nodeBin -e 'const fs=require("node:fs"); JSON.parse(fs.readFileSync(process.argv[1],"utf8")); console.log("Claude configuration JSON is valid")' $configPath
```

The `node -e` scripts take their first user argument at `process.argv[1]`. If
you save one to a file and run it as `node <file>`, every index shifts by one
(`argv[1]` becomes the script path) — adjust the destructuring or keep `-e`.

Compare the selected entry and surrounding projects with the backup. If any
unrelated content changed, restore it with
`Copy-Item $backupPath $configPath -Force`. Preserve every other project and
MCP server. Never recover by creating a URL-only entry.

### Repair `Cannot POST /register`

This error is not an S/4 or Ariba tool response:

```text
HTTP 404: Invalid OAuth error response ... Raw body: Cannot POST /register
```

It means Claude Code started OAuth Dynamic Client Registration against the MCP
host. The SAP Domain Models MCP uses IAS `client_credentials` and does not
expose `/register`. This does not show that `headersHelper` cannot refresh; it
shows that the effective connection did not have a usable helper-provided
`Authorization` header. Do not use **Authenticate**, `claude mcp login`, or
repeated credential-wizard runs to repair it.

Inspect `claude mcp get "$MCP_NAME"` and same-named entries in every configured
scope. Claude uses local scope before project scope and project scope before
user scope, so a URL-only higher-precedence entry can shadow a correct entry.
Also verify that the configured helper command exists, prints valid header JSON
in the safe check, and is trusted to run for a project- or local-scope entry.
Repair the effective entry with the dynamic `headersHelper` configuration above,
then start a fresh Claude Code session. If the safe credential check succeeds,
do not replace the credentials file merely because `/register` returned 404.

## Codex

Codex does not run Claude Code's dynamic `headersHelper`. Save the absolute
Node/helper command as a stdio MCP server:

```sh
codex mcp get "$MCP_NAME"
codex mcp add \
  --env PATH="$SERVER_PATH" \
  --env SAP_DOMAIN_MODELS_MCP_CREDS_FILE="$CREDS_FILE" \
  "$MCP_NAME" -- \
  "$NODE_BIN" "$HELPER_PATH" mcp-remote "$ENDPOINT"
```

For a requested temperature override, add
`--env SAP_DOMAIN_MODELS_TEMPERATURE="$TEMPERATURE"` before `"$MCP_NAME"`.
`codex mcp add` writes user-level configuration. Use an equivalent entry in a
trusted project's `.codex/config.toml` only when project scope is requested.

## Cursor

For any stdio JSON entry below, add
`"SAP_DOMAIN_MODELS_TEMPERATURE": "<value>"` to `env` only for a requested
override.

Substitute literal resolved values in `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "<mcp-name>": {
      "command": "<absolute-node>",
      "args": ["<absolute-helper.cjs>", "mcp-remote", "<endpoint>"],
      "env": {
        "PATH": "<server-path>",
        "SAP_DOMAIN_MODELS_MCP_CREDS_FILE": "<absolute-credentials-file>"
      }
    }
  }
}
```

## Cline

Substitute literal resolved values in `cline_mcp_settings.json`:

```json
{
  "mcpServers": {
    "<mcp-name>": {
      "command": "<absolute-node>",
      "args": ["<absolute-helper.cjs>", "mcp-remote", "<endpoint>"],
      "env": {
        "PATH": "<server-path>",
        "SAP_DOMAIN_MODELS_MCP_CREDS_FILE": "<absolute-credentials-file>"
      },
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

## VS Code native MCP and GitHub Copilot

Use VS Code with MCP support and Copilot agent mode. Substitute literal values
in the user `mcp.json`; note the `servers` key:

```json
{
  "servers": {
    "<mcp-name>": {
      "type": "stdio",
      "command": "<absolute-node>",
      "args": ["<absolute-helper.cjs>", "mcp-remote", "<endpoint>"],
      "env": {
        "PATH": "<server-path>",
        "SAP_DOMAIN_MODELS_MCP_CREDS_FILE": "<absolute-credentials-file>"
      }
    }
  }
}
```

On Windows, use the absolute `node.exe` and `helper.cjs` paths, a semicolon-
separated `PATH`, an absolute forward-slash credentials path, and the selected
environment's server name.

## Validate the saved entry

For Claude Code, first run `claude mcp get "$MCP_NAME"` and confirm the effective
entry is direct HTTP with the selected endpoint and a working `headersHelper`;
it must not be URL-only or contain a minted bearer token. Exit the current
process and start a fresh session before making a real read-only `s4` or `ariba`
call through the environment-specific server name. Never attempt that call in
the setup session or from a subagent spawned within it — a newly added server
is not visible to either, and the call returns "No such tool available" even
when the configuration is correct. Do not use **Authenticate** or
`claude mcp login` to repair a `/register` error. For other editors, reload or
reconnect the selected environment. A token mint, `tools/list`, `claude mcp
list`, `/mcp` panel, or server list is diagnostic but not end-to-end proof. For
example:

```text
Use the prod_dewc_sap_domain_models_mcp s4 tool: what is an ABAP CDS view?
```
