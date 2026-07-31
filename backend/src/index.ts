import 'dotenv/config';
import express, { NextFunction, Request, Response } from 'express';
import cors from 'cors';
import { rupiahToJson } from './utils/money';
import { getCorsOrigins, getEmailConfig, isOriginAllowed } from './utils/config';
import { requestContext } from './middleware/requestContext';

const app = express();
const port = process.env.PORT || 3000;
const corsOrigins = getCorsOrigins();
getEmailConfig();

app.set('json replacer', (_key: string, value: unknown) =>
  typeof value === 'bigint' ? rupiahToJson(value) : value
);
app.use(requestContext);
app.use(cors({
  origin: (origin, callback) => callback(
    isOriginAllowed(origin, corsOrigins)
      ? null
      : new Error('Origin tidak diizinkan'),
    isOriginAllowed(origin, corsOrigins),
  ),
}));
app.use(express.json({ limit: '2mb' }));
app.use((req, res, next) => {
  if (
    req.body !== undefined &&
    (req.body === null || typeof req.body !== 'object' || Array.isArray(req.body))
  ) {
    return res.status(400).json({ message: 'JSON body must be an object' });
  }
  next();
});

import authRoutes from './routes/auth';
import walletRoutes from './routes/wallet';
import transactionRoutes from './routes/transaction';
import budgetRoutes from './routes/budget';
import healthRoutes from './routes/health';
import chatRoutes from './routes/chat';
import recurringRoutes from './routes/recurring';
import { initRecurringJob } from './cron/recurringJob';

app.use('/api/auth', authRoutes);
app.use('/api/wallets', walletRoutes);
app.use('/api/transactions', transactionRoutes);
app.use('/api/budgets', budgetRoutes);
app.use('/api/health', healthRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/recurring', recurringRoutes);

app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'NALA Backend API is running' });
});

app.use((_req, res) => {
  res.status(404).json({ message: 'Endpoint not found' });
});

app.use((
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) => {
  console.error('Unhandled request error:', error);
  if (res.headersSent) return;
  const status = error instanceof SyntaxError ? 400 : 500;
  res.status(status).json({
    message: status === 400 ? 'Invalid JSON body' : 'Internal server error',
  });
});

initRecurringJob();

app.listen(Number(port), '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
