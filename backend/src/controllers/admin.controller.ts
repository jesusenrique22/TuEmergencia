import { Response } from 'express';
import { User } from '../models/User';
import { Appointment } from '../models/Appointment';
import { MedicalFacility } from '../models/MedicalFacility';
import { Specialty } from '../models/Specialty';
import { DoctorProfile } from '../models/DoctorProfile';
import { sanitizeUser } from '../utils/sanitizeUser';
import { UserRole } from '../types/enums';

export const listUsers = async (req: import('../middleware/auth').AuthRequest, res: Response) => {
  const filter: Record<string, unknown> = {};
  if (req.query.role) filter.role = req.query.role;

  const users = await User.find(filter).select('-password').sort({ createdAt: -1 });
  res.json(users.map(sanitizeUser));
};

export const getStats = async (_req: import('../middleware/auth').AuthRequest, res: Response) => {
  const [patients, doctors, admins, appointments, facilities, specialties] = await Promise.all([
    User.countDocuments({ role: 'PATIENT' }),
    User.countDocuments({ role: 'DOCTOR' }),
    User.countDocuments({ role: 'ADMIN' }),
    Appointment.countDocuments(),
    MedicalFacility.countDocuments({ isActive: true }),
    Specialty.countDocuments(),
  ]);

  res.json({ patients, doctors, admins, appointments, facilities, specialties });
};

export const createFacility = async (req: import('../middleware/auth').AuthRequest, res: Response) => {
  const facility = await MedicalFacility.create(req.body);
  res.status(201).json(facility);
};

export const createSpecialty = async (req: import('../middleware/auth').AuthRequest, res: Response) => {
  const specialty = await Specialty.create(req.body);
  res.status(201).json(specialty);
};

export const listDoctors = async (_req: import('../middleware/auth').AuthRequest, res: Response) => {
  const profiles = await DoctorProfile.find()
    .populate('specialtyIds')
    .populate('facilityIds')
    .sort({ createdAt: -1 });

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

