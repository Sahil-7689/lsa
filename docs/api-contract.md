# HabotConnect HPF — REST API Contract

> **Context:** This specification defines the HTTP contract between the Flutter Mobile Client and the Compliance Verification Service. In development and testing, a lightweight Node.js/Express mock server implements this contract.

---

## 1. Endpoints & Base URLs

| Environment | Base URL | Usage |
| :--- | :--- | :--- |
| **Production** | `https://api.habotconnect.com` | Production compliance infrastructure |
| **Android Emulator** | `http://10.0.2.2:3000` | Local Android Emulator loopback |
| **Desktop / Web / Tests** | `http://localhost:3000` | Local development and headless testing |

---

## 2. Verification Endpoint

### `POST /v1/compliance/verify`

Submits an LSA record for compliance verification and lineage validation.

#### Mandated Request Headers

| Header | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `Content-Type` | `string` | Content MIME type | `application/json` |
| `x-trace-id` | `UUID v4` | Unique request trace ID | `4b4aa921-c787-4167-a2f3-bd45918e987d` |
| `x-logic-hash` | `SHA-256` | 64-char hex hash of client logic | `02819bab8b3825f5cfe63f0fd625f37915c4a50034cb84d7162efa483c3b91bd` |

*Note: Missing either `x-trace-id` or `x-logic-hash` triggers HTTP 400.*

---

#### Request Body
```json
{
  "predecessor_id": "PRED-9982-XYZ",
  "lsa_id": "LSA-7049",
  "parent_consent_code": "PCC-2026-9901",
  "timestamp_utc": "2026-08-15T12:00:00.000Z"
}
```

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `predecessor_id` | `string` | **Yes** | Ancestral lineage identifier. If missing, request fails closed. |
| `lsa_id` | `string` | **Yes** | Identifier of the current LSA onboarding node. |
| `parent_consent_code` | `string` | **Yes** | Verification consent code entered by user. |
| `timestamp_utc` | `ISO 8601` | **Yes** | UTC timestamp of request generation. |

---

## 3. Responses

### 200 OK — Successful Verification
Returned when all headers, lineage requirements, and payload values are valid.
```json
{
  "status": "success",
  "verification_id": "VER-84920",
  "processed_at": "2026-08-15T12:00:01.120Z"
}
```

---

### 400 Bad Request — Missing Headers or Invalid Payload
Returned when mandatory headers or non-lineage payload fields are missing.
```json
{
  "status": "error",
  "code": "MISSING_MANDATORY_HEADERS",
  "message": "Outbound compliance request rejected. Missing required headers: x-trace-id, x-logic-hash",
  "missingHeaders": ["x-trace-id", "x-logic-hash"]
}
```

---

### 422 Unprocessable Entity — Missing Lineage (Fail-Closed)
Returned when `predecessor_id` is omitted or empty.
```json
{
  "status": "quarantined",
  "reason": "missing_predecessor_id"
}
```

---

### 500 Internal Server Error — Compliance Failure Simulation
Triggered when `parent_consent_code` is `"FAIL-500"`.
```json
{
  "status": null,
  "error": "SIMULATED_INTERNAL_COMPLIANCE_ERROR",
  "message": "Simulated 500 failure for testing frontend Fail-Closed quarantine."
}
```
