import mongoose, { Document, Schema } from 'mongoose';

export interface IPharmacy extends Document {
  name: string;
  address: string;
  logoUrl?: string;
  phone?: string;
  isActive: boolean;
  serviceEnabled: boolean;
}

const pharmacySchema = new Schema<IPharmacy>(
  {
    name: { type: String, required: true, trim: true },
    address: { type: String, required: true },
    logoUrl: { type: String },
    phone: { type: String },
    isActive: { type: Boolean, default: true },
    serviceEnabled: { type: Boolean, default: true },
  },
  { timestamps: true, collection: 'pharmacies' },
);

export const Pharmacy = mongoose.model<IPharmacy>('Pharmacy', pharmacySchema);
