import express from 'express';
import { createRecurringBill, getRecurringBills, deleteRecurringBill } from '../controllers/recurring';
import { authenticate } from '../middleware/auth';

const router = express.Router();

router.use(authenticate);

router.post('/', createRecurringBill);
router.get('/', getRecurringBills);
router.delete('/:id', deleteRecurringBill);

export default router;
