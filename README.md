# RA161 - Hands on SAP Domain Models across design, build, and run time

## Description

This repository contains the material for the SAP TechEd 2026 session RA161 — Hands on SAP Domain Models across design, build, and run time.

SAP Domain Models are specialized language models trained on SAP system knowledge — the S/4HANA ABAP codebase and data dictionary, and the Ariba API specifications and application code — combined with retrieval over an ontology layer built from those sources. They answer with verifiable system facts (tables and key fields, function modules with packages, released APIs, endpoint paths) where general-purpose models must hedge or point you at documentation.

## Overview

In this session you connect Claude Code to the SAP Domain Models MCP server and use the `s4`, `ariba`, and `cap` tools as grounded research partners across the lifecycle of an SAP engagement:

- **Design time** — explore a system area you don't know yet: which tables, transaction keys, and CDS views drive a process, straight from the codebase.
- **Build time** — turn grounded facts into an implementation plan and generated code: every object in your plan carries a package, release state, or verifiable identifier.
- **Run time** — investigate how processes behave in a live system: status fields, integration handoffs, and the objects an agent would monitor.

The session starts guided (Getting Started plus two exercises); the rest is yours: a structured menu of exploration tracks, or bring your own scenario.

A working principle you will use all session: domain-model answers are strongest on **structure** — object names, key fields, packages, endpoint paths — and those are exactly the facts you can verify. Treat one-line semantic glosses and exact credential strings as leads to confirm, not facts to copy.

## Requirements

- A laptop with [VS Code](https://code.visualstudio.com/) and [Claude Code](https://claude.com/claude-code), or Claude Code in a terminal
- Node.js 20.20.0 or newer and npm 10.8.2 or newer
- Access credentials for the SAP Domain Models MCP server — two service binding files in this repository's `credentials/` directory; the IAS binding is added shortly before the session and revoked after it (see [Getting Started](exercises/ex0/))
- No SAP system access is required; all exercises run against the domain models

## Exercises

**Guided exercises**

- [Getting Started](exercises/ex0/) — connect Claude Code to the SAP Domain Models MCP server and verify it with a real call
- [Exercise 1 - Explore: GL Account Determination](exercises/ex1/)
    - [Exercise 1.1 - Ask without grounding](exercises/ex1#exercise-11-ask-without-grounding)
    - [Exercise 1.2 - Ask the S/4 domain model](exercises/ex1#exercise-12-ask-the-s4-domain-model)
    - [Exercise 1.3 - Verify the structure](exercises/ex1#exercise-13-verify-the-structure)
- [Exercise 2 - Plan: A BTP Side-by-Side Extension](exercises/ex2/)
    - [Exercise 2.1 - Draft the plan with grounded facts](exercises/ex2#exercise-21-draft-the-plan-with-grounded-facts)
    - [Exercise 2.2 - Score the plan with the rubric](exercises/ex2#exercise-22-score-the-plan-with-the-rubric)

**Free exploration**

- [Exercise 3 - Exploration Tracks](exercises/ex3/) — choose a track: Ariba integration plan-and-build, design-time deep dives, run-time process intelligence, or your own scenario

## How to obtain support

Support for the content in this repository is available during the actual time of the online session for which this content has been designed. Otherwise, you may request support via the [Issues](../../issues) tab.

## Contributing
Please read the [CONTRIBUTING.md](./CONTRIBUTING.md) to understand the contribution guidelines.

## Code of Conduct
Please read the [SAP Open Source Code of Conduct](https://github.com/SAP-samples/.github/blob/main/CODE_OF_CONDUCT.md).

## License
Copyright (c) 2026 SAP SE or an SAP affiliate company and teched2026-RA161 contributors. Please see our [LICENSE](LICENSE) for copyright and license information. Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/SAP-samples/teched2026-RA161).
