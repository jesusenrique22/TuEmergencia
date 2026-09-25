import { prisma } from '../lib/prisma';

/** Municipio Maracaibo y el sur inmediato (Hospital General del Sur). */
export const MARACAIBO_BOUNDS = {
  minLat: 10.55,
  maxLat: 10.73,
  minLng: -71.78,
  maxLng: -71.5,
};

export function inMaracaibo(lat: number, lng: number): boolean {
  return (
    lat >= MARACAIBO_BOUNDS.minLat &&
    lat <= MARACAIBO_BOUNDS.maxLat &&
    lng >= MARACAIBO_BOUNDS.minLng &&
    lng <= MARACAIBO_BOUNDS.maxLng
  );
}

type GeoPlace = {
  city?: string | null;
  address?: string | null;
  latitude: number | null;
  longitude: number | null;
};

/** Clínicas que tú cargaste con city/address Maracaibo o coords en el área. */
export function isMaracaiboPlace(row: GeoPlace): boolean {
  if (row.latitude == null || row.longitude == null) return false;
  const text = `${row.city ?? ''} ${row.address ?? ''}`.toLowerCase();
  if (text.includes('maracaibo') || text.includes('zulia')) return true;
  return inMaracaibo(row.latitude, row.longitude);
}

/** Reactiva y marca urgencias las sedes que ya existen en Maracaibo (Neon / admin). */
export async function activateMaracaiboFacilitiesFromDb(): Promise<number> {
  const candidates = await prisma.medicalFacility.findMany({
    where: {
      OR: [
        { city: { contains: 'Maracaibo', mode: 'insensitive' } },
        { city: { contains: 'maracaibo', mode: 'insensitive' } },
        { address: { contains: 'Maracaibo', mode: 'insensitive' } },
        { address: { contains: 'maracaibo', mode: 'insensitive' } },
      ],
    },
  });
  const ids = candidates.filter(isMaracaiboPlace).map((f) => f.id);
  if (ids.length === 0) return 0;
  const result = await prisma.medicalFacility.updateMany({
    where: { id: { in: ids } },
    data: {
      isActive: true,
      serviceEnabled: true,
      hasEmergencyRoom: true,
      city: 'Maracaibo',
    },
  });
  return result.count;
}

export type DrivingLeg = { km: number; etaMinutes: number };

type CacheEntry = DrivingLeg & { at: number; key: string };
const routeCache = new Map<string, CacheEntry>();

function cacheKey(aLat: number, aLng: number, bLat: number, bLng: number): string {
  const r = (n: number) => n.toFixed(3);
  return `${r(aLat)},${r(aLng)}>${r(bLat)},${r(bLng)}`;
}

/** Distancia y tiempo de manejo reales (OSRM / calles de OpenStreetMap). */
export async function drivingLeg(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
): Promise<DrivingLeg | null> {
  if (!inMaracaibo(fromLat, fromLng) || !inMaracaibo(toLat, toLng)) return null;

  const key = cacheKey(fromLat, fromLng, toLat, toLng);
  const hit = routeCache.get(key);
  if (hit && Date.now() - hit.at < 20_000) {
    return { km: hit.km, etaMinutes: hit.etaMinutes };
  }

  const url =
    `https://router.project-osrm.org/route/v1/driving/` +
    `${fromLng},${fromLat};${toLng},${toLat}?overview=false`;

  try {
    const resp = await fetch(url, {
      headers: { 'User-Agent': 'TuEmergencia/1.0 (Maracaibo)' },
      signal: AbortSignal.timeout(8000),
    });
    if (!resp.ok) return hit ? { km: hit.km, etaMinutes: hit.etaMinutes } : null;
    const body = (await resp.json()) as {
      routes?: { distance?: number; duration?: number }[];
    };
    const route = body.routes?.[0];
    if (!route?.distance || !route.duration) return null;
    const leg: DrivingLeg = {
      km: Math.round((route.distance / 1000) * 100) / 100,
      etaMinutes: Math.max(1, Math.round(route.duration / 60)),
    };
    routeCache.set(key, { ...leg, at: Date.now(), key });
    return leg;
  } catch {
    return hit ? { km: hit.km, etaMinutes: hit.etaMinutes } : null;
  }
}

/** Calle real vía Nominatim. Solo si el punto cae en Maracaibo. */
export async function streetAddress(lat: number, lng: number): Promise<string | null> {
  if (!inMaracaibo(lat, lng)) return null;
  const url =
    `https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=18&lat=${lat}&lon=${lng}`;
  try {
    const resp = await fetch(url, {
      headers: { 'User-Agent': 'TuEmergencia/1.0 (Maracaibo)' },
      signal: AbortSignal.timeout(8000),
    });
    if (!resp.ok) return null;
    const body = (await resp.json()) as {
      display_name?: string;
      address?: { city?: string; town?: string; state?: string };
    };
    const place = `${body.address?.city ?? ''} ${body.address?.town ?? ''} ${body.address?.state ?? ''} ${body.display_name ?? ''}`;
    if (!/maracaibo|zulia|san francisco/i.test(place)) return null;
    const name = body.display_name?.trim();
    return name && name.length > 0 ? name : null;
  } catch {
    return null;
  }
}

