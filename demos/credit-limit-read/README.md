# Find the right credit limit

A three-minute SAP Domain Models example: discover how to read a credit account’s current limit and currency through SAP S/4HANA tables or an OData API.

## Business scenario

A credit manager has a file of 50,000 requested credit-limit changes. Before implementing an uploader, a developer needs to identify each account and find its existing limit and currency. This exercise focuses on discovering the read interfaces. It does not implement the uploader or demonstrate the performance of reading 50,000 rows.

## Files

| File | Purpose |
| --- | --- |
| [prompt.md](prompt.md) | The short investigation prompt used in the presentation |
| [demo.html](demo.html) | Prepared, interactive walkthrough of the findings |
| [presenter-notes.md](presenter-notes.md) | Three-minute talk track and click cues |

## Try the exercise

1. Complete [Getting Started](../../exercises/ex0/README.md) to connect Claude Code to the SAP Domain Models MCP server and verify the `s4` tool. Access is required for the investigation, but not for the HTML walkthrough.
2. Paste the prompt from [prompt.md](prompt.md) into the client.
3. In the repository copy you downloaded during Getting Started, open `demos/credit-limit-read/demo.html` in a browser. The page is self-contained and needs no build step. GitHub’s source-file preview shows the HTML code; open the local file to use the interactive page.
4. Explore **Read from tables**: select the credit account and credit segment to see their fields. Then select **Read through OData** to compare the API option.

For a presentation, start the investigation and open the prepared HTML after about 45 seconds. The HTML shows saved findings; it is not updated by the running agent.

## What the example illustrates

- A business partner and credit segment identify a credit account within an SAP client.
- The table option identifies `UKMBP_CMS_SGM.CREDIT_LIMIT` and the segment currency in `UKMCRED_SGM0C.CURRENCY`. Classic ABAP table access depends on what the target environment permits.
- The API option identifies `API_CRDTMBUSINESSPARTNER` (OData V2), the `CreditManagementAccount` entity, the `BusinessPartner` and `CreditSegment` keys, and the `CreditLimitAmount` and `CreditSegmentCurrency` response properties.
- The business diagram explains the retrieved technical metadata. It is not a formal ontology exported by the graph.

The page records findings retrieved on 15 October 2026 and distinguishes graph metadata from the SAP documentation used to confirm the example GET request. The request uses illustrative identifiers and has not been executed. A service’s released status does not establish activation or access in a particular system.

The investigation prompt requests metadata only. The HTML does not query customer records, upload changes, or call an SAP service. Credentials are configured separately in the AI client.
