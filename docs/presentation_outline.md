# HabotConnect Hiring Project (HPF) — Technical Presentation Deck
**Position:** Digivir – Flutter Mobile App Developer  
**Project:** LSA Profile Verification Screen & Fail-Closed Security Pipeline

---

## Slide 1: Title
* **Applicant:** Flutter Mobile App Developer Candidate
* **Role:** Digivir – Flutter Mobile App Developer
* **Project:** HabotConnect LSA Profile Verification (HPF)
* **Core Themes:** Stateless UI, Modular Byt Architecture, Fail-Closed Security, Lineage Governance & Friction Telemetry
* **Suggested Visual:** App branding splash with HabotConnect logo and Material 3 theme badge.
* **Key Technical Message:** High-fidelity Flutter architecture combining pure stateless UI rendering with robust client-side security and data integrity gates.

---

## Slide 2: Problem & Objective
* Credential verification workflows in decentralized environments cannot afford orphan or unverified records.
* Accidental network transmissions of non-compliant data create severe compliance and audit liabilities.
* User drop-offs during credentialing require telemetry to detect UI friction without collecting sensitive keystrokes.
* **Objective:** Deliver a production-quality, fail-closed Flutter application with strict module boundaries.
* **Suggested Visual:** Flow diagram comparing vulnerable "fail-open" vs. resilient "fail-closed" pipelines.
* **Key Technical Message:** Prevent malformed, non-compliant, or orphan data from ever reaching outbound network transport.

---

## Slide 3: Architecture Overview
* **Stateless UI Layer:** Pure rendering Byts receiving immutable `VerificationViewState`.
* **Controller Layer:** Orchestrates business logic, timers, and security state via `ValueNotifier`.
* **Security & Lineage Engine:** 5-tier pre-flight validation pipeline with local data quarantine.
* **API Transport:** Dedicated client with payload mapping and strict response verification.
* **Suggested Visual:** End-to-end architecture diagram showing UI $\rightarrow$ Controller $\rightarrow$ Security Gate $\rightarrow$ Quarantine/API.
* **Key Technical Message:** Clean separation of concerns with unidirectional data flow and zero business logic embedded in UI widgets.

---

## Slide 4: Modular "Byt" Boundaries
* Each "Byt" represents an atomic, single-responsibility module with clear contracts.
* `ProfileHeaderByt`: Candidate avatar, role description, and real-time status chips.
* `VerificationFormByt` & `DocumentVerificationByt`: Personal credentials and document serials.
* `ComplianceSectionByt`: Policy agreement and fail-closed accreditation status selector.
* `SubmitButtonByt` & `AuditDrawerByt`: Action trigger and live telemetry inspection console.
* **Suggested Visual:** Exploded modular layout showing Byt component boundaries.
* **Key Technical Message:** Strict component isolation enables high reusability, easy refactoring, and zero side effects.

---

## Slide 5: Stateless Flutter Design
* Every UI widget extends `StatelessWidget` with `const` constructors.
* No `StatefulWidget`, mutable variables, or timers inside widget classes.
* Interactions propagate strictly through typed callbacks (`onFullNameChanged`, `onFieldFocused`, `onSubmit`).
* Rebuilds are scoped and efficient using `ValueListenableBuilder<VerificationViewState>`.
* **Suggested Visual:** Flutter widget tree diagram highlighting immutable data passing.
* **Key Technical Message:** Stateless UI guarantees determinism, eliminates lifecycle race conditions, and simplifies testing.

---

## Slide 6: Figma-to-Code Implementation Approach
* **Material Design 3 Design System:** Custom palette with Deep Teal (`#0F766E`), Cyan (`#00ADB5`), and Slate surfaces.
* **Design Tokens:** Standardized 8pt spatial grid, rounded 12–16px card radii, and modern typography.
* **Responsive Scaffolding:** `ConstrainedBox` max-width container ensuring premium layout across mobile, tablet, and web.
* **Micro-interactions:** Focus rings, lineage connection indicators, and live badge transitions.
* **Suggested Visual:** Side-by-side comparison of Figma layout specs and running Flutter application.
* **Key Technical Message:** Pixel-perfect execution of design specifications translated into maintainable, structured Flutter widgets.

