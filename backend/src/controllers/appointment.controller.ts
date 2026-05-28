import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { Appointment } from '../models/Appointment';
import { DoctorProfile } from '../models/DoctorProfile';
import { MedicalHistory } from '../models/MedicalHistory';
import { AppointmentStatus, AppointmentType, UserRole } from '../types/enums';
import {
  assertNoConflict,
  computeEndTime,
  normalizeDuration,
} from '../services/slots.service';
import { getDoctorConsultationDuration } from '../services/doctorDuration.service';
import { assertDoctorFacility } from '../utils/doctorFacilities';
import { isSuperAdminRole } from '../utils/roleHelpers';
import { recalculateDoctorRating } from '../services/doctorRating.service';

export async function recordCompletedVisit(
  appointment: InstanceType<typeof Appointment>,
  doctorId: string,
  clinicalNotes?: string,
): Promise<void> {
  const title =
    appointment.reason?.trim() ||
    `Consulta ${appointment.type === AppointmentType.ONLINE ? 'telemedicina' : 'presencial'}`;

  await MedicalHistory.findOneAndUpdate(
    { patientId: appointment.patientId },
    {
      $push: {
        entries: {
          date: appointment.dateTime,
          doctorId,
          title,
          description:
            clinicalNotes?.trim() ||
            appointment.notes?.trim() ||
            'Consulta completada.',
          diagnosis: appointment.reason,
          treatment: clinicalNotes || appointment.notes,
        },
      },
    },
    { upsert: true, new: true },
  );
}

export const createAppointment = async (req: AuthRequest, res: Response) => {
  const {
    doctorId,
    facilityId,
    specialtyId,
    dateTime,
    type,
    reason,
    durationMinutes: rawDuration,
  } = req.body;

  if (!doctorId || !dateTime || !type) {
    return res.status(400).json({ error: 'doctorId, dateTime y type son obligatorios' });
  }

  if (!Object.values(AppointmentType).includes(type)) {
    return res.status(400).json({ error: 'type inválido: ONLINE o PRESENTIAL' });
  }

  const resolvedSpecialtyId = specialtyId as string | undefined;
  const duration =
    rawDuration != null
      ? normalizeDuration(Number(rawDuration))
      : await getDoctorConsultationDuration(doctorId, resolvedSpecialtyId);

  const start = new Date(dateTime);
  if (Number.isNaN(start.getTime())) {
    return res.status(400).json({ error: 'dateTime inválido' });
  }
  if (start.getTime() < Date.now()) {
    return res.status(400).json({ error: 'No se pueden agendar citas en el pasado' });
  }

  if (type === AppointmentType.PRESENTIAL) {
    if (!facilityId) {
      return res.status(400).json({ error: 'facilityId es obligatorio para citas presenciales' });
    }
    try {
      await assertDoctorFacility(doctorId, facilityId);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  }

  try {
    await assertNoConflict({ doctorId, dateTime: start, durationMinutes: duration });
  } catch (e) {
    return res.status(409).json({ error: (e as Error).message });
  }

  const patientId =
    req.user!.role === UserRole.PATIENT ? req.user!.id : req.body.patientId;
  if (!patientId) return res.status(400).json({ error: 'patientId requerido' });

  const doctorProfile = await DoctorProfile.findOne({ userId: doctorId });
  const price =
    type === AppointmentType.ONLINE
      ? doctorProfile?.consultationPriceOnline ?? 25
      : doctorProfile?.consultationPricePresential ?? 45;

  const endTime = computeEndTime(start, duration);

  const appointment = await Appointment.create({
    patientId,
    doctorId,
    facilityId: type === AppointmentType.PRESENTIAL ? facilityId : undefined,
    specialtyId,
    dateTime: start,
    endTime,
    durationMinutes: duration,
    type,
    reason,
    price,
    status: AppointmentStatus.CONFIRMED,
  });

  const populated = await Appointment.findById(appointment.id)
    .populate('doctorId', 'name email profilePic phone')
    .populate('patientId', 'name email profilePic phone')
    .populate('facilityId', 'name address type')
    .populate('specialtyId', 'name');

  res.status(201).json(populated);
};

export const getAppointmentById = async (req: AuthRequest, res: Response) => {
  const appointment = await Appointment.findById(req.params.id)
    .populate('doctorId', 'name email profilePic phone')
    .populate('patientId', 'name email profilePic phone')
    .populate('facilityId')
    .populate('specialtyId', 'name');

  if (!appointment) return res.status(404).json({ error: 'Cita no encontrada' });

  const userId = req.user!.id;
  const ok =
    appointment.patientId.toString() === userId ||
    appointment.doctorId.toString() === userId ||
    isSuperAdminRole(req.user!.role);

  if (!ok) return res.status(403).json({ error: 'Acceso denegado' });
  res.json(appointment);
};

export const cancelAppointment = async (req: AuthRequest, res: Response) => {
  const appointment = await Appointment.findById(req.params.id);
  if (!appointment) return res.status(404).json({ error: 'Cita no encontrada' });

  const userId = req.user!.id;
  const ok =
    appointment.patientId.toString() === userId ||
    appointment.doctorId.toString() === userId ||
    isSuperAdminRole(req.user!.role);

  if (!ok) return res.status(403).json({ error: 'Acceso denegado' });

  appointment.status = AppointmentStatus.CANCELLED;
  await appointment.save();

  const populated = await Appointment.findById(appointment.id)
    .populate('doctorId', 'name email profilePic')
    .populate('patientId', 'name email profilePic')
    .populate('facilityId', 'name address')
    .populate('specialtyId', 'name');

  res.json(populated);
};

export const rateAppointment = async (req: AuthRequest, res: Response) => {
  const stars = Number(req.body.rating);
  const comment =
    typeof req.body.comment === 'string' ? req.body.comment.trim() : undefined;

  if (!Number.isFinite(stars) || stars < 1 || stars > 5) {
    return res.status(400).json({ error: 'La calificación debe ser entre 1 y 5 estrellas' });
  }

  const appointment = await Appointment.findById(req.params.id);
  if (!appointment) return res.status(404).json({ error: 'Cita no encontrada' });

  if (appointment.patientId.toString() !== req.user!.id) {
    return res.status(403).json({ error: 'Solo el paciente puede calificar esta cita' });
  }

  if (appointment.status !== AppointmentStatus.COMPLETED) {
    return res.status(400).json({
      error: 'Solo puedes calificar citas que ya fueron completadas',
    });
  }

  if (appointment.patientRating != null) {
    return res.status(400).json({ error: 'Ya calificaste esta consulta' });
  }

  appointment.patientRating = Math.round(stars);
  appointment.patientReview = comment || undefined;
  appointment.ratedAt = new Date();
  await appointment.save();

  await recalculateDoctorRating(appointment.doctorId.toString());

  const populated = await Appointment.findById(appointment.id)
    .populate('doctorId', 'name email profilePic phone')
    .populate('patientId', 'name email profilePic phone')
    .populate('facilityId', 'name address type')
    .populate('specialtyId', 'name');

  res.json(populated);
};
