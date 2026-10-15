# Getting Started

In this exercise, you connect Claude Code to the SAP Domain Models MCP server and prove the connection with a real grounded call. Everything else in the workshop depends on this working, so we verify it end to end — not just that the server appears in a list.

## What you are connecting to

The SAP Domain Models MCP server exposes three tools inside Claude Code:

| Tool | Grounded in | Ask it about |
|---|---|---|
| `s4` | Ontology layer over the S/4HANA ABAP codebase and data dictionary | Tables, fields, function modules, BAdIs, CDS views, transactions |
| `ariba` | Ontology layer over the Ariba API specifications and application code | API endpoints, request/response schemas, pagination, integration patterns |
| `cap` | SAP Cloud Application Programming Model | CDS models, services, annotations, project setup |

Each tool takes a natural-language question. Behind it, a reasoning model retrieves evidence from the ontology layer and the domain model, then answers grounded in that evidence.

## Step 1 — Download this repository

The workshop machines do not come with this repository, and you don't need a GitHub account or `git` to get it:

**1. Download the ZIP:** <https://github.com/SAP-samples/teched2026-RA161/archive/refs/heads/main.zip> (or **Code → Download ZIP** on the repository page — no sign-in required).

**2. Extract it into a `projects` directory under your home directory** (created if it doesn't exist). Don't move or delete the extracted folder after setup: the editor configuration you are about to create points at it by absolute path.

Windows (PowerShell) — run the three commands in order:

```powershell
New-Item -ItemType Directory -Force -Path "$HOME\projects" | Out-Null
```

```powershell
Expand-Archive -LiteralPath "$HOME\Downloads\teched2026-RA161-main.zip" -DestinationPath "$HOME\projects"
```

```powershell
cd "$HOME\projects\teched2026-RA161-main"
```

macOS/Linux — run the three commands in order:

```sh
mkdir -p ~/projects
```

```sh
unzip ~/Downloads/teched2026-RA161-main.zip -d ~/projects
```

```sh
cd ~/projects/teched2026-RA161-main
```

**3. Stay in that terminal** — you are now in the extracted folder (`~/projects/teched2026-RA161-main`), and every command in this exercise runs from there.

## Step 2 — Locate your credentials

Your credentials are two service binding files in this repository's `credentials/` directory:

| File | What it is |
|---|---|
| `credentials/sap-domain-models-prod-usea.json` | Service binding that identifies the workshop environment |
| `credentials/ias-prod-usea.json.enc` | **Encrypted** IAS binding the token helper uses to mint short-lived access tokens — added shortly before the session |

Decrypt the IAS binding with the passphrase shown on screen at the session — the command is the same in PowerShell and in a macOS/Linux shell, run from the extracted folder:

```
node scripts/decrypt-credentials.cjs
```

It prompts for the passphrase (your input is hidden) and writes `credentials/ias-prod-usea.json`. If it reports that the encrypted file is missing, your ZIP predates the credential upload — download a fresh copy of the repository (Step 1) and start again from there.

These are shared, session-scoped credentials minted for this workshop and revoked right after it ends. Even so, practice normal credential hygiene: the setup only ever needs the file **paths** — never paste the decrypted file's contents into chat.

## Step 3 — Run the guided setup

This repository ships an installation skill that does the entire setup for you: it checks your Node.js version, walks you through a private credentials wizard, configures Claude Code, and validates the connection end to end.

In the terminal from Step 1 — you are already in this repository's directory — start Claude Code:

```
claude
```

Then ask:

```
Use docs/remote-mcp/install-sap-domain-models-mcp/SKILL.md to configure SAP Domain Models MCP in this editor. Do not ask me to paste secrets.
```

### What the skill will do

The run is mostly hands-off: Claude Code runs the checks and the credentials wizard itself, using the two files from Step 2 — the wizard's output contains no secrets. **There is nothing to copy or paste in this section** — it only describes what you will see. Your part:

**1. Approve the permission prompts**: a few read-only checks (Node.js version, locating the helper) and the wizard run against `credentials/sap-domain-models-prod-usea.json` and `credentials/ias-prod-usea.json`. The wizard detects the workshop environment from the service binding, writes a protected credentials file, and prints exactly four non-secret result lines. A successful run looks like this — it is output, not something to type:

```text
Detected environment: Prod USEA
MCP endpoint: https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp
MCP server name: prod_usea_sap_domain_models_mcp
Wrote C:\Users\<you>\.config\sap-domain-models\mcp-prod-usea-credentials.env
```

(On macOS/Linux the last line reads `Wrote /Users/<you>/.config/sap-domain-models/mcp-prod-usea-credentials.env`.)

**2. Confirm `--force` if asked.** If the wizard reports `Credentials file already exists`, a previous attempt already wrote one — the skill asks your approval to re-run with `--force`, and the last line then reads `Replaced` instead of `Wrote`.

The skill finishes by writing the MCP server entry and validating the connection with a real tool call.

If the facilitators announce a fallback during the session, the repository already carries a Prod DEWC backup pair: decrypt it with `node scripts/decrypt-credentials.cjs --fallback` (same or newly announced passphrase), then ask the skill to re-run the setup with `credentials/sap-domain-models-prod-dewc.json` and `credentials/ias-prod-dewc.json` — the result lines say `Prod DEWC`, and the fallback server is added beside the first one.

One caution for the whole run: if a browser window or an "Authenticate" prompt ever appears, close it and tell the skill — that is the wrong (interactive) login flow; this server authenticates only through the configured helper.

## Step 4 — Verify the connection

**1. When the skill finishes, confirm in a new terminal window:**

```
claude mcp list
```

You should see the server name the skill reported, with a ✔ Connected status. If it shows a failure, ask a facilitator before continuing — the fix is usually a stale session (exit Claude Code fully and start it again) rather than a configuration change.

**2. Exit Claude Code completely and start a fresh session** in this repository's directory. A fresh start is required for the new server to load reliably — re-opening the `/mcp` panel in a running session is not enough.

## Step 5 — Make a real grounded call

A connection listing is not proof; a real tool call is. In Claude Code, ask:

```
Use the s4 tool: what is table VBAK? One sentence.
```

A grounded answer names the table's purpose **and its package** (VA). That package attribution is your first taste of the difference between a grounded answer and a general one — it comes from the data dictionary, not from prose about SAP.

Then verify the Ariba side:

```
Use the ariba tool: which endpoint retrieves a vendor's certificates in the Supplier Data API with Pagination? One sentence.
```

A grounded answer names the endpoint path and HTTP method — `GET /vendors/{vendorId}/certificates` in the `supplierdatapagination_v4` API — not a paraphrase of what the API is for. The path and method are structural facts you can check against the API definition, the Ariba counterpart of the `VBAK`/package answer above.

A transcript of both probe calls from a working session is in [reference/probe-transcript.md](reference/probe-transcript.md) — your wording will differ; the shape should match.

> **If your connection cannot be fixed in a few minutes:** pair with a neighbor and continue the exercises together, and flag a facilitator so they can work on your setup in the background. Do not spend the session debugging alone.

## Step 6 — Set up your evaluation worksheet

Throughout the workshop you will judge answers with three questions. Keep this table in a scratch file (or on paper):

| Claim | Where it came from | Structurally verifiable? |
|---|---|---|
| e.g. "T030 key fields are KTOPL, KTOSL, BKLAS, BWMOD, KOMOK" | `s4` tool | Yes — data dictionary fact |
| e.g. "VST is a sales-related transaction key" | `s4` tool | No — semantic gloss, verify before trusting |

The rule of thumb you will test repeatedly: **structure is reliable, glosses are leads.** Object names, key fields, packages, endpoint paths, and pagination mechanics come from the ontology layer and hold up. One-line explanations of what something means, and exact credential strings like OAuth scopes, vary — treat them as pointers to confirm in the authoritative source.

## Summary

You have a verified, grounded connection to the SAP Domain Models and a worksheet for judging what comes back.

Continue to - [Exercise 1 - Explore: GL Account Determination](../ex1/README.md)
