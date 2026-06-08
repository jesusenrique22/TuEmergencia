import { Router } from 'express';
import {
  cancelEmergency,
  getEmergency,
  getEmergencyChatMessages,
  listClinicAmbulances,
  listMyEmergencies,
  patchClinicAmbulance,
  patchEmergencyLocation,
  patchEmergencyStatus,
  postClinicAmbulance,
  postEmergency,
  postEmergencyChatMessage,
} from '../controllers/emergency.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate);

router.post('/', authorize(UserRole.PATIENT), postEmergency);
router.get('/mine', listMyEmergencies);

router.get(
  '/clinic/ambulances',
  authorize(UserRole.CLINIC_ADMIN),
  listClinicAmbulances,
);
router.post(
  '/clinic/ambulances',
  authorize(UserRole.CLINIC_ADMIN),
  postClinicAmbulance,
);
router.patch(
  '/clinic/ambulances/:unitId',
  authorize(UserRole.CLINIC_ADMIN),
  patchClinicAmbulance,
);

router.get('/:id', getEmergency);
router.patch('/:id/status', patchEmergencyStatus);
router.patch('/:id/location', authorize(UserRole.AMBULANCE_DRIVER), patchEmergencyLocation);
router.post('/:id/cancel', authorize(UserRole.PATIENT), cancelEmergency);
router.get('/:id/messages', getEmergencyChatMessages);
router.post('/:id/messages', postEmergencyChatMessage);

export default router;
