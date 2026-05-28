import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { Types } from 'mongoose';
import { User } from '../models/User';
import { DoctorProfile } from '../models/DoctorProfile';
import { Specialty } from '../models/Specialty';
import { MedicalFacility } from '../models/MedicalFacility';
import { UserRole } from '../types/enums';
import { sanitizeUser } from '../utils/sanitizeUser';

export interface CreateDoctorInput {
  name: string;
  email: string;
  phone: string;
  documentId: string;
  specialtyId: string;
  facilityIds: string[];
  /** Si se define, facilityIds debe ser subconjunto (admin de clínica) */
  allowedFacilityIds?: string[];
}

function generateTemporaryPassword(): string {
  return crypto.randomBytes(4).toString('hex') + 'A1!';
}

export async function createDoctorByAdmin(input: CreateDoctorInput) {
  const { name, email, phone, documentId, specialtyId, facilityIds } = input;

  const emailNorm = email.toLowerCase().trim();
  const docNorm = documentId.trim().toUpperCase();

  const existingUser = await User.findOne({ email: emailNorm });
  if (existingUser) {
    throw new Error('El correo ya está registrado');
  }

  const existingDoc = await DoctorProfile.findOne({ documentId: docNorm });
  if (existingDoc) {
    throw new Error('La cédula ya está asociada a otro médico');
  }

  const specialty = await Specialty.findById(specialtyId);
  if (!specialty) {
    throw new Error('Especialidad no encontrada');
  }

  if (!facilityIds.length) {
    throw new Error('Selecciona al menos una clínica asociada');
  }

  const uniqueFacilityIds = [...new Set(facilityIds)];

  if (input.allowedFacilityIds?.length) {
    const allowed = new Set(input.allowedFacilityIds.map(String));
    const outOfScope = uniqueFacilityIds.filter((id) => !allowed.has(id));
    if (outOfScope.length) {
      throw new Error('Solo puedes asignar médicos a tu clínica autorizada');
    }
  }

  const facilities = await MedicalFacility.find({
    _id: { $in: uniqueFacilityIds },
    isActive: true,
    serviceEnabled: true,
  });
  if (facilities.length !== uniqueFacilityIds.length) {
    throw new Error('Una o más clínicas no son válidas, están inactivas o sin servicio');
  }

  const temporaryPassword = generateTemporaryPassword();
  const hashedPassword = await bcrypt.hash(temporaryPassword, 10);

  const user = await User.create({
    email: emailNorm,
    password: hashedPassword,
    name: name.trim(),
    role: UserRole.DOCTOR,
    phone: phone.trim(),
  });

  const profile = await DoctorProfile.create({
    userId: user.id,
    documentId: docNorm,
    specialtyIds: [new Types.ObjectId(specialtyId)],
    facilityIds: uniqueFacilityIds.map((id) => new Types.ObjectId(id)),
  });

  const populated = await DoctorProfile.findById(profile.id)
    .populate('specialtyIds')
    .populate('facilityIds');

  return {
    user: sanitizeUser(user),
    profile: populated,
    temporaryPassword,
  };
}
