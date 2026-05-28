import 'radiology_models.dart';

class RadiologyDataMock {
  static final List<RadiologyCenter> centers = [
    RadiologyCenter(
      id: 'rad-001',
      name: 'Imagenología Premium',
      logoUrl:
          'https://images.unsplash.com/photo-1516549655169-df83a0774514?auto=format&fit=crop&q=80&w=100',
      hasMRI: true,
    ),
  ];

  static final List<ImagingService> services = [
    ImagingService(
      id: 'ser-201',
      centerId: 'rad-001',
      name: 'Rayos X de Tórax',
      price: 45.00,
      preparation:
          'No requiere preparación. Retirar objetos metálicos del torso.',
    ),
    ImagingService(
      id: 'ser-202',
      centerId: 'rad-001',
      name: 'Resonancia Magnética (Rodilla)',
      price: 150.00,
      preparation:
          'Asistir con ropa cómoda. Informar si posee implantes metálicos.',
    ),
    ImagingService(
      id: 'ser-203',
      centerId: 'rad-001',
      name: 'Eco Abdominal Superior',
      price: 60.00,
      preparation: 'Ayunas de 6 horas. Vejiga llena (beber 4 vasos de agua).',
    ),
  ];

  static final List<ImagingResult> results = [];
}
