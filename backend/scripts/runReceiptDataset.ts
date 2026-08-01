import { readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';

type DatasetCase = {
  id: string;
  image: string;
};

const main = async () => {
  const [manifestArgument, outputArgument] = process.argv.slice(2);
  const token = process.env.NALA_TEST_TOKEN;
  if (!manifestArgument || !outputArgument || !token) {
    throw new Error(
      'Usage: NALA_TEST_TOKEN=... npm run test:receipt-dataset -- <manifest.json> <results.json>',
    );
  }
  const apiUrl = process.env.NALA_API_URL ?? 'http://127.0.0.1:3001/api';
  const manifestPath = resolve(manifestArgument);
  const cases = JSON.parse(await readFile(manifestPath, 'utf8')) as DatasetCase[];
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
