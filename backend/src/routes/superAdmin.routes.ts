import { Router } from 'express';
import {
  getOverviewStats,
  getFacilityStats,
  getPharmacyStats,
  listFacilities,
  createFacility,
  listPharmacies,
  setFacilityService,
  setPharmacyService,
  createClinicAdmin,
  createPharmacyAdmin,
  listManagedUsers,
} from '../controllers/superAdmin.controller';
import { authenticate, authorizeSuperAdmin } from '../middleware/auth';

const router = Router();

router.use(authenticate, authorizeSuperAdmin());

router.get('/stats/overview', getOverviewStats);
router.get('/stats/facilities', getFacilityStats);
router.get('/stats/pharmacies', getPharmacyStats);
router.get('/facilities', listFacilities);
router.post('/facilities', createFacility);
router.get('/pharmacies', listPharmacies);
router.patch('/facilities/:id/service', setFacilityService);
router.patch('/pharmacies/:id/service', setPharmacyService);
router.post('/admins/clinic', createClinicAdmin);
router.post('/admins/pharmacy', createPharmacyAdmin);
router.get('/admins', listManagedUsers);

export default router;
