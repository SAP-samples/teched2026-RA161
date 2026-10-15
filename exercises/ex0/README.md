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

## Step 1 — Locate your credentials

Your credentials are two service binding files in this repository's `credentials/` directory:

| File | What it is |
|---|---|
| `credentials/sap-domain-models-dev.json` | Service binding that identifies the workshop environment |
| `credentials/ias-dev.json` | IAS binding the token helper uses to mint short-lived access tokens — **added shortly before the session** |

These are shared, session-scoped credentials minted for this workshop and revoked right after it ends. Even so, practice normal credential hygiene: the setup only ever needs the file **paths** — never paste the file contents into chat. If `ias-dev.json` is missing, pull the latest commit (`git pull`).

## Step 2 — Run the guided setup

This repository ships an installation skill that does the entire setup for you: it checks your Node.js version, walks you through a private credentials wizard, configures Claude Code, and validates the connection end to end.

Start Claude Code **in this repository's directory** and ask:

```
Use docs/remote-mcp/install-sap-domain-models-mcp/SKILL.md to configure SAP Domain Models MCP in this editor. Do not ask me to paste secrets.
```

### What the skill will ask you

So you know what's coming, the run has four interaction points:

1. **Permission prompts** for a few read-only checks (Node.js version, locating the helper). Approve them.

2. **The credentials wizard, in your own terminal.** The skill installs a small wizard script and pauses, asking you to run it yourself — secrets stay out of the chat by design. Run it from this repository's root directory so the defaults in the next step resolve:

```
bash ~/.config/sap-domain-models/sap-domain-models-set-credentials.sh
```

3. **Two file-path prompts** from the wizard, each showing this repository's `credentials/` copy as a default in brackets (the defaults resolve when you run the wizard from the repository root). **Press Enter to accept the default**; type a path only if your files are somewhere else:

```
Location of sap-domain-models-dev.json [<repo>/credentials/sap-domain-models-dev.json]:
Location of ias-dev.json [<repo>/credentials/ias-dev.json]:
```

The wizard validates both files, detects the workshop environment from the service binding, and writes a protected credentials file. It prints exactly four non-secret result lines:

```
Detected environment: Prod USEA
MCP endpoint: https://sap-domain-models-mcp-prod-usea.appai.cloud.sap/mcp
MCP server name: prod_usea_sap_domain_models_mcp
Wrote /Users/<you>/.config/sap-domain-models/mcp-prod-usea-credentials.env
```

If the facilitators announce a fallback during the session, you'll receive Prod DEWC binding files instead — the flow is identical and the result lines say `Prod DEWC`.

If the wizard instead reports `Credentials file already exists`, you (or a previous attempt) already wrote one — re-run it with `--force` to replace it, and the last line reads `Replaced` instead of `Wrote`.

4. **Paste those four lines back into Claude Code.** The skill uses them to write the MCP server entry and then validates the connection with a real tool call.

One caution for the whole run: if a browser window or an "Authenticate" prompt ever appears, close it and tell the skill — that is the wrong (interactive) login flow; this server authenticates only through the configured helper.

## Step 3 — Verify the connection

1. When the skill finishes, confirm in a terminal:

```
claude mcp list
```

You should see the server name the skill reported, with a ✔ Connected status. If it shows a failure, ask a facilitator before continuing — the fix is usually a stale session (exit Claude Code fully and start it again) rather than a configuration change.

2. **Exit Claude Code completely and start a fresh session** in this repository's directory. A fresh start is required for the new server to load reliably — re-opening the `/mcp` panel in a running session is not enough.

## Step 4 — Make a real grounded call

A connection listing is not proof; a real tool call is. In Claude Code, ask:

```
Use the s4 tool: what is table VBAK? One sentence.
```

A grounded answer names the table's purpose **and its package** (VA). That package attribution is your first taste of the difference between a grounded answer and a general one — it comes from the data dictionary, not from prose about SAP.

Then verify the Ariba side:

```
Use the ariba tool: which API creates a supplier in Ariba SLP? One sentence.
```

Notice the answer's style: it names a specific API and operation, and if the evidence is thin it says so explicitly. That evidence-bound honesty is a feature you will rely on all session.

A transcript of both probe calls from a working session is in [reference/probe-transcript.md](reference/probe-transcript.md) — your wording will differ; the shape should match.

> **If your connection cannot be fixed in a few minutes:** pair with a neighbor and continue the exercises together, and flag a facilitator so they can work on your setup in the background. Do not spend the session debugging alone.

## Step 5 — Set up your evaluation worksheet

Throughout the workshop you will judge answers with three questions. Keep this table in a scratch file (or on paper):

| Claim | Where it came from | Structurally verifiable? |
|---|---|---|
| e.g. "T030 key fields are KTOPL, KTOSL, BKLAS, BWMOD, KOMOK" | `s4` tool | Yes — data dictionary fact |
| e.g. "VST is a sales-related transaction key" | `s4` tool | No — semantic gloss, verify before trusting |

The rule of thumb you will test repeatedly: **structure is reliable, glosses are leads.** Object names, key fields, packages, endpoint paths, and pagination mechanics come from the ontology layer and hold up. One-line explanations of what something means, and exact credential strings like OAuth scopes, vary — treat them as pointers to confirm in the authoritative source.

## Summary

You have a verified, grounded connection to the SAP Domain Models and a worksheet for judging what comes back.

Continue to - [Exercise 1 - Explore: GL Account Determination](../ex1/README.md)
