# Credit-limit read investigation

After [Getting Started](../../exercises/ex0/README.md), paste this prompt into Claude Code.

```text
Our credit manager has a file of 50,000 requested credit-limit changes. Before implementing the uploader, we need to find each account’s current credit limit and currency.

Use the s4 tool to answer:
How can we read these values through tables or an OData API?

Keep the answer concise. Investigate reads only: do not query customer records, upload changes or generate HTML.
```
