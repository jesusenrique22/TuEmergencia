import mongoose, { Document, Schema, Types } from 'mongoose';

export type NotificationCategory =
  | 'APPOINTMENT_REMINDER'
  | 'CHAT_MESSAGE'
  | 'CLINIC_INVITATION'
  | 'SYSTEM';

export interface INotification extends Document {
  userId: Types.ObjectId;
  title: string;
  message: string;
  type: 'INFO' | 'SUCCESS' | 'WARNING' | 'ALERT';
  category: NotificationCategory;
  relatedPath?: string;
  relatedId?: string;
  isRead: boolean;
}

const notificationSchema = new Schema<INotification>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
      type: String,
      enum: ['INFO', 'SUCCESS', 'WARNING', 'ALERT'],
      default: 'INFO',
    },
    category: {
      type: String,
      enum: ['APPOINTMENT_REMINDER', 'CHAT_MESSAGE', 'CLINIC_INVITATION', 'SYSTEM'],
      required: true,
    },
    relatedPath: { type: String },
    relatedId: { type: String },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: true, collection: 'notifications' },
);

notificationSchema.index({ userId: 1, category: 1, relatedId: 1 });

export const Notification = mongoose.model<INotification>(
  'Notification',
  notificationSchema,
);
