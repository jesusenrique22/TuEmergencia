/**
 * Inventario demo para búsqueda de recetas — idempotente (no duplica productos).
 * Ejecutar: pnpm run db:seed:pharmacy
 */
import '../loadEnv';

import { connectDatabase, disconnectDatabase, prisma } from '../config/db';
import {
  PHARMACY_ASSIGNMENTS,
  PHARMACY_LOCATIONS,
  type ProductSeed,
} from './pharmacy-catalog-data';

async function ensurePharmacy(data: (typeof PHARMACY_LOCATIONS)[number]) {
  const existing = await prisma.pharmacy.findFirst({ where: { name: data.name } });
  if (existing) {
    return prisma.pharmacy.update({
      where: { id: existing.id },
      data: {
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
        logoUrl: data.logoUrl,
        isActive: true,
        serviceEnabled: true,
      },
    });
  }
  return prisma.pharmacy.create({
    data: {
      name: data.name,
      address: data.address,
      latitude: data.latitude,
      longitude: data.longitude,
      logoUrl: data.logoUrl,
      isActive: true,
      serviceEnabled: true,
    },
  });
}

function dedupeProducts(products: ProductSeed[]): ProductSeed[] {
  const map = new Map<string, ProductSeed>();
  for (const p of products) {
    map.set(p.name.toLowerCase(), p);
  }
  return [...map.values()];
}

async function seedPharmacyInventory() {
  await connectDatabase();

  const pharmacies = await Promise.all(PHARMACY_LOCATIONS.map(ensurePharmacy));

  let created = 0;
  let updated = 0;
  let total = 0;

  for (const pharmacy of pharmacies) {
    const products = dedupeProducts(PHARMACY_ASSIGNMENTS[pharmacy.name] ?? []);
    for (const p of products) {
      total++;
      const exists = await prisma.pharmacyProduct.findFirst({
        where: { pharmacyId: pharmacy.id, name: p.name },
      });
      if (exists) {
        await prisma.pharmacyProduct.update({
          where: { id: exists.id },
          data: {
            brand: p.brand,
            category: p.category,
            price: p.price,
            stock: p.stock,
            isAvailable: true,
          },
        });
        updated++;
        continue;
      }
      await prisma.pharmacyProduct.create({
        data: {
          pharmacyId: pharmacy.id,
          name: p.name,
          brand: p.brand,
          category: p.category,
          price: p.price,
          stock: p.stock,
          isAvailable: true,
        },
      });
      created++;
    }
  }

  const count = await prisma.pharmacyProduct.count();
  console.log(`✓ Inventario farmacias: ${pharmacies.length} farmacias`);
  console.log(`  Productos en seed: ${total} (nuevos: ${created}, actualizados: ${updated})`);
  console.log(`  Total en BD: ${count} productos`);
  await disconnectDatabase();
}

seedPharmacyInventory().catch((err) => {
  console.error(err);
  process.exit(1);
});
