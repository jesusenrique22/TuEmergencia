import { Response } from 'express';
import bcrypt from 'bcryptjs';
import { AuthRequest } from '../middleware/auth';
import { User } from '../models/User';
import { DoctorProfile } from '../models/DoctorProfile';
import { DoctorWorkSchedule } from '../models/DoctorWorkSchedule';
import { Appointment } from '../models/Appointment';
import { MedicalHistory } from '../models/MedicalHistory';
import { PatientProfile } from '../models/PatientProfile';
import { ChatConversation } from '../models/Chat';
import { AppointmentStatus } from '../types/enums';
import { recordCompletedVisit } from './appointment.controller';
import { assertDoctorFacility } from '../utils/doctorFacilities';
import { IWeightControlRecord } from '../models/PatientProfile';
import {
  acceptClinicInvitation as acceptClinicInvitationService,
  rejectClinicInvitation as rejectClinicInvitationService,
} from '../services/clinicInvitation.service';

async function assertGeneralMedicineDoctor(doctorId: string): Promise<void> {
  const profile = await DoctorProfile.findOne({ userId: doctorId }).populate(
    'specialtyIds',
    'name',
  );
  if (!profile) throw new Error('Perfil de médico no encontrado');

  const names = (profile.specialtyIds as unknown as { name: string }[]).map((s) =>
    s.name.toLowerCase(),
  );
  const isGeneral = names.some((n) => n.includes('medicina general') || n === 'general');
  if (!isGeneral) {
    throw new Error(
      'Solo los médicos de Medicina General pueden registrar el control de peso del paciente',
    );
  }
}

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

export const getMyProfile = async (req: AuthRequest, res: Response) => {
  const profile = await DoctorProfile.findOne({ userId: req.user!.id })
    .populate('specialtyIds')
    .populate('facilityIds');
  const user = await User.findById(req.user!.id).select('-password');
  res.json({ user, profile });
};

export const updateMyProfile = async (req: AuthRequest, res: Response) => {
  const profile = await DoctorProfile.findOneAndUpdate(
    { userId: req.user!.id },
    { $set: req.body },
    { new: true, runValidators: true },
  )
    .populate('specialtyIds')
    .populate('facilityIds');
  if (!profile) return res.status(404).json({ error: 'Perfil de doctor no encontrado' });
  res.json(profile);
};

export const getMySchedules = async (req: AuthRequest, res: Response) => {
  const schedules = await DoctorWorkSchedule.find({ doctorId: req.user!.id, isActive: true })
    .populate('facilityId')
    .sort({ dayOfWeek: 1, startTime: 1 });
  res.json(schedules);
};

export const createSchedule = async (req: AuthRequest, res: Response) => {
  const { facilityId } = req.body;
  if (!facilityId) {
    return res.status(400).json({ error: 'facilityId es obligatorio' });
  }
  try {
    await assertDoctorFacility(req.user!.id, facilityId);
  } catch (e) {
    return res.status(400).json({ error: (e as Error).message });
  }

  const schedule = await DoctorWorkSchedule.create({
    ...req.body,
    doctorId: req.user!.id,
  });
  const populated = await schedule.populate('facilityId');
  res.status(201).json(populated);
};

