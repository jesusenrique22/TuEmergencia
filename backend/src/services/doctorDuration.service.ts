import { DoctorProfile } from '../models/DoctorProfile';
import { normalizeDuration } from './slots.service';

export async function getDoctorConsultationDuration(
  doctorId: string,
  specialtyId?: string,
): Promise<number> {
  const profile = await DoctorProfile.findOne({ userId: doctorId });
  if (!profile) return 30;

  if (specialtyId && profile.specialtyConsultationDurations?.length) {
    const match = profile.specialtyConsultationDurations.find(
      (entry) => entry.specialtyId.toString() === specialtyId,
    );
    if (match?.durationMinutes) {
      return normalizeDuration(match.durationMinutes);
    }
  }

  return normalizeDuration(profile.defaultConsultationMinutes ?? 30);
}
