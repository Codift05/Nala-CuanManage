import { readFile, writeFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import {
  AiCoachCase,
  AiCoachResult,
  evaluateAiCoach,
} from '../src/utils/aiCoachMetrics';

const main = async () => {
  const [casesArgument, outputArgument] = process.argv.slice(2);
  if (!casesArgument || !outputArgument) {
    throw new Error(
      'Usage: npm run evaluate:ai-coach-live -- <cases.json> <results.json>',
    );
  }
  if (process.env.NALA_AI_EVAL_CONFIRM !== 'YES') {
    throw new Error('Set NALA_AI_EVAL_CONFIRM=YES to allow live API usage');
  }
  const limit = Number(process.env.NALA_AI_EVAL_LIMIT);
  if (!Number.isSafeInteger(limit) || limit <= 0) {
    throw new Error('Set a positive NALA_AI_EVAL_LIMIT request cap');
  }

  const apiUrl = process.env.NALA_API_URL ?? 'http://127.0.0.1:3001/api';
  let token = process.env.NALA_TEST_TOKEN;
  if (!token && process.env.NALA_TEST_EMAIL && process.env.NALA_TEST_PASSWORD) {
    const response = await fetch(`${apiUrl}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: process.env.NALA_TEST_EMAIL,
        password: process.env.NALA_TEST_PASSWORD,
        deviceName: 'AI Coach evaluation runner',
      }),
    });
    const body = await response.json() as {
      token?: string;
      accessToken?: string;
    };
    token = body.accessToken ?? body.token;
  }
  if (!token) throw new Error('Token or test-account credentials are required');

  const casesPath = resolve(casesArgument);
  const cases = (JSON.parse(await readFile(casesPath, 'utf8')) as AiCoachCase[])
    .slice(0, limit);
  const results: AiCoachResult[] = [];

  for (const item of cases) {
    const startedAt = performance.now();
    const response = await fetch(`${apiUrl}/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ message: item.prompt }),
    });
    const body = await response.json() as Record<string, unknown>;
    results.push({
      id: item.id,
      statusCode: response.status,
      latencyMs: Math.round(performance.now() - startedAt),
      reply: typeof body.reply === 'string' ? body.reply : '',
      fallback: body.fallback === true,
      transactionDraft: body.transactionDraft &&
        typeof body.transactionDraft === 'object'
        ? body.transactionDraft as Record<string, unknown>
        : null,
    });
  }

  const report = {
    metadata: {
      generatedAt: new Date().toISOString(),
      apiUrl,
      model: process.env.GEMINI_MODEL ?? 'server-configured',
      requestCount: results.length,
      casesFile: casesPath,
    },
    metrics: evaluateAiCoach(cases, results),
    results,
  };
  await writeFile(resolve(outputArgument), `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report.metrics, null, 2));
};

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
