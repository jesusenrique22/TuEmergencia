import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { Notification } from '../models/Notification';
import { syncAppointmentReminders } from '../services/notification.service';

export const listMyNotifications = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const role = req.user!.role;

  await syncAppointmentReminders(userId, role);

  const notifications = await Notification.find({ userId })
    .sort({ isRead: 1, updatedAt: -1, createdAt: -1 })
    .limit(50);

  res.json(notifications);
};

export const markNotificationRead = async (req: AuthRequest, res: Response) => {
  const notification = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user!.id },
    { $set: { isRead: true } },
    { new: true },
  );
  if (!notification) return res.status(404).json({ error: 'Notificación no encontrada' });
  res.json(notification);
};

export const markAllNotificationsRead = async (req: AuthRequest, res: Response) => {
  await Notification.updateMany(
    { userId: req.user!.id, isRead: false },
    { $set: { isRead: true } },
  );
  res.json({ message: 'Todas marcadas como leídas' });
};

export const getUnreadCount = async (req: AuthRequest, res: Response) => {
  await syncAppointmentReminders(req.user!.id, req.user!.role);
  const count = await Notification.countDocuments({
    userId: req.user!.id,
    isRead: false,
  });
  res.json({ count });
};
