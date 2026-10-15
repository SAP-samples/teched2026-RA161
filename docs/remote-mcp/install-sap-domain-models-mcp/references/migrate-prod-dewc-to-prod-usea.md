# Switch from Prod DEWC to Prod USEA

This runbook is for someone who already has SAP Domain Models MCP working
against Prod DEWC and wants to use the Prod USEA cluster.

A request to **migrate** or **switch** from Prod DEWC to Prod USEA authorizes
disabling the Prod DEWC entry after Prod USEA passes an end-to-end check. The
migration is additive until that validation succeeds. Do not overwrite the Prod
DEWC server entry or reuse its credentials for Prod USEA.

## What changes

| Setting          | Existing Prod DEWC                                                         | New Prod USEA                                                 |
| ---------------- | -------------------------------------------------------------------------- | ------------------------------------------------------------- |
| MCP server name  | `prod_dewc_sap_domain_models_mcp` (or legacy `prod_sap_domain_models_mcp`) | `prod_usea_sap_domain_models_mcp`                             |
| MCP endpoint     | `https://sap-domain-models-mcp-prod-dewc.appai.cloud.sap/mcp`              | `https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp` |
| Credentials file | `~/.config/sap-domain-models/mcp-prod-dewc-credentials.env`                | `~/.config/sap-domain-models/mcp-prod-usea-credentials.env`   |

## Before starting

Download two new JSON files from the Prod USEA BTP subaccount:

1. The SAP Domain Models service binding (or service key). Its `url` must
   identify `https://nova-service-prod-usea.appai.cloud.sap`.
2. A `SECRET` IAS service binding from the same subaccount for the consumer
   application authorized to call that SAP Domain Models service.

Keep both files private. Provide only their local paths to the credential
wizard; never paste binding contents, client secrets, JWTs, or authorization
headers into chat. Prod DEWC and Prod USEA credentials are not interchangeable.

Keep the existing Prod DEWC entry enabled and retain its credentials file until
the Prod USEA connection has passed a real tool call. After validation, disable
the Prod DEWC entry but retain its configuration and credentials for rollback.

## Run the guided migration

Open the project or workspace whose editor configuration you want to update and
ask its coding agent:

```text
Use the install-sap-domain-models-mcp skill to migrate this editor from Prod DEWC to Prod USEA. Add Prod USEA beside the existing Prod DEWC entry, keep Prod DEWC enabled until Prod USEA passes a real read-only tool call, then disable Prod DEWC without deleting its configuration or credentials. Do not ask me to paste secrets.
```

The skill will validate Node.js and the helper, then ask you to run the private
Bash or PowerShell credential wizard in your own terminal. Give the wizard the
two Prod USEA binding-file paths.

Continue only when its four non-secret result lines identify all of these
values:

```text
Detected environment: Prod USEA
MCP endpoint: https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp
MCP server name: prod_usea_sap_domain_models_mcp
Wrote .../mcp-prod-usea-credentials.env
```

If it detects Prod DEWC or another environment, stop. Do not edit the output or
derive a hostname manually; download the correct Prod USEA SAP Domain Models
binding. If the Prod USEA credentials destination already exists, inspect why
it exists and use the wizard's force option only after the user explicitly
approves replacing it to rotate those credentials.

The agent should then add `prod_usea_sap_domain_models_mcp` beside the existing
Prod DEWC entry, preserving every unrelated MCP server and configuration scope.
The exact editor configuration is defined in
[`config-snippets.md`](./config-snippets.md).

## Validate before cutting over

1. Run the skill's safe authentication check. It must report success without
   displaying the token or generated `Authorization` header.
2. Restart Claude Code completely, or reload/reconnect the MCP server in the
   selected editor.
3. Make a real read-only `s4` or `ariba` call explicitly through
   `prod_usea_sap_domain_models_mcp`.

A successful token mint, server listing, connection indicator, `tools/list`,
or `GET /health` provides useful diagnostics but is not end-to-end proof that
the Prod USEA application is authorized and serving tool calls.

After the real tool call succeeds, disable the Prod DEWC entry to complete the
requested migration and use Prod USEA for normal work. Retain the Prod DEWC
configuration and credentials for rollback. If the user asked only to add or
test Prod USEA rather than migrate or switch, keep Prod DEWC enabled.

## Roll back or retire Prod DEWC

To roll back, re-enable the retained Prod DEWC entry and disable the Prod USEA
entry. The separate Prod DEWC credentials file remains available.

Disabling Prod DEWC is part of a requested migration or switch after validation;
deleting its entry is not. Permanently remove the Prod DEWC entry only when the
user explicitly asks. Do not delete the Prod DEWC credentials file, downloaded
binding files, or BTP service keys without separate explicit approval.

## Troubleshooting

- **Wizard detects Prod DEWC:** the SAP Domain Models binding is from the wrong
  subaccount or service instance. Obtain the Prod USEA binding; do not substitute
  endpoint strings by hand.
- **Authentication succeeds but the real tool call returns `401` or `403`:**
  confirm that both bindings came from the intended Prod USEA consumer setup and
  that the IAS token audience includes the Prod USEA SAP Domain Models provider.
- **Claude reports `Cannot POST /register`:** the effective entry started the
  unsupported interactive OAuth flow. Repair its dynamic `headersHelper` and
  check for a higher-precedence URL-only entry as described in
  [`config-snippets.md`](./config-snippets.md).
- **The old server is still used:** invoke `prod_usea_sap_domain_models_mcp`
  explicitly, then inspect duplicate names and editor configuration scopes.
- **The helper or Node.js works in a terminal but not the editor:** use the
  absolute Node/helper paths and saved server `PATH` required by the skill.
