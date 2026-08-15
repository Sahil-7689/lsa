// HabotConnect HPF — Technical Demonstration Controller & Security Pipeline Logic

// State definition
let state = {
  lsaId: 'LSA-7049',
  parentConsentCode: '',
  predecessorId: 'PRED-9982-XYZ',
  status: 'idle', // idle, processing, success, quarantined
  statusMessage: 'Form is ready for verification input. Enter consent code below.',
  verificationId: null,
  isSubmissionLocked: false,
  lastTraceId: null,
  lastLogicHash: null,
  quarantinedRecords: [],
  frictionEvents: []
};

// DOM Elements
const lsaIdInput = document.getElementById('lsaIdInput');
const parentConsentInput = document.getElementById('parentConsentInput');
const predecessorValue = document.getElementById('predecessorValue');
const predecessorBox = document.getElementById('predecessorBox');
const predecessorBadge = document.getElementById('predecessorBadge');
const verifySubmitBtn = document.getElementById('verifySubmitBtn');
const btnSpinner = document.getElementById('btnSpinner');
const btnIcon = document.getElementById('btnIcon');
const btnText = document.getElementById('btnText');
const statusBanner = document.getElementById('statusBanner');
const statusIcon = document.getElementById('statusIcon');
const statusTitle = document.getElementById('statusTitle');
const statusDesc = document.getElementById('statusDesc');
const bannerResetBtn = document.getElementById('bannerResetBtn');

// Inspector & Telemetry Elements
const telemetryTraceId = document.getElementById('telemetryTraceId');
const telemetryLogicHash = document.getElementById('telemetryLogicHash');
const frictionPill = document.getElementById('frictionPill');
const frictionStatusText = document.getElementById('frictionStatusText');
const frictionTimerFill = document.getElementById('frictionTimerFill');
const frictionTimerSeconds = document.getElementById('frictionTimerSeconds');
const frictionConsole = document.getElementById('frictionConsole');
const auditConsole = document.getElementById('auditConsole');
const quarantineCounter = document.getElementById('quarantineCounter');

// Buttons
const btnCase1 = document.getElementById('btnCase1');
const btnCase2 = document.getElementById('btnCase2');
const btnCase3 = document.getElementById('btnCase3');
const btnResetAll = document.getElementById('btnResetAll');
const simPanelToggle = document.getElementById('simPanelToggle');
const simBody = document.getElementById('simBody');
const simToggleIcon = document.getElementById('simToggleIcon');

// Friction Tracking State
let frictionTimer = null;
let frictionElapsedMs = 0;
let hasEmittedFriction = false;
const FRICTION_THRESHOLD_MS = 5000;

// SHA-256 & UUID Cryptographic Helpers
function generateTraceId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

