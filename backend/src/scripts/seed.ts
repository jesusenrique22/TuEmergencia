import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { connectDatabase, disconnectDatabase } from '../config/db';
import { User } from '../models/User';
import { PatientProfile } from '../models/PatientProfile';
import { DoctorProfile } from '../models/DoctorProfile';
import { MedicalFacility } from '../models/MedicalFacility';
import { Specialty } from '../models/Specialty';
import { DoctorWorkSchedule } from '../models/DoctorWorkSchedule';
import { Appointment } from '../models/Appointment';
import { MedicalHistory } from '../models/MedicalHistory';
import { ChatConversation } from '../models/Chat';
import { Pharmacy } from '../models/Pharmacy';
import { PharmacyProduct } from '../models/PharmacyProduct';
import { PharmacyOrder } from '../models/PharmacyOrder';
import {
  AppointmentStatus,
  AppointmentType,
  DayOfWeek,
  PharmacyOrderStatus,
  UserRole,
} from '../types/enums';

dotenv.config();

async function seed() {
  await connectDatabase();

  await Promise.all([
    User.deleteMany({}),
    PatientProfile.deleteMany({}),
    DoctorProfile.deleteMany({}),
    MedicalFacility.deleteMany({}),
    Specialty.deleteMany({}),
    DoctorWorkSchedule.deleteMany({}),
    Appointment.deleteMany({}),
    MedicalHistory.deleteMany({}),
    ChatConversation.deleteMany({}),
    Pharmacy.deleteMany({}),
    PharmacyProduct.deleteMany({}),
    PharmacyOrder.deleteMany({}),
  ]);

  const password = await bcrypt.hash('password', 10);

  const specialties = await Specialty.insertMany([
    { name: 'Cardiología', description: 'Enfermedades del corazón' },
    { name: 'Medicina General', description: 'Atención primaria' },
    { name: 'Dermatología', description: 'Piel y anexos' },
    { name: 'Pediatría', description: 'Salud infantil' },
  ]);

  const facilities = await MedicalFacility.insertMany([
    {
      name: 'Clínica Metropolitana',
      type: 'CLINIC',
      address: 'Av. Principal, Caracas',
      city: 'Caracas',
    },
    {
      name: 'Hospital Central',
      type: 'HOSPITAL',
      address: 'Centro Médico, Caracas',
      city: 'Caracas',
    },
    {
      name: 'Consultorio Norte',
      type: 'CONSULTORY',
      address: 'Zona Norte, Valencia',
      city: 'Valencia',
    },
    {
      name: 'Clínica San José',
      type: 'CLINIC',
      address: 'Los Palos Grandes, Caracas',
      city: 'Caracas',
    },
  ]);

  const superAdmin = await User.create({
    email: 'admin@vita.com',
    password,
    name: 'Super Admin VITA',
    role: UserRole.SUPER_ADMIN,
    phone: '+58 412-000-0001',
  });

  const pharmacies = await Pharmacy.insertMany([
    {
      name: 'FarmaVita Central',
      address: 'Av. Libertador #123, Caracas',
      logoUrl:
        'https://images.unsplash.com/photo-1586015555751-63bb77f4322a?auto=format&fit=crop&q=80&w=100',
    },
    {
      name: 'EcoMedic Express',
      address: 'Calle 50 con Calle 72, Panamá',
      logoUrl:
        'https://images.unsplash.com/photo-1576602976047-174e57a47881?auto=format&fit=crop&q=80&w=100',
    },
  ]);

  const clinicAdmin = await User.create({
    email: 'clinic.admin@vita.com',
    password,
    name: 'Admin Clínica Metropolitana',
    role: UserRole.CLINIC_ADMIN,
    phone: '+58 412-000-0002',
    managedFacilityId: facilities[0]._id,
    createdBy: superAdmin._id,
  });

  const pharmacyAdmin = await User.create({
    email: 'pharmacy.admin@vita.com',
    password,
    name: 'Admin FarmaVita',
    role: UserRole.PHARMACY_ADMIN,
    phone: '+58 412-000-0003',
    pharmacyId: pharmacies[0]._id,
    createdBy: superAdmin._id,
  });

  await User.create({
    email: 'farmacista@vita.com',
    password,
    name: 'Ana Farmacéutica',
    role: UserRole.PHARMACIST,
    phone: '+58 412-000-0004',
    pharmacyId: pharmacies[0]._id,
    createdBy: pharmacyAdmin._id,
  });

  await User.create({
    email: 'cajero@vita.com',
    password,
    name: 'Luis Cajero',
    role: UserRole.PHARMACY_CASHIER,
    phone: '+58 412-000-0005',
    pharmacyId: pharmacies[0]._id,
    createdBy: pharmacyAdmin._id,
  });

  const products = await PharmacyProduct.insertMany([
    {
      pharmacyId: pharmacies[0]._id,
      name: 'Amoxicilina 500mg',
      brand: 'Genfar',
      category: 'Antibióticos',
      price: 12.5,
      stock: 80,
      isAvailable: true,
    },
    {
      pharmacyId: pharmacies[0]._id,
      name: 'Ibuprofeno 400mg',
      brand: 'MK',
      category: 'Analgésicos',
      price: 8.0,
      stock: 120,
      isAvailable: true,
    },
    {
      pharmacyId: pharmacies[1]._id,
      name: 'Losartán 50mg',
      brand: 'La Santé',
      category: 'Cardiovascular',
      price: 15.0,
      stock: 45,
      isAvailable: true,
    },
  ]);

  await PharmacyOrder.insertMany([
    {
      pharmacyId: pharmacies[0]._id,
      patientId: null,
      productId: products[0]._id,
      productName: products[0].name,
      quantity: 2,
      total: 25,
      status: PharmacyOrderStatus.COMPLETED,
    },
    {
      pharmacyId: pharmacies[0]._id,
      patientId: null,
      productId: products[1]._id,
      productName: products[1].name,
      quantity: 1,
      total: 8,
      status: PharmacyOrderStatus.PENDING,
    },
  ]);

  const patient = await User.create({
    email: 'juan@patient.com',
    password,
    name: 'Juan Pérez',
    role: UserRole.PATIENT,
    phone: '+58 412-555-0198',
    profilePic: 'https://i.pravatar.cc/150?img=1',
  });

  await PatientProfile.create({
    userId: patient.id,
    fullName: 'Juan Pérez',
    email: patient.email,
    phone: '+58 412-555-0198',
    documentId: 'V-12345678',
    birthDate: '1990-04-12',
    address: 'Av. Libertador, Caracas',
    emergencyContactName: 'María Pérez',
    emergencyContactPhone: '+58 414-555-0142',
    bloodType: 'O+',
    allergies: 'Penicilina',
    chronicConditions: 'Hipertensión controlada',
    currentMedications: 'Losartán 50mg diario',
    surgeries: 'Apendicectomía 2014',
    weightKg: '78',
    heightCm: '176',
    insuranceProvider: 'Seguros Mercantil',
    policyNumber: 'MC-2024-889900',
  });

  await MedicalHistory.create({
    patientId: patient.id,
    bloodType: 'O+',
    allergies: 'Penicilina',
    chronicConditions: 'Hipertensión controlada',
    currentMedications: 'Losartán 50mg diario',
    surgeries: 'Apendicectomía 2014',
    weightKg: '78',
    heightCm: '176',
    entries: [
      {
        date: new Date('2025-11-10'),
        title: 'Control de presión',
        description: 'Presión arterial dentro de rango normal.',
        diagnosis: 'Hipertensión controlada',
        treatment: 'Continuar Losartán 50mg',
      },
    ],
  });

  const doctor = await User.create({
    email: 'maria@doctor.com',
    password,
    name: 'Dra. María Gómez',
    role: UserRole.DOCTOR,
    phone: '+58 414-555-0200',
    profilePic: 'https://i.pravatar.cc/150?img=2',
  });

  const doctorProfile = await DoctorProfile.create({
    userId: doctor.id,
    documentId: 'V-12345678',
    licenseNumber: 'MED-45821',
    bio: 'Cardióloga con 12 años de experiencia',
    specialtyIds: [specialties[0]._id, specialties[1]._id],
    facilityIds: [facilities[0]._id, facilities[1]._id],
    rating: 4.9,
    consultationPriceOnline: 25,
    consultationPricePresential: 45,
    defaultConsultationMinutes: 30,
    specialtyConsultationDurations: [
      { specialtyId: specialties[0]._id, durationMinutes: 60 },
      { specialtyId: specialties[1]._id, durationMinutes: 30 },
    ],
  });

  const weekdays = [
    DayOfWeek.MONDAY,
    DayOfWeek.TUESDAY,
    DayOfWeek.WEDNESDAY,
    DayOfWeek.THURSDAY,
    DayOfWeek.FRIDAY,
    DayOfWeek.SATURDAY,
  ];
  await DoctorWorkSchedule.insertMany(
    weekdays.flatMap((day) => [
      {
        doctorId: doctor.id,
        facilityId: facilities[0]._id,
        dayOfWeek: day,
        startTime: '08:00',
        endTime: '12:00',
      },
      {
        doctorId: doctor.id,
        facilityId: facilities[1]._id,
        dayOfWeek: day,
        startTime: '14:00',
        endTime: '18:00',
      },
    ]),
  );

  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(10, 30, 0, 0);

  await Appointment.insertMany([
    {
      patientId: patient.id,
      doctorId: doctor.id,
      facilityId: facilities[1]._id,
      specialtyId: specialties[0]._id,
      dateTime: tomorrow,
      status: AppointmentStatus.PENDING,
      type: AppointmentType.PRESENTIAL,
      reason: 'Control cardiológico',
      price: 45,
    },
    {
      patientId: patient.id,
      doctorId: doctor.id,
      specialtyId: specialties[0]._id,
      dateTime: new Date(tomorrow.getTime() + 2 * 60 * 60 * 1000),
      status: AppointmentStatus.CONFIRMED,
      type: AppointmentType.ONLINE,
      reason: 'Seguimiento telemedicina',
      price: 25,
    },
  ]);

  await ChatConversation.create({
    doctorId: doctor.id,
    patientId: patient.id,
    lastMessage: 'Buenos días doctor, tengo una consulta sobre mi medicación.',
    lastMessageAt: new Date(),
  });

  console.log('Seed completado:');
  console.log(`  Super Admin:    ${superAdmin.email} / password`);
  console.log(`  Admin Clínica:  ${clinicAdmin.email} / password`);
  console.log(`  Admin Farmacia: ${pharmacyAdmin.email} / password`);
  console.log(`  Farmacéutico:   farmacista@vita.com / password`);
  console.log(`  Cajero:         cajero@vita.com / password`);
  console.log(`  Paciente: ${patient.email} / password`);
  console.log(`  Doctor:  ${doctor.email} / password`);
  console.log(`  Especialidades: ${specialties.length}`);
  console.log(`  Sedes: ${facilities.length}`);
  console.log(`  Perfil doctor: ${doctorProfile.id}`);

  await disconnectDatabase();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
