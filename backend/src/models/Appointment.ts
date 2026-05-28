import mongoose, { Document, Schema, Types } from 'mongoose';
import { AppointmentStatus, AppointmentType } from '../types/enums';

export interface IAppointment extends Document {
  patientId: Types.ObjectId;
  doctorId: Types.ObjectId;
  facilityId?: Types.ObjectId;
  specialtyId?: Types.ObjectId;
  dateTime: Date;
  endTime?: Date;
  durationMinutes: number;
  status: AppointmentStatus;
  type: AppointmentType;
  notes?: string;
  reason?: string;
  price: number;
  patientRating?: number;
  patientReview?: string;
  ratedAt?: Date;
}

const appointmentSchema = new Schema<IAppointment>(
  {
    patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    doctorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    facilityId: { type: Schema.Types.ObjectId, ref: 'MedicalFacility' },
    specialtyId: { type: Schema.Types.ObjectId, ref: 'Specialty' },
    dateTime: { type: Date, required: true },
    endTime: { type: Date },
    durationMinutes: { type: Number, default: 30, min: 15, max: 120 },
    status: {
      type: String,
      enum: Object.values(AppointmentStatus),
      default: AppointmentStatus.PENDING,
    },
    type: {
      type: String,
      enum: Object.values(AppointmentType),
      required: true,
    },
    notes: { type: String },
    reason: { type: String },
    price: { type: Number, default: 0 },
    patientRating: { type: Number, min: 1, max: 5 },
    patientReview: { type: String, trim: true },
    ratedAt: { type: Date },
  },
  { timestamps: true, collection: 'appointments' },
);

appointmentSchema.index({ doctorId: 1, dateTime: 1 });
appointmentSchema.index({ patientId: 1, dateTime: 1 });

export const Appointment = mongoose.model<IAppointment>('Appointment', appointmentSchema);
