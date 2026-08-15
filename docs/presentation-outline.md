# HabotConnect HPF — Technical Presentation Outline

> **Topic:** LSA Verification & Data Lineage Integration (HPF Technical Assignment)  
> **Target Role:** Flutter Mobile App Developer  
> **Format:** 12-Slide Technical Walkthrough

---

## Slide 1: Project Overview
* **Subtitle:** HabotConnect LSA Verification & Data Lineage Integration
* **Key Bullets:**
  * Technical simulation for HabotConnect Flutter Mobile Developer role.
  * Single-screen LSA Onboarding Gate enforcing data compliance and auditability.
  * Implements strict Fail-Closed security, deterministic Data Lineage, and UI friction tracking.
  * Complemented by a lightweight Node.js/Express mock REST service.
* **Suggested Visual:** App banner screenshot showcasing clean Material 3 LSA Onboarding Gate.
* **Key Takeaway:** Demonstrates high-reliability frontend architecture designed for security-critical compliance workflows.

---

## Slide 2: Core Requirements
* **Subtitle:** Scope & Technical Constraints
* **Key Bullets:**
  * Exactly one primary screen: `LsaVerificationScreen extends StatelessWidget`.
  * Modular Byt architecture with zero `setState()` and clear separation of concerns.
  * Lineage enforcement via non-editable `predecessor_id`.
  * Outbound request headers: dynamic `x-trace-id` (UUID v4) and `x-logic-hash` (SHA-256).
  * Fail-closed quarantine on missing lineage, server 500, or `status: null`.
* **Suggested Visual:** Requirements matrix mapping specification rules to architectural gates.
* **Key Takeaway:** Rigorous adherence to all HPF specifications without over-engineering.

---

## Slide 3: UI Architecture
* **Subtitle:** Layered Separation of Responsibilities
* **Key Bullets:**
  * **Stateless UI Layer:** Pure presentation widgets receiving state and emitting events.
  * **Controller Boundary:** `VerificationController` orchestrating lifecycle and state.
  * **Security & Lineage Engine:** `SecurityService` validating constraints and generating metadata.
  * **Communication Layer:** `ComplianceApi` communicating with REST mock server.
* **Suggested Visual:** Architecture flow diagram from UI -> Controller -> Security -> API.
* **Key Takeaway:** Business logic and side effects are completely decoupled from UI rendering.

---

## Slide 4: Byt Component Structure
* **Subtitle:** Atomic UI Decomposition
* **Key Bullets:**
  * `VerificationHeaderByt`: Branding and compliance status indicator.
  * `StatusBannerByt`: Prominent state banner (Idle / Processing / Quarantined / Success).
  * `LsaIdFieldByt`: Prefilled `LSA-7049` identifier field.
  * `ParentConsentFieldByt`: Editable input with focus and interaction telemetry.
  * `PredecessorFieldByt`: System-controlled, read-only lineage display.
  * `VerificationButtonByt`: Primary action button with loading and lock feedback.
* **Suggested Visual:** Component breakdown diagram showing individual Byt widgets.
* **Key Takeaway:** Atomic Byts ensure maximum reusability, testability, and single-responsibility boundaries.

---

## Slide 5: Stateless Flutter Design
* **Subtitle:** State Management via ChangeNotifier & ListenableBuilder
* **Key Bullets:**
  * `LsaVerificationScreen` is strictly `StatelessWidget`.
  * No `setState()` anywhere in the screen hierarchy.
  * Built using Flutter's native `ListenableBuilder` listening to `VerificationController`.
  * Eliminates boilerplate and avoids heavy external dependencies like Bloc or Riverpod.
* **Suggested Visual:** Code snippet of `LsaVerificationScreen` demonstrating stateless composition.
* **Key Takeaway:** Clean, idiomatic Flutter state management using standard SDK primitives.

---

## Slide 6: API Integration & Mock REST Service
* **Subtitle:** Contract Enforcement & Environment Config
* **Key Bullets:**
  * Outbound endpoint: `POST /v1/compliance/verify`.
  * Configurable base URL: Android Emulator (`10.0.2.2:3000`), Local (`localhost:3000`), or Prod.
  * Full JSON payload serialization with dynamic UTC ISO 8601 timestamps.
  * Lightweight Node.js/Express mock service with header, lineage, and failure simulation handlers.
* **Suggested Visual:** Sequence diagram showing HTTP request/response exchange with mock backend.
* **Key Takeaway:** Isolates network concerns and guarantees seamless contract verification in local environments.

