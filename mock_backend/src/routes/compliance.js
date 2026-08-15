const express = require('express');
const { securityHeaderMiddleware } = require('../middleware/security');
const { validateComplianceRequest } = require('../validators/complianceValidator');

const router = express.Router();

/**
 * POST /v1/compliance/verify
 *
 * Implements the LSA Compliance verification endpoint.
 * Protected by security header validation and lineage validation.
 */
router.post(
  '/compliance/verify',
  securityHeaderMiddleware,
  validateComplianceRequest,
  (req, res) => {
    const { predecessor_id, lsa_id, parent_consent_code, timestamp_utc } = req.body;
    const { traceId, logicHash } = req.complianceMetadata;

    console.log('----------------------------------------------------');
    console.log('[COMPLIANCE AUDIT LOG] Incoming Verified Request:');
    console.log(`Trace ID            : ${traceId}`);
    console.log(`Logic Hash          : ${logicHash}`);
    console.log(`Predecessor ID      : ${predecessor_id}`);
    console.log(`LSA ID              : ${lsa_id}`);
    console.log(`Parent Consent Code : ${parent_consent_code}`);
    console.log(`Timestamp (UTC)     : ${timestamp_utc}`);
    console.log('----------------------------------------------------');

    // =========================================================================
    // TEST FAILURE SIMULATION (Assignment Case 3)
    // If parent_consent_code is "FAIL-500", simulate server failure / null status
    // =========================================================================
    if (parent_consent_code === 'FAIL-500') {
      console.warn('[SIMULATION] Simulating HTTP 500 server compliance failure with status=null');
      return res.status(500).json({
        status: null,
        error: 'SIMULATED_INTERNAL_COMPLIANCE_ERROR',
        message: 'Simulated 500 failure for testing frontend Fail-Closed quarantine.'
      });
    }

    // =========================================================================
    // SUCCESS RESPONSE
    // Generates a dynamic verification ID
    // =========================================================================
    const dynamicId = Math.floor(10000 + Math.random() * 90000);
    const verificationId = `VER-${dynamicId}`;

    return res.status(200).json({
      status: 'success',
      verification_id: verificationId,
      processed_at: new Date().toISOString()
    });
  }
);

module.exports = router;
