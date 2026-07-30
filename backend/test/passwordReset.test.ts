import assert from 'node:assert/strict';
import test from 'node:test';
import {
  createPasswordResetToken,
  hashPasswordResetToken,
  PASSWORD_RESET_MINUTES,
} from '../src/utils/passwordReset';

test('password reset tokens are random, hashed, and expire in 15 minutes', () => {
  const first = createPasswordResetToken();
  const second = createPasswordResetToken();

  assert.notEqual(first.token, second.token);
  assert.equal(first.tokenHash, hashPasswordResetToken(first.token));
  assert.equal(first.tokenHash.length, 64);
  assert.ok(first.expiresAt.getTime() - Date.now() <= PASSWORD_RESET_MINUTES * 60000);
  assert.ok(first.expiresAt.getTime() > Date.now());
});
