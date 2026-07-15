/** Aliases comunes → nombre canónico para matching en inventario. */
const ALIASES: Record<string, string[]> = {
  amoxicilina: ['amoxicilina', 'amox', 'amoxicillin'],
  ibuprofeno: ['ibuprofeno', 'ibu', 'advil', 'motrin'],
  paracetamol: ['paracetamol', 'acetaminofen', 'acetaminofén', 'tylenol', 'dolex'],
  losartan: ['losartan', 'losartán', 'cozaar'],
  omeprazol: ['omeprazol', 'prilosec'],
  loratadina: ['loratadina', 'claritine', 'clarityne'],
  metformina: ['metformina', 'glucophage'],
  enalapril: ['enalapril', 'vasotec'],
  atorvastatina: ['atorvastatina', 'lipitor'],
  azitromicina: ['azitromicina', 'azithromycin', 'zithromax', 'zitromax'],
};

function stripAccents(value: string): string {
  return value.normalize('NFD').replace(/\p{M}/gu, '');
}

/** Normaliza texto de receta o nombre de producto para comparación. */
export function normalizeMedicationToken(raw: string): string {
  let s = stripAccents(raw.toLowerCase());
  s = s.replace(/\d+\s*(mg|mcg|g|ml|ui|%)/gi, '').trim();
  s = s.replace(/[^a-z0-9\s]/g, ' ').replace(/\s+/g, ' ').trim();

  for (const [canonical, aliases] of Object.entries(ALIASES)) {
    if (aliases.some((alias) => s.includes(alias)) || s.includes(canonical)) {
      return canonical;
    }
  }

  const first = s.split(' ').find((part) => part.length >= 4);
  return first ?? s;
}

export function productMatchesMedication(productName: string, normalizedMed: string): boolean {
  const productNorm = normalizeMedicationToken(productName);
  if (!productNorm || !normalizedMed) return false;
  return (
    productNorm.includes(normalizedMed) ||
    normalizedMed.includes(productNorm) ||
    productNorm.split(' ')[0] === normalizedMed
  );
}

export function dedupeMedications(names: string[]): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const name of names) {
    const trimmed = name.trim();
    if (!trimmed) continue;
    const key = normalizeMedicationToken(trimmed);
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(trimmed);
  }
  return result;
}
