import { Types } from 'mongoose';
import { DoctorProfile } from '../models/DoctorProfile';

export async function doctorHasFacility(
  doctorUserId: string,
  facilityId: string,
): Promise<boolean> {
  const profile = await DoctorProfile.findOne({ userId: doctorUserId }).select('facilityIds');
  if (!profile) return false;
  return profile.facilityIds.some((id) => id.toString() === facilityId);
}

export async function assertDoctorFacility(
  doctorUserId: string,
  facilityId: string,
): Promise<void> {
  const ok = await doctorHasFacility(doctorUserId, facilityId);
  if (!ok) {
    throw new Error('La clínica no está asociada al perfil de este médico');
  }
}

export function facilityIdsAsStrings(facilityIds: Types.ObjectId[]): string[] {
  return facilityIds.map((id) => id.toString());
}
