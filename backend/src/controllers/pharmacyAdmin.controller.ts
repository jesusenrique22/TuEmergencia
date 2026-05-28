import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { User } from '../models/User';
import { Pharmacy } from '../models/Pharmacy';
import { PharmacyProduct } from '../models/PharmacyProduct';
import { PharmacyOrder } from '../models/PharmacyOrder';
import { UserRole, PharmacyOrderStatus } from '../types/enums';
import { createStaffUser } from '../services/staffUser.service';
import { sanitizeUser } from '../utils/sanitizeUser';

async function getPharmacyAdminContext(userId: string) {
  const user = await User.findById(userId);
  if (!user?.pharmacyId) return null;
  const pharmacy = await Pharmacy.findById(user.pharmacyId);
  return { user, pharmacy };
}

function staffRolesForPharmacyAdmin() {
  return [UserRole.PHARMACIST, UserRole.PHARMACY_CASHIER];
}

export const getMyContext = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx) {
    return res.status(400).json({ error: 'Administrador sin farmacia asignada' });
  }
  res.json({
    user: sanitizeUser(ctx.user),
    pharmacy: ctx.pharmacy,
  });
};

export const getStats = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }
  const pharmacyId = ctx.pharmacy._id;
  const [products, orders, pendingReview] = await Promise.all([
    PharmacyProduct.countDocuments({ pharmacyId }),
    PharmacyOrder.countDocuments({ pharmacyId }),
    PharmacyOrder.countDocuments({
      pharmacyId,
      status: PharmacyOrderStatus.PENDING,
    }),
  ]);
  res.json({ products, orders, pendingReview });
};

export const createStaff = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const { name, email, phone, role } = req.body;
  if (!name?.trim() || !email?.trim()) {
    return res.status(400).json({ error: 'Nombre y correo son obligatorios' });
  }
  if (!staffRolesForPharmacyAdmin().includes(role)) {
    return res.status(400).json({
      error: 'Rol inválido. Use PHARMACIST o PHARMACY_CASHIER',
    });
  }

  try {
    const result = await createStaffUser({
      name,
      email,
      phone,
      role,
      createdBy: req.user!.id,
      pharmacyId: ctx.pharmacy.id,
    });
    res.status(201).json(result);
  } catch (e) {
    const message = (e as Error).message;
    res.status(message.includes('ya está') ? 409 : 400).json({ error: message });
  }
};

export const listStaff = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const staff = await User.find({
    pharmacyId: ctx.pharmacy._id,
    role: { $in: staffRolesForPharmacyAdmin() },
  })
    .select('-password')
    .sort({ createdAt: -1 });

  res.json(staff.map(sanitizeUser));
};

export const listProducts = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const products = await PharmacyProduct.find({ pharmacyId: ctx.pharmacy._id }).sort({
    name: 1,
  });
  res.json(products);
};

export const createProduct = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const product = await PharmacyProduct.create({
    ...req.body,
    pharmacyId: ctx.pharmacy._id,
  });
  res.status(201).json(product);
};

export const updateProduct = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const product = await PharmacyProduct.findOneAndUpdate(
    { _id: req.params.id, pharmacyId: ctx.pharmacy._id },
    { $set: req.body },
    { new: true, runValidators: true },
  );
  if (!product) return res.status(404).json({ error: 'Producto no encontrado' });
  res.json(product);
};

export const deleteProduct = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const result = await PharmacyProduct.findOneAndDelete({
    _id: req.params.id,
    pharmacyId: ctx.pharmacy._id,
  });
  if (!result) return res.status(404).json({ error: 'Producto no encontrado' });
  res.json({ message: 'Producto eliminado' });
};

export const listOrders = async (req: AuthRequest, res: Response) => {
  const ctx = await getPharmacyAdminContext(req.user!.id);
  if (!ctx?.pharmacy) {
    return res.status(400).json({ error: 'Sin farmacia asignada' });
  }

  const orders = await PharmacyOrder.find({ pharmacyId: ctx.pharmacy._id })
    .sort({ createdAt: -1 })
    .limit(100);
  res.json(orders);
};
