import mongoose, { Document, Schema, Types } from 'mongoose';

export interface ISpecialtyConsultationDuration {
  specialtyId: Types.ObjectId;
  durationMinutes: number;
}

export interface IDoctorProfile extends Document {
  userId: Types.ObjectId;
  /** Cédula de identidad */
  documentId?: string;
  licenseNumber?: string;
  bio?: string;
  specialtyIds: Types.ObjectId[];
  facilityIds: Types.ObjectId[];
  rating: number;
  ratingCount: number;
  consultationPriceOnline: number;
  consultationPricePresential: number;
  /** Duración por defecto si no hay regla por especialidad */
  defaultConsultationMinutes: number;
  /** Duración definida por el médico para cada especialidad */
  specialtyConsultationDurations: ISpecialtyConsultationDuration[];
}

const doctorProfileSchema = new Schema<IDoctorProfile>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    documentId: { type: String, trim: true, unique: true, sparse: true },
    licenseNumber: { type: String },
    bio: { type: String },
    specialtyIds: [{ type: Schema.Types.ObjectId, ref: 'Specialty' }],
    facilityIds: [{ type: Schema.Types.ObjectId, ref: 'MedicalFacility' }],
    rating: { type: Number, default: 5 },
    ratingCount: { type: Number, default: 0 },
    consultationPriceOnline: { type: Number, default: 25 },
    consultationPricePresential: { type: Number, default: 45 },
    defaultConsultationMinutes: { type: Number, default: 30, min: 15, max: 120 },
    specialtyConsultationDurations: [
      {
        specialtyId: { type: Schema.Types.ObjectId, ref: 'Specialty', required: true },
        durationMinutes: { type: Number, required: true, min: 15, max: 120 },
      },
    ],
  },
  { timestamps: true, collection: 'doctor_profiles' },
);

export const DoctorProfile = mongoose.model<IDoctorProfile>(
  'DoctorProfile',
  doctorProfileSchema,
);
