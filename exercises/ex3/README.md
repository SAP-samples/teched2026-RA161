# Exercise 3 - Exploration Tracks

The rest of the session is yours. Pick a track below — or invent your own. Each track is a starting point, not a script: the goal is to practice the explore → plan → execute pattern from the guided exercises on material you care about. Facilitators are around for questions, and the comparison habit from Exercise 1 still applies — ask once without tools, once with the domain model, then have Claude compare the two. Read every analysis with the same rule: **structure is reliable, glosses are leads.**

## Track A — Build: an Ariba integration, end to end

The build-time pattern on the Ariba side. Start with the grounded plan:

```
Use the ariba tool: I'm building a custom supplier onboarding portal that
needs to display a supplier's qualification status, active processes, and
questionnaire data from Ariba. Which APIs do I call, in what order? What
OAuth scopes does my app need, and how does pagination work for large
supplier datasets?
```

Expect spec-grade structure: endpoint paths, call ordering, per-endpoint page sizes, pagination token mechanics, and the required `realm` parameter. One deliberate caution: **treat OAuth scope strings as placeholders** — they vary between answers and releases; the authoritative source is your API portal. Everything structural (paths, pagination) is the durable part.

Then execute from the plan: ask Claude Code to generate a client skeleton *from the grounded answer* — the call sequence as functions, pagination handled per the mechanics the model described, scopes left as configuration. Notice the division of labor: the domain model supplied verified structure; the general model writes the code. That pairing, not either model alone, is the production pattern.

A grounded answer from a working session: [reference/grounded-answer-ariba.md](reference/grounded-answer-ariba.md).

## Track B — Design: deep dives into S/4HANA Finance and P2P

Two meaty design-time questions. Run either, then chase whatever surprises you with follow-ups.

**The Universal Journal:**

```
Use the s4 tool: In S/4HANA Finance, what is the ACDOCA (Universal Journal)
table structure? What data flows into it from MM, PP, SD, and CO? How does
it eliminate the FI/CO separation compared to ECC? What are the key fields,
CDS views, and BAdIs for extending or querying it for custom reporting?
```

**The procure-to-pay handoff:**

```
Use the s4 tool: Walk me through how a purchase order created and approved
in SAP Ariba flows into S/4HANA for goods receipt and invoice posting. What
are the key integration objects, API endpoints, S/4 tables, and handoff
points? Where do P2P integrations most commonly break, and what should an
AI agent monitor to detect issues early?
```

Grounded answers from a working session: [reference/grounded-answer-acdoca.md](reference/grounded-answer-acdoca.md) and [reference/grounded-answer-p2p.md](reference/grounded-answer-p2p.md).

## Track C — Run: process intelligence, unscripted

The run-time frontier: what would an agent watch in a live system? Ask about status fields for stuck sales orders, blocked invoices, failed deliveries; which tables record goods-receipt vs invoice-receipt mismatches; what events could trigger alerts. This track is deliberately open — there is **no reference output**, and answers here vary more than in the other tracks. That makes it the best place to practice the comparison: ask Claude to separate the structural claims (tables, status fields) from the interpretive ones, and for every monitoring claim, ask yourself what you'd check in a real system before paging someone at 2 AM.

## Track D — Bring your own scenario

Ask about the system area you actually work in. Prompt-crafting tips that consistently pay off:

- **Ask for structure explicitly**: "...include the package, key fields, and release state" turns a prose answer into a verifiable one.
- **Iterate**: each answer names objects; the next question should pick one up ("what are the parameters of...", "which tables does ... read from", "what navigates to ...").
- **Try the `cap` tool** if you build on BTP: CDS modeling, service definitions, annotations — e.g. `Use the cap tool: how do I model a composition of aspects for an orders entity, and what does the generated service look like?`
- **Probe the limits**: ask something you know well and grade the answer. Finding where grounding ends is as valuable as finding where it starts.

## Summary

You've run the full lifecycle against the SAP Domain Models: explored a subsystem from its real structure, built a plan whose claims carry evidence, and tested the boundaries yourself. The pattern to take home: pair a general model you direct with a domain model you verify against — and keep the comparison habit.
