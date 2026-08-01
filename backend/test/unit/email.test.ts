import assert from 'node:assert/strict';
import test from 'node:test';
import {
  sendEmailVerification,
  sendPasswordResetEmail,
} from '../../src/utils/email';

test('password reset email uses the provider safely and no-ops in development', async () => {
  assert.equal(
    await sendPasswordResetEmail({
      to: 'user@example.com',
      token: 'secret',
      idempotencyKey: 'reset-1',
    }, null),
    false,
  );

  let request: RequestInit | undefined;
  const sent = await sendPasswordResetEmail(
    { to: 'user@example.com', token: 'a+b/c?', idempotencyKey: 'reset-2' },
    {
      apiKey: 're_test',
      from: 'NALA <noreply@nala.example>',
      appUrl: 'https://app.nala.example',
    },
    async (input, init) => {
      assert.equal(input, 'https://api.resend.com/emails');
      request = init;
      return new Response(JSON.stringify({ id: 'email-1' }), { status: 200 });
    },
  );
  assert.equal(sent, true);
  assert.equal(
    (request?.headers as Record<string, string>)['Idempotency-Key'],
    'reset-2',
  );
  assert.match(String(request?.body), /a%2Bb%2Fc%3F/);
});

test('verification email contains a NALA verification deep link', async () => {
  let body = '';
  await sendEmailVerification(
    { to: 'user@example.com', token: 'verify-secret', idempotencyKey: 'verify-1' },
    {
      apiKey: 're_test',
      from: 'NALA <noreply@nala.example>',
      appUrl: 'nala://app',
    },
    async (_input, init) => {
      body = String(init?.body);
      return new Response(JSON.stringify({ id: 'email-2' }), { status: 200 });
    },
  );
  assert.match(body, /nala:\/\/verify-email\?token=verify-secret/);
});

