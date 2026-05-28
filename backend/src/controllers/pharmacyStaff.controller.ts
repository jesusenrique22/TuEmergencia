import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { User } from '../models/User';
import { Pharmacy } from '../models/Pharmacy';
import { PharmacyOrder } from '../models/PharmacyOrder';
import { PharmacyOrderStatus } from '../types/enums';
import { sanitizeUser } from '../utils/sanitizeUser';

async function getPharmacyStaffContext(userId: string) {
  const user = await User.findById(userId);
  if (!user?.pharmacyId) return null;
  const pharmacy = await Pharmacy.findById(user.pharmacyId);
  return { user, pharmacy };
}

export const getMyContext = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyStaffContext(req.user!.id);
  if (!ctx) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }
  res.json({
    user: sanitizeUser(ctx.user),
    pharmacy: ctx.pharmacy,
  });
};

export const listOrders = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyStaffContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const orders = await PharmacyOrder.find({ pharmacyId: ctx.pharmacy._id })
    .sort({ createdAt: -1 })
    .limit(100);
  res.json(orders);
};

export const updateOrderStatus = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyStaffContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const { status } = req.body;
  if (!Object.values(PharmacyOrderStatus).includes(status)) {
    return res.status(400).json({ error: 'Estado inválido' });
  }

  const order = await PharmacyOrder.findOne({
    _id: req.params.id,
    pharmacyId: ctx.pharmacy._id,
  });
  if (!order) return res.status(404).json({ error: 'Pedido no encontrado' });

  order.status = status;
  await order.save();
  res.json(order);
};
