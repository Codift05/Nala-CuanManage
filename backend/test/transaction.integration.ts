import assert from 'node:assert/strict';
import prisma from '../src/utils/prisma';

const apiUrl = process.env.API_BASE_URL ?? 'http://127.0.0.1:3000/api';
const key = `integration-${Date.now()}`;

const request = async (
  path: string,
  token: string,
  init: RequestInit = {},
) => {
  const response = await fetch(`${apiUrl}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
      ...init.headers,
    },
  });
  return { response, body: await response.json() };
};

const run = async () => {
  const loginResponse = await fetch(`${apiUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: 'admin@nala.com',
      password: 'password123',
      deviceName: 'Integration primary',
    }),
  });
  const login = await loginResponse.json();
  assert.equal(loginResponse.status, 200);
  assert.equal(typeof login.token, 'string');

  const { response: walletsResponse, body: wallets } = await request(
    '/wallets',
    login.token,
  );
  assert.equal(walletsResponse.status, 200);
  assert.ok(Array.isArray(wallets) && wallets.length > 0);

  const wallet = wallets[0];
  const initialBalance = wallet.balance;
  let transactionId: string | undefined;
  let temporaryUserId: string | undefined;

  try {
    const invalidBody = await fetch(`${apiUrl}/wallets`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${login.token}`,
      },
      body: JSON.stringify(['invalid']),
    });
    assert.equal(invalidBody.status, 400);

    for (const [path, payload] of [
      ['/wallets', { name: 'Invalid wallet', type: 'CRYPTO' }],
      ['/budgets', { categoryId: 'Food', amount: 1000, month: 13, year: 2026 }],
      ['/recurring', {
        title: ['invalid'],
        amount: 1000,
        categoryId: 'Bills',
        walletId: wallet.id,
        dueDate: 1,
      }],
      ['/chat', { message: ['invalid'] }],
      ['/transactions/scan', { imageBase64: 'not-base64' }],
    ] as const) {
      const invalidResource = await request(path, login.token, {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      assert.equal(invalidResource.response.status, 400);
    }

    for (const [payload, expectedMessage] of [
      [{ walletId: wallet.id, type: 'TRANSFER', amount: 1000 }, 'type'],
      [{ walletId: wallet.id, type: 'EXPENSE', amount: 0 }, 'amount'],
      [{ walletId: wallet.id, type: 'EXPENSE', amount: 1000, date: '2026-02-31' }, 'date'],
    ] as const) {
      const invalid = await request('/transactions', login.token, {
        method: 'POST',
        headers: { 'Idempotency-Key': `${key}-${expectedMessage}` },
        body: JSON.stringify(payload),
      });
      assert.equal(invalid.response.status, 400);
      assert.match(invalid.body.message, new RegExp(expectedMessage, 'i'));
    }

    const invalidLimit = await request('/transactions?limit=101', login.token);
    assert.equal(invalidLimit.response.status, 400);

    const temporaryEmail = `ownership-${Date.now()}@nala.test`;
    const registrationResponse = await fetch(`${apiUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: 'Ownership Test',
        email: temporaryEmail,
        password: 'password123',
      }),
    });
    const registration = await registrationResponse.json();
    assert.equal(registrationResponse.status, 201);
    temporaryUserId = registration.user.id;
    assert.equal(registration.accessToken, undefined);
    assert.equal(typeof registration.verificationToken, 'string');

    const loginBeforeVerification = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: temporaryEmail,
        password: 'password123',
      }),
    });
    assert.equal(loginBeforeVerification.status, 403);

    const verificationResponse = await fetch(`${apiUrl}/auth/verify-email`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: registration.verificationToken }),
    });
    assert.equal(verificationResponse.status, 200);
    const reusedVerification = await fetch(`${apiUrl}/auth/verify-email`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: registration.verificationToken }),
    });
    assert.equal(reusedVerification.status, 400);

    const initialLoginResponse = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: temporaryEmail,
        password: 'password123',
        deviceName: 'Integration verified device',
      }),
    });
    const initialLogin = await initialLoginResponse.json();
    assert.equal(initialLoginResponse.status, 200);

    const refreshResponse = await fetch(`${apiUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: initialLogin.refreshToken }),
    });
    const refreshed = await refreshResponse.json();
    assert.equal(refreshResponse.status, 200);
    assert.notEqual(refreshed.refreshToken, initialLogin.refreshToken);

    const reusedRefreshResponse = await fetch(`${apiUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: initialLogin.refreshToken }),
    });
    assert.equal(reusedRefreshResponse.status, 401);
    const temporaryToken = refreshed.accessToken;

    const walletCreation = await request('/wallets', temporaryToken, {
      method: 'POST',
      body: JSON.stringify({
        name: 'Integration Wallet',
        type: 'CASH',
        balance: 1000,
      }),
    });
    assert.equal(walletCreation.response.status, 201);
    assert.equal(walletCreation.body.wallet.balance, 1000);

    const foreignWalletBill = await request('/recurring', temporaryToken, {
      method: 'POST',
      body: JSON.stringify({
        title: 'Foreign wallet test',
        amount: 1000,
        categoryId: 'Bills',
        walletId: wallet.id,
        dueDate: 1,
      }),
    });
    assert.equal(foreignWalletBill.response.status, 404);

    const deleteWithoutPassword = await request(
      '/auth/me',
      temporaryToken,
      { method: 'DELETE', body: JSON.stringify({}) },
    );
    assert.equal(deleteWithoutPassword.response.status, 400);

    const deleteWithWrongPassword = await request(
      '/auth/me',
      temporaryToken,
      {
        method: 'DELETE',
        body: JSON.stringify({ password: 'definitely-wrong' }),
      },
    );
    assert.equal(deleteWithWrongPassword.response.status, 401);

    const secondLoginResponse = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: temporaryEmail,
        password: 'password123',
        deviceName: 'Integration second device',
      }),
    });
    const secondLogin = await secondLoginResponse.json();
    assert.equal(secondLoginResponse.status, 200);

    const sessions = await request('/auth/sessions', temporaryToken);
    assert.equal(sessions.response.status, 200);
    assert.equal(sessions.body.length, 2);

    const logout = await request('/auth/logout', secondLogin.accessToken, {
      method: 'POST',
    });
    assert.equal(logout.response.status, 200);
    const revokedAccess = await request('/auth/me', secondLogin.accessToken);
    assert.equal(revokedAccess.response.status, 403);

    const passwordChange = await request('/auth/password', temporaryToken, {
      method: 'PUT',
      body: JSON.stringify({
        oldPassword: 'password123',
        newPassword: 'password456',
      }),
    });
    assert.equal(passwordChange.response.status, 200);
    const revokedAfterPasswordChange = await request('/auth/me', temporaryToken);
    assert.equal(revokedAfterPasswordChange.response.status, 403);

    const loginAfterPasswordChangeResponse = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: temporaryEmail,
        password: 'password456',
        deviceName: 'Integration reauthenticated',
      }),
    });
    const loginAfterPasswordChange = await loginAfterPasswordChangeResponse.json();
    assert.equal(loginAfterPasswordChangeResponse.status, 200);

    const unknownResetResponse = await fetch(`${apiUrl}/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: `unknown-${Date.now()}@nala.test` }),
    });
    const unknownReset = await unknownResetResponse.json();
    assert.equal(unknownResetResponse.status, 200);
    assert.equal(unknownReset.resetToken, undefined);

    const resetRequestResponse = await fetch(`${apiUrl}/auth/forgot-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: temporaryEmail }),
    });
    const resetRequest = await resetRequestResponse.json();
    assert.equal(resetRequestResponse.status, 200);
    assert.equal(typeof resetRequest.resetToken, 'string');

    const resetResponse = await fetch(`${apiUrl}/auth/reset-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: resetRequest.resetToken,
        password: 'password789',
      }),
    });
    assert.equal(resetResponse.status, 200);

    const reusedResetResponse = await fetch(`${apiUrl}/auth/reset-password`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: resetRequest.resetToken,
        password: 'password999',
      }),
    });
    assert.equal(reusedResetResponse.status, 400);
    const revokedAfterReset = await request(
      '/auth/me',
      loginAfterPasswordChange.accessToken,
    );
    assert.equal(revokedAfterReset.response.status, 403);

    const loginAfterResetResponse = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: temporaryEmail,
        password: 'password789',
        deviceName: 'Integration reset session',
      }),
    });
    const loginAfterReset = await loginAfterResetResponse.json();
    assert.equal(loginAfterResetResponse.status, 200);

    const deleteWithPassword = await request(
      '/auth/me',
      loginAfterReset.accessToken,
      {
        method: 'DELETE',
        body: JSON.stringify({ password: 'password789' }),
      },
    );
    assert.equal(deleteWithPassword.response.status, 200);
    temporaryUserId = undefined;

    const payload = {
      walletId: wallet.id,
      type: 'EXPENSE',
      amount: 321,
      categoryId: 'Others',
      merchant: 'HTTP integration test',
      date: '2026-07-30T12:00:00.000Z',
    };
    const create = await request('/transactions', login.token, {
      method: 'POST',
      headers: { 'Idempotency-Key': key },
      body: JSON.stringify(payload),
    });
    assert.equal(create.response.status, 201);
    assert.equal(create.body.replayed, false);
    transactionId = create.body.transaction.id;

    const replay = await request('/transactions', login.token, {
      method: 'POST',
      headers: { 'Idempotency-Key': key },
      body: JSON.stringify(payload),
    });
    assert.equal(replay.response.status, 200);
    assert.equal(replay.body.replayed, true);
    assert.equal(replay.body.transaction.id, transactionId);

    const conflict = await request('/transactions', login.token, {
      method: 'POST',
      headers: { 'Idempotency-Key': key },
      body: JSON.stringify({ ...payload, amount: 322 }),
    });
    assert.equal(conflict.response.status, 409);

    const afterCreate = await request(`/wallets/${wallet.id}`, login.token);
    assert.equal(afterCreate.body.balance, initialBalance - payload.amount);

    const directBalanceEdit = await request(`/wallets/${wallet.id}`, login.token, {
      method: 'PUT',
      body: JSON.stringify({ balance: initialBalance + 999999 }),
    });
    assert.equal(directBalanceEdit.response.status, 400);

    const update = await request(
      `/transactions/${transactionId}`,
      login.token,
      {
        method: 'PUT',
        body: JSON.stringify({
          ...payload,
          type: 'INCOME',
          amount: 500,
        }),
      },
    );
    assert.equal(update.response.status, 200);
    assert.equal(update.body.transaction.type, 'INCOME');
    assert.equal(update.body.transaction.amount, 500);

    const afterUpdate = await request(`/wallets/${wallet.id}`, login.token);
    assert.equal(afterUpdate.body.balance, initialBalance + 500);

    const deletion = await request(
      `/transactions/${transactionId}`,
      login.token,
      { method: 'DELETE' },
    );
    assert.equal(deletion.response.status, 200);
    transactionId = undefined;

    const afterDelete = await request(`/wallets/${wallet.id}`, login.token);
    assert.equal(afterDelete.body.balance, initialBalance);

    const limitedEmail = `rate-${Date.now()}@nala.test`;
    let rateLimitStatus = 0;
    for (let attempt = 0; attempt < 11; attempt++) {
      const response = await fetch(`${apiUrl}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: limitedEmail,
          password: 'wrong-password',
        }),
      });
      rateLimitStatus = response.status;
    }
    assert.equal(rateLimitStatus, 429);
    console.log('Transaction HTTP integration test passed');
  } finally {
    const transaction = await prisma.transaction.findFirst({
      where: { idempotencyKey: key },
    });
    if (transaction) {
      await prisma.$transaction([
        prisma.transaction.delete({ where: { id: transaction.id } }),
        prisma.wallet.update({
          where: { id: transaction.walletId },
          data: {
            balance: {
              increment: transaction.type === 'INCOME'
                ? -transaction.amount
                : transaction.amount,
            },
          },
        }),
      ]);
    }
    if (temporaryUserId) {
      await prisma.$transaction(async (tx) => {
        await tx.recurringBill.deleteMany({ where: { userId: temporaryUserId } });
        await tx.transaction.deleteMany({ where: { userId: temporaryUserId } });
        await tx.budget.deleteMany({ where: { userId: temporaryUserId } });
        await tx.wallet.deleteMany({ where: { userId: temporaryUserId } });
        await tx.user.deleteMany({ where: { id: temporaryUserId } });
      });
    }
    await prisma.session.updateMany({
      where: {
        userId: login.user.id,
        deviceName: 'Integration primary',
        revokedAt: null,
      },
      data: { revokedAt: new Date() },
    });
    await prisma.$disconnect();
  }
};

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
