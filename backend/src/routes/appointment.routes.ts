import { Router } from 'express';
import {
  createAppointment,
  getAppointmentById,
  cancelAppointment,
  rateAppointment,
} from '../controllers/appointment.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate);

router.post(
  '/',
  authorize(UserRole.PATIENT, UserRole.DOCTOR, UserRole.SUPER_ADMIN, UserRole.ADMIN),
  createAppointment,
);
router.get('/:id', getAppointmentById);
router.patch('/:id/cancel', cancelAppointment);
router.post('/:id/rate', authorize(UserRole.PATIENT), rateAppointment);

export default router;
