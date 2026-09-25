import { prisma } from '../lib/prisma';
import {
  AmbulanceUnitStatus,
  EmergencyRequestStatus,
  UserRole,
} from '../types/enums';
import { emitToFacility, pushRealtimeBroadcasts } from '../socket/realtimeGatewayClient';
import type { RealtimeBroadcast } from './realtimeOrchestration.service';
import { drivingLeg, inMaracaibo, streetAddress } from './maracaibo.geo';

const BASE_FARE = 25;
const PER_KM_RATE = 2.5;
const EARTH_RADIUS_KM = 6371;
function isFakeSimulatorGps(lat: number, lng: number): boolean {
  return haversineKm(lat, lng, 37.785834, -122.406417) < 2
    || haversineKm(lat, lng, 37.3349, -122.009) < 3;
}

function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number,
): number {
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function mapEmergencyRequest(
  row: Awaited<ReturnType<typeof fetchEmergencyById>>,
) {
  if (!row) return null;
  const driver = row.ambulance?.driver;
  const paramedic = row.ambulance?.paramedic;
  const nurse = row.ambulance?.nurse;
  return {
    id: row.id,
    patientId: row.patientId,
    facilityId: row.facilityId,
    facility: row.facility
      ? {
          id: row.facility.id,
          name: row.facility.name,
          address: row.facility.address,
          latitude: row.facility.latitude,
          longitude: row.facility.longitude,
          hasEmergencyRoom: row.facility.hasEmergencyRoom,
        }
      : null,
    ambulanceUnitId: row.ambulanceUnitId,
    ambulance: row.ambulance
      ? {
          id: row.ambulance.id,
          plateNumber: row.ambulance.plateNumber,
          callSign: row.ambulance.callSign,
          status: row.ambulance.status,
          driver: driver
            ? {
                id: driver.id,
                name: driver.name,
                phone: driver.phone,
                profilePic: driver.profilePic,
              }
            : null,
          paramedic: paramedic
            ? {
                id: paramedic.id,
                name: paramedic.name,
                phone: paramedic.phone,
                profilePic: paramedic.profilePic,
              }
            : null,
          nurse: nurse
            ? {
                id: nurse.id,
                name: nurse.name,
                phone: nurse.phone,
                profilePic: nurse.profilePic,
              }
            : null,
        }
      : null,
    originLat: row.originLat,
    originLng: row.originLng,
    originAddress: row.originAddress,
    symptoms: row.symptoms,
    painLevel: row.painLevel,
    medicalHistory: row.medicalHistory,
    status: row.status,
    paymentMethod: row.paymentMethod,
    quotedCost: row.quotedCost,
    etaMinutes: row.etaMinutes,
    ambulanceLat: row.ambulanceLat,
    ambulanceLng: row.ambulanceLng,
    requestedAt: row.requestedAt,
    completedAt: row.completedAt,
    updatedAt: row.updatedAt,
  };
}

const crewUserSelect = {
  select: { id: true, name: true, phone: true, profilePic: true },
} as const;

const emergencyInclude = {
  facility: true,
  ambulance: {
    include: {
      driver: crewUserSelect,
      paramedic: crewUserSelect,
      nurse: crewUserSelect,
    },
  },
  patient: { select: { id: true, name: true, phone: true, profilePic: true } },
} as const;

async function fetchEmergencyById(id: string) {
  return prisma.emergencyRequest.findUnique({
    where: { id },
    include: emergencyInclude,
  });
}

async function findAvailableUnit(facilityId: string) {
  return prisma.ambulanceUnit.findFirst({
    where: {
      facilityId,
      isActive: true,
      status: AmbulanceUnitStatus.AVAILABLE,
      driverId: { not: null },
    },
    include: {
      driver: { select: { id: true, name: true, phone: true, profilePic: true } },
    },
    orderBy: { updatedAt: 'asc' },
  });
}

export async function createEmergencyRequest(params: {
  patientId: string;
  facilityId: string;
  originLat: number;
  originLng: number;
  originAddress?: string;
  symptoms?: string;
  painLevel?: number;
  medicalHistory?: string;
  paymentMethod?: string;
}) {
  const facility = await prisma.medicalFacility.findFirst({
    where: {
      id: params.facilityId,
      isActive: true,
      serviceEnabled: true,
    },
  });
  if (!facility) {
    throw new Error('Clínica no encontrada o no disponible');
  }

  if (!inMaracaibo(params.originLat, params.originLng)) {
    throw new Error('La ambulancia solo cubre Maracaibo. Activa el GPS dentro de la ciudad.');
  }
  if (facility.latitude == null || facility.longitude == null || !inMaracaibo(facility.latitude, facility.longitude)) {
    throw new Error('La clínica no está en Maracaibo');
  }

  const road = await drivingLeg(
    params.originLat,
    params.originLng,
    facility.latitude,
    facility.longitude,
  );
  if (!road) {
    throw new Error('No se pudo calcular la ruta por calle en Maracaibo');
  }
  const quotedCost = Math.round((BASE_FARE + road.km * PER_KM_RATE) * 100) / 100;
  const etaMinutes = road.etaMinutes;
  const originAddress =
    (await streetAddress(params.originLat, params.originLng)) ??
    (params.originAddress && !/^-?\d/.test(params.originAddress) ? params.originAddress : null);

  const request = await prisma.emergencyRequest.create({
    data: {
      patientId: params.patientId,
      facilityId: params.facilityId,
      originLat: params.originLat,
      originLng: params.originLng,
      originAddress,
      symptoms: params.symptoms,
      painLevel: params.painLevel,
      medicalHistory: params.medicalHistory,
      paymentMethod: params.paymentMethod ?? 'CASH',
      status: EmergencyRequestStatus.REQUESTED,
      quotedCost,
      etaMinutes,
      ambulanceLat: facility.latitude ?? params.originLat,
      ambulanceLng: facility.longitude ?? params.originLng,
    },
    include: emergencyInclude,
  });

  const mapped = mapEmergencyRequest(request)!;
  const broadcasts: RealtimeBroadcast[] = [
    {
      room: `emergency:${request.id}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
    {
      room: `user:${params.patientId}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
  ];

  await pushRealtimeBroadcasts(broadcasts);
  emitToFacility(params.facilityId, 'emergency:incoming', { emergency: mapped });

  return mapped;
}

export async function listPendingFacilityRequests(userId: string) {
  const unit = await prisma.ambulanceUnit.findFirst({
    where: {
      isActive: true,
      OR: [{ driverId: userId }, { paramedicId: userId }, { nurseId: userId }],
    },
    include: { facility: true },
  });
  if (!unit) {
    throw new Error('El usuario no pertenece a ninguna clínica o unidad de ambulancia activa');
  }

  const city = unit.facility?.city?.trim();
  const rows = await prisma.emergencyRequest.findMany({
    where: {
      status: EmergencyRequestStatus.REQUESTED,
      ...(city
        ? { facility: { city } }
        : { facilityId: unit.facilityId }),
    },
    include: emergencyInclude,
    orderBy: { requestedAt: 'desc' },
  });
  return rows.map((r) => mapEmergencyRequest(r)!);
}

export async function acceptEmergencyRequest(requestId: string, driverId: string) {
  const unit = await prisma.ambulanceUnit.findFirst({
    where: {
      isActive: true,
      OR: [{ driverId }, { paramedicId: driverId }, { nurseId: driverId }],
    },
  });
  if (!unit) {
    throw new Error('No tienes ninguna unidad de ambulancia activa asignada');
  }

  const request = await prisma.emergencyRequest.findUnique({
    where: { id: requestId },
  });
  if (!request) {
    throw new Error('Solicitud de emergencia no encontrada');
  }
  if (request.status !== EmergencyRequestStatus.REQUESTED) {
    throw new Error('La solicitud ya fue tomada por otra unidad o cancelada');
  }

  const facility = await prisma.medicalFacility.findUnique({
    where: { id: unit.facilityId },
  });
  const startLat = facility?.latitude ?? unit.latitude ?? request.originLat;
  const startLng = facility?.longitude ?? unit.longitude ?? request.originLng;

  const updated = await prisma.$transaction(async (tx) => {
    await tx.ambulanceUnit.update({
      where: { id: unit.id },
      data: {
        status: AmbulanceUnitStatus.DISPATCHED,
        latitude: startLat,
        longitude: startLng,
      },
    });

    return tx.emergencyRequest.update({
      where: { id: requestId },
      data: {
        ambulanceUnitId: unit.id,
        status: EmergencyRequestStatus.DISPATCHED,
        ambulanceLat: startLat,
        ambulanceLng: startLng,
      },
      include: emergencyInclude,
    });
  });

  const mapped = mapEmergencyRequest(updated)!;

  const broadcasts: RealtimeBroadcast[] = [
    {
      room: `emergency:${requestId}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
    {
      room: `user:${updated.patientId}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
  ];

  const crewIds = [
    updated.ambulance?.driver?.id,
    updated.ambulance?.paramedic?.id,
    updated.ambulance?.nurse?.id,
  ].filter(Boolean) as string[];

  for (const id of crewIds) {
    broadcasts.push({
      room: `user:${id}`,
      event: 'emergency:assigned',
      payload: { emergency: mapped },
    });
  }

  await pushRealtimeBroadcasts(broadcasts);
  emitToFacility(updated.facilityId, 'emergency:updated', { emergency: mapped });
  return mapped;
}

export async function getEmergencyRequest(id: string) {
  const row = await fetchEmergencyById(id);
  return mapEmergencyRequest(row);
}

export async function getEmergencyRequestForUser(
  id: string,
  userId: string,
  role: UserRole,
) {
  const row = await fetchEmergencyById(id);
  if (!row) return null;
  await assertCanAccessEmergency(row, userId, role);
  return mapEmergencyRequest(row);
}

function ambulanceCrewFilter(userId: string) {
  return {
    OR: [{ driverId: userId }, { paramedicId: userId }, { nurseId: userId }],
  };
}

function isUserOnAmbulanceCrew(
  ambulance:
    | {
        driverId?: string | null;
        paramedicId?: string | null;
        nurseId?: string | null;
      }
    | null
    | undefined,
  userId: string,
): boolean {
  if (!ambulance) return false;
  return (
    ambulance.driverId === userId ||
    ambulance.paramedicId === userId ||
    ambulance.nurseId === userId
  );
}

function ambulanceCrewUserIds(
  ambulance: {
    driverId?: string | null;
    paramedicId?: string | null;
    nurseId?: string | null;
  } | null,
): string[] {
  if (!ambulance) return [];
  return [ambulance.driverId, ambulance.paramedicId, ambulance.nurseId].filter(
    Boolean,
  ) as string[];
}

export async function listPatientEmergencies(patientId: string) {
  const rows = await prisma.emergencyRequest.findMany({
    where: { patientId },
    include: emergencyInclude,
    orderBy: { requestedAt: 'desc' },
    take: 20,
  });
  return rows.map((r) => mapEmergencyRequest(r)!);
}

export async function listFacilityEmergencies(facilityId: string) {
  const activeStatuses = [
    EmergencyRequestStatus.REQUESTED,
    EmergencyRequestStatus.DISPATCHED,
    EmergencyRequestStatus.ON_SCENE,
    EmergencyRequestStatus.PATIENT_ONBOARD,
    EmergencyRequestStatus.EN_ROUTE,
  ];
  const rows = await prisma.emergencyRequest.findMany({
    where: { facilityId, status: { in: activeStatuses } },
    include: emergencyInclude,
    orderBy: { requestedAt: 'desc' },
  });
  return rows.map((r) => mapEmergencyRequest(r)!);
}

export async function listDriverEmergencies(userId: string) {
  const rows = await prisma.emergencyRequest.findMany({
    where: {
      ambulance: ambulanceCrewFilter(userId),
      status: {
        notIn: [EmergencyRequestStatus.COMPLETED, EmergencyRequestStatus.CANCELLED],
      },
    },
    include: emergencyInclude,
    orderBy: { requestedAt: 'desc' },
  });
  return rows.map((r) => mapEmergencyRequest(r)!);
}

export async function updateEmergencyStatus(
  requestId: string,
  userId: string,
  role: UserRole,
  status: EmergencyRequestStatus,
) {
  const request = await fetchEmergencyById(requestId);
  if (!request) throw new Error('Solicitud no encontrada');

  await assertCanAccessEmergency(request, userId, role);

  const terminal = [EmergencyRequestStatus.COMPLETED, EmergencyRequestStatus.CANCELLED];
  if (terminal.includes(request.status as EmergencyRequestStatus)) {
    throw new Error('La solicitud ya está cerrada');
  }

  const data: {
    status: string;
    completedAt?: Date;
  } = { status };

  if (status === EmergencyRequestStatus.COMPLETED || status === EmergencyRequestStatus.CANCELLED) {
    data.completedAt = new Date();
  }

  const updated = await prisma.$transaction(async (tx) => {
    const row = await tx.emergencyRequest.update({
      where: { id: requestId },
      data,
      include: emergencyInclude,
    });

    if (
      status === EmergencyRequestStatus.COMPLETED ||
      status === EmergencyRequestStatus.CANCELLED
    ) {
      if (row.ambulanceUnitId) {
        await tx.ambulanceUnit.update({
          where: { id: row.ambulanceUnitId },
          data: { status: AmbulanceUnitStatus.AVAILABLE },
        });
      }
    }

    return row;
  });

  const mapped = mapEmergencyRequest(updated)!;
  await pushRealtimeBroadcasts([
    {
      room: `emergency:${requestId}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
    {
      room: `user:${updated.patientId}`,
      event: 'emergency:updated',
      payload: { emergency: mapped },
    },
  ]);

  return mapped;
}

const CREW_ROLES = new Set<UserRole>([
  UserRole.AMBULANCE_DRIVER,
  UserRole.PARAMEDIC,
  UserRole.AMBULANCE_NURSE,
]);

export async function updateEmergencyLocation(
  requestId: string,
  userId: string,
  role: UserRole,
  latitude: number,
  longitude: number,
  etaMinutes?: number,
) {
  const request = await prisma.emergencyRequest.findFirst({
    where: {
      id: requestId,
      status: {
        notIn: [EmergencyRequestStatus.COMPLETED, EmergencyRequestStatus.CANCELLED],
      },
    },
    include: { ambulance: true, facility: true },
  });
  if (!request) throw new Error('Solicitud no encontrada o ya finalizada');

  const isPatient = role === UserRole.PATIENT && request.patientId === userId;
  const isAssignedCrew =
    CREW_ROLES.has(role) &&
    !!request.ambulance &&
    [request.ambulance.driverId, request.ambulance.paramedicId, request.ambulance.nurseId]
      .filter(Boolean)
      .includes(userId);

  if (!isPatient && !isAssignedCrew) {
    throw new Error('No autorizado para publicar ubicación de esta emergencia');
  }

  if (!isPatient && (isFakeSimulatorGps(latitude, longitude))) {
    return {
      emergencyRequestId: requestId,
      source: 'ambulance',
      latitude: request.ambulanceLat ?? request.originLat,
      longitude: request.ambulanceLng ?? request.originLng,
      etaMinutes: request.etaMinutes,
      distanceRemainingKm: request.ambulanceLat != null
        ? Math.round(haversineKm(request.ambulanceLat, request.ambulanceLng ?? 0, request.originLat, request.originLng) * 100) / 100
        : null,
      ignored: true,
    };
  }

  const source = isPatient ? 'patient' : 'ambulance';

  const toClinic = [
    EmergencyRequestStatus.PATIENT_ONBOARD,
    EmergencyRequestStatus.EN_ROUTE,
    EmergencyRequestStatus.ARRIVED,
  ].includes(request.status as EmergencyRequestStatus);

  const destLat = toClinic && request.facility?.latitude != null
    ? request.facility.latitude
    : isPatient
      ? latitude
      : request.originLat;
  const destLng = toClinic && request.facility?.longitude != null
    ? request.facility.longitude
    : isPatient
      ? longitude
      : request.originLng;

  const fromLat = isPatient ? (request.ambulanceLat ?? latitude) : latitude;
  const fromLng = isPatient ? (request.ambulanceLng ?? longitude) : longitude;
  const road = await drivingLeg(fromLat, fromLng, destLat, destLng);
  const distanceRemainingKm = road?.km ?? null;
  const computedEta = road?.etaMinutes ?? request.etaMinutes;

  const patientMovedKm = isPatient
    ? haversineKm(request.originLat, request.originLng, latitude, longitude)
    : 0;
  const nextAddress =
    isPatient && patientMovedKm > 0.08
      ? (await streetAddress(latitude, longitude)) ?? request.originAddress
      : request.originAddress;

  const now = new Date();
  await prisma.$transaction([
    prisma.emergencyRequest.update({
      where: { id: requestId },
      data: isPatient
        ? {
            originLat: latitude,
            originLng: longitude,
            ...(nextAddress ? { originAddress: nextAddress } : {}),
            ...(computedEta != null ? { etaMinutes: computedEta } : {}),
          }
        : {
            ambulanceLat: latitude,
            ambulanceLng: longitude,
            ...(computedEta != null ? { etaMinutes: computedEta } : {}),
          },
    }),
    ...(isAssignedCrew && request.ambulanceUnitId
      ? [
          prisma.ambulanceUnit.update({
            where: { id: request.ambulanceUnitId },
            data: { latitude, longitude, lastSeenAt: now },
          }),
        ]
      : []),
  ]);

  const payload = {
    emergencyRequestId: requestId,
    source,
    latitude,
    longitude,
    etaMinutes: computedEta ?? request.etaMinutes,
    distanceRemainingKm,
  };

  await pushRealtimeBroadcasts([
    {
      room: `emergency:${requestId}`,
      event: 'emergency:location',
      payload,
    },
    {
      room: `user:${request.patientId}`,
      event: 'emergency:location',
      payload,
    },
    {
      room: `facility:${request.facilityId}`,
      event: 'emergency:location',
      payload,
    },
  ]);

  return payload;
}

/** @deprecated usar updateEmergencyLocation */
export async function updateAmbulanceLocation(
  requestId: string,
  driverId: string,
  latitude: number,
  longitude: number,
  etaMinutes?: number,
) {
  return updateEmergencyLocation(
    requestId,
    driverId,
    UserRole.AMBULANCE_DRIVER,
    latitude,
    longitude,
    etaMinutes,
  );
}

export async function cancelEmergencyRequest(requestId: string, patientId: string) {
  return updateEmergencyStatus(
    requestId,
    patientId,
    UserRole.PATIENT,
    EmergencyRequestStatus.CANCELLED,
  );
}

async function assertCanAccessEmergency(
  request: NonNullable<Awaited<ReturnType<typeof fetchEmergencyById>>>,
  userId: string,
  role: UserRole,
) {
  if (role === UserRole.PATIENT && request.patientId === userId) return;
  if (isUserOnAmbulanceCrew(request.ambulance, userId)) return;
  if (role === UserRole.CLINIC_ADMIN) {
    const admin = await prisma.user.findUnique({
      where: { id: userId },
      select: { managedFacilityId: true },
    });
    if (admin?.managedFacilityId === request.facilityId) return;
  }
  if (role === UserRole.SUPER_ADMIN || role === UserRole.ADMIN) return;
  throw new Error('No autorizado para esta emergencia');
}

export async function assertEmergencyParticipant(
  emergencyRequestId: string,
  userId: string,
): Promise<{ ok: boolean; peerId?: string }> {
  const request = await fetchEmergencyById(emergencyRequestId);
  if (!request) return { ok: false };

  const crewIds = ambulanceCrewUserIds(request.ambulance);
  const participants = [request.patientId, ...crewIds];
  if (!participants.includes(userId)) return { ok: false };

  const peerId =
    userId === request.patientId
      ? crewIds.find((id) => id !== userId) ?? crewIds[0]
      : request.patientId;
  return { ok: true, peerId };
}

export async function createEmergencyChatMessage(params: {
  emergencyRequestId: string;
  senderId: string;
  text: string;
}) {
  const request = await fetchEmergencyById(params.emergencyRequestId);
  if (!request) throw new Error('Solicitud no encontrada');

  const crewIds = ambulanceCrewUserIds(request.ambulance);
  const allowed = [request.patientId, ...crewIds];
  if (!allowed.includes(params.senderId)) {
    throw new Error('No autorizado para chatear en esta emergencia');
  }

  const message = await prisma.emergencyChatMessage.create({
    data: {
      emergencyRequestId: params.emergencyRequestId,
      senderId: params.senderId,
      text: params.text.trim(),
    },
    include: {
      sender: { select: { id: true, name: true, profilePic: true } },
    },
  });

  const payload = {
    emergencyRequestId: params.emergencyRequestId,
    message: {
      id: message.id,
      text: message.text,
      senderId: message.senderId,
      senderName: message.sender.name,
      senderProfilePic: message.sender.profilePic,
      createdAt: message.createdAt,
    },
  };

  const peerId =
    params.senderId === request.patientId
      ? crewIds.find((id) => id !== params.senderId) ?? crewIds[0]
      : request.patientId;

  const broadcasts: RealtimeBroadcast[] = [
    {
      room: `emergency:${params.emergencyRequestId}`,
      event: 'emergency:message',
      payload,
    },
  ];
  if (peerId) {
    broadcasts.push({
      room: `user:${peerId}`,
      event: 'emergency:message',
      payload,
    });
  }

  await pushRealtimeBroadcasts(broadcasts);
  return message;
}

export async function listEmergencyMessages(emergencyRequestId: string, userId: string) {
  const check = await assertEmergencyParticipant(emergencyRequestId, userId);
  if (!check.ok) throw new Error('No autorizado');

  const messages = await prisma.emergencyChatMessage.findMany({
    where: { emergencyRequestId },
    include: { sender: { select: { id: true, name: true, profilePic: true } } },
    orderBy: { createdAt: 'asc' },
  });

  return messages.map((m) => ({
    id: m.id,
    text: m.text,
    senderId: m.senderId,
    senderName: m.sender.name,
    senderProfilePic: m.sender.profilePic,
    createdAt: m.createdAt,
  }));
}

export async function resolveEmergencyCallPeer(
  userId: string,
  emergencyRequestId: string,
): Promise<string | null> {
  const check = await assertEmergencyParticipant(emergencyRequestId, userId);
  return check.peerId ?? null;
}

export async function listFacilityAmbulances(facilityId: string) {
  return prisma.ambulanceUnit.findMany({
    where: { facilityId, isActive: true },
    include: {
      driver: crewUserSelect,
      paramedic: crewUserSelect,
      nurse: crewUserSelect,
    },
    orderBy: { callSign: 'asc' },
  });
}

export async function createAmbulanceUnit(params: {
  facilityId: string;
  plateNumber: string;
  callSign?: string;
  driverId?: string;
  paramedicId?: string;
  nurseId?: string;
  latitude?: number;
  longitude?: number;
}) {
  let latitude = params.latitude;
  let longitude = params.longitude;
  if (latitude == null || longitude == null) {
    const facility = await prisma.medicalFacility.findUnique({
      where: { id: params.facilityId },
      select: { latitude: true, longitude: true },
    });
    latitude ??= facility?.latitude ?? undefined;
    longitude ??= facility?.longitude ?? undefined;
  }

  return prisma.ambulanceUnit.create({
    data: {
      facilityId: params.facilityId,
      plateNumber: params.plateNumber.trim(),
      callSign: params.callSign?.trim(),
      driverId: params.driverId,
      paramedicId: params.paramedicId,
      nurseId: params.nurseId,
      latitude,
      longitude,
    },
    include: {
      driver: crewUserSelect,
      paramedic: crewUserSelect,
      nurse: crewUserSelect,
    },
  });
}

export async function updateAmbulanceUnit(
  unitId: string,
  facilityId: string,
  data: {
    plateNumber?: string;
    callSign?: string;
    driverId?: string | null;
    paramedicId?: string | null;
    nurseId?: string | null;
    status?: AmbulanceUnitStatus;
    isActive?: boolean;
  },
) {
  const unit = await prisma.ambulanceUnit.findFirst({
    where: { id: unitId, facilityId },
  });
  if (!unit) throw new Error('Unidad no encontrada');

  return prisma.ambulanceUnit.update({
    where: { id: unitId },
    data: {
      ...(data.plateNumber != null ? { plateNumber: data.plateNumber.trim() } : {}),
      ...(data.callSign !== undefined ? { callSign: data.callSign?.trim() ?? null } : {}),
      ...(data.driverId !== undefined ? { driverId: data.driverId } : {}),
      ...(data.paramedicId !== undefined ? { paramedicId: data.paramedicId } : {}),
      ...(data.nurseId !== undefined ? { nurseId: data.nurseId } : {}),
      ...(data.status != null ? { status: data.status } : {}),
      ...(data.isActive != null ? { isActive: data.isActive } : {}),
    },
    include: {
      driver: crewUserSelect,
      paramedic: crewUserSelect,
      nurse: crewUserSelect,
    },
  });
}

export async function getDriverFacilityRoom(userId: string): Promise<string | null> {
  const unit = await prisma.ambulanceUnit.findFirst({
    where: {
      isActive: true,
      OR: [{ driverId: userId }, { paramedicId: userId }, { nurseId: userId }],
    },
    select: { facilityId: true },
  });
  return unit?.facilityId ?? null;
}
