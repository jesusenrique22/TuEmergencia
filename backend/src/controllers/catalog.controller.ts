import { Request, Response } from 'express';
import { Specialty } from '../models/Specialty';
import { MedicalFacility } from '../models/MedicalFacility';
import { DoctorProfile } from '../models/DoctorProfile';
import { User } from '../models/User';
import { AppointmentType, UserRole } from '../types/enums';
import { getAvailableSlots } from '../services/slots.service';
import { getDoctorConsultationDuration } from '../services/doctorDuration.service';

export const listSpecialties = async (_req: Request, res: Response) => {
  const specialties = await Specialty.find().sort({ name: 1 });
  res.json(specialties);
};

export const listFacilities = async (_req: Request, res: Response) => {
  const facilities = await MedicalFacility.find({
    isActive: true,
    serviceEnabled: true,
  }).sort({ name: 1 });
  res.json(facilities);
};

export const listDoctors = async (req: Request, res: Response) => {
  const filter: Record<string, unknown> = {};
  if (req.query.specialtyId) filter.specialtyIds = req.query.specialtyId;
  if (req.query.facilityId) filter.facilityIds = req.query.facilityId;

  const profiles = await DoctorProfile.find(filter)
    .populate('specialtyIds')
    .populate('facilityIds');

  const userIds = profiles.map((p) => p.userId);
  const users = await User.find({ _id: { $in: userIds }, role: UserRole.DOCTOR }).select(
    '-password',
  );

  res.json(
    profiles.map((profile) => ({
      profile,
      user: users.find((u) => u.id === profile.userId.toString()) ?? null,
    })),
  );
};

export const doctorAvailability = async (req: Request, res: Response) => {
  const { doctorId } = req.params;
  const date = req.query.date as string;
  const rawType = (req.query.type as string)?.toUpperCase();
  const type =
    rawType === AppointmentType.ONLINE ? AppointmentType.ONLINE : AppointmentType.PRESENTIAL;
  const specialtyId = req.query.specialtyId as string | undefined;
  const facilityId = req.query.facilityId as string | undefined;

  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'Parámetro date requerido (YYYY-MM-DD)' });
  }

  try {
    const durationMinutes = await getDoctorConsultationDuration(doctorId, specialtyId);
    const slots = await getAvailableSlots({ doctorId, date, type, durationMinutes, facilityId });
    res.json({ date, type, specialtyId, durationMinutes, slots });
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
};