---

## Slide 7: Data Lineage (`predecessor_id`)
* **Subtitle:** Preventing Orphan Records in Data Compliance
* **Key Bullets:**
  * `predecessor_id` is mandatory for establishing end-to-end data provenance.
  * UI enforces read-only display (`PRED-9982-XYZ`) to prevent client-side tampering.
  * If `predecessor_id` is null or empty, `SecurityService` throws `LineageException`.
  * Blocks network transmission immediately and quarantines the request.
* **Suggested Visual:** Diagram showing lineage chain linking predecessor nodes to current LSA.
* **Key Takeaway:** Data lineage is non-negotiable; missing lineage terminates the pipeline instantly.

---

## Slide 8: Dynamic Metadata (`trace-id` & `logic-hash`)
* **Subtitle:** Cryptographic Integrity & Distributed Tracing
* **Key Bullets:**
  * **`x-trace-id`:** Fresh RFC 4122 UUID v4 generated dynamically per submission.
  * **`x-logic-hash`:** 64-character hexadecimal SHA-256 hash computed from business/schema tokens.
  * Replaces any hardcoded example values with real, cryptographically valid digests.
  * Validated by backend security middleware (HTTP 400 if missing).
* **Suggested Visual:** Cryptographic pipeline snippet showing SHA-256 digest computation.
* **Key Takeaway:** Guarantees tamper-evident traceability and verification logic synchronization.

---

## Slide 9: Fail-Closed Security Pipeline
* **Subtitle:** Never Failing Open Under Any Failure Condition
* **Key Bullets:**
  * **Lineage Failure:** Null/empty `predecessor_id` -> LineageException -> Quarantine (No API call).
  * **Server Error:** HTTP 500 or `status: null` -> Quarantine -> Lock submission -> Clear volatile inputs.
  * **Tamper/Format Failure:** Invalid body -> Quarantine payload -> Display compliance failure.
  * Volatile input (`parent_consent_code`) is wiped to prevent replay of quarantined data.
* **Suggested Visual:** State machine diagram illustrating Fail-Closed quarantine transitions.
* **Key Takeaway:** Fail-closed guarantees that unauthorized or unverified data can never enter production data stores.

---

## Slide 10: Friction Tracking (>5-Second Inactivity Rule)
* **Subtitle:** Behavioral UI Telemetry on Critical Inputs
* **Key Bullets:**
  * Tracks focus and interaction on `parent_consent_code`.
  * Focusing starts a 5.0-second countdown timer; typing/interacting resets the countdown.
  * Inactivity exceeding 5.0 seconds triggers `[UI_FRICTION_LOG]` with timestamp and duration.
  * Deduplication logic ensures only one event per focus session; blurring cancels the timer.
* **Suggested Visual:** Terminal log capture of `[UI_FRICTION_LOG]` with timer sequence diagram.
* **Key Takeaway:** Telemetry is isolated from widget rendering and provides non-intrusive compliance auditing.

---

## Slide 11: Comprehensive Test Suite
* **Subtitle:** 100% Pass Rate Across Unit, Widget, and Backend Tests
* **Key Bullets:**
  * **Test 1:** Valid submission -> API called, metadata headers verified, Success state.
  * **Test 2 & 3:** Missing/empty predecessor -> LineageException, API not called, Quarantined.
  * **Test 4 & 5:** HTTP 500 & null status -> Quarantined, form reset, submission locked.
  * **Test 6:** Friction tracking -> >5s timer fires, typing resets, blur cancels.
  * **Backend Tests:** 6/6 Node.js TAP tests validating header, lineage, and 500 simulation routes.
* **Suggested Visual:** Terminal output showing `All tests passed!` (15 Flutter tests + 6 Node tests).
* **Key Takeaway:** Complete automated coverage of all edge cases, failure modes, and UI contracts.

---

## Slide 12: Conclusion & Engineering Summary
* **Subtitle:** Delivering Secure, Scalable Flutter Applications
* **Key Bullets:**
  * Translated strict HPF requirements into modular, stateless, enterprise-grade Flutter code.
  * Implemented atomic Byt architecture, Fail-Closed quarantine, and real cryptographic metadata.
  * Maintained lean dependencies (no heavy third-party state libraries).
  * Provided complete runnable mock backend, full test suite, and architectural documentation.
* **Suggested Visual:** Summary checklist with all requirements verified.
* **Key Takeaway:** Ready to deliver high-quality, secure mobile experiences for the HabotConnect team.
