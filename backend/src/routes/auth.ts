import { Router } from 'express';
import {
  register, login, me, updateProfile, changePassword, deleteAccount,
  refreshSession, logout, getSessions, revokeSession,
  requestPasswordReset, resetPassword,
  verifyEmail, resendVerification,
} from '../controllers/auth';
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
router.post('/refresh', rateLimit({
  prefix: 'refresh',
  limit: 30,
  windowSeconds: 60,
}), refreshSession);
router.post('/forgot-password', rateLimit({
  prefix: 'forgot-password',
  limit: 5,
  windowSeconds: 60 * 60,
  includeEmail: true,
}), requestPasswordReset);
router.post('/reset-password', rateLimit({
  prefix: 'reset-password',
  limit: 10,
  windowSeconds: 60,
}), resetPassword);
router.post('/verify-email', rateLimit({
  prefix: 'verify-email',
  limit: 10,
  windowSeconds: 60,
}), verifyEmail);
router.post('/resend-verification', rateLimit({
  prefix: 'resend-verification',
  limit: 5,
  windowSeconds: 60 * 60,
  includeEmail: true,
}), resendVerification);
router.get('/me', authenticate, me);
router.post('/logout', authenticate, logout);
router.get('/sessions', authenticate, getSessions);
router.delete('/sessions/:id', authenticate, revokeSession);
router.put('/profile', authenticate, updateProfile);
router.put('/password', authenticate, changePassword);
router.delete('/me', authenticate, deleteAccount);

export default router;
