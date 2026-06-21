import { Router } from 'express';
import {
  createTransaction,
  getTransactions,
  getTransactionById,
  deleteTransaction,
  updateTransaction
} from '../controllers/transaction';
import { scanReceipt } from '../controllers/ocr';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.post('/scan', scanReceipt);
router.post('/', createTransaction);
router.get('/', getTransactions);
router.get('/:id', getTransactionById);
router.put('/:id', updateTransaction);
router.delete('/:id', deleteTransaction);

export default router;
