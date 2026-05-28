import mongoose, { Document, Schema, Types } from 'mongoose';

export enum ClinicInvitationStatus {
  PENDING = 'PENDING',
  ACCEPTED = 'ACCEPTED',
  REJECTED = 'REJECTED',
}

export interface IClinicInvitation extends Document {
  doctorId: Types.ObjectId;
  facilityId: Types.ObjectId;
  invitedByUserId: Types.ObjectId;
  status: ClinicInvitationStatus;
  respondedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

const clinicInvitationSchema = new Schema<IClinicInvitation>(
  {
    doctorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    facilityId: { type: Schema.Types.ObjectId, ref: 'MedicalFacility', required: true },
    invitedByUserId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    status: {
      type: String,
      enum: Object.values(ClinicInvitationStatus),
      default: ClinicInvitationStatus.PENDING,
    },
    respondedAt: { type: Date },
  },
  { timestamps: true, collection: 'clinic_invitations' },
);

clinicInvitationSchema.index({ doctorId: 1, facilityId: 1, status: 1 });

export const ClinicInvitation = mongoose.model<IClinicInvitation>(
  'ClinicInvitation',
  clinicInvitationSchema,
);