export const updateSchedule = async (req: AuthRequest, res: Response) => {
  if (req.body.facilityId) {
    try {
      await assertDoctorFacility(req.user!.id, req.body.facilityId);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  }

  const schedule = await DoctorWorkSchedule.findOneAndUpdate(
    { _id: req.params.id, doctorId: req.user!.id },
    { $set: req.body },
    { new: true },
  ).populate('facilityId');
  if (!schedule) return res.status(404).json({ error: 'Horario no encontrado' });
  res.json(schedule);
};

export const deleteSchedule = async (req: AuthRequest, res: Response) => {
  const result = await DoctorWorkSchedule.findOneAndDelete({
    _id: req.params.id,
    doctorId: req.user!.id,
  });
  if (!result) return res.status(404).json({ error: 'Horario no encontrado' });
  res.json({ message: 'Horario eliminado' });
};

export const getMyAppointments = async (req: AuthRequest, res: Response) => {
  const filter: Record<string, unknown> = { doctorId: req.user!.id };
  if (req.query.status) filter.status = req.query.status;
  if (req.query.date) {
    const day = new Date(req.query.date as string);
    const next = new Date(day);
    next.setDate(next.getDate() + 1);
    filter.dateTime = { $gte: day, $lt: next };
  }

  const appointments = await Appointment.find(filter)
    .populate('patientId', 'name email profilePic phone')
    .populate('facilityId', 'name address')
    .populate('specialtyId', 'name')
    .sort({ dateTime: 1 });
  res.json(appointments);
};

export const updateAppointmentStatus = async (req: AuthRequest, res: Response) => {
  const { status, notes, clinicalNotes } = req.body;

  const appointment = await Appointment.findOne({
    _id: req.params.id,
    doctorId: req.user!.id,
  });
  if (!appointment) return res.status(404).json({ error: 'Cita no encontrada' });

  if (status) appointment.status = status;
  if (notes !== undefined) appointment.notes = notes;

  if (status === AppointmentStatus.COMPLETED) {
    await recordCompletedVisit(appointment, req.user!.id, clinicalNotes);
  }

  await appointment.save();

  const populated = await Appointment.findById(appointment.id)
    .populate('patientId', 'name email profilePic phone')
    .populate('facilityId', 'name address')
    .populate('specialtyId', 'name');

  res.json(populated);
};

export const getPatientMedicalHistory = async (req: AuthRequest, res: Response) => {
  // Solo médicos que hayan tenido al menos una cita con el paciente
  const hasRelation = await Appointment.exists({
    doctorId: req.user!.id,
    patientId: req.params.patientId,
  });
  if (!hasRelation) {
    return res.status(403).json({
      error: 'Solo puedes ver el historial de pacientes que hayas atendido',
    });
  }

  const [history, profile] = await Promise.all([
    MedicalHistory.findOne({ patientId: req.params.patientId })
      .populate('entries.doctorId', 'name email'),
    PatientProfile.findOne({ userId: req.params.patientId }),
  ]);

  res.json({ profile: profile ?? null, history: history ?? { entries: [] } });
};

export const addMedicalHistoryEntry = async (req: AuthRequest, res: Response) => {
  const { patientId } = req.params;

  const hasRelation = await Appointment.exists({
    doctorId: req.user!.id,
    patientId,
  });
  if (!hasRelation) {
    return res.status(403).json({ error: 'Sin relación médico-paciente' });
  }

  const entry = {
    ...req.body,
    doctorId: req.user!.id,
    date: req.body.date ? new Date(req.body.date) : new Date(),
  };

  const history = await MedicalHistory.findOneAndUpdate(
    { patientId },
    { $push: { entries: entry } },
    { new: true, upsert: true },
  );
  res.status(201).json(history);
};

export const updatePatientWeightControls = async (req: AuthRequest, res: Response) => {
  const { patientId } = req.params;
  const { weightControls } = req.body as { weightControls?: IWeightControlRecord[] };

  if (!Array.isArray(weightControls)) {
    return res.status(400).json({ error: 'weightControls debe ser un arreglo' });
  }

  try {
    await assertGeneralMedicineDoctor(req.user!.id);
  } catch (e) {
    return res.status(403).json({ error: (e as Error).message });
  }

  const hasRelation = await Appointment.exists({
    doctorId: req.user!.id,
    patientId,
  });
  if (!hasRelation) {
    return res.status(403).json({
      error: 'Solo puedes actualizar pacientes con los que hayas tenido citas',
    });
  }

  const profile = await PatientProfile.findOneAndUpdate(
    { userId: patientId },
    { $set: { weightControls } },
    { new: true },
  );
  if (!profile) return res.status(404).json({ error: 'Perfil del paciente no encontrado' });

  res.json(profile);
};

export const getMyPatients = async (req: AuthRequest, res: Response) => {
  const apptPatients = await Appointment.distinct('patientId', {
    doctorId: req.user!.id,
  });
  const chatPatients = await ChatConversation.distinct('patientId', {
    doctorId: req.user!.id,
  });
  const ids = [...new Set([...apptPatients.map(String), ...chatPatients.map(String)])];
  const users = await User.find({ _id: { $in: ids } }).select('-password');
  const profiles = await PatientProfile.find({ userId: { $in: ids } });
  res.json(
    users.map((u) => ({
      user: u,
      profile: profiles.find((pr) => pr.userId.toString() === u.id) ?? null,
    })),
  );
};

export const acceptClinicInvitation = async (req: AuthRequest, res: Response) => {
  try {
    const result = await acceptClinicInvitationService(req.params.id, req.user!.id);
    res.json({
      message: `Te uniste a ${result.facilityName} correctamente`,
      profile: result.profile,
    });
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
};

export const rejectClinicInvitation = async (req: AuthRequest, res: Response) => {
  try {
    const result = await rejectClinicInvitationService(req.params.id, req.user!.id);
    res.json({
      message: `Rechazaste la invitación a ${result.facilityName}`,
    });
  } catch (e) {
    res.status(400).json({ error: (e as Error).message });
  }
};
