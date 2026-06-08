import dotenv from 'dotenv';
import path from 'path';

// Debe ejecutarse antes de leer process.env en otros módulos.
dotenv.config({ path: path.join(__dirname, '..', '.env') });

import { internalRealtimeSecret, jwtSecret } from './secrets';

export const config = {
  port: Number(process.env.PORT) || 3001,
  jwtSecret: jwtSecret(),
  backendUrl: process.env.BACKEND_URL || 'http://localhost:3000',
  internalSecret: internalRealtimeSecret(),
};
