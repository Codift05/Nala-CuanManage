import { Router } from 'express';
import { register, login, me, updateProfile, changePassword, deleteAccount } from '../controllers/auth';
import { authenticate } from '../middleware/auth';
import { rateLimit } from '../middleware/rateLimit';

const router = Router();

router.post('/register', rateLimit({
  prefix: 'register',
  limit: 20,
  windowSeconds: 60 * 60,
}), register);
router.post('/login', rateLimit({
  prefix: 'login',
  limit: 10,
  windowSeconds: 60,
  includeEmail: true,
}), login);
router.get('/me', authenticate, me);
router.put('/profile', authenticate, updateProfile);
router.put('/password', authenticate, changePassword);
router.delete('/me', authenticate, deleteAccount);

export default router;
