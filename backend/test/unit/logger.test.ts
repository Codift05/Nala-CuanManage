import assert from 'node:assert/strict';
import test from 'node:test';
import { formatLog } from '../../src/utils/logger';

test('structured logs redact credentials and personal data', () => {
  const line = formatLog('error', 'auth.login_failed', {
    requestId: 'request-1',
    email: 'person@example.com',
    authorization: 'Bearer visible-token',
    errorMessage: 'Account person@example.com card 4111 1111 1111 1111',
  });

  assert.equal(line.includes('person@example.com'), false);
  assert.equal(line.includes('visible-token'), false);
  assert.equal(line.includes('4111 1111 1111 1111'), false);
  const info = JSON.parse(line);
  assert.deepEqual(info, {
    timestamp: info.timestamp,
    level: 'error',
    event: 'auth.login_failed',
    requestId: 'request-1',
    email: '[REDACTED]',
    authorization: '[REDACTED]',
    errorMessage: 'Account [REDACTED_EMAIL] card [REDACTED_NUMBER]',
  });
});
