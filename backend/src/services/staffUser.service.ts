import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { Types } from 'mongoose';
import { User } from '../models/User';
import { UserRole } from '../types/enums';
import { sanitizeUser } from '../utils/sanitizeUser';

export function generateTemporaryPassword(): string {
  return crypto.randomBytes(4).toString('hex') + 'A1!';
}

export interface CreateStaffUserInput {
  name: string;
  email: string;
  phone?: string;
  role: UserRole;
  createdBy: string;
  managedFacilityId?: string;
  pharmacyId?: string;
}

export async function createStaffUser(input: CreateStaffUserInput) {
  const emailNorm = input.email.toLowerCase().trim();

  const existing = await User.findOne({ email: emailNorm });
  if (existing) {
    throw new Error('El correo ya está registrado');
  }

  const temporaryPassword = generateTemporaryPassword();
  const hashedPassword = await bcrypt.hash(temporaryPassword, 10);

  const user = await User.create({
    email: emailNorm,
    password: hashedPassword,
    name: input.name.trim(),
    role: input.role,
    phone: input.phone?.trim(),
    managedFacilityId: input.managedFacilityId
      ? new Types.ObjectId(input.managedFacilityId)
      : undefined,
    pharmacyId: input.pharmacyId ? new Types.ObjectId(input.pharmacyId) : undefined,
    createdBy: new Types.ObjectId(input.createdBy),
    isActive: true,
  });

  return {
    user: sanitizeUser(user),
    temporaryPassword,
  };
}
