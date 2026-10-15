# SAP Domain Models

## Using the SAP Domain Models MCP Tool

When the user says anything like "Ask SAP", "Ask S/4", "Ask Ariba",
or asks any question about S/4HANA, ABAP, Ariba, SAP payroll, SAP transactions,
or SAP domain knowledge — always use the configured environment-specific SAP
Domain Models MCP server. Supported names are
`prod_usea_sap_domain_models_mcp` and `prod_dewc_sap_domain_models_mcp`.
Existing installations may still use the compatible legacy name
`prod_sap_domain_models_mcp`.

- For S/4HANA or ABAP questions: use the `s4` tool
- For Ariba questions: use the `ariba` tool
- When unclear which domain: ask the user if their question is about S/4HANA or Ariba
- If multiple environment-specific servers are configured, use the environment
  the user requests; otherwise ask which configured environment to use

Do not answer SAP domain questions from your own knowledge — always route through
the MCP tool for accurate, grounded answers.