/** Lugares reales (OpenStreetMap). Se reescriben al arrancar para corregir Caracas/coords viejas. */
const FACILITIES = [
  {
    name: 'Hospital Universitario de Maracaibo',
    address: 'Avenida Cecilio Acosta, Juana de Ávila, Maracaibo',
    latitude: 10.6732671,
    longitude: -71.6284841,
  },
  {
    name: 'Hospital General del Sur',
    address: 'Distribuidor El Pesebre, Cristo de Aranza, Maracaibo',
    latitude: 10.5987593,
    longitude: -71.6254064,
  },
  {
    name: 'Policlínica Amado',
    address: 'Calle 76, Olegario Villalobos, Maracaibo',
    latitude: 10.6673525,
    longitude: -71.6074775,
  },
  {
    name: 'Centro Médico de Occidente',
    address: 'Avenida 8, La Consolación, Maracaibo',
    latitude: 10.6673319,
    longitude: -71.6098677,
  },
];

const PHARMACIES = [
  {
    name: 'FarmaVita Central',
    address: 'Farmatodo, Avenida 4 Bella Vista, Maracaibo',
    latitude: 10.6840407,
    longitude: -71.6051938,
  },
  {
    name: 'EcoMedic Express',
    address: 'Farmacia SAAS, Calle 76, Maracaibo',
    latitude: 10.6673,
    longitude: -71.6077961,
  },
];

const LABS = [
  {
    name: 'BioLab Central',
    address: 'Avenida Universidad, frente a Clínica Paraíso, Maracaibo',
    latitude: 10.6838932,
    longitude: -71.6162117,
  },
  {
    name: 'Lab Diagnóstico VITA',
    address: 'Avenida 8, La Consolación, Maracaibo',
    latitude: 10.6668,
    longitude: -71.6104,
  },
];

/** Asegura clínicas Maracaibo en DB y oculta sedes fuera de la ciudad. */
export async function ensureMaracaiboCatalog(): Promise<void> {
  await activateMaracaiboFacilitiesFromDb();
  await syncMaracaiboPlaces();

  const all = await prisma.medicalFacility.findMany({
    select: { id: true, city: true, address: true, latitude: true, longitude: true },
  });
  const outsideIds = all.filter((f) => !isMaracaiboPlace(f)).map((f) => f.id);
  if (outsideIds.length > 0) {
    await prisma.medicalFacility.updateMany({
      where: { id: { in: outsideIds } },
      data: { isActive: false, serviceEnabled: false },
    });
  }
}

export async function syncMaracaiboPlaces(): Promise<void> {
  for (const place of FACILITIES) {
    const data = {
      address: place.address,
      city: 'Maracaibo',
      latitude: place.latitude,
      longitude: place.longitude,
      hasEmergencyRoom: true,
      isActive: true,
      serviceEnabled: true,
    };
    const updated = await prisma.medicalFacility.updateMany({
      where: { name: place.name },
      data,
    });
    if (updated.count === 0) {
      await prisma.medicalFacility.create({
        data: {
          name: place.name,
          type: place.name.startsWith('Hospital') ? 'HOSPITAL' : 'CLINIC',
          ...data,
        },
      });
    }
  }
  for (const place of PHARMACIES) {
    const data = {
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      isActive: true,
      serviceEnabled: true,
    };
    const updated = await prisma.pharmacy.updateMany({
      where: { name: place.name },
      data,
    });
    if (updated.count === 0) {
      await prisma.pharmacy.create({ data: { name: place.name, ...data } });
    }
  }
  for (const place of LABS) {
    const data = {
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      isActive: true,
      serviceEnabled: true,
    };
    const updated = await prisma.laboratory.updateMany({
      where: { name: place.name },
      data,
    });
    if (updated.count === 0) {
      await prisma.laboratory.create({ data: { name: place.name, ...data } });
    }
  }

  const hum = FACILITIES[0];
  const sur = FACILITIES[1];
  await prisma.ambulanceUnit.updateMany({
    where: { callSign: { in: ['VITA-04', 'VITA-07'] } },
    data: { latitude: hum.latitude, longitude: hum.longitude },
  });
  await prisma.ambulanceUnit.updateMany({
    where: { callSign: 'VITA-12' },
    data: { latitude: sur.latitude, longitude: sur.longitude },
  });
}
