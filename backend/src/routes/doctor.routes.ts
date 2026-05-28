import { Router } from 'express';
import {
  changeMyPassword,
  getMyProfile,
  updateMyProfile,
  getMySchedules,
  createSchedule,
  updateSchedule,
  deleteSchedule,
  getMyAppointments,
  updateAppointmentStatus,
  getPatientMedicalHistory,
  addMedicalHistoryEntry,
  getMyPatients,
  updatePatientWeightControls,
  acceptClinicInvitation,
  rejectClinicInvitation,
} from '../controllers/doctor.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

router.use(authenticate, authorize(UserRole.DOCTOR));

router.get('/profile', getMyProfile);
router.put('/profile', updateMyProfile);
router.patch('/profile/password', changeMyPassword);
router.get('/schedules', getMySchedules);
router.post('/schedules', createSchedule);
router.put('/schedules/:id', updateSchedule);
router.delete('/schedules/:id', deleteSchedule);
router.get('/appointments', getMyAppointments);
router.patch('/appointments/:id', updateAppointmentStatus);
router.get('/patients', getMyPatients);
router.get('/patients/:patientId/medical-history', getPatientMedicalHistory);
router.post('/patients/:patientId/medical-history/entries', addMedicalHistoryEntry);
router.put('/patients/:patientId/weight-controls', updatePatientWeightControls);
router.post('/clinic-invitations/:id/accept', acceptClinicInvitation);
router.post('/clinic-invitations/:id/reject', rejectClinicInvitation);

export default router;