async function generateLogicHash() {
  const seed = 'habotconnect_lsa_logic_v1.0:schema_v1.0_2026';
  const msgUint8 = new TextEncoder().encode(seed);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

// Pipeline visualizer helper
function setPipelineStep(stepIndex, status = 'active') {
  for (let i = 1; i <= 7; i++) {
    const node = document.getElementById(`gateNode${i}`);
    if (!node) continue;
    if (i < stepIndex) {
      node.className = 'pipeline-node node-pass';
    } else if (i === stepIndex) {
      node.className = `pipeline-node node-${status}`;
    } else {
      node.className = 'pipeline-node';
    }
  }
}

function resetPipeline() {
  for (let i = 1; i <= 7; i++) {
    const node = document.getElementById(`gateNode${i}`);
    if (node) node.className = 'pipeline-node';
  }
}

// UI State Synchronizer
function renderUI() {
  // Fields
  lsaIdInput.value = state.lsaId;
  lsaIdInput.disabled = state.isSubmissionLocked;
  parentConsentInput.value = state.parentConsentCode;
  parentConsentInput.disabled = state.isSubmissionLocked;

  // Predecessor Box
  if (!state.predecessorId || state.predecessorId.trim() === '') {
    predecessorValue.textContent = '<NULL / MISSING LINEAGE>';
    predecessorValue.className = 'predecessor-value missing-text';
    predecessorBox.className = 'predecessor-box missing';
    predecessorBadge.className = 'field-pill pill-lineage pill-lineage-missing';
    predecessorBadge.innerHTML = '<i class="fa-solid fa-triangle-exclamation"></i> Missing Lineage';
  } else {
    predecessorValue.textContent = state.predecessorId;
    predecessorValue.className = 'predecessor-value';
    predecessorBox.className = 'predecessor-box';
    predecessorBadge.className = 'field-pill pill-lineage';
    predecessorBadge.innerHTML = '<i class="fa-solid fa-lock"></i> Read-Only';
  }

  // Button state
  if (state.status === 'processing') {
    verifySubmitBtn.disabled = true;
    btnSpinner.style.display = 'inline-block';
    btnIcon.style.display = 'none';
    btnText.textContent = 'Processing Verification...';
  } else if (state.isSubmissionLocked) {
    verifySubmitBtn.disabled = true;
    btnSpinner.style.display = 'none';
    btnIcon.style.display = 'inline-block';
    btnIcon.innerHTML = '<i class="fa-solid fa-lock"></i>';
    btnText.textContent = 'Submission Locked';
  } else {
    verifySubmitBtn.disabled = false;
    btnSpinner.style.display = 'none';
    btnIcon.style.display = 'inline-block';
    btnIcon.innerHTML = '<i class="fa-solid fa-shield-halved"></i>';
    btnText.textContent = 'Verify & Submit';
  }

  // Banner status
  statusBanner.className = `byt-status-banner status-${state.status}`;
  bannerResetBtn.style.display = state.status === 'quarantined' || state.status === 'success' ? 'block' : 'none';

  if (state.status === 'idle') {
    statusIcon.innerHTML = '<i class="fa-regular fa-circle-check"></i>';
    statusTitle.textContent = 'Idle';
    statusDesc.textContent = state.statusMessage;
  } else if (state.status === 'processing') {
    statusIcon.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    statusTitle.textContent = 'Processing Security Pipeline...';
    statusDesc.textContent = 'Evaluating data lineage and generating cryptographic metadata...';
  } else if (state.status === 'success') {
    statusIcon.innerHTML = '<i class="fa-solid fa-circle-check" style="color: #10B981;"></i>';
    statusTitle.textContent = 'Success';
    statusDesc.textContent = `Verification ID: ${state.verificationId}`;
  } else if (state.status === 'quarantined') {
    statusIcon.innerHTML = '<i class="fa-solid fa-triangle-exclamation" style="color: #EF4444;"></i>';
    statusTitle.textContent = 'Quarantined (Fail-Closed)';
    statusDesc.textContent = state.statusMessage;
  }

  // Telemetry display
  telemetryTraceId.textContent = state.lastTraceId || 'Generated on submit (RFC 4122 UUID v4)';
  telemetryLogicHash.textContent = state.lastLogicHash || 'Generated on submit (SHA-256 64-char hex)';
  quarantineCounter.textContent = `${state.quarantinedRecords.length} Quarantined Records`;
}

// Log Append Helpers
function appendFrictionLog(text) {
  const line = document.createElement('div');
  line.className = 'console-line';
  line.innerHTML = text;
  frictionConsole.prepend(line);
}

function appendAuditLog(text, isError = false) {
  const line = document.createElement('div');
  line.className = isError ? 'console-line text-red' : 'console-line';
  line.innerHTML = text;
  auditConsole.prepend(line);
}

// =========================================================================
// FRICTION TRACKING LIFECYCLE (>5.0s Inactivity Rule)
// =========================================================================
function startFrictionTracking() {
  if (state.isSubmissionLocked) return;
  clearInterval(frictionTimer);
  frictionElapsedMs = 0;
  hasEmittedFriction = false;

  frictionPill.className = 'friction-status-pill';
  frictionPill.innerHTML = '<i class="fa-solid fa-circle text-orange"></i> <span id="frictionStatusText">Tracking Active...</span>';
  
  const tickIntervalMs = 100;
  frictionTimer = setInterval(() => {
    frictionElapsedMs += tickIntervalMs;
    const progressPercent = Math.min(100, (frictionElapsedMs / FRICTION_THRESHOLD_MS) * 100);
    frictionTimerFill.style.width = `${progressPercent}%`;
    frictionTimerSeconds.textContent = `Timer: ${(frictionElapsedMs / 1000).toFixed(1)}s / 5.0s`;

    if (frictionElapsedMs >= FRICTION_THRESHOLD_MS && !hasEmittedFriction) {
      hasEmittedFriction = true;
      triggerFrictionEvent('parent_consent_code', 5.0);
    }
  }, tickIntervalMs);
}

function resetFrictionTimer() {
  if (!frictionTimer) return;
  frictionElapsedMs = 0;
  hasEmittedFriction = false;
  frictionTimerFill.style.width = '0%';
  frictionTimerSeconds.textContent = 'Timer: 0.0s / 5.0s (Reset on interaction)';
}

function stopFrictionTracking() {
  clearInterval(frictionTimer);
  frictionTimer = null;
  frictionTimerFill.style.width = '0%';
  frictionTimerSeconds.textContent = 'Timer: 0.0s / 5.0s';
  frictionPill.className = 'friction-status-pill';
  frictionPill.innerHTML = '<i class="fa-solid fa-circle text-gray"></i> <span>Idle</span>';
}

function triggerFrictionEvent(fieldName, durationSec) {
  const timestamp = new Date().toISOString();
  state.frictionEvents.push({ fieldName, durationSec, timestamp });

  appendFrictionLog(`<span style="color:#F59E0B; font-weight:bold;">[UI_FRICTION_LOG]</span><br>` +
    `Timestamp: ${timestamp}<br>` +
    `Field: <b>${fieldName}</b><br>` +
    `Hesitation Duration: <b>${durationSec.toFixed(1)}s</b>`);
}

// Event Listeners for Friction Field
parentConsentInput.addEventListener('focus', () => {
  startFrictionTracking();
});

parentConsentInput.addEventListener('input', (e) => {
  state.parentConsentCode = e.target.value;
  resetFrictionTimer();
});

parentConsentInput.addEventListener('blur', () => {
  stopFrictionTracking();
});

lsaIdInput.addEventListener('input', (e) => {
  state.lsaId = e.target.value;
});

// =========================================================================
// FAIL-CLOSED VERIFICATION PIPELINE
// =========================================================================
async function submitVerification() {
  if (state.isSubmissionLocked || state.status === 'processing') return;

  state.status = 'processing';
  state.statusMessage = null;
  state.verificationId = null;
  renderUI();

  appendAuditLog(`----------------------------------------------------`);
  appendAuditLog(`[PIPELINE START] Beginning verification execution pipeline...`);

  // Step 1: UI & Format Check
  setPipelineStep(1, 'active');
  await new Promise(r => setTimeout(r, 200));

  // Step 2: Payload Validation
  setPipelineStep(2, 'active');
  await new Promise(r => setTimeout(r, 200));

  if (!state.lsaId || state.lsaId.trim() === '') {
    enforceQuarantine('Validation Error: LSA ID is required and cannot be empty.', 'lsa_id');
    setPipelineStep(2, 'fail');
    return;
  }

  if (!state.parentConsentCode || state.parentConsentCode.trim() === '') {
    enforceQuarantine('Validation Error: Parent Consent Code is required and cannot be empty.', 'parent_consent_code');
    setPipelineStep(2, 'fail');
    return;
  }

  // Step 3: Mandatory Predecessor Lineage Gate (Fail-Closed)
  setPipelineStep(3, 'active');
  await new Promise(r => setTimeout(r, 250));

  if (!state.predecessorId || state.predecessorId.trim() === '') {
    appendAuditLog(`<span class="text-red"><b>[LINEAGE GATE BLOCKED]</b> LineageException: Missing mandatory predecessor_id.</span>`, true);
    appendAuditLog(`[NETWORK BLOCKED] Outbound HTTP transmission intercepted and halted.`, true);
    setPipelineStep(3, 'fail');
    enforceQuarantine('Data Quarantined – Compliance Failure: Missing Data Lineage (predecessor_id)', 'predecessor_id');
    renderUI();
    return;
  }

  // Step 4: Metadata Generation (UUID + SHA-256)
  setPipelineStep(4, 'active');
  await new Promise(r => setTimeout(r, 250));

  const traceId = generateTraceId();
  const logicHash = await generateLogicHash();
  state.lastTraceId = traceId;
  state.lastLogicHash = logicHash;
  renderUI();

  appendAuditLog(`[SECURITY METADATA] x-trace-id: ${traceId}`);
  appendAuditLog(`[SECURITY METADATA] x-logic-hash: ${logicHash}`);

  // Step 5: Outbound Network Request
  setPipelineStep(5, 'active');
  appendAuditLog(`--> POST http://localhost:3000/v1/compliance/verify`);

  const payload = {
    predecessor_id: state.predecessorId,
    lsa_id: state.lsaId,
    parent_consent_code: state.parentConsentCode,
    timestamp_utc: new Date().toISOString()
  };

  try {
    const response = await fetch('http://localhost:3000/v1/compliance/verify', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-trace-id': traceId,
        'x-logic-hash': logicHash
      },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    appendAuditLog(`<-- HTTP ${response.status} Response Body: ${JSON.stringify(data)}`);

    // Step 6: Response Validation
    setPipelineStep(6, 'active');
    await new Promise(r => setTimeout(r, 200));

    if (response.ok && data.status === 'success') {
      // Step 7: Terminal Success
      state.status = 'success';
      state.verificationId = data.verification_id;
      state.statusMessage = `Verification Successful (ID: ${data.verification_id})`;
      setPipelineStep(7, 'pass');
      document.getElementById('terminalDesc').textContent = 'Success State';
      appendAuditLog(`<span class="text-green"><b>[SUCCESS]</b> Verified with ID: ${data.verification_id}</span>`);
    } else {
      // Step 7: Fail-Closed Quarantine
      setPipelineStep(6, 'fail');
      setPipelineStep(7, 'fail');
      document.getElementById('terminalDesc').textContent = 'Quarantined State';
      enforceQuarantine('Data Quarantined – Compliance Failure', 'api_response', traceId, payload);
    }
  } catch (netErr) {
    appendAuditLog(`<span class="text-red">[API NETWORK ERROR] ${netErr.message}</span>`, true);
    setPipelineStep(5, 'fail');
    setPipelineStep(7, 'fail');
    enforceQuarantine('Data Quarantined – Compliance Failure', 'network_error', traceId, payload);
  }

  renderUI();
}

function enforceQuarantine(statusMessage, failedField, traceId = 'N/A', payload = {}) {
  const qId = 'QUAR-' + Math.random().toString(16).substring(2, 10).toUpperCase();
  const timestamp = new Date().toISOString();

  const record = {
    id: qId,
    timestamp,
    reason: statusMessage,
    failedField,
    traceId,
    payload: {
      predecessor_id: state.predecessorId,
      lsa_id: state.lsaId,
      parent_consent_code: state.parentConsentCode,
      timestamp_utc: timestamp
    }
  };

  state.quarantinedRecords.push(record);
  state.status = 'quarantined';
  state.statusMessage = statusMessage;
  state.parentConsentCode = ''; // Clear volatile form data
  state.isSubmissionLocked = true; // Lock further submission

  appendAuditLog(`================ <span class="text-red"><b>[FAIL-CLOSED QUARANTINE]</b></span> ================<br>` +
    `Quarantine ID : ${qId}<br>` +
    `Timestamp     : ${timestamp}<br>` +
    `Reason        : ${statusMessage}<br>` +
    `Failed Field  : ${failedField}<br>` +
    `Trace ID      : ${traceId}<br>` +
    `Payload       : ${JSON.stringify(record.payload)}<br>` +
    `==========================================================`, true);
}

// Preset Loader Actions
function loadValidCase() {
  state.lsaId = 'LSA-7049';
  state.parentConsentCode = 'PCC-2026-9901';
  state.predecessorId = 'PRED-9982-XYZ';
  state.status = 'idle';
  state.statusMessage = 'Preset Loaded: Case 1 (Valid Submission)';
  state.verificationId = null;
  state.isSubmissionLocked = false;
  resetPipeline();
  renderUI();
  appendAuditLog(`[Preset Loaded] Case 1: Valid Profile (LSA-7049, PCC-2026-9901, PRED-9982-XYZ)`);
}

function loadMissingLineageCase() {
  state.lsaId = 'LSA-7049';
  state.parentConsentCode = 'PCC-2026-9901';
  state.predecessorId = ''; // Missing lineage
  state.status = 'idle';
  state.statusMessage = 'Preset Loaded: Case 2 (Missing Predecessor Lineage)';
  state.verificationId = null;
  state.isSubmissionLocked = false;
  resetPipeline();
  renderUI();
  appendAuditLog(`[Preset Loaded] Case 2: Missing Lineage (predecessor_id set to null/empty)`);
}

function loadSimulate500Case() {
  state.lsaId = 'LSA-7049';
  state.parentConsentCode = 'FAIL-500';
  state.predecessorId = 'PRED-9982-XYZ';
  state.status = 'idle';
  state.statusMessage = 'Preset Loaded: Case 3 (HTTP 500 / Null Status Simulation)';
  state.verificationId = null;
  state.isSubmissionLocked = false;
  resetPipeline();
  renderUI();
  appendAuditLog(`[Preset Loaded] Case 3: HTTP 500 Simulation (parent_consent_code set to FAIL-500)`);
}

function resetAll() {
  state.lsaId = 'LSA-7049';
  state.parentConsentCode = '';
  state.predecessorId = 'PRED-9982-XYZ';
  state.status = 'idle';
  state.statusMessage = 'Form is ready for verification input. Enter consent code below.';
  state.verificationId = null;
  state.isSubmissionLocked = false;
  resetPipeline();
  stopFrictionTracking();
  renderUI();
  appendAuditLog(`[Reset] Form unlocked and restored to default idle state.`);
}

// Button bindings
verifySubmitBtn.addEventListener('click', submitVerification);
btnCase1.addEventListener('click', loadValidCase);
btnCase2.addEventListener('click', loadMissingLineageCase);
btnCase3.addEventListener('click', loadSimulate500Case);
btnResetAll.addEventListener('click', resetAll);
bannerResetBtn.addEventListener('click', resetAll);

simPanelToggle.addEventListener('click', () => {
  if (simBody.style.display === 'none') {
    simBody.style.display = 'block';
    simToggleIcon.style.transform = 'rotate(0deg)';
  } else {
    simBody.style.display = 'none';
    simToggleIcon.style.transform = 'rotate(-90deg)';
  }
});

// Initial render
renderUI();
