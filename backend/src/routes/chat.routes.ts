import { Router } from 'express';
import {
  listConversations,
  getOrCreateConversation,
  getMessages,
  sendMessage,
} from '../controllers/chat.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate, authorize(UserRole.PATIENT, UserRole.DOCTOR));

router.get('/conversations', listConversations);
router.post('/conversations', getOrCreateConversation);
router.get('/conversations/:conversationId/messages', getMessages);
router.post('/messages', sendMessage);

export default router;
