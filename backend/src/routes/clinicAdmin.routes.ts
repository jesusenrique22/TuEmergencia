import { Router } from 'express';
import {
  getMyContext,
  getDashboard,
  listDoctors,
  listAssignableDoctors,
  assignDoctor,
  unassignDoctor,
  createDoctor,
  changeMyPassword,
} from '../controllers/clinicAdmin.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate, authorize(UserRole.CLINIC_ADMIN));

router.get('/me', getMyContext);
router.get('/dashboard', getDashboard);
router.get('/doctors', listDoctors);
router.get('/doctors/assignable', listAssignableDoctors);
router.post('/doctors/assign', assignDoctor);
router.delete('/doctors/:doctorUserId', unassignDoctor);
router.post('/doctors', createDoctor);
router.patch('/password', changeMyPassword);

export default router;
