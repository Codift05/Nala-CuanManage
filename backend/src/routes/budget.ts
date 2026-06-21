import { Router } from 'express';
import {
  createBudget,
  getBudgets,
  updateBudget,
  deleteBudget
} from '../controllers/budget';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.post('/', createBudget);
router.get('/', getBudgets);
router.put('/:id', updateBudget);
router.delete('/:id', deleteBudget);

export default router;
