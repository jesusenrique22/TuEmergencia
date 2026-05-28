import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IWeightControlRecord {
  weightKg?: string;
  fatPercent?: string;
  visceral?: string;
  muscleKg?: string;
  bmi?: string;
  doseDate?: string;
  dose?: string;
}

export interface IPatientProfile extends Document {
  userId: Types.ObjectId;
  fullName: string;
  email: string;
  phone?: string;
  documentId?: string;
  birthDate?: string;
  address?: string;
  emergencyContactName?: string;
  emergencyContactPhone?: string;
  referredBy?: string;
  maritalStatus?: string;
  occupation?: string;
  bloodType?: string;
  allergies?: string;
  chronicConditions?: string;
  currentMedications?: string;
  surgeries?: string;
  weightKg?: string;
  heightCm?: string;
  obesityType?: string;
  recommendedSurgery?: string;
  vaccines?: string;
  hasHypertension?: boolean;
  hasDiabetes?: boolean;
  hasBronchialAsthma?: boolean;
  isSmoker?: boolean;
  /** NONE | MILD | MODERATE | SEVERE */
  covidSeverity?: string;
  observations?: string;
  weightControls?: IWeightControlRecord[];
  insuranceProvider?: string;
  policyNumber?: string;
  medicalHistoryCompleted?: boolean;
}

const weightControlSchema = new Schema<IWeightControlRecord>(
  {
    weightKg: String,
    fatPercent: String,
    visceral: String,
    muscleKg: String,
    bmi: String,
    doseDate: String,
    dose: String,
  },
  { _id: false },
);

const patientProfileSchema = new Schema<IPatientProfile>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    fullName: { type: String, required: true },
    email: { type: String, required: true },
    phone: { type: String },
    documentId: { type: String },
    birthDate: { type: String },
    address: { type: String },
    emergencyContactName: { type: String },
    emergencyContactPhone: { type: String },
    referredBy: { type: String },
    maritalStatus: { type: String },
    occupation: { type: String },
    bloodType: { type: String },
    allergies: { type: String },
    chronicConditions: { type: String },
    currentMedications: { type: String },
    surgeries: { type: String },
    weightKg: { type: String },
    heightCm: { type: String },
    obesityType: { type: String },
    recommendedSurgery: { type: String },
    vaccines: { type: String },
    hasHypertension: { type: Boolean, default: false },
    hasDiabetes: { type: Boolean, default: false },
    hasBronchialAsthma: { type: Boolean, default: false },
    isSmoker: { type: Boolean, default: false },
    covidSeverity: { type: String, default: 'NONE' },
    observations: { type: String },
    weightControls: { type: [weightControlSchema], default: [] },
    insuranceProvider: { type: String },
    policyNumber: { type: String },
    medicalHistoryCompleted: { type: Boolean, default: false },
  },
  { timestamps: true, collection: 'patient_profiles' },
);

export const PatientProfile = mongoose.model<IPatientProfile>(
  'PatientProfile',
  patientProfileSchema,
);
