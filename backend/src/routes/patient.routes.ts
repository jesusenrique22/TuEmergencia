import { Router } from 'express';
import {
  getMyProfile,
  updateMyProfile,
  getMyMedicalHistory,
  getMyAppointments,
} from '../controllers/patient.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate, authorize(UserRole.PATIENT));

router.get('/profile', getMyProfile);
router.put('/profile', updateMyProfile);
router.get('/medical-history', getMyMedicalHistory);
router.get('/appointments', getMyAppointments);

export default router;
