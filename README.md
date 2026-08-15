# HabotConnect HPF — LSA Verification & Data Lineage Integration

> **Hiring Project Form (HPF) Technical Submission**  
> **Target Role:** Flutter Mobile App Developer  
> **Simulation Purpose:** Demonstrates secure REST API integration, atomic Byt UI architecture, deterministic Data Lineage enforcement, Fail-Closed quarantine mechanics, and UI hesitation telemetry.  
> 🎥 **Demo Video:** [Watch Technical Demo Video](./docs/demo_video.mp4) | 📊 **Presentation Deck:** [docs/presentation.md](./docs/presentation.md)

---

## 1. Project Overview & Objective

This repository contains the complete implementation of the **HabotConnect LSA Verification & Data Lineage Integration** technical assignment.

The solution consists of:
1. **Flutter Mobile Application (`flutter_app` / root):** A stateless, modular application featuring the `LsaVerificationScreen` built using atomic Byt components.
2. **Local Mock REST Backend (`mock_backend`):** A lightweight Node.js/Express service providing the REST API contract (`POST /v1/compliance/verify`), header validation (`x-trace-id`, `x-logic-hash`), lineage validation (`predecessor_id`), and failure simulations.

---

## 2. End-to-End Architecture

```text
Flutter UI Layer (LsaVerificationScreen - StatelessWidget)
    │
    ▼
Byt Atomic UI Components
    ├── VerificationHeaderByt
    ├── StatusBannerByt
    ├── LsaIdFieldByt
    ├── ParentConsentFieldByt
    ├── PredecessorFieldByt
    ├── VerificationButtonByt
    └── SimulationPanelByt
    │
    ▼
Verification Controller (ChangeNotifier & State Orchestration)
    │
    ▼
Input Validation Gate (Empty field verification)
    │
    ▼
Data Lineage Gate (predecessor_id != null && !empty)
    ├── If Missing ──► [LineageException] ──► Fail-Closed Quarantine (NO Network Call)
    │
    ▼
Cryptographic Metadata Generation
    ├── x-trace-id: Fresh RFC 4122 UUID v4
    └── x-logic-hash: Real SHA-256 Digest
    │
    ▼
Outbound REST API (POST /v1/compliance/verify)
    │
    ▼
Mock REST Backend (Node.js / Express)
    ├── Security Header Validation (400 if missing)
    ├── Lineage Validation (422 if missing)
    └── Failure Simulation (500 if FAIL-500)
    │
    ▼
Response Validation Gate
    ├── HTTP 200 + status == 'success' ──► [Success State] (Display VER-* ID)
    └── HTTP 500 / status == null       ──► [Fail-Closed Quarantine] (Lock Submission & Clear Input)
```

---

## 3. Fail-Closed Security Implementation

Under the **Fail-Closed** security principle, the application never defaults to open access or assumes success. Any anomaly immediately halts execution and isolates data.

### The 3 Core Assignment Scenarios:

| Scenario | Input / Condition | System Behavior | Outcome |
| :--- | :--- | :--- | :--- |
| **Case 1: Valid Verification** | Valid `lsa_id`, `parent_consent_code`, `predecessor_id` | Validates lineage, generates fresh `x-trace-id` and `x-logic-hash`, executes REST call, validates HTTP 200 response. | **Success** (`VER-*` ID displayed). |
| **Case 2: Missing Lineage** | `predecessor_id == null` or empty string | `SecurityService` throws `LineageException`. **API call is strictly blocked**. Payload is quarantined. | **Quarantined (Fail-Closed)**. Form volatile data cleared. |
| **Case 3: Compliance Failure** | `parent_consent_code = "FAIL-500"` (or backend returns HTTP 500 / `status: null`) | Client detects null or invalid status. Treats response as invalid. Quarantines payload. | **Data Quarantined – Compliance Failure**. Submission locked. |

---

## 4. Friction Tracking (>5-Second Inactivity Rule)

`FrictionTracker` monitors user hesitation on the security-critical `parent_consent_code` field:
- **Timer Start:** Focus on `parent_consent_code` initiates a 5.0-second countdown.
- **Timer Reset:** User typing or keystrokes immediately reset the 5.0-second countdown.
- **Trigger Condition:** If the user stays focused without interacting or submitting for **> 5.0 seconds**, a `FrictionEvent` is generated:
  ```text
  [UI_FRICTION_LOG]
  Timestamp: 2026-08-15T12:00:00Z
  Field: parent_consent_code
  Hesitation Duration: 5.2s
  ```
- **Deduplication:** Duplicate logs for the same focus session are prevented. Blurring or submitting immediately cancels pending timers.
- **Stateless Isolation:** All timer logic lives strictly in `FrictionTracker`, keeping `LsaVerificationScreen` 100% stateless.

---

## 5. Project Directory Structure

