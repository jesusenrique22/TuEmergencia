import mongoose, { Document, Schema, Types } from 'mongoose';
import { PharmacyOrderStatus } from '../types/enums';

export interface IPharmacyOrder extends Document {
  pharmacyId: Types.ObjectId;
  patientId?: Types.ObjectId;
  productId?: Types.ObjectId;
  productName: string;
  quantity: number;
  total: number;
  status: PharmacyOrderStatus;
}

const pharmacyOrderSchema = new Schema<IPharmacyOrder>(
  {
    pharmacyId: { type: Schema.Types.ObjectId, ref: 'Pharmacy', required: true },
    patientId: { type: Schema.Types.ObjectId, ref: 'User' },
    productId: { type: Schema.Types.ObjectId, ref: 'PharmacyProduct' },
    productName: { type: String, required: true },
    quantity: { type: Number, required: true, min: 1 },
    total: { type: Number, required: true, min: 0 },
    status: {
      type: String,
      enum: Object.values(PharmacyOrderStatus),
      default: PharmacyOrderStatus.PENDING,
    },
  },
  { timestamps: true, collection: 'pharmacy_orders' },
);

pharmacyOrderSchema.index({ pharmacyId: 1, createdAt: -1 });

export const PharmacyOrder = mongoose.model<IPharmacyOrder>(
  'PharmacyOrder',
  pharmacyOrderSchema,
);
