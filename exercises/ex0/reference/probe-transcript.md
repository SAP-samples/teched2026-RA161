# Reference transcript — Getting Started probe calls

Captured from a working session. Your wording will differ; what matters is the
shape: specific objects, package attributions, and explicit statements about
what the evidence does or does not establish.

## Probe 1 — `s4` tool

**Prompt**

> Use the s4 tool: what is table VBAK? One sentence.

**Response**

> Table VBAK is the Sales Document Header Data table in package VA.

Note the package attribution (VA) — a data-dictionary fact, not prose about SAP.

## Probe 2 — `ariba` tool

**Prompt**

> Use the ariba tool: which endpoint retrieves a vendor's certificates in the Supplier Data API with Pagination? One sentence.

**Response**

> The `supplierdatapagination_v4` API exposes `GET /vendors/{vendorId}/certificates`
> ("Fetch Certificate by SMVendorID") to retrieve a vendor's certificates.

Note the structural attribution: a definite path, HTTP method, and API package —
facts you can check against the API definition, not prose about what the API does.
