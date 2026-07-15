import { Router } from 'express';
import {
  getCompanies,
  getMyPolicy,
  updateMyPolicy,
  calculateCopay,
  getMyInvoices,
  createInvoice,
} from '../controllers/insurance.controller';
import { authenticate, authorize } from '../middleware/auth';
import { UserRole } from '../types/enums';

const router = Router();

// Todas las rutas de seguros requieren que el usuario esté autenticado
router.use(authenticate);

// Listar compañías y coberturas generales
router.get('/companies', getCompanies);

// Calcular copagos
router.post('/calculate-copay', calculateCopay);

// Rutas exclusivas del Paciente (obtener/registrar póliza, listar facturas médicas de seguro)
router.use(authorize(UserRole.PATIENT));

router.get('/policy', getMyPolicy);
router.post('/policy', updateMyPolicy);
router.get('/invoices', getMyInvoices);
router.post('/invoices', createInvoice);

export default router;
