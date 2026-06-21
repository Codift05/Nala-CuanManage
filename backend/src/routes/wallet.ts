import { Router } from 'express';
import {
  createWallet,
  getWallets,
  getWalletById,
  updateWallet,
  deleteWallet
} from '../controllers/wallet';
import { authenticate } from '../middleware/auth';

const router = Router();

router.use(authenticate);

router.post('/', createWallet);
router.get('/', getWallets);
router.get('/:id', getWalletById);
router.put('/:id', updateWallet);
router.delete('/:id', deleteWallet);

export default router;
