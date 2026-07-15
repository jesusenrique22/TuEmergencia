import crypto from 'crypto';
import { dedupeMedications } from '../utils/medicationNormalizer';
import {
  PRESCRIPTION_ISSUE_MESSAGES,
  PrescriptionImageError,
  PrescriptionImageIssue,
} from './prescriptionImageError';

interface CacheEntry {
  medications: string[];
  at: number;
}

const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
const cache = new Map<string, CacheEntry>();

const FALLBACK_MODELS = [
  'gemini-3.5-flash',
  'gemini-3.1-flash-lite',
  'gemini-2.5-flash',
] as const;

const RETRY_DELAYS_MS = [1500, 3000];

const PROMPT = `Analiza la imagen y decide si es una receta médica o prescripción de medicamentos.

Responde ÚNICAMENTE con JSON válido, sin markdown:
{
  "isPrescription": boolean,
  "imageQuality": "good" | "blurry" | "dark" | "unreadable",
  "issue": "none" | "not_prescription" | "blurry" | "unreadable" | "no_medications",
  "issueMessage": "mensaje breve en español para el paciente o null",
  "medications": [{"name": "nombre medicamento", "dosage": "opcional", "quantity": "opcional"}]
}

Reglas estrictas:
- Si la imagen NO es receta médica (selfie, paisaje, comida, ticket, cédula, pantalla sin receta, etc.): isPrescription=false, issue="not_prescription".
- Si parece receta pero está borrosa, movida, oscura o ilegible: issue="blurry" o "unreadable".
- Si es receta legible pero no hay medicamentos detectables: issue="no_medications".
- Si todo está bien: issue="none" y lista los medicamentos en medications.
- No inventes medicamentos. Si no lees uno con certeza, omítelo.
- issueMessage debe ser claro y amable en español, indicando qué hacer.`;

interface GeminiPrescriptionPayload {
  isPrescription?: boolean;
  imageQuality?: string;
  issue?: string;
  issueMessage?: string | null;
  medications?: Array<{ name?: string }>;
}

function parseGeminiResponse(text: string): {
  medications: string[];
  issue: PrescriptionImageIssue | null;
  userMessage: string | null;
} {
  const cleaned = text.replace(/```json|```/g, '').trim();
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return {
      medications: [],
      issue: 'unreadable',
      userMessage: PRESCRIPTION_ISSUE_MESSAGES.unreadable,
    };
  }

  const parsed = JSON.parse(cleaned.slice(start, end + 1)) as GeminiPrescriptionPayload;
  const medications = dedupeMedications(
    (parsed.medications ?? [])
      .map((m) => m.name?.trim() ?? '')
      .filter(Boolean),
  );

  const rawIssue = parsed.issue?.trim() ?? 'none';
  const quality = parsed.imageQuality?.trim() ?? 'good';
  const customMessage = parsed.issueMessage?.trim() || null;

  if (rawIssue === 'not_prescription' || parsed.isPrescription === false) {
    return {
      medications: [],
      issue: 'not_prescription',
      userMessage: customMessage ?? PRESCRIPTION_ISSUE_MESSAGES.not_prescription,
    };
  }

  if (rawIssue === 'blurry' || quality === 'blurry' || quality === 'dark') {
    return {
      medications,
      issue: 'blurry',
      userMessage: customMessage ?? PRESCRIPTION_ISSUE_MESSAGES.blurry,
    };
  }

  if (rawIssue === 'unreadable' || quality === 'unreadable') {
    return {
      medications,
      issue: 'unreadable',
      userMessage: customMessage ?? PRESCRIPTION_ISSUE_MESSAGES.unreadable,
    };
  }

  if (medications.length === 0) {
    return {
      medications: [],
      issue: 'no_medications',
      userMessage: customMessage ?? PRESCRIPTION_ISSUE_MESSAGES.no_medications,
    };
  }

  return { medications, issue: null, userMessage: null };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function modelCandidates(): string[] {
  const primary = process.env.GEMINI_MODEL?.trim();
  const list = primary ? [primary, ...FALLBACK_MODELS.filter((m) => m !== primary)] : [...FALLBACK_MODELS];
  return [...new Set(list)];
}

