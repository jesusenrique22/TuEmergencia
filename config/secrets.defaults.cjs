/**
 * Valores por defecto SOLO para desarrollo local.
 * En producción define JWT_SECRET e INTERNAL_REALTIME_SECRET en cada servicio.
 * Mantener alineado: backend, realtime-gateway y docs/ENV.md
 */
module.exports = {
  DEV_JWT_SECRET: 'smart-medic-dev-secret',
  DEV_INTERNAL_REALTIME_SECRET: 'smart-medic-internal-dev',
};
