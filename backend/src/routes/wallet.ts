import { Router } from 'express';
import {
  createWallet,
  getWallets,
  getWalletById,
  updateWallet,
  deleteWallet
} from '../controllers/wallet';
import { authenticateToken } from '../middlewares/auth';

const router = Router();

router.use(authenticateToken);

router.post('/', createWallet);
router.get('/', getWallets);
router.get('/:id', getWalletById);
router.put('/:id', updateWallet);
router.delete('/:id', deleteWallet);

export default router;
