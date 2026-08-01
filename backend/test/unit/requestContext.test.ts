import assert from 'node:assert/strict';
import test from 'node:test';
import { normalizeErrorBody } from '../../src/middleware/requestContext';

test('error responses keep legacy message and add traceable contract', () => {
  assert.deepEqual(
    normalizeErrorBody(400, { error: 'Email invalid' }, 'request-1'),
    {
      message: 'Email invalid',
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Email invalid',
        requestId: 'request-1',
      },
    },
  );
  assert.equal(
    normalizeErrorBody(500, null, 'request-2').error.code,
    'INTERNAL_ERROR',
  );
});

