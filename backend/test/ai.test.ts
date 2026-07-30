import assert from 'node:assert/strict';
import test from 'node:test';
import { getGeminiTimeoutMs, withTimeout } from '../src/utils/ai';

test('Gemini timeout is bounded and stops waiting for a stalled request', async () => {
  assert.equal(getGeminiTimeoutMs(undefined), 8000);
  assert.equal(getGeminiTimeoutMs('5000'), 5000);
  assert.equal(getGeminiTimeoutMs('0'), 8000);
  assert.equal(getGeminiTimeoutMs('invalid'), 8000);
  assert.equal(await withTimeout(Promise.resolve('ok'), 10), 'ok');
  await assert.rejects(
    withTimeout(new Promise(() => {}), 10),
    /Gemini timeout/,
  );
});
