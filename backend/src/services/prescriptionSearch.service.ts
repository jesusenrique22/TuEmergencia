import { prisma } from '../lib/prisma';
import { distanceKm } from '../utils/geo';
import {
  dedupeMedications,
  normalizeMedicationToken,
  productMatchesMedication,
} from '../utils/medicationNormalizer';

const IVA_RATE = 0.12;

export interface MedicationDetected {
  detected: string;
  normalized: string;
}

export interface MatchedProduct {
  productId: string;
  name: string;
  brand: string | null;
  price: number;
  stock: number;
  matchedMedication: string;
}

export interface PharmacyInventoryMatch {
  pharmacy: {
    id: string;
    name: string;
    address: string;
    logoUrl: string | null;
    latitude: number | null;
    longitude: number | null;
    distanceKm: number | null;
  };
  items: MatchedProduct[];
  missing: string[];
  completeness: number;
  subtotal: number;
  tax: number;
  total: number;
}

export interface PrescriptionSearchResult {
  medications: MedicationDetected[];
  pharmacies: PharmacyInventoryMatch[];
  bestFullCart: PharmacyInventoryMatch | null;
  bestNearby: PharmacyInventoryMatch | null;
  geminiUsed: boolean;
  fromCache: boolean;
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

export async function searchPharmacyInventory(
  rawMedicationNames: string[],
  options?: { lat?: number; lng?: number },
): Promise<Omit<PrescriptionSearchResult, 'geminiUsed' | 'fromCache'>> {
  const uniqueNames = dedupeMedications(rawMedicationNames);
  const medications: MedicationDetected[] = uniqueNames.map((detected) => ({
    detected,
    normalized: normalizeMedicationToken(detected),
  }));

  if (medications.length === 0) {
    return {
      medications: [],
      pharmacies: [],
      bestFullCart: null,
      bestNearby: null,
    };
  }

  const products = await prisma.pharmacyProduct.findMany({
    where: {
      isAvailable: true,
      stock: { gt: 0 },
      pharmacy: { isActive: true, serviceEnabled: true },
    },
    include: { pharmacy: true },
  });

  const pharmacyMap = new Map<string, PharmacyInventoryMatch>();

  for (const product of products) {
    const pharmacy = product.pharmacy;
    let entry = pharmacyMap.get(pharmacy.id);
    if (!entry) {
      const distance =
        options?.lat != null &&
        options?.lng != null &&
        pharmacy.latitude != null &&
        pharmacy.longitude != null
          ? round2(distanceKm(options.lat, options.lng, pharmacy.latitude, pharmacy.longitude))
          : null;

      entry = {
        pharmacy: {
          id: pharmacy.id,
          name: pharmacy.name,
          address: pharmacy.address,
          logoUrl: pharmacy.logoUrl,
          latitude: pharmacy.latitude,
          longitude: pharmacy.longitude,
          distanceKm: distance,
        },
        items: [],
        missing: [],
        completeness: 0,
        subtotal: 0,
        tax: 0,
        total: 0,
      };
      pharmacyMap.set(pharmacy.id, entry);
    }

    for (const med of medications) {
      const alreadyMatched = entry.items.some(
        (i) => i.matchedMedication === med.detected,
      );
      if (alreadyMatched) continue;

      if (productMatchesMedication(product.name, med.normalized)) {
        entry.items.push({
          productId: product.id,
          name: product.name,
          brand: product.brand,
          price: product.price,
          stock: product.stock,
          matchedMedication: med.detected,
        });
        break;
      }
    }
  }

  const pharmacies: PharmacyInventoryMatch[] = [];

  for (const entry of pharmacyMap.values()) {
    const matchedMeds = new Set(entry.items.map((i) => i.matchedMedication));
    entry.missing = medications
      .filter((m) => !matchedMeds.has(m.detected))
      .map((m) => m.detected);

    entry.completeness =
      medications.length === 0
        ? 0
        : Math.round((entry.items.length / medications.length) * 100);

    entry.subtotal = round2(entry.items.reduce((sum, i) => sum + i.price, 0));
    entry.tax = round2(entry.subtotal * IVA_RATE);
    entry.total = round2(entry.subtotal + entry.tax);
    pharmacies.push(entry);
  }

  pharmacies.sort((a, b) => {
    if (b.completeness !== a.completeness) return b.completeness - a.completeness;
    const distA = a.pharmacy.distanceKm ?? Number.MAX_VALUE;
    const distB = b.pharmacy.distanceKm ?? Number.MAX_VALUE;
    if (distA !== distB) return distA - distB;
    return a.total - b.total;
  });

  const fullCarts = pharmacies.filter((p) => p.completeness === 100);
  const bestFullCart =
    fullCarts.length > 0
      ? fullCarts.reduce((best, cur) => (cur.total < best.total ? cur : best))
      : null;

  const withAnyStock = pharmacies.filter((p) => p.items.length > 0);
  const bestNearby =
    withAnyStock.length > 0
      ? withAnyStock.reduce((best, cur) => {
          const bestDist = best.pharmacy.distanceKm ?? Number.MAX_VALUE;
          const curDist = cur.pharmacy.distanceKm ?? Number.MAX_VALUE;
          if (curDist !== bestDist) return curDist < bestDist ? cur : best;
          if (cur.completeness !== best.completeness) {
            return cur.completeness > best.completeness ? cur : best;
          }
          return cur.total < best.total ? cur : best;
        })
      : null;

  return {
    medications,
    pharmacies,
    bestFullCart,
    bestNearby,
  };
}
