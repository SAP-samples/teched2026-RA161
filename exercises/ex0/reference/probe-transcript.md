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

> Use the ariba tool: which API creates a supplier in Ariba SLP? One sentence.

**Response**

> Based on the provided API descriptions, SupplierProfileImport (SOAP, operation
> SupplierProfileImportOperation) is the only API whose name and operation imply
> creating/importing a supplier; however, the description field is empty and does
> not explicitly state this.

Note the evidence-bound honesty: the model names the specific API and operation,
and says exactly what the retrieved evidence does not confirm.
