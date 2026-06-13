import { Router } from 'express';
import { chatWithNala } from '../controllers/chat';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/', authenticate, chatWithNala);

export default router;
