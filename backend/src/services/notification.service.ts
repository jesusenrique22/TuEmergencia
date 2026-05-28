import { Types } from 'mongoose';
import { Appointment } from '../models/Appointment';
import { Notification } from '../models/Notification';
import { AppointmentStatus, UserRole } from '../types/enums';
import { User } from '../models/User';

function formatApptWhen(date: Date): string {
  const d = new Date(date);
  const day = d.getDate();
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  const h = d.getHours();
  const m = d.getMinutes().toString().padStart(2, '0');
  const period = h >= 12 ? 'p. m.' : 'a. m.';
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${day} ${months[d.getMonth()]} · ${h12}:${m} ${period}`;
}

function reminderCopy(msUntil: number, otherName: string, when: string, isDoctor: boolean): {
  title: string;
  message: string;
  type: 'INFO' | 'WARNING' | 'ALERT';
} {
  const hours = msUntil / (1000 * 60 * 60);
  const prefix = isDoctor ? `Cita con ${otherName}` : `Cita con ${otherName}`;

  if (hours <= 2) {
    const mins = Math.max(1, Math.round(msUntil / 60000));
    const timeLabel =
      mins < 60 ? `${mins} min` : `${Math.floor(mins / 60)} h ${mins % 60} min`;
    return {
      title: '¡Tu cita es pronto!',
      message: `${prefix} en ${timeLabel} (${when}).`,
      type: 'ALERT',
    };
  }
  if (hours <= 24) {
    return {
      title: 'Cita mañana',
      message: `${prefix} — ${when}.`,
      type: 'WARNING',
    };
  }
  if (hours <= 72) {
    const days = Math.ceil(hours / 24);
    return {
      title: 'Recordatorio de cita',
      message: `En ${days} día${days === 1 ? '' : 's'}: ${prefix} (${when}).`,
      type: 'INFO',
    };
  }
  return {
    title: 'Cita agendada',
    message: `${prefix} el ${when}.`,
    type: 'INFO',
  };
}

export async function syncAppointmentReminders(
  userId: string,
  role: UserRole,
): Promise<void> {
  const now = new Date();
  const horizon = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
  const userOid = new Types.ObjectId(userId);

  const filter: Record<string, unknown> = {
    status: { $nin: [AppointmentStatus.CANCELLED, AppointmentStatus.COMPLETED] },
    dateTime: { $gt: now, $lte: horizon },
  };

  if (role === UserRole.PATIENT) {
    filter.patientId = userOid;
  } else if (role === UserRole.DOCTOR) {
    filter.doctorId = userOid;
  } else {
    return;
  }

  const appointments = await Appointment.find(filter)
    .populate('doctorId', 'name')
    .populate('patientId', 'name')
    .sort({ dateTime: 1 });

  const activeIds = new Set<string>();

  for (const appt of appointments) {
    const apptId = appt.id;
    activeIds.add(apptId);
    const when = formatApptWhen(appt.dateTime);
    const msUntil = appt.dateTime.getTime() - now.getTime();
    const isDoctor = role === UserRole.DOCTOR;
    const doctor = appt.doctorId as unknown as { name?: string };
    const patient = appt.patientId as unknown as { name?: string };
    const otherName = isDoctor
      ? patient?.name ?? 'paciente'
      : doctor?.name ?? 'tu médico';
    const { title, message, type } = reminderCopy(msUntil, otherName, when, isDoctor);

    await Notification.findOneAndUpdate(
      {
        userId: userOid,
        category: 'APPOINTMENT_REMINDER',
        relatedId: apptId,
      },
      {
        $set: {
          title,
          message,
          type,
          relatedPath: '/appointments',
        },
        $setOnInsert: { isRead: false },
      },
      { upsert: true, new: true },
    );
  }

  await Notification.deleteMany({
    userId: userOid,
    category: 'APPOINTMENT_REMINDER',
    relatedId: { $nin: [...activeIds] },
  });
}

export async function createChatNotification(params: {
  recipientId: string;
  senderId: string;
  senderName: string;
  text: string;
  conversationId: string;
}): Promise<void> {
  const preview =
    params.text.length > 120 ? `${params.text.slice(0, 117)}...` : params.text;

  await Notification.create({
    userId: params.recipientId,
    title: `Mensaje de ${params.senderName}`,
    message: preview,
    type: 'INFO',
    category: 'CHAT_MESSAGE',
    relatedPath: '/messages',
    relatedId: params.conversationId,
    isRead: false,
  });
}

export async function getSenderName(userId: string): Promise<string> {
  const user = await User.findById(userId).select('name');
  return user?.name ?? 'Usuario';
}
