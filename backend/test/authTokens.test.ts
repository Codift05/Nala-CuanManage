import assert from 'node:assert/strict';
import test from 'node:test';
import jwt from 'jsonwebtoken';
import { createAccessToken, hashRefreshToken } from '../src/utils/authTokens';

test('auth tokens are hashed and access tokens expire after 15 minutes', () => {
  const raw = 'refresh-token-secret';
  const hash = hashRefreshToken(raw);
  assert.equal(hash.length, 64);
  assert.notEqual(hash, raw);
  assert.equal(hashRefreshToken(raw), hash);

  const decoded = jwt.decode(createAccessToken('user-1', 'session-1')) as {
    exp: number;
    iat: number;
    sessionId: string;
  };
  assert.equal(decoded.sessionId, 'session-1');
  assert.equal(decoded.exp - decoded.iat, 15 * 60);
});
