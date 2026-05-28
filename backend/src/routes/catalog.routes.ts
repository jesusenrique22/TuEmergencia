import { Router } from 'express';
import {
  listSpecialties,
  listFacilities,
  listDoctors,
  doctorAvailability,
} from '../controllers/catalog.controller';

const router = Router();

router.get('/specialties', listSpecialties);
router.get('/facilities', listFacilities);
router.get('/doctors', listDoctors);
router.get('/doctors/:doctorId/availability', doctorAvailability);

export default router;
