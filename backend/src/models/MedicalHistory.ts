import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IMedicalHistoryEntry {
  date: Date;
  doctorId?: Types.ObjectId;
  title: string;
  description: string;
  diagnosis?: string;
  treatment?: string;
  attachments?: string[];
}

export interface IMedicalHistory extends Document {
  patientId: Types.ObjectId;
  bloodType?: string;
  allergies?: string;
  chronicConditions?: string;
  currentMedications?: string;
  surgeries?: string;
  weightKg?: string;
  heightCm?: string;
  entries: IMedicalHistoryEntry[];
}

const medicalHistoryEntrySchema = new Schema<IMedicalHistoryEntry>(
  {
    date: { type: Date, default: Date.now },
    doctorId: { type: Schema.Types.ObjectId, ref: 'User' },
    title: { type: String, required: true },
    description: { type: String, required: true },
    diagnosis: { type: String },
    treatment: { type: String },
    attachments: [{ type: String }],
  },
  { _id: true },
);

const medicalHistorySchema = new Schema<IMedicalHistory>(
  {
    patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    bloodType: { type: String },
    allergies: { type: String },
    chronicConditions: { type: String },
    currentMedications: { type: String },
    surgeries: { type: String },
    weightKg: { type: String },
    heightCm: { type: String },
    entries: [medicalHistoryEntrySchema],
  },
  { timestamps: true, collection: 'medical_histories' },
);

export const MedicalHistory = mongoose.model<IMedicalHistory>(
  'MedicalHistory',
  medicalHistorySchema,
);
