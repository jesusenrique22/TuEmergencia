import mongoose, { Document, Schema } from 'mongoose';

export interface IMedicalFacility extends Document {
  name: string;
  type: 'HOSPITAL' | 'CLINIC' | 'CONSULTORY';
  address: string;
  city?: string;
  phone?: string;
  latitude?: number;
  longitude?: number;
  isActive: boolean;
  /** Si es false, la clínica no recibe citas ni servicios por la app */
  serviceEnabled: boolean;
}

const medicalFacilitySchema = new Schema<IMedicalFacility>(
  {
    name: { type: String, required: true, trim: true },
    type: {
      type: String,
      enum: ['HOSPITAL', 'CLINIC', 'CONSULTORY'],
      default: 'CLINIC',
    },
    address: { type: String, required: true },
    city: { type: String },
    phone: { type: String },
    latitude: { type: Number },
    longitude: { type: Number },
    isActive: { type: Boolean, default: true },
    serviceEnabled: { type: Boolean, default: true },
  },
  { timestamps: true, collection: 'medical_facilities' },
);

export const MedicalFacility = mongoose.model<IMedicalFacility>(
  'MedicalFacility',
  medicalFacilitySchema,
);
