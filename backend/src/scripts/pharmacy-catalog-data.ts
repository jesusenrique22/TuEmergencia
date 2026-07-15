/**
 * Catálogo demo de medicamentos — distribuido entre farmacias aliadas.
 * Incluye Azitromicina jarabe/comprimidos (receta típica pediátrica).
 */
export type ProductSeed = {
  name: string;
  brand: string;
  category: string;
  price: number;
  stock: number;
};

/** Productos base reutilizables */
export const CATALOG: ProductSeed[] = [
  // Antibióticos
  { name: 'Amoxicilina 500mg', brand: 'Genfar', category: 'Antibióticos', price: 12.5, stock: 80 },
  { name: 'Amoxicilina 250mg/5ml Suspensión', brand: 'Sandoz', category: 'Antibióticos', price: 14.0, stock: 45 },
  { name: 'Azitromicina 500mg', brand: 'Pfizer', category: 'Antibióticos', price: 22.0, stock: 35 },
  { name: 'Azitromicina Jarabe 200mg/5ml 15ml', brand: 'Genfar', category: 'Antibióticos', price: 18.5, stock: 28 },
  { name: 'Azitromicina Jarabe 200mg/5ml 30ml', brand: 'MK', category: 'Antibióticos', price: 24.0, stock: 22 },
  { name: 'Ciprofloxacina 500mg', brand: 'Genfar', category: 'Antibióticos', price: 16.0, stock: 40 },
  { name: 'Cefalexina 500mg', brand: 'La Santé', category: 'Antibióticos', price: 13.5, stock: 50 },
  { name: 'Claritromicina 500mg', brand: 'Abbott', category: 'Antibióticos', price: 28.0, stock: 18 },
  { name: 'Trimetoprim/Sulfametoxazol 400/80mg', brand: 'MK', category: 'Antibióticos', price: 9.5, stock: 60 },
  { name: 'Metronidazol 500mg', brand: 'Genfar', category: 'Antibióticos', price: 7.8, stock: 55 },
  // Analgésicos / antipiréticos
  { name: 'Paracetamol 500mg', brand: 'Calox', category: 'Analgésicos', price: 5.5, stock: 200 },
  { name: 'Paracetamol Jarabe 160mg/5ml', brand: 'Dolex', category: 'Analgésicos', price: 8.2, stock: 70 },
  { name: 'Ibuprofeno 400mg', brand: 'MK', category: 'Analgésicos', price: 8.0, stock: 120 },
  { name: 'Ibuprofeno 600mg', brand: 'Advil', category: 'Analgésicos', price: 9.2, stock: 90 },
  { name: 'Ibuprofeno Jarabe 100mg/5ml', brand: 'Bayer', category: 'Analgésicos', price: 10.5, stock: 40 },
  { name: 'Naproxeno 250mg', brand: 'Genfar', category: 'Analgésicos', price: 11.0, stock: 65 },
  { name: 'Diclofenaco 50mg', brand: 'MK', category: 'Analgésicos', price: 6.5, stock: 85 },
  { name: 'Ketorolaco 10mg', brand: 'La Santé', category: 'Analgésicos', price: 12.0, stock: 30 },
  // Gastrointestinal (diarrea, etc.)
  { name: 'Omeprazol 20mg', brand: 'Genfar', category: 'Gastrointestinal', price: 10.45, stock: 60 },
  { name: 'Loperamida 2mg', brand: 'Imodium', category: 'Gastrointestinal', price: 9.0, stock: 75 },
  { name: 'Suero Oral Polvo Sobre', brand: 'Pedialyte', category: 'Gastrointestinal', price: 2.5, stock: 150 },
  { name: 'Metoclopramida 10mg', brand: 'MK', category: 'Gastrointestinal', price: 5.0, stock: 40 },
  { name: 'Ranitidina 150mg', brand: 'Genfar', category: 'Gastrointestinal', price: 7.0, stock: 35 },
  { name: 'Dimenhidrinato 50mg', brand: 'Dramamine', category: 'Gastrointestinal', price: 8.5, stock: 25 },
  // Cardiovascular
  { name: 'Losartán 50mg', brand: 'La Santé', category: 'Cardiovascular', price: 15.0, stock: 45 },
  { name: 'Enalapril 10mg', brand: 'MK', category: 'Cardiovascular', price: 9.5, stock: 55 },
  { name: 'Amlodipina 5mg', brand: 'Genfar', category: 'Cardiovascular', price: 11.5, stock: 48 },
  { name: 'Atorvastatina 20mg', brand: 'Genfar', category: 'Cardiovascular', price: 18.0, stock: 40 },
  { name: 'Hidroclorotiazida 25mg', brand: 'MK', category: 'Cardiovascular', price: 6.0, stock: 60 },
  { name: 'Carvedilol 6.25mg', brand: 'La Santé', category: 'Cardiovascular', price: 14.5, stock: 22 },
  // Diabetes
  { name: 'Metformina 850mg', brand: 'Genfar', category: 'Diabetes', price: 11.0, stock: 70 },
  { name: 'Glibenclamida 5mg', brand: 'MK', category: 'Diabetes', price: 8.0, stock: 35 },
  { name: 'Insulina NPH 10ml', brand: 'Novo Nordisk', category: 'Diabetes', price: 45.0, stock: 12 },
  // Antialérgicos / respiratorio
  { name: 'Loratadina 10mg', brand: 'Claritine', category: 'Antialérgicos', price: 12.0, stock: 45 },
  { name: 'Cetirizina 10mg', brand: 'Zyrtec', category: 'Antialérgicos', price: 10.0, stock: 50 },
  { name: 'Salbutamol Inhalador 100mcg', brand: 'GSK', category: 'Respiratorio', price: 22.0, stock: 20 },
  { name: 'Ambroxol Jarabe', brand: 'Mucosolvan', category: 'Respiratorio', price: 9.8, stock: 38 },
  // Vitaminas / OTC
  { name: 'Complejo B Tabletas', brand: 'MK', category: 'Vitaminas', price: 6.5, stock: 90 },
  { name: 'Vitamina C 500mg', brand: 'Redoxon', category: 'Vitaminas', price: 7.5, stock: 100 },
  { name: 'Vitamina D3 1000 UI', brand: 'Genfar', category: 'Vitaminas', price: 12.0, stock: 55 },
  { name: 'Hierro + Ácido Fólico', brand: 'La Santé', category: 'Vitaminas', price: 8.5, stock: 42 },
  // Dermatológicos
  { name: 'Clotrimazol Crema 1%', brand: 'Genfar', category: 'Dermatológicos', price: 7.0, stock: 30 },
  { name: 'Hidrocortisona Crema 1%', brand: 'MK', category: 'Dermatológicos', price: 6.0, stock: 28 },
  // Neurología / psiquiatría leve
  { name: 'Diazepam 10mg', brand: 'Genfar', category: 'Neurología', price: 5.5, stock: 15 },
  { name: 'Sertralina 50mg', brand: 'Pfizer', category: 'Neurología', price: 25.0, stock: 18 },
];

