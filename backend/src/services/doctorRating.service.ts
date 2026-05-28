import { Types } from 'mongoose';
import { Appointment } from '../models/Appointment';
import { DoctorProfile } from '../models/DoctorProfile';
import { AppointmentStatus } from '../types/enums';

export async function recalculateDoctorRating(doctorId: string): Promise<void> {
  const doctorOid = new Types.ObjectId(doctorId);
  const [agg] = await Appointment.aggregate([
    {
      $match: {
        doctorId: doctorOid,
        status: AppointmentStatus.COMPLETED,
        patientRating: { $exists: true, $ne: null },
      },
    },
    {
      $group: {
        _id: null,
        avg: { $avg: '$patientRating' },
        count: { $sum: 1 },
      },
    },
  ]);

  const rating = agg?.avg != null ? Math.round(agg.avg * 10) / 10 : 5;
  const ratingCount = agg?.count ?? 0;

  await DoctorProfile.findOneAndUpdate(
    { userId: doctorId },
    { $set: { rating, ratingCount } },
  );
}
