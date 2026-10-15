Automatic GL account determination for vendor invoice posting relies on a family of customizing tables in package FBAS, transaction keys that classify posting operations, and CDS views that expose this configuration.

### T030 Table Family

The T030 family stores the rules that map a combination of account determination keys to specific GL accounts:

| Table | Purpose | Key Fields |
|-------|---------|------------|
| **T030** | Master account determination table (Fixkontentabelle) | KTOPL, KTOSL, MANDT, BKLAS, BWMOD, KOMOK |
| **T030A** | Transaction key assignment to groups (Vorgangsschlüssel und Zuordnung zu Gruppen) | KTOSL, MANDT, GRUPP, INT, TCODE, F1BKL, F1BWM, F1KOM, F4BKL, F4BWM, F4KOM |
| **T030K** | Tax account determination (Kontenfindung Steuerkonten) | MANDT, KTOPL, KTOSL, LAND1, MWSKZ |
| **T030U** | Balance sheet transfer account determination (Kontenfindung für Bilanzumbuchungen) | MANDT, KTOPL, KTOSL, KORRK, ZIELK, BWBER |

**T030** is the central table. Its fields KTOSL (transaction key) and KTOPL (chart of accounts) drive the lookup, while KONTH and KONTS hold the debit and credit GL account numbers respectively. The table has foreign keys to SKA1 (GL account master) via fields KONTS and KONTH, and to T004 (chart of accounts directory) via KTOPL.

**T030A** assigns transaction keys to processing groups. Its field KTOSL links back to T030 via a foreign key, and TCODE references transaction codes in table TSTC.

**T030K** extends determination with tax-specific criteria: LAND1 (country) references T005, and MWSKZ (tax code) references T007A. The KONTH and KONTS fields both have foreign keys to SKA1.

**T030U** adds balance-sheet-specific keys: KORRK (correction key) and ZIELK (target key) both reference SKA1, while BWBER references valuation area table T033.

### KTOSL Transaction Keys

The transaction key (KTOSL) classifies the nature of a posting line. Based on the evidence:

- **KBS** – Used in the context of account determination (referenced by CDS view I_RetainedEarningsGLAccount).
- **VST** – Sales-related transaction key.
- **WRX** – Goods receipt/invoice receipt clearing.
- **PRD** – Production-related posting.
- **GBB** – Offsetting entry for inventory movements.

These keys serve as the primary lookup dimension in T030 when the system resolves which GL account to post to for a given business event.

### CDS Views Exposing Account Determination

Several CDS views provide analytical or operational access to account determination data:

- **Fac_Ad_Cds_T030** – Directly reads from T030.
- **Fac_Ad_Cds_T030k** – Reads tax account determination from T030K.
- **FAC_AD_CDS_T030U** – Reads balance sheet transfer accounts from T030U.
- **I_RetainedEarningsGLAccount** – Exposes retained earnings GL accounts using transaction key KBS.
- **I_TransactionTypeStdGLAcct** – Provides standard GL account mappings by transaction type.
- **fco_grir_accnt_det_view** – GR/IR account determination view.
- **fgl_bcf_acc** – Balance carry-forward account view.
- **fisvd_glacct_coa** – GL account by chart of accounts.
- **I_SAFTTaxAcctDetermination** – SAF-T tax account determination.
- **Fac_Ad_Cds_Apar_Key_U** – Reads both T030A and T030U for AP/AR key resolution.

### Function Modules for Programmatic Resolution

For custom coding, the following function modules can be called to resolve GL accounts:

- **FI_STANDARD_ACCOUNT_DETERMINE** – Standard automatic account determination logic; reads T030 and related tables.
- **MR_ACCOUNT_ASSIGNMENT** – Determines account and posting key during invoice verification (package MRM); described as "Ermittlung des Kontos und des Buchungsschlüssels."
- **ACCOUNT_DETERMINATION_REPLACE** – Replaces account symbols with actual GL accounts (package FBAS).
- **ACCOUNT_ALLOCATION** / **ACCOUNT_ALLOCATION_GENERAL** – General account determination entry points (package ACCOUNT_DETERMINATION).
- **FI_ACCT_DET_HR** – Account determination for HR-related postings.
- **FAGL_GL_STAMM_CHECK** – Validates GL master data consistency during account determination.

All of these function modules read T030 and/or its satellite tables to resolve the correct GL account for a given transaction key and chart of accounts combination.
