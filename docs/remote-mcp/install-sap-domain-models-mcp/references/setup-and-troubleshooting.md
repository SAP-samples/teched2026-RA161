# SAP Domain Models MCP setup and troubleshooting

This reference defines the binding-derived guided workflow for the
`install-sap-domain-models-mcp` skill in this onboarding repository. Helper
resolution belongs in `SKILL.md`; editor command examples belong in
[`config-snippets.md`](./config-snippets.md).

## Table of contents

- [Binding-based environment detection](#binding-based-environment-detection)
- [Prerequisites](#prerequisites)
- [Guided workflow](#guided-workflow)
- [Validate authentication safely](#validate-authentication-safely)
- [Configure credentials privately](#configure-credentials-privately)
- [Editor behavior](#editor-behavior)
- [Temperature](#temperature)
- [Token refresh](#token-refresh)
- [Troubleshooting](#troubleshooting)

## Binding-based environment detection

Do not ask the user to choose an environment. Ask them to open the matching
service instances in the SAP BTP cockpit and download the credentials for these
two service bindings (or service keys) from the same subaccount:

1. The SAP Domain Models service binding, whose `url` identifies the SAP
   Domain Models service cluster.
2. A `SECRET` IAS service binding, which contains `url`, `clientid`, and
   `clientsecret`.

The downloaded file may contain the credential fields at the top level or under
a top-level `credentials` object. The workshop files are named
`sap-domain-models-prod-usea.json` and `ias-prod-usea.json` and ship in the workshop
repository's `credentials/` directory; `ias-prod-usea.json` is produced there by
running `node scripts/decrypt-credentials.cjs` with the passphrase announced
at the session. If it is missing, have the user run that script first. A
Prod DEWC backup pair, `sap-domain-models-prod-dewc.json` and `ias-prod-dewc.json`
(decrypted with `--fallback`), is used only when facilitators announce it. The
user provides only the two local file paths to the private wizard. Never ask them to paste either JSON document or any
binding value into chat, and never read either binding with agent file tools.
The wizard maps the SAP Domain Models binding's exact service origin to the MCP
configuration below:

| Detected environment | SAP Domain Models binding `url`                  | MCP endpoint                                                  | Credentials file                                            | MCP server name                   |
| -------------------- | ------------------------------------------------ | ------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------- |
| Prod DEWC            | `https://nova-service-prod-dewc.appai.cloud.sap` | `https://sap-domain-models-mcp-prod-dewc.appai.cloud.sap/mcp` | `~/.config/sap-domain-models/mcp-prod-dewc-credentials.env` | `prod_dewc_sap_domain_models_mcp` |
| Prod USEA            | `https://nova-service-prod-usea.appai.cloud.sap` | `https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp` | `~/.config/sap-domain-models/mcp-prod-usea-credentials.env` | `prod_usea_sap_domain_models_mcp` |

Reject an unrecognized service origin instead of deriving a hostname. The IAS
binding must belong to the consumer application configured for the downloaded
SAP Domain Models service binding; a successful token mint alone cannot prove
that audience relationship.

The environments are designed to coexist. Configure only the detected row and
never overwrite another environment's server entry or credentials file. Use all
four wizard output lines: `Detected environment`, `MCP endpoint`, `MCP server
name`, and `Wrote` (or `Replaced`). Assign `ENDPOINT`, `MCP_NAME`, and the
literal absolute `CREDS_FILE` from the same output. Do not infer a cluster from
a user's location or leave `~` or `$HOME` in saved JSON.

## Prerequisites

Require Node.js 20.20.0 or newer. Resolve it before changing editor
configuration. Do not install or change Node.js without permission.

On macOS or Linux, resolve an absolute executable and validate its version. If
the active shell's Node.js is missing or too old, select an already-installed,
compatible nvm Node.js without downloading or changing the shell default:

```sh
node_is_supported() {
  [ -x "$1" ] && "$1" -e 'const [major,minor]=process.versions.node.split(".").map(Number); process.exit(major>20 || (major===20 && minor>=20) ? 0 : 1)' >/dev/null 2>&1
}

NODE_BIN="$(command -v node 2>/dev/null || true)"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ "${NODE_BIN#/}" = "$NODE_BIN" ] || ! node_is_supported "$NODE_BIN"; then
  NODE_BIN=""
  for candidate in "$NVM_DIR"/versions/node/*/bin/node; do
    if node_is_supported "$candidate"; then
      NODE_BIN="$candidate"
    fi
  done
fi
case "$NODE_BIN" in
  /*) ;;
  *) echo "An installed Node.js 20.20.0 or newer was not found" >&2; exit 1 ;;
esac
"$NODE_BIN" --version
NODE_BIN_DIR="$(dirname "$NODE_BIN")"
SERVER_PATH="$NODE_BIN_DIR:/usr/local/bin:/usr/bin:/bin"
```

On Windows, the agent's shell is Git Bash, not PowerShell, so a PowerShell
block pasted directly fails with `command not found`. Run every PowerShell
block in this skill through `powershell -NoProfile -Command "..."`, or save it
to a file and run
`powershell -NoProfile -ExecutionPolicy Bypass -File <path>`.

On Windows PowerShell, prefer the active executable when it is compatible. If
it is too old, search an existing nvm-windows installation before stopping:

```powershell
function Test-SupportedNode([string] $candidate) {
  if (-not $candidate -or -not (Test-Path $candidate -PathType Leaf)) { return $false }
  & $candidate -e 'const [major,minor]=process.versions.node.split(".").map(Number); process.exit(major>20 || (major===20 && minor>=20) ? 0 : 1)' 2>$null
  return $LASTEXITCODE -eq 0
}

$nodeBin = (Get-Command node -CommandType Application -ErrorAction SilentlyContinue).Source
if (-not (Test-SupportedNode $nodeBin)) {
  $nvmRoot = if ($env:NVM_HOME) { $env:NVM_HOME } else { Join-Path $env:APPDATA "nvm" }
  $nodeCandidates = if (Test-Path $nvmRoot) {
    Get-ChildItem $nvmRoot -Filter node.exe -File -Recurse -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName
  } else { @() }
  $nodeBin = $nodeCandidates | Where-Object { Test-SupportedNode $_ } | Select-Object -Last 1
}
if (-not $nodeBin) { throw "An installed Node.js 20.20.0 or newer was not found" }
& $nodeBin --version
$nodeBinDir = Split-Path -Parent $nodeBin
$serverPath = "$nodeBinDir;$env:PATH"
```

Use the resolved executable and server `PATH` in saved stdio configuration.
The helper launches `npx` internally, so an absolute Node.js command alone may
still fail when a GUI client starts with a clean `PATH`.

- Never ask the user to paste a service binding, client secret, bearer token, or
  credentials-file contents into chat.
- Existing working `prod_sap_domain_models_mcp` configurations remain
  compatible. Do not rewrite one unless the user asks to migrate or their SAP
  Domain Models binding identifies another cluster. For a migration, create the
  binding-derived entry beside it, validate a real read-only call, and only then
  offer to remove the old entry.
  The legacy `prod_sap_domain_models_mcp` name maps specifically to
  `prod_dewc_sap_domain_models_mcp`.
- Stdio clients run a local refreshing proxy and may need public registry
  access on first use or after a cache miss.

## Guided workflow

1. Identify the requested editor and inspect an existing entry before changing
   it. Preserve unrelated MCP servers and scopes. Use the editor's default scope
   without asking unless the user already requested another supported scope.
2. Resolve and validate Node.js, then select the helper described by `SKILL.md`.
3. Run the private binding-file workflow below. It detects the environment and
   writes the matching credentials file. The wizard refuses to overwrite an
   existing file; use its force option only after the user asks to replace it.
4. Validate token minting without displaying the JWT or generated
   `Authorization` header. Report only success or the failure cause.
5. Configure only the requested editor and detected environment, using
   [`config-snippets.md`](./config-snippets.md). Use absolute executable,
   helper, and credentials paths, plus the resolved server `PATH` for stdio
   configuration. Do not save a generic server name.
6. For Claude Code, exit the current process and start a fresh session. Do not
   use `/mcp` as the refresh step; its panel can retain stale state and omit a
   newly added server. For other editors, reload or reconnect the MCP server.
7. Make a real read-only `s4` or `ariba` tool call through the named server. A
   token mint, connection panel, `tools/list`, or server list is diagnostic but
   not end-to-end proof. Never attempt this call in the setup session itself or
   via a subagent spawned from it: a newly added server is not visible to
   either, so the call returns "No such tool available" even when the
   configuration is correct. Validate only after the restart in step 6.

## Validate authentication safely

Use `HELPER_PATH` from `SKILL.md` to validate generated headers without
displaying the JWT or `Authorization` value.

On macOS or Linux:

```sh
"$NODE_BIN" -e 'const cp=require("node:child_process"); const p=JSON.parse(cp.execFileSync(process.execPath,[process.argv[1],"headers"],{encoding:"utf8",env:{...process.env,SAP_DOMAIN_MODELS_MCP_CREDS_FILE:process.argv[2]}})); if(typeof p.Authorization!=="string" || !p.Authorization.startsWith("Bearer ") || p.Authorization.length<="Bearer ".length) throw new Error("Invalid Authorization header"); console.log("SAP Domain Models headersHelper authentication succeeded")' \
  "$HELPER_PATH" "$CREDS_FILE"
```

On Windows PowerShell:

```powershell
$previousCredsFile = $env:SAP_DOMAIN_MODELS_MCP_CREDS_FILE
try {
  $env:SAP_DOMAIN_MODELS_MCP_CREDS_FILE = $credsFile
  $headers = (& $nodeBin $helperPath headers | ConvertFrom-Json)
  if (-not $headers.Authorization -or -not $headers.Authorization.StartsWith("Bearer ")) {
    throw "Invalid Authorization header"
  }
  Write-Host "SAP Domain Models headersHelper authentication succeeded"
} finally {
  if ($null -eq $previousCredsFile) {
    Remove-Item Env:SAP_DOMAIN_MODELS_MCP_CREDS_FILE -ErrorAction SilentlyContinue
  } else {
    $env:SAP_DOMAIN_MODELS_MCP_CREDS_FILE = $previousCredsFile
  }
}
```

A successful header or token check validates the IAS credentials, not the MCP
endpoint. The real named tool call remains the end-to-end check.

## Configure credentials privately

Honor an existing `SAP_DOMAIN_MODELS_MCP_CREDS_FILE` only when it belongs to the
detected environment. Otherwise use the binding-derived path in the table above.
Credentials for prod DEWC and prod USEA are not interchangeable.

Install the bundled wizard without reading its output file:

```sh
mkdir -p "$HOME/.config/sap-domain-models"
cp "<this-skill-dir>/assets/set-credentials.sh" \
  "$HOME/.config/sap-domain-models/sap-domain-models-set-credentials.sh"
chmod 700 "$HOME/.config/sap-domain-models/sap-domain-models-set-credentials.sh"
```

Run the wizard yourself, non-interactively, passing the repository's two
binding files as arguments (absolute paths):

```sh
bash "$HOME/.config/sap-domain-models/sap-domain-models-set-credentials.sh" \
  "<repo>/credentials/sap-domain-models-prod-usea.json" \
  "<repo>/credentials/ias-prod-usea.json"
```

The wizard validates both files, detects the cluster from the SAP Domain
Models `url`, extracts the IAS values without displaying them, and atomically
writes a mode-600 credentials file. Its entire output is four non-secret
results: detected environment, MCP endpoint, MCP server name, and the written
credentials path — use those four lines directly. Never read or display either
binding or the resulting credentials file, and never run the wizard in its
interactive prompt mode from the agent. If the repository binding files are
missing (`ias-prod-usea.json` means the decrypt step has not run; see above),
or the user keeps their bindings elsewhere, ask the user to run the same
command in their own terminal with their paths and to share the four result
lines. If the wizard reports that the destination exists, obtain explicit user
approval before rerunning it with `--force`. Use
`assets/credentials.env.example` only when the user declines the wizard or it
cannot run.

On Windows, install the bundled PowerShell wizard and run it the same way,
with both binding paths as parameters:

```powershell
$dir = Join-Path $HOME ".config\sap-domain-models"
New-Item -ItemType Directory -Force $dir | Out-Null
Copy-Item "<this-skill-dir>\assets\set-credentials.ps1" `
  (Join-Path $dir "sap-domain-models-set-credentials.ps1")
$wizard = Join-Path $dir "sap-domain-models-set-credentials.ps1"
Unblock-File -LiteralPath $wizard
powershell -NoProfile -ExecutionPolicy Bypass -File $wizard `
  -SapDomainModelsBinding "<repo>\credentials\sap-domain-models-prod-usea.json" `
  -IasBinding "<repo>\credentials\ias-prod-usea.json"
```

The Windows wizard creates owner-only ACLs on its directory and credentials
file. If it reports that the destination exists, obtain explicit user approval
before rerunning it with `-Force`; do not change the machine or user execution
policy. After successful setup and validation, offer to let the user delete the
downloaded binding files from their Downloads folder. Do not delete them or
their BTP service keys without explicit approval.

## Editor behavior

- **Claude Code:** use direct HTTP with a dynamic `headersHelper`. A URL-only
  entry starts the wrong interactive OAuth flow. The helper process must inherit
  `SAP_DOMAIN_MODELS_TEMPERATURE` and any nondefault
  `SAP_DOMAIN_MODELS_MCP_CREDS_FILE`; an HTTP entry's `env` block is not
  reliable for this process. On Windows, use the environment-specific `.cmd`
  wrapper and the scope-specific direct-edit recovery procedure in
  `config-snippets.md` when nested JSON quoting is fragile. For the Claude Code
  VS Code extension across projects, use user scope; its MCP entry belongs in
  the top-level `mcpServers` object in `~/.claude.json`, not
  `~/.claude/settings.json`.
- **Codex:** use the helper as a stdio MCP server because Codex cannot run
  Claude Code's dynamic HTTP `headersHelper`. Give saved configuration an
  absolute Node.js/helper path and a `PATH` that can resolve `npx`. Respect user
  versus project scope.
- **Cursor, Cline, VS Code native MCP, and GitHub Copilot agent mode:** use the
  stdio refreshing proxy. Put a literal absolute credentials path in the
  server's `env`; JSON does not reliably expand `~` or `$HOME`.
- GUI clients may not inherit an `nvm` shell's `PATH`. Prefer literal absolute
  executable paths over assuming `node` or `npx` is visible.

## Temperature

Keep the hosted default and do not ask a temperature question unless the user
already requested an override. For an override, accept only a number from `0`
through `2`, then configure `SAP_DOMAIN_MODELS_TEMPERATURE` in the helper
process environment. The helper sends `X-SAP-Domain-Models-Temperature` for
every authenticated request. Temperature does not belong in the credentials
file or individual tool arguments.

## Token refresh

- Claude Code mints headers on connect. Claude Code 2.1.193 and newer also
  reruns `headersHelper` after a 401 or 403, reconnects, and retries once. On an
  older version, reconnect and retry; upgrading is optional troubleshooting.
- Claude Code 2.1.205 and newer can report failed MCP connections to the model
  when tool search is enabled. A custom `ANTHROPIC_BASE_URL` gateway or
  `ENABLE_TOOL_SEARCH=false` can keep that reporting unavailable, so a client
  upgrade alone does not prove the intended server is being used.
- Stdio clients use a local refreshing proxy. If authentication still fails
  after a long idle period, reload the MCP server in the editor.

## Troubleshooting

- **The wizard reports a missing path or exits at a prompt:** enter both local
  binding paths, or pass both quoted paths as arguments. Empty input and EOF are
  rejected. `~` and `~/...` expand on macOS/Linux; use a full path on Windows.
- **The wizard cannot read a binding, reports invalid JSON, or expects an
  object:** download the binding credentials again from the BTP service instance
  or service key. The file must be a JSON object with fields either at the top
  level or inside `credentials`; do not paste it into chat to diagnose it.
- **The wizard rejects a binding field or service URL:** the SAP Domain Models
  binding needs a supported `url`; the `SECRET` IAS binding needs `url`,
  `clientid`, and `clientsecret`. URLs must be plain HTTPS origins. Do not edit a
  binding to force it to another cluster.
- **The wizard reports that Node.js is required:** install or select a supported
  Node.js version using the prerequisite procedure, then rerun the wizard.
- **PowerShell says the script is disabled or not digitally signed:** unblock
  and invoke only this wizard:

  ```powershell
  Unblock-File -LiteralPath <wizard-path>
  powershell -NoProfile -ExecutionPolicy Bypass -File <wizard-path>
  ```

  Do not use `Set-ExecutionPolicy`.

- **`Set-Acl` was found in module `Microsoft.PowerShell.Security` but the
  module could not be loaded:** the installed wizard copy predates the
  module-free ACL handling. Re-copy `assets/set-credentials.ps1` over
  `~\.config\sap-domain-models\sap-domain-models-set-credentials.ps1`,
  unblock it, and rerun — the current wizard applies ACLs through .NET and
  needs no PowerShell module.
- **The credentials destination already exists:** leave it unchanged unless the
  user explicitly requests replacement, then rerun with `--force` on
  macOS/Linux or `-Force` on Windows.

- **`Cannot POST /register` with an HTML OAuth response:** Claude Code started
  OAuth Dynamic Client Registration. This is not an S/4 or Ariba tool response,
  does not show the MCP endpoint is down, and does not by itself show that
  `headersHelper` cannot refresh. Inspect `claude mcp get <name>` and same-named
  entries in every scope; a higher-precedence URL-only entry can shadow the
  correct one. Verify that the helper command exists, passes the safe header
  check, and is trusted to run for a project- or local-scope entry. Repair the
  effective entry with the dynamic `headersHelper` from `config-snippets.md`.
  Do not use **Authenticate**, `claude mcp login`, change redirect URIs, or
  replace credentials that pass the safe check.
- **A browser opens or IAS reports an OpenID-provider error:** the editor
  started interactive OAuth. Close it and restore the dynamic header or stdio
  helper configuration. Do not change redirect URIs.
- **Claude Code says authentication is required:** inspect the saved entry for a
  working `headersHelper`, reconnect, and make a real call through the named
  server. The list or panel probe may not run the helper.
- **Another MCP server answers silently:** call the selected server explicitly
  and temporarily disable overlapping servers during controlled validation.
  If Claude Code still does not report the failed connection, check whether a
  custom `ANTHROPIC_BASE_URL` or `ENABLE_TOOL_SEARCH=false` has disabled tool
  search; do not enable unsupported beta features merely for this diagnostic.
- **Token minting returns HTML, `Unexpected token '<'`, or `<!DOCTYPE`:** an
  XSUAA/UAA `authentication.<region>.hana.ondemand.com` URL was probably used.
  Use the IAS `accounts.ondemand.com` or `accounts400.ondemand.com` tenant from
  the credentials.
- **Token minting returns a JSON error:** verify the private file path, client
  ID, secret, and `client_credentials` grant without printing secrets or the
  token.
- **`/mcp` returns 401:** confirm the endpoint and credentials use the same
  environment. Inspect only the token metadata needed to verify that `iss`
  matches the selected IAS tenant and `aud` contains that environment's
  SAP Domain Models service provider client ID; never print or paste the token.
- **The editor cannot find Node.js, `npx`, or the helper:** replace shell-only
  names with absolute paths. On Windows, use the corresponding `.cmd` shim.
- **Stdio cannot find `mcp-remote`:** ensure the saved `PATH` begins with the
  directory containing the validated Node.js and `npx`, then reconnect.
- **A custom credentials path works in a terminal but not the editor:** put the
  literal absolute path in the saved helper command or stdio `env`.
- **The editor connects to the wrong environment:** rerun the wizard with the
  intended SAP Domain Models and IAS binding files. Replace only the detected
  entry so the server name, endpoint, and credentials path match the same row
  above; user location does not select the cluster.
- **A helper works in a terminal but not an `nvm`-based editor:** replace bare
  `node` with `NODE_BIN` and set the saved server `PATH` to `SERVER_PATH` from
  the resolution procedure above.
- **Stdio stops after token expiry or the proxy is stuck:** reload the MCP
  server. If necessary, remove only its matching cache under `~/.mcp-auth/` (or
  `%USERPROFILE%\.mcp-auth\`), stop stray proxy processes, and reload.
- **Windows rejects nested Claude JSON:** use forward-slash absolute paths and
  `.cmd` executables. If `claude mcp add-json` reports
  `Invalid configuration: Invalid input`, use the backup and scope-specific
  direct-edit procedure in `config-snippets.md`. Use the top-level user-scope
  recovery for the Claude Code VS Code extension, or the selected-project
  recovery for local scope; preserve all other projects and servers.
