/**
 * Request & Lineage Validator for LSA Compliance Gate.
 * Enforces Fail-Closed rejection for missing lineage or payload fields.
 */
function validateComplianceRequest(req, res, next) {
  const { predecessor_id, lsa_id, parent_consent_code, timestamp_utc } = req.body || {};

  // 1. Mandatory Data Lineage Validation (Fail-Closed)
  if (predecessor_id === undefined || predecessor_id === null || String(predecessor_id).trim() === '') {
    console.warn('[LINEAGE FAIL-CLOSED] Request rejected due to missing predecessor_id.');
    return res.status(422).json({
      status: 'quarantined',
      reason: 'missing_predecessor_id'
    });
  }

  // 2. Mandatory Payload Fields
  const missingFields = [];
  if (!lsa_id || String(lsa_id).trim() === '') missingFields.push('lsa_id');
  if (!parent_consent_code || String(parent_consent_code).trim() === '') missingFields.push('parent_consent_code');
  if (!timestamp_utc || String(timestamp_utc).trim() === '') missingFields.push('timestamp_utc');

  if (missingFields.length > 0) {
    console.warn(`[VALIDATION FAIL-CLOSED] Missing required body fields: ${missingFields.join(', ')}`);
    return res.status(400).json({
      status: 'error',
      code: 'INVALID_REQUEST_PAYLOAD',
      message: `Invalid compliance payload. Missing required fields: ${missingFields.join(', ')}`,
      missingFields
    });
  }

  next();
}

module.exports = {
  validateComplianceRequest
};
