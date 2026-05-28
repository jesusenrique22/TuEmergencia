import { Response } from 'express';
import bcrypt from 'bcryptjs';
import { AuthRequest } from '../middleware/auth';
import { User } from '../models/User';
import { MedicalFacility } from '../models/MedicalFacility';
import { DoctorProfile } from '../models/DoctorProfile';
import { Appointment } from '../models/Appointment';
import { createDoctorByAdmin } from '../services/adminDoctor.service';
import {
  listDoctorsForFacility,
  listDoctorsNotInFacility,
  unassignDoctorFromFacility,
} from '../services/clinicDoctorAssignment.service';
import {
  ClinicInvitation,
  ClinicInvitationStatus,
} from '../models/ClinicInvitation';
import { inviteDoctorToFacility } from '../services/clinicInvitation.service';
import { sanitizeUser } from '../utils/sanitizeUser';

async function getClinicAdminContext(userId: string) {
  const user = await User.findById(userId);
  if (!user?.managedFacilityId) {
    return null;
  }
  const facility = await MedicalFacility.findById(user.managedFacilityId);
  return { user, facility };
}

export const getMyContext = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx) {
    return res.status(400).json({ error: 'Administrador de clínica sin sede asignada' });
  }
  res.json({
    user: sanitizeUser(ctx.user),
    facility: ctx.facility,
  });
};

export const getDashboard = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const facilityId = ctx.facility.id;
  const doctors = await listDoctorsForFacility(facilityId);
  const doctorUserIds = doctors
    .map((d) => d.user?.id)
    .filter((id): id is string => Boolean(id));

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  let appointmentsToday = 0;
  if (doctorUserIds.length) {
    appointmentsToday = await Appointment.countDocuments({
      doctorId: { $in: doctorUserIds },
      dateTime: { $gte: today, $lt: tomorrow },
      status: { $ne: 'CANCELLED' },
    });
  }

  const pendingInvitations = await ClinicInvitation.find({
    facilityId: ctx.facility.id,
    status: ClinicInvitationStatus.PENDING,
  })
    .populate('doctorId', 'name email phone profilePic')
    .sort({ createdAt: -1 });

  res.json({
    facility: ctx.facility,
    stats: {
      doctorsCount: doctors.length,
      appointmentsToday,
      pendingInvitationsCount: pendingInvitations.length,
    },
    doctors,
    pendingInvitations: pendingInvitations.map((inv) => ({
      id: inv.id,
      doctor: inv.doctorId,
      createdAt: inv.createdAt,
    })),
  });
};

export const listDoctors = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }
  const doctors = await listDoctorsForFacility(ctx.facility.id);
  res.json(doctors);
};

export const listAssignableDoctors = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }
  const search = req.query.search as string | undefined;
  const doctors = await listDoctorsNotInFacility(ctx.facility.id, search);
  res.json(doctors);
};

export const assignDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { doctorUserId } = req.body;
  if (!doctorUserId) {
    return res.status(400).json({ error: 'doctorUserId es obligatorio' });
  }

  try {
    const result = await inviteDoctorToFacility(
      doctorUserId,
      ctx.facility.id,
      req.user!.id,
    );
    res.status(200).json({
      invitationId: result.invitation.id,
      facilityName: result.facility.name,
      doctorName: result.doctor.name,
      message: `Invitación enviada a ${result.doctor.name}. El médico debe aceptarla para unirse a ${result.facility.name}.`,
    });
  } catch (e) {
    const message = (e as Error).message;
    res.status(400).json({ error: message });
  }
};

export const unassignDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { doctorUserId } = req.params;
  if (!doctorUserId) {
    return res.status(400).json({ error: 'doctorUserId es obligatorio' });
  }

  try {
    const result = await unassignDoctorFromFacility(doctorUserId, ctx.facility.id);
    res.json({
      profile: result.profile,
      message: 'Médico desvinculado de la clínica',
    });
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
};

export const createDoctor = async (req: AuthRequest, res: Response) => {
  const ctx = await getClinicAdminContext(req.user!.id);
  if (!ctx?.facility) {
    return res.status(400).json({ error: 'Sin clínica asignada' });
  }

  const { name, email, phone, documentId, specialtyId } = req.body;
  if (!name?.trim() || !email?.trim() || !phone?.trim() || !documentId?.trim()) {
    return res.status(400).json({
      error: 'Nombre, correo, teléfono y cédula son obligatorios',
    });
  }
  if (!specialtyId) {
    return res.status(400).json({ error: 'La especialidad es obligatoria' });
  }

  const facilityId = ctx.facility.id;

  try {
    const result = await createDoctorByAdmin({
      name,
      email,
      phone,
      documentId,
      specialtyId,
      facilityIds: [facilityId],
      allowedFacilityIds: [facilityId],
    });
    res.status(201).json(result);
  } catch (e) {
    const message = (e as Error).message;
    res.status(message.includes('ya está') ? 409 : 400).json({ error: message });
  }
};

export const changeMyPassword = async (req: AuthRequest, res: Response) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: 'Contraseña actual y nueva son obligatorias' });
  }
  if (String(newPassword).length < 6) {
    return res.status(400).json({ error: 'La nueva contraseña debe tener al menos 6 caracteres' });
  }

  const user = await User.findById(req.user!.id);
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });

  const isMatch = await bcrypt.compare(currentPassword, user.password);
  if (!isMatch) {
    return res.status(400).json({ error: 'La contraseña actual no es correcta' });
  }

  user.password = await bcrypt.hash(String(newPassword), 10);
  await user.save();

  res.json({ message: 'Contraseña actualizada correctamente' });
};
