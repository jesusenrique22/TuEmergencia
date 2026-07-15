import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import { UserRole } from '../types/enums';

/**
 * Obtener todas las compañías de seguro activas con sus coberturas.
 */
export const getCompanies = async (req: AuthRequest, res: Response) => {
  try {
    const companies = await prisma.insuranceCompany.findMany({
      where: { isActive: true },
      include: { coverages: true },
    });
    return res.json(companies);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

/**
 * Obtener la póliza de seguro activa para el paciente autenticado.
 */
export const getMyPolicy = async (req: AuthRequest, res: Response) => {
  try {
    const policy = await prisma.patientPolicy.findFirst({
      where: {
        patientId: req.user!.id,
        status: 'ACTIVE',
      },
      include: {
        insurance: {
          include: {
            coverages: true,
          },
        },
      },
    });
    return res.json(policy);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

/**
 * Registrar o actualizar una póliza de seguro para el paciente autenticado.
 */
export const updateMyPolicy = async (req: AuthRequest, res: Response) => {
  try {
    const { insuranceId, policyNumber, status } = req.body;
    if (!insuranceId || !policyNumber) {
      return res.status(400).json({ error: 'insuranceId y policyNumber son requeridos' });
    }

    const company = await prisma.insuranceCompany.findUnique({
      where: { id: insuranceId },
    });
    if (!company) {
      return res.status(404).json({ error: 'Compañía de seguros no encontrada' });
    }

    // Desactivar pólizas anteriores si la nueva será la ACTIVA
    const newStatus = status || 'ACTIVE';
    if (newStatus === 'ACTIVE') {
      await prisma.patientPolicy.updateMany({
        where: {
          patientId: req.user!.id,
          status: 'ACTIVE',
        },
        data: { status: 'INACTIVE' },
      });
    }

    const policy = await prisma.patientPolicy.upsert({
      where: {
        patientId_insuranceId: {
          patientId: req.user!.id,
          insuranceId: insuranceId,
        },
      },
      create: {
        patientId: req.user!.id,
        insuranceId: insuranceId,
        policyNumber: policyNumber,
        status: newStatus,
      },
      update: {
        policyNumber: policyNumber,
        status: newStatus,
      },
      include: {
        insurance: {
          include: {
            coverages: true,
          },
        },
      },
    });

    // Mantener sincronizado el perfil clínico estático
    await prisma.patientProfile.update({
      where: { userId: req.user!.id },
      data: {
        insuranceProvider: company.name,
        policyNumber: policyNumber,
      },
    });

    return res.json(policy);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

/**
 * Calcular el copago en tiempo real desde el servidor.
 */
export const calculateCopay = async (req: AuthRequest, res: Response) => {
  try {
    const { subtotal, category } = req.body;
    if (typeof subtotal !== 'number' || !category) {
      return res.status(400).json({ error: 'subtotal y category son requeridos' });
    }

    const activePolicy = await prisma.patientPolicy.findFirst({
      where: {
        patientId: req.user!.id,
        status: 'ACTIVE',
      },
      include: {
        insurance: {
          include: {
            coverages: true,
          },
        },
      },
    });

    if (!activePolicy) {
      return res.json({
        subtotal,
        coveredAmount: 0.0,
        totalToPay: subtotal,
        percentage: 0.0,
        insuranceName: 'Ninguno',
        insuranceId: null,
      });
    }

    const coverage = activePolicy.insurance.coverages[0];
    if (!coverage) {
      return res.status(404).json({ error: 'Configuración de cobertura no encontrada' });
    }

    let percentage = 0.0;
    switch (category) {
      case 'pharmacy':
        percentage = coverage.pharmacyPercentage;
        break;
      case 'ambulance':
        percentage = coverage.ambulancePercentage;
        break;
      case 'laboratory':
        percentage = coverage.laboratoryPercentage;
        break;
      case 'er':
        percentage = coverage.erConsultationPercentage;
        break;
      default:
        return res.status(400).json({ error: 'Categoría de copago no válida' });
    }

    let coveredAmount = subtotal * percentage;
    if (coveredAmount > coverage.maxLimit) {
      coveredAmount = coverage.maxLimit;
    }
    const totalToPay = subtotal - coveredAmount;

    return res.json({
      subtotal,
      coveredAmount,
      totalToPay,
      percentage,
      insuranceName: activePolicy.insurance.name,
      insuranceId: activePolicy.insuranceId,
    });
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

/**
 * Obtener facturas e historial de liquidaciones del paciente.
 */
export const getMyInvoices = async (req: AuthRequest, res: Response) => {
  try {
    const invoices = await prisma.medicalInvoice.findMany({
      where: { patientId: req.user!.id },
      include: { insurance: true },
      orderBy: { createdAt: 'desc' },
    });
    return res.json(invoices);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};

/**
 * Registrar una factura médica aprobada por seguro.
 */
export const createInvoice = async (req: AuthRequest, res: Response) => {
  try {
    const { requestId, insuranceId, subtotal, coveredAmount, copayAmount, status } = req.body;
    if (!requestId || !insuranceId || typeof subtotal !== 'number') {
      return res.status(400).json({ error: 'Datos de facturación incompletos' });
    }

    const invoice = await prisma.medicalInvoice.create({
      data: {
        requestId,
        patientId: req.user!.id,
        insuranceId,
        subtotal,
        coveredAmount,
        copayAmount,
        status: status || 'PENDING',
      },
      include: { insurance: true },
    });

    return res.json(invoice);
  } catch (error: any) {
    return res.status(500).json({ error: error.message });
  }
};
