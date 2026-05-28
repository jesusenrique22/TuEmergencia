import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { PatientProfile } from '../models/PatientProfile';
import { MedicalHistory } from '../models/MedicalHistory';
import { Appointment } from '../models/Appointment';
import { User } from '../models/User';

export const getMyProfile = async (req: AuthRequest, res: Response) => {
  const profile = await PatientProfile.findOne({ userId: req.user!.id });
  if (!profile) return res.status(404).json({ error: 'Perfil no encontrado' });
  res.json(profile);
};

export const updateMyProfile = async (req: AuthRequest, res: Response) => {
  const userId = req.user!.id;
  const body = { ...req.body };
  delete body.weightControls;

  const profile = await PatientProfile.findOneAndUpdate(
    { userId },
    { $set: body },
    { new: true, runValidators: true },
  );
  if (!profile) return res.status(404).json({ error: 'Perfil no encontrado' });

  await MedicalHistory.findOneAndUpdate(
    { patientId: userId },
    {
      $set: {
        bloodType: profile.bloodType,
        allergies: profile.allergies,
        chronicConditions: profile.chronicConditions,
        currentMedications: profile.currentMedications,
        surgeries: profile.surgeries,
        weightKg: profile.weightKg,
        heightCm: profile.heightCm,
      },
    },
    { upsert: true },
  );

  res.json(profile);
};

export const getMyMedicalHistory = async (req: AuthRequest, res: Response) => {
  let history = await MedicalHistory.findOne({ patientId: req.user!.id });
  if (!history) {
    history = await MedicalHistory.create({ patientId: req.user!.id, entries: [] });
  }
  res.json(history);
};

export const getMyAppointments = async (req: AuthRequest, res: Response) => {
  const appointments = await Appointment.find({ patientId: req.user!.id })
    .populate('doctorId', 'name email profilePic phone')
    .populate('facilityId', 'name address type')
    .populate('specialtyId', 'name')
    .sort({ dateTime: 1 });
  res.json(appointments);
};

export const getDoctorById = async (req: AuthRequest, res: Response) => {
  const doctor = await User.findById(req.params.doctorId).select('-password');
  if (!doctor || doctor.role !== 'DOCTOR') {
    return res.status(404).json({ error: 'Doctor no encontrado' });
  }
  res.json(doctor);
};
