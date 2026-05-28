import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { ChatConversation, ChatMessage } from '../models/Chat';
import { UserRole } from '../types/enums';
import {
  createChatNotification,
  getSenderName,
} from '../services/notification.service';

export const listConversations = async (req: AuthRequest, res: Response) => {
  const filter =
    req.user!.role === UserRole.DOCTOR
      ? { doctorId: req.user!.id }
      : { patientId: req.user!.id };

  const conversations = await ChatConversation.find(filter)
    .populate('doctorId', 'name email profilePic')
    .populate('patientId', 'name email profilePic')
    .sort({ lastMessageAt: -1 });

  res.json(conversations);
};

export const getOrCreateConversation = async (req: AuthRequest, res: Response) => {
  const { doctorId, patientId } = req.body;

  let docId = doctorId;
  let patId = patientId;

  if (req.user!.role === UserRole.DOCTOR) {
    docId = req.user!.id;
    if (!patId) return res.status(400).json({ error: 'patientId requerido' });
  } else {
    patId = req.user!.id;
    if (!docId) return res.status(400).json({ error: 'doctorId requerido' });
  }

  let conversation = await ChatConversation.findOne({ doctorId: docId, patientId: patId });
  if (!conversation) {
    conversation = await ChatConversation.create({ doctorId: docId, patientId: patId });
  }

  const populated = await conversation.populate([
    { path: 'doctorId', select: 'name email profilePic' },
    { path: 'patientId', select: 'name email profilePic' },
  ]);

  res.json(populated);
};

export const getMessages = async (req: AuthRequest, res: Response) => {
  const conversation = await ChatConversation.findById(req.params.conversationId);
  if (!conversation) return res.status(404).json({ error: 'Conversación no encontrada' });

  const userId = req.user!.id;
  const isParticipant =
    conversation.doctorId.toString() === userId ||
    conversation.patientId.toString() === userId;

  if (!isParticipant) return res.status(403).json({ error: 'Acceso denegado' });

  const messages = await ChatMessage.find({ conversationId: conversation.id })
    .populate('senderId', 'name profilePic role')
    .sort({ createdAt: 1 });

  res.json(messages);
};

export const sendMessage = async (req: AuthRequest, res: Response) => {
  const { conversationId, text } = req.body;
  const conversation = await ChatConversation.findById(conversationId);
  if (!conversation) return res.status(404).json({ error: 'Conversación no encontrada' });

  const userId = req.user!.id;
  const isParticipant =
    conversation.doctorId.toString() === userId ||
    conversation.patientId.toString() === userId;

  if (!isParticipant) return res.status(403).json({ error: 'Acceso denegado' });

  const message = await ChatMessage.create({
    conversationId,
    senderId: userId,
    text,
  });

  conversation.lastMessage = text;
  conversation.lastMessageAt = new Date();
  await conversation.save();

  const recipientId =
    conversation.doctorId.toString() === userId
      ? conversation.patientId.toString()
      : conversation.doctorId.toString();
  const senderName = await getSenderName(userId);
  await createChatNotification({
    recipientId,
    senderId: userId,
    senderName,
    text: String(text).trim(),
    conversationId: conversation.id,
  });

  const populated = await message.populate('senderId', 'name profilePic role');
  res.status(201).json(populated);
};
