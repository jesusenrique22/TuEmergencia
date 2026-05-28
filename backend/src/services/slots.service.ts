import { Appointment } from '../models/Appointment';
import { DoctorProfile } from '../models/DoctorProfile';
import { DoctorWorkSchedule } from '../models/DoctorWorkSchedule';
import { MedicalFacility } from '../models/MedicalFacility';
import { AppointmentStatus, AppointmentType, DayOfWeek } from '../types/enums';
import { Types } from 'mongoose';

export type SlotDuration = number;

const JS_DAY_TO_ENUM: DayOfWeek[] = [
  DayOfWeek.SUNDAY,
  DayOfWeek.MONDAY,
  DayOfWeek.TUESDAY,
  DayOfWeek.WEDNESDAY,
  DayOfWeek.THURSDAY,
  DayOfWeek.FRIDAY,
  DayOfWeek.SATURDAY,
];

export interface TimeSlot {
  startTime: string;   // "09:00"
  endTime: string;     // "09:30"
  dateTime: string;    // ISO
  facilityId?: string;
  facilityName?: string;
  available: boolean;
}

function hhmm(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + (m || 0);
}

function addMinutes(date: Date, mins: number): Date {
  return new Date(date.getTime() + mins * 60_000);
}

function overlaps(aStart: Date, aEnd: Date, bStart: Date, bEnd: Date): boolean {
  return aStart < bEnd && aEnd > bStart;
}

/** Redondea a bloques de 15 min (15–120). */
export function normalizeDuration(raw?: number): SlotDuration {
  if (!raw || Number.isNaN(raw)) return 30;
  const rounded = Math.round(raw / 15) * 15;
  return Math.min(120, Math.max(15, rounded));
}

export function computeEndTime(start: Date, duration: SlotDuration): Date {
  return addMinutes(start, duration);
}

