# Credit-limit demo: presenter notes

Open [demo.html](demo.html) for the walkthrough. Use [prompt.md](prompt.md) for the live investigation.

**The story:** Identify the right account. Find its amount and currency. Show the API alternative. Explain what the SAP tools contributed.

Read the quoted paragraphs aloud. Bracketed text is an action for you. Allow time for pointing and clicks. You do not need to read the long table or API names aloud.

## 0:00–0:35 — The business request

[Introduce the scenario below. If you are using presentation slides, show the credit manager’s request and sample rows.]

> Our credit manager wants to change 50,000 credit limits. Before we build the uploader, we need to read the current limits and their currencies.
>
> Our question is simple: which SAP objects and interfaces let us read those values?

## 0:35–0:45 — Start the investigation

[Switch to Claude Code and submit the prompt from [prompt.md](prompt.md). Leave it running in the background.]

> Let’s ask the S/4 tools. While they investigate, I’ll use this prepared page to explain our earlier findings.

## 0:45–1:10 — Identify the account

[Open the HTML on **Read from tables**. Point to **Business partner + Credit segment → Credit account**. The Credit account object is selected by default.]

> First, which account do we mean?
>
> Here, the business partner is the customer. A credit segment is an area where credit is managed separately.
>
> The same customer can have different limits in different segments. So we need both the partner and the segment to identify the right account.

## 1:10–1:45 — Find the amount and currency

[Point to **Credit account**, then the right-hand field **Existing credit-limit amount**.]

> The tools found this account table and the field that stores the current limit.

[Click **Credit segment**. Point to **Configured segment currency** on the right.]

> The currency comes from the segment configuration. Now we know how to read the amount and understand its currency.
>
> This is the ontology idea in this example: understanding the objects and how they relate.

## 1:45–2:35 — Show the API alternative

[Click **Read through OData**. Point to the single service card, then **Provide** and **Receive**. Keep the code and metadata sections collapsed.]

> If we are building a separate application, we can use an API. The tools found this released OData V2 service.
>
> We provide the partner and segment. One read request returns the limit and currency. The application does not need to join the tables itself.
>
> These are two options for the same task. A classic ABAP report may use the tables where access is permitted. A separate application can use the remote API, once access is set up.

## 2:35–3:00 — Explain the value

[Stay on the OData view. Return to the presentation afterward if you are using slides.]

> The tools helped us find the right account information and two ways to read it.
>
> We now know which inputs identify the account and where the amount and currency come from. That gives the developer concrete details to start implementation.

## If you lose your place

Remember these four prompts:

1. **Which account?** Partner plus segment.
2. **Which values?** Amount on the account, currency from the segment.
3. **Which read option?** Tables or a remote API.
4. **What did the tools contribute?** Concrete SAP objects, fields and relationships that support the implementation choice.

## Presenter notes, not spoken

- The HTML presents saved metadata findings. It does not query customer records or upload changes. The 50,000 rows are business context, not a bulk-read performance demonstration.
- The account/segment diagram explains table keys and foreign-key metadata. It is a prepared business explanation, not a formal ontology exported by the graph.
- The table names are UKMBP_CMS_SGM and UKMCRED_SGM0C. The amount field is CREDIT_LIMIT and the currency field is CURRENCY. The business key is partner plus segment within an SAP client; the physical table key also includes CLIENT.
- The service is API_CRDTMBUSINESSPARTNER. The entity set is CreditManagementAccount. Provide BusinessPartner and CreditSegment, and read CreditLimitAmount and CreditSegmentCurrency.
- Service, entity and property metadata came from earlier S/4 tool findings. SAP documentation confirms the keys in the illustrative GET URL. The GET example has not been executed.
- RELEASED metadata does not establish activation or access in the target system. These require verification before implementation.
- Use the prompt from [prompt.md](prompt.md). Open the prepared HTML at 0:45 whether or not the live investigation has finished. Do not show the generated answer during this walkthrough.
- If the live connection fails, say: “The live connection is unavailable. I’ll continue with the prepared findings.”
