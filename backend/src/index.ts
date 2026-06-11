import express, { Request, Response } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

import authRoutes from './routes/auth';

app.use('/api/auth', authRoutes);

app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'NALA Backend API is running' });
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
