const { test, describe } = require('node:test');
const assert = require('node:assert');
const http = require('node:http');
const app = require('../src/server');

let server;
let baseUrl;

function makeRequest({ method = 'POST', path = '/v1/compliance/verify', headers = {}, body = null }) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, baseUrl);
    const bodyData = body ? JSON.stringify(body) : null;

    const req = http.request(
      url,
      {
        method,
        headers: {
          'Content-Type': 'application/json',
          ...(bodyData ? { 'Content-Length': Buffer.byteLength(bodyData) } : {}),
          ...headers,
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          let json = null;
          try {
            if (data) json = JSON.parse(data);
          } catch (e) {
            json = data;
          }
          resolve({ statusCode: res.statusCode, headers: res.headers, body: json });
        });
      }
    );

    req.on('error', reject);
    if (bodyData) req.write(bodyData);
    req.end();
  });
}

describe('HabotConnect Mock REST API Tests', async () => {
  test('Server setup', async () => {
    await new Promise((resolve) => {
      server = app.listen(0, '127.0.0.1', () => {
        const port = server.address().port;
        baseUrl = `http://127.0.0.1:${port}`;
        resolve();
      });
    });
  });

  test('Test 1: Valid compliance submission returns 200 with VER-* ID', async () => {
    const res = await makeRequest({
      headers: {
        'x-trace-id': 'test-uuid-trace-1234',
        'x-logic-hash': '02819bab8b3825f5cfe63f0fd625f37915c4a50034cb84d7162efa483c3b91bd',
      },
      body: {
        predecessor_id: 'PRED-9982-XYZ',
        lsa_id: 'LSA-7049',
        parent_consent_code: 'PCC-2026-9901',
        timestamp_utc: '2026-08-15T12:00:00Z',
      },
    });

    assert.strictEqual(res.statusCode, 200);
    assert.strictEqual(res.body.status, 'success');
    assert.match(res.body.verification_id, /^VER-\d+/);
  });

  test('Test 2: Missing metadata headers returns 400 Bad Request', async () => {
    const res = await makeRequest({
      headers: {}, // Missing x-trace-id and x-logic-hash
      body: {
        predecessor_id: 'PRED-9982-XYZ',
        lsa_id: 'LSA-7049',
        parent_consent_code: 'PCC-2026-9901',
        timestamp_utc: '2026-08-15T12:00:00Z',
      },
    });

    assert.strictEqual(res.statusCode, 400);
    assert.strictEqual(res.body.code, 'MISSING_MANDATORY_HEADERS');
  });

  test('Test 3: Missing predecessor_id returns 422 Quarantined', async () => {
    const res = await makeRequest({
      headers: {
        'x-trace-id': 'test-uuid-trace-1234',
        'x-logic-hash': '02819bab8b3825f5cfe63f0fd625f37915c4a50034cb84d7162efa483c3b91bd',
      },
      body: {
        // Missing predecessor_id
        lsa_id: 'LSA-7049',
        parent_consent_code: 'PCC-2026-9901',
        timestamp_utc: '2026-08-15T12:00:00Z',
      },
    });

    assert.strictEqual(res.statusCode, 422);
    assert.strictEqual(res.body.status, 'quarantined');
    assert.strictEqual(res.body.reason, 'missing_predecessor_id');
  });

  test('Test 4: FAIL-500 consent code returns 500 with null status', async () => {
    const res = await makeRequest({
      headers: {
        'x-trace-id': 'test-uuid-trace-1234',
        'x-logic-hash': '02819bab8b3825f5cfe63f0fd625f37915c4a50034cb84d7162efa483c3b91bd',
      },
      body: {
        predecessor_id: 'PRED-9982-XYZ',
        lsa_id: 'LSA-7049',
        parent_consent_code: 'FAIL-500',
        timestamp_utc: '2026-08-15T12:00:00Z',
      },
    });

    assert.strictEqual(res.statusCode, 500);
    assert.strictEqual(res.body.status, null);
  });

  test('Server teardown', async () => {
    await new Promise((resolve) => server.close(resolve));
  });
});
