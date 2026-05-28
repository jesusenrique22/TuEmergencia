import mongoose, { Document, Schema, Types } from 'mongoose';
import { UserRole } from '../types/enums';

export interface IUser extends Document {
  email: string;
  password: string;
  name: string;
  role: UserRole;
  phone?: string;
  profilePic?: string;
  /** Clínica que administra (CLINIC_ADMIN) */
  managedFacilityId?: Types.ObjectId;
  /** Farmacia asignada (personal de farmacia) */
  pharmacyId?: Types.ObjectId;
  isActive: boolean;
  createdBy?: Types.ObjectId;
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true },
    name: { type: String, required: true, trim: true },
    role: { type: String, enum: Object.values(UserRole), required: true },
    phone: { type: String },
    profilePic: { type: String },
    managedFacilityId: { type: Schema.Types.ObjectId, ref: 'MedicalFacility' },
    pharmacyId: { type: Schema.Types.ObjectId, ref: 'Pharmacy' },
    isActive: { type: Boolean, default: true },
    createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  },
  { timestamps: true, collection: 'users' },
);

userSchema.index({ role: 1 });

export const User = mongoose.model<IUser>('User', userSchema);
