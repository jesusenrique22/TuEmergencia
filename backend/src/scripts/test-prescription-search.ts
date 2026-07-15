/**
 * Prueba búsqueda de receta sin Flutter ni Gemini.
 *
 *   pnpm run test:prescription -- Amoxicilina Ibuprofeno Paracetamol
 *   pnpm run test:prescription -- --lat 10.49 --lng -66.88 Amoxicilina Losartán
 */
import '../loadEnv';

import { connectDatabase, disconnectDatabase } from '../config/db';
import { searchPharmacyInventory } from '../services/prescriptionSearch.service';

async function main() {
  const args = process.argv.slice(2);
  let lat: number | undefined;
  let lng: number | undefined;
  const meds: string[] = [];

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--lat' && args[i + 1]) {
      lat = Number(args[++i]);
    } else if (args[i] === '--lng' && args[i + 1]) {
      lng = Number(args[++i]);
    } else {
      meds.push(args[i]);
    }
  }

  if (meds.length === 0) {
    meds.push('Amoxicilina 500mg', 'Ibuprofeno 400mg', 'Paracetamol 500mg');
    console.log('(Sin medicamentos en args — usando demo)\n');
  }

  await connectDatabase();
  const result = await searchPharmacyInventory(meds, { lat, lng });

  console.log('Medicamentos detectados:');
  for (const m of result.medications) {
    console.log(`  • ${m.detected} → ${m.normalized}`);
  }

  console.log('\nFarmacias (ordenadas):');
  for (const p of result.pharmacies) {
    const dist = p.pharmacy.distanceKm != null ? `${p.pharmacy.distanceKm} km` : 'sin GPS';
    console.log(
      `\n  ${p.pharmacy.name} — ${p.completeness}% completo — $${p.total} — ${dist}`,
    );
    for (const item of p.items) {
      console.log(`    ✓ ${item.name} — $${item.price} (stock ${item.stock})`);
    }
    for (const miss of p.missing) {
      console.log(`    ✗ Falta: ${miss}`);
    }
  }

  if (result.bestFullCart) {
    console.log(`\n★ Mejor carrito completo: ${result.bestFullCart.pharmacy.name} ($${result.bestFullCart.total})`);
  } else {
    console.log('\n★ Ninguna farmacia tiene todos los medicamentos.');
  }

  if (result.bestNearby) {
    console.log(`★ Más cercana con stock: ${result.bestNearby.pharmacy.name}`);
  }

  await disconnectDatabase();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
