import { Response } from 'express';
import { Types } from 'mongoose';
import { AuthRequest } from '../middleware/auth';
import { User } from '../models/User';
import { Appointment } from '../models/Appointment';
import { MedicalFacility } from '../models/MedicalFacility';
import { Pharmacy } from '../models/Pharmacy';
import { PharmacyOrder } from '../models/PharmacyOrder';
import { PharmacyProduct } from '../models/PharmacyProduct';
import { UserRole } from '../types/enums';
import { createStaffUser } from '../services/staffUser.service';
import { sanitizeUser } from '../utils/sanitizeUser';

export const getOverviewStats = async (_req: AuthRequest, res: Response) => {
  const [
    patients,
    doctors,
    clinicAdmins,
    pharmacyAdmins,
    appointments,
    facilities,
    pharmacies,
    pharmacyOrders,
    productsListed,
  ] = await Promise.all([
    User.countDocuments({ role: UserRole.PATIENT }),
    User.countDocuments({ role: UserRole.DOCTOR }),
    User.countDocuments({ role: UserRole.CLINIC_ADMIN }),
    User.countDocuments({ role: UserRole.PHARMACY_ADMIN }),
    Appointment.countDocuments(),
    MedicalFacility.countDocuments(),
    Pharmacy.countDocuments(),
    PharmacyOrder.countDocuments(),
    PharmacyProduct.countDocuments(),
  ]);

  res.json({
    patients,
    doctors,
    clinicAdmins,
    pharmacyAdmins,
    appointments,
    facilities,
    pharmacies,
    pharmacyOrders,
    productsListed,
  });
};

export const getFacilityStats = async (_req: AuthRequest, res: Response) => {
  const facilities = await MedicalFacility.find().sort({ name: 1 });
  const stats = await Promise.all(
    facilities.map(async (facility) => {
      const facilityId = facility._id;
      const appointmentsAtFacility = await Appointment.countDocuments({
        facilityId,
        status: { $ne: 'CANCELLED' },
      });
      const distinctPatients = await Appointment.distinct('patientId', {
        facilityId,
        status: { $ne: 'CANCELLED' },
      });
      return {
        facility: {
          id: facility.id,
          name: facility.name,
          city: facility.city,
          isActive: facility.isActive,
          serviceEnabled: facility.serviceEnabled,
        },
        appointmentsCount: appointmentsAtFacility,
        patientsViaApp: distinctPatients.length,
      };
    }),
  );
  res.json(stats);
};

export const getPharmacyStats = async (_req: AuthRequest, res: Response) => {
  const pharmacies = await Pharmacy.find().sort({ name: 1 });
  const stats = await Promise.all(
    pharmacies.map(async (pharmacy) => {
      const pharmacyId = pharmacy._id;
      const [ordersCount, productsCount, revenueAgg] = await Promise.all([
        PharmacyOrder.countDocuments({ pharmacyId }),
        PharmacyProduct.countDocuments({ pharmacyId }),
        PharmacyOrder.aggregate([
          { $match: { pharmacyId: new Types.ObjectId(pharmacy.id) } },
          { $group: { _id: null, total: { $sum: '$total' } } },
        ]),
      ]);
      return {
        pharmacy: {
          id: pharmacy.id,
          name: pharmacy.name,
          isActive: pharmacy.isActive,
          serviceEnabled: pharmacy.serviceEnabled,
        },
        ordersCount,
        productsCount,
        revenueTotal: revenueAgg[0]?.total ?? 0,
      };
    }),
  );
  res.json(stats);
};

export const listFacilities = async (_req: AuthRequest, res: Response) => {
  const facilities = await MedicalFacility.find().sort({ name: 1 });
  res.json(facilities);
};

