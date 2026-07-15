import crypto from 'crypto';

interface ExplainedMedication {
  name: string;
  purpose: string;
  dosage: string;
  sideEffects: string[];
  precautions: string;
}

interface ExplanationPayload {
  isPrescription: boolean;
  issue: 'none' | 'not_prescription' | 'blurry' | 'unreadable' | 'no_medications';
  issueMessage: string | null;
  patientExplanation: string | null;
  medications: ExplainedMedication[];
}

interface CacheEntry {
  explanation: ExplanationPayload;
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

const PROMPT = `Analiza la imagen de la receta médica y genera una explicación sencilla y detallada para el paciente en español.
   
Responde ÚNICAMENTE con un objeto JSON válido, sin markdown ni bloques de código:
{
  "isPrescription": boolean,
  "issue": "none" | "not_prescription" | "blurry" | "unreadable" | "no_medications",
  "issueMessage": "mensaje amable explicando el problema si isPrescription es false o hay problemas",
  "patientExplanation": "Resumen general de las instrucciones del médico, recomendaciones de reposo, alimentación, etc. (en español sencillo, máximo 3 frases)",
  "medications": [
    {
      "name": "Nombre comercial o genérico del medicamento",
      "purpose": "¿Para qué sirve? Explicación simple en una sola frase corta",
      "dosage": "Indicación de dosis y duración (ej. 1 tableta cada 8 horas por 7 días)",
      "sideEffects": ["Efecto secundario común 1", "Efecto secundario común 2"],
      "precautions": "Advertencia importante o recomendación (ej. Tomar con abundante agua, evitar alcohol, etc.)"
    }
  ]
}

Reglas estrictas:
- Si la imagen NO es receta médica: isPrescription=false, issue="not_prescription", issueMessage="mensaje explicativo", medications=[].
- Si parece receta pero está muy borrosa o ilegible: issue="blurry" o "unreadable".
- Si es receta pero no hay medicamentos claros: issue="no_medications".
- Si todo está bien: issue="none", isPrescription=true y completa todos los detalles amablemente.
- Mantén el vocabulario accesible para cualquier paciente sin conocimientos médicos.`;

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

async function callGeminiExplainerModel(
  apiKey: string,
  model: string,
  imageBase64: string,
  mimeType: string,
): Promise<ExplanationPayload> {
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
          maxOutputTokens: 2048,
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
      
      const cleaned = text.replace(/```json|```/g, '').trim();
      const start = cleaned.indexOf('{');
      const end = cleaned.lastIndexOf('}');
      if (start < 0 || end <= start) {
        throw new Error('Respuesta inválida del modelo');
      }

      const parsed = JSON.parse(cleaned.slice(start, end + 1)) as ExplanationPayload;
      if (parsed.issue === 'none') {
        parsed.issueMessage = null;
      }
      if (parsed.issueMessage === 'none' || parsed.issueMessage === 'null') {
        parsed.issueMessage = null;
      }
      return parsed;
    }

    const errText = await response.text();
    lastError = `Gemini error (${response.status}): ${errText.slice(0, 200)}`;

    if (isRetryableStatus(response.status) && attempt < RETRY_DELAYS_MS.length) {
      console.warn(
        `[explainer] ${model} ocupado (${response.status}), reintento ${attempt + 1}/${RETRY_DELAYS_MS.length}`,
      );
      await sleep(RETRY_DELAYS_MS[attempt]);
      continue;
    }

    throw new Error(lastError);
  }

  throw new Error(lastError);
}

export async function explainPrescriptionImage(
  imageBase64: string,
  mimeType = 'image/jpeg',
): Promise<ExplanationPayload> {
  const hash = crypto.createHash('sha256').update(imageBase64).digest('hex');
  const cached = cache.get(hash);
  if (cached && Date.now() - cached.at < CACHE_TTL_MS) {
    return cached.explanation;
  }

  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) {
    if (process.env.ENABLE_PRESCRIPTION_MOCK === 'true') {
      console.warn('[explainer] Gemini no configurado — usando mock demo');
      return {
        isPrescription: true,
        issue: 'none',
        issueMessage: null,
        patientExplanation: 'Tomar la azitromicina según lo indicado por 3 días completos para eliminar la infección de garganta. Evitar bebidas frías.',
        medications: [
          {
            name: 'Azitromicina Jarabe 200mg/5ml',
            purpose: 'Antibiótico para combatir infecciones bacterianas de las vías respiratorias.',
            dosage: 'Tomar 5 ml cada 24 horas por 3 días consecutivos.',
            sideEffects: ['Dolor de estómago leve', 'Náuseas', 'Diarrea transitoria'],
            precautions: 'Tomar preferiblemente 1 hora antes o 2 horas después de los alimentos. No suspender antes de los 3 días.',
          },
        ],
      };
    }
    throw new Error(
      'GEMINI_API_KEY no configurada en el backend. Activa ENABLE_PRESCRIPTION_MOCK=true en dev.',
    );
  }

  const models = modelCandidates();
  let lastError = 'No se pudo analizar la receta';

  for (const model of models) {
    try {
      const explanation = await callGeminiExplainerModel(apiKey, model, imageBase64, mimeType);
      cache.set(hash, { explanation, at: Date.now() });
      return explanation;
    } catch (error) {
      lastError = error instanceof Error ? error.message : lastError;
      const retryable =
        lastError.includes('503') ||
        lastError.includes('429') ||
        lastError.includes('404') ||
        lastError.includes('no longer available');
      if (retryable) {
        console.warn(`[explainer] ${model} falló, probando siguiente modelo…`);
        continue;
      }
      throw error;
    }
  }

  throw new Error(
    'El servicio de explicación de recetas está saturado. Espera un minuto e intenta de nuevo.',
  );
}
