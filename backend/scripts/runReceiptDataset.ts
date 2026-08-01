import { readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

type DatasetCase = {
  id: string;
  image: string;
};

const main = async () => {
  const [manifestArgument, outputArgument] = process.argv.slice(2);
  if (!manifestArgument || !outputArgument) {
    throw new Error(
      'Usage: npm run test:receipt-dataset -- <manifest.json> <results.json>',
    );
  }
  const apiUrl = process.env.NALA_API_URL ?? 'http://127.0.0.1:3001/api';
  let token = process.env.NALA_TEST_TOKEN;
  if (!token && process.env.NALA_TEST_EMAIL && process.env.NALA_TEST_PASSWORD) {
    const login = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: process.env.NALA_TEST_EMAIL,
        password: process.env.NALA_TEST_PASSWORD,
        deviceName: 'Receipt dataset runner',
      }),
    });
    const body = await login.json() as { token?: string };
    token = body.token;
  }
  if (!token) throw new Error('Token atau kredensial akun test diperlukan');

  const manifestPath = resolve(manifestArgument);
  const allCases = JSON.parse(
    await readFile(manifestPath, 'utf8'),
  ) as DatasetCase[];
  const limit = Number(process.env.NALA_RECEIPT_LIMIT ?? allCases.length);
  const cases = allCases.slice(0, Number.isSafeInteger(limit) && limit > 0
    ? limit
    : allCases.length);
  const results = [];

  for (const item of cases) {
    const image = await readFile(resolve(dirname(manifestPath), item.image));
    const startedAt = performance.now();
    const response = await fetch(`${apiUrl}/transactions/scan`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ imageBase64: image.toString('base64') }),
    });
    const latencyMs = Math.round(performance.now() - startedAt);
    const body = await response.json() as Record<string, unknown>;
    results.push({
      id: item.id,
      prediction: response.ok ? {
        amount: body.amount,
        merchant: body.merchant,
        categoryId: body.categoryId,
      } : null,
      reviewRequired: response.ok ? body.reviewRequired : [],
      correctedFields: [],
      latencyMs,
      statusCode: response.status,
    });
  }

  await writeFile(resolve(outputArgument), `${JSON.stringify(results, null, 2)}\n`);
  console.log(`Tested ${results.length} receipts against ${apiUrl}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