```text
d:/flutter/
│
├── lib/
│   ├── main.dart                               # Application entry point & theme configuration
│   │
│   ├── screen/
│   │   └── lsa_verification_screen.dart        # Pure StatelessWidget (LSA Onboarding Gate)
│   │
│   ├── byts/                                   # Atomic single-responsibility UI components
│   │   ├── verification_header_byt.dart        # Screen title, subtitle & compliance badge
│   │   ├── status_banner_byt.dart              # Idle / Processing / Quarantined / Success banner
│   │   ├── lsa_id_field_byt.dart               # LSA-7049 input field
│   │   ├── parent_consent_field_byt.dart       # User-editable field with focus telemetry
│   │   ├── predecessor_field_byt.dart          # Read-only system lineage field (PRED-9982-XYZ)
│   │   ├── verification_button_byt.dart        # "Verify & Submit" CTA button
│   │   └── simulation_panel_byt.dart           # Diagnostics & preset test loader
│   │
│   ├── controllers/
│   │   └── verification_controller.dart        # State management, validation & pipeline orchestration
│   │
│   ├── models/
│   │   ├── verification_request.dart           # Request model with dynamic UTC timestamp
│   │   ├── verification_response.dart          # Response model with fail-closed validation
│   │   ├── verification_status.dart            # VerificationStatus enum
│   │   ├── quarantined_record.dart             # Audit log model for isolated records
│   │   └── friction_event.dart                 # Hesitation telemetry event model
│   │
│   ├── services/
│   │   ├── compliance_api.dart                 # Outbound REST API client with metadata headers
│   │   ├── security_service.dart               # Pre-flight lineage & format validator
│   │   ├── friction_tracker.dart               # Inactivity timer (>5s) tracker
│   │   └── quarantine_service.dart             # Fail-closed payload isolator
│   │
│   ├── exceptions/
│   │   └── lineage_exception.dart              # Thrown on missing/empty predecessor_id
│   │
│   └── utils/
│       ├── hash_utils.dart                     # Real SHA-256 deterministic logic hash generator
│       └── uuid_utils.dart                     # RFC 4122 UUID v4 trace ID generator
│
├── mock_backend/                               # Local Mock REST API Server
│   ├── src/
│   │   ├── server.js                           # Express app listening on port 3000
│   │   ├── routes/compliance.js                # POST /v1/compliance/verify route
│   │   ├── middleware/security.js              # x-trace-id and x-logic-hash header validator
│   │   └── validators/complianceValidator.js   # predecessor_id & payload validator
│   ├── test/
│   │   └── compliance.test.js                  # Backend test suite (6/6 tests passing)
│   ├── package.json
│   └── README.md
│
├── test/                                       # Flutter Automated Test Suite
│   ├── security_pipeline_test.dart             # Tests 1-5 (Valid, Missing lineage, Empty, 500, Null)
│   ├── friction_tracker_test.dart              # Test 6 (Friction >5s, typing reset, deduplication)
│   ├── lsa_verification_screen_test.dart       # Widget & UI integration tests
│   └── widget_test.dart                        # Application smoke test
│
├── docs/                                       # Technical Documentation
│   ├── architecture.md                         # Detailed architecture & component breakdown
│   ├── api-contract.md                         # REST API endpoints, headers & responses
│   └── presentation-outline.md                 # 12-slide technical presentation outline
│
├── pubspec.yaml
└── README.md
```

---

## 6. How to Run the Application

### Step 1: Start the Mock Backend
In a terminal:
```bash
cd mock_backend
npm install
npm start
```
*The server will start on `http://localhost:3000` (accessible from Android Emulator as `http://10.0.2.2:3000`).*

---

### Step 2: Run the Flutter Mobile App
In another terminal:
```bash
flutter pub get
flutter run
```
*To run specifically on the Android Emulator:*
```bash
flutter run -d emulator-5554
```

---

## 7. Running Automated Tests & Code Analysis

### Run Flutter Test Suite (15 Tests)
```bash
flutter test
```
*Covers:*
- **Test 1:** Valid submission -> API called, metadata verified, Success state.
- **Test 2:** Missing predecessor (`null`) -> `LineageException`, API not called, Quarantined.
- **Test 3:** Empty predecessor (`''`) -> API not called, Quarantined.
- **Test 4:** HTTP 500 response -> Quarantined, form reset, submission locked.
- **Test 5:** Null status in response -> Fail-Closed Quarantined.
- **Test 6:** Friction Tracking -> Focus `parent_consent_code`, wait > 5s -> friction event logged.
- **Widget Tests:** Pure `StatelessWidget` verification, atomic Byt rendering, full UI flows.

### Run Flutter Linter Analysis
```bash
flutter analyze
```
*Result: `No issues found!`*

### Run Mock Backend Tests (6 Tests)
```bash
cd mock_backend
npm test
```
*Result: `All 6 tests passed!`*

---

## 8. Demonstrating Test Cases in the UI

The UI includes a collapsible **Assignment Test Scenarios & Telemetry** panel (`SimulationPanelByt`) for instant visual demonstration:
1. **Case 1 (Valid):** Click **Case 1: Valid** -> Click **Verify & Submit** -> Banner displays **Success** with dynamic `VER-*` ID.
2. **Case 2 (Missing Lineage):** Click **Case 2: Missing Lineage** -> Click **Verify & Submit** -> Banner displays **Quarantined (Fail-Closed)** with `LineageException` details; API call is blocked.
3. **Case 3 (HTTP 500 / Null Status):** Click **Case 3: HTTP 500 / Null Status** -> Click **Verify & Submit** -> Banner displays **Data Quarantined – Compliance Failure**; submission is locked; volatile input is wiped.
4. **Friction Telemetry:** Click into the **Parent Consent Code** field and wait without typing for 5 seconds -> Console outputs:
   ```text
   [UI_FRICTION_LOG]
   Timestamp: 2026-08-15T12:00:00.000Z
   Field: parent_consent_code
   Hesitation Duration: 5.0s
   ```
