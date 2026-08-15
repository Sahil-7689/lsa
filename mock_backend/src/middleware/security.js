/**
 * Security Middleware enforcing mandatory compliance headers.
 * Rejects requests with HTTP 400 if x-trace-id or x-logic-hash is missing.
 */
function securityHeaderMiddleware(req, res, next) {
  const traceId = req.headers['x-trace-id'];
  const logicHash = req.headers['x-logic-hash'];

  const missing = [];
  if (!traceId || String(traceId).trim() === '') {
    missing.push('x-trace-id');
  }
  if (!logicHash || String(logicHash).trim() === '') {
    missing.push('x-logic-hash');
  }

  if (missing.length > 0) {
    console.warn(`[SECURITY FAIL-CLOSED] Missing required headers: ${missing.join(', ')}`);
    return res.status(400).json({
      status: 'error',
      code: 'MISSING_MANDATORY_HEADERS',
      message: `Outbound compliance request rejected. Missing required headers: ${missing.join(', ')}`,
      missingHeaders: missing
    });
  }

  // Attach metadata to request object for logging
  req.complianceMetadata = {
    traceId,
    logicHash,
    receivedAt: new Date().toISOString()
  };

  next();
}

module.exports = {
  securityHeaderMiddleware
};