/** Asignación por farmacia (índices del catálogo o productos exclusivos). */
export const PHARMACY_ASSIGNMENTS: Record<string, ProductSeed[]> = {
  'FarmaVita Central': [
    ...CATALOG.filter((_, i) => i % 3 === 0),
    { name: 'Azitromicina Jarabe 200mg/5ml 15ml', brand: 'Pfizer', category: 'Antibióticos', price: 19.9, stock: 15 },
  ],
  'EcoMedic Express': [
    ...CATALOG.filter((_, i) => i % 3 === 1),
    { name: 'Azitromicina 500mg', brand: 'Sandoz', category: 'Antibióticos', price: 20.5, stock: 32 },
    { name: 'Azitromicina Jarabe 200mg/5ml 15ml', brand: 'Genfar', category: 'Antibióticos', price: 17.0, stock: 40 },
  ],
  'Farmacia Salud Plus': [
    ...CATALOG.filter((_, i) => i % 3 === 2),
    { name: 'Azitromicina Jarabe 200mg/5ml 30ml', brand: 'MK', category: 'Antibióticos', price: 23.5, stock: 18 },
    { name: 'Loperamida 2mg', brand: 'Genfar', category: 'Gastrointestinal', price: 8.5, stock: 55 },
    { name: 'Suero Oral Polvo Sobre', brand: 'Hidraplus', category: 'Gastrointestinal', price: 2.0, stock: 200 },
  ],
  'Farmacia San Rafael': [
    ...CATALOG.slice(0, 25),
    { name: 'Azitromicina Jarabe 200mg/5ml 15ml', brand: 'La Santé', category: 'Antibióticos', price: 16.5, stock: 25 },
  ],
  'FarmaExpress 24h': [
    ...CATALOG.slice(15, 45),
    { name: 'Azitromicina 500mg', brand: 'Genfar', category: 'Antibióticos', price: 21.0, stock: 20 },
  ],
};

export const PHARMACY_LOCATIONS = [
  {
    name: 'FarmaVita Central',
    address: 'Av. Libertador #123, Caracas',
    latitude: 10.49,
    longitude: -66.88,
    logoUrl:
      'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&q=80&w=100',
  },
  {
    name: 'EcoMedic Express',
    address: 'Calle 50 con Calle 72, Caracas',
    latitude: 10.48,
    longitude: -66.9,
    logoUrl:
      'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=100',
  },
  {
    name: 'Farmacia Salud Plus',
    address: 'Centro Comercial Lider, Caracas',
    latitude: 10.505,
    longitude: -66.865,
    logoUrl:
      'https://images.unsplash.com/photo-1471864190281-ad5f9f8162e6?auto=format&fit=crop&q=80&w=100',
  },
  {
    name: 'Farmacia San Rafael',
    address: 'Av. Francisco de Miranda, Caracas',
    latitude: 10.495,
    longitude: -66.855,
    logoUrl:
      'https://images.unsplash.com/photo-1587854692152-cbe660dbbb88?auto=format&fit=crop&q=80&w=100',
  },
  {
    name: 'FarmaExpress 24h',
    address: 'Autopista Gran Cacique, Caracas',
    latitude: 10.512,
    longitude: -66.878,
    logoUrl:
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=100',
  },
] as const;
