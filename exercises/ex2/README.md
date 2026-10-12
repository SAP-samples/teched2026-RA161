# Exercise 2 - Plan: A BTP Side-by-Side Extension

In this exercise, you move from exploring to **building**: you produce an implementation plan a team could actually execute, with every technical decision grounded in the domain model. The deliverable is a short plan document — the kind of thing you'd attach to a customer estimate or hand to a Basis team.

The business setting: you are building a BTP side-by-side extension that reads purchase order details — including account assignment — from S/4HANA. Before anyone writes code, three decisions need grounded answers: which API, which entities, and what the Basis team must grant.

## Exercise 2.1 Draft the plan with grounded facts

Ask Claude Code to build the plan, using the domain model for every system fact:

```
Draft a one-page implementation plan for a read-only BTP side-by-side
extension that reads purchase order details including account assignment
from S/4HANA. Use the s4 tool to ground every technical claim. The plan
must decide: OData V2 or V4 and which released service; which entity sets
cover header, items, account assignment, and schedule lines and how they
navigate to each other; the key filter fields with their types; and what
the Basis team needs to verify or grant for a read-only integration.
```

Claude Code will call the `s4` tool (possibly more than once) and assemble the plan. Save the result to a file — this is your deliverable.

## Exercise 2.2 Score the plan with the rubric

Now review your own plan the way a skeptical architect would. The rubric has one rule:

> **Every named object must carry a verifiable identifier** — a package, a release state, an entity-set name from metadata, or a typed key field. A plan line that names an object without one is a guess wearing a suit.

Check your plan for:

| Plan decision | Grounded when it includes |
|---|---|
| Service choice | The service name **and** its release state and package — and ideally why the alternatives were rejected |
| Entity coverage | Entity-set names plus the navigation path from header to account assignment |
| Filter design | Key fields with their EDM types and lengths |
| Authorization ask | What the evidence actually establishes — and what it does not |

That last row is the important one. The ontology layer's authorization trace for this service comes back **thin** — the access-control artifacts exist, but concrete authorization objects and activity values are not recorded in the evidence. A well-grounded answer *says so* and tells you what to do next (run a live authorization trace with STAUTHTRACE during a test call) instead of inventing object names. If your plan contains confident authorization specifics, check them extra hard: that is exactly where an ungrounded model would fabricate.

This is the second lesson of the workshop, and it may be the more important one: **a grounded system earns trust by how it handles what it doesn't know.** Your plan should hand the Basis team a verification procedure, not a guess.

A grounded fact sheet from a working session is in [reference/grounded-plan-facts.md](reference/grounded-plan-facts.md) — compare the structural facts in your plan against it.

**If you have time:** ask a follow-up that extends the plan — `Use the s4 tool: which tables does that service ultimately read from?` — and see how lineage facts (header, item, and schedule-line tables reached through the CDS stack) would change your testing strategy.

## Summary

You've produced a plan whose every claim is either verifiable or honestly marked as needing verification — grounded facts where the graph has evidence, and a named procedure where it doesn't. That's the build-time pattern, and it's also how you should read any AI-generated plan from now on.

Continue to - [Exercise 3 - Exploration Tracks](../ex3/README.md)
