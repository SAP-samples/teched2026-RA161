# Connecting an editor to SAP Domain Models MCP

This guide connects an MCP-capable coding editor—Claude Code, Codex, Cursor,
Cline, VS Code native MCP, GitHub Copilot agent mode, or another compatible
client—to the SAP Domain Models MCP cluster associated with a BTP subaccount.

## Why client credentials

The repository helper mints an IAS bearer token and supplies it to the MCP
connection. This avoids interactive browser authentication. Client credentials
identify the application, not an individual user, so protect them as secrets.

## Prerequisites

1. Node.js 20.20.0 or newer and npm 10.8.2 or newer. The helper uses Node.js,
   and stdio-style editor configurations use the public `mcp-remote` package
   through `npx`.
2. A downloaded SAP Domain Models service binding JSON file
   (`sap-domain-models-dev.json`). Its `url`
   identifies the correct prod DEWC or prod USEA cluster.
3. A downloaded `SECRET` IAS service binding JSON file (`ias-dev.json`) from
   the same BTP subaccount. It must contain credentials for an app with the
   `client_credentials` grant whose tokens carry the selected SAP Domain Models
   service's provider client ID in `aud`.
4. An MCP-capable coding editor or coding agent that can follow a local skill.

## Repository-only guided setup

The onboarding repository supplies both required components:

- Skill:
  [`install-sap-domain-models-mcp/`](./install-sap-domain-models-mcp/)
- Helper: [`scripts/remote-mcp/helper.cjs`](../../scripts/remote-mcp/helper.cjs)

Keep the checkout (or extracted download) in a durable location because the saved editor configuration
uses the helper's absolute path. The onboarding flow does not install or use a
private SAP npm package. For stdio clients, the helper launches public
`mcp-remote` through `npx`, so first use or a cache miss requires public npm
registry access.

Open the repository in your editor and ask its coding agent:

```text
Use docs/remote-mcp/install-sap-domain-models-mcp/SKILL.md to configure SAP Domain Models MCP in this editor. Do not ask me to paste secrets.
```

Pointing the agent at the repository path works even when the editor does not
automatically discover skills. The skill:

1. Uses the SAP Domain Models service binding to detect the environment,
   endpoint, credentials path, and MCP server name.
2. Validates Node.js and the repository helper.
3. Guides you to provide only the two local binding-file paths to a private
   Bash or PowerShell wizard.
4. Preserves unrelated MCP entries while configuring the selected editor.
5. Validates authentication without displaying a token.
6. Finishes with a real read-only `s4` or `ariba` call through the detected
   environment-specific server.

The binding files are used only during setup. The wizard writes the same
`SAP_DOMAIN_MODELS_IAS_*` runtime variables used by existing installations;
the binding paths are not saved in the editor configuration. Existing working
prod DEWC entries do not need to be rewritten unless the user asks to migrate
or the binding indicates a different cluster.

The skill contains editor-specific configuration and troubleshooting for macOS,
Linux, and Windows. No Claude Code extension is required for VS Code native MCP
or GitHub Copilot agent mode.

## Switching an existing Prod DEWC setup to Prod USEA

Follow the skill's
[Prod DEWC to Prod USEA runbook](./install-sap-domain-models-mcp/references/migrate-prod-dewc-to-prod-usea.md).
It adds the Prod USEA connection beside the working Prod DEWC connection,
requires a real read-only tool call before disabling Prod DEWC, and retains the
disabled Prod DEWC configuration and credentials for rollback.
