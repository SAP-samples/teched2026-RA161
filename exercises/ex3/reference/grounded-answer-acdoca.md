## ACDOCA – Universal Journal Entry Line Items

ACDOCA (TABL:ACDOCA, package FINS_ACDOC_DB) is the single-source-of-truth persistence table for all journal entry line items in SAP S/4HANA Finance. It replaces the separate FI and CO document tables used in ECC (BKPF/BSEG for FI, COEP/COBK for CO) by storing both financial accounting and controlling postings in one unified structure.

### Table Structure and Semantic Field Groups

The table contains a very wide set of fields (the evidence lists at least 200+ fields). Based on the grounded evidence, fields can be grouped into the following semantic categories:

| Group | Representative Fields | Purpose |
|-------|----------------------|--------|
| **Document Identity** | BELNR, DOCLN, GJAHR, RLDNR, DOCLN_LD | Accounting document number, line item, fiscal year, ledger, and ledger-specific line number |
| **Organizational / Account Assignment** | BUKRS, FIKRS, KOKRS, RBUKRS, FIKRS, KBLNR, KBLPOS, PRCTR, SEGMENT | Company code, financial management area, controlling area, budget document/item |
| **GL Account** | RACCT, RACCT_SENDER | GL account and sender GL account (via include ACDOC_SI_CFIN) |
| **Amounts / Currencies** | AMOUNTINCOMPANYCODECURRENCY, AMOUNTINFUNCTIONALCURRENCY, AMOUNTINGLOBALCURRENCY, AMOUNTINTRANSACTIONCURRENCY, AMOUNTINOBJECTCURRENCY, plus 8 free-defined currency amounts | Multi-currency amounts across parallel ledgers |
| **Asset Accounting** | ANLN1, ANLN2, ANLGR, ANLGR2, PANL1, PANL2, AFABE, ANBWA | Asset main/sub-number, group asset, depreciation area |
| **Controlling / CO-PA** | AUFPS, ARBID, ARTPR, CE4KEY, CO_BELKZ, CO_OSL, CO_ACCASTY | Order, business process, cost element, debit/credit indicator |
| **Joint Venture** | JVACTIVITY, JVACT, CBRACCT, CBRUNID, CBOBJNR, EGRUP, BTYPE, BILLM | JV activity, billing type, equity group |
| **Funds Management** | BDGT_ACCOUNT, BDGT_CNSMPN_AMOUNT_TYPE, BDGT_CNSMPN_DATE, BDGT_CNSMPN_PERIOD, BDGT_CNSMPN_TYPE, BDGT_CNSMPN_YEAR, BDGT_RELEVANT | Budget account and consumption tracking |
| **Real Estate** | DABRZ, PDABRZ, PSEMPSL, SEMPSL, SGRNR, SGENR, SMENR, SWENR, RECNNR, PRECNNR | Rental object, settlement rule, contract |
| **Material Ledger / Logistics** | ILART, ISTRU, MATKL_MM, MAUFNR, VORNR, UVORN, TPLNR, VNAME, VPTNR, EQUNR, PLKNZ, PRIOK | Activity type, material group, production order, equipment, planning indicator |
| **Valuation** | VALOBJ_ID, VALOBJTYPE, VALSOBJ_ID, VALUE_DATA, RISK_CLASS, NETDT | Valuation object identifiers and dates |
| **Technical / Migration** | _DATAAGING, MIG_DOCLN, MIG_SOURCE, SDM_VERSION, FUP_ACTION | Data aging flag, migration document reference, SDM version, follow-up action |
| **Subledger** | SUBLEDGER_AA, SUBLEDGER_CO, SUBLEDGER_COPA, SUBLEDGER_FI, SUBLEDGER_ML, SUBLEDGER_SHARED | Subledger classification |

Many fields are contributed via SAP include structures (e.g., ACDOC_SI_CFIN for sender fields, ACDOC_SI_LOG for logistics fields, ACDOC_SI_PS for public-sector fields, ACDOC_SI_JVA for joint-venture fields, ACDOC_SI_RE for real-estate fields, ACDOC_SI_VAL for valuation fields, ACDOC_SI_TECH for technical fields).

### Related Companion Tables

Several satellite tables extend or support ACDOCA:
- **ACDOCA_CLR_RDIFF** – Realized foreign currency differences in additional currency (package FINS_GL_CLEARING)
- **ACDOCA_HXF** – Historical exchange rates / T2Factors used in journal entries (package FIN_HISTORIC_EXCHANGE_RATES)
- **ACDOCA_KENC** – History table for realignment on ACDOCA (package FINS_COPA_REALIGNMENT)
- **ACDOCA_M_EXTRACT** – Extract table for Material Ledger (package FINS_ML_EXTRACT)

Foreign keys from ACDOCA reference asset master tables ANKA (field ANLKL), ANLA (fields ANLN2, PANL2, ANLGR2), and ANLH (fields PANL1, ANLN1, ANLGR).

## Data Flows into ACDOCA

ACDOCA receives postings from multiple source processes:

