This walkthrough traces the end-to-end procurement integration from SAP Ariba through S/4HANA, covering the purchase order handoff, goods receipt, and supplier invoice posting stages.

### 1. Purchase Order Handoff (Ariba → S/4HANA)

Once a purchase order is approved in SAP Ariba, it is transmitted to S/4HANA. The grounded evidence identifies the following service bindings that expose purchase-order data in S/4HANA:

| Service Binding | Description | Protocol | Release State | Package |
|---|---|---|---|---|
| SRVB:API_PURCHASEORDER_2 | OData service for Purchase Order | V4 | RELEASED | ODATA_MM_PUR_PO_API_2 |
| SRVB:API_CFINRPLDPURCHASEORDER | service binding for API_CFINRPLDPURCHASEORDER | V4 | NOT_RELEASED | FINS_CFIN_ACC_VIEW_EX |
| SRVB:API_ACMPURCHASEORDER | Purchase Order | V4 | NOT_RELEASED | ODATA_ACM_PO |
| SRVB:API_DIGITALVEHPURCHASEORD | Srv Binding for Digital Veh Purchase Order | V4 | RELEASED | ISAUTO_VLC_LEAN |

The released, general-purpose purchase-order API is **SRVB:API_PURCHASEORDER_2** (package ODATA_MM_PUR_PO_API_2, protocol V4). A digital-vehicle-specific variant, **SRVB:API_DIGITALVEHPURCHASEORD**, is also released. Several other bindings (central purchase order, accounting view, spend query, mass update, value query) exist but are not released for external consumption.

The behavior definition **BDEF:A_PURCHASEORDER_2** governs the purchase-order root entity and is implemented by class `CL_MM_PUR_PO_BIL_ODATA_API_2`. This same behavior definition also covers sub-entities for items, schedule lines, notes, partners, account assignments, invoicing plans, subcontracting components, supplier addresses, delivery addresses, and pricing elements.

### 2. Goods Receipt Posting

After the purchase order exists in S/4HANA, a goods receipt can be posted against it. The grounded evidence identifies:

- **Service Binding**: SRVB:API_SSPOPENITMGOODSRECEIPT (package ODATA_MM_PUR_CONFIRM_PR_API, protocol V4, release state RELEASED).
- **Entity Set**: `A_SSPOpenItemGoodsReceipt` (description: "Goods Receipt Confirmation"). The entity is read-only (creatable: false, deletable: false, updatable: false) with 17 properties.
- **Action**: `PostGoodsReceipt` — a bound OData action on the entity type `A_SSPOpenItemGoodsReceiptType`, returning type `MMPUR_S_GR_OUT`.

The behavior definition **BDEF:R_SSPOPENITEMGOODSRECEIPTTP** is implemented by class `CL_MM_BP_R_SSPOPNITMGDSRCPTTP`.

### 3. Supplier Invoice Posting

The graph did not surface a released supplier-invoice API for creation or posting. The only invoice-related service found is:

- **GWSV:API_SUPPLIERINVOICE_PROCESS_SRV** — release state is not recorded in the evidence. Its entity sets are all read-oriented (creatable: false, deletable: false, updatable: false) and include:
  - `A_SupplierInvoice` — reads supplier invoice data (navigates to tax, withholding tax, item-level views for asset/material/GL account posting, delivery notes, purchasing documents, service entry sheets, and additional data).
  - `A_SuplrInvcHeaderWhldgTax` — withholding tax at header level.
  - `A_SuplrInvcItemPurOrdRef` — item-level purchase order reference.
  - `A_SuplrInvcItemAcctAssgmt` — account assignment per item.
  - `A_SuplrInvcSeldPurgDocument` — selected purchasing documents.
  - `A_SuplrInvcSeldInbDeliveryNote` — selected inbound delivery notes.
  - `A_SuplrInvcSeldSrvcEntrShtLean` — selected lean service entry sheets.
  - `A_SuplrInvoiceAdditionalData` — additional invoice data.
  - Item-level views for asset posting (`A_SupplierInvoiceItemAsset`), GL account posting (`A_SupplierInvoiceItemGLAcct`), and material posting (`A_SupplierInvoiceItemMaterial`).
  - `A_SupplierInvoiceTax` — tax data.

