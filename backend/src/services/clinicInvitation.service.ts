import { Types } from 'mongoose';
import {
  ClinicInvitation,
  ClinicInvitationStatus,
} from '../models/ClinicInvitation';
import { DoctorProfile } from '../models/DoctorProfile';
import { MedicalFacility } from '../models/MedicalFacility';
import { Notification } from '../models/Notification';
import { User } from '../models/User';
import { UserRole } from '../types/enums';

export async function inviteDoctorToFacility(
  doctorUserId: string,
  facilityId: string,
  invitedByUserId: string,
) {
  const user = await User.findOne({ _id: doctorUserId, role: UserRole.DOCTOR });
  if (!user) throw new Error('Médico no encontrado');

  const profile = await DoctorProfile.findOne({ userId: doctorUserId });
  if (!profile) throw new Error('Perfil de médico no encontrado');

  const facility = await MedicalFacility.findById(facilityId);
  if (!facility) throw new Error('Clínica no encontrada');

  const fid = new Types.ObjectId(facilityId);
  if (profile.facilityIds.some((id) => id.equals(fid))) {
    throw new Error('Este médico ya está vinculado a tu clínica');
  }

  const pending = await ClinicInvitation.findOne({
    doctorId: doctorUserId,
    facilityId: fid,
    status: ClinicInvitationStatus.PENDING,
  });
  if (pending) {
    throw new Error('Ya existe una invitación pendiente para este médico');
  }

  const invitation = await ClinicInvitation.create({
    doctorId: doctorUserId,
    facilityId: fid,
    invitedByUserId,
    status: ClinicInvitationStatus.PENDING,
  });

  const inviter = await User.findById(invitedByUserId).select('name');
  const inviterName = inviter?.name ?? 'Administración de clínica';

  await Notification.findOneAndUpdate(
    {
      userId: doctorUserId,
      category: 'CLINIC_INVITATION',
      relatedId: invitation.id,
    },
    {
      $set: {
        title: 'Invitación a clínica',
        message: `${inviterName} te invita a unirte a ${facility.name}. Acepta o rechaza la solicitud.`,
        type: 'WARNING',
        relatedPath: '/clinic_invitation',
        isRead: false,
      },
    },
    { upsert: true, new: true },
  );

  return { invitation, facility, doctor: user };
}

export async function acceptClinicInvitation(invitationId: string, doctorUserId: string) {
  const invitation = await ClinicInvitation.findOne({
    _id: invitationId,
    doctorId: doctorUserId,
    status: ClinicInvitationStatus.PENDING,
  });
  if (!invitation) throw new Error('Invitación no encontrada o ya respondida');

  const profile = await DoctorProfile.findOne({ userId: doctorUserId });
  if (!profile) throw new Error('Perfil de médico no encontrado');

  const fid = invitation.facilityId;
  if (!profile.facilityIds.some((id) => id.equals(fid))) {
    profile.facilityIds.push(fid);
    await profile.save();
  }

  invitation.status = ClinicInvitationStatus.ACCEPTED;
  invitation.respondedAt = new Date();
  await invitation.save();

  const facility = await MedicalFacility.findById(fid);
  const facilityName = facility?.name ?? 'la clínica';

  await Notification.findOneAndUpdate(
    {
      userId: doctorUserId,
      category: 'CLINIC_INVITATION',
      relatedId: invitationId,
    },
    {
      $set: {
        title: 'Invitación aceptada',
        message: `Te uniste a ${facilityName}. Ya puedes configurar horarios en esta sede.`,
        type: 'SUCCESS',
        isRead: true,
      },
    },
  );

  const populated = await DoctorProfile.findById(profile.id)
    .populate('specialtyIds', 'name')
    .populate('facilityIds', 'name');

  return { profile: populated, facilityName };
}

export async function rejectClinicInvitation(invitationId: string, doctorUserId: string) {
  const invitation = await ClinicInvitation.findOne({
    _id: invitationId,
    doctorId: doctorUserId,
    status: ClinicInvitationStatus.PENDING,
  });
  if (!invitation) throw new Error('Invitación no encontrada o ya respondida');

  invitation.status = ClinicInvitationStatus.REJECTED;
  invitation.respondedAt = new Date();
  await invitation.save();

  const facility = await MedicalFacility.findById(invitation.facilityId);
  const facilityName = facility?.name ?? 'la clínica';

  await Notification.findOneAndUpdate(
    {
      userId: doctorUserId,
      category: 'CLINIC_INVITATION',
      relatedId: invitationId,
    },
    {
      $set: {
        title: 'Invitación rechazada',
        message: `Rechazaste unirte a ${facilityName}.`,
        type: 'INFO',
        isRead: true,
      },
    },
  );

  return { facilityName };
}

export async function getPendingInvitationIdsForFacility(
  facilityId: string,
): Promise<Types.ObjectId[]> {
  const rows = await ClinicInvitation.find({
    facilityId,
    status: ClinicInvitationStatus.PENDING,
  }).select('doctorId');
  return rows.map((r) => r.doctorId);
}
