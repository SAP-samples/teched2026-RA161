# Exercise 1 - Explore: GL Account Determination

In this exercise, you use the `s4` domain model to explore a classic consulting question — how S/4HANA decides which GL account a vendor invoice posts to — and you learn to tell a grounded fact from a plausible guess. This is the **design time** pattern: interrogating a system area before you build anything on it.

The business setting: a customer posts a vendor invoice for IT software license costs, and you need to understand the account determination machinery well enough to explain it, debug it, or extend it.

## Exercise 1.1 Ask without grounding

First, see what a very good general-purpose model does with this question on its own. In Claude Code, ask it **not** to use any tools:

```
Without using any tools, answer from your own knowledge: in S/4HANA, which
tables and fields drive automatic GL account determination for a vendor
invoice? What function module resolves a GL account programmatically?
```

Read the answer and mark in your worksheet: which claims are hedged ("typically", "verify in your system", "the exact name may differ")? A strong general model gives you a correct *shape* — the T030 area, transaction keys — and honest uncertainty about exact names. That uncertainty is precisely what you are about to remove.

## Exercise 1.2 Ask the S/4 domain model

Now the same question, grounded. Ask Claude Code:

```
Use the s4 tool: A customer is posting a vendor invoice for IT software
license costs in S/4HANA. What tables and fields drive the automatic GL
account determination? Specifically, explain the T030 family (T030, T030A,
T030K, T030U) and the role of KTOSL transaction keys (KBS, VST, WRX, PRD,
GBB). What CDS views expose this determination data? What function module
can a partner call to programmatically resolve a GL account in custom coding?
```

This call takes a moment — the backend is traversing the knowledge graph. While it runs, predict: which of the hedged claims from 1.1 do you expect to become concrete?

## Exercise 1.3 Verify the structure

Score the grounded answer against this checklist. Everything in the first group is a **structural fact** — it comes from the data dictionary and repository, and should appear concretely:

| Look for | Why it matters |
|---|---|
| T030 key fields (KTOPL, KTOSL, BKLAS, BWMOD, KOMOK) | The actual lookup dimensions — this is what you'd debug against |
| A function module for programmatic resolution, with its package | The supported path for custom code, instead of SELECTing T030 directly |
| A second FM for invoice verification, with its package | Account determination has more than one entry point |
| Named CDS views over T030 / T030K / T030U | The modern query surface for this configuration |
| Foreign-key relationships (SKA1, T004, T005, T007A) | The graph structure around the table family |

Second group — **glosses, not facts**. If the answer explains what individual KTOSL keys *mean* (e.g. what VST or PRD stands for) or which of KONTS/KONTH is debit vs credit, log those claims in your worksheet as *leads to verify*: one-line semantic explanations are where grounded models are weakest, even when every object name around them is exact.

Compare your two answers side by side: the general model's honest hedges vs. the domain model's named objects with packages. A full grounded answer from a working session is in [reference/grounded-answer-s4.md](reference/grounded-answer-s4.md) — your run will differ in wording and possibly in which objects surface; the structural facts should hold.

**If you have time:** pick one object from the answer — a CDS view or the function module — and ask a follow-up: `Use the s4 tool: what are the parameters of <that function module>?` Grounded exploration is iterative; each answer gives you the handles for the next question.

## Summary

You've seen the core pattern: general models give you the shape with honest uncertainty, the domain model fills in verifiable structure, and your worksheet separates the two. Next, you'll turn grounded facts into something you'd hand to a customer.

Continue to - [Exercise 2 - Plan: A BTP Side-by-Side Extension](../ex2/README.md)
