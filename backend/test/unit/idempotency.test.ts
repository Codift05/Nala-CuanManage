import assert from 'node:assert/strict';
import test from 'node:test';
import {
  parseIdempotencyKey,
  recurringDueDays,
  recurringIdempotencyKey,
  recurringPeriod,
} from '../../src/utils/idempotency';

test('accepts bounded idempotency keys and rejects unsafe values', () => {
  assert.equal(
    parseIdempotencyKey('nala-1722345678901-a1b2c3d4'),
    'nala-1722345678901-a1b2c3d4',
  );
  assert.equal(parseIdempotencyKey('terlalu-pendek'), null);
  assert.equal(parseIdempotencyKey('x'.repeat(129)), null);
  assert.equal(parseIdempotencyKey('invalid key with spaces'), null);
});

test('recurring keys stay stable within a month and change next month', () => {
  const january = new Date(2026, 0, 1);
  const januaryLater = new Date(2026, 0, 31);
  const february = new Date(2026, 1, 1);

  assert.equal(recurringPeriod(january), '2026-01');
  assert.equal(
    recurringIdempotencyKey('bill-1', january),
    recurringIdempotencyKey('bill-1', januaryLater),
  );
  assert.notEqual(
    recurringIdempotencyKey('bill-1', january),
    recurringIdempotencyKey('bill-1', february),
  );
});

test('month end includes recurring bills that use unavailable dates', () => {
  assert.deepEqual(recurringDueDays(new Date(2026, 1, 27)), [27]);
  assert.deepEqual(recurringDueDays(new Date(2026, 1, 28)), [28, 29, 30, 31]);
  assert.deepEqual(recurringDueDays(new Date(2028, 1, 29)), [29, 30, 31]);
  assert.deepEqual(recurringDueDays(new Date(2026, 3, 30)), [30, 31]);
});