---

## Slide 7: API Endpoint & Payload Mapping
* Dedicated `VerificationApi` interface decoupled from concrete transport implementations.
* Immutable `VerificationPayload` model with strict null safety and JSON serialization.
* Canonical payload sorting ensures deterministic byte output for downstream validation.
* Outbound envelope maps fields to standardized `https://mock.habotconnect.internal/api/v2/lsa/profile-verify`.
* **Suggested Visual:** JSON payload schema structure mapped to HTTP request envelope.
* **Key Technical Message:** Explicit contract decoupling isolates network transport from internal application models.

---

## Slide 8: Mandatory Metadata & Cryptographic Integrity
* **`trace_id` Header:** Unique RFC 4122 Version 4 UUID generated per request for distributed tracing.
* **`logic_hash` Header:** Deterministic SHA-256 hash combining validation logic version, schema version, and canonical payload.
* Eliminates hardcoded or static security headers.
* Header tampering or invalid UUID formats are intercepted prior to network flight.
* **Suggested Visual:** Formula diagram illustrating `SHA-256(logic_version + schema_version + sorted_payload)`.
* **Key Technical Message:** Cryptographic metadata guarantees request provenance and prevents payload tampering.

---

## Slide 9: Data Lineage Governance
* Enforces mandatory `predecessor_id` validation before every submission.
* Orphan data without a lineage parent is blocked at Gate 3.
* Prevents disconnected records in the LSA accreditation chain.
* Visual lineage indicators provide transparent feedback on predecessor linkage.
* **Suggested Visual:** Diagram illustrating linked predecessor chain vs. blocked orphan record.
* **Key Technical Message:** Strict lineage governance ensures data integrity and continuity throughout the verification lifecycle.

---

## Slide 10: Fail-Closed Validation & Quarantine Service
* 5-tier security gate executes sequentially: Schema $\rightarrow$ Required Fields $\rightarrow$ Predecessor $\rightarrow$ Compliance $\rightarrow$ Cryptography.
* If any gate fails: execution halts immediately, payload is quarantined, and no API request is sent.
* `QuarantineService` logs failed gate ID, timestamp, reason, and remediation advice.
* API response validation fails closed on null, timeout, or malformed payloads.
* **Suggested Visual:** Fail-closed decision tree showing immediate routing to Quarantine on failure.
* **Key Technical Message:** Security fails closed by default—invalid or uncertain states are safely contained and logged.

---

## Slide 11: Autonomous UI Friction Tracking
* `FrictionTracker` monitors the primary input field (`fullName`) without UI widget coupling.
* Inactivity $> 5.0$ seconds during active focus triggers a telemetry `FrictionEvent`.
* User typing or interactions immediately reset the 5-second countdown timer.
* Built-in deduplication prevents event flooding during continuous user pauses.
* **Suggested Visual:** Timeline diagram showing focus gain, typing reset, and 5-second stall event trigger.
* **Key Technical Message:** Privacy-preserving friction detection highlights UX obstacles without storing sensitive keystrokes.

---

## Slide 12: Automated Testing & Conclusion
* Comprehensive automated test suite passing `flutter analyze` and `flutter test`.
* **Security Pipeline Tests:** Verified valid pass, missing predecessor quarantine, and revoked compliance blocks.
* **API Tests:** Verified response validation, null-response fail-closed handling, and trace alignment.
* **Friction & Widget Tests:** Verified 5s stall timers, interaction resets, and stateless rendering.
* **Conclusion:** Production-ready architecture meeting all HabotConnect HPF requirements.
* **Suggested Visual:** Terminal screenshot showing 100% passing tests and zero analyzer warnings.
* **Key Technical Message:** Clean, resilient, and verifiable Flutter engineering ready for production deployment.
