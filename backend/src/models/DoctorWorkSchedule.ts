import mongoose, { Document, Schema, Types } from 'mongoose';
import { DayOfWeek } from '../types/enums';

export interface IDoctorWorkSchedule extends Document {
  doctorId: Types.ObjectId;
  facilityId: Types.ObjectId;
  dayOfWeek: DayOfWeek;
  startTime: string;
  endTime: string;
  isActive: boolean;
}

const doctorWorkScheduleSchema = new Schema<IDoctorWorkSchedule>(
  {
    doctorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    facilityId: { type: Schema.Types.ObjectId, ref: 'MedicalFacility', required: true },
    dayOfWeek: { type: String, enum: Object.values(DayOfWeek), required: true },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true, collection: 'doctor_work_schedules' },
);

doctorWorkScheduleSchema.index({ doctorId: 1, dayOfWeek: 1 });

export const DoctorWorkSchedule = mongoose.model<IDoctorWorkSchedule>(
  'DoctorWorkSchedule',
  doctorWorkScheduleSchema,
);
