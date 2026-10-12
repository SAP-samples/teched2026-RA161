# Getting Started

In this exercise, you connect Claude Code to the SAP Domain Models MCP server and prove the connection with a real grounded call. Everything else in the workshop depends on this working, so we verify it end to end — not just that the server appears in a list.

## What you are connecting to

The SAP Domain Models MCP server exposes three tools inside Claude Code:

| Tool | Grounded in | Ask it about |
|---|---|---|
| `s4` | S/4HANA ABAP codebase and data dictionary knowledge graph | Tables, fields, function modules, BAdIs, CDS views, transactions |
| `ariba` | Ariba API specifications and application code knowledge graph | API endpoints, request/response schemas, pagination, integration patterns |
| `cap` | SAP Cloud Application Programming Model | CDS models, services, annotations, project setup |

Each tool takes a natural-language question. Behind it, a reasoning model retrieves evidence from the knowledge graph and the domain model, then answers grounded in that evidence.

## Step 1 — Get your workshop bundle

> **TBD:** The handout format is finalized closer to the session. Your facilitator provides:
>
> | Item | What it is |
> |---|---|
> | Setup bundle | A folder containing the SAP Domain Models MCP client — including a **guided installation skill** and the token helper. `<BUNDLE_PATH>` below is wherever you saved it |
> | Two service binding files | Credential files for the workshop environment (keep them private — their contents never get pasted into chat) |

The server uses application credentials — there is no browser login. A token helper mints a short-lived token each time Claude Code connects; you never handle tokens yourself. Prerequisite: Node.js 20.20.0 or newer (`node --version`).

## Step 2 — Run the guided setup

The bundle ships an installation skill that does the entire setup for you: it checks your Node.js version, walks you through a **private credentials wizard** (you run one command in your own terminal with the paths to your two binding files — no secret ever enters the chat), configures Claude Code, and validates the connection end to end.

Start Claude Code and ask:

```
Use $install-sap-domain-models-mcp to configure this editor for the SAP Domain Models MCP server. Do not ask me to paste secrets.
```

If Claude Code does not find the skill by name, point it at the skill directory inside your bundle (`<BUNDLE_PATH>`) and ask again.

Follow its instructions. Two expectations while it runs:

- It will ask you to run a short command **in your own terminal** and report back four non-secret lines (environment, endpoint, server name, credentials path). That privacy split is by design.
- If a browser window or an "Authenticate" prompt ever appears, close it and tell the skill — that is the wrong (interactive) login flow; this server authenticates only through the configured helper.

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

The rule of thumb you will test repeatedly: **structure is reliable, glosses are leads.** Object names, key fields, packages, endpoint paths, and pagination mechanics come from the knowledge graph and hold up. One-line explanations of what something means, and exact credential strings like OAuth scopes, vary — treat them as pointers to confirm in the authoritative source.

## Summary

You have a verified, grounded connection to the SAP Domain Models and a worksheet for judging what comes back.

Continue to - [Exercise 1 - Explore: GL Account Determination](../ex1/README.md)
