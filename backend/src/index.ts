import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import { connectDatabase } from './config/db';
import authRoutes from './routes/auth.routes';
import patientRoutes from './routes/patient.routes';
import doctorRoutes from './routes/doctor.routes';
import appointmentRoutes from './routes/appointment.routes';
import chatRoutes from './routes/chat.routes';
import catalogRoutes from './routes/catalog.routes';
import adminRoutes from './routes/admin.routes';
import superAdminRoutes from './routes/superAdmin.routes';
import clinicAdminRoutes from './routes/clinicAdmin.routes';
import pharmacyAdminRoutes from './routes/pharmacyAdmin.routes';
import pharmacyStaffRoutes from './routes/pharmacyStaff.routes';
import notificationRoutes from './routes/notification.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'OK', message: 'Smart Medic API running' });
});

app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/doctors', doctorRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/catalog', catalogRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/super-admin', superAdminRoutes);
app.use('/api/clinic-admin', clinicAdminRoutes);
app.use('/api/pharmacy-admin', pharmacyAdminRoutes);
app.use('/api/pharmacy-staff', pharmacyStaffRoutes);
app.use('/api/notifications', notificationRoutes);

async function start() {
  try {
    await connectDatabase();
    app.listen(PORT, () => {
      console.log(`Smart Medic Backend en puerto ${PORT}`);
    });
  } catch (error) {
    console.error('No se pudo iniciar el servidor:', error);
    process.exit(1);
  }
}

start();
