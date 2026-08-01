import assert from 'node:assert/strict';
import test from 'node:test';
import {
  createEmailVerificationToken,
  hashEmailVerificationToken,
} from '../../src/utils/emailVerification';

test('email verification tokens are random, hashed, and expire in 24 hours', () => {
  const first = createEmailVerificationToken();
  const second = createEmailVerificationToken();
  assert.notEqual(first.token, second.token);
  assert.equal(first.tokenHash, hashEmailVerificationToken(first.token));
  assert.equal(first.tokenHash.length, 64);
  assert.ok(first.expiresAt.getTime() > Date.now());
  assert.ok(first.expiresAt.getTime() - Date.now() <= 24 * 60 * 60 * 1000);
});

