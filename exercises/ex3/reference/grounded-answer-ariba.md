## Recommended API Sequence and Integration Pattern

### Step 1: Authenticate and Obtain Access Token
- **OAuth Scope Required**: `supplierdatapagination:read`
- **Purpose**: All subsequent calls to the Supplier Data API With Pagination require this scope.

### Step 2: Retrieve Supplier Organization and Qualification Status
- **API**: `supplierdatapagination_v4`
- **Endpoint**: `POST /vendorDataRequests/`
- **Request Body Filters** (to narrow to the specific supplier):
  ```json
  {
    "smVendorIds": ["<supplier_sm_id>"],
    "qualificationStatusList": ["Qualified", "Unqualified", "Pending"],
    "withQuestionnaire": true,
    "withGenericCustomFields": true,
    "withDisqualifications": true
  }
  ```
- **Query Parameters**:
  - `realm=<your_realm>` (required)
  - `$count=true` (optional, to know total records)
- **Response**: Contains vendor details, qualification status, and registration status.

### Step 3: Retrieve Active Processes for the Supplier
- **API**: `supplierdatapagination_v4`
- **Endpoint**: `GET /vendors/{vendorId}/processes`
- **Query Parameters**:
  - `realm=<your_realm>` (required)
  - `$skip` (omit for first page)
- **Response**: List of processes; use `pageToken` from response to fetch subsequent pages via `$skip`.

### Step 4: Retrieve Qualification Evidence (Certificates)
- **API**: `supplierdatapagination_v4`
- **Endpoint**: `GET /vendors/{vendorId}/certificates`
- **Purpose**: Fetch certificate details that evidence qualification status.
- **Pagination**: `$top` (max 100), `$skip` for subsequent pages.

### Step 5: Retrieve Questionnaire Data
- **API**: `supplierdatapagination_v4`
- **Endpoint**: `GET /vendors/{vendorId}/workspaces/questionnaires`
- **Purpose**: List modular questionnaires for the supplier.
- **Pagination**: `$top` (max 5), `$skip` uses `pageToken` from response.

To fetch answers for a specific questionnaire:
- **Endpoint**: `GET /vendors/{vendorId}/workspaces/questionnaires/{questionnaireId}/qna`
- **Pagination**: `$top` (max 100), `$skip` for subsequent pages.

To fetch scoring data:
- **Endpoint**: `GET /vendors/{vendorId}/workspaces/questionnaires/{questionnaireId}/scores`

### Step 6: Optional Risk Engagement Data
- **API**: `risk_engagement`
- **Endpoints**:
  - `GET /engagements` — Engagement projects
  - `GET /issues` — Issues
  - `GET /questionnaires` — Modular questionnaires from risk perspective

## Pagination Summary

| Endpoint | Page Size | Token Mechanism |
|----------|-----------|------------------|
| `POST /vendorDataRequests/` | 500 | `X-Pagination-Token` header or `pageToken` body → use as `$skip` |
| `GET /vendors/{vendorId}/processes` | 100 | `X-Pagination-Token` header or `pageToken` body → use as `$skip` |
| `GET /vendors/{vendorId}/workspaces` | 5 | Composite `$skip`: first char = workspace type (0–7), remainder = page token |
| `GET /vendors/{vendorId}/workspaces/questionnaires` | 5 | `X-Pagination-Token` header or `pageToken` body → use as `$skip` |
| `GET /vendors/{vendorId}/certificates` | 100 | `X-Pagination-Token` header or `pageToken` body → use as `$skip` |
| `GET .../questionnaires/{id}/qna` | 100 | `X-Pagination-Token` header or `pageToken` body → use as `$skip` |

**First page**: Omit `$skip` or pass `$skip=0`
**Subsequent pages**: Pass the `pageToken` value from the previous response as `$skip`

## Required OAuth Scopes

- **Supplier Data API With Pagination**: `supplierdatapagination:read`
- **Supplier Risk Engagements API**: `risk_engagement:read`

## Required Query Parameter for All Endpoints
- `realm` (string, required): The realm name for which the client application is authenticated. Example: `realm=testRealm`
