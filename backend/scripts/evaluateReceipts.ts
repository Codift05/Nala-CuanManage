import { readFile } from 'node:fs/promises';
import { evaluateReceipts, ReceiptCase, ReceiptResult } from '../src/utils/receiptMetrics';

const main = async () => {
  const [manifestPath, resultsPath] = process.argv.slice(2);
  if (!manifestPath || !resultsPath) {
    throw new Error(
      'Usage: npm run evaluate:receipts -- <manifest.json> <results.json>',
    );
  }

  const [cases, results] = await Promise.all([
    readFile(manifestPath, 'utf8').then(
      (value) => JSON.parse(value) as ReceiptCase[],
    ),
    readFile(resultsPath, 'utf8').then(
      (value) => JSON.parse(value) as ReceiptResult[],
    ),
  ]);
  console.log(JSON.stringify(evaluateReceipts(cases, results), null, 2));
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
