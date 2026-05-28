import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IPharmacyProduct extends Document {
  pharmacyId: Types.ObjectId;
  name: string;
  brand?: string;
  category?: string;
  price: number;
  stock: number;
  isAvailable: boolean;
  imageUrl?: string;
}

const pharmacyProductSchema = new Schema<IPharmacyProduct>(
  {
    pharmacyId: { type: Schema.Types.ObjectId, ref: 'Pharmacy', required: true },
    name: { type: String, required: true, trim: true },
    brand: { type: String },
    category: { type: String },
    price: { type: Number, required: true, min: 0 },
    stock: { type: Number, default: 0, min: 0 },
    isAvailable: { type: Boolean, default: true },
    imageUrl: { type: String },
  },
  { timestamps: true, collection: 'pharmacy_products' },
);

pharmacyProductSchema.index({ pharmacyId: 1 });

export const PharmacyProduct = mongoose.model<IPharmacyProduct>(
  'PharmacyProduct',
  pharmacyProductSchema,
);