- **Material Management (MM)** – Goods movements and invoice verification generate FI line items that land in ACDOCA. The evidence shows logistics-oriented fields (ILART, ISTRU, MATKL_MM, MAUFNR, VORNR, EQUNR) and companion function modules COEP_UPDATE_SGTXT_MM and COEP_UPDATE_SGTXT_UJE that write ACDOCA.
- **Production Planning (PP)** – Activity confirmations and cost postings flow into ACDOCA via function module COEP_UPDATE_SGTXT_CO.
- **Sales & Distribution (SD)** – Billing documents and revenue recognition entries post to ACDOCA.
- **Controlling (CO)** – Cost allocations, assessments, and settlements write through function modules such as GLE_MCA_UPDATE_GRP_CURR (group currency update) and JV_CLEAR_EXPENSE_LINES_ACD / JV_MARK_EXPENSE_LINES_ACD (joint-venture clearing).
- **Financial Accounting (FI)** – Direct journal entries, AP/AR postings, and clearing operations (BALANCE_CLR_ON_BUZEI_BY_UPDATE, BALANCE_JOURNALENTRY_BY_UPDATE) write ACDOCA.

Function module FAGL_DELETE_ITEMS handles deletion of items; FINS_ACDOC_POSTING_INSERT and FINS_ACDOC_POSTING_DELETE_BCF manage insert and delete operations respectively.

## FI/CO Separation vs. S/4HANA Convergence

In ECC, FI and CO maintained separate document stores (BKPF/BSEG for FI, COBK/COEP for CO). S/4HANA eliminates this separation by persisting both FI and CO data in ACDOCA. The subledger fields (SUBLEDGER_FI, SUBLEDGER_CO, SUBLEDGER_COPA, SUBLEDGER_AA, SUBLEDGER_ML, SUBLEDGER_SHARED) distinguish the originating subledger within the same row. While the conceptual distinction between FI and CO remains—different valuation areas, ledgers, and controlling objects—the physical storage is unified. The companion tables (ACDOCA_KENC for CO-PA realignment, ACDOCA_CLR_RDIFF for clearing differences) handle scenarios that previously lived in separate CO or FI tables.

## CDS View Layer and Query Patterns

The evidence shows a rich set of CDS views built on top of ACDOCA:

| CDS View | Description | Role |
|----------|-------------|------|
| A_JOURNALENTRYITEMBASIC | API Journal Entry Item Basic | Released API view (authorizationCheck: CHECK); selects from I_JournalEntryItemCube; exposed via OData service API_JOURNALENTRYITEMBASIC_SRV |
| I_JOURNALENTRYITEM | Journal Entry Item | Core interface view |
| I_JOURNALENTRYITEMBASIC | Journal Entry Item Basic | Reusable interface view |
| I_JOURNALENTRYITEMCUBE | Journal Entry Item Cube | Analytical cube (select source for A_JOURNALENTRYITEMBASIC) |
| I_JOURNALENTRYITEMBROWSER | Journal Entry Item Browser | Extended browser view |
| I_JOURNALENTRYITEMITEMIZATIONC | Itemization | Itemization detail |
| I_JOURNALENTRYITEMONETIMEDATA | One-time data | One-time account data |
| I_JOURNALENTRYITEMWIP | Work In Process | WIP interface view |
| C_ACCRUALSJOURNALENTRYITEM | Accruals Journal Entry Item | Consumption view for accruals |
| C_ACCTGNOTIFJOURNALENTRY | Accounting Notification | Notification-related journal entries |
| C_ALLOCRUNJOURNALENTRYITEM | Allocation Run Journal Entry | Allocation run results |
| X_US_I_JOURNALENTRYITEM | US Federal extensions | Country-specific extension |

The CDS view A_JOURNALENTRYITEMBASIC has 160 fields and exposes associations `_CompanyCode` (to A_CompanyCode), `_CurrentCostCenter` (to A_CostCenter), `_CurrentProfitCenter` (to A_ProfitCenter), and `_GLAccountInChartOfAccounts` (to A_GLAccountInChartOfAccounts). It is not a root view and not a projection view.

For custom reporting, the recommendation is to consume released CDS views (such as A_JOURNALENTRYITEMBASIC) rather than selecting directly from ACDOCA.

## Extension Points and BAdI Guidance

Three BAdI implementation examples exist in package FINS_GEN_SUB_VAL:

- **CL_FIN_ACDOC_EXT_CHG_SUB_IM_EX** – Journal Entry Item Extension Fields Change
- **CL_FIN_ACDOC_EXT_REV_SUB_IM_EX** – Journal Entry Item Extension Fields Reversal
- **CL_FIN_ACDOC_EXT_SUB_IMPL_EX** – Journal Entry Item Extension Fields Substitution

These classes implement BAdI logic for extending journal entry items with custom fields during posting, reversal, and substitution. The exact enhancement spot or interface name is not explicitly resolved in the available evidence, so developers should use the BAdI framework documentation for the precise enhancement spot identifier.

Released extensibility (custom fields via the extensibility framework) is the preferred approach rather than direct ACDOCA modification.

## Important Caveats

- **Performance**: ACDOCA is a high-volume table. The evidence references HDB hints (`NO_JOIN_THRU_JOIN`) in CDS annotations, indicating that join performance is a design concern.
- **Authorization**: CDS views like A_JOURNALENTRYITEMBASIC specify `authorizationCheck: CHECK`, meaning access control objects are enforced at the view level.
- **Read-only SQL restriction**: The system instruction states that generated SQL must not be executed and that read-only restrictions apply; this applies to the AI assistant context.
- **Version/release**: The companion tables (ACDOCA_HXF, ACDOCA_KENC, ACDOCA_M_EXTRACT) reside in different packages and may have different release cycles than the core ACDOCA table.
