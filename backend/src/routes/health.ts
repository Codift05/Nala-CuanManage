import { Router } from 'express';
import { getHealthScore } from '../controllers/health';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/score', authenticate, getHealthScore);

export default router;
