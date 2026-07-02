import 'package:flutter/material.dart';

/// Oferta promocional mostrada en el carrusel del inicio.
class PromoOffer {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String ctaLabel;
  final String? route;
  final List<Color> gradient;
  final IconData icon;
  final String? partnerName;

  const PromoOffer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.ctaLabel,
    this.route,
    required this.gradient,
    required this.icon,
    this.partnerName,
  });
}

/// Partner destacado en filas horizontales (doctores, clínicas, etc.).
class PromoPartner {
  final String id;
  final String name;
  final String subtitle;
  final String? badge;
  final Color accentColor;
  final IconData icon;
  final String? route;
  final double? rating;

  const PromoPartner({
    required this.id,
    required this.name,
    required this.subtitle,
    this.badge,
    required this.accentColor,
    required this.icon,
    this.route,
    this.rating,
  });
}

/// Datos mock hasta conectar con API de promociones.
class PromoMockData {
  static const offers = [
    PromoOffer(
      id: '1',
      title: 'Consulta con cardiología',
      subtitle: 'Dr. Martínez · Clínica Santa María',
      badge: '30% OFF',
      ctaLabel: 'Agendar ahora',
      route: '/schedule',
      gradient: [Color(0xFF059669), Color(0xFF10B981)],
      icon: Icons.favorite_rounded,
      partnerName: 'Clínica Santa María',
    ),
    PromoOffer(
      id: '2',
      title: 'Delivery gratis en farmacia',
      subtitle: 'Farmacia Salud Plus · Pedidos desde \$5',
      badge: 'Envío gratis',
      ctaLabel: 'Ver oferta',
      route: '/pharmacy',
      gradient: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
      icon: Icons.local_pharmacy_rounded,
      partnerName: 'Farmacia Salud Plus',
    ),
    PromoOffer(
      id: '3',
      title: 'Paquete laboratorio completo',
      subtitle: 'Lab Diagnóstico · Resultados en 24h',
      badge: '2x1',
      ctaLabel: 'Explorar',
      route: '/lab_marketplace',
      gradient: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
      icon: Icons.science_rounded,
      partnerName: 'Lab Diagnóstico',
    ),
    PromoOffer(
      id: '4',
      title: 'Seguro médico familiar',
      subtitle: 'Cobertura desde \$12/mes · Sin deducible',
      badge: 'Nuevo',
      ctaLabel: 'Conocer más',
      route: '/insurance_wallet',
      gradient: [Color(0xFFF97316), Color(0xFFFB923C)],
      icon: Icons.shield_rounded,
      partnerName: 'Vida Segura',
    ),
  ];

  static const featuredDoctors = [
    PromoPartner(
      id: 'd1',
      name: 'Dra. Ana López',
      subtitle: 'Pediatría · 4.9★',
      badge: 'Top',
      accentColor: Color(0xFF059669),
      icon: Icons.medical_services_rounded,
      route: '/schedule',
      rating: 4.9,
    ),
    PromoPartner(
      id: 'd2',
      name: 'Dr. Carlos Ruiz',
      subtitle: 'Dermatología · 4.8★',
      accentColor: Color(0xFF8B5CF6),
      icon: Icons.face_retouching_natural_rounded,
      route: '/schedule',
      rating: 4.8,
    ),
    PromoPartner(
      id: 'd3',
      name: 'Dra. María Vega',
      subtitle: 'Ginecología · 4.9★',
      badge: 'Popular',
      accentColor: Color(0xFF0EA5E9),
      icon: Icons.health_and_safety_rounded,
      route: '/schedule',
      rating: 4.9,
    ),
    PromoPartner(
      id: 'd4',
      name: 'Dr. Pedro Soto',
      subtitle: 'Medicina general · 4.7★',
      accentColor: Color(0xFFF97316),
      icon: Icons.person_pin_rounded,
      route: '/schedule',
      rating: 4.7,
    ),
  ];

  static const clinics = [
    PromoPartner(
      id: 'c1',
      name: 'Clínica Vida',
      subtitle: 'Emergencias 24/7',
      badge: 'Aliada',
      accentColor: Color(0xFF059669),
      icon: Icons.local_hospital_rounded,
      route: '/clinic_network',
    ),
    PromoPartner(
      id: 'c2',
      name: 'Centro Médico Norte',
      subtitle: 'Especialistas · Rayos X',
      accentColor: Color(0xFF6366F1),
      icon: Icons.business_rounded,
      route: '/clinic_network',
    ),
    PromoPartner(
      id: 'c3',
      name: 'Hospital San José',
      subtitle: 'Cirugía · UCI',
      accentColor: Color(0xFF0EA5E9),
      icon: Icons.domain_rounded,
      route: '/clinic_network',
    ),
  ];

  static const pharmacies = [
    PromoPartner(
      id: 'p1',
      name: 'Farmacia Salud Plus',
      subtitle: 'Delivery en 45 min',
      badge: 'Gratis',
      accentColor: Color(0xFF8B5CF6),
      icon: Icons.local_pharmacy_rounded,
      route: '/pharmacy',
    ),
    PromoPartner(
      id: 'p2',
      name: 'FarmaExpress',
      subtitle: 'Recetas digitales',
      accentColor: Color(0xFF059669),
      icon: Icons.medication_rounded,
      route: '/pharmacy',
    ),
    PromoPartner(
      id: 'p3',
      name: 'MediStore',
      subtitle: 'Descuentos en genéricos',
      badge: '-20%',
      accentColor: Color(0xFFF97316),
      icon: Icons.storefront_rounded,
      route: '/pharmacy',
    ),
  ];

