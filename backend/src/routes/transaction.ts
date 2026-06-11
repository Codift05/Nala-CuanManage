import { Router } from 'express';
import {
  createTransaction,
  getTransactions,
  getTransactionById,
  deleteTransaction
} from '../controllers/transaction';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.use(authenticateToken);

router.post('/', createTransaction);
router.get('/', getTransactions);
router.get('/:id', getTransactionById);
router.delete('/:id', deleteTransaction);

export default router;
