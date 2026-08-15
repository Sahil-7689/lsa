# HabotConnect Mock Compliance REST API

> **Notice:** This is a **Local Mock REST API** used to demonstrate the required API contract and fail-closed integration behavior for the HabotConnect HPF Technical Assignment. It does not represent HabotConnect's production infrastructure.

---

## 1. Quick Start

### Installation
```bash
cd mock_backend
npm install
```

### Start Server
```bash
npm start
```
The server will start on `http://localhost:3000` (and `http://10.0.2.2:3000` for Android Emulator).

---

## 2. API Contract

### Endpoint
`POST /v1/compliance/verify`

### Required Request Headers
| Header | Value | Description |
| :--- | :--- | :--- |
| `Content-Type` | `application/json` | Mandated JSON payload type |
| `x-trace-id` | `<UUID v4>` | Fresh, dynamically generated trace ID per request |
| `x-logic-hash` | `<SHA-256>` | Cryptographic hash representing logic & schema version |

*If either header is missing, the server responds with **HTTP 400 Bad Request**.*

---

### Request Body
```json
{
  "predecessor_id": "PRED-9982-XYZ",
  "lsa_id": "LSA-7049",
  "parent_consent_code": "PCC-2026-9901",
  "timestamp_utc": "2026-08-07T11:30:00Z"
}
```

---

## 3. Response Scenarios

### Case 1: Valid Verification (HTTP 200)
```json
{
  "status": "success",
  "verification_id": "VER-84920",
  "processed_at": "2026-08-07T11:30:01.120Z"
}
```

### Case 2: Missing Data Lineage (HTTP 422)
When `predecessor_id` is omitted or empty:
```json
{
  "status": "quarantined",
  "reason": "missing_predecessor_id"
}
```

### Case 3: Test Failure Simulation (HTTP 500)
When `parent_consent_code` is set to `"FAIL-500"`:
```json
{
  "status": null,
  "error": "SIMULATED_INTERNAL_COMPLIANCE_ERROR",
  "message": "Simulated 500 failure for testing frontend Fail-Closed quarantine."
}
```
