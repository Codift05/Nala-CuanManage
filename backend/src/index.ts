import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

import authRoutes from './routes/auth';
import walletRoutes from './routes/wallet';
import transactionRoutes from './routes/transaction';
import budgetRoutes from './routes/budget';
import healthRoutes from './routes/health';
import chatRoutes from './routes/chat';
import recurringRoutes from './routes/recurring';

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

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

app.listen(Number(port), '0.0.0.0', () => {
  console.log(`Server is running on port ${port}`);
});
