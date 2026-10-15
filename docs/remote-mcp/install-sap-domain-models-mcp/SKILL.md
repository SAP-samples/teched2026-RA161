---
name: install-sap-domain-models-mcp
description: Configure, migrate, or repair prod DEWC or prod USEA SAP Domain Models MCP in an MCP-capable editor from this repository. Use for binding-file-based client-credentials authentication and cluster routing, Claude headersHelper or stdio configuration, Cannot POST /register OAuth failures, Windows and nvm path failures, token refresh, silent fallback, or existing prod DEWC migration.
---

# Install SAP Domain Models MCP from onboarding

Use only the helper and setup resources shipped in this onboarding repository.
Do not install or reference the private npm package. The service bindings
(`sap-domain-models-dev.json` and `ias-dev.json`) select the environment; do
not ask the user to choose or infer one from their location.

Read and follow both setup references:

1. [`references/setup-and-troubleshooting.md`](./references/setup-and-troubleshooting.md)
   defines the binding-derived guided workflow, credential safety, compatibility,
   validation, refresh behavior, and troubleshooting.
2. [`references/config-snippets.md`](./references/config-snippets.md) defines
   reliable editor configuration using absolute Node, helper, credentials, and
   server `PATH` values.

When the user already uses Prod DEWC and wants to migrate or switch to Prod USEA, also follow
[`references/migrate-prod-dewc-to-prod-usea.md`](./references/migrate-prod-dewc-to-prod-usea.md).
Treat that migration or switch request as authorization to disable Prod DEWC
only after the separate Prod USEA entry passes a real read-only tool call. Keep
the disabled Prod DEWC configuration and credentials for rollback; do not delete
them without separate explicit approval.

## Resolve the onboarding helper

Starting from the current directory, walk upward until the helper is found:

```sh
ONBOARDING_ROOT="$(pwd -P)"
while [ ! -f "$ONBOARDING_ROOT/scripts/remote-mcp/helper.cjs" ] && \
  [ "$ONBOARDING_ROOT" != "/" ]; do
  ONBOARDING_ROOT="$(dirname "$ONBOARDING_ROOT")"
done
```

On Windows PowerShell:

```powershell
$onboardingRoot = (Get-Location).Path
while (-not (Test-Path (Join-Path $onboardingRoot "scripts\remote-mcp\helper.cjs"))) {
  $parent = Split-Path -Parent $onboardingRoot
  if (-not $parent -or $parent -eq $onboardingRoot) { break }
  $onboardingRoot = $parent
}
```

Require the complete repository workflow:

```text
<repo>/scripts/remote-mcp/helper.cjs
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/assets/credentials.env.example
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/references/setup-and-troubleshooting.md
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/references/config-snippets.md
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/references/migrate-prod-dewc-to-prod-usea.md
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/assets/set-credentials.sh
<repo>/docs/remote-mcp/install-sap-domain-models-mcp/assets/set-credentials.ps1
```

If any required file is missing, stop and ask the user to re-clone or
re-download the complete onboarding repository.

Before saving the helper path in editor configuration, confirm the checkout is
in a durable location. If it is under a temporary directory, stop and ask the
user to move it (or clone or download it again) to a stable path.

After the shared Node.js resolution procedure, set the absolute helper path:

```sh
HELPER_PATH="$ONBOARDING_ROOT/scripts/remote-mcp/helper.cjs"
```

On Windows:

```powershell
$helperPath = Join-Path $onboardingRoot "scripts\remote-mcp\helper.cjs"
```

Validate generated headers with the shared safe parser. Never display a JWT,
generated `Authorization` header, service binding, or credential file.

For stdio clients, the repository helper launches public `mcp-remote` through
`npx`. First use or a cache miss therefore requires public registry access.
Save the absolute `NODE_BIN`, `HELPER_PATH`, binding-derived credentials path,
and `SERVER_PATH` exactly as directed by the configuration reference.

Do not rewrite a working existing prod DEWC entry unless the user asks to
migrate it or their SAP Domain Models binding identifies another cluster. Finish
new or migrated setup with a real read-only `s4` or `ariba` call through the
binding-derived environment-specific server name.
