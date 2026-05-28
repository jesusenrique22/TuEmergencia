import { Types } from 'mongoose';
import { DoctorProfile } from '../models/DoctorProfile';
import { DoctorWorkSchedule } from '../models/DoctorWorkSchedule';
import { User } from '../models/User';
import { UserRole } from '../types/enums';
import { getPendingInvitationIdsForFacility } from './clinicInvitation.service';

export async function listDoctorsForFacility(facilityId: string) {
  const fid = new Types.ObjectId(facilityId);
  const profiles = await DoctorProfile.find({ facilityIds: fid })
    .populate('specialtyIds', 'name')
    .populate('facilityIds', 'name');

  const userIds = profiles.map((p) => p.userId);
  const users = await User.find({
    _id: { $in: userIds },
    role: UserRole.DOCTOR,
  }).select('-password');

  return profiles.map((profile) => ({
    profile,
    user: users.find((u) => u.id === profile.userId.toString()) ?? null,
  }));
}

export async function listDoctorsNotInFacility(facilityId: string, search?: string) {
  const fid = new Types.ObjectId(facilityId);

  // Doctor IDs that already have a pending invitation to this facility
  const pendingDoctorIds = new Set(
    (await getPendingInvitationIdsForFacility(facilityId)).map((id) => id.toString()),
  );

  // Use MongoDB $nin to reliably exclude profiles already assigned to this facility
  const profiles = await DoctorProfile.find({
    facilityIds: { $nin: [fid] },
  })
    .populate('specialtyIds', 'name')
    .populate('facilityIds', 'name');

  // Exclude doctors with a pending invitation
  const filtered = profiles.filter(
    (p) => !pendingDoctorIds.has(p.userId.toString()),
  );

  const userIds = filtered.map((p) => p.userId);
  let users = await User.find({
    _id: { $in: userIds },
    role: UserRole.DOCTOR,
  }).select('-password');

  if (search?.trim()) {
    const q = search.trim().toLowerCase();
    users = users.filter(
      (u) =>
        u.name.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q) ||
        (u.phone?.toLowerCase().includes(q) ?? false),
    );
    const allowedIds = new Set(users.map((u) => u.id));
    return filtered
      .filter((p) => allowedIds.has(p.userId.toString()))
      .map((profile) => ({
        profile,
        user: users.find((u) => u.id === profile.userId.toString()) ?? null,
      }));
  }

  return filtered.map((profile) => ({
    profile,
    user: users.find((u) => u.id === profile.userId.toString()) ?? null,
  }));
}

export async function assignDoctorToFacility(doctorUserId: string, facilityId: string) {
  const user = await User.findOne({ _id: doctorUserId, role: UserRole.DOCTOR });
  if (!user) throw new Error('Médico no encontrado');

  const profile = await DoctorProfile.findOne({ userId: doctorUserId });
  if (!profile) throw new Error('Perfil de médico no encontrado');

  const fid = new Types.ObjectId(facilityId);
  if (profile.facilityIds.some((id) => id.equals(fid))) {
    throw new Error('Este médico ya está vinculado a tu clínica');
  }

  profile.facilityIds.push(fid);
  await profile.save();

  const populated = await DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name')
    .populate('facilityIds', 'name');

  return { user, profile: populated };
}

export async function unassignDoctorFromFacility(doctorUserId: string, facilityId: string) {
  const profile = await DoctorProfile.findOne({ userId: doctorUserId });
  if (!profile) throw new Error('Perfil de médico no encontrado');

  const fid = new Types.ObjectId(facilityId);
  if (!profile.facilityIds.some((id) => id.equals(fid))) {
    throw new Error('El médico no está vinculado a esta clínica');
  }

  if (profile.facilityIds.length <= 1) {
    throw new Error(
      'No puedes desvincular al único centro del médico. Debe pertenecer al menos a una clínica.',
    );
  }

  profile.facilityIds = profile.facilityIds.filter((id) => !id.equals(fid));
  await profile.save();

  await DoctorWorkSchedule.deleteMany({
    doctorId: doctorUserId,
    facilityId: fid,
  });

  const populated = await DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name')
    .populate('facilityIds', 'name');

  return { profile: populated };
}