function isRetryableStatus(status: number): boolean {
  return status === 429 || status === 503;
}

function assertValidImageAnalysis(analysis: {
  medications: string[];
  issue: PrescriptionImageIssue | null;
  userMessage: string | null;
}): string[] {
  if (analysis.issue) {
    throw new PrescriptionImageError(
      analysis.userMessage ?? PRESCRIPTION_ISSUE_MESSAGES[analysis.issue],
      analysis.issue,
    );
  }
  return analysis.medications;
}

async function callGeminiModel(
  apiKey: string,
  model: string,
  imageBase64: string,
  mimeType: string,
): Promise<string[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  let lastError = 'Error desconocido';

  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: PROMPT },
              {
                inline_data: {
                  mime_type: mimeType,
                  data: imageBase64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          temperature: 0.1,
          maxOutputTokens: 1024,
          responseMimeType: 'application/json',
        },
      }),
    });

    if (response.ok) {
      const data = (await response.json()) as {
        candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
      };
      const text =
        data.candidates?.[0]?.content?.parts?.map((p) => p.text ?? '').join('') ?? '';
      const analysis = parseGeminiResponse(text);
      return assertValidImageAnalysis(analysis);
    }

    const errText = await response.text();
    lastError = `Gemini error (${response.status}): ${errText.slice(0, 200)}`;

    if (isRetryableStatus(response.status) && attempt < RETRY_DELAYS_MS.length) {
      console.warn(
        `[prescription] ${model} ocupado (${response.status}), reintento ${attempt + 1}/${RETRY_DELAYS_MS.length}`,
      );
      await sleep(RETRY_DELAYS_MS[attempt]);
      continue;
    }

    throw new Error(lastError);
  }

  throw new Error(lastError);
}

/** Gemini Vision — una llamada por imagen; con caché por hash. */
export async function parsePrescriptionImage(
  imageBase64: string,
  mimeType = 'image/jpeg',
): Promise<{ medications: string[]; fromCache: boolean }> {
  const hash = crypto.createHash('sha256').update(imageBase64).digest('hex');
  const cached = cache.get(hash);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) {
    return { medications: cached.medications, fromCache: true };
  }

  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    if (process.env.ENABLE_PRESCRIPTION_MOCK === 'true') {
      console.warn('[prescription] Gemini no configurado — usando parse demo (Azitromicina)');
      return {
        medications: ['Azitromicina Jarabe 200mg/5ml'],
        fromCache: false,
      };
    }
    throw new Error(
      'GEMINI_API_KEY no configurada en el backend. Usa medications[] en el body para probar sin IA, o ENABLE_PRESCRIPTION_MOCK=true en dev.',
    );
  }

  const models = modelCandidates();
  let lastError = 'No se pudo leer la receta';

  for (const model of models) {
    try {
      const medications = await callGeminiModel(apiKey, model, imageBase64, mimeType);
      cache.set(hash, { medications, at: Date.now() });
      if (model !== models[0]) {
        console.info(`[prescription] OK con modelo alternativo: ${model}`);
      }
      return { medications, fromCache: false };
    } catch (error) {
      if (error instanceof PrescriptionImageError) {
        throw error;
      }
      lastError = error instanceof Error ? error.message : lastError;
      const retryable =
        lastError.includes('503') ||
        lastError.includes('429') ||
        lastError.includes('404') ||
        lastError.includes('no longer available');
      if (retryable) {
        console.warn(`[prescription] ${model} falló, probando siguiente modelo…`);
        continue;
      }
      throw error instanceof Error ? error : new Error(lastError);
    }
  }

  throw new Error(
    'El servicio de lectura de recetas está saturado. Espera un minuto e intenta de nuevo, o busca el medicamento por nombre.',
  );
}