export const createFacility = async (req: AuthRequest, res: Response) => {
  const { name, type, address, city, phone } = req.body;

  if (!name?.trim()) {
    return res.status(400).json({ error: 'El nombre de la clínica es obligatorio' });
  }
  if (!address?.trim()) {
    return res.status(400).json({ error: 'La dirección es obligatoria' });
  }

  const allowedTypes = ['HOSPITAL', 'CLINIC', 'CONSULTORY'] as const;
  const facilityType =
    type && allowedTypes.includes(type) ? type : 'CLINIC';

  const existing = await MedicalFacility.findOne({
    name: { $regex: new RegExp(`^${name.trim()}$`, 'i') },
  });
  if (existing) {
    return res.status(409).json({ error: 'Ya existe una clínica con ese nombre' });
  }

  const facility = await MedicalFacility.create({
    name: name.trim(),
    type: facilityType,
    address: address.trim(),
    city: city?.trim() || undefined,
    phone: phone?.trim() || undefined,
    isActive: true,
    serviceEnabled: true,
  });

  res.status(201).json(facility);
};

export const listPharmacies = async (_req: AuthRequest, res: Response) => {
  const pharmacies = await Pharmacy.find().sort({ name: 1 });
  res.json(pharmacies);
};

export const setFacilityService = async (req: AuthRequest, res: Response) => {
  const { serviceEnabled } = req.body;
  if (typeof serviceEnabled !== 'boolean') {
    return res.status(400).json({ error: 'serviceEnabled debe ser true o false' });
  }
  const facility = await MedicalFacility.findByIdAndUpdate(
    req.params.id,
    { serviceEnabled },
    { new: true },
  );
  if (!facility) return res.status(404).json({ error: 'Clínica no encontrada' });
  res.json(facility);
};

export const setPharmacyService = async (req: AuthRequest, res: Response) => {
  const { serviceEnabled } = req.body;
  if (typeof serviceEnabled !== 'boolean') {
    return res.status(400).json({ error: 'serviceEnabled debe ser true o false' });
  }
  const pharmacy = await Pharmacy.findByIdAndUpdate(
    req.params.id,
    { serviceEnabled },
    { new: true },
  );
  if (!pharmacy) return res.status(404).json({ error: 'Farmacia no encontrada' });
  res.json(pharmacy);
};

export const createClinicAdmin = async (req: AuthRequest, res: Response) => {
  const { name, email, phone, facilityId } = req.body;
  if (!name?.trim() || !email?.trim() || !facilityId) {
    return res.status(400).json({ error: 'Nombre, correo y clínica son obligatorios' });
  }

  const facility = await MedicalFacility.findById(facilityId);
  if (!facility) return res.status(400).json({ error: 'Clínica no encontrada' });

  try {
    const result = await createStaffUser({
      name,
      email,
      phone,
      role: UserRole.CLINIC_ADMIN,
      createdBy: req.user!.id,
      managedFacilityId: facilityId,
    });
    res.status(201).json(result);
  } catch (e) {
    const message = (e as Error).message;
    res.status(message.includes('ya está') ? 409 : 400).json({ error: message });
  }
};

export const createPharmacyAdmin = async (req: AuthRequest, res: Response) => {
  const { name, email, phone, pharmacyId } = req.body;
  if (!name?.trim() || !email?.trim() || !pharmacyId) {
    return res.status(400).json({ error: 'Nombre, correo y farmacia son obligatorios' });
  }

  const pharmacy = await Pharmacy.findById(pharmacyId);
  if (!pharmacy) return res.status(400).json({ error: 'Farmacia no encontrada' });

  try {
    const result = await createStaffUser({
      name,
      email,
      phone,
      role: UserRole.PHARMACY_ADMIN,
      createdBy: req.user!.id,
      pharmacyId,
    });
    res.status(201).json(result);
  } catch (e) {
    const message = (e as Error).message;
    res.status(message.includes('ya está') ? 409 : 400).json({ error: message });
  }
};

export const listManagedUsers = async (req: AuthRequest, res: Response) => {
  const filter: Record<string, unknown> = {
    createdBy: req.user!.id,
    role: {
      $in: [UserRole.CLINIC_ADMIN, UserRole.PHARMACY_ADMIN],
    },
  };
  const users = await User.find(filter).select('-password').sort({ createdAt: -1 });
  res.json(users.map(sanitizeUser));
};
