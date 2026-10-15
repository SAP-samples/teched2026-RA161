For a BTP side-by-side read-only extension that needs purchase order details including account assignment, use **OData V4** via the released service **API_PURCHASEORDER_2**.

### Recommended Service

| Attribute | Value |
|-----------|-------|
| Service Binding | SRVB:API_PURCHASEORDER_2 |
| Protocol | OData V4 |
| Release State | RELEASED |
| Package | ODATA_MM_PUR_PO_API_2 |
| Description | OData service for Purchase Order |

The search results show multiple purchase-order services (e.g., API_ACMPURCHASEORDER, API_CFINRPLDPURCHASEORDER, UI_CFINRPLDPURCHASEORDER, UI_PURCHASEORDERACCRS_DSP), but these are either NOT_RELEASED, use OData V2, or serve specialized scenarios such as accounting-view or accruals display. API_PURCHASEORDER_2 is the only candidate with releaseState RELEASED and is therefore the grounded recommendation for stable consumption.

### Entity Sets and Navigation Relationships

The service exposes at least 13 entity sets. The primary entities relevant to your read scenario are:

| Entity Set | Description | CUD Capabilities |
|------------|-------------|------------------|
| PurchaseOrder | Header-level purchase order | Creatable: null, Deletable: null, Updatable: null |
| PurchaseOrderItem | Line items | Creatable: false, Deletable: null, Updatable: null |
| PurchaseOrderAccountAssignment | Account assignment (cost center, GL account, etc.) | Creatable: false, Deletable: false, Updatable: null |
| PurchaseOrderScheduleLine | Schedule lines (delivery dates, quantities) | Creatable: false, Deletable: false, Updatable: null |

**Navigation paths (from metadata):**

- **PurchaseOrder** navigates to `_PurchaseOrderItem`, `_PurchaseOrderNote`, `_PurchaseOrderPartner`, and `_SupplierAddress`.
- **PurchaseOrderItem** navigates to `_PurchaseOrder`, `_PurOrdAccountAssignment`, `_PurchaseOrderInvoicingPlan`, `_PurchaseOrderItemNote`, `_PurchaseOrderScheduleLineTP`, `_DeliveryAddress`, and `_PurOrdPricingElement`.
- **PurchaseOrderAccountAssignment** navigates to `_PurchaseOrder` and `_PurchaseOrderItem`.
- **PurchaseOrderScheduleLine** navigates to `_PurchaseOrder`, `_PurchaseOrderItem`, and `_SubcontractingComponent`.

To read a purchase order with its account assignments in a single request, navigate from PurchaseOrder through `_PurchaseOrderItem` to `_PurOrdAccountAssignment`.

### Key and Filter Fields

Based on the retrieved property metadata, the following fields appear on the relevant entities and are suitable for filtering:

| Entity | Key / Non-Nullable Fields | EDM Type | Max Length |
|--------|---------------------------|----------|------------|
| PurchaseOrder | PurchaseOrder | Edm.String | 10 |
| PurchaseOrder | PurchaseOrderType | Edm.String | 4 |
| PurchaseOrder | PurchaseOrderSubtype | Edm.String | 1 |
| PurchaseOrder | PurchaseOrderDeletionCode | Edm.String | 1 |
| PurchaseOrder | PurchaseOrderDate | Edm.Date | — |
| PurchaseOrderItem | PurchaseOrder | Edm.String | 10 |
| PurchaseOrderItem | PurchaseOrderItem | Edm.String | 5 |
| PurchaseOrderItem | PurchaseOrderCategory | Edm.String | 1 |
| PurchaseOrderItem | PurchaseOrderItemCategory | Edm.String | 1 |
| PurchaseOrderItem | AccountAssignmentCategory | Edm.String | 1 |
| PurchaseOrderAccountAssignment | PurchaseOrder | Edm.String | 10 |
| PurchaseOrderAccountAssignment | PurchaseOrderItem | Edm.String | 5 |
| PurchaseOrderAccountAssignment | AccountAssignmentNumber | Edm.String | 2 |
| PurchaseOrderScheduleLine | PurchaseOrder | Edm.String | 10 |
| PurchaseOrderScheduleLine | PurchaseOrderItem | Edm.String | 5 |
| PurchaseOrderScheduleLine | ScheduleLine | Edm.String | 4 |

**Usage pattern (example URL structure):**
```
/sap/opu/odata4/sap/api_purchaseorder_2/srvd_a2x/sap/api_purchaseorder_2/0001/PurchaseOrder(PurchaseOrder='4500000001')/_PurchaseOrderItem?
```
This is a structural pattern; actual key syntax depends on the service binding's exact metadata document.

### Authorization and Security

The authorization trace for SRVB:API_PURCHASEORDER_2 shows DCLS (Data Control Language Security) entries for the underlying views such as A_PURCHASEORDER_2, A_PURCHASEORDERITEM_2, A_PURORDACCOUNTASSIGNMENT_2, and A_PURCHASEORDSCHEDULELINE_2. However, these DCLS entries have empty authObjects, meaning no specific authorization object names or field-level ACTVT values are recorded in the trace for these views. Additionally, the SU24 transaction authorization results are empty.

**What Basis should validate:**

1. **Service communication arrangement** — Ensure the BTP destination is mapped to a communication scenario that exposes API_PURCHASEORDER_2, and that the technical communication user has the necessary ICF service activation.
2. **Runtime authorization trace (ST01/STAUTHTRACE)** — Because the DCLS metadata does not expose concrete authorization objects, Basis should run a live trace during an actual API call to capture which authorization objects (and field values) are checked at runtime.
3. **DCL restrictions** — Even though the DCLS entries show empty authObjects in the evidence, the presence of DCLS artifacts (e.g., A_PURCHASEORDER_2) means that row-level access control is implemented. The actual restriction logic (organizational filtering by purchasing organization, plant, etc.) is enforced within the CDS access control layer.

Distinguish between **API-level read access** (which requires the service to be activated and the user to have basic OData consumption authorization) and **business authorization/DCL restrictions** (which control which purchase orders the caller can see based on organizational assignments).

### Underlying Table Lineage

The trace-to-tables evidence shows that the behavior definitions implemented by class CL_MM_PUR_PO_BIL_ODATA_API_2 persist to or read from the following tables:

- **EKKO** (Purchase Order Header) — reached via 3 hops through the CDS views.
- **EKPO** (Purchase Order Item) — reached via 3 hops.
- **EKET** (Schedule Lines) — reached via 4 hops.

The table EKKN (account assignment) is not exposed in the filtered lineage evidence, so its presence as a direct data source for the PurchaseOrderAccountAssignment entity cannot be confirmed from the available data.
