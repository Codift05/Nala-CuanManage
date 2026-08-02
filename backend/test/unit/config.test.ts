import assert from 'node:assert/strict';
import test from 'node:test';
import {
  getCorsOrigins,
  getEmailConfig,
  getJwtSecret,
  isOriginAllowed,
  validateProductionServices,
} from '../../src/utils/config';

test('production requires strong secrets and an explicit CORS allowlist', () => {
  assert.throws(() => getJwtSecret({ NODE_ENV: 'production' }), /JWT_SECRET/);
  assert.throws(
    () => getJwtSecret({ NODE_ENV: 'production', JWT_SECRET: 'too-short' }),
    /JWT_SECRET/,
  );
  assert.equal(
    getJwtSecret({
      NODE_ENV: 'production',
      JWT_SECRET: '12345678901234567890123456789012',
    }).length,
    32,
  );

  assert.throws(() => getCorsOrigins({ NODE_ENV: 'production' }), /CORS_ORIGINS/);
  const origins = getCorsOrigins({
    NODE_ENV: 'production',
    CORS_ORIGINS: 'https://nala.example,https://admin.nala.example',
  });
  assert.equal(isOriginAllowed(undefined, origins), true);
  assert.equal(isOriginAllowed('https://nala.example', origins), true);
  assert.equal(isOriginAllowed('https://evil.example', origins), false);

  assert.throws(
    () => getEmailConfig({ NODE_ENV: 'production' }),
    /RESEND_API_KEY/,
  );
  assert.equal(
    getEmailConfig({
      NODE_ENV: 'production',
      RESEND_API_KEY: 're_test',
      EMAIL_FROM: 'NALA <noreply@nala.example>',
      APP_URL: 'https://app.nala.example/reset',
    })?.appUrl,
    'https://app.nala.example/reset',
  );

  assert.throws(
    () => validateProductionServices({ NODE_ENV: 'production' }),
    /DATABASE_URL/,
  );
  assert.throws(
    () => validateProductionServices({
      NODE_ENV: 'production',
      DATABASE_URL: 'postgresql://database',
    }),
    /REDIS_URL/,
  );
  assert.doesNotThrow(() => validateProductionServices({
    NODE_ENV: 'production',
    DATABASE_URL: 'postgresql://database',
    REDIS_URL: 'redis://cache',
  }));
});
