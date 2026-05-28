import mongoose, { Document, Schema, Types } from 'mongoose';

export interface IChatConversation extends Document {
  doctorId: Types.ObjectId;
  patientId: Types.ObjectId;
  lastMessage?: string;
  lastMessageAt?: Date;
}

const chatConversationSchema = new Schema<IChatConversation>(
  {
    doctorId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    patientId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    lastMessage: { type: String },
    lastMessageAt: { type: Date },
  },
  { timestamps: true, collection: 'chat_conversations' },
);

chatConversationSchema.index({ doctorId: 1, patientId: 1 }, { unique: true });

export const ChatConversation = mongoose.model<IChatConversation>(
  'ChatConversation',
  chatConversationSchema,
);

export interface IChatMessage extends Document {
  conversationId: Types.ObjectId;
  senderId: Types.ObjectId;
  text: string;
  readAt?: Date;
}

const chatMessageSchema = new Schema<IChatMessage>(
  {
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: 'ChatConversation',
      required: true,
    },
    senderId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    text: { type: String, required: true, trim: true },
    readAt: { type: Date },
  },
  { timestamps: true, collection: 'chat_messages' },
);

chatMessageSchema.index({ conversationId: 1, createdAt: 1 });

export const ChatMessage = mongoose.model<IChatMessage>('ChatMessage', chatMessageSchema);
