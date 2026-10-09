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

## Step 1 — Get your credentials

> **TBD:** Credential handout is finalized closer to the session. Your facilitator provides a credentials file and the MCP server entry for the facilitator's environment. Follow the handout; the server name in your configuration comes from it.

## Step 2 — Verify the connection

1. In a terminal, check that the server is configured and connected:

```
claude mcp list
```

You should see the SAP Domain Models server with a ✔ Connected status. If it shows a failure, ask a facilitator before continuing — the fix is usually a stale session (exit Claude Code fully and start it again) rather than a configuration change.

2. Start a fresh Claude Code session in this repository's directory.

## Step 3 — Make a real grounded call

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

> **If your connection cannot be fixed in a few minutes:** pair with a neighbor and continue the exercises together, and flag a facilitator so they can work on your setup in the background. Do not spend the hour debugging alone.

## Step 4 — Set up your evaluation worksheet

Throughout the workshop you will judge answers with three questions. Keep this table in a scratch file (or on paper):

| Claim | Where it came from | Structurally verifiable? |
|---|---|---|
| e.g. "T030 key fields are KTOPL, KTOSL, BKLAS, BWMOD, KOMOK" | `s4` tool | Yes — data dictionary fact |
| e.g. "VST is a sales-related transaction key" | `s4` tool | No — semantic gloss, verify before trusting |

The rule of thumb you will test repeatedly: **structure is reliable, glosses are leads.** Object names, key fields, packages, endpoint paths, and pagination mechanics come from the knowledge graph and hold up. One-line explanations of what something means, and exact credential strings like OAuth scopes, vary — treat them as pointers to confirm in the authoritative source.

## Summary

You have a verified, grounded connection to the SAP Domain Models and a worksheet for judging what comes back.

Continue to - [Exercise 1 - Explore: GL Account Determination](../ex1/README.md)
