import { Router } from 'express';
import { chatWithNala } from '../controllers/chat';
import { authenticate } from '../middleware/auth';
import { rateLimit } from '../middleware/rateLimit';

const router = Router();

router.post('/', authenticate, rateLimit({
  prefix: 'chat',
  limit: 20,
  windowSeconds: 60,
}), chatWithNala);

export default router;