export async function getAvailableSlots(params: {
  doctorId: string;
  date: string;
  type: AppointmentType;
  durationMinutes: SlotDuration;
  facilityId?: string;
}): Promise<TimeSlot[]> {
  const { doctorId, date, type, durationMinutes, facilityId } = params;

  const parts = date.split('-').map(Number);
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) {
    throw new Error('Fecha inválida');
  }
  const [year, month, day] = parts;
  const dayDate = new Date(year, month - 1, day);
  const dayOfWeek = JS_DAY_TO_ENUM[dayDate.getDay()];

  const scheduleQuery: Record<string, unknown> = {
    doctorId,
    dayOfWeek,
    isActive: true,
  };
  if (type === AppointmentType.PRESENTIAL && facilityId) {
    scheduleQuery.facilityId = facilityId;
  }

  if (type === AppointmentType.PRESENTIAL && !facilityId) {
    const profile = await DoctorProfile.findOne({ userId: doctorId }).select('facilityIds');
    if (profile?.facilityIds.length) {
      scheduleQuery.facilityId = { $in: profile.facilityIds };
    }
  }

  const schedules = await DoctorWorkSchedule.find(scheduleQuery).populate<{
    facilityId: { _id: Types.ObjectId; name: string } | null;
  }>('facilityId', 'name');

  type Block = {
    startTime: string;
    endTime: string;
    facility: { _id: Types.ObjectId; name: string } | null;
  };

  const blocks: Block[] = schedules.map((sched) => {
    const facilityRaw = sched.facilityId;
    const facility =
      facilityRaw && typeof facilityRaw === 'object' && '_id' in facilityRaw
        ? (facilityRaw as { _id: Types.ObjectId; name: string })
        : null;
    return {
      startTime: sched.startTime,
      endTime: sched.endTime,
      facility,
    };
  });

  if (blocks.length === 0 && type === AppointmentType.ONLINE) {
    blocks.push({
      startTime: '09:00',
      endTime: '18:00',
      facility: null,
    });
  }

  if (blocks.length === 0 && type === AppointmentType.PRESENTIAL && facilityId) {
    const facility = await MedicalFacility.findById(facilityId).select('name');
    if (facility) {
      blocks.push({
        startTime: '08:00',
        endTime: '18:00',
        facility: { _id: facility._id, name: facility.name },
      });
    }
  }

  const dayStart = new Date(dayDate);
  dayStart.setHours(0, 0, 0, 0);
  const dayEnd = new Date(dayDate);
  dayEnd.setHours(23, 59, 59, 999);

  const existing = await Appointment.find({
    doctorId,
    status: { $nin: [AppointmentStatus.CANCELLED] },
    dateTime: { $gte: dayStart, $lte: dayEnd },
  });

  const slots: TimeSlot[] = [];
  const STEP = durationMinutes;

  for (const sched of blocks) {
    const startMin = toMinutes(sched.startTime);
    const endMin = toMinutes(sched.endTime);
    const facility = sched.facility;

    for (let min = startMin; min + durationMinutes <= endMin; min += STEP) {
      const slotStart = new Date(dayDate);
      slotStart.setHours(Math.floor(min / 60), min % 60, 0, 0);
      const slotEnd = computeEndTime(slotStart, durationMinutes);

      const isPast = slotStart.getTime() <= Date.now();
      const conflict = existing.some((appt) => {
        const apptEnd =
          appt.endTime ?? computeEndTime(appt.dateTime, normalizeDuration(appt.durationMinutes));
        return overlaps(slotStart, slotEnd, appt.dateTime, apptEnd);
      });

      slots.push({
        startTime: hhmm(min),
        endTime: hhmm(min + durationMinutes),
        dateTime: slotStart.toISOString(),
        facilityId: facility?._id?.toString(),
        facilityName: facility?.name,
        available: !isPast && !conflict,
      });
    }
  }

  slots.sort((a, b) => new Date(a.dateTime).getTime() - new Date(b.dateTime).getTime());

  // Misma hora en varias sedes: si hay conflicto (p. ej. cita virtual), marcar todas como no disponibles.
  const byDateTime = new Map<string, TimeSlot>();
  for (const slot of slots) {
    const key = slot.dateTime;
    const prev = byDateTime.get(key);
    if (!prev) {
      byDateTime.set(key, slot);
      continue;
    }
    byDateTime.set(key, {
      ...prev,
      available: prev.available && slot.available,
      facilityId: prev.facilityId ?? slot.facilityId,
      facilityName:
        prev.facilityName && slot.facilityName && prev.facilityName !== slot.facilityName
          ? `${prev.facilityName} / ${slot.facilityName}`
          : prev.facilityName ?? slot.facilityName,
    });
  }

  return [...byDateTime.values()].sort(
    (a, b) => new Date(a.dateTime).getTime() - new Date(b.dateTime).getTime(),
  );
}

export async function assertNoConflict(params: {
  doctorId: string;
  dateTime: Date;
  durationMinutes: SlotDuration;
  excludeId?: string;
}): Promise<void> {
  const { doctorId, dateTime, durationMinutes, excludeId } = params;
  const endTime = computeEndTime(dateTime, durationMinutes);

  const query: Record<string, unknown> = {
    doctorId,
    status: { $nin: [AppointmentStatus.CANCELLED] },
  };
  if (excludeId) query._id = { $ne: excludeId };

  const existing = await Appointment.find(query);
  const conflict = existing.find((appt) => {
    const apptEnd =
      appt.endTime ?? computeEndTime(appt.dateTime, normalizeDuration(appt.durationMinutes));
    return overlaps(dateTime, endTime, appt.dateTime, apptEnd);
  });

  if (conflict) {
    const dt = conflict.dateTime;
    const timeStr = `${String(dt.getHours()).padStart(2, '0')}:${String(dt.getMinutes()).padStart(2, '0')}`;
    throw new Error(`El médico ya tiene una cita a las ${timeStr}. Elige otro horario.`);
  }
}
