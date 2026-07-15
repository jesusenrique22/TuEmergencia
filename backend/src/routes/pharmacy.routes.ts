import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {
  searchPrescriptionInventory,
  explainPrescription,
} from '../controllers/pharmacyPrescription.controller';

const router = Router();

/** Busca medicamentos de una receta en inventario de farmacias (Gemini opcional + PostgreSQL). */
router.post('/prescription/search', authenticate, searchPrescriptionInventory);

/** Analiza y explica las prescripciones médicas con IA (Gemini). */
router.post('/prescription/explain', authenticate, explainPrescription);

export default router;