  static const laboratories = [
    PromoPartner(
      id: 'l1',
      name: 'Lab Diagnóstico',
      subtitle: 'Resultados en 24h',
      badge: '2x1',
      accentColor: Color(0xFF0EA5E9),
      icon: Icons.biotech_rounded,
      route: '/lab_marketplace',
    ),
    PromoPartner(
      id: 'l2',
      name: 'BioLab Central',
      subtitle: 'Hemograma completo',
      accentColor: Color(0xFF8B5CF6),
      icon: Icons.science_rounded,
      route: '/lab_marketplace',
    ),
    PromoPartner(
      id: 'l3',
      name: 'Rayos X Express',
      subtitle: 'Radiología sin cita',
      accentColor: Color(0xFF6366F1),
      icon: Icons.image_search_rounded,
      route: '/radiology_marketplace',
    ),
  ];

  static const pharmacyPromos = [
    PromoOffer(
      id: 'ph1',
      title: 'Delivery gratis hoy',
      subtitle: 'Farmacia Salud Plus · Pedidos +\$5',
      badge: 'Gratis',
      ctaLabel: 'Pedir',
      route: '/pharmacy',
      gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      icon: Icons.local_shipping_rounded,
    ),
    PromoOffer(
      id: 'ph2',
      title: '20% en genéricos',
      subtitle: 'FarmaExpress · Solo esta semana',
      badge: '-20%',
      ctaLabel: 'Ver catálogo',
      route: '/pharmacy',
      gradient: [Color(0xFF059669), Color(0xFF34D399)],
      icon: Icons.medication_rounded,
    ),
  ];

  static const labPromos = [
    PromoOffer(
      id: 'lb1',
      title: 'Paquete preventivo 2x1',
      subtitle: 'Lab Diagnóstico · 15 exámenes',
      badge: '2x1',
      ctaLabel: 'Reservar',
      route: '/lab_marketplace',
      gradient: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      icon: Icons.biotech_rounded,
    ),
    PromoOffer(
      id: 'lb2',
      title: 'Toma a domicilio gratis',
      subtitle: 'BioLab Central · Sin costo extra',
      badge: 'Domicilio',
      ctaLabel: 'Agendar',
      route: '/lab_marketplace',
      gradient: [Color(0xFF8B5CF6), Color(0xFFC4B5FD)],
      icon: Icons.home_rounded,
    ),
  ];

  static const clinicPromos = [
    PromoOffer(
      id: 'cl1',
      title: 'Consulta general \$15',
      subtitle: 'Clínica Vida · Sin cita previa',
      badge: 'Oferta',
      ctaLabel: 'Ver clínicas',
      route: '/clinic_network',
      gradient: [Color(0xFF047857), Color(0xFF10B981)],
      icon: Icons.local_hospital_rounded,
    ),
  ];

  static const insurancePromos = [
    PromoOffer(
      id: 'in1',
      title: 'Seguro familiar desde \$12',
      subtitle: 'Vida Segura · Sin deducible',
      badge: 'Nuevo',
      ctaLabel: 'Cotizar',
      route: '/insurance_wallet',
      gradient: [Color(0xFFF97316), Color(0xFFFBBF24)],
      icon: Icons.shield_rounded,
    ),
  ];

  static const radiologyPromos = [
    PromoOffer(
      id: 'ra1',
      title: 'Eco + Rayos X combo',
      subtitle: 'Imagen Médica Plus · 35% OFF',
      badge: '35% OFF',
      ctaLabel: 'Reservar',
      route: '/radiology_marketplace',
      gradient: [Color(0xFF6366F1), Color(0xFF818CF8)],
      icon: Icons.image_search_rounded,
    ),
  ];

  static const loginSlides = [
    PromoOffer(
      id: 'lg1',
      title: 'Tu salud, simplificada',
      subtitle: 'Citas, emergencias y resultados en un solo lugar',
      badge: 'TuEmergencia',
      ctaLabel: '',
      gradient: [Color(0xFF064E3B), Color(0xFF10B981)],
      icon: Icons.favorite_rounded,
    ),
    PromoOffer(
      id: 'lg2',
      title: 'Doctores con descuento',
      subtitle: 'Promociones exclusivas cada semana',
      badge: 'Hasta 30% OFF',
      ctaLabel: '',
      gradient: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
      icon: Icons.medical_services_rounded,
    ),
    PromoOffer(
      id: 'lg3',
      title: 'Farmacia a domicilio',
      subtitle: 'Delivery gratis en pedidos seleccionados',
      badge: 'Envío gratis',
      ctaLabel: '',
      gradient: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      icon: Icons.local_pharmacy_rounded,
    ),
    PromoOffer(
      id: 'lg4',
      title: 'Emergencias 24/7',
      subtitle: 'Ambulancia y red médica al instante',
      badge: 'Siempre activo',
      ctaLabel: '',
      gradient: [Color(0xFFDC2626), Color(0xFFF97316)],
      icon: Icons.emergency_rounded,
    ),
  ];
}
