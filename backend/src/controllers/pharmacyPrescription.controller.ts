import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { parsePrescriptionImage } from '../services/geminiPrescription.service';
import { explainPrescriptionImage } from '../services/geminiPrescriptionExplainer.service';
import { PrescriptionImageError } from '../services/prescriptionImageError';
import { searchPharmacyInventory } from '../services/prescriptionSearch.service';
import { dedupeMedications } from '../utils/medicationNormalizer';

interface SearchBody {
  imageBase64?: string;
  mimeType?: string;
  medications?: string[];
  lat?: number;
  lng?: number;
}

export const searchPrescriptionInventory = async (req: AuthRequest, res: Response) => {
  try {
    const body = req.body as SearchBody;
    let medicationNames = Array.isArray(body.medications)
      ? body.medications.filter((m) => typeof m === 'string' && m.trim())
      : [];

    let geminiUsed = false;
    let fromCache = false;

    if (body.imageBase64?.trim()) {
      const parsed = await parsePrescriptionImage(
        body.imageBase64.trim(),
        body.mimeType?.trim() || 'image/jpeg',
      );
      medicationNames = dedupeMedications([...medicationNames, ...parsed.medications]);
      geminiUsed = true;
      fromCache = parsed.fromCache;

      if (medicationNames.length === 0) {
        return res.status(422).json({
          error:
            'Parece una receta, pero no detectamos medicamentos. Verifica que se vean los nombres de los fármacos.',
          code: 'NO_MEDICATIONS',
          geminiUsed: true,
          fromCache,
          medications: [],
          pharmacies: [],
          bestFullCart: null,
          bestNearby: null,
        });
      }
    }

    if (medicationNames.length === 0) {
      return res.status(400).json({
        error:
          'Envía imageBase64 (foto de receta) o medications (lista de nombres) para buscar inventario.',
      });
    }

    const lat = typeof body.lat === 'number' ? body.lat : undefined;
    const lng = typeof body.lng === 'number' ? body.lng : undefined;

    const result = await searchPharmacyInventory(medicationNames, { lat, lng });

    res.json({
      ...result,
      geminiUsed,
      fromCache,
    });
  } catch (error) {
    if (error instanceof PrescriptionImageError) {
      console.warn('[prescription/search]', error.issue, error.message);
      return res.status(error.statusCode).json({
        error: error.message,
        code: error.issue.toUpperCase(),
        geminiUsed: true,
        fromCache: false,
        medications: [],
        pharmacies: [],
        bestFullCart: null,
        bestNearby: null,
      });
    }
    const message = error instanceof Error ? error.message : 'Error al buscar inventario';
    console.error('[prescription/search]', message);
    res.status(500).json({ error: message });
  }
};

export const explainPrescription = async (req: AuthRequest, res: Response) => {
  try {
    const body = req.body as { imageBase64?: string; mimeType?: string };
    if (!body.imageBase64?.trim()) {
      return res.status(400).json({
        error: 'Envía la imagen base64 de la receta para su explicación.',
      });
    }

    const result = await explainPrescriptionImage(
      body.imageBase64.trim(),
      body.mimeType?.trim() || 'image/jpeg',
    );

    res.json(result);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Error al explicar la receta';
    console.error('[prescription/explain]', message);
    res.status(500).json({ error: message });
  }
};