Because no released invoice-creation endpoint is confirmed, tenant/version verification is required before assuming write capability.

### 4. Key S/4HANA Tables (Persistence & Diagnostics)

The trace-to-tables results reveal the following persistence anchors:

**Purchase Order path** (root SRVB:API_PURCHASEORDER_2):
- TABL:EKKO (PO header), TABL:EKPO (PO item), TABL:EKET (schedule lines), TABL:EKPA (partners), TABL:T161 (purchasing document types).
- Also reachable: TABL:AUFK (internal orders), TABL:AFKO/AFVC/AFVU/AFVV (production order data via subcontracting), TABL:MARA (material master), TABL:LFA1 (supplier master).

**Goods Receipt path** (root SRVB:API_SSPOPENITMGOODSRECEIPT):
- TABL:MSEG (material document segment), TABL:MKPF (material document header).
- Referenced via: TABL:EKKO, TABL:EKPO, TABL:EBAN (purchase requisition), TABL:MARA, TABL:T006/T006A/T006D/T006I/T006J/T006T (units of measure), TABL:T002/T002T (language).

**Supplier Invoice path** (root GWSV:API_SUPPLIERINVOICE_PROCESS_SRV):
- TABL:RBKP (invoice document header), TABL:RSEG (invoice document item), TABL:RBCO (invoice company code data), TABL:RBMA (material valuation), TABL:RBSELBEST (PO reference), TABL:RBSELERFB_NEW (PO history), TABL:RBSELLIFS (service entry sheet reference).
- Also reachable: TABL:LFA1 (supplier master), TABL:BNKA/BNKAIN (bank master), TABL:EKPO (PO item), TABL:MARA (material master), TABL:PRPS (WBS element).

**Accounting document headers** (from search_nodes):
- TABL:BKPF (accounting document header), TABL:BKPF_ADD (additional fields), TABL:ARIX_BKPF (archive index).

### 5. Handoff Points and Common Breakpoints

| Stage | Handoff | Common Breakpoint |
|---|---|---|
| PO creation | Ariba → S/4HANA API call | Payload mapping errors, missing master data (supplier in LFA1, material in MARA), authorization failures |
| Goods receipt | S/4HANA OData action `PostGoodsReceipt` | Unit-of-measure conversion (T006 family), stock type mismatches, missing PO reference in EKPO |
| Invoice posting | S/4HANA invoice service | Missing GR reference, withholding tax config (RBCO), GL account determination, PO history update (RBSELERFB_NEW) |

### 6. AI-Agent Monitoring Design

An AI agent monitoring this P2P integration should track:

1. **Correlation IDs** — Map the Ariba PO number to the S/4HANA purchase-order number (EKKO) and correlate goods-receipt material documents (MKPF/MSEG) and invoice documents (RBKP/RSEG).
2. **Status transitions** — Monitor PO item status in EKPO, GR posting confirmation (MMPUR_S_GR_OUT return), and invoice verification status.
3. **Retries & idempotency** — Track duplicate payload submissions; the OData V4 protocol supports idempotency tokens.
4. **Master-data validation** — Verify supplier exists in LFA1, material in MARA, and plant/storage-location assignments before posting.
5. **Business-rule validation** — Check account assignments (EKPA), pricing elements, and schedule-line quantities against the PO.
6. **Queues & logs** — Monitor OData request logs and any middleware queues for failed deliveries.
7. **Reconciliation KPIs** — Compare Ariba-approved amounts against S/4HANA PO values, GR quantities against PO schedule lines, and invoice amounts against GR/IR balances.

### Important Notes

- The exact Ariba realm, tenant integration mechanism, and middleware mappings are configuration-dependent and not captured in the grounded evidence.
- Classic table names (EKKO, MKPF, RBKP, etc.) serve as persistence and diagnostic anchors but are not integration contracts; the released OData service bindings are the supported integration surface.
- For S/4HANA Cloud, compatibility-view considerations apply to material-document tables (MSEG/MKPF); use the released APIs rather than direct table access.
- The supplier-invoice service (GWSV:API_SUPPLIERINVOICE_PROCESS_SRV) exposes only read entities in this evidence snapshot; confirm write endpoints via tenant-specific metadata.
