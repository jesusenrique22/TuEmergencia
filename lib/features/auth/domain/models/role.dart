enum Role {
  patient,
  doctor,
  /// Jefe de la app (SUPER_ADMIN / ADMIN)
  superAdmin,
  /// Administra una clínica — crea médicos de su sede
  clinicAdmin,
  /// Administra una farmacia — personal e inventario
  pharmacyAdmin,
  /// Revisa medicamentos / pedidos
  pharmacist,
  /// Caja
  pharmacyCashier,
  /// @deprecated Usar superAdmin
  admin,
  pharmacy,
  clinicStaff,
  labTech,
  radiologyTech,
  driver,
}
